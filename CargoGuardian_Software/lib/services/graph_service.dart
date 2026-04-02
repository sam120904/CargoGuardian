import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/config.dart';

/// Service class for communicating with the Smart Cargo Intelligence Network middleware.
/// Provides graph-powered analytics: shortest paths, bottleneck detection,
/// suspicious rerouting, overload risks, and network health.
class GraphService {
  static String get _baseUrl => AppConfig.middlewareBaseUrl;

  // ============ EFFICIENCY SIDE ============

  /// Find the shortest/fastest route between two stations.
  /// Uses Dijkstra's algorithm on weighted graph edges.
  Future<Map<String, dynamic>> getShortestRoute(String fromStation, String toStation) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/routes/shortest?from=$fromStation&to=$toStation'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch route: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) print('GraphService.getShortestRoute error: $e');
      rethrow;
    }
  }

  /// Get all route connections for network visualization.
  Future<List<dynamic>> getRouteConnections() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/routes/connections'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      throw Exception('Failed to fetch connections: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) print('GraphService.getRouteConnections error: $e');
      rethrow;
    }
  }

  // ============ SECURITY SIDE ============

  /// Detect bottleneck stations based on load/capacity ratio.
  Future<List<dynamic>> getBottlenecks({double threshold = 0.8}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/security/bottlenecks?threshold=$threshold'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      throw Exception('Failed to fetch bottlenecks: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) print('GraphService.getBottlenecks error: $e');
      rethrow;
    }
  }

  /// Detect suspicious cargo rerouting patterns.
  Future<List<dynamic>> getSuspiciousRerouting({int hours = 24}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/security/suspicious-rerouting?hours=$hours'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      throw Exception('Failed to fetch suspicious rerouting: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) print('GraphService.getSuspiciousRerouting error: $e');
      rethrow;
    }
  }

  /// Detect trains at risk of overloading.
  Future<List<dynamic>> getOverloadRisks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/security/overload-risks'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      throw Exception('Failed to fetch overload risks: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) print('GraphService.getOverloadRisks error: $e');
      rethrow;
    }
  }

  // ============ DATA ============

  /// Get all stations in the network.
  Future<List<dynamic>> getAllStations() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/data/stations'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      throw Exception('Failed to fetch stations: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) print('GraphService.getAllStations error: $e');
      rethrow;
    }
  }

  /// Get all trains.
  Future<List<dynamic>> getAllTrains() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/data/trains'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      throw Exception('Failed to fetch trains: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) print('GraphService.getAllTrains error: $e');
      rethrow;
    }
  }

  /// Get all cargo.
  Future<List<dynamic>> getAllCargo() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/data/cargo'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
      throw Exception('Failed to fetch cargo: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) print('GraphService.getAllCargo error: $e');
      rethrow;
    }
  }

  /// Get network health (Duality Score).
  Future<Map<String, dynamic>> getNetworkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/data/network-health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch network health: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) print('GraphService.getNetworkHealth error: $e');
      rethrow;
    }
  }

  /// Check if middleware server is reachable.
  Future<bool> isMiddlewareOnline() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
