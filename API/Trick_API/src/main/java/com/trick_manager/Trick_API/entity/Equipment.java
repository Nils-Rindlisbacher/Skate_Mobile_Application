package com.trick_manager.Trick_API.entity;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Entity
@Table(name = "equipment")
@Data
@NoArgsConstructor
public class Equipment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(nullable = false)
    @JsonProperty("name")
    private String name;

    @Column(nullable = false)
    @JsonProperty("type")
    private String type; 

    @Column(name = "brand")
    @JsonProperty("brand")
    private String brand;

    @Column(name = "model")
    @JsonProperty("model")
    private String model;

    @Column(name = "size")
    @JsonProperty("size")
    private String size;

    @Column(name = "notes")
    @JsonProperty("notes")
    private String notes;

    @Column(name = "setup_date")
    @JsonProperty("setup_date")
    private LocalDate setupDate;

    @Column(name = "is_active", nullable = false)
    @JsonProperty("is_active")
    private boolean active = true;

    @JsonProperty("price")
    private Double price;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false)
    private User user;

    @JsonProperty("is_active")
    public boolean getIsActive() {
        return active;
    }

    @JsonProperty("is_active")
    public void setIsActive(boolean active) {
        this.active = active;
    }
}
