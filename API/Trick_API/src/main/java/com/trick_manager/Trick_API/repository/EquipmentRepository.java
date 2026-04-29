package com.trick_manager.Trick_API.repository;

import com.trick_manager.Trick_API.entity.Equipment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Repository
public interface EquipmentRepository extends JpaRepository<Equipment, Long> {
    List<Equipment> findByUserId(Long userId);
    List<Equipment> findByUserIdAndIsActive(Long userId, boolean isActive);

    @Transactional
    @Modifying
    void deleteByUserId(Long userId);
}
