package com.trick_manager.Trick_API.repository;

import com.trick_manager.Trick_API.entity.FriendRequest;
import com.trick_manager.Trick_API.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FriendRequestRepository extends JpaRepository<FriendRequest, Long> {
    List<FriendRequest> findByReceiverAndStatus(User receiver, String status);
    List<FriendRequest> findBySenderAndStatus(User sender, String status);
    Optional<FriendRequest> findBySenderAndReceiver(User sender, User receiver);
}
