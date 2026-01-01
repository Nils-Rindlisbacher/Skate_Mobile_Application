package com.trick_manager.Trick_API.repository;

import com.trick_manager.Trick_API.entity.Stance;
import com.trick_manager.Trick_API.entity.WishlistTrick;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

public interface WishlistTrickRepository extends JpaRepository<WishlistTrick, Long> {
    boolean existsByUserIdAndTrickIdAndStance(Long userId, Long trickId, Stance stance);
    
    @Transactional
    @Modifying
    void deleteByUserIdAndTrickIdAndStance(Long userId, Long trickId, Stance stance);

    @Transactional
    @Modifying
    void deleteByUserId(Long userId);

    List<WishlistTrick> findByUserId(Long userId);

    List<WishlistTrick> findByUserIdAndTrickIdIn(Long userId, List<Long> trickIds);
}
