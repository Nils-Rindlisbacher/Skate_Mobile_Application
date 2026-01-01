package com.trick_manager.Trick_API.controller;

import com.trick_manager.Trick_API.entity.SessionGoal;
import com.trick_manager.Trick_API.entity.Stance;
import com.trick_manager.Trick_API.entity.User;
import com.trick_manager.Trick_API.repository.SessionGoalRepository;
import com.trick_manager.Trick_API.repository.UserRepository;
import com.trick_manager.Trick_API.service.TrickActionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/goals")
@CrossOrigin(origins = "*")
public class SessionGoalController {

    @Autowired
    private SessionGoalRepository goalRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TrickActionService trickActionService;

    private Long getCurrentUserId(Principal principal) {
        return userRepository.findByUsername(principal.getName())
                .orElseThrow(() -> new RuntimeException("User not found"))
                .getId();
    }

    @GetMapping
    public List<SessionGoal> getGoals(Principal principal) {
        return goalRepository.findByUserId(getCurrentUserId(principal));
    }

    @PostMapping
    public SessionGoal addGoal(@RequestBody SessionGoal goal, Principal principal) {
        goal.setUserId(getCurrentUserId(principal));
        return goalRepository.save(goal);
    }

    @PutMapping("/{id}")
    public SessionGoal updateGoal(@PathVariable Long id, @RequestBody SessionGoal goalDetails, Principal principal) {
        SessionGoal goal = goalRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Goal not found"));

        if (!goal.getUserId().equals(getCurrentUserId(principal))) {
            throw new RuntimeException("Unauthorized");
        }

        goal.setTitle(goalDetails.getTitle());
        goal.setType(goalDetails.getType());
        goal.setTrickId(goalDetails.getTrickId());
        goal.setStance(goalDetails.getStance());
        goal.setTargetCount(goalDetails.getTargetCount());
        goal.setCurrentCount(goalDetails.getCurrentCount());
        goal.setTimerDuration(goalDetails.getTimerDuration());
        goal.setRemainingTime(goalDetails.getRemainingTime());
        goal.setCompleted(goalDetails.isCompleted());

        // If goal is trick-based and marked completed, automatically add to completed tricks
        if (goal.isCompleted() && goal.getTrickId() != null) {
            Stance stance = goal.getStance() != null ? goal.getStance() : Stance.REGULAR;
            trickActionService.addToCompleted(goal.getUserId(), goal.getTrickId(), stance);
        }

        return goalRepository.save(goal);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteGoal(@PathVariable Long id, Principal principal) {
        SessionGoal goal = goalRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Goal not found"));

        if (!goal.getUserId().equals(getCurrentUserId(principal))) {
            throw new RuntimeException("Unauthorized");
        }

        goalRepository.delete(goal);
        return ResponseEntity.ok().build();
    }
}
