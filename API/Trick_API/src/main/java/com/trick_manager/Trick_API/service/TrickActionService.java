package com.trick_manager.Trick_API.service;

import com.trick_manager.Trick_API.entity.CompletedTrick;
import com.trick_manager.Trick_API.entity.Stance;
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
    public void addToWishlist(Long userId, Long trickId, Stance stance) {
        Stance targetStance = (stance != null) ? stance : Stance.REGULAR;
        if (!wishlistRepository.existsByUserIdAndTrickIdAndStance(userId, trickId, targetStance)) {
            WishlistTrick item = new WishlistTrick();
            item.setUserId(userId);
            item.setTrickId(trickId);
            item.setStance(targetStance);
            wishlistRepository.save(item);
        }
    }

    @Transactional
    public void removeFromWishlist(Long userId, Long trickId, Stance stance) {
        Stance targetStance = (stance != null) ? stance : Stance.REGULAR;
        wishlistRepository.deleteByUserIdAndTrickIdAndStance(userId, trickId, targetStance);
    }

    @Transactional
    public void addToCompleted(Long userId, Long trickId, Stance stance) {
        Stance targetStance = (stance != null) ? stance : Stance.REGULAR;
        if (!completedRepository.existsByUserIdAndTrickIdAndStance(userId, trickId, targetStance)) {
            CompletedTrick item = new CompletedTrick();
            item.setUserId(userId);
            item.setTrickId(trickId);
            item.setStance(targetStance);
            completedRepository.save(item);
        }
    }

    @Transactional
    public void removeFromCompleted(Long userId, Long trickId, Stance stance) {
        Stance targetStance = (stance != null) ? stance : Stance.REGULAR;
        completedRepository.deleteByUserIdAndTrickIdAndStance(userId, trickId, targetStance);
    }
}
