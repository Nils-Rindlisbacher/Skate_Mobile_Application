package com.trick_manager.Trick_API.repository;

import com.trick_manager.Trick_API.entity.Trick;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Map;

public interface TrickRepository extends JpaRepository<Trick, Long> {

    List<Trick> findByCategoryId(Long categoryId);

    long countByCategoryId(Long categoryId);

    @Query(value = "SELECT t.*, ct.created_at FROM tricks t " +
            "JOIN completed_tricks ct ON t.id = ct.trick_id " +
            "WHERE ct.user_id = :userId",
            nativeQuery = true)
    List<Map<String, Object>> findCompletedTricksByUserIdWithTimestamp(@Param("userId") Long userId);

    @Query(value = "SELECT t.* FROM tricks t " +
            "JOIN completed_tricks ct ON t.id = ct.trick_id " +
            "WHERE ct.user_id = :userId",
            nativeQuery = true)
    List<Trick> findCompletedTricksByUserId(@Param("userId") Long userId);

    @Query(value = "SELECT t.* FROM tricks t " +
            "JOIN wishlist_tricks wt ON t.id = wt.trick_id " +
            "WHERE wt.user_id = :userId",
            nativeQuery = true)
    List<Trick> findWishlistTricksByUserId(@Param("userId") Long userId);
}
