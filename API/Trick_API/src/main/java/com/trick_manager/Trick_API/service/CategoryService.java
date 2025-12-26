package com.trick_manager.Trick_API.service;

import com.trick_manager.Trick_API.entity.Category;
import com.trick_manager.Trick_API.repository.CategoryRepository;
import com.trick_manager.Trick_API.repository.CompletedTrickRepository;
import com.trick_manager.Trick_API.repository.TrickRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class CategoryService {

    @Autowired
    private CategoryRepository categoryRepository;
    @Autowired
    private TrickRepository trickRepository;
    @Autowired
    private CompletedTrickRepository completedTrickRepository;

    public Category createCategory(Category category) {
        return categoryRepository.save(category);
    }

    public List<Category> getAllCategories() {
        return categoryRepository.findAll();
    }

    public Category getCategoryById(Long id) {
        return categoryRepository.findById(id).orElse(null);
    }

    public List<Map<String, Object>> getCategoryStatsForUser(Long userId) {
        List<Category> categories = categoryRepository.findAll();

        return categories.stream().map(cat -> {
            Map<String, Object> stats = new HashMap<>();
            stats.put("id", cat.getId());
            stats.put("name", cat.getName());

            // Count all tricks in this category
            stats.put("totalTricks", trickRepository.countByCategoryId(cat.getId()));

            // Count tricks completed by the user in this category
            // You'll need to add this method to your CompletedTrickRepository
            stats.put("completedTricks", completedTrickRepository.countByUserIdAndTrickCategoryId(userId, cat.getId()));

            return stats;
        }).collect(Collectors.toList());
    }

    public Category updateCategory(Long id, Category category) {
        category.setId(id);
        return categoryRepository.save(category);
    }

    public void deleteCategory(Long id) {
        categoryRepository.deleteById(id);
    }
}