import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  double _convertedAmount = 0.0;
  double _displayAmount = 0.0; // animated display value
  double _rate = 0.0;
  bool _isLoading = false;
  bool _hasResult = false;
  String? _errorMessage;

  final TextEditingController _amountController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultKey = GlobalKey();

  static const String _accessKey = '270ca084-96a82de7-ae4aff0f-60b941d9';

  final List<Map<String, dynamic>> _quickRates = [
    {'code': 'GBP', 'rate': 83.02, 'trend': 'up'},
    {'code': 'JPY', 'rate': 231.89, 'trend': 'down'},
    {'code': 'AUD', 'rate': 120.98, 'trend': 'up'},
  ];

  final Map<String, Map<String, String>> _currencies = {
    'USD': {'name': 'US Dollar', 'flag': '🇺🇸'},
    'EUR': {'name': 'Euro', 'flag': '🇪🇺'},
    'GBP': {'name': 'British Pound', 'flag': '🇬🇧'},
    'JPY': {'name': 'Japanese Yen', 'flag': '🇯🇵'},
    'AUD': {'name': 'Australian Dollar', 'flag': '🇦🇺'},
    'INR': {'name': 'Indian Rupee', 'flag': '🇮🇳'},
    'CAD': {'name': 'Canadian Dollar', 'flag': '🇨🇦'},
    'CHF': {'name': 'Swiss Franc', 'flag': '🇨🇭'},
    'CNY': {'name': 'Chinese Yuan', 'flag': '🇨🇳'},
    'SGD': {'name': 'Singapore Dollar', 'flag': '🇸🇬'},
  };

  @override
  void initState() {
    super.initState();
    _fetchQuickRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Count-up Animation ─────────────────────────────────────────────────────
  void _animateCountUp(double targetAmount) {
    const steps = 60;
    const stepDuration = Duration(milliseconds: 20); // 60 × 20ms = 1200ms

    double current = 0.0;
    final increment = targetAmount / steps;
    int stepCount = 0;

    Timer.periodic(stepDuration, (timer) {
      stepCount++;
      current += increment;
      if (stepCount >= steps) {
        current = targetAmount;
        timer.cancel();
      }
      if (mounted) {
        setState(() => _displayAmount = current);
      }
    });
  }

  // ── Convert ────────────────────────────────────────────────────────────────
  Future<void> _convertNow() async {
    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasResult = false;
      _displayAmount = 0.0;
    });

    try {
      final uri = Uri.parse(
        'https://api.exconvert.com/convert'
        '?from=$_fromCurrency&to=$_toCurrency&amount=$amount&access_key=$_accessKey',
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result'] as Map<String, dynamic>;
        final convertedAmount = result[_toCurrency];
        final rate = result['rate'];

        setState(() {
          _convertedAmount = (convertedAmount).toDouble();
          _rate = (rate).toDouble();
          _hasResult = true;
        });

        // 👇 Start count-up animation
        _animateCountUp(_convertedAmount);

        // 👇 Scroll to result card
        await Future.delayed(const Duration(milliseconds: 300));
        final resultContext = _resultKey.currentContext;
        if (resultContext != null) {
          Scrollable.ensureVisible(
            resultContext,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.3,
          );
        }
      } else {
        setState(() => _errorMessage = 'Failed to fetch rate. Try again.');
      }
    } catch (_) {
      setState(() => _errorMessage = 'Network error. Check your connection.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Quick Rates ────────────────────────────────────────────────────────────
  Future<void> _fetchQuickRates() async {
    for (int i = 0; i < _quickRates.length; i++) {
      try {
        final code = _quickRates[i]['code'] as String;
        final uri = Uri.parse(
          'https://api.exconvert.com/convert'
          '?from=USD&to=$code&amount=1&access_key=$_accessKey',
        );
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final rate = data['conversion_result'] ?? data['result'] ?? 0.0;
          setState(() {
            _quickRates[i]['rate'] = (rate as num).toDouble();
          });
        }
      } catch (_) {}
    }
  }

  // ── Swap ───────────────────────────────────────────────────────────────────
  void _swapCurrencies() {
    setState(() {
      final tmp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = tmp;
      _hasResult = false;
      _displayAmount = 0.0;
    });
  }

  // ── Currency Picker ────────────────────────────────────────────────────────
  void _openCurrencyPicker({required bool isFrom}) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CurrencyPickerSheet(
        currencies: _currencies,
        selected: isFrom ? _fromCurrency : _toCurrency,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromCurrency = picked;
        } else {
          _toCurrency = picked;
        }
        _hasResult = false;
        _displayAmount = 0.0;
      });
    }
  }

  // ── Format ─────────────────────────────────────────────────────────────────
  String _formatAmount(double val) {
    if (val >= 1000) {
      return val
          .toStringAsFixed(2)
          .replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return val.toStringAsFixed(2);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),

            // Header
            const Center(
              child: Column(
                children: [
                  Text(
                    'REAL-TIME EXCHANGE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Convert',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: -1.0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Main Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Field
                  const Text(
                    'AMOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter amount',
                        hintStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8E8E93),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // FROM
                  const Text(
                    'FROM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _CurrencySelector(
                    code: _fromCurrency,
                    name: _currencies[_fromCurrency]!['name']!,
                    flag: _currencies[_fromCurrency]!['flag']!,
                    onTap: () => _openCurrencyPicker(isFrom: true),
                  ),

                  // Swap Button
                  Center(
                    child: GestureDetector(
                      onTap: _swapCurrencies,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1C1C2E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_vert_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  // TO
                  const Text(
                    'TO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _CurrencySelector(
                    code: _toCurrency,
                    name: _currencies[_toCurrency]!['name']!,
                    flag: _currencies[_toCurrency]!['flag']!,
                    onTap: () => _openCurrencyPicker(isFrom: false),
                  ),

                  const SizedBox(height: 20),

                  // Error
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFFF3B30),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFFF3B30),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Convert Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _convertNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1C1C2E),
                        disabledBackgroundColor: const Color(
                          0xFF1C1C2E,
                        ).withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.currency_exchange_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                      label: Text(
                        _isLoading ? 'Converting...' : 'Convert Now',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  // ── Result Card ──────────────────────────────────────────
                  if (_hasResult) ...[
                    const SizedBox(height: 20),
                    Container(
                      key: _resultKey,
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'CONVERTED AMOUNT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.4,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // 👇 uses _displayAmount for count-up effect
                              Text(
                                _formatAmount(_displayAmount),
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Text(
                                  _toCurrency,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF34C759),
                                size: 15,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Transaction Ready',
                                style: TextStyle(
                                  color: Color(0xFF34C759),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 13,
                                color: Color(0xFF8E8E93),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '1 $_fromCurrency = ${_rate.toStringAsFixed(4)} $_toCurrency',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick Rates Row
            Row(
              children: _quickRates
                  .map(
                    (item) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: item == _quickRates.first ? 0 : 6,
                          right: item == _quickRates.last ? 0 : 6,
                        ),
                        child: _QuickRateCard(
                          code: item['code'],
                          rate: item['rate'],
                          isUp: item['trend'] == 'up',
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ── Currency Selector ─────────────────────────────────────────────────────────

class _CurrencySelector extends StatelessWidget {
  final String code;
  final String name;
  final String flag;
  final VoidCallback onTap;

  const _CurrencySelector({
    required this.code,
    required this.name,
    required this.flag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black54,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Currency Picker Sheet ─────────────────────────────────────────────────────

class _CurrencyPickerSheet extends StatefulWidget {
  final Map<String, Map<String, String>> currencies;
  final String selected;

  const _CurrencyPickerSheet({
    required this.currencies,
    required this.selected,
  });

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.currencies.entries
        .where(
          (e) =>
              e.key.toLowerCase().contains(_search.toLowerCase()) ||
              e.value['name']!.toLowerCase().contains(_search.toLowerCase()),
        )
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Currency',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF8E8E93),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search currency...',
                        hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final code = filtered[i].key;
                  final info = filtered[i].value;
                  final isSelected = code == widget.selected;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          info['flag']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    title: Text(
                      '$code - ${info['name']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      _currencyFullName(code),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF34C759),
                          )
                        : null,
                    onTap: () => Navigator.pop(context, code),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _currencyFullName(String code) {
    const map = {
      'USD': 'United States Dollar',
      'EUR': 'European Union Euro',
      'GBP': 'United Kingdom Pound Sterling',
      'JPY': 'Japanese Yen',
      'AUD': 'Australian Dollar',
      'INR': 'Indian Rupee',
      'CAD': 'Canadian Dollar',
      'CHF': 'Swiss Franc',
      'CNY': 'Chinese Yuan Renminbi',
      'SGD': 'Singapore Dollar',
    };
    return map[code] ?? '';
  }
}

// ── Quick Rate Card ───────────────────────────────────────────────────────────

class _QuickRateCard extends StatelessWidget {
  final String code;
  final double rate;
  final bool isUp;

  const _QuickRateCard({
    required this.code,
    required this.rate,
    required this.isUp,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = isUp ? const Color(0xFF34C759) : const Color(0xFFFF3B30);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            code,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rate == 0.0
                ? '...'
                : rate >= 100
                ? rate.toStringAsFixed(1)
                : rate.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 4, color: const Color(0xFFE5E5EA)),
                FractionallySizedBox(
                  widthFactor: isUp ? 0.65 : 0.35,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: trendColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
