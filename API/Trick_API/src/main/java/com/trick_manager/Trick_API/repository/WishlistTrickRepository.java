package com.trick_manager.Trick_API.repository;

import com.trick_manager.Trick_API.entity.WishlistTrick;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.transaction.annotation.Transactional;

public interface WishlistTrickRepository extends JpaRepository<WishlistTrick, Long> {
    boolean existsByUserIdAndTrickId(Long userId, Long trickId);
    
    @Transactional
    @Modifying
    void deleteByUserIdAndTrickId(Long userId, Long trickId);

    @Transactional
    @Modifying
    void deleteByUserId(Long userId);
}
