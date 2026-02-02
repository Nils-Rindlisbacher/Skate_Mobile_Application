package com.trick_manager.Trick_API.repository;

import com.trick_manager.Trick_API.entity.Media;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface MediaRepository extends JpaRepository<Media, Long> {
    List<Media> findByUserIdOrderByCreatedAtDesc(Long userId);
    void deleteByUserId(Long userId);
}
