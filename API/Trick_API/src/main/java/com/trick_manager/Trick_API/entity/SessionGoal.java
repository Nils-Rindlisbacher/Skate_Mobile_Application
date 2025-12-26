package com.trick_manager.Trick_API.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "session_goals")
@Data
public class SessionGoal {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    @JsonIgnore
    private User user;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false)
    private String type; // "text" or "trick"

    @Column(name = "trick_id")
    private Long trickId;

    @Column(name = "target_count")
    private Integer targetCount;

    @Column(name = "current_count")
    private Integer currentCount = 0;

    @Column(name = "timer_duration")
    private Long timerDuration; // in seconds

    @Column(name = "remaining_time")
    private Long remainingTime; // in seconds

    @JsonProperty("completed")
    @Column(name = "is_completed")
    private boolean isCompleted = false;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();
}
