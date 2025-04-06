from __future__ import annotations

from typing import TypeVar
from typing import final

import pynvim

from .interface import Spotify
from .interface import SpotifyService
from .models import PlayerState
from .runner import AsyncRunner

T = TypeVar("T")


@final
@pynvim.plugin
class SpotifyNvimPlugin:
    def __init__(self, nvim: pynvim.Nvim):
        self.nvim = nvim
        self.runner = AsyncRunner()
        self._dbus_connected = False
        self._spotify = Spotify(SpotifyService.DESKTOP)

    @property
    def spotify(self):
        if not self._dbus_connected:
            try:
                self.runner.run_coroutine_sync(self._spotify.connect())
                self._dbus_connected = True
            except Exception:
                raise
        return self._spotify

    @pynvim.command("SpotifyPlayPause")
    def play_pause(self):
        self.runner.run_coroutine_sync(self.spotify.toggle_playback())

    @pynvim.command("SpotifyNext")
    def next_track(self):
        self.runner.run_coroutine_sync(self.spotify.next_track())

    @pynvim.command("SpotifyStatus")
    def show_status(self):
        state: PlayerState = self.runner.run_coroutine_sync(
            self.spotify.getplayer_state()
        )
        metadata = state.metadata
        status_line = (
            f"Spotify: [{state.playback_status}] "
            f"{metadata.display_title} ({metadata.album}) "
            f"Volume: {state.volume * 100:.0f}% "
            f"Shuffle: {'On' if state.shuffle else 'Off'} "
            f"Loop: {state.loop_status}"
        )
        self.nvim.out_write(status_line + "\n")
