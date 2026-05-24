"""HTTP middleware — request logging and DB session safety."""

import logging
import time

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

logger = logging.getLogger("popal.requests")


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        start = time.perf_counter()
        method = request.method
        path = request.url.path
        try:
            response = await call_next(request)
            ms = (time.perf_counter() - start) * 1000
            logger.info("%s %s -> %s (%.1fms)", method, path, response.status_code, ms)
            return response
        except Exception:
            ms = (time.perf_counter() - start) * 1000
            logger.exception("%s %s -> ERROR (%.1fms)", method, path, ms)
            raise
