package com.trick_manager.Trick_API.repository;

import com.trick_manager.Trick_API.entity.Equipment;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface EquipmentRepository extends JpaRepository<Equipment, Long> {
    List<Equipment> findByUserId(Long userId);
    List<Equipment> findByUserIdAndIsActive(Long userId, boolean isActive);
}
