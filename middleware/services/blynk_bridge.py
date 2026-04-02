"""
Blynk Bridge — Syncs IoT sensor data from Blynk Cloud into TigerGraph.
Runs periodically to keep the graph database updated with real-time weight data.
"""

import httpx
from config import settings
from services.tigergraph_service import tg_service


class BlynkBridge:
    """Bridges Blynk IoT data → TigerGraph graph updates."""

    def __init__(self):
        self._base_url = settings.BLYNK_BASE_URL
        self._token = settings.BLYNK_AUTH_TOKEN

    async def is_device_online(self) -> bool:
        """Check if the IoT hardware is connected."""
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.get(
                    f"{self._base_url}/isHardwareConnected",
                    params={"token": self._token},
                )
                return resp.status_code == 200 and resp.text.lower() == "true"
        except Exception as e:
            print(f"Error checking Blynk device: {e}")
            return False

    async def get_current_weight(self) -> float | None:
        """Fetch current weight reading from Blynk V1 pin."""
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.get(
                    f"{self._base_url}/get",
                    params={"token": self._token, "v1": ""},
                )
                if resp.status_code == 200:
                    data = resp.json()
                    if isinstance(data, list) and data:
                        return float(data[0])
                    elif isinstance(data, (int, float)):
                        return float(data)
        except Exception as e:
            print(f"Error fetching Blynk weight: {e}")
        return None

    async def sync_to_graph(self, train_id: str = "RAJ001") -> dict:
        """
        Pull latest weights from Blynk and push to TigerGraph.
        Maps the single IoT device to the specified train.
        """
        result = {
            "device_online": False,
            "weight": None,
            "graph_updated": False,
            "error": None,
        }

        try:
            result["device_online"] = await self.is_device_online()

            if result["device_online"]:
                weight = await self.get_current_weight()
                if weight is not None:
                    result["weight"] = weight
                    # Update the train's weight in the graph
                    success = await tg_service.update_train_weight(train_id, weight)
                    result["graph_updated"] = success
                else:
                    result["error"] = "Could not read weight from device"
            else:
                result["error"] = "IoT device is offline"

        except Exception as e:
            result["error"] = str(e)

        return result


# Singleton
blynk_bridge = BlynkBridge()
