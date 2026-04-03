import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/finops_cost_detail.dart';
import '../services/finops_service.dart';
import '../widgets/theme_selector_modal.dart';

class FinOpsCostDetailsScreen extends StatefulWidget {
  const FinOpsCostDetailsScreen({
    super.key,
    required this.analysisRunId,
    this.subtitle,
  });

  final int analysisRunId;
  final String? subtitle;

  @override
  State<FinOpsCostDetailsScreen> createState() =>
      _FinOpsCostDetailsScreenState();
}

class _FinOpsCostDetailsScreenState extends State<FinOpsCostDetailsScreen> {
  List<FinOpsCostDetail> _details = [];
  bool _isLoading = true;
  String? _errorMessage;

  static final _currency =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final _recordedAtFormat = DateFormat.yMMMd().add_jm();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await FinOpsService.getCostDetailsForAnalysisRun(
        widget.analysisRunId,
      );
      if (!mounted) return;
      setState(() {
        _details = list;
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
          'Cost Details',
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
        onRefresh: _load,
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
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    if (_details.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.subtitle!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
          Center(
            child: Text(
              'No cost details for this run',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              widget.subtitle!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ..._details.map((d) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            d.name.isNotEmpty ? d.name : d.costType,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (d.costType.isNotEmpty)
                          Chip(
                            label: Text(
                              d.costType,
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _detailRow(
                      'Cost',
                      _currency.format(d.cost),
                      isDarkMode,
                    ),
                    if (d.resourceGroup.isNotEmpty)
                      _detailRow(
                        'Resource group',
                        d.resourceGroup,
                        isDarkMode,
                      ),
                    _detailRow(
                      'Recorded',
                      _recordedAtFormat.format(d.recordedAt.toLocal()),
                      isDarkMode,
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _detailRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
