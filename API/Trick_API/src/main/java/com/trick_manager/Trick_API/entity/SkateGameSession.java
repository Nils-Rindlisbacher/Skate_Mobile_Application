package com.trick_manager.Trick_API.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "skate_game_sessions")
@Data
public class SkateGameSession {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String status; // WAITING, STARTING, ONGOING, FINISHED
    private Long currentTurnPlayerId;
    private String currentTrick;
    private boolean waitingForConfirmation;
    private Long trickSetterId;
    
    private LocalDateTime createdAt = LocalDateTime.now();
    private LocalDateTime updatedAt = LocalDateTime.now();

    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true)
    @JoinColumn(name = "session_id")
    private List<SkateGamePlayer> players = new ArrayList<>();
}
