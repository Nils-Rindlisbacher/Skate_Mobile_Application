package com.trick_manager.Trick_API.repository;

import com.trick_manager.Trick_API.entity.SessionGoal;
import com.trick_manager.Trick_API.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface SessionGoalRepository extends JpaRepository<SessionGoal, Long> {
    List<SessionGoal> findByUserOrderByCreatedAtDesc(User user);
}
