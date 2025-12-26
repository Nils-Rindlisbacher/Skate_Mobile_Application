package com.trick_manager.Trick_API.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;

@Entity
@Table(name = "tricks")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Trick {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id", nullable = false)
    private Category category;

    // Constructors
    public Trick() {
    }

    public Trick(String name, Category category) {
        this.name = name;
        this.category = category;
    }

    // Getters
    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public Category getCategory() {
        return category;
    }

    // Setters
    public void setId(Long id) {
        this.id = id;
    }

    public void setName(String name) {
        this.name = name;
    }

    public void setCategory(Category category) {
        this.category = category;
    }
}
