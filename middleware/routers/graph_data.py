"""
Graph Data Router — CRUD operations for stations, trains, and cargo.
Provides data for the Flutter app's network visualization.
"""

from fastapi import APIRouter
from services.tigergraph_service import tg_service

router = APIRouter(prefix="/api/data", tags=["Data — Network Entities"])


@router.get("/stations")
async def get_all_stations():
    """Get all stations in the railway network."""
    stations = await tg_service.get_all_stations()
    return {
        "status": "success",
        "data": stations,
        "count": len(stations),
        "demo_mode": tg_service.is_demo,
    }


@router.get("/stations/{station_id}")
async def get_station(station_id: str):
    """Get a single station by ID."""
    station = await tg_service.get_station(station_id)
    if station:
        return {"status": "success", "data": station, "demo_mode": tg_service.is_demo}
    return {"status": "error", "message": f"Station {station_id} not found"}


@router.get("/trains")
async def get_all_trains():
    """Get all trains with their current status and weight."""
    trains = await tg_service.get_all_trains()
    return {
        "status": "success",
        "data": trains,
        "count": len(trains),
        "demo_mode": tg_service.is_demo,
    }


@router.get("/cargo")
async def get_all_cargo():
    """Get all cargo items being tracked."""
    cargo = await tg_service.get_all_cargo()
    return {
        "status": "success",
        "data": cargo,
        "count": len(cargo),
        "demo_mode": tg_service.is_demo,
    }


@router.get("/network-health")
async def get_network_health():
    """
    Get the Duality Score — holistic network health.
    Combines efficiency and security metrics into one score.
    """
    health = await tg_service.get_network_health()
    return {
        "status": "success",
        "data": health,
        "demo_mode": tg_service.is_demo,
    }
