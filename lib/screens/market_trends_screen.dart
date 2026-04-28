import 'package:flutter/material.dart';

// ── Data Models ──────────────────────────────────────────────────────────────

enum TimeRange { fiveD, oneM, sixM, oneY }

extension TimeRangeLabel on TimeRange {
  String get label {
    switch (this) {
      case TimeRange.fiveD:
        return '5D';
      case TimeRange.oneM:
        return '1M';
      case TimeRange.sixM:
        return '6M';
      case TimeRange.oneY:
        return '1Y';
    }
  }
}

class HistoricalEntry {
  final String date;
  final double rate;
  final bool isUp;
  const HistoricalEntry({
    required this.date,
    required this.rate,
    required this.isUp,
  });
}

// ── Screen ───────────────────────────────────────────────────────────────────

class MarketTrendsScreen extends StatefulWidget {
  const MarketTrendsScreen({super.key});

  @override
  State<MarketTrendsScreen> createState() => _MarketTrendsScreenState();
}

class _MarketTrendsScreenState extends State<MarketTrendsScreen> {
  TimeRange _selectedRange = TimeRange.fiveD;

  // Chart data points (normalised 0-1 for the painter)
  final Map<TimeRange, List<double>> _chartData = {
    TimeRange.fiveD: [0.25, 0.35, 0.55, 0.80, 0.60, 0.20, 0.40, 0.75, 0.90],
    TimeRange.oneM: [0.10, 0.40, 0.30, 0.65, 0.50, 0.70, 0.45, 0.60, 0.80],
    TimeRange.sixM: [0.50, 0.30, 0.70, 0.20, 0.60, 0.80, 0.40, 0.55, 0.75],
    TimeRange.oneY: [0.20, 0.50, 0.35, 0.65, 0.45, 0.75, 0.30, 0.60, 0.85],
  };

  final List<HistoricalEntry> _history = const [
    HistoricalEntry(date: 'May 16, 2024', rate: 0.9242, isUp: true),
    HistoricalEntry(date: 'May 15, 2024', rate: 0.9198, isUp: true),
    HistoricalEntry(date: 'May 14, 2024', rate: 0.9212, isUp: false),
    HistoricalEntry(date: 'May 13, 2024', rate: 0.9150, isUp: true),
    HistoricalEntry(date: 'May 12, 2024', rate: 0.9104, isUp: true),
  ];

  String get _startLabel {
    switch (_selectedRange) {
      case TimeRange.fiveD:
        return 'MAY 12';
      case TimeRange.oneM:
        return 'APR 17';
      case TimeRange.sixM:
        return 'NOV 16';
      case TimeRange.oneY:
        return 'MAY 16 \'23';
    }
  }

  double get _high {
    switch (_selectedRange) {
      case TimeRange.fiveD:
        return 0.9288;
      case TimeRange.oneM:
        return 0.9350;
      case TimeRange.sixM:
        return 0.9410;
      case TimeRange.oneY:
        return 0.9500;
    }
  }

  double get _low {
    switch (_selectedRange) {
      case TimeRange.fiveD:
        return 0.9104;
      case TimeRange.oneM:
        return 0.8950;
      case TimeRange.sixM:
        return 0.8700;
      case TimeRange.oneY:
        return 0.8500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ── Rate Header ────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  const Text(
                    'EUR / USD',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '0.9242',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: -2,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        color: Color(0xFF34C759),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '+1.24%',
                        style: TextStyle(
                          color: Color(0xFF34C759),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Last 24h',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.4),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Main Chart Card ────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Time range tabs
                  _TimeRangeTabs(
                    selected: _selectedRange,
                    onChanged: (r) => setState(() => _selectedRange = r),
                  ),

                  const SizedBox(height: 20),

                  // Chart
                  _LineChart(
                    dataPoints: _chartData[_selectedRange]!,
                    startLabel: _startLabel,
                  ),

                  const SizedBox(height: 16),

                  // High / Low
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: '${_selectedRange.label} HIGH',
                          value: _high.toStringAsFixed(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(
                          label: '${_selectedRange.label} LOW',
                          value: _low.toStringAsFixed(4),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Market Insight
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0EE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 14,
                              color: Color(0xFF34C759),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'MARKET INSIGHT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: Color(0xFF34C759),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'EUR is showing strong momentum against the USD following positive ECB sentiment. '
                          'Resistance is expected near the 0.9310 level.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF3A3A3C),
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Historical Data ────────────────────────────────────────────
            Text(
              'Historical Data (${_selectedRange.label})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 14),

            ..._history.map((e) => _HistoryRow(entry: e)),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Time Range Tab Bar ────────────────────────────────────────────────────────

class _TimeRangeTabs extends StatelessWidget {
  final TimeRange selected;
  final ValueChanged<TimeRange> onChanged;

  const _TimeRangeTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: TimeRange.values.map((r) {
          final isSelected = r == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1C1C2E)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  r.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF8E8E93),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Line Chart ────────────────────────────────────────────────────────────────

class _LineChart extends StatelessWidget {
  final List<double> dataPoints;
  final String startLabel;

  const _LineChart({required this.dataPoints, required this.startLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: CustomPaint(
            painter: _ChartPainter(dataPoints),
            size: const Size(double.infinity, 160),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              startLabel,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Text(
              'TODAY',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> points;
  _ChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final pad = 8.0;

    // Convert normalised points to canvas coordinates (y-flipped)
    List<Offset> coords = [];
    for (int i = 0; i < points.length; i++) {
      final x = pad + (w - 2 * pad) * i / (points.length - 1);
      final y = pad + (h - 2 * pad) * (1 - points[i]);
      coords.add(Offset(x, y));
    }

    // Build smooth path using cubic bezier
    Path linePath = Path();
    linePath.moveTo(coords[0].dx, coords[0].dy);
    for (int i = 0; i < coords.length - 1; i++) {
      final cp1 = Offset((coords[i].dx + coords[i + 1].dx) / 2, coords[i].dy);
      final cp2 = Offset(
        (coords[i].dx + coords[i + 1].dx) / 2,
        coords[i + 1].dy,
      );
      linePath.cubicTo(
        cp1.dx,
        cp1.dy,
        cp2.dx,
        cp2.dy,
        coords[i + 1].dx,
        coords[i + 1].dy,
      );
    }

    // Fill path (gradient)
    Path fillPath = Path()..addPath(linePath, Offset.zero);
    fillPath.lineTo(coords.last.dx, h);
    fillPath.lineTo(coords.first.dx, h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF34C759).withValues(alpha: 0.18),
          const Color(0xFF34C759).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePaint = Paint()
      ..color = const Color(0xFF34C759)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Dot at end
    final dotPaint = Paint()..color = const Color(0xFF34C759);
    canvas.drawCircle(coords.last, 5, dotPaint);
    canvas.drawCircle(coords.last, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.points != points;
}

// ── Stat Box (High / Low) ─────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Historical Data Row ───────────────────────────────────────────────────────

class _HistoryRow extends StatelessWidget {
  final HistoricalEntry entry;

  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            entry.date,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF3A3A3C),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            entry.rate.toStringAsFixed(4),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            entry.isUp
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 16,
            color: entry.isUp
                ? const Color(0xFF34C759)
                : const Color(0xFFFF3B30),
          ),
        ],
      ),
    );
  }
}
