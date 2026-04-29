package com.trick_manager.Trick_API.repository;

import com.trick_manager.Trick_API.entity.SessionGoal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Repository
public interface SessionGoalRepository extends JpaRepository<SessionGoal, Long> {
    List<SessionGoal> findByUserId(Long userId);

    @Transactional
    @Modifying
    void deleteByUserId(Long userId);
}
