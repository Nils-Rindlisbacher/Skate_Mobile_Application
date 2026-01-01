package com.trick_manager.Trick_API.controller;

import com.trick_manager.Trick_API.entity.Trick;
import com.trick_manager.Trick_API.entity.User;
import com.trick_manager.Trick_API.service.TrickService;
import com.trick_manager.Trick_API.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

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
            @RequestParam(name = "search", required = false) String search,
            @RequestParam(name = "page", defaultValue = "0") int page,
            @RequestParam(name = "size", defaultValue = "20") int size,
            Principal principal) {

        Pageable pageable = PageRequest.of(page, size, Sort.by("id").ascending());

        if (principal == null) {
            Page<Map<String, Object>> result = trickService.getAllTricksWithFalseFlags(categoryId, search, pageable);
            return ResponseEntity.ok(result.getContent());
        }

        User user = userService.findByUsername(principal.getName())
                .orElseThrow(() -> new RuntimeException("User not found"));

        Page<Map<String, Object>> result = trickService.getTricksForUser(user.getId(), categoryId, search, pageable);
        return ResponseEntity.ok(result.getContent());
    }

    @GetMapping("/count")
    public Long getTrickCount() {
        return trickService.getTrickCount();
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
