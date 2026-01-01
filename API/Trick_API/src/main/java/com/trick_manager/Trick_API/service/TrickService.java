package com.trick_manager.Trick_API.service;

import com.trick_manager.Trick_API.entity.CompletedTrick;
import com.trick_manager.Trick_API.entity.Stance;
import com.trick_manager.Trick_API.entity.Trick;
import com.trick_manager.Trick_API.entity.WishlistTrick;
import com.trick_manager.Trick_API.repository.CompletedTrickRepository;
import com.trick_manager.Trick_API.repository.TrickRepository;
import com.trick_manager.Trick_API.repository.WishlistTrickRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class TrickService {

    @Autowired
    private TrickRepository trickRepository;

    @Autowired
    private CompletedTrickRepository completedRepository;

    @Autowired
    private WishlistTrickRepository wishlistRepository;

    public Page<Map<String, Object>> getTricksForUser(Long userId, Long categoryId, Pageable pageable) {
        Page<Trick> trickPage = (categoryId == null)
                ? trickRepository.findAll(pageable)
                : trickRepository.findByCategoryId(categoryId, pageable);

        List<Long> trickIds = trickPage.getContent().stream().map(Trick::getId).collect(Collectors.toList());
        
        List<CompletedTrick> userCompleted = completedRepository.findByUserIdAndTrickIdIn(userId, trickIds);
        List<WishlistTrick> userWishlist = wishlistRepository.findByUserIdAndTrickIdIn(userId, trickIds);

        Set<String> completedLookup = userCompleted.stream()
                .map(c -> c.getTrickId() + "_" + c.getStance().name())
                .collect(Collectors.toSet());

        Set<String> wishlistLookup = userWishlist.stream()
                .map(w -> w.getTrickId() + "_" + w.getStance().name())
                .collect(Collectors.toSet());

        return trickPage.map(trick -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", trick.getId());
            map.put("name", trick.getName());
            map.put("category_id", trick.getCategory().getId());
            map.put("type", trick.getCategory().getName());
            
            Map<String, Map<String, Boolean>> stanceMap = new HashMap<>();
            for (Stance s : Stance.values()) {
                String key = trick.getId() + "_" + s.name();
                Map<String, Boolean> status = new HashMap<>();
                status.put("completed", completedLookup.contains(key));
                status.put("wishlisted", wishlistLookup.contains(key));
                stanceMap.put(s.name(), status);
            }
            map.put("stances", stanceMap);
            return map;
        });
    }

    public Page<Map<String, Object>> getAllTricksWithFalseFlags(Long categoryId, Pageable pageable) {
        Page<Trick> trickPage = (categoryId == null)
                ? trickRepository.findAll(pageable)
                : trickRepository.findByCategoryId(categoryId, pageable);

        return trickPage.map(trick -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", trick.getId());
            map.put("name", trick.getName());
            map.put("category_id", trick.getCategory().getId());
            map.put("type", trick.getCategory().getName());
            
            Map<String, Map<String, Boolean>> stanceMap = new HashMap<>();
            for (Stance s : Stance.values()) {
                Map<String, Boolean> status = new HashMap<>();
                status.put("completed", false);
                status.put("wishlisted", false);
                stanceMap.put(s.name(), status);
            }
            map.put("stances", stanceMap);
            return map;
        });
    }

    public List<Trick> getAllTricks() {
        return trickRepository.findAll();
    }

    public Long getTrickCount() {
        return trickRepository.count();
    }

    public Trick getTrickById(Long id) {
        return trickRepository.findById(id).orElse(null);
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
