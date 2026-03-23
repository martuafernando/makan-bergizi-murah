/// Data model for BPOM Tabel Informasi Nilai Gizi
/// Based on PerBPOM No. 22 Tahun 2019 format
class NutritionLabel {
  final String? productName;
  final String? servingSize;      // Takaran Saji
  final int? servingsPerPackage;  // Jumlah Sajian per Kemasan
  final int? energiTotal;         // kkal
  final int? energiDariLemak;     // kkal

  final NutrientRow? lemakTotal;
  final NutrientRow? lemakJenuh;
  final NutrientRow? lemakTrans;
  final NutrientRow? kolesterol;
  final NutrientRow? protein;
  final NutrientRow? karbohidratTotal;
  final NutrientRow? seratPangan;
  final NutrientRow? gula;
  final NutrientRow? natrium;

  final List<NutrientRow> vitaminsAndMinerals;
  final String? rawText; // original OCR text

  const NutritionLabel({
    this.productName,
    this.servingSize,
    this.servingsPerPackage,
    this.energiTotal,
    this.energiDariLemak,
    this.lemakTotal,
    this.lemakJenuh,
    this.lemakTrans,
    this.kolesterol,
    this.protein,
    this.karbohidratTotal,
    this.seratPangan,
    this.gula,
    this.natrium,
    this.vitaminsAndMinerals = const [],
    this.rawText,
  });

  String toFormattedText() {
    final buf = StringBuffer();
    buf.writeln('═══════════════════════════════');
    buf.writeln(' INFORMASI NILAI GIZI');
    buf.writeln('═══════════════════════════════');
    if (productName != null) buf.writeln('Produk      : $productName');
    if (servingSize != null) buf.writeln('Takaran Saji: $servingSize');
    if (servingsPerPackage != null) buf.writeln('Sajian/Kemasan: $servingsPerPackage');
    buf.writeln('───────────────────────────────');
    if (energiTotal != null) buf.writeln('Energi Total        : ${energiTotal} kkal');
    if (energiDariLemak != null) buf.writeln('Energi dari Lemak   : ${energiDariLemak} kkal');
    buf.writeln('───────────────────────────────');
    buf.writeln('Kandungan per Sajian         %AKG');

    void writeRow(String label, NutrientRow? row, {bool indent = false}) {
      if (row == null) return;
      final prefix = indent ? '  ' : '';
      final pct = row.akgPercent != null ? '${row.akgPercent}%' : '-';
      buf.writeln('${prefix}$label'.padRight(28) + '${row.amount} ${row.unit}'.padRight(10) + pct);
    }

    writeRow('Lemak Total', lemakTotal);
    writeRow('Lemak Jenuh', lemakJenuh, indent: true);
    writeRow('Lemak Trans', lemakTrans, indent: true);
    writeRow('Kolesterol', kolesterol);
    writeRow('Protein', protein);
    writeRow('Karbohidrat Total', karbohidratTotal);
    writeRow('Serat Pangan', seratPangan, indent: true);
    writeRow('Gula', gula, indent: true);
    writeRow('Natrium', natrium);

    if (vitaminsAndMinerals.isNotEmpty) {
      buf.writeln('───────────────────────────────');
      for (final v in vitaminsAndMinerals) {
        final pct = v.akgPercent != null ? '${v.akgPercent}%' : '-';
        buf.writeln('${v.name ?? ''}'.padRight(28) + '${v.amount} ${v.unit}'.padRight(10) + pct);
      }
    }

    buf.writeln('═══════════════════════════════');
    buf.writeln('%AKG = Angka Kecukupan Gizi');
    return buf.toString();
  }
}

class NutrientRow {
  final String? name;
  final double amount;
  final String unit;
  final int? akgPercent;

  const NutrientRow({
    this.name,
    required this.amount,
    required this.unit,
    this.akgPercent,
  });
}
