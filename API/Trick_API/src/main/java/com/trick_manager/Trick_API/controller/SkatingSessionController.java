package com.trick_manager.Trick_API.controller;

import com.trick_manager.Trick_API.entity.SkatingSession;
import com.trick_manager.Trick_API.entity.User;
import com.trick_manager.Trick_API.repository.SkatingSessionRepository;
import com.trick_manager.Trick_API.repository.UserRepository;
import com.trick_manager.Trick_API.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/sessions")
@CrossOrigin(origins = "*")
public class SkatingSessionController {

    @Autowired
    private SkatingSessionRepository sessionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserService userService;

    private Long getCurrentUserId(Principal principal) {
        return userRepository.findByUsername(principal.getName())
                .orElseThrow(() -> new RuntimeException("User not found"))
                .getId();
    }

    @GetMapping
    public ResponseEntity<List<SkatingSession>> getSessions(
            @RequestParam(name = "user_id", required = false) Long userId,
            Principal principal) {
        
        Long targetUserId;
        if (userId != null) {
            User targetUser = userService.findById(userId)
                    .orElseThrow(() -> new RuntimeException("User not found"));
            
            if (!targetUser.isPublic() && (principal == null || !principal.getName().equals(targetUser.getUsername()))) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
            targetUserId = userId;
        } else {
            if (principal == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
            targetUserId = getCurrentUserId(principal);
        }
        
        return ResponseEntity.ok(sessionRepository.findByUserId(targetUserId));
    }

    @PostMapping
    public SkatingSession logSession(@RequestBody SkatingSession session, Principal principal) {
        Long userId = getCurrentUserId(principal);
        session.setUserId(userId);
        if (session.getSessionDate() == null) {
            session.setSessionDate(LocalDate.now());
        }
        
        // Check if session for this date already exists
        return sessionRepository.findByUserIdAndSessionDate(userId, session.getSessionDate())
                .map(existing -> {
                    existing.setMood(session.getMood());
                    return sessionRepository.save(existing);
                })
                .orElseGet(() -> sessionRepository.save(session));
    }

    @DeleteMapping("/{date}")
    public ResponseEntity<?> deleteSession(@PathVariable String date, Principal principal) {
        Long userId = getCurrentUserId(principal);
        LocalDate sessionDate = LocalDate.parse(date);
        
        sessionRepository.findByUserIdAndSessionDate(userId, sessionDate).ifPresent(session -> {
            sessionRepository.delete(session);
        });
        
        return ResponseEntity.ok().build();
    }
}
