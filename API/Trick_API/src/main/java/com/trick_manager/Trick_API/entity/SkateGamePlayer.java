package com.trick_manager.Trick_API.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "skate_game_players")
@Data
public class SkateGamePlayer {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long userId;
    private String username;
    private int score; // 0 to 5 (S-K-A-T-E)
    private boolean joined = false;
    private Integer turnOrder;
    private String coinChoice; // HEADS or TAILS
    
    @Column(name = "is_ready")
    private boolean ready = false;
}
