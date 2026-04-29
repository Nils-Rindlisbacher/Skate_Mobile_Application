package com.trick_manager.Trick_API.repository;

import com.trick_manager.Trick_API.entity.Media;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Repository
public interface MediaRepository extends JpaRepository<Media, Long> {
    List<Media> findByUserIdOrderByCreatedAtDesc(Long userId);

    @Transactional
    @Modifying
    void deleteByUserId(Long userId);
}
