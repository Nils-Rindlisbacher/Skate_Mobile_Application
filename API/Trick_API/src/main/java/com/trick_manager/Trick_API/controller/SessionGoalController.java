package com.trick_manager.Trick_API.controller;

import com.trick_manager.Trick_API.entity.SessionGoal;
import com.trick_manager.Trick_API.entity.User;
import com.trick_manager.Trick_API.repository.SessionGoalRepository;
import com.trick_manager.Trick_API.repository.UserRepository;
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

    @GetMapping
    public List<SessionGoal> getGoals(Authentication authentication) {
        User user = userRepository.findByUsername(authentication.getName()).orElseThrow();
        return goalRepository.findByUserOrderByCreatedAtDesc(user);
    }

    @PostMapping
    public SessionGoal addGoal(@RequestBody SessionGoal goal, Authentication authentication) {
        User user = userRepository.findByUsername(authentication.getName()).orElseThrow();
        goal.setUser(user);
        return goalRepository.save(goal);
    }

    @PutMapping("/{id}")
    public SessionGoal updateGoal(@PathVariable Long id, @RequestBody SessionGoal goalDetails, Authentication authentication) {
        SessionGoal goal = goalRepository.findById(id).orElseThrow();
        // Security check
        if (!goal.getUser().getUsername().equals(authentication.getName())) {
            throw new RuntimeException("Unauthorized");
        }
        
        goal.setCurrentCount(goalDetails.getCurrentCount());
        goal.setRemainingTime(goalDetails.getRemainingTime());
        goal.setCompleted(goalDetails.isCompleted());
        
        return goalRepository.save(goal);
    }

    @DeleteMapping("/{id}")
    public void deleteGoal(@PathVariable Long id, Authentication authentication) {
        SessionGoal goal = goalRepository.findById(id).orElseThrow();
        if (goal.getUser().getUsername().equals(authentication.getName())) {
            goalRepository.delete(goal);
        }
    }
}
