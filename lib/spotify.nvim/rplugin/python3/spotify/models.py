from __future__ import annotations

from enum import StrEnum
from typing import Any

from dbus_fast.signature import Variant
from pydantic import BaseModel
from pydantic import ConfigDict
from pydantic import Field
from pydantic import HttpUrl
from pydantic import SerializationInfo
from pydantic import ValidationInfo
from pydantic import field_serializer
from pydantic import field_validator
from pydantic import model_validator


class PlaybackStatus(StrEnum):
    PLAYING = "Playing"
    PAUSED = "Paused"
    STOPPED = "Stopped"


class LoopStatus(StrEnum):
    NONE = "None"
    PLAYLIST = "Playlist"
    TRACK = "Track"


class TrackMetadata(BaseModel):
    model_config = ConfigDict(
        extra="ignore",
        json_schema_extra={
            "examples": [
                {
                    "title": "Bohemian Rhapsody",
                    "artist": ["Queen"],
                    "album": "A Night at the Opera",
                }
            ]
        },
    )

    title: str = Field(
        default="Unknown Title",
        description="Title of the track",
    )
    artist: list[str] = Field(
        default_factory=lambda: ["Unknown Artist"],
        description="Artists performing the track",
    )
    album: str = Field(
        default="Unknown Album", description="Album containing the track"
    )
    album_artist: list[str] = Field(
        default_factory=lambda: ["Unknown Artist"],
        description="Artists who created the album",
    )
    art_url: HttpUrl | None = Field(default=None, description="URL to album artwork")
    length: int = Field(default=0, description="Track length in microseconds", ge=0)
    track_id: str = Field(default="", description="D-Bus object path for the track")
    url: str | None = Field(default=None, description="URI of the track")
    disc_number: int | None = Field(
        default=None, description="Position of the disc in the album", ge=1
    )
    track_number: int | None = Field(
        default=None, description="Position of the track on the disc", ge=1
    )

    @classmethod
    def from_dbus_dict(cls, metadata: dict[str, Any]) -> TrackMetadata:
        processed_data: dict[str, Any] = {}
        for key, value in metadata.items():
            if isinstance(value, Variant):
                processed_data[key] = value.value
            else:
                processed_data[key] = value

        return cls(
            title=processed_data.get("xesam:title", "Unknown Title"),
            artist=processed_data.get("xesam:artist", ["Unknown Artist"]),
            album=processed_data.get("xesam:album", "Unknown Album"),
            album_artist=processed_data.get("xesam:albumArtist", ["Unknown Artist"]),
            art_url=processed_data.get("mpris:artUrl"),
            length=processed_data.get("mpris:length", 0),
            track_id=processed_data.get("mpris:trackid", ""),
            url=processed_data.get("xesam:url"),
            disc_number=processed_data.get("xesam:discNumber"),
            track_number=processed_data.get("xesam:trackNumber"),
        )

    @field_validator("track_id")
    @classmethod
    def validate_track_id(cls, v: str) -> str:
        if v and not v.startswith("/"):
            # D-Bus object paths should begin with a slash
            raise ValueError("track_id must be a valid D-Bus object path")
        return v

    @field_serializer("length")
    def format_length(self, value: int, _info: SerializationInfo) -> str:
        if _info.context and _info.context.get("format_time", False):
            seconds = value // 1_000_000
            minutes, seconds = divmod(seconds, 60)
            hours, minutes = divmod(minutes, 60)

            if hours > 0:
                return f"{hours}:{minutes:02d}:{seconds:02d}"
            else:
                return f"{minutes}:{seconds:02d}"
        return f"{value}"

    @property
    def duration_seconds(self) -> float:
        return self.length / 1_000_000

    @property
    def display_title(self) -> str:
        artists = ", ".join(self.artist)
        return f"{self.title} by {artists}"


class PlayerState(BaseModel):
    model_config = ConfigDict(
        validate_assignment=True,
        extra="ignore",
        json_schema_extra={
            "examples": [{"playback_status": "Playing", "volume": 0.8, "shuffle": True}]
        },
    )

    playback_status: PlaybackStatus = Field(
        default=PlaybackStatus.STOPPED, description="Current playback status"
    )
    loop_status: LoopStatus = Field(
        default=LoopStatus.NONE, description="Current loop/repeat status"
    )
    shuffle: bool = Field(
        default=False, description="Whether tracks play in random order"
    )
    volume: float = Field(
        default=1.0,
        description="Playback volume from 0.0 (muted) to 1.0 (max)",
        ge=0.0,
        le=1.0,
    )
    position: int = Field(
        default=0,
        description="Current playback position in microseconds",
        ge=0,
    )
    metadata: TrackMetadata = Field(
        default_factory=TrackMetadata, description="Metadata for the current track"
    )
    can_control: bool = Field(
        default=True, description="Whether the player can be controlled"
    )
    can_go_next: bool = Field(
        default=True, description="Whether the player can skip to the next track"
    )
    can_go_previous: bool = Field(
        default=True, description="Whether the player can skip to the previous track"
    )
    can_play: bool = Field(default=True, description="Whether the player can play")
    can_pause: bool = Field(default=True, description="Whether the player can pause")
    can_seek: bool = Field(
        default=True, description="Whether the player can seek to a position"
    )

    @field_validator("volume")
    @classmethod
    def clamp_volume(cls, v: float) -> float:
        """Ensure volume stays within 0.0 to 1.0 range."""
        return max(0.0, min(1.0, v))

    @field_validator("position")
    @classmethod
    def validate_position(cls, v: int, info: ValidationInfo) -> int:
        """Ensure position is valid relative to track length."""
        # Non-negative check
        if v < 0:
            return 0

        # Check if we have metadata with length to validate against
        if "metadata" in info.data:
            metadata = info.data["metadata"]
            if hasattr(metadata, "length") and metadata.length > 0:
                # If position is beyond track length, cap it
                if v > metadata.length:
                    return metadata.length

        return v

    @model_validator(mode="after")
    def validate_state_consistency(self) -> PlayerState:
        # If can't play, playback status can't be PLAYING
        if not self.can_play and self.playback_status == PlaybackStatus.PLAYING:
            self.playback_status = PlaybackStatus.STOPPED

        # If can't pause, playback status must be PLAYING or STOPPED (not PAUSED)
        if not self.can_pause and self.playback_status == PlaybackStatus.PAUSED:
            self.playback_status = PlaybackStatus.STOPPED

        # If can't seek, position can only be 0 or track length
        if not self.can_seek and self.position > 0 and self.metadata.length > 0:
            # Either at beginning or end
            if self.position > self.metadata.length / 2:
                self.position = self.metadata.length
            else:
                self.position = 0

        return self

    def is_muted(self) -> bool:
        return self.volume <= 0.01

    def is_playing(self) -> bool:
        return self.playback_status == PlaybackStatus.PLAYING

    @property
    def progress_percentage(self) -> float:
        if self.metadata.length <= 0:
            return 0.0
        return min(100.0, (self.position / self.metadata.length) * 100.0)

    @property
    def time_remaining(self) -> int:
        # in microseconds
        if self.metadata.length <= 0:
            return 0
        return max(0, self.metadata.length - self.position)

    @property
    def controls_summary(self) -> str:
        controls: list[str] = []
        if self.can_play:
            controls.append("Play")
        if self.can_pause:
            controls.append("Pause")
        if self.can_go_next:
            controls.append("Next")
        if self.can_go_previous:
            controls.append("Previous")
        if self.can_seek:
            controls.append("Seek")

        return ", ".join(controls) if controls else "No controls available"
