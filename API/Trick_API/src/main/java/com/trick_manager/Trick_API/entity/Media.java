package com.trick_manager.Trick_API.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_media")
@Data
public class Media {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String path;

    private String trickName;

    @Column(columnDefinition = "TEXT")
    private String note;

    private boolean isVideo = false;

    private LocalDateTime createdAt = LocalDateTime.now();
}
