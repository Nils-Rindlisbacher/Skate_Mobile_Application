package com.trick_manager.Trick_API.service;

import com.trick_manager.Trick_API.entity.CompletedTrick;
import com.trick_manager.Trick_API.entity.WishlistTrick;
import com.trick_manager.Trick_API.repository.CompletedTrickRepository;
import com.trick_manager.Trick_API.repository.WishlistTrickRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TrickActionService {

    @Autowired
    private WishlistTrickRepository wishlistRepository;

    @Autowired
    private CompletedTrickRepository completedRepository;

    @Transactional
    public void addToWishlist(Long userId, Long trickId) {
        if (!wishlistRepository.existsByUserIdAndTrickId(userId, trickId)) {
            WishlistTrick item = new WishlistTrick();
            item.setUserId(userId);
            item.setTrickId(trickId);
            wishlistRepository.save(item);
        }
    }

    @Transactional
    public void removeFromWishlist(Long userId, Long trickId) {
        wishlistRepository.deleteByUserIdAndTrickId(userId, trickId);
    }

    @Transactional
    public void addToCompleted(Long userId, Long trickId) {
        if (!completedRepository.existsByUserIdAndTrickId(userId, trickId)) {
            CompletedTrick item = new CompletedTrick();
            item.setUserId(userId);
            item.setTrickId(trickId);
            completedRepository.save(item);
        }
    }

    @Transactional
    public void removeFromCompleted(Long userId, Long trickId) {
        completedRepository.deleteByUserIdAndTrickId(userId, trickId);
    }
}