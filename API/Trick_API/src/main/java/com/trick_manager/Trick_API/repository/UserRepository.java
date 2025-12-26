package com.trick_manager.Trick_API.repository;

import com.trick_manager.Trick_API.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);

    @Query(value = "SELECT u.id as id, u.name as name, u.username as username, " +
            "u.profile_image as profile_image, " +
            "(SELECT COUNT(*) FROM completed_tricks ct " +
            " JOIN tricks t ON ct.trick_id = t.id " +
            " WHERE ct.user_id = u.id AND (:category_id IS NULL OR t.category_id = :category_id)) as completedCount " +
            "FROM users u " +
            "ORDER BY completedCount DESC", nativeQuery = true)
    List<LeaderboardProjection> getLeaderboardData(@Param("category_id") Long categoryId);
}
