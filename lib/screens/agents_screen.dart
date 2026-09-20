import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/monitor_agent.dart';
import '../config/app_config.dart';
import '../models/monitor_region.dart';
import '../theme/app_colors.dart';
import '../widgets/app_ui.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  late Future<List<MonitorAgent>> _agents;

  @override
  void initState() {
    super.initState();
    _agents = _fetchAgents();
  }

  Future<List<MonitorAgent>> _fetchAgents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse('${AppConfig.monitoringApiUrl}/api/Monitor/allMonitorAgents'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => MonitorAgent.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load agents');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agents'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _agents = _fetchAgents();
          });
        },
        child: FutureBuilder<List<MonitorAgent>>(
          future: _agents,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return AppErrorState(
                title: 'Could not load agents',
                message: 'Check your connection and try again.',
                onRetry: () {
                  setState(() {
                    _agents = _fetchAgents();
                  });
                },
              );
            }

            final agents = snapshot.data!;
            if (agents.isEmpty) {
              return const AppEmptyState(
                icon: Icons.dns_outlined,
                title: 'No agents found',
              );
            }

            final totalMonitors =
                agents.fold<int>(0, (sum, agent) => sum + agent.listTasks);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _summaryStat(
                            theme,
                            label: 'Agents',
                            value: '${agents.length}',
                            icon: Icons.dns_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 44,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        Expanded(
                          child: _summaryStat(
                            theme,
                            label: 'Monitors',
                            value: '$totalMonitors',
                            icon: Icons.monitor_heart_outlined,
                            color: AppColors.online,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...agents.map((agent) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppIconBadge(
                                  icon: Icons.computer_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    agent.hostname,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                if (agent.isMaster)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.paused
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: AppColors.paused,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Master',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.paused,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _infoRow('Monitors', '${agent.listTasks}'),
                            _infoRow('Version', agent.version),
                            _infoRow(
                              'Region',
                              MonitorRegion.fromId(agent.monitorRegion).name,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summaryStat(
    ThemeData theme, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
