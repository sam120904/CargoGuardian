"""
Graph Routes Router — Efficiency Side of Duality.
Handles shortest-path queries, route optimization, and delivery ETAs.
"""

from fastapi import APIRouter, Query
from services.tigergraph_service import tg_service

router = APIRouter(prefix="/api/routes", tags=["Routes — Efficiency"])


@router.get("/shortest")
async def get_shortest_route(
    from_station: str = Query(..., alias="from", description="Origin station ID"),
    to_station: str = Query(..., alias="to", description="Destination station ID"),
):
    """
    ⚡ EFFICIENCY: Find the fastest delivery route between two stations.
    Uses Dijkstra's algorithm on weighted graph edges (travel time × congestion).
    """
    result = await tg_service.get_shortest_route(from_station, to_station)
    return {
        "status": "success",
        "side": "efficiency",
        "query": "shortest_path",
        "data": result,
        "demo_mode": tg_service.is_demo,
    }


@router.get("/connections")
async def get_all_connections():
    """Get all route connections for network visualization."""
    connections = await tg_service.get_route_connections()
    return {
        "status": "success",
        "data": connections,
        "count": len(connections),
        "demo_mode": tg_service.is_demo,
    }
