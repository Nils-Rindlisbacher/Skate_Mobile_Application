package com.trick_manager.Trick_API.repository;

import com.trick_manager.Trick_API.entity.SkatingSession;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.time.LocalDate;

public interface SkatingSessionRepository extends JpaRepository<SkatingSession, Long> {
    List<SkatingSession> findByUserId(Long userId);
    Optional<SkatingSession> findByUserIdAndSessionDate(Long userId, LocalDate sessionDate);
}
