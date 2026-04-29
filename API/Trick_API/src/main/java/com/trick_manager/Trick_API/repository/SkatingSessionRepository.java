package com.trick_manager.Trick_API.repository;

import com.trick_manager.Trick_API.entity.SkatingSession;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.Optional;
import java.time.LocalDate;

@Repository
public interface SkatingSessionRepository extends JpaRepository<SkatingSession, Long> {
    List<SkatingSession> findByUserId(Long userId);
    Optional<SkatingSession> findByUserIdAndSessionDate(Long userId, LocalDate sessionDate);

    @Transactional
    @Modifying
    void deleteByUserId(Long userId);
}
