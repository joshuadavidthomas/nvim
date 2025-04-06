from __future__ import annotations

import asyncio
import atexit
import logging
import threading
from collections.abc import Callable
from collections.abc import Coroutine
from concurrent.futures import Future
from concurrent.futures import TimeoutError
from typing import Any
from typing import TypeVar
from typing import final

logger = logging.getLogger(__name__)

T = TypeVar("T")


@final
class AsyncRunner:
    """Manages a dedicated asyncio event loop running in a background thread."""

    def __init__(self):
        self._loop: asyncio.AbstractEventLoop | None = None
        self._loop_thread: threading.Thread | None = None
        self._started = threading.Event()  # To signal loop start
        self._start_event_loop_thread()
        atexit.register(self.shutdown)
        logger.info("AsyncRunner initialized.")

    def _event_loop_thread_target(self):
        """Target function for the background event loop thread."""
        try:
            logger.info("Background thread started.")
            self._loop = asyncio.new_event_loop()
            asyncio.set_event_loop(self._loop)
            self._started.set()  # Signal that the loop is set
            logger.info("Running event loop: %s", self._loop)
            self._loop.run_forever()
        except Exception:
            logger.exception("Unhandled exception in event loop thread.")
        finally:
            # Cleanup loop resources if it stops
            if self._loop and self._loop.is_running():
                logger.info("Stopping event loop from thread target finally block.")
                self._loop.call_soon_threadsafe(self._loop.stop)
            logger.info("Background thread finished.")
            self._loop = None  # Mark loop as gone

    def _start_event_loop_thread(self):
        """Starts the background event loop thread."""
        if self._loop_thread is None or not self._loop_thread.is_alive():
            logger.info("Starting event loop thread...")
            self._started.clear()
            self._loop_thread = threading.Thread(
                target=self._event_loop_thread_target,
                daemon=True,
                name="AsyncRunnerThread",
            )
            self._loop_thread.start()
            # Wait for the loop to be created and set in the thread
            if not self._started.wait(timeout=5):  # Wait up to 5 seconds
                logger.error("Event loop did not start within timeout!")
                raise RuntimeError("AsyncRunner event loop failed to start.")
            logger.info("Event loop thread started and loop is ready.")

    def run_coroutine_sync(
        self, coro: Coroutine[Any, Any, T], timeout: float | None = 10.0
    ) -> T:
        """
        Runs a coroutine on the background loop and blocks until it completes,
        returning its result or raising its exception.

        Args:
            coro: The coroutine object to run.
            timeout: Maximum time in seconds to wait for the coroutine.
                     None means wait indefinitely.

        Returns:
            The result of the coroutine.

        Raises:
            RuntimeError: If the event loop is not running.
            TimeoutError: If the coroutine doesn't complete within the timeout.
            Exception: Any exception raised by the coroutine itself.
        """
        if not self._loop or not self._loop.is_running():
            logger.error("Attempted to run coroutine but event loop is not running.")
            raise RuntimeError("AsyncRunner event loop is not available")

        future: Future[T] = asyncio.run_coroutine_threadsafe(coro, self._loop)
        logger.debug("Scheduled coroutine %s, waiting for result...", coro.__name__)

        try:
            result = future.result(timeout=timeout)
            logger.debug("Coroutine %s completed with result.", coro.__name__)
            return result
        except TimeoutError:
            logger.error(
                "Coroutine %s timed out after %s seconds.", coro.__name__, timeout
            )
            # Optionally attempt to cancel the future
            # future.cancel() # Cancellation might not always work depending on the coroutine
            raise
        except Exception as e:
            logger.exception("Coroutine %s raised an exception.", coro.__name__)
            raise e  # Re-raise the original exception

    def call_soon(self, callback: Callable[..., Any], *args: Any) -> asyncio.Handle:
        """
        Schedules a regular function call on the event loop thread soon.

        This is thread-safe.

        Args:
            callback: The function to call.
            *args: Arguments for the function.

        Returns:
            An asyncio.Handle instance.

        Raises:
            RuntimeError: If the event loop is not running.
        """
        if not self._loop or not self._loop.is_running():
            logger.error("Attempted call_soon but event loop is not running.")
            raise RuntimeError("AsyncRunner event loop is not available")
        return self._loop.call_soon_threadsafe(callback, *args)

    def shutdown(self):
        """Stops the event loop and waits for the background thread to join."""
        logger.info("AsyncRunner shutdown requested.")
        if self._loop and self._loop.is_running():
            logger.info("Stopping event loop via shutdown...")
            # Schedule stop from the current thread
            self._loop.call_soon_threadsafe(self._loop.stop)

        if self._loop_thread and self._loop_thread.is_alive():
            logger.info("Waiting for loop thread %s to join...", self._loop_thread.name)
            self._loop_thread.join(timeout=5)  # Wait up to 5 seconds
            if self._loop_thread.is_alive():
                logger.warning(
                    "Loop thread did not exit cleanly after shutdown request."
                )
        logger.info("AsyncRunner shutdown complete.")

    def get_loop(self) -> asyncio.AbstractEventLoop:
        """
        Returns the managed asyncio event loop.

        Raises:
            RuntimeError: If the event loop is not running.
        """
        if not self._loop or not self._loop.is_running():
            raise RuntimeError("AsyncRunner event loop is not available")
        return self._loop
