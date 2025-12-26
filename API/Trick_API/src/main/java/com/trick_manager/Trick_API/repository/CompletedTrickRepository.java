package com.trick_manager.Trick_API.repository;

import com.trick_manager.Trick_API.entity.CompletedTrick;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository 
public interface CompletedTrickRepository extends JpaRepository<CompletedTrick, Long> {
    boolean existsByUserIdAndTrickId(Long userId, Long trickId);
    
    @Transactional
    @Modifying
    void deleteByUserIdAndTrickId(Long userId, Long trickId);

    @Transactional
    @Modifying
    void deleteByUserId(Long userId);

    @Query(value = "SELECT COUNT(ct.id) FROM completed_tricks ct " +
            "JOIN tricks t ON ct.trick_id = t.id " +
            "WHERE ct.user_id = :userId AND t.category_id = :categoryId",
            nativeQuery = true)
    long countByUserIdAndTrickCategoryId(@Param("userId") Long userId, @Param("categoryId") Long categoryId);
}
