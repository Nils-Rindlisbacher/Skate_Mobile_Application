package com.trick_manager.Trick_API.repository;

import com.trick_manager.Trick_API.entity.CompletedTrick;
import com.trick_manager.Trick_API.entity.Stance;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Repository 
public interface CompletedTrickRepository extends JpaRepository<CompletedTrick, Long> {
    boolean existsByUserIdAndTrickIdAndStance(Long userId, Long trickId, Stance stance);
    
    @Transactional
    @Modifying
    void deleteByUserIdAndTrickIdAndStance(Long userId, Long trickId, Stance stance);

    @Transactional
    @Modifying
    void deleteByUserId(Long userId);

    @Query(value = "SELECT COUNT(ct.id) FROM completed_tricks ct " +
            "JOIN tricks t ON ct.trick_id = t.id " +
            "WHERE ct.user_id = :userId AND t.category_id = :categoryId",
            nativeQuery = true)
    long countByUserIdAndTrickCategoryId(@Param("userId") Long userId, @Param("categoryId") Long categoryId);

    List<CompletedTrick> findByUserId(Long userId);

    List<CompletedTrick> findByUserIdAndTrickIdIn(Long userId, List<Long> trickIds);
}
