"""
Graph Security Router — Security Side of Duality.
Handles bottleneck detection, suspicious rerouting, and overload risk analysis.
"""

from fastapi import APIRouter, Query
from services.tigergraph_service import tg_service

router = APIRouter(prefix="/api/security", tags=["Security — Risk Detection"])


@router.get("/bottlenecks")
async def detect_bottlenecks(
    threshold: float = Query(0.8, ge=0.0, le=1.0, description="Load ratio threshold"),
):
    """
    🛡️ SECURITY: Detect bottleneck stations.
    Stations where load/capacity ratio exceeds threshold AND have high connectivity.
    """
    bottlenecks = await tg_service.get_bottlenecks(threshold)
    return {
        "status": "success",
        "side": "security",
        "query": "bottleneck_detection",
        "data": bottlenecks,
        "count": len(bottlenecks),
        "threshold": threshold,
        "demo_mode": tg_service.is_demo,
    }


@router.get("/suspicious-rerouting")
async def detect_suspicious_rerouting(
    hours: int = Query(24, ge=1, le=168, description="Lookback period in hours"),
):
    """
    🛡️ SECURITY: Detect suspicious cargo rerouting.
    Flags cargo that deviated from planned shortest path routes.
    """
    suspicious = await tg_service.get_suspicious_rerouting(hours)
    return {
        "status": "success",
        "side": "security",
        "query": "suspicious_rerouting",
        "data": suspicious,
        "count": len(suspicious),
        "lookback_hours": hours,
        "demo_mode": tg_service.is_demo,
    }


@router.get("/overload-risks")
async def detect_overload_risks():
    """
    ⚡🛡️ DUALITY: Detect trains at risk of overloading.
    Combines IoT weight data with graph cargo sum analysis.
    Affects both efficiency (delays) and security (safety).
    """
    risks = await tg_service.get_overload_risks()
    return {
        "status": "success",
        "side": "duality",
        "query": "overload_risk",
        "data": risks,
        "count": len(risks),
        "demo_mode": tg_service.is_demo,
    }
