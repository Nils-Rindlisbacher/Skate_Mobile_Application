package com.trick_manager.Trick_API.controller;

import com.trick_manager.Trick_API.entity.SessionGoal;
import com.trick_manager.Trick_API.entity.User;
import com.trick_manager.Trick_API.repository.SessionGoalRepository;
import com.trick_manager.Trick_API.repository.UserRepository;
import com.trick_manager.Trick_API.service.TrickActionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/goals")
public class SessionGoalController {

    @Autowired
    private SessionGoalRepository goalRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TrickActionService trickActionService;

    @GetMapping
    public List<SessionGoal> getGoals(Authentication authentication) {
        User user = userRepository.findByUsername(authentication.getName()).orElseThrow();
        return goalRepository.findByUserOrderByCreatedAtDesc(user);
    }

    @PostMapping
    public SessionGoal addGoal(@RequestBody SessionGoal goal, Authentication authentication) {
        User user = userRepository.findByUsername(authentication.getName()).orElseThrow();
        goal.setUser(user);
        
        // Ensure timerDuration is set if remainingTime is provided on creation
        if (goal.getTimerDuration() == null && goal.getRemainingTime() != null) {
            goal.setTimerDuration(goal.getRemainingTime());
        }
        
        return goalRepository.save(goal);
    }

    @PutMapping("/{id}")
    public SessionGoal updateGoal(@PathVariable Long id, @RequestBody SessionGoal goalDetails, Authentication authentication) {
        SessionGoal goal = goalRepository.findById(id).orElseThrow();
        User user = userRepository.findByUsername(authentication.getName()).orElseThrow();
        
        // Security check
        if (!goal.getUser().getUsername().equals(user.getUsername())) {
            throw new RuntimeException("Unauthorized");
        }
        
        boolean wasCompleted = goal.isCompleted();
        
        goal.setCurrentCount(goalDetails.getCurrentCount());
        goal.setRemainingTime(goalDetails.getRemainingTime());
        goal.setCompleted(goalDetails.isCompleted());
        
        SessionGoal updatedGoal = goalRepository.save(goal);
        
        // If goal was just completed and it's a trick goal, add to completed tricks
        if (!wasCompleted && updatedGoal.isCompleted() && "trick".equals(updatedGoal.getType()) && updatedGoal.getTrickId() != null) {
            trickActionService.addToCompleted(user.getId(), updatedGoal.getTrickId());
        }
        
        return updatedGoal;
    }

    @DeleteMapping("/{id}")
    public void deleteGoal(@PathVariable Long id, Authentication authentication) {
        SessionGoal goal = goalRepository.findById(id).orElseThrow();
        if (goal.getUser().getUsername().equals(authentication.getName())) {
            goalRepository.delete(goal);
        }
    }
}
