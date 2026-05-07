package com.trick_manager.Trick_API.controller;

import com.trick_manager.Trick_API.entity.User;
import com.trick_manager.Trick_API.entity.FriendRequest;
import com.trick_manager.Trick_API.repository.LeaderboardProjection;
import com.trick_manager.Trick_API.service.UserService;
import com.trick_manager.Trick_API.config.JwtUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired
    private UserService userService;

    @Autowired
    private JwtUtils jwtUtils;

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody User user) {
        try {
            User savedUser = userService.registerUser(user);
            return new ResponseEntity<>(savedUser, HttpStatus.CREATED);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Registrierung fehlgeschlagen: " + e.getMessage());
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        String username = credentials.get("username");
        String password = credentials.get("password");

        if (userService.validateUser(username, password)) {
            String token = jwtUtils.generateToken(username);
            return ResponseEntity.ok(Map.of("token", token));
        }
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Ungültige Zugangsdaten");
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(Principal principal) {
        if (principal == null) {
            return ResponseEntity.status(401).body("Not authenticated");
        }

        return userService.findByUsername(principal.getName())
                .map(user -> {
                    user.setPassword(null);
                    return ResponseEntity.ok(user);
                })
                .orElse(ResponseEntity.status(404).build());
    }

    @DeleteMapping("/me")
    public ResponseEntity<?> deleteCurrentUser(Principal principal) {
        if (principal == null) {
            return ResponseEntity.status(401).body("Not authenticated");
        }
        try {
            userService.deleteUser(principal.getName());
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(e.getMessage());
        }
    }

    @GetMapping("/profile/{id}")
    public ResponseEntity<?> getUserProfile(@PathVariable Long id) {
        return userService.findById(id)
                .map(user -> {
                    if (!user.isPublic()) {
                        return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Profile is private");
                    }
                    user.setPassword(null);
                    return ResponseEntity.ok(user);
                })
                .orElse(ResponseEntity.status(404).build());
    }

    @GetMapping("/search")
    public ResponseEntity<List<User>> searchUsers(@RequestParam String query) {
        return ResponseEntity.ok(userService.searchUsers(query));
    }

    @PostMapping("/me/image")
    public ResponseEntity<?> updateProfileImage(@RequestBody Map<String, String> request, Principal principal) {
        String base64Image = request.get("image");
        if (base64Image == null) return ResponseEntity.badRequest().build();

        userService.updateProfileImage(principal.getName(), base64Image);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/me/privacy")
    public ResponseEntity<?> updatePrivacy(@RequestBody Map<String, Boolean> request, Principal principal) {
        if (principal == null) return ResponseEntity.status(401).build();
        
        Boolean isPublic = request.get("is_public");
        if (isPublic == null) return ResponseEntity.badRequest().build();

        userService.updatePrivacy(principal.getName(), isPublic);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/leaderboard")
    public ResponseEntity<List<LeaderboardProjection>> getLeaderboard(
            @RequestParam(name = "category_id", required = false) Long categoryId,
            @RequestParam(name = "stance", required = false) String stance) {
        
        String filterStance = (stance == null || stance.equalsIgnoreCase("ALL")) ? null : stance.toUpperCase();
        return ResponseEntity.ok(userService.getLeaderboardData(categoryId, filterStance));
    }

    // --- Friends (Expert Bidirectional System) ---
    
    @GetMapping("/relationship/{targetId}")
    public ResponseEntity<Map<String, String>> getRelationshipStatus(@PathVariable Long targetId, Principal principal) {
        // Fallback for guests: relationship is always NONE
        if (principal == null) return ResponseEntity.ok(Map.of("status", "NONE"));
        return ResponseEntity.ok(Map.of("status", userService.getRelationshipStatus(principal.getName(), targetId)));
    }

    @PostMapping("/friends/request/send")
    public ResponseEntity<?> sendFriendRequest(@RequestBody Map<String, Long> request, Principal principal) {
        try {
            userService.sendFriendRequest(principal.getName(), request.get("user_id"));
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/friends/requests/pending")
    public ResponseEntity<List<FriendRequest>> getPendingRequests(Principal principal) {
        return ResponseEntity.ok(userService.getPendingRequests(principal.getName()));
    }

    @PostMapping("/friends/requests/{id}/accept")
    public ResponseEntity<?> acceptFriendRequest(@PathVariable Long id, Principal principal) {
        try {
            userService.acceptFriendRequest(principal.getName(), id);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/friends/requests/{id}/decline")
    public ResponseEntity<?> declineFriendRequest(@PathVariable Long id, Principal principal) {
        try {
            userService.declineFriendRequest(principal.getName(), id);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/friends/remove")
    public ResponseEntity<?> removeFriend(@RequestBody Map<String, Long> request, Principal principal) {
        try {
            userService.unfriendUser(principal.getName(), request.get("user_id"));
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/friends")
    public ResponseEntity<?> getFriends(Principal principal) {
        return ResponseEntity.ok(userService.getFriends(principal.getName()));
    }

    // --- Blocking ---
    @PostMapping("/block")
    public ResponseEntity<?> blockUser(@RequestBody Map<String, Long> request, Principal principal) {
        userService.blockUser(principal.getName(), request.get("user_id"));
        return ResponseEntity.ok().build();
    }

    @PostMapping("/unblock")
    public ResponseEntity<?> unblockUser(@RequestBody Map<String, Long> request, Principal principal) {
        userService.unblockUser(principal.getName(), request.get("user_id"));
        return ResponseEntity.ok().build();
    }

    @GetMapping("/blocked")
    public ResponseEntity<?> getBlockedUsers(Principal principal) {
        return ResponseEntity.ok(userService.getBlockedUsers(principal.getName()));
    }

    // --- Reporting ---
    @PostMapping("/report")
    public ResponseEntity<?> reportUser(@RequestBody Map<String, Object> request, Principal principal) {
        Long targetUserId = ((Number) request.get("user_id")).longValue();
        String reason = (String) request.get("reason");
        userService.reportUser(principal.getName(), targetUserId, reason);
        return ResponseEntity.ok().build();
    }
}
