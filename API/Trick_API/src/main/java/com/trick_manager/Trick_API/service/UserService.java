package com.trick_manager.Trick_API.service;

import com.trick_manager.Trick_API.entity.FriendRequest;
import com.trick_manager.Trick_API.entity.User;
import com.trick_manager.Trick_API.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CompletedTrickRepository completedTrickRepository;

    @Autowired
    private WishlistTrickRepository wishlistTrickRepository;

    @Autowired
    private EquipmentRepository equipmentRepository;

    @Autowired
    private MediaRepository mediaRepository;

    @Autowired
    private SessionGoalRepository sessionGoalRepository;

    @Autowired
    private SkatingSessionRepository skatingSessionRepository;

    @Autowired
    private FriendRequestRepository friendRequestRepository;

    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public User registerUser(User user) {
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        return userRepository.save(user);
    }

    public boolean validateUser(String username, String password) {
        Optional<User> userOpt = userRepository.findByUsername(username);
        return userOpt.isPresent() && passwordEncoder.matches(password, userOpt.get().getPassword());
    }

    public Optional<User> findByUsername(String username) {
        return userRepository.findByUsername(username);
    }

    public Optional<User> findById(Long id) {
        return userRepository.findById(id);
    }

    public List<LeaderboardProjection> getLeaderboardData(Long categoryId, String stance) {
        return userRepository.getLeaderboardData(categoryId, stance);
    }

    public void updateProfileImage(String username, String base64Image) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setProfileImage(base64Image);
        userRepository.save(user);
    }

    public void updatePrivacy(String username, boolean isPublic) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setPublic(isPublic);
        userRepository.save(user);
    }

    @Transactional
    public void deleteUser(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        Long userId = user.getId();
        
        try {
            completedTrickRepository.deleteByUserId(userId);
            wishlistTrickRepository.deleteByUserId(userId);
            equipmentRepository.deleteByUserId(userId);
            mediaRepository.deleteByUserId(userId);
            sessionGoalRepository.deleteByUserId(userId);
            skatingSessionRepository.deleteByUserId(userId);
        } catch (Exception e) {
            System.err.println("Error deleting linked data for user " + userId + ": " + e.getMessage());
        }
        
        userRepository.delete(user);
    }

    // --- Friend Request System (Expert Level) ---

    @Transactional
    public void sendFriendRequest(String senderUsername, Long receiverId) {
        User sender = userRepository.findByUsername(senderUsername)
                .orElseThrow(() -> new RuntimeException("Sender not found"));
        User receiver = userRepository.findById(receiverId)
                .orElseThrow(() -> new RuntimeException("Receiver not found"));

        if (sender.getId().equals(receiverId)) {
            throw new RuntimeException("You cannot add yourself as a friend");
        }

        if (sender.getFriendIds().contains(receiverId)) {
            throw new RuntimeException("Already friends");
        }

        Optional<FriendRequest> existingRequest = friendRequestRepository.findBySenderAndReceiver(sender, receiver);
        if (existingRequest.isPresent()) {
            throw new RuntimeException("Request already sent");
        }

        FriendRequest request = new FriendRequest();
        request.setSender(sender);
        request.setReceiver(receiver);
        request.setStatus("PENDING");
        friendRequestRepository.save(request);
    }

    @Transactional
    public void acceptFriendRequest(String username, Long requestId) {
        User receiver = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        FriendRequest request = friendRequestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Request not found"));

        if (!request.getReceiver().getId().equals(receiver.getId())) {
            throw new RuntimeException("Unauthorized to accept this request");
        }

        User sender = request.getSender();
        
        // Add to both sides for bidirectional friendship
        receiver.getFriendIds().add(sender.getId());
        sender.getFriendIds().add(receiver.getId());

        userRepository.save(receiver);
        userRepository.save(sender);

        request.setStatus("ACCEPTED");
        friendRequestRepository.save(request);
    }

    @Transactional
    public void declineFriendRequest(String username, Long requestId) {
        User receiver = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        FriendRequest request = friendRequestRepository.findById(requestId)
                .orElseThrow(() -> new RuntimeException("Request not found"));

        if (!request.getReceiver().getId().equals(receiver.getId()) && !request.getSender().getId().equals(receiver.getId())) {
            throw new RuntimeException("Unauthorized");
        }

        friendRequestRepository.delete(request);
    }

    @Transactional(readOnly = true)
    public List<FriendRequest> getPendingRequests(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return friendRequestRepository.findByReceiverAndStatus(user, "PENDING");
    }

    @Transactional(readOnly = true)
    public List<User> getFriends(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return user.getFriendIds().stream()
                .map(userRepository::findById)
                .filter(Optional::isPresent)
                .map(Optional::get)
                .map(u -> {
                    u.setPassword(null);
                    return u;
                })
                .collect(Collectors.toList());
    }

    @Transactional
    public void unfriendUser(String username, Long targetUserId) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        User target = userRepository.findById(targetUserId)
                .orElseThrow(() -> new RuntimeException("Target user not found"));

        user.getFriendIds().remove(targetUserId);
        target.getFriendIds().remove(user.getId());

        userRepository.save(user);
        userRepository.save(target);

        // Also clean up any accepted requests
        friendRequestRepository.findBySenderAndReceiver(user, target).ifPresent(friendRequestRepository::delete);
        friendRequestRepository.findBySenderAndReceiver(target, user).ifPresent(friendRequestRepository::delete);
    }

    // --- Blocking ---
    @Transactional
    public void blockUser(String username, Long targetUserId) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.getBlockedIds().add(targetUserId);
        userRepository.save(user);
    }

    @Transactional
    public void unblockUser(String username, Long targetUserId) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.getBlockedIds().remove(targetUserId);
        userRepository.save(user);
    }

    @Transactional(readOnly = true)
    public List<User> getBlockedUsers(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return user.getBlockedIds().stream()
                .map(userRepository::findById)
                .filter(Optional::isPresent)
                .map(Optional::get)
                .map(u -> {
                    u.setPassword(null);
                    return u;
                })
                .collect(Collectors.toList());
    }

    // --- Reporting ---
    public void reportUser(String reporterUsername, Long targetUserId, String reason) {
        System.out.println("USER REPORTED: " + reporterUsername + " reported user " + targetUserId + " for: " + reason);
    }
}
