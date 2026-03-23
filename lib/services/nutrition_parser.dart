import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/nutrition_label.dart';

/// Parses BPOM Tabel Informasi Nilai Gizi from ML Kit RecognizedText.
///
/// Strategy: use bounding box Y-coordinates to reconstruct table rows.
/// OCR on multi-column tables reads column-by-column, so "Lemak Total" and
/// "5g 7%" may appear as separate lines. By grouping all TextLines that share
/// roughly the same Y position, we rebuild each visual row correctly.
class NutritionParser {
  /// Parse using bounding box–aware row reconstruction.
  static NutritionLabel parse(RecognizedText recognizedText) {
    final visualRows = _buildVisualRows(recognizedText);
    final rawText = visualRows.map((r) => r.text).join('\n');
    return _parseRows(visualRows, rawText);
  }

  // ── Step 1: collect all TextLines with Y-center, sort & group ────────────

  static List<_VisualRow> _buildVisualRows(RecognizedText recognized) {
    // Collect every TextLine with its bounding box
    final allLines = <_LineInfo>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final box = line.boundingBox;
        if (box == null) continue;
        final yCenter = box.top + box.height / 2;
        allLines.add(_LineInfo(
          text: line.text.trim(),
          xLeft: box.left,
          yCenter: yCenter,
        ));
      }
    }

    if (allLines.isEmpty) return [];

    // Sort all lines by Y-center (top to bottom)
    allLines.sort((a, b) => a.yCenter.compareTo(b.yCenter));

    // Group lines whose Y-centers are within `tolerance` px of each other
    // (they belong to the same visual table row)
    const double tolerance = 18.0; // ~18px covers typical label row height
    final groups = <List<_LineInfo>>[];
    var current = [allLines.first];

    for (int i = 1; i < allLines.length; i++) {
      final line = allLines[i];
      final groupCenterY = current.map((l) => l.yCenter).reduce((a, b) => a + b) / current.length;
      if ((line.yCenter - groupCenterY).abs() <= tolerance) {
        current.add(line);
      } else {
        groups.add(List.from(current));
        current = [line];
      }
    }
    groups.add(current);

    // Within each group, sort left-to-right by X and join as one string
    return groups.map((group) {
      group.sort((a, b) => a.xLeft.compareTo(b.xLeft));
      final text = group.map((l) => l.text).join('  ');
      return _VisualRow(text: text, lines: group);
    }).toList();
  }

  // ── Step 2: parse reconstructed rows into NutritionLabel ─────────────────

  static NutritionLabel _parseRows(List<_VisualRow> rows, String rawText) {
    String? productName;
    String? servingSize;
    int? servingsPerPackage;
    int? energiTotal;
    int? energiDariLemak;
    NutrientRow? lemakTotal;
    NutrientRow? lemakJenuh;
    NutrientRow? lemakTrans;
    NutrientRow? kolesterol;
    NutrientRow? protein;
    NutrientRow? karbohidratTotal;
    NutrientRow? seratPangan;
    NutrientRow? gula;
    NutrientRow? natrium;
    final vitaminsAndMinerals = <NutrientRow>[];

    bool foundHeader = false;

    for (int i = 0; i < rows.length; i++) {
      final raw = rows[i].text;
      final lu = raw.toUpperCase();

      // ── Header detection ────────────────────────────────────────────────
      if (lu.contains('INFORMASI NILAI GIZI') ||
          lu.contains('NUTRITION FACTS') ||
          lu.contains('NUTRITION INFORMATION')) {
        foundHeader = true;
        if (i > 0) productName = rows[i - 1].text.trim();
        continue;
      }

      // ── Takaran Saji ────────────────────────────────────────────────────
      if (lu.contains('TAKARAN SAJI') || lu.contains('SERVING SIZE')) {
        servingSize = _extractAfterColon(raw) ?? _extractAmountWithUnit(raw);
        continue;
      }

      // ── Jumlah Sajian per Kemasan ────────────────────────────────────────
      if (lu.contains('JUMLAH SAJIAN') || lu.contains('SERVINGS PER')) {
        servingsPerPackage = int.tryParse(_extractFirstInt(raw) ?? '');
        continue;
      }

      // ── Energi Total ─────────────────────────────────────────────────────
      if ((lu.contains('ENERGI TOTAL') || lu.contains('CALORIES') ||
          lu.contains('KALORI')) && !lu.contains('DARI')) {
        energiTotal = int.tryParse(_extractFirstInt(raw) ?? '');
        // Energi dari Lemak might be on the same reconstructed row
        if (lu.contains('DARI LEMAK') || lu.contains('FROM FAT')) {
          final nums = _extractAllInts(raw);
          if (nums.length >= 2) energiDariLemak = nums[1];
        }
        continue;
      }

      // ── Energi dari Lemak ─────────────────────────────────────────────────
      if (lu.contains('DARI LEMAK') || lu.contains('FROM FAT')) {
        energiDariLemak = int.tryParse(_extractFirstInt(raw) ?? '');
        continue;
      }

      // ── Lemak Total ────────────────────────────────────────────────────
      if (_rowStartsWith(lu, ['LEMAK TOTAL', 'TOTAL FAT', 'TOTAL LEMAK']) &&
          !lu.contains('JENUH') && !lu.contains('TRANS') && !lu.contains('SATURATED')) {
        lemakTotal = _parseNutrientFromRow(raw, 'Lemak Total');
        continue;
      }

      // ── Lemak Jenuh ─────────────────────────────────────────────────────
      if (_rowContains(lu, ['LEMAK JENUH', 'SATURATED FAT', 'LEMAK JENUH'])) {
        lemakJenuh = _parseNutrientFromRow(raw, 'Lemak Jenuh');
        continue;
      }

      // ── Lemak Trans ─────────────────────────────────────────────────────
      if (_rowContains(lu, ['LEMAK TRANS', 'TRANS FAT'])) {
        lemakTrans = _parseNutrientFromRow(raw, 'Lemak Trans');
        continue;
      }

      // ── Kolesterol ──────────────────────────────────────────────────────
      if (_rowContains(lu, ['KOLESTEROL', 'CHOLESTEROL'])) {
        kolesterol = _parseNutrientFromRow(raw, 'Kolesterol', defaultUnit: 'mg');
        continue;
      }

      // ── Protein ─────────────────────────────────────────────────────────
      if (_rowStartsWith(lu, ['PROTEIN'])) {
        protein = _parseNutrientFromRow(raw, 'Protein');
        continue;
      }

      // ── Karbohidrat Total ───────────────────────────────────────────────
      if (_rowContains(lu, ['KARBOHIDRAT TOTAL', 'TOTAL CARBOHYDRATE', 'TOTAL KARBOHIDRAT']) &&
          !lu.contains('SERAT') && !lu.contains('GULA') && !lu.contains('FIBER') && !lu.contains('SUGAR')) {
        karbohidratTotal = _parseNutrientFromRow(raw, 'Karbohidrat Total');
        continue;
      }

      // ── Serat Pangan ─────────────────────────────────────────────────────
      if (_rowContains(lu, ['SERAT PANGAN', 'SERAT', 'DIETARY FIBER', 'TOTAL FIBER'])) {
        seratPangan = _parseNutrientFromRow(raw, 'Serat Pangan');
        continue;
      }

      // ── Gula ─────────────────────────────────────────────────────────────
      if (_rowStartsWith(lu, ['GULA', 'SUGAR', 'SUGARS'])) {
        gula = _parseNutrientFromRow(raw, 'Gula');
        continue;
      }

      // ── Natrium ──────────────────────────────────────────────────────────
      if (_rowContains(lu, ['NATRIUM', 'SODIUM'])) {
        natrium = _parseNutrientFromRow(raw, 'Natrium', defaultUnit: 'mg');
        continue;
      }

      // ── Vitamin & Mineral ────────────────────────────────────────────────
      if (foundHeader && _isVitaminOrMineral(lu)) {
        final row = _parseNutrientFromRow(raw, _extractNutrientName(raw));
        if (row != null) vitaminsAndMinerals.add(row);
      }
    }

    return NutritionLabel(
      productName: productName,
      servingSize: servingSize,
      servingsPerPackage: servingsPerPackage,
      energiTotal: energiTotal,
      energiDariLemak: energiDariLemak,
      lemakTotal: lemakTotal,
      lemakJenuh: lemakJenuh,
      lemakTrans: lemakTrans,
      kolesterol: kolesterol,
      protein: protein,
      karbohidratTotal: karbohidratTotal,
      seratPangan: seratPangan,
      gula: gula,
      natrium: natrium,
      vitaminsAndMinerals: vitaminsAndMinerals,
      rawText: rawText,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static bool _rowStartsWith(String lu, List<String> keywords) =>
      keywords.any((k) => lu.trimLeft().startsWith(k));

  static bool _rowContains(String lu, List<String> keywords) =>
      keywords.any((k) => lu.contains(k));

  static bool _isVitaminOrMineral(String lu) {
    const list = [
      'VITAMIN A','VITAMIN B','VITAMIN C','VITAMIN D','VITAMIN E','VITAMIN K',
      'TIAMIN','RIBOFLAVIN','NIASIN','FOLAT','BIOTIN',
      'KALSIUM','KALIUM','FOSFOR','BESI','SENG','IODIUM','SELENIUM',
      'MAGNESIUM','MANGAN','KROM','TEMBAGA',
      'CALCIUM','IRON','POTASSIUM','ZINC',
    ];
    return list.any((v) => lu.contains(v));
  }

  static String _extractNutrientName(String line) {
    final m = RegExp(r'^([A-Za-z\s]+)', unicode: true).firstMatch(line.trim());
    return m?.group(1)?.trim() ?? line.trim();
  }

  /// Parse amount + unit + %AKG from a single reconstructed row.
  /// Row example: "Lemak Total  5 g  7%"
  /// Row example: "Total Fat  5g  7%"
  static NutrientRow? _parseNutrientFromRow(String row, String name,
      {String defaultUnit = 'g'}) {
    // Look for number+unit patterns (5g, 5 g, 100mg, 0 g)
    final amountRegex = RegExp(
      r'(\d+[.,]?\d*)\s*(mg|g|mcg|µg|iu|kkal)\b',
      caseSensitive: false,
    );
    // Look for %AKG (standalone number followed by %)
    final pctRegex = RegExp(r'\b(\d+)\s*%');

    final amountMatch = amountRegex.firstMatch(row);
    final pctMatch = pctRegex.firstMatch(row);

    if (amountMatch == null) return null;

    final amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', '.'));
    if (amount == null) return null;

    final unit = amountMatch.group(2)?.toLowerCase() ?? defaultUnit;
    final pct = pctMatch != null ? int.tryParse(pctMatch.group(1)!) : null;

    return NutrientRow(name: name, amount: amount, unit: unit, akgPercent: pct);
  }

  static String? _extractAfterColon(String line) {
    final idx = line.indexOf(':');
    if (idx < 0) return null;
    return line.substring(idx + 1).trim();
  }

  static String? _extractAmountWithUnit(String line) {
    final m = RegExp(
      r'(\d+[.,]?\d*\s*(?:g|ml|mg|gram|mililiter))',
      caseSensitive: false,
    ).firstMatch(line);
    return m?.group(1)?.trim();
  }

  static String? _extractFirstInt(String line) {
    final m = RegExp(r'\d+').firstMatch(line);
    return m?.group(0);
  }

  static List<int> _extractAllInts(String line) {
    return RegExp(r'\d+').allMatches(line).map((m) => int.parse(m.group(0)!)).toList();
  }
}

class _LineInfo {
  final String text;
  final double xLeft;
  final double yCenter;
  _LineInfo({required this.text, required this.xLeft, required this.yCenter});
}

class _VisualRow {
  final String text;
  final List<_LineInfo> lines;
  _VisualRow({required this.text, required this.lines});
}
