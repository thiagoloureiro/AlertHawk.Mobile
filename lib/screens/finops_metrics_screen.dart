import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/finops_analysis_run.dart';
import '../services/finops_service.dart';
import '../widgets/theme_selector_modal.dart';
import 'finops_cost_details_screen.dart';
import 'finops_coming_soon_screen.dart';

class FinOpsMetricsScreen extends StatefulWidget {
  const FinOpsMetricsScreen({super.key});

  @override
  State<FinOpsMetricsScreen> createState() => _FinOpsMetricsScreenState();
}

class _FinOpsMetricsScreenState extends State<FinOpsMetricsScreen> {
  List<FinOpsAnalysisRun> _runs = [];
  bool _isLoading = true;
  String? _errorMessage;

  static final _currency =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final _dateTime = DateFormat.yMMMd().add_jm();

  @override
  void initState() {
    super.initState();
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final runs = await FinOpsService.getLatestAnalysisRunsPerSubscription();
      if (!mounted) return;
      setState(() {
        _runs = runs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FinOps Metrics',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Select theme',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => showThemeSelectorModal(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRuns,
        child: _buildBody(context, isDarkMode),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDarkMode) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: GoogleFonts.inter(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loadRuns,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    if (_runs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.3,
          ),
          Center(
            child: Text(
              'No analysis runs found',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _runs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final run = _runs[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  run.subscriptionName.isNotEmpty
                      ? run.subscriptionName
                      : run.subscriptionId,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (run.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    run.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _row(
                  Icons.payments_outlined,
                  'Monthly cost',
                  _currency.format(run.totalMonthlyCost),
                  isDarkMode,
                ),
                _row(
                  Icons.cloud_outlined,
                  'Resources analyzed',
                  '${run.totalResourcesAnalyzed}',
                  isDarkMode,
                ),
                _row(
                  Icons.schedule,
                  'Run date',
                  _dateTime.format(run.runDate.toLocal()),
                  isDarkMode,
                ),
                if (run.aiModel.isNotEmpty)
                  _row(
                    Icons.smart_toy_outlined,
                    'AI model',
                    run.aiModel,
                    isDarkMode,
                  ),
                const SizedBox(height: 8),
                Text(
                  'Subscription: ${run.subscriptionId}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white38 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => FinOpsCostDetailsScreen(
                              analysisRunId: run.id,
                              subtitle: run.subscriptionName.isNotEmpty
                                  ? run.subscriptionName
                                  : null,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Cost Details',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const FinOpsComingSoonScreen(
                              title: 'AI Recommendations',
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'AI Recommendations',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const FinOpsComingSoonScreen(
                              title: 'Historical Results',
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Historical Results',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(IconData icon, String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isDarkMode ? Colors.white54 : Colors.black45,
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
