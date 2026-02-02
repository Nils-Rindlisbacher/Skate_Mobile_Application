package com.trick_manager.Trick_API.service;

import com.trick_manager.Trick_API.entity.Media;
import com.trick_manager.Trick_API.repository.MediaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class MediaService {

    @Autowired
    private MediaRepository mediaRepository;

    public List<Media> getMediaByUserId(Long userId) {
        return mediaRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public Media addMedia(Media media) {
        return mediaRepository.save(media);
    }

    public void deleteMedia(Long id) {
        mediaRepository.deleteById(id);
    }
}
