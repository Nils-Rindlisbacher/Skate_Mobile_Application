package com.trick_manager.Trick_API.entity;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import lombok.Data;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "users")
@Data
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(unique = true, nullable = false)
    private String username;

    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    @Column(nullable = false)
    private String password;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(name = "profile_image", columnDefinition = "TEXT")
    private String profileImage;

    @Column(name = "is_public", nullable = false)
    @JsonProperty("is_public")
    private boolean isPublic = true;

    @Column(name = "skate_wins")
    private int skateWins = 0;

    @Column(name = "skate_losses")
    private int skateLosses = 0;

    @ElementCollection
    @CollectionTable(name = "user_friends", joinColumns = @JoinColumn(name = "user_id"))
    @Column(name = "friend_user_id")
    private Set<Long> friendIds = new HashSet<>();

    @ElementCollection
    @CollectionTable(name = "user_blocked", joinColumns = @JoinColumn(name = "user_id"))
    @Column(name = "blocked_user_id")
    private Set<Long> blockedIds = new HashSet<>();
}
