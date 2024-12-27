import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/monitor_agent.dart';
import '../config/app_config.dart';
import '../models/monitor_region.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Agents',
          style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
        ),
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
              return Center(
                child: Text(
                  'Error loading agents',
                  style: GoogleFonts.robotoMono(color: Colors.red),
                ),
              );
            }

            final agents = snapshot.data!;
            final totalMonitors =
                agents.fold<int>(0, (sum, agent) => sum + agent.listTasks);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary',
                          style: GoogleFonts.robotoMono(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Agents:',
                              style: GoogleFonts.robotoMono(),
                            ),
                            Text(
                              '${agents.length}',
                              style: GoogleFonts.robotoMono(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Monitors:',
                              style: GoogleFonts.robotoMono(),
                            ),
                            Text(
                              '$totalMonitors',
                              style: GoogleFonts.robotoMono(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Agent cards
                ...agents.map((agent) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    agent.hostname,
                                    style: GoogleFonts.robotoMono(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Icon(
                                  agent.isMaster
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: agent.isMaster
                                      ? Colors.amber
                                      : Colors.grey,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Monitors:',
                                  style: GoogleFonts.robotoMono(),
                                ),
                                Text(
                                  '${agent.listTasks}',
                                  style: GoogleFonts.robotoMono(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Version:',
                                  style: GoogleFonts.robotoMono(),
                                ),
                                Text(
                                  agent.version,
                                  style: GoogleFonts.robotoMono(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Region:',
                                  style: GoogleFonts.robotoMono(),
                                ),
                                Text(
                                  MonitorRegion.fromId(agent.monitorRegion)
                                      .name,
                                  style: GoogleFonts.robotoMono(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }
}
