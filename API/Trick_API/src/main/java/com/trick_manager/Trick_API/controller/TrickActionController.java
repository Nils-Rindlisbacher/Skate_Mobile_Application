package com.trick_manager.Trick_API.controller;

import com.trick_manager.Trick_API.dto.TrickActionRequest;
import com.trick_manager.Trick_API.entity.Trick;
import com.trick_manager.Trick_API.service.TrickActionService;
import com.trick_manager.Trick_API.repository.UserRepository;
import com.trick_manager.Trick_API.entity.User;
import com.trick_manager.Trick_API.service.TrickService;
import com.trick_manager.Trick_API.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class TrickActionController {

    @Autowired
    private TrickActionService trickActionService;
    @Autowired
    private UserService userService;
    @Autowired
    private TrickService trickService;

    @Autowired
    private UserRepository userRepository;

    private Long getCurrentUserId(Principal principal) {
        return userRepository.findByUsername(principal.getName())
                .orElseThrow(() -> new RuntimeException("Benutzer nicht gefunden"))
                .getId();
    }

    @GetMapping("/wishlist")
    public ResponseEntity<List<Trick>> getWishlistTricks(Principal principal) {
        User user = userService.findByUsername(principal.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));
        return ResponseEntity.ok(trickService.getWishlistTricksForUser(user.getId()));
    }

    @PostMapping("/wishlist/add")
    public ResponseEntity<?> addToWishlist(@RequestBody TrickActionRequest request, Principal principal) {
        trickActionService.addToWishlist(getCurrentUserId(principal), request.getTrick_id());
        return ResponseEntity.ok().build();
    }

    @PostMapping("/wishlist/remove")
    public ResponseEntity<?> removeFromWishlist(@RequestBody TrickActionRequest request, Principal principal) {
        trickActionService.removeFromWishlist(getCurrentUserId(principal), request.getTrick_id());
        return ResponseEntity.ok().build();
    }

    @GetMapping("/completed")
    public ResponseEntity<List<Map<String, Object>>> getCompletedTricks(Principal principal) {
        User user = userService.findByUsername(principal.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));

        return ResponseEntity.ok(trickService.getCompletedTricksWithTimestamps(user.getId()));
    }

    @PostMapping("/completed/add")
    public ResponseEntity<?> addToCompleted(@RequestBody TrickActionRequest request, Principal principal) {
        trickActionService.addToCompleted(getCurrentUserId(principal), request.getTrick_id());
        return ResponseEntity.ok().build();
    }

    @PostMapping("/completed/remove")
    public ResponseEntity<?> removeFromCompleted(@RequestBody TrickActionRequest request, Principal principal) {
        trickActionService.removeFromCompleted(getCurrentUserId(principal), request.getTrick_id());
        return ResponseEntity.ok().build();
    }
}
