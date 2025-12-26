package com.trick_manager.Trick_API.controller;

import com.trick_manager.Trick_API.entity.Trick;
import com.trick_manager.Trick_API.entity.User;
import com.trick_manager.Trick_API.service.TrickService;
import com.trick_manager.Trick_API.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/tricks")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class TrickController {

    @Autowired
    private TrickService trickService;

    @Autowired
    private UserService userService;

    @PostMapping
    public Trick createTrick(@RequestBody Trick trick) {
        return trickService.createTrick(trick);
    }

    @GetMapping
    public ResponseEntity<?> getAllTricks(
            @RequestParam(name = "category_id", required = false) Long categoryId,
            Principal principal) {

        if (principal == null) {
            return ResponseEntity.ok(trickService.getAllTricksWithFalseFlags(categoryId));
        }

        // Korrekter Aufruf über die injizierte Instanz 'userService'
        User user = userService.findByUsername(principal.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));

        return ResponseEntity.ok(trickService.getTricksForUser(user.getId(), categoryId));
    }

    @GetMapping("/{id}")
    public Trick getTrickById(@PathVariable Long id) {
        return trickService.getTrickById(id);
    }

    @PutMapping("/{id}")
    public Trick updateTrick(@PathVariable Long id, @RequestBody Trick trick) {
        return trickService.updateTrick(id, trick);
    }

    @DeleteMapping("/{id}")
    public void deleteTrick(@PathVariable Long id) {
        trickService.deleteTrick(id);
    }
}