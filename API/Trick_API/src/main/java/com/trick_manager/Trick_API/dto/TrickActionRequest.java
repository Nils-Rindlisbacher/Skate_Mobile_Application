package com.trick_manager.Trick_API.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.trick_manager.Trick_API.entity.Stance;
import lombok.Data;

@Data
public class TrickActionRequest {
    @JsonProperty("trick_id")
    private Long trickId;

    @JsonProperty("stance")
    private Stance stance;
}