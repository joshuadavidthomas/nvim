from __future__ import annotations

from enum import StrEnum
from typing import Any
from typing import Protocol
from typing import cast
from typing import final
from typing import override

from dbus_fast import BusType
from dbus_fast.aio import MessageBus

from .models import LoopStatus
from .models import PlaybackStatus
from .models import PlayerState
from .models import TrackMetadata


class AsyncPlayerInterface(Protocol):
    async def call_next(self) -> None: ...
    async def call_previous(self) -> None: ...
    async def call_pause(self) -> None: ...
    async def call_play_pause(self) -> None: ...
    async def call_stop(self) -> None: ...
    async def call_play(self) -> None: ...
    async def call_seek(self, offset: int) -> None: ...
    async def call_set_position(self, track_id: str, position: int) -> None: ...
    async def call_open_uri(self, uri: str) -> None: ...
    async def get_playback_status(self) -> str: ...
    async def get_loop_status(self) -> str: ...
    async def get_rate(self) -> float: ...
    async def get_shuffle(self) -> bool: ...
    async def get_metadata(self) -> dict[str, Any]: ...
    async def get_volume(self) -> float: ...
    async def get_position(self) -> int: ...
    async def get_minimum_rate(self) -> float: ...
    async def get_maximum_rate(self) -> float: ...
    async def get_can_go_next(self) -> bool: ...
    async def get_can_go_previous(self) -> bool: ...
    async def get_can_play(self) -> bool: ...
    async def get_can_pause(self) -> bool: ...
    async def get_can_seek(self) -> bool: ...
    async def get_can_control(self) -> bool: ...
    async def set_loop_status(self, value: str) -> None: ...
    async def set_rate(self, value: float) -> None: ...
    async def set_shuffle(self, value: bool) -> None: ...
    async def set_volume(self, value: float) -> None: ...


class AsyncMediaPlayer2Interface(Protocol):
    async def call_quit(self) -> None: ...
    async def call_raise(self) -> None: ...
    async def get_can_quit(self) -> bool: ...
    async def get_can_raise(self) -> bool: ...
    async def get_has_track_list(self) -> bool: ...
    async def get_identity(self) -> str: ...
    async def get_desktop_entry(self) -> str: ...
    async def get_supported_uri_schemes(self) -> list[str]: ...
    async def get_supported_mime_types(self) -> list[str]: ...


class SpotifyService(StrEnum):
    DAEMON = "spotifyd"
    DESKTOP = "spotify"

    @override
    def __str__(self) -> str:
        service_name = super().__str__()
        return f"org.mpris.MediaPlayer2.{service_name}"


@final
class Spotify:
    PATH = "/org/mpris/MediaPlayer2"
    PLAYER = "org.mpris.MediaPlayer2.Player"
    MEDIA_PLAYER = "org.mpris.MediaPlayer2"

    def __init__(self, service: SpotifyService = SpotifyService.DESKTOP):
        self._service = service
        self._bus: MessageBus | None = None
        self._player: AsyncPlayerInterface | None = None
        self._media_player: AsyncMediaPlayer2Interface | None = None

    async def __aenter__(self) -> Spotify:
        await self.connect()
        return self

    async def __aexit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> None:
        await self.disconnect()

    async def connect(self) -> None:
        self._bus = await MessageBus(bus_type=BusType.SESSION).connect()

        introspection = await self._bus.introspect(str(self._service), self.PATH)

        proxy_object = self._bus.get_proxy_object(
            str(self._service), self.PATH, introspection
        )

        media_player_interface = proxy_object.get_interface(self.MEDIA_PLAYER)
        player_interface = proxy_object.get_interface(self.PLAYER)

        self._media_player = cast(
            AsyncMediaPlayer2Interface, cast(object, media_player_interface)
        )
        self._player = cast(AsyncPlayerInterface, cast(object, player_interface))

    async def disconnect(self) -> None:
        if self._bus:
            self._bus.disconnect()
            self._bus = None
            self._media_player = None
            self._player = None

    @property
    def media_player(self) -> AsyncMediaPlayer2Interface:
        if not self._media_player:
            raise RuntimeError("Not connected to D-Bus")
        return self._media_player

    @property
    def player(self) -> AsyncPlayerInterface:
        if not self._player:
            raise RuntimeError("Not connected to D-Bus")
        return self._player

    async def get_metadata(self) -> TrackMetadata:
        metadata = await self.player.get_metadata()
        return TrackMetadata.from_dbus_dict(metadata)

    async def getplayer_state(self) -> PlayerState:
        return PlayerState(
            playback_status=PlaybackStatus(await self.player.get_playback_status()),
            loop_status=LoopStatus(await self.player.get_loop_status()),
            shuffle=await self.player.get_shuffle(),
            volume=await self.player.get_volume(),
            position=await self.player.get_position(),
            metadata=await self.get_metadata(),
            can_control=await self.player.get_can_control(),
            can_go_next=await self.player.get_can_go_next(),
            can_go_previous=await self.player.get_can_go_previous(),
            can_play=await self.player.get_can_play(),
            can_pause=await self.player.get_can_pause(),
            can_seek=await self.player.get_can_seek(),
        )

    async def play(self) -> None:
        await self.player.call_play()

    async def pause(self) -> None:
        await self.player.call_pause()

    async def next_track(self) -> None:
        await self.player.call_next()

    async def previous_track(self) -> None:
        await self.player.call_previous()

    async def set_position(self, position: int) -> None:
        metadata = await self.get_metadata()
        await self.player.call_set_position(metadata.track_id, position)

    async def set_volume(self, volume: float) -> None:
        await self.player.set_volume(volume)

    async def set_loop_status(self, status: LoopStatus) -> None:
        await self.player.set_loop_status(status)

    async def toggle_playback(self) -> None:
        await self.player.call_play_pause()

    async def toggle_shuffle(self) -> None:
        current = await self.player.get_shuffle()
        await self.player.set_shuffle(not current)

    async def stop(self) -> None:
        await self.player.call_stop()
