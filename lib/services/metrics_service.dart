import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/node_metric.dart';
import '../models/pod_metric.dart';
import '../models/cluster_event.dart';

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

  static Future<List<NodeMetric>> getNodeMetrics({
    required String clusterName,
    int hours = 24,
    int limit = 100,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final baseUrl = AppConfig.metricsApiUrl;
    final uri = Uri.parse('$baseUrl/api/metrics/node').replace(
      queryParameters: {
        'hours': hours.toString(),
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
    final uri = Uri.parse('$baseUrl/api/Metrics/namespace').replace(
      queryParameters: {
        'hours': hours.toString(),
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
}

