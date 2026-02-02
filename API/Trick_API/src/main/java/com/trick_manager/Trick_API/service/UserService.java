package com.trick_manager.Trick_API.service;

import com.trick_manager.Trick_API.entity.User;
import com.trick_manager.Trick_API.repository.CompletedTrickRepository;
import com.trick_manager.Trick_API.repository.LeaderboardProjection;
import com.trick_manager.Trick_API.repository.UserRepository;
import com.trick_manager.Trick_API.repository.WishlistTrickRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
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
        
        completedTrickRepository.deleteByUserId(user.getId());
        wishlistTrickRepository.deleteByUserId(user.getId());
        userRepository.delete(user);
    }

    // --- Friends ---
    public void addFriend(String username, Long targetUserId) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.getFriendIds().add(targetUserId);
        userRepository.save(user);
    }

    public void unfriendUser(String username, Long targetUserId) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.getFriendIds().remove(targetUserId);
        userRepository.save(user);
    }

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

    // --- Blocking ---
    public void blockUser(String username, Long targetUserId) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.getBlockedIds().add(targetUserId);
        userRepository.save(user);
    }

    public void unblockUser(String username, Long targetUserId) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.getBlockedIds().remove(targetUserId);
        userRepository.save(user);
    }

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
