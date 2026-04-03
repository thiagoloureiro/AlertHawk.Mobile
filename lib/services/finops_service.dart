import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/finops_analysis_run.dart';
import '../models/finops_cost_detail.dart';

class FinOpsService {
  static String get _baseUrl =>
      AppConfig.finopsApiUrl.replaceAll(RegExp(r'/+$'), '');

  /// GET `/api/AnalysisRuns/latest-per-subscription` on the FinOps API base URL.
  static Future<List<FinOpsAnalysisRun>>
      getLatestAnalysisRunsPerSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final uri = Uri.parse(
        '$_baseUrl/api/AnalysisRuns/latest-per-subscription');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final snippet = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      throw Exception(
          'Failed to load FinOps analysis runs (${response.statusCode}): $snippet');
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected FinOps response: expected a JSON array');
    }

    return decoded
        .map((e) => FinOpsAnalysisRun.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList();
  }

  /// GET `/api/CostDetails/analysis/{analysisRunId}` on the FinOps API base URL.
  static Future<List<FinOpsCostDetail>> getCostDetailsForAnalysisRun(
    int analysisRunId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final uri = Uri.parse(
        '$_baseUrl/api/CostDetails/analysis/$analysisRunId');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      final snippet = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      throw Exception(
          'Failed to load cost details (${response.statusCode}): $snippet');
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('Unexpected cost details response: expected a JSON array');
    }

    return decoded
        .map((e) => FinOpsCostDetail.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>)))
        .toList();
  }
}
