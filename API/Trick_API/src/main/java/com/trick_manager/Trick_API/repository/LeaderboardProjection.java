package com.trick_manager.Trick_API.repository;

public interface LeaderboardProjection {
    Long getId();
    String getName();
    String getUsername();
    String getProfile_image(); // This matches entry['profile_image'] in Flutter
    Long getCompletedCount();
}