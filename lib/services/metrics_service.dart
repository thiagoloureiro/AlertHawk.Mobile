import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/node_metric.dart';
import '../models/pod_metric.dart';
import '../models/cluster_event.dart';
import '../models/volume_metric.dart';
import '../models/cluster_node_metric.dart';

class MetricsService {
  static Future<List<String>> getClusters() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final baseUrl = AppConfig.metricsApiUrl;
    final uri = Uri.parse('$baseUrl/api/metrics/clusters');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((item) => item.toString()).toList();
    } else {
      throw Exception('Failed to load clusters');
    }
  }

  /// Fetches node metrics for all clusters (dashboard view).
  /// Tries /api/metrics/node first (same as getNodeMetrics, no cluster filter), then /metrics/api/Metrics/node.
  static Future<List<ClusterNodeMetric>> getClusterDashboardNodes({
    int minutes = 1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final baseUrl = AppConfig.metricsApiUrl;

    final urisToTry = [
      Uri.parse('$baseUrl/api/metrics/node').replace(
        queryParameters: {'minutes': minutes.toString()},
      ),
      Uri.parse('$baseUrl/metrics/api/Metrics/node').replace(
        queryParameters: {'minutes': minutes.toString()},
      ),
    ];

    http.Response? lastResponse;
    for (final uri in urisToTry) {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      lastResponse = response;
      if (response.statusCode != 200) continue;
      try {
        final decoded = json.decode(response.body);
        final List<dynamic> jsonList = decoded is List
            ? decoded
            : (decoded is Map ? (decoded['data'] ?? decoded['nodes'] ?? []) : []);
        return jsonList
            .map((e) => ClusterNodeMetric.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        rethrow;
      }
    }

    final res = lastResponse!;
    final msg = '${res.statusCode}: ${res.body.length > 200 ? res.body.substring(0, 200) + "..." : res.body}';
    throw Exception('Failed to load clusters: $msg');
  }

  static Future<List<NodeMetric>> getNodeMetrics({
    required String clusterName,
    int hours = 24,
    int limit = 100,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final baseUrl = AppConfig.metricsApiUrl;
    final minutes = hours * 60;
    final uri = Uri.parse('$baseUrl/api/metrics/node').replace(
      queryParameters: {
        'minutes': minutes.toString(),
        'limit': limit.toString(),
        'clusterName': clusterName,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => NodeMetric.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load node metrics');
    }
  }

  static Future<List<String>> getNamespaces({
    required String clusterName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final baseUrl = AppConfig.metricsApiUrl;
    final uri = Uri.parse('$baseUrl/api/metrics/namespaces').replace(
      queryParameters: {
        'clusterName': clusterName,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((item) => item.toString()).toList();
    } else {
      throw Exception('Failed to load namespaces');
    }
  }

  static Future<List<PodMetric>> getNamespaceMetrics({
    required String clusterName,
    required String namespace,
    int hours = 1,
    int limit = 1000,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final baseUrl = AppConfig.metricsApiUrl;
    final minutes = hours * 60;
    final uri = Uri.parse('$baseUrl/api/metrics/namespace').replace(
      queryParameters: {
        'minutes': minutes.toString(),
        'limit': limit.toString(),
        'clusterName': clusterName,
        'namespace': namespace,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => PodMetric.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load namespace metrics');
    }
  }

  static Future<List<ClusterEvent>> getEvents({
    required String clusterName,
    int minutes = 1440,
    int limit = 100,
    int offset = 0,
    String? namespace,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final baseUrl = AppConfig.metricsApiUrl;
    final queryParams = {
      'minutes': minutes.toString(),
      'limit': limit.toString(),
      'clusterName': clusterName,
    };
    if (offset > 0) queryParams['offset'] = offset.toString();
    if (namespace != null && namespace.isNotEmpty) {
      queryParams['namespace'] = namespace;
    }
    final uri = Uri.parse('$baseUrl/api/events').replace(
      queryParameters: queryParams,
    );

    debugPrint('Cluster events API URL: $uri');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => ClusterEvent.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to load cluster events: ${response.statusCode} ${response.body.isNotEmpty ? response.body : ""}');
    }
  }

  static Future<List<VolumeMetric>> getPvcMetrics({
    required String clusterName,
    int minutes = 1,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final baseUrl = AppConfig.metricsApiUrl;
    final uri = Uri.parse('$baseUrl/api/metrics/pvc').replace(
      queryParameters: {
        'minutes': minutes.toString(),
        'clusterName': clusterName,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      // print json size
      return jsonList.map((json) => VolumeMetric.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load volume metrics');
    }
  }
}
