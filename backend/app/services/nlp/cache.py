"""Simple in-memory cache placeholder for NLP inference (swap for Redis later)."""

from collections import OrderedDict
from typing import Any


class InferenceCache:
    """LRU-style cache for model outputs."""

    def __init__(self, max_size: int = 512) -> None:
        self._store: OrderedDict[str, Any] = OrderedDict()
        self._max_size = max_size

    def get(self, key: str) -> Any | None:
        if key not in self._store:
            return None
        self._store.move_to_end(key)
        return self._store[key]

    def set(self, key: str, value: Any) -> None:
        self._store[key] = value
        self._store.move_to_end(key)
        while len(self._store) > self._max_size:
            self._store.popitem(last=False)


# Shared cache instance for sentiment batching prep
nlp_cache = InferenceCache()
