package com.trick_manager.Trick_API.repository;

import com.trick_manager.Trick_API.entity.Trick;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Map;

public interface TrickRepository extends JpaRepository<Trick, Long> {

    @EntityGraph(attributePaths = {"category"})
    Page<Trick> findByCategoryId(Long categoryId, Pageable pageable);

    @EntityGraph(attributePaths = {"category"})
    Page<Trick> findAll(Pageable pageable);

    long countByCategoryId(Long categoryId);

    @Query(value = "SELECT t.id as id, t.name as name, t.category_id as category_id, ct.created_at as created_at, ct.stance as stance FROM tricks t " +
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
