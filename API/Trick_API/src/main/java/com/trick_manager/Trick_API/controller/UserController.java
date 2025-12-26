package com.trick_manager.Trick_API.controller;

import com.trick_manager.Trick_API.entity.User;
import com.trick_manager.Trick_API.repository.LeaderboardProjection;
import com.trick_manager.Trick_API.repository.UserRepository;
import com.trick_manager.Trick_API.service.UserService;
import com.trick_manager.Trick_API.config.JwtUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
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
                    user.setPassword(null);
                    return ResponseEntity.ok(user);
                })
                .orElse(ResponseEntity.status(404).build());
    }

    @PostMapping("/me/image")
    public ResponseEntity<?> updateProfileImage(@RequestBody Map<String, String> request, Principal principal) {
        String base64Image = request.get("image");
        if (base64Image == null) return ResponseEntity.badRequest().build();

        userService.updateProfileImage(principal.getName(), base64Image);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/leaderboard")
    public ResponseEntity<List<LeaderboardProjection>> getLeaderboard(
            @RequestParam(name = "category_id", required = false) Long categoryId) {
        return ResponseEntity.ok(userService.getLeaderboardData(categoryId));
    }
}
