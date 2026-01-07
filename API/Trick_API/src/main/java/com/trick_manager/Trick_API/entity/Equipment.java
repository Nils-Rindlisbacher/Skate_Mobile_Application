package com.trick_manager.Trick_API.entity;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;

@Entity
@Table(name = "equipment")
@Data
public class Equipment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String type; // e.g., DECK, TRUCKS, WHEELS, BEARINGS

    private String brand;
    private String model;
    private String size;
    private String notes;

    @Column(name = "setup_date")
    private LocalDate setupDate;

    @Column(name = "is_active", nullable = false)
    @JsonProperty("is_active")
    private boolean isActive = true;

    private Double price;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false)
    private User user;
}
