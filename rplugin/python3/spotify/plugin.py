from __future__ import annotations

import asyncio
import logging
from typing import Any
from typing import final

import pynvim
from dbus_fast import BusType
from dbus_fast.aio import MessageBus
from dbus_fast.aio.proxy_object import ProxyInterface
from dbus_fast.aio.proxy_object import ProxyObject
from dbus_fast.errors import DBusError

# Assuming your interface and models are correctly placed
from .interface import Spotify
from .interface import SpotifyService
from .models import PlaybackStatus
from .runner import AsyncRunner

# Configure logging for debugging if needed
logging.basicConfig(level=logging.DEBUG, filename="/tmp/spotify_nvim.log", filemode="w")
logger = logging.getLogger(__name__)


@final
@pynvim.plugin
class SpotifyNvimPlugin:
    """Neovim plugin to interact with Spotify via D-Bus."""

    # Removed DBUS_DAEMON constants, no longer needed

    def __init__(self, nvim: pynvim.Nvim):
        logger.info("hello")
        self.nvim = nvim
        self.runner = AsyncRunner()
        self.pause_timer: asyncio.TimerHandle | None = None
        self.last_status: PlaybackStatus | None = None
        self.monitor_bus: MessageBus | None = None
        # Store the proxy and interface for Spotify properties
        self.spotify_proxy: ProxyObject | None = None
        self.spotify_props_interface: ProxyInterface | None = None
        self.spotify_service: SpotifyService = SpotifyService.DESKTOP  # Default
        self.last_formatted_text: str | None = None  # Track text last sent to Lua
        self.icons: dict[str, str] = {"playing": "▶", "paused": "⏸"}  # Default icons

        # --- Config Loading (remains the same) ---
        lua_config = {}  # Default empty config
        try:
            self.nvim.exec_lua("spotify = require('lib.spotify')")
            config = self.nvim.lua.spotify.get_config()
            logger.info(f"Successfully loaded Lua config. {config=}")
            lua_config = self.nvim.exec_lua(
                'return require("lib.spotify").get_config()'
            )
            logger.info(f"Successfully loaded Lua config. {lua_config}")

            # Now use the loaded (or default empty) lua_config table
            self.pause_timeout_sec = 30.0

            logger.info(
                f"Using config: timeout={self.pause_timeout_sec}, "
                f"service={self.spotify_service}, "
                f"icons={self.icons}"
            )
        # Keep general exception handling for Python errors during processing
        except pynvim.NvimError as e:
            logger.error(f"NvimError accessing Lua API: {e}. Using defaults.")
            self.nvim.async_call(
                self.nvim.err_write,
                f"[SpotifyNvim] NvimError accessing Lua API: {e}. Using defaults.\n",
            )
            self.pause_timeout_sec = 30.0
        except (ValueError, TypeError) as e:
            logger.error(f"Error processing config values: {e}. Using defaults.")
            self.nvim.async_call(
                self.nvim.err_write,
                f"[SpotifyNvim] Error processing config values: {e}. Using defaults.\n",
            )
            self.pause_timeout_sec = 30.0
        except Exception as e:
            logger.exception(f"Unexpected error loading config: {e}. Using defaults.")
            self.nvim.async_call(
                self.nvim.err_write,
                f"[SpotifyNvim] Unexpected error loading config: {e}. Using defaults.\n",
            )
            self.pause_timeout_sec = 30.0

        # Start initialization in the background loop
        try:
            self.runner.run_coroutine_sync(self.async_init(), timeout=15.0)
        except Exception as e:
            logger.exception("Failed during synchronous part of initialization:")
            self.nvim.async_call(
                self.nvim.err_write, f"[SpotifyNvim] Failed to initialize: {e}\n"
            )
            # Prevent further operation if init fails badly
            if self.runner:  # Check if runner exists before shutdown
                self.runner.shutdown()

    async def async_init(self):
        """Perform asynchronous initialization and set up signal monitoring."""
        logger.info("Starting async initialization...")
        await self.connect_and_monitor_signals()
        # Perform an initial status update only if signal setup was successful
        if self.spotify_props_interface:
            await self.update_status()
        else:
            logger.warning(
                "Skipping initial status update as signal monitoring setup failed."
            )
        logger.info("Async initialization complete.")

    async def connect_and_monitor_signals(self):
        """Connect to D-Bus, get Spotify proxy, and attach signal handler."""
        try:
            logger.info("Connecting to session bus for signal monitoring...")
            self.monitor_bus = await MessageBus(bus_type=BusType.SESSION).connect()
            logger.info(f"Connected to bus: {self.monitor_bus.unique_name}")

            # Introspect the Spotify service to get its interfaces
            logger.info(
                f"Introspecting Spotify service: {self.spotify_service} at {Spotify.PATH}"
            )
            introspection = await self.monitor_bus.introspect(
                str(self.spotify_service), Spotify.PATH
            )

            # Get the proxy object for the Spotify service
            self.spotify_proxy = self.monitor_bus.get_proxy_object(
                str(self.spotify_service), Spotify.PATH, introspection
            )
            logger.info("Got Spotify proxy object.")

            # Get the standard Properties interface from the Spotify proxy
            self.spotify_props_interface = self.spotify_proxy.get_interface(
                "org.freedesktop.DBus.Properties"
            )
            logger.info("Got Spotify Properties interface.")

            # Register the handler directly on the interface for the PropertiesChanged signal
            # The callback (_handle_spotify_properties_changed) will receive the signal's arguments
            self.spotify_props_interface.on_properties_changed(
                self._handle_spotify_properties_changed
            )
            logger.info("Registered 'on_properties_changed' signal handler.")

        except DBusError as e:
            logger.error(f"D-Bus error during signal setup: {e}")
            self.nvim.async_call(
                self.nvim.err_write,
                f"[SpotifyNvim] D-Bus error connecting to {self.spotify_service}: {e}. Is it running?\n",
            )
            # Clean up partially connected resources
            if self.monitor_bus and self.monitor_bus.connected:
                self.monitor_bus.disconnect()
            self.monitor_bus = None
            self.spotify_proxy = None
            self.spotify_props_interface = None
        except Exception as e:
            logger.exception("Unexpected error during signal setup:")
            self.nvim.async_call(
                self.nvim.err_write,
                f"[SpotifyNvim] Unexpected error setting up signals: {e}\n",
            )
            if self.monitor_bus and self.monitor_bus.connected:
                self.monitor_bus.disconnect()
            self.monitor_bus = None
            self.spotify_proxy = None
            self.spotify_props_interface = None

    def _handle_spotify_properties_changed(
        self,
        interface_name: str,
        changed_properties: dict[str, Any],
        invalidated_properties: list[str],
    ):
        """
        Callback executed when Spotify emits PropertiesChanged signal.
        Runs in the AsyncRunner's event loop thread.
        """
        logger.debug(
            f"Signal received: interface='{interface_name}', "
            f"changed={list(changed_properties.keys())}, invalidated={invalidated_properties}"
        )

        # We only care about changes to the Player interface properties
        if interface_name == Spotify.PLAYER:
            # Check if relevant properties (PlaybackStatus or Metadata) were changed
            if (
                "PlaybackStatus" in changed_properties
                or "Metadata" in changed_properties
            ):
                logger.info(
                    f"Relevant property changed ({list(changed_properties.keys())}). Scheduling status update."
                )
                try:
                    loop = self.runner.get_loop()
                    if loop.is_running():
                        loop.create_task(self.update_status())
                    else:
                        logger.warning(
                            "Event loop not running, cannot schedule update_status task."
                        )
                except RuntimeError:
                    logger.error(
                        "Failed to schedule update: AsyncRunner loop unavailable."
                    )
            else:
                logger.debug(
                    "Ignoring PropertiesChanged signal for irrelevant player properties."
                )
        else:
            logger.debug(
                f"Ignoring PropertiesChanged signal for non-player interface: {interface_name}"
            )

    # --- Timer and Lua update helpers (remain the same) ---
    def _cancel_pause_timer(self):
        """Cancel the pause timer if it exists."""
        if self.pause_timer:
            logger.debug("Cancelling pause timer.")
            self.pause_timer.cancel()
            self.pause_timer = None

    def _start_pause_timer(self):
        """Start a timer to hide the track info after pause_timeout_sec."""
        self._cancel_pause_timer()  # Ensure no existing timer
        try:
            loop = self.runner.get_loop()
            if loop.is_running():
                logger.debug(
                    f"Starting pause timer for {self.pause_timeout_sec} seconds."
                )
                self.pause_timer = loop.call_later(
                    self.pause_timeout_sec,
                    # Schedule the update to clear text on the main thread
                    lambda: self.nvim.async_call(self._update_nvim_state, ""),
                )
            else:
                logger.warning("Event loop not running, cannot start pause timer.")
        except RuntimeError:  # If runner/loop isn't available
            logger.error("Cannot start pause timer: Event loop unavailable.")

    def _format_track_py(self, status_str: str, track_info: str) -> str:
        """Internal Python equivalent of Lua format_track for comparison."""
        if not track_info:
            return ""
        playing_icon = self.icons.get("playing", "▶")
        paused_icon = self.icons.get("paused", "⏸")

        if status_str == "Playing":
            return f"{playing_icon} {track_info}"
        elif status_str == "Paused":
            return f"{paused_icon} {track_info}"
        return ""  # Mimic Lua behavior for other states

    def _update_nvim_state(self, final_text: str):
        """
        Calls the necessary Lua functions on the Neovim main thread.
        This function MUST be called via nvim.async_call.
        """
        # Check if the text actually needs updating in Lua
        if self.last_formatted_text == final_text:
            logger.debug(f"Skipping nvim update as text is unchanged: '{final_text}'")
            return

        logger.debug(f"Updating Neovim Lua state with text: '{final_text}'")
        try:
            # Use pcall for safety, calling the Lua update function
            self.nvim.exec_lua("spotify = require('lib.spotify')")
            self.nvim.lua.spotify.update_track(final_text)
            # Update our internal cache *after* successful call
            self.last_formatted_text = final_text
        except pynvim.NvimError as e:
            logger.error(f"NvimError calling Lua function 'update_track': {e}")
            self.nvim.err_write(f"[SpotifyNvim] Failed to update Lua state: {e}\n")
            # Clear cache on error to force update next time
            self.last_formatted_text = None
        except Exception as e:
            logger.exception(f"Unexpected error calling Lua update_track: {e}")
            self.nvim.err_write(
                f"[SpotifyNvim] Unexpected error updating Lua state: {e}\n"
            )
            self.last_formatted_text = None

    # --- Main Status Update Logic (remains the same) ---
    async def update_status(self):
        """
        Fetch status from Spotify (async) and schedule Neovim update (main thread).
        """
        logger.debug("Attempting to update Spotify status...")
        intended_text = ""  # What we want to display
        needs_nvim_update = True  # Assume update is needed initially

        try:
            async with asyncio.timeout(5):
                async with Spotify(service=self.spotify_service) as spotify:
                    player_state = await spotify.getplayer_state()

            current_status = player_state.playback_status
            metadata = player_state.metadata
            track_info = ""
            status_str = str(current_status)  # Default status string

            if (
                metadata
                and metadata.title != "Unknown Title"
                and (
                    current_status == PlaybackStatus.PLAYING
                    or current_status == PlaybackStatus.PAUSED
                )
            ):
                artist = (
                    ", ".join(metadata.artist) if metadata.artist else "Unknown Artist"
                )
                title = metadata.title if metadata.title else "Unknown Title"
                track_info = f"{artist} - {title}"

                if current_status == PlaybackStatus.PLAYING:
                    status_str = "Playing"
                    intended_text = self._format_track_py(status_str, track_info)
                    self._cancel_pause_timer()

                elif current_status == PlaybackStatus.PAUSED:
                    status_str = "Paused"
                    intended_text = self._format_track_py(status_str, track_info)

                    # Optimization: If paused, timer running, and text hasn't changed, skip update
                    if (
                        self.last_status == PlaybackStatus.PAUSED
                        and self.pause_timer
                        and not self.pause_timer.cancelled()
                        and self.last_formatted_text == intended_text
                    ):
                        logger.debug(
                            "Status Paused, timer running, text unchanged. Skipping nvim update."
                        )
                        needs_nvim_update = False
                    else:
                        # Start timer if status changed to paused or timer not running
                        if (
                            self.last_status != PlaybackStatus.PAUSED
                            or not self.pause_timer
                            or self.pause_timer.cancelled()
                        ):
                            self._start_pause_timer()

            else:
                # Not playing/paused, or invalid metadata -> Clear text
                intended_text = ""
                self._cancel_pause_timer()

            # Schedule Neovim update only if needed
            if needs_nvim_update:
                self.nvim.async_call(self._update_nvim_state, intended_text)

            # Update internal status *after* potential UI update scheduling
            self.last_status = current_status

        except asyncio.TimeoutError:
            logger.warning("Timeout waiting for Spotify D-Bus response.")
            self.nvim.async_call(self._update_nvim_state, "[Spotify Timeout]")
            self.last_status = None
            self.last_formatted_text = "[Spotify Timeout]"  # Update cache
            self._cancel_pause_timer()
        except DBusError as e:
            # Log specific error but clear the display generally
            logger.error(
                f"D-Bus error updating status: {e}. Is {self.spotify_service} running?"
            )
            # Clear only if not already cleared/errored to avoid spam
            if self.last_formatted_text != "":
                self.nvim.async_call(self._update_nvim_state, "")  # Clear display
            self.last_status = None  # Reset status
            self.last_formatted_text = ""  # Reset cache
            self._cancel_pause_timer()
        except Exception:
            logger.exception("Unexpected error updating Spotify status:")
            error_text = "[Spotify Error]"
            if self.last_formatted_text != error_text:  # Avoid spam
                self.nvim.async_call(self._update_nvim_state, error_text)
            self.last_status = None
            self.last_formatted_text = error_text  # Update cache
            self._cancel_pause_timer()

    # --- Cleanup ---
    @pynvim.shutdown_hook
    def cleanup(self):
        """Cleanup resources on Neovim exit."""
        logger.info("Running cleanup hook...")
        self._cancel_pause_timer()

        # Disconnect the bus. This should implicitly handle signal listener cleanup.
        # Run this in the runner's thread if possible.
        async def disconnect_bus():
            if self.monitor_bus and self.monitor_bus.connected:
                logger.info("Disconnecting monitoring bus...")
                try:
                    self.monitor_bus.disconnect()
                    logger.info("Monitoring bus disconnected.")
                except Exception as e:
                    logger.error(f"Error disconnecting monitor bus: {e}")
            else:
                logger.info("Monitor bus already disconnected or never connected.")
            self.monitor_bus = None
            self.spotify_proxy = None
            self.spotify_props_interface = None

        # Only run cleanup if runner/loop is likely still available
        if self.runner and self.runner._loop and self.runner._loop.is_running():
            try:
                # Schedule the disconnect coroutine and wait briefly
                self.runner.run_coroutine_sync(disconnect_bus(), timeout=2.0)
            except TimeoutError:
                logger.warning("Timeout waiting for D-Bus disconnect during shutdown. ")
            except RuntimeError as e:
                logger.warning(
                    f"RuntimeError during D-Bus disconnect (loop might be stopped): {e}"
                )
            except Exception as e:
                logger.error(f"Unexpected error during bus disconnect scheduling: {e}")
        else:
            logger.warning(
                "AsyncRunner loop not running, cannot perform async D-Bus disconnect."
            )

        # Shutdown the runner's event loop and thread *after* attempting async cleanup
        logger.info("Shutting down AsyncRunner...")
        if self.runner:  # Check runner exists
            self.runner.shutdown()
        logger.info("Cleanup complete.")

    # --- Commands (remain the same) ---
    @pynvim.command("SpotifyToggle", nargs=0, sync=False)
    def toggle_playback_command(self):
        logger.info("Received SpotifyToggle command.")

        async def _toggle():
            try:
                async with asyncio.timeout(3):  # Short timeout for commands
                    async with Spotify(service=self.spotify_service) as spotify:
                        await spotify.toggle_playback()
                # Schedule update *after* command finishes
                if self.runner._loop and self.runner._loop.is_running():
                    self.runner.get_loop().create_task(self.update_status())
            except asyncio.TimeoutError:
                logger.warning("Timeout executing toggle playback command.")
                self.nvim.async_call(
                    self.nvim.err_write, "[SpotifyNvim] Timeout toggling playback.\n"
                )
            except Exception as e:
                logger.error(f"Error toggling playback: {e}")
                self.nvim.async_call(self.nvim.err_write, f"[SpotifyNvim] Error: {e}\n")

        # Schedule the command action using call_soon -> create_task
        if self.runner and self.runner._loop and self.runner._loop.is_running():
            self.runner.call_soon(lambda: asyncio.create_task(_toggle()))
        else:
            logger.error("Cannot toggle playback: AsyncRunner not ready.")
            self.nvim.async_call(
                self.nvim.err_write,
                "[SpotifyNvim] Error: Async runner not available.\n",
            )

    @pynvim.command("SpotifyNext", nargs=0, sync=False)
    def next_track_command(self):
        logger.info("Received SpotifyNext command.")

        async def _next():
            try:
                async with asyncio.timeout(3):
                    async with Spotify(service=self.spotify_service) as spotify:
                        await spotify.next_track()
                if self.runner._loop and self.runner._loop.is_running():
                    self.runner.get_loop().create_task(self.update_status())
            except asyncio.TimeoutError:
                logger.warning("Timeout executing next track command.")
                self.nvim.async_call(
                    self.nvim.err_write, "[SpotifyNvim] Timeout skipping track.\n"
                )
            except Exception as e:
                logger.error(f"Error skipping to next track: {e}")
                self.nvim.async_call(self.nvim.err_write, f"[SpotifyNvim] Error: {e}\n")

        if self.runner and self.runner._loop and self.runner._loop.is_running():
            self.runner.call_soon(lambda: asyncio.create_task(_next()))
        else:
            logger.error("Cannot skip next: AsyncRunner not ready.")
            self.nvim.async_call(
                self.nvim.err_write,
                "[SpotifyNvim] Error: Async runner not available.\n",
            )

    @pynvim.command("SpotifyPrev", nargs=0, sync=False)
    def previous_track_command(self):
        logger.info("Received SpotifyPrev command.")

        async def _prev():
            try:
                async with asyncio.timeout(3):
                    async with Spotify(service=self.spotify_service) as spotify:
                        await spotify.previous_track()
                if self.runner._loop and self.runner._loop.is_running():
                    self.runner.get_loop().create_task(self.update_status())
            except asyncio.TimeoutError:
                logger.warning("Timeout executing previous track command.")
                self.nvim.async_call(
                    self.nvim.err_write, "[SpotifyNvim] Timeout skipping track.\n"
                )
            except Exception as e:
                logger.error(f"Error skipping to previous track: {e}")
                self.nvim.async_call(self.nvim.err_write, f"[SpotifyNvim] Error: {e}\n")

        if self.runner and self.runner._loop and self.runner._loop.is_running():
            self.runner.call_soon(lambda: asyncio.create_task(_prev()))
        else:
            logger.error("Cannot skip previous: AsyncRunner not ready.")
            self.nvim.async_call(
                self.nvim.err_write,
                "[SpotifyNvim] Error: Async runner not available.\n",
            )

    @pynvim.command("SpotifyUpdate", nargs=0, sync=False)
    def force_update_command(self):
        """Manually trigger a status update."""
        logger.info("Received SpotifyUpdate command.")
        if self.runner and self.runner._loop and self.runner._loop.is_running():
            # Schedule update_status directly
            self.runner.call_soon(lambda: asyncio.create_task(self.update_status()))
        else:
            logger.error("Cannot force update: AsyncRunner not ready.")
            self.nvim.async_call(
                self.nvim.err_write,
                "[SpotifyNvim] Error: Async runner not available.\n",
            )
