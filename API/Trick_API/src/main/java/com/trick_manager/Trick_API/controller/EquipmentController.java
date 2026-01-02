package com.trick_manager.Trick_API.controller;

import com.trick_manager.Trick_API.entity.Equipment;
import com.trick_manager.Trick_API.entity.User;
import com.trick_manager.Trick_API.repository.EquipmentRepository;
import com.trick_manager.Trick_API.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/equipment")
public class EquipmentController {

    @Autowired
    private EquipmentRepository equipmentRepository;

    @Autowired
    private UserRepository userRepository;

    private User getCurrentUser() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    @GetMapping
    public List<Equipment> getAllEquipment() {
        User user = getCurrentUser();
        return equipmentRepository.findByUserId(user.getId());
    }

    @GetMapping("/active")
    public List<Equipment> getActiveEquipment() {
        User user = getCurrentUser();
        return equipmentRepository.findByUserIdAndIsActive(user.getId(), true);
    }

    @PostMapping
    public Equipment addEquipment(@RequestBody Equipment equipment) {
        User user = getCurrentUser();
        equipment.setUserId(user.getId());
        return equipmentRepository.save(equipment);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Equipment> updateEquipment(@PathVariable Long id, @RequestBody Equipment equipmentDetails) {
        User user = getCurrentUser();
        Equipment equipment = equipmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Equipment not found"));

        if (!equipment.getUserId().equals(user.getId())) {
            return ResponseEntity.status(403).build();
        }

        equipment.setName(equipmentDetails.getName());
        equipment.setType(equipmentDetails.getType());
        equipment.setBrand(equipmentDetails.getBrand());
        equipment.setModel(equipmentDetails.getModel());
        equipment.setSize(equipmentDetails.getSize());
        equipment.setNotes(equipmentDetails.getNotes());
        equipment.setSetupDate(equipmentDetails.getSetupDate());
        equipment.setActive(equipmentDetails.isActive());

        return ResponseEntity.ok(equipmentRepository.save(equipment));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteEquipment(@PathVariable Long id) {
        User user = getCurrentUser();
        Equipment equipment = equipmentRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Equipment not found"));

        if (!equipment.getUserId().equals(user.getId())) {
            return ResponseEntity.status(403).build();
        }

        equipmentRepository.delete(equipment);
        return ResponseEntity.ok().build();
    }
}
