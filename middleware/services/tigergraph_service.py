"""
TigerGraph Service — Core graph database client.
Handles all interactions with TigerGraph Cloud REST API.
Falls back to demo mode with realistic fake data when TigerGraph is not connected.
"""

import random
import math
from datetime import datetime, timedelta
from typing import Any

import httpx

from config import settings

# Demo data — realistic Indian Railway network
DEMO_STATIONS = [
    {"station_id": "NDLS", "name": "New Delhi", "city": "Delhi", "state": "Delhi",
     "latitude": 28.6139, "longitude": 77.2090, "capacity": 500, "current_load": 320.0,
     "station_type": "terminal", "risk_score": 0.15, "is_active": True},
    {"station_id": "BCT", "name": "Mumbai Central", "city": "Mumbai", "state": "Maharashtra",
     "latitude": 18.9712, "longitude": 72.8196, "capacity": 450, "current_load": 380.0,
     "station_type": "terminal", "risk_score": 0.22, "is_active": True},
    {"station_id": "HWH", "name": "Howrah Junction", "city": "Kolkata", "state": "West Bengal",
     "latitude": 22.5839, "longitude": 88.3425, "capacity": 400, "current_load": 290.0,
     "station_type": "junction", "risk_score": 0.18, "is_active": True},
    {"station_id": "MAS", "name": "Chennai Central", "city": "Chennai", "state": "Tamil Nadu",
     "latitude": 13.0827, "longitude": 80.2707, "capacity": 380, "current_load": 250.0,
     "station_type": "terminal", "risk_score": 0.12, "is_active": True},
    {"station_id": "SBC", "name": "Bangalore City", "city": "Bangalore", "state": "Karnataka",
     "latitude": 12.9716, "longitude": 77.5946, "capacity": 350, "current_load": 180.0,
     "station_type": "terminal", "risk_score": 0.08, "is_active": True},
    {"station_id": "JP", "name": "Jaipur Junction", "city": "Jaipur", "state": "Rajasthan",
     "latitude": 26.9196, "longitude": 75.7878, "capacity": 280, "current_load": 220.0,
     "station_type": "junction", "risk_score": 0.25, "is_active": True},
    {"station_id": "ADI", "name": "Ahmedabad Junction", "city": "Ahmedabad", "state": "Gujarat",
     "latitude": 23.0225, "longitude": 72.5714, "capacity": 320, "current_load": 270.0,
     "station_type": "junction", "risk_score": 0.19, "is_active": True},
    {"station_id": "LKO", "name": "Lucknow Charbagh", "city": "Lucknow", "state": "Uttar Pradesh",
     "latitude": 26.8467, "longitude": 80.9462, "capacity": 300, "current_load": 195.0,
     "station_type": "junction", "risk_score": 0.14, "is_active": True},
    {"station_id": "PUNE", "name": "Pune Junction", "city": "Pune", "state": "Maharashtra",
     "latitude": 18.5204, "longitude": 73.8567, "capacity": 250, "current_load": 210.0,
     "station_type": "junction", "risk_score": 0.11, "is_active": True},
    {"station_id": "BPL", "name": "Bhopal Junction", "city": "Bhopal", "state": "Madhya Pradesh",
     "latitude": 23.2599, "longitude": 77.4126, "capacity": 270, "current_load": 240.0,
     "station_type": "junction", "risk_score": 0.31, "is_active": True},
    {"station_id": "NGP", "name": "Nagpur Junction", "city": "Nagpur", "state": "Maharashtra",
     "latitude": 21.1458, "longitude": 79.0882, "capacity": 290, "current_load": 260.0,
     "station_type": "junction", "risk_score": 0.28, "is_active": True},
    {"station_id": "HYB", "name": "Hyderabad Deccan", "city": "Hyderabad", "state": "Telangana",
     "latitude": 17.3850, "longitude": 78.4867, "capacity": 340, "current_load": 200.0,
     "station_type": "terminal", "risk_score": 0.10, "is_active": True},
    {"station_id": "GKP", "name": "Gorakhpur Junction", "city": "Gorakhpur", "state": "Uttar Pradesh",
     "latitude": 26.7606, "longitude": 83.3732, "capacity": 200, "current_load": 175.0,
     "station_type": "junction", "risk_score": 0.35, "is_active": True},
    {"station_id": "CNB", "name": "Kanpur Central", "city": "Kanpur", "state": "Uttar Pradesh",
     "latitude": 26.4499, "longitude": 80.3319, "capacity": 260, "current_load": 230.0,
     "station_type": "junction", "risk_score": 0.20, "is_active": True},
    {"station_id": "PNBE", "name": "Patna Junction", "city": "Patna", "state": "Bihar",
     "latitude": 25.6093, "longitude": 85.1376, "capacity": 240, "current_load": 210.0,
     "station_type": "junction", "risk_score": 0.27, "is_active": True},
]

DEMO_ROUTES = [
    {"from": "NDLS", "to": "JP", "distance_km": 308, "travel_time_hours": 4.5, "track_condition": "good", "congestion_level": 0.3},
    {"from": "NDLS", "to": "LKO", "distance_km": 511, "travel_time_hours": 6.5, "track_condition": "good", "congestion_level": 0.4},
    {"from": "NDLS", "to": "CNB", "distance_km": 440, "travel_time_hours": 5.0, "track_condition": "good", "congestion_level": 0.35},
    {"from": "NDLS", "to": "BPL", "distance_km": 707, "travel_time_hours": 8.0, "track_condition": "fair", "congestion_level": 0.5},
    {"from": "JP", "to": "ADI", "distance_km": 625, "travel_time_hours": 9.0, "track_condition": "good", "congestion_level": 0.25},
    {"from": "ADI", "to": "BCT", "distance_km": 493, "travel_time_hours": 6.5, "track_condition": "good", "congestion_level": 0.45},
    {"from": "BCT", "to": "PUNE", "distance_km": 192, "travel_time_hours": 3.5, "track_condition": "good", "congestion_level": 0.2},
    {"from": "PUNE", "to": "HYB", "distance_km": 560, "travel_time_hours": 8.0, "track_condition": "fair", "congestion_level": 0.35},
    {"from": "BPL", "to": "NGP", "distance_km": 355, "travel_time_hours": 5.5, "track_condition": "fair", "congestion_level": 0.6},
    {"from": "NGP", "to": "HYB", "distance_km": 504, "travel_time_hours": 7.0, "track_condition": "good", "congestion_level": 0.3},
    {"from": "NGP", "to": "HWH", "distance_km": 1093, "travel_time_hours": 14.0, "track_condition": "fair", "congestion_level": 0.55},
    {"from": "HYB", "to": "MAS", "distance_km": 625, "travel_time_hours": 8.5, "track_condition": "good", "congestion_level": 0.25},
    {"from": "HYB", "to": "SBC", "distance_km": 570, "travel_time_hours": 8.0, "track_condition": "good", "congestion_level": 0.2},
    {"from": "MAS", "to": "SBC", "distance_km": 346, "travel_time_hours": 5.0, "track_condition": "good", "congestion_level": 0.15},
    {"from": "LKO", "to": "GKP", "distance_km": 273, "travel_time_hours": 4.0, "track_condition": "poor", "congestion_level": 0.7},
    {"from": "LKO", "to": "CNB", "distance_km": 82, "travel_time_hours": 1.5, "track_condition": "good", "congestion_level": 0.3},
    {"from": "CNB", "to": "PNBE", "distance_km": 596, "travel_time_hours": 7.5, "track_condition": "fair", "congestion_level": 0.45},
    {"from": "PNBE", "to": "HWH", "distance_km": 533, "travel_time_hours": 7.0, "track_condition": "fair", "congestion_level": 0.5},
    {"from": "HWH", "to": "MAS", "distance_km": 1663, "travel_time_hours": 20.0, "track_condition": "good", "congestion_level": 0.4},
    {"from": "BCT", "to": "NGP", "distance_km": 826, "travel_time_hours": 12.0, "track_condition": "fair", "congestion_level": 0.55},
]

DEMO_TRAINS = [
    {"train_id": "RAJ001", "name": "Rajdhani Express", "max_capacity": 80.0, "current_weight": 62.5,
     "status": "en_route", "speed": 130.0, "route": ["NDLS", "BPL", "NGP", "BCT"]},
    {"train_id": "SHT002", "name": "Shatabdi Express", "max_capacity": 60.0, "current_weight": 45.0,
     "status": "en_route", "speed": 110.0, "route": ["NDLS", "JP", "ADI"]},
    {"train_id": "DRN003", "name": "Duronto Express", "max_capacity": 100.0, "current_weight": 88.0,
     "status": "loading", "speed": 0.0, "route": ["HWH", "PNBE", "CNB", "LKO", "NDLS"]},
    {"train_id": "GAR004", "name": "Garib Rath", "max_capacity": 70.0, "current_weight": 35.0,
     "status": "en_route", "speed": 95.0, "route": ["MAS", "HYB", "NGP", "BPL"]},
    {"train_id": "VAN005", "name": "Vande Bharat", "max_capacity": 55.0, "current_weight": 52.0,
     "status": "delayed", "speed": 0.0, "route": ["NDLS", "CNB", "PNBE", "HWH"]},
]

DEMO_CARGO = [
    {"cargo_id": "CG001", "description": "Electronics - Samsung", "weight": 12.5,
     "origin": "NDLS", "destination": "BCT", "status": "in_transit", "priority": "express",
     "train": "RAJ001", "shipper": "Samsung India", "receiver": "Reliance Digital"},
    {"cargo_id": "CG002", "description": "Textile Rolls", "weight": 8.0,
     "origin": "ADI", "destination": "MAS", "status": "in_transit", "priority": "normal",
     "train": "GAR004", "shipper": "Arvind Mills", "receiver": "Chennai Textiles"},
    {"cargo_id": "CG003", "description": "Pharmaceutical Goods", "weight": 5.5,
     "origin": "HYB", "destination": "NDLS", "status": "loaded", "priority": "express",
     "train": "DRN003", "shipper": "Dr. Reddy's", "receiver": "Apollo Pharmacy"},
    {"cargo_id": "CG004", "description": "Auto Parts - Tata", "weight": 18.0,
     "origin": "PUNE", "destination": "HWH", "status": "in_transit", "priority": "normal",
     "train": "RAJ001", "shipper": "Tata Motors", "receiver": "Eastern Motors"},
    {"cargo_id": "CG005", "description": "HAZMAT - Chemical Drums", "weight": 22.0,
     "origin": "BCT", "destination": "NDLS", "status": "flagged", "priority": "hazmat",
     "train": "VAN005", "shipper": "IOCL", "receiver": "HPCL Delhi"},
    {"cargo_id": "CG006", "description": "Food Grains - Wheat", "weight": 15.0,
     "origin": "JP", "destination": "MAS", "status": "in_transit", "priority": "normal",
     "train": "SHT002", "shipper": "FCI Jaipur", "receiver": "FCI Chennai"},
    {"cargo_id": "CG007", "description": "Steel Coils", "weight": 25.0,
     "origin": "HWH", "destination": "BCT", "status": "in_transit", "priority": "normal",
     "train": "DRN003", "shipper": "SAIL Durgapur", "receiver": "JSW Steel"},
    {"cargo_id": "CG008", "description": "IT Equipment - Infosys", "weight": 6.0,
     "origin": "SBC", "destination": "NDLS", "status": "booked", "priority": "express",
     "train": None, "shipper": "Infosys", "receiver": "Infosys Delhi"},
]


def _haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance between two points in km."""
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))
    return R * c


class TigerGraphService:
    """
    Service layer wrapping TigerGraph operations.
    Falls back to demo mode with realistic data when TigerGraph Cloud is unavailable.
    """

    def __init__(self):
        self._token = None
        self._host = settings.TG_HOST.rstrip("/")
        self._graphname = settings.TG_GRAPH_NAME
        self._demo_mode = True  # Start in demo, try to connect

        if settings.is_tigergraph_configured() and not settings.DEMO_MODE:
            print(f"🔄 Attempting TigerGraph connection to {self._host}...")
            try:
                self._authenticate()
                if self._token:
                    self._demo_mode = False
                    print("✅ Connected to TigerGraph Cloud via REST API")
                else:
                    print("⚠️ Authentication failed — no token received")
                    print("📊 Falling back to DEMO mode")
            except Exception as e:
                print(f"⚠️ Connection failed: {e}")
                print("📊 Falling back to DEMO mode with simulated graph data")
        else:
            if settings.DEMO_MODE:
                print("📊 DEMO_MODE=true. Running with simulated graph data.")
            else:
                print("📊 TigerGraph not configured. Running in DEMO mode.")

    def _authenticate(self):
        """Get auth token via TigerGraph Savanna REST API (port 443 only)."""
        import requests

        # Strategy 1: /restpp/requesttoken (Savanna 4.x proxy)
        for path in ["/restpp/requesttoken", "/api/requesttoken", "/requesttoken"]:
            try:
                resp = requests.post(
                    f"{self._host}{path}",
                    json={"secret": settings.TG_SECRET, "graph": self._graphname},
                    headers={"Content-Type": "application/json"},
                    timeout=15,
                )
                if resp.status_code == 200:
                    data = resp.json()
                    token = data.get("token") or data.get("results", {}).get("token", "")
                    if token:
                        self._token = token
                        print(f"   Token acquired via {path}")
                        return
                    print(f"   {path}: 200 but no token in response: {resp.text[:200]}")
                else:
                    print(f"   {path}: {resp.status_code} - {resp.text[:100]}")
            except Exception as e:
                print(f"   {path}: Failed - {e}")

        # Strategy 2: Use secret directly as bearer token and verify with /api/ping
        try:
            resp = requests.get(
                f"{self._host}/api/ping",
                headers={"Authorization": f"Bearer {settings.TG_SECRET}"},
                timeout=10,
            )
            if resp.status_code == 200:
                self._token = settings.TG_SECRET
                print("   Using secret as bearer token (verified via /api/ping)")
                return
        except Exception as e:
            print(f"   Bearer token test failed: {e}")

        # Strategy 3: Try basic auth to get a token
        try:
            from base64 import b64encode
            creds = b64encode(f"{settings.TG_USERNAME}:{settings.TG_PASSWORD}".encode()).decode()
            resp = requests.get(
                f"{self._host}/api/ping",
                headers={"Authorization": f"Basic {creds}"},
                timeout=10,
            )
            if resp.status_code == 200:
                # Basic auth works — use secret as API token
                self._token = settings.TG_SECRET
                print("   Basic auth verified, using secret as API token")
                return
            print(f"   Basic auth: {resp.status_code}")
        except Exception as e:
            print(f"   Basic auth failed: {e}")

    def _rest_get(self, endpoint: str, params: dict = None) -> dict | None:
        """Make authenticated GET to TigerGraph (Savanna: port 443 only, /restpp/ prefix)."""
        import requests
        headers = {}
        if self._token:
            headers["Authorization"] = f"Bearer {self._token}"

        # Try /restpp/ prefix first (Savanna proxy), then direct
        for prefix in ["/restpp", ""]:
            try:
                url = f"{self._host}{prefix}{endpoint}"
                resp = requests.get(url, params=params, headers=headers, timeout=15)
                if resp.status_code == 200:
                    return resp.json()
            except Exception:
                continue
        return None

    def _rest_post(self, endpoint: str, data: dict = None) -> dict | None:
        """Make authenticated POST to TigerGraph (Savanna: port 443 only, /restpp/ prefix)."""
        import requests
        headers = {"Content-Type": "application/json"}
        if self._token:
            headers["Authorization"] = f"Bearer {self._token}"

        for prefix in ["/restpp", ""]:
            try:
                url = f"{self._host}{prefix}{endpoint}"
                resp = requests.post(url, json=data or {}, headers=headers, timeout=15)
                if resp.status_code == 200:
                    return resp.json()
            except Exception:
                continue
        return None

    @property
    def is_demo(self) -> bool:
        return self._demo_mode

    # ========================
    # STATION OPERATIONS
    # ========================

    async def get_all_stations(self) -> list[dict]:
        """Get all stations in the network."""
        if self._demo_mode:
            return DEMO_STATIONS
        try:
            result = self._rest_get(f"/graph/{self._graphname}/vertices/Station")
            if result and "results" in result:
                return [self._format_vertex(v) for v in result["results"]]
        except Exception as e:
            print(f"Error fetching stations: {e}")
        return DEMO_STATIONS
    async def get_station(self, station_id: str) -> dict | None:
        """Get a single station by ID."""
        if self._demo_mode:
            return next((s for s in DEMO_STATIONS if s["station_id"] == station_id), None)
        try:
            result = self._rest_get(f"/graph/{self._graphname}/vertices/Station/{station_id}")
            if result and "results" in result and result["results"]:
                return self._format_vertex(result["results"][0])
        except Exception as e:
            print(f"Error fetching station: {e}")
        return None
    # ========================
    # TRAIN OPERATIONS
    # ========================

    async def get_all_trains(self) -> list[dict]:
        """Get all trains with current status."""
        if self._demo_mode:
            return DEMO_TRAINS
        try:
            result = self._rest_get(f"/graph/{self._graphname}/vertices/Train")
            if result and "results" in result:
                return [self._format_vertex(v) for v in result["results"]]
        except Exception as e:
            print(f"Error fetching trains: {e}")
        return DEMO_TRAINS
    async def update_train_weight(self, train_id: str, weight: float) -> bool:
        """Update a train's current weight from IoT data."""
        if self._demo_mode:
            for t in DEMO_TRAINS:
                if t["train_id"] == train_id:
                    t["current_weight"] = weight
                    return True
            return False
        try:
            result = self._rest_post(
                f"/graph/{self._graphname}",
                {"vertices": {"Train": {train_id: {"current_weight": {"value": weight}}}}}
            )
            return result is not None
        except Exception as e:
            print(f"Error updating weight: {e}")
            return False
    # ========================
    # CARGO OPERATIONS
    # ========================

    async def get_all_cargo(self) -> list[dict]:
        """Get all cargo items."""
        if self._demo_mode:
            return DEMO_CARGO
        try:
            result = self._rest_get(f"/graph/{self._graphname}/vertices/Cargo")
            if result and "results" in result:
                return [self._format_vertex(v) for v in result["results"]]
        except Exception as e:
            print(f"Error fetching cargo: {e}")
        return DEMO_CARGO
    # ========================
    # GRAPH INTELLIGENCE QUERIES
    # ========================

    async def get_shortest_route(self, from_station: str, to_station: str) -> dict:
        """
        Find fastest delivery route between two stations.
        EFFICIENCY SIDE of Duality.
        """
        if self._demo_mode:
            return self._demo_shortest_path(from_station, to_station)
        try:
            result = self._rest_get(
                f"/query/{self._graphname}/fastest_route",
                {"source": from_station, "target": to_station}
            )
            if result and "results" in result:
                return result["results"][0] if result["results"] else {"error": "No path found"}
        except Exception as e:
            print(f"Error running shortest route: {e}")
        return self._demo_shortest_path(from_station, to_station)
    async def get_bottlenecks(self, threshold: float = 0.8) -> list[dict]:
        """
        Detect station bottlenecks — high load + high connectivity.
        SECURITY SIDE of Duality.
        """
        if self._demo_mode:
            return self._demo_bottlenecks(threshold)
        try:
            result = self._rest_get(
                f"/query/{self._graphname}/detect_bottlenecks",
                {"threshold": threshold}
            )
            if result and "results" in result:
                return result["results"][0].get("bottlenecks", []) if result["results"] else []
        except Exception as e:
            print(f"Error running bottleneck query: {e}")
        return self._demo_bottlenecks(threshold)
    async def get_suspicious_rerouting(self, lookback_hours: int = 24) -> list[dict]:
        """
        Detect cargo that deviated from planned routes.
        SECURITY SIDE of Duality.
        """
        if self._demo_mode:
            return self._demo_suspicious_rerouting()
        try:
            result = self._rest_get(
                f"/query/{self._graphname}/detect_suspicious_rerouting",
                {"lookback_hours": lookback_hours}
            )
            if result and "results" in result:
                return result["results"][0].get("suspicious", []) if result["results"] else []
        except Exception as e:
            print(f"Error running suspicious rerouting query: {e}")
        return self._demo_suspicious_rerouting()
    async def get_overload_risks(self) -> list[dict]:
        """
        Detect trains at risk of overloading.
        DUALITY — affects both efficiency and security.
        """
        if self._demo_mode:
            return self._demo_overload_risks()
        try:
            result = self._rest_get(f"/query/{self._graphname}/overload_risk_analysis")
            if result and "results" in result:
                return result["results"][0].get("at_risk", []) if result["results"] else []
        except Exception as e:
            print(f"Error running overload risk query: {e}")
        return self._demo_overload_risks()
    async def get_network_health(self) -> dict:
        """
        Compute holistic network health — the Duality Score.
        Balances efficiency metrics vs security metrics.
        """
        if self._demo_mode:
            return self._demo_network_health()
        try:
            result = self._rest_get(f"/query/{self._graphname}/network_health_score")
            if result and "results" in result:
                return self._compute_health_from_raw(result["results"])
        except Exception as e:
            print(f"Error computing network health: {e}")
        return self._demo_network_health()
    async def get_route_connections(self) -> list[dict]:
        """Get all route connections (edges) for network visualization."""
        if self._demo_mode:
            return DEMO_ROUTES
        try:
            result = self._rest_get(f"/graph/{self._graphname}/edges/Station")
            if result and "results" in result:
                return [self._format_edge(e) for e in result["results"]]
        except Exception as e:
            print(f"Error fetching routes: {e}")
        return DEMO_ROUTES
    # ========================
    # DEMO MODE IMPLEMENTATIONS
    # ========================

    def _demo_shortest_path(self, from_id: str, to_id: str) -> dict:
        """Simplified BFS-based pathfinding on demo data."""
        # Build adjacency list
        adj: dict[str, list[tuple[str, float, float]]] = {}
        for r in DEMO_ROUTES:
            adj.setdefault(r["from"], []).append((r["to"], r["travel_time_hours"], r["distance_km"]))
            adj.setdefault(r["to"], []).append((r["from"], r["travel_time_hours"], r["distance_km"]))

        # Dijkstra
        import heapq
        dist = {from_id: 0.0}
        prev: dict[str, str | None] = {from_id: None}
        dist_km = {from_id: 0.0}
        pq = [(0.0, from_id)]

        while pq:
            d, u = heapq.heappop(pq)
            if u == to_id:
                break
            if d > dist.get(u, float("inf")):
                continue
            for v, w, km in adj.get(u, []):
                # Include congestion as weight multiplier
                route = next((r for r in DEMO_ROUTES if (r["from"] == u and r["to"] == v) or (r["from"] == v and r["to"] == u)), None)
                congestion = route["congestion_level"] if route else 0
                cost = d + w * (1 + congestion)
                if cost < dist.get(v, float("inf")):
                    dist[v] = cost
                    dist_km[v] = dist_km.get(u, 0) + km
                    prev[v] = u
                    heapq.heappush(pq, (cost, v))

        if to_id not in prev:
            return {"error": "No path found", "path": [], "total_hours": 0, "total_km": 0}

        # Reconstruct path
        path = []
        node: str | None = to_id
        while node is not None:
            station = next((s for s in DEMO_STATIONS if s["station_id"] == node), None)
            path.append({
                "station_id": node,
                "name": station["name"] if station else node,
                "city": station["city"] if station else "",
            })
            node = prev.get(node)
        path.reverse()

        # Build segments
        segments = []
        for i in range(len(path) - 1):
            route = next(
                (r for r in DEMO_ROUTES if
                 (r["from"] == path[i]["station_id"] and r["to"] == path[i+1]["station_id"]) or
                 (r["from"] == path[i+1]["station_id"] and r["to"] == path[i]["station_id"])),
                None
            )
            if route:
                segments.append({
                    "from": path[i]["name"],
                    "to": path[i+1]["name"],
                    "distance_km": route["distance_km"],
                    "travel_hours": route["travel_time_hours"],
                    "congestion": route["congestion_level"],
                    "condition": route["track_condition"],
                })

        return {
            "path": path,
            "segments": segments,
            "total_hours": round(dist.get(to_id, 0), 1),
            "total_km": round(dist_km.get(to_id, 0), 0),
            "stops": len(path),
        }

    def _demo_bottlenecks(self, threshold: float) -> list[dict]:
        """Identify stations where load/capacity exceeds threshold."""
        bottlenecks = []
        # Count connections per station
        conn_count: dict[str, int] = {}
        for r in DEMO_ROUTES:
            conn_count[r["from"]] = conn_count.get(r["from"], 0) + 1
            conn_count[r["to"]] = conn_count.get(r["to"], 0) + 1

        for s in DEMO_STATIONS:
            load_ratio = s["current_load"] / s["capacity"]
            connections = conn_count.get(s["station_id"], 0)
            if load_ratio > threshold or (connections > 4 and load_ratio > 0.6):
                bottlenecks.append({
                    "station_id": s["station_id"],
                    "name": s["name"],
                    "city": s["city"],
                    "current_load": s["current_load"],
                    "capacity": s["capacity"],
                    "load_ratio": round(load_ratio, 2),
                    "connections": connections,
                    "risk_level": "CRITICAL" if load_ratio > 0.9 else "HIGH" if load_ratio > threshold else "MEDIUM",
                })

        return sorted(bottlenecks, key=lambda x: x["load_ratio"], reverse=True)

    def _demo_suspicious_rerouting(self) -> list[dict]:
        """Simulated suspicious rerouting detections for demo."""
        return [
            {
                "cargo_id": "CG005",
                "description": "HAZMAT - Chemical Drums",
                "origin_station": "Mumbai Central",
                "destination_station": "New Delhi",
                "unplanned_stops": ["Nagpur Junction", "Gorakhpur Junction"],
                "deviation_count": 2,
                "risk_level": "CRITICAL",
                "reason": "Hazmat cargo diverted through non-approved corridor",
            },
            {
                "cargo_id": "CG002",
                "description": "Textile Rolls",
                "origin_station": "Ahmedabad Junction",
                "destination_station": "Chennai Central",
                "unplanned_stops": ["Bhopal Junction"],
                "deviation_count": 1,
                "risk_level": "MEDIUM",
                "reason": "Route deviation detected — possible congestion bypass",
            },
        ]

    def _demo_overload_risks(self) -> list[dict]:
        """Identify trains at overload risk from demo data."""
        risks = []
        for t in DEMO_TRAINS:
            load_pct = t["current_weight"] / t["max_capacity"]
            if load_pct > 0.85:
                # Sum cargo loaded on this train
                cargo_weight = sum(
                    c["weight"] for c in DEMO_CARGO
                    if c.get("train") == t["train_id"] and c["status"] in ("loaded", "in_transit")
                )
                risks.append({
                    "train_id": t["train_id"],
                    "name": t["name"],
                    "current_weight": t["current_weight"],
                    "max_capacity": t["max_capacity"],
                    "cargo_weight": cargo_weight,
                    "load_percentage": round(load_pct * 100, 1),
                    "status": t["status"],
                    "risk_level": "CRITICAL" if load_pct > 0.95 else "HIGH",
                })
        return risks

    def _demo_network_health(self) -> dict:
        """Compute demo network health score."""
        total_stations = len(DEMO_STATIONS)
        total_trains = len(DEMO_TRAINS)
        total_cargo = len(DEMO_CARGO)

        # Efficiency metrics
        avg_congestion = sum(r["congestion_level"] for r in DEMO_ROUTES) / len(DEMO_ROUTES)
        blocked_routes = sum(1 for r in DEMO_ROUTES if r.get("is_blocked", False))
        active_trains = sum(1 for t in DEMO_TRAINS if t["status"] == "en_route")
        delayed_trains = sum(1 for t in DEMO_TRAINS if t["status"] == "delayed")
        efficiency_score = max(0, 100 - (avg_congestion * 50) - (blocked_routes * 10) - (delayed_trains * 15))

        # Security metrics
        flagged_cargo = sum(1 for c in DEMO_CARGO if c["status"] == "flagged")
        overloaded = sum(1 for t in DEMO_TRAINS if t["current_weight"] / t["max_capacity"] > 0.9)
        bottlenecks = len(self._demo_bottlenecks(0.8))
        suspicious = len(self._demo_suspicious_rerouting())
        security_score = max(0, 100 - (flagged_cargo * 15) - (overloaded * 20) - (suspicious * 10) - (bottlenecks * 5))

        # Duality score — harmonic mean of both
        duality_score = (2 * efficiency_score * security_score) / (efficiency_score + security_score + 0.01)

        return {
            "duality_score": round(duality_score, 1),
            "efficiency": {
                "score": round(efficiency_score, 1),
                "avg_congestion": round(avg_congestion, 2),
                "blocked_routes": blocked_routes,
                "active_trains": active_trains,
                "delayed_trains": delayed_trains,
                "on_time_rate": round((active_trains / max(total_trains, 1)) * 100, 1),
            },
            "security": {
                "score": round(security_score, 1),
                "flagged_cargo": flagged_cargo,
                "overloaded_trains": overloaded,
                "bottleneck_stations": bottlenecks,
                "suspicious_routes": suspicious,
                "risk_incidents": flagged_cargo + overloaded + suspicious,
            },
            "network": {
                "total_stations": total_stations,
                "total_trains": total_trains,
                "total_cargo": total_cargo,
                "total_routes": len(DEMO_ROUTES),
            },
            "timestamp": datetime.now().isoformat(),
        }

    def _compute_health_from_raw(self, raw_result: list) -> dict:
        """Transform raw TigerGraph query result into network health."""
        # Parse raw results
        data = {}
        for item in raw_result:
            data.update(item)

        total_stations = data.get("total_stations", 0)
        total_cargo = data.get("total_cargo", 0)
        flagged_cargo = data.get("flagged_cargo", 0)
        total_trains = data.get("total_trains", 0)
        overloaded_trains = data.get("overloaded_trains", 0)

        efficiency_score = max(0, 100 - (overloaded_trains * 20))
        security_score = max(0, 100 - (flagged_cargo * 15) - (overloaded_trains * 20))
        duality_score = (2 * efficiency_score * security_score) / (efficiency_score + security_score + 0.01)

        return {
            "duality_score": round(duality_score, 1),
            "efficiency": {"score": round(efficiency_score, 1)},
            "security": {"score": round(security_score, 1)},
            "network": {
                "total_stations": total_stations,
                "total_trains": total_trains,
                "total_cargo": total_cargo,
            },
            "timestamp": datetime.now().isoformat(),
        }

    def _format_vertex(self, v: dict) -> dict:
        """Format a TigerGraph vertex result."""
        attrs = v.get("attributes", v)
        attrs["v_id"] = v.get("v_id", "")
        return attrs

    def _format_edge(self, e: dict) -> dict:
        """Format a TigerGraph edge result."""
        attrs = e.get("attributes", {})
        attrs["from"] = e.get("from_id", "")
        attrs["to"] = e.get("to_id", "")
        return attrs


# Singleton instance
tg_service = TigerGraphService()
