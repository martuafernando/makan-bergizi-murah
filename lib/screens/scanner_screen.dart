import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:share_plus/share_plus.dart';

import '../models/nutrition_label.dart';
import '../services/nutrition_parser.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _picker = ImagePicker();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  File? _image;
  bool _isScanning = false;
  String? _error;
  NutritionLabel? _result;
  String? _rawOcrText;

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickAndScan(ImageSource source) async {
    setState(() {
      _error = null;
      _isScanning = false;
      _result = null;
      _rawOcrText = null;
    });

    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return;

      final file = File(picked.path);
      setState(() {
        _image = file;
        _isScanning = true;
      });

      // Run OCR
      final inputImage = InputImage.fromFile(file);
      final recognized = await _textRecognizer.processImage(inputImage);
      final rawText = recognized.text;

      if (rawText.trim().isEmpty) {
        setState(() {
          _isScanning = false;
          _error = 'Tidak ada teks yang terdeteksi. Pastikan gambar jelas dan cukup cahaya.';
        });
        return;
      }

      // Parse nutrition label
      final label = NutritionParser.parse(rawText);

      setState(() {
        _isScanning = false;
        _rawOcrText = rawText;
        _result = label;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _error = 'Gagal memproses gambar: ${e.toString()}';
      });
    }
  }

  Future<void> _copyToClipboard() async {
    if (_result == null) return;
    await Clipboard.setData(ClipboardData(text: _result!.toFormattedText()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teks disalin ke clipboard ✓')),
      );
    }
  }

  Future<void> _shareResult() async {
    if (_result == null) return;
    await Share.share(
      _result!.toFormattedText(),
      subject: 'Informasi Nilai Gizi',
    );
  }

  void _reset() {
    setState(() {
      _image = null;
      _result = null;
      _rawOcrText = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Scan Nilai Gizi 🔍'),
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            actions: [
              if (_result != null)
                IconButton(icon: const Icon(Icons.refresh), tooltip: 'Scan ulang', onPressed: _reset),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _result != null
                  ? _ResultView(
                      label: _result!,
                      rawText: _rawOcrText,
                      onCopy: _copyToClipboard,
                      onShare: _shareResult,
                      onRescan: _reset,
                    )
                  : _ScanPanel(
                      image: _image,
                      isScanning: _isScanning,
                      error: _error,
                      onCamera: () => _pickAndScan(ImageSource.camera),
                      onGallery: () => _pickAndScan(ImageSource.gallery),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scan panel (initial state) ───────────────────────────────────────────────

class _ScanPanel extends StatelessWidget {
  final File? image;
  final bool isScanning;
  final String? error;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _ScanPanel({
    required this.image,
    required this.isScanning,
    required this.error,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text('Cara Menggunakan', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const _Step(n: '1', text: 'Foto tabel "Informasi Nilai Gizi" pada kemasan produk'),
              const _Step(n: '2', text: 'Pastikan tabel terlihat jelas, tidak buram, pencahayaan cukup'),
              const _Step(n: '3', text: 'App akan otomatis membaca semua nutrisi dari tabel BPOM'),
              const _Step(n: '4', text: 'Salin atau bagikan hasilnya'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Image preview
        if (image != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(image!, height: 220, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
        ],

        // Scanning indicator
        if (isScanning) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Text('Memindai tabel gizi...', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 20),
        ],

        // Error
        if (error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(error!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Action buttons
        if (!isScanning) ...[
          FilledButton.icon(
            onPressed: onCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Foto Tabel Gizi'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Pilih dari Galeri'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Example label format info
        const _BpomFormatInfo(),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String n;
  final String text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 10, child: Text(n, style: const TextStyle(fontSize: 11))),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _BpomFormatInfo extends StatelessWidget {
  const _BpomFormatInfo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Format Tabel BPOM yang Didukung', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            '✓ Takaran Saji & Jumlah Sajian\n'
            '✓ Energi Total & Energi dari Lemak\n'
            '✓ Lemak Total, Jenuh, Trans\n'
            '✓ Kolesterol & Natrium\n'
            '✓ Karbohidrat, Serat & Gula\n'
            '✓ Protein\n'
            '✓ Vitamin & Mineral\n'
            '✓ %AKG (Angka Kecukupan Gizi)',
            style: TextStyle(fontSize: 12, height: 1.7),
          ),
        ],
      ),
    );
  }
}

// ── Result view ──────────────────────────────────────────────────────────────

class _ResultView extends StatefulWidget {
  final NutritionLabel label;
  final String? rawText;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onRescan;

  const _ResultView({
    required this.label,
    required this.rawText,
    required this.onCopy,
    required this.onShare,
    required this.onRescan,
  });

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  bool _showRaw = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = widget.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success header
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 6),
            Text('Berhasil dibaca!', style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFF388E3C), fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),

        // Main nutrition card
        _NutritionCard(label: label),
        const SizedBox(height: 12),

        // Vitamins & minerals
        if (label.vitaminsAndMinerals.isNotEmpty) ...[
          _VitaminCard(rows: label.vitaminsAndMinerals),
          const SizedBox(height: 12),
        ],

        // Action buttons
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.onCopy,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Salin Teks'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.onShare,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Bagikan'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: widget.onRescan,
          icon: const Icon(Icons.camera_alt, size: 18),
          label: const Text('Scan Produk Lain'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
        ),
        const SizedBox(height: 20),

        // Raw OCR toggle
        if (widget.rawText != null) ...[
          TextButton.icon(
            onPressed: () => setState(() => _showRaw = !_showRaw),
            icon: Icon(_showRaw ? Icons.expand_less : Icons.expand_more, size: 18),
            label: Text(_showRaw ? 'Sembunyikan teks mentah OCR' : 'Lihat teks mentah OCR'),
          ),
          if (_showRaw) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                widget.rawText!,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.5),
              ),
            ),
          ],
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final NutritionLabel label;
  const _NutritionCard({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('INFORMASI NILAI GIZI',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                if (label.productName != null)
                  Text(label.productName!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label.servingSize != null)
                  Text('Takaran Saji: ${label.servingSize}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (label.servingsPerPackage != null)
                  Text('Jumlah Sajian per Kemasan: ${label.servingsPerPackage}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 6, color: Colors.black),

          // Energy
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Energi Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  label.energiTotal != null ? '${label.energiTotal} kkal' : '-',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          if (label.energiDariLemak != null)
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 6),
              child: Text('Energi dari Lemak: ${label.energiDariLemak} kkal',
                  style: const TextStyle(fontSize: 12)),
            ),

          const Divider(height: 1, thickness: 2, color: Colors.black),

          // Table header
          const _TableHeader(),

          const Divider(height: 1, thickness: 0.5, color: Colors.black38),

          // Nutrient rows
          _NutrientRowWidget('Lemak Total', label.lemakTotal),
          _NutrientRowWidget('   Lemak Jenuh', label.lemakJenuh),
          _NutrientRowWidget('   Lemak Trans', label.lemakTrans),
          _NutrientRowWidget('Kolesterol', label.kolesterol),
          _NutrientRowWidget('Protein', label.protein),
          _NutrientRowWidget('Karbohidrat Total', label.karbohidratTotal),
          _NutrientRowWidget('   Serat Pangan', label.seratPangan),
          _NutrientRowWidget('   Gula', label.gula),
          _NutrientRowWidget('Natrium', label.natrium),

          const Divider(height: 1, thickness: 1, color: Colors.black),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              '%AKG = Angka Kecukupan Gizi\nberdasarkan kebutuhan energi 2150 kkal.\nKebutuhan energi Anda mungkin lebih tinggi atau lebih rendah.',
              style: const TextStyle(fontSize: 9, color: Color(0xFF616161), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text('', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: 80,
            child: Text('per sajian', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: 50,
            child: Text('%AKG*', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _NutrientRowWidget extends StatelessWidget {
  final String label;
  final NutrientRow? row;

  const _NutrientRowWidget(this.label, this.row);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              row != null ? '${row!.amount % 1 == 0 ? row!.amount.toInt() : row!.amount} ${row!.unit}' : '-',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              row?.akgPercent != null ? '${row!.akgPercent}%' : '-',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _VitaminCard extends StatelessWidget {
  final List<NutrientRow> rows;
  const _VitaminCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: Colors.black,
            child: const Text('VITAMIN & MINERAL',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          ...rows.map((r) => _NutrientRowWidget(r.name ?? '', r)),
        ],
      ),
    );
  }
}
