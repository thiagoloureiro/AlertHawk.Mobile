import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/node_metric.dart';
import '../models/pod_metric.dart';

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

    print(response.statusCode);

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
}

