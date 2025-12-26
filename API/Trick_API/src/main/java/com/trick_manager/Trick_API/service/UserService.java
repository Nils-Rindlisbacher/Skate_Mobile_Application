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

import java.util.List;
import java.util.Optional;

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

    public List<LeaderboardProjection> getLeaderboardData(Long categoryId) {
        return userRepository.getLeaderboardData(categoryId);
    }

    public void updateProfileImage(String username, String base64Image) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setProfileImage(base64Image);
        userRepository.save(user);
    }

    @Transactional
    public void deleteUser(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Delete related data first
        completedTrickRepository.deleteByUserId(user.getId());
        wishlistTrickRepository.deleteByUserId(user.getId());
        
        // Delete the user
        userRepository.delete(user);
    }
}
