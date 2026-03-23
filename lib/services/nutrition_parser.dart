import '../models/nutrition_label.dart';

/// Parses raw OCR text from BPOM Tabel Informasi Nilai Gizi
/// into a structured NutritionLabel model.
///
/// BPOM label format (PerBPOM No.22/2019):
///   Takaran Saji: Xg / Xml
///   Jumlah Sajian per Kemasan: N
///   Energi Total: X kkal  Energi dari Lemak: X kkal
///   [Nutrient] [amount][unit] [%AKG]
class NutritionParser {
  static NutritionLabel parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

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

    // Try to find product name (usually before "INFORMASI NILAI GIZI" header)
    bool foundHeader = false;
    for (int i = 0; i < lines.length; i++) {
      final l = lines[i];
      final lu = l.toUpperCase();

      if (lu.contains('INFORMASI NILAI GIZI') || lu.contains('INFORMATION') || lu.contains('NUTRITION FACTS')) {
        foundHeader = true;
        if (i > 0) productName = lines[i - 1];
        continue;
      }

      // Takaran Saji
      if (lu.contains('TAKARAN SAJI') || lu.contains('SERVING SIZE')) {
        servingSize = _extractAfterColon(l) ?? _extractNumberWithUnit(l);
        continue;
      }

      // Jumlah Sajian per Kemasan
      if (lu.contains('JUMLAH SAJIAN') || lu.contains('SERVINGS PER') || lu.contains('SAJIAN PER KEMASAN')) {
        final numStr = _extractFirstNumber(l);
        if (numStr != null) servingsPerPackage = int.tryParse(numStr);
        continue;
      }

      // Energi Total
      if (lu.contains('ENERGI TOTAL') || lu.contains('KALORI') || lu.contains('CALORIES') || lu.contains('ENERGI:')) {
        final num = _extractFirstNumber(l);
        if (num != null) energiTotal = int.tryParse(num);

        // Energi dari Lemak might be on same line
        if (lu.contains('DARI LEMAK') || lu.contains('FROM FAT')) {
          final nums = _extractAllNumbers(l);
          if (nums.length >= 2) energiDariLemak = int.tryParse(nums[1]);
        }
        continue;
      }

      // Energi dari Lemak (separate line)
      if (lu.contains('DARI LEMAK') || lu.contains('FROM FAT')) {
        final num = _extractFirstNumber(l);
        if (num != null) energiDariLemak = int.tryParse(num);
        continue;
      }

      // Lemak Total / Total Fat
      if (_matchesNutrient(lu, ['LEMAK TOTAL', 'TOTAL FAT', 'TOTAL LEMAK']) && !lu.contains('JENUH') && !lu.contains('TRANS')) {
        lemakTotal = _parseNutrientRow(l, 'Lemak Total');
        continue;
      }

      // Lemak Jenuh / Saturated Fat
      if (_matchesNutrient(lu, ['LEMAK JENUH', 'SATURATED FAT', 'JENUH'])) {
        lemakJenuh = _parseNutrientRow(l, 'Lemak Jenuh');
        continue;
      }

      // Lemak Trans / Trans Fat
      if (_matchesNutrient(lu, ['LEMAK TRANS', 'TRANS FAT', 'TRANS'])) {
        lemakTrans = _parseNutrientRow(l, 'Lemak Trans');
        continue;
      }

      // Kolesterol / Cholesterol
      if (_matchesNutrient(lu, ['KOLESTEROL', 'CHOLESTEROL'])) {
        kolesterol = _parseNutrientRow(l, 'Kolesterol', defaultUnit: 'mg');
        continue;
      }

      // Protein
      if (_matchesNutrient(lu, ['PROTEIN'])) {
        protein = _parseNutrientRow(l, 'Protein');
        continue;
      }

      // Karbohidrat Total / Total Carbohydrate
      if (_matchesNutrient(lu, ['KARBOHIDRAT TOTAL', 'TOTAL CARBOHYDRATE', 'KARBOHIDRAT']) && !lu.contains('SERAT') && !lu.contains('GULA')) {
        karbohidratTotal = _parseNutrientRow(l, 'Karbohidrat Total');
        continue;
      }

      // Serat Pangan / Dietary Fiber
      if (_matchesNutrient(lu, ['SERAT PANGAN', 'SERAT', 'DIETARY FIBER', 'FIBER'])) {
        seratPangan = _parseNutrientRow(l, 'Serat Pangan');
        continue;
      }

      // Gula / Sugar
      if (_matchesNutrient(lu, ['GULA', 'SUGARS', 'SUGAR'])) {
        gula = _parseNutrientRow(l, 'Gula');
        continue;
      }

      // Natrium / Sodium
      if (_matchesNutrient(lu, ['NATRIUM', 'SODIUM'])) {
        natrium = _parseNutrientRow(l, 'Natrium', defaultUnit: 'mg');
        continue;
      }

      // Vitamins and minerals (lines with % AKG after main nutrients)
      if (foundHeader && _isVitaminOrMineral(lu)) {
        final row = _parseNutrientRow(l, _cleanNutrientName(l));
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

  static bool _matchesNutrient(String line, List<String> keywords) {
    return keywords.any((k) => line.contains(k));
  }

  static bool _isVitaminOrMineral(String line) {
    const vitMins = [
      'VITAMIN A', 'VITAMIN B', 'VITAMIN C', 'VITAMIN D', 'VITAMIN E', 'VITAMIN K',
      'TIAMIN', 'RIBOFLAVIN', 'NIASIN', 'FOLAT', 'BIOTIN',
      'KALSIUM', 'KALIUM', 'FOSFOR', 'BESI', 'SENG', 'IODIUM', 'SELENIUM',
      'MAGNESIUM', 'MANGAN', 'KROM', 'TEMBAGA', 'FLOURIDA',
      'CALCIUM', 'IRON', 'POTASSIUM', 'ZINC',
    ];
    return vitMins.any((v) => line.toUpperCase().contains(v));
  }

  static String _cleanNutrientName(String line) {
    // Extract just the nutrient name before any numbers
    final match = RegExp(r'^([A-Za-z\s]+)').firstMatch(line.trim());
    return match?.group(1)?.trim() ?? line.trim();
  }

  static NutrientRow? _parseNutrientRow(String line, String name, {String defaultUnit = 'g'}) {
    // Extract amount + unit + optional %AKG
    // Pattern: word... NUMBER UNIT  NUMBER%
    final numPattern = RegExp(r'(\d+[.,]?\d*)\s*(mg|g|mcg|µg|iu|kkal|%)?', caseSensitive: false);
    final matches = numPattern.allMatches(line).toList();

    if (matches.isEmpty) return null;

    double? amount;
    String unit = defaultUnit;
    int? akgPercent;

    // Find the first number that looks like a nutrient amount
    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      final numStr = m.group(1)!.replaceAll(',', '.');
      final unitStr = (m.group(2) ?? '').toLowerCase();

      if (amount == null && !unitStr.contains('%')) {
        amount = double.tryParse(numStr);
        if (unitStr.isNotEmpty) unit = unitStr;
      } else if (amount != null && (unitStr.contains('%') || line.substring(m.start).contains('%'))) {
        // This might be the %AKG value
        akgPercent = int.tryParse(numStr);
        break;
      }
    }

    // Look for explicit % sign after the number
    final pctMatch = RegExp(r'(\d+)\s*%').firstMatch(line);
    if (pctMatch != null && akgPercent == null) {
      akgPercent = int.tryParse(pctMatch.group(1)!);
    }

    if (amount == null) return null;

    return NutrientRow(
      name: name,
      amount: amount,
      unit: unit,
      akgPercent: akgPercent,
    );
  }

  static String? _extractAfterColon(String line) {
    final idx = line.indexOf(':');
    if (idx < 0) return null;
    return line.substring(idx + 1).trim();
  }

  static String? _extractNumberWithUnit(String line) {
    final m = RegExp(r'(\d+[.,]?\d*\s*(?:g|ml|mg|gram|mililiter))', caseSensitive: false).firstMatch(line);
    return m?.group(1)?.trim();
  }

  static String? _extractFirstNumber(String line) {
    final m = RegExp(r'\d+').firstMatch(line);
    return m?.group(0);
  }

  static List<String> _extractAllNumbers(String line) {
    return RegExp(r'\d+').allMatches(line).map((m) => m.group(0)!).toList();
  }
}
