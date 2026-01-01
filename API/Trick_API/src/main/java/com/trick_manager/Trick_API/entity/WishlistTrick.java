package com.trick_manager.Trick_API.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

@Entity
@Table(name = "wishlist_tricks", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"user_id", "trick_id", "stance"})
})
@Data
public class WishlistTrick {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "trick_id")
    private Long trickId;

    @Enumerated(EnumType.STRING)
    @Column(name = "stance", nullable = false)
    private Stance stance = Stance.REGULAR;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;
}
