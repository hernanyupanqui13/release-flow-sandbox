import time

CACHE_TTL_SECONDS = 30


class PendingRequestsCache:
    """Keep the pending requests list for a short time to avoid slow reloads."""

    def __init__(self, loader, clock=time.monotonic):
        self._loader = loader
        self._clock = clock
        self._value = None
        self._expires_at = 0.0

    def get(self):
        now = self._clock()
        if self._value is None or now >= self._expires_at:
            self._value = self._loader()
            self._expires_at = now + CACHE_TTL_SECONDS
        return self._value
