package com.trick_manager.Trick_API.dto;

import lombok.Data;

@Data
public class TrickActionRequest {
    // This MUST match the name sent from Flutter: jsonEncode({'trick_id': trickId})
    private Long trick_id;
}