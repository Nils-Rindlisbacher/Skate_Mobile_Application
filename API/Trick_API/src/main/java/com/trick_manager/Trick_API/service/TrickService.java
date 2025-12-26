package com.trick_manager.Trick_API.service;

import com.trick_manager.Trick_API.entity.Trick;
import com.trick_manager.Trick_API.repository.CompletedTrickRepository;
import com.trick_manager.Trick_API.repository.TrickRepository;
import com.trick_manager.Trick_API.repository.WishlistTrickRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class TrickService {

    @Autowired
    private TrickRepository trickRepository;

    @Autowired
    private CompletedTrickRepository completedRepository;

    @Autowired
    private WishlistTrickRepository wishlistRepository;

    public List<Map<String, Object>> getTricksForUser(Long userId, Long categoryId) {
        List<Trick> tricks = (categoryId == null)
                ? trickRepository.findAll()
                : trickRepository.findByCategoryId(categoryId);

        return tricks.stream().map(trick -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", trick.getId());
            map.put("name", trick.getName());
            map.put("completed", completedRepository.existsByUserIdAndTrickId(userId, trick.getId()));
            map.put("wishlisted", wishlistRepository.existsByUserIdAndTrickId(userId, trick.getId()));
            return map;
        }).collect(Collectors.toList());
    }

    public List<Map<String, Object>> getAllTricksWithFalseFlags(Long categoryId) {
        List<Trick> tricks = (categoryId == null)
                ? trickRepository.findAll()
                : trickRepository.findByCategoryId(categoryId);

        return tricks.stream().map(trick -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", trick.getId());
            map.put("name", trick.getName());
            map.put("completed", false);
            map.put("wishlisted", false);
            return map;
        }).collect(Collectors.toList());
    }

    public List<Trick> getAllTricks() {
        return trickRepository.findAll();
    }

    public Trick getTrickById(Long id) {
        return trickRepository.findById(id).orElse(null);
    }

    public List<Trick> getTricksByCategoryId(Long categoryId) {
        return trickRepository.findByCategoryId(categoryId);
    }

    public Trick createTrick(Trick trick) {
        return trickRepository.save(trick);
    }

    public Trick updateTrick(Long id, Trick trick) {
        trick.setId(id);
        return trickRepository.save(trick);
    }

    public void deleteTrick(Long id) {
        trickRepository.deleteById(id);
    }

    public List<Trick> getWishlistTricksForUser(Long userId) {
        return trickRepository.findWishlistTricksByUserId(userId);
    }

    public List<Trick> getCompletedTricksForUser(Long userId) {
        return trickRepository.findCompletedTricksByUserId(userId);
    }

    public List<Map<String, Object>> getCompletedTricksWithTimestamps(Long userId) {
        return trickRepository.findCompletedTricksByUserIdWithTimestamp(userId);
    }
}
