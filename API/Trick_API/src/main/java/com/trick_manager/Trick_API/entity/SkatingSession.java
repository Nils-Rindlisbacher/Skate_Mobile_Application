package com.trick_manager.Trick_API.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;

@Entity
@Table(name = "skating_sessions", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"user_id", "session_date"})
})
@Data
public class SkatingSession {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", insertable = false, updatable = false)
    @JsonIgnore
    private User user;

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "session_date", nullable = false)
    private LocalDate sessionDate = LocalDate.now();

    @Column(nullable = false)
    private String mood; // GREAT, OK, BAD, INJURED
}
