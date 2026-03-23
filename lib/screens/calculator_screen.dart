import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _budgetController = TextEditingController();
  double _budget = 0;
  int _meals = 3;

  double get _perMeal => _meals > 0 ? _budget / _meals : 0;

  String _formatRupiah(double amount) {
    if (amount == 0) return 'Rp 0';
    final int rounded = amount.round();
    final str = rounded.toString();
    final buffer = StringBuffer('Rp ');
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join();
  }

  List<Map<String, dynamic>> get _suggestions {
    if (_perMeal <= 0) return [];
    return [
      {
        'emoji': '🍳',
        'name': 'Nasi Telur Dadar',
        'price': 8000,
        'fits': _perMeal >= 8000,
      },
      {
        'emoji': '🟫',
        'name': 'Nasi Tempe + Sayur',
        'price': 6000,
        'fits': _perMeal >= 6000,
      },
      {
        'emoji': '🥣',
        'name': 'Bubur Ayam',
        'price': 10000,
        'fits': _perMeal >= 10000,
      },
      {
        'emoji': '🥗',
        'name': 'Gado-gado',
        'price': 12000,
        'fits': _perMeal >= 12000,
      },
      {
        'emoji': '🍜',
        'name': 'Mie Ayam',
        'price': 14000,
        'fits': _perMeal >= 14000,
      },
      {
        'emoji': '🐟',
        'name': 'Pecel Lele',
        'price': 15000,
        'fits': _perMeal >= 15000,
      },
    ];
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fittingSuggestions = _suggestions.where((s) => s['fits'] == true).toList();
    final tooExpensive = _suggestions.where((s) => s['fits'] == false).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulator Gizi 🧮'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Berapa budget makan kamu?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        prefixText: 'Rp ',
                        labelText: 'Budget per hari',
                        border: OutlineInputBorder(),
                        hintText: 'contoh: 30000',
                      ),
                      onChanged: (val) {
                        setState(() {
                          _budget = double.tryParse(val) ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Berapa kali makan per hari?',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 2, label: Text('2x')),
                        ButtonSegment(value: 3, label: Text('3x')),
                        ButtonSegment(value: 4, label: Text('4x')),
                      ],
                      selected: {_meals},
                      onSelectionChanged: (val) =>
                          setState(() => _meals = val.first),
                    ),
                  ],
                ),
              ),
            ),
            // Result
            if (_budget > 0) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budget per makan',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            _formatRupiah(_perMeal),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_formatRupiah(_budget)} ÷ $_meals',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (fittingSuggestions.isNotEmpty) ...[
                Text(
                  '✅ Bisa kamu beli',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 8),
                ...fittingSuggestions.map((s) => _SuggestionTile(
                      emoji: s['emoji'],
                      name: s['name'],
                      price: s['price'],
                      fits: true,
                    )),
              ],
              if (tooExpensive.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '❌ Di luar budget',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 8),
                ...tooExpensive.map((s) => _SuggestionTile(
                      emoji: s['emoji'],
                      name: s['name'],
                      price: s['price'],
                      fits: false,
                    )),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final String emoji;
  final String name;
  final int price;
  final bool fits;

  const _SuggestionTile({
    required this.emoji,
    required this.name,
    required this.price,
    required this.fits,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fits
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: fits ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fits ? null : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            'Rp ${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: fits ? Colors.green[700] : Colors.red[400],
            ),
          ),
        ],
      ),
    );
  }
}
