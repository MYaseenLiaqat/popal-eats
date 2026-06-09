"""
Foodpanda (Pakistan) HTTP client — vendors listing and restaurant menu.

Endpoints (verified via scripts/foodpanda_scraper, 2026-06):
  - GET vendors-gateway .../pandora/vendors  (restaurant search)
  - GET api/v5/vendors/{vendor_code}?include=menus  (full menu JSON)

Security:
  - No Authorization header is sent.
  - No customer_id, customer_hash, or dps-session-id headers.
  - Menu API probe (2026-06): omitting perseus-session-id → HTTP 400
    ``{"error":"perseus headers are absent"}``; generic app session id → HTTP 200.
  - perseus-session-id is optional in settings but required by Foodpanda for menus.
"""

from __future__ import annotations

import logging
from typing import Any

import httpx

from app.config import Settings, get_settings

logger = logging.getLogger(__name__)


class FoodpandaAPIError(Exception):
    """Non-success response from a Foodpanda API."""

    def __init__(
        self,
        message: str,
        *,
        status_code: int | None = None,
        url: str | None = None,
        body: str | None = None,
    ) -> None:
        super().__init__(message)
        self.status_code = status_code
        self.url = url
        self.body = body


class FoodpandaClient:
    """
    Thin httpx wrapper around Foodpanda Pakistan public APIs.

    Returns raw JSON dicts; parsing/import belongs in a future service layer.
    """

    def __init__(
        self,
        settings: Settings | None = None,
        *,
        client: httpx.Client | None = None,
    ) -> None:
        self._settings = settings or get_settings()
        self._owns_client = client is None
        timeout = httpx.Timeout(self._settings.foodpanda_request_timeout_seconds)
        self._client = client or httpx.Client(timeout=timeout)

    def close(self) -> None:
        if self._owns_client:
            self._client.close()

    def __enter__(self) -> FoodpandaClient:
        return self

    def __exit__(self, *args: object) -> None:
        self.close()

    def search_restaurants(
        self,
        latitude: float,
        longitude: float,
        limit: int,
        offset: int,
    ) -> dict[str, Any]:
        """
        Search restaurants near a coordinate using the Pandora vendors endpoint.

        ``GET {FOODPANDA_VENDORS_API_URL}?latitude=...&longitude=...&limit=...&offset=...``
        """
        params = self._vendor_search_params(
            latitude=latitude,
            longitude=longitude,
            limit=limit,
            offset=offset,
        )
        return self._get_json(
            self._settings.foodpanda_vendors_api_url,
            params=params,
            headers=self._vendor_headers(referer_path="/"),
        )

    def get_restaurant_menu(
        self,
        vendor_code: str,
        latitude: float,
        longitude: float,
    ) -> dict[str, Any]:
        """
        Fetch a vendor menu with categories and products.

        ``GET {FOODPANDA_MENU_API_BASE}/vendors/{vendor_code}?include=menus&...``

        Set FOODPANDA_PERSEUS_SESSION_ID for menu calls (app-generated id; not from browser).
        """
        code = vendor_code.strip()
        if not code:
            raise ValueError("vendor_code is required")

        url = f"{self._settings.foodpanda_menu_api_base.rstrip('/')}/vendors/{code}"
        params = self._menu_params(latitude=latitude, longitude=longitude)
        headers = self._menu_headers(referer_path=f"/restaurant/{code}")
        return self._get_json(url, params=params, headers=headers)

    def _vendor_search_params(
        self,
        *,
        latitude: float,
        longitude: float,
        limit: int,
        offset: int,
    ) -> dict[str, Any]:
        return {
            "latitude": latitude,
            "longitude": longitude,
            "language_id": self._settings.foodpanda_language_id,
            "include": "characteristics",
            "dynamic_pricing": 0,
            "configuration": self._settings.foodpanda_configuration,
            "country": self._settings.foodpanda_country,
            "budgets": "",
            "cuisine": "",
            "sort": "",
            "food_characteristic": "",
            "use_free_delivery_label": "false",
            "vertical": "restaurants",
            "limit": limit,
            "offset": offset,
            "customer_type": "regular",
        }

    def _menu_params(self, *, latitude: float, longitude: float) -> dict[str, Any]:
        return {
            "latitude": latitude,
            "longitude": longitude,
            "language_id": self._settings.foodpanda_language_id,
            "country": self._settings.foodpanda_country,
            "opening_type": "delivery",
            "include": "menus",
        }

    def _vendor_headers(self, *, referer_path: str) -> dict[str, str]:
        origin = self._settings.foodpanda_site_origin.rstrip("/")
        path = referer_path if referer_path.startswith("/") else f"/{referer_path}"
        return {
            "Accept": "application/json, text/plain, */*",
            "Accept-Language": self._settings.foodpanda_accept_language,
            "Origin": origin,
            "Referer": f"{origin}{path}",
            "User-Agent": self._settings.foodpanda_user_agent,
            "x-disco-client-id": self._settings.foodpanda_disco_client_id,
            "Sec-Fetch-Dest": "empty",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Site": "same-site",
        }

    def _menu_headers(self, *, referer_path: str) -> dict[str, str]:
        headers = self._vendor_headers(referer_path=referer_path)
        headers["perseus-client-id"] = self._settings.foodpanda_perseus_client_id
        session_id = self._settings.foodpanda_perseus_session_id.strip()
        if session_id:
            headers["perseus-session-id"] = session_id
        return headers

    def _get_json(
        self,
        url: str,
        *,
        params: dict[str, Any],
        headers: dict[str, str],
    ) -> dict[str, Any]:
        logger.debug("Foodpanda GET %s params=%s", url, params)
        try:
            response = self._client.get(url, params=params, headers=headers)
        except httpx.RequestError as exc:
            raise FoodpandaAPIError(
                f"Foodpanda request failed: {exc}",
                url=str(exc.request.url) if exc.request else url,
            ) from exc

        body_preview = (response.text or "")[:500]
        if response.status_code != httpx.codes.OK:
            raise FoodpandaAPIError(
                f"Foodpanda API returned HTTP {response.status_code}",
                status_code=response.status_code,
                url=str(response.url),
                body=body_preview,
            )

        if not response.text or not response.text.strip():
            raise FoodpandaAPIError(
                "Foodpanda API returned an empty body",
                status_code=response.status_code,
                url=str(response.url),
            )

        try:
            payload = response.json()
        except ValueError as exc:
            raise FoodpandaAPIError(
                "Foodpanda API returned invalid JSON",
                status_code=response.status_code,
                url=str(response.url),
                body=body_preview,
            ) from exc

        if not isinstance(payload, dict):
            raise FoodpandaAPIError(
                "Foodpanda API returned non-object JSON",
                status_code=response.status_code,
                url=str(response.url),
            )

        api_status = payload.get("status_code")
        if api_status not in (None, 200):
            raise FoodpandaAPIError(
                f"Foodpanda API status_code={api_status}",
                status_code=response.status_code,
                url=str(response.url),
                body=body_preview,
            )

        return payload
