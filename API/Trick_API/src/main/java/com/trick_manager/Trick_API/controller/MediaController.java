package com.trick_manager.Trick_API.controller;

import com.trick_manager.Trick_API.entity.Media;
import com.trick_manager.Trick_API.service.MediaService;
import com.trick_manager.Trick_API.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/media")
@CrossOrigin(origins = "*")
public class MediaController {

    @Autowired
    private MediaService mediaService;

    @Autowired
    private UserService userService;

    @GetMapping
    public ResponseEntity<List<Media>> getMyMedia(Principal principal) {
        Long userId = userService.findByUsername(principal.getName()).get().getId();
        return ResponseEntity.ok(mediaService.getMediaByUserId(userId));
    }

    @PostMapping
    public ResponseEntity<Media> addMedia(@RequestBody Media media, Principal principal) {
        Long userId = userService.findByUsername(principal.getName()).get().getId();
        media.setUserId(userId);
        return ResponseEntity.ok(mediaService.addMedia(media));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteMedia(@PathVariable Long id) {
        mediaService.deleteMedia(id);
        return ResponseEntity.ok().build();
    }
}
