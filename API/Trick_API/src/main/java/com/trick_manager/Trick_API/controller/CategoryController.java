package com.trick_manager.Trick_API.controller;

import com.trick_manager.Trick_API.entity.Category;
import com.trick_manager.Trick_API.entity.User;
import com.trick_manager.Trick_API.repository.CategoryRepository;
import com.trick_manager.Trick_API.service.CategoryService;
import com.trick_manager.Trick_API.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/categories")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class CategoryController {

    @Autowired
    private CategoryRepository repository;

    @Autowired
    private UserService userService;
    @Autowired
    private CategoryService categoryService;

    // Get all categories
    @GetMapping
    public List<Category> getAll() {
        return repository.findAll();
    }

    // Get category by ID
    @GetMapping("/{id}")
    public ResponseEntity<Category> getById(@PathVariable Long id) {
        Optional<Category> category = repository.findById(id);
        return category.map(ResponseEntity::ok).orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping("/stats")
    public ResponseEntity<?> getCategoryStats(
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
            targetUserId = userService.findByUsername(principal.getName())
                    .orElseThrow()
                    .getId();
        }

        return ResponseEntity.ok(categoryService.getCategoryStatsForUser(targetUserId));
    }

    // Create new category
    @PostMapping
    public Category create(@RequestBody Category category) {
        return repository.save(category);
    }

    // Update category
    @PutMapping("/{id}")
    public ResponseEntity<Category> update(@PathVariable Long id, @RequestBody Category categoryDetails) {
        return repository.findById(id).map(category -> {
            category.setName(categoryDetails.getName());
            Category updated = repository.save(category);
            return ResponseEntity.ok(updated);
        }).orElseGet(() -> ResponseEntity.notFound().build());
    }

    // Delete category
    @DeleteMapping("/{id}")
    public ResponseEntity<Object> delete(@PathVariable Long id) {
        return repository.findById(id).map(category -> {
            repository.delete(category);
            return ResponseEntity.noContent().build();
        }).orElseGet(() -> ResponseEntity.notFound().build());
    }
}
