"""
Graph Sync Router — Real-time IoT → Graph synchronization.
Bridges Blynk sensor data into TigerGraph for live graph updates.
"""

from fastapi import APIRouter
from services.blynk_bridge import blynk_bridge
from services.tigergraph_service import tg_service

router = APIRouter(prefix="/api/sync", tags=["Sync — Real-time IoT"])


@router.post("/blynk-to-graph")
async def sync_blynk_to_graph():
    """
    Manually trigger a sync of Blynk IoT data → TigerGraph.
    Automated sync runs every 30 seconds via scheduler.
    """
    result = await blynk_bridge.sync_to_graph()
    return {
        "status": "success" if result["graph_updated"] else "partial",
        "data": result,
        "demo_mode": tg_service.is_demo,
    }


@router.get("/device-status")
async def get_device_status():
    """Check if the IoT hardware device is online."""
    online = await blynk_bridge.is_device_online()
    return {
        "status": "success",
        "data": {
            "device_online": online,
        },
        "demo_mode": tg_service.is_demo,
    }
