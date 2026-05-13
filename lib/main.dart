import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env"); // Load file .env
  runApp(const MaterialApp(home: SmartImageAnalyzer()));
}

class SmartImageAnalyzer extends StatefulWidget {
  const SmartImageAnalyzer({super.key});

  @override
  State<SmartImageAnalyzer> createState() => _SmartImageAnalyzerState();
}

class _SmartImageAnalyzerState extends State<SmartImageAnalyzer> {
  File? _selectedImage;
  String _analysisResult = "Belum ada analisis. Ambil foto terlebih dahulu.";
  bool _isLoading = false;

  final String _apiKey =
      dotenv.env['GEMINI_API_KEY'] ?? 'KUNCI_TIDAK_DITEMUKAN';

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _analysisResult =
            "Foto terpilih. Klik 'Analisis Sekarang' untuk memproses.";
      });
    }
  }

  Future<void> _analyzeWithGemini() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _analysisResult = "Sedang menganalisis gambar...";
    });

    try {
      // 1. Inisialisasi Model
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);

      // 2. Siapkan Data Gambar
      final imageBytes = await _selectedImage!.readAsBytes();
      final prompt = TextPart(
        "Tolong jelaskan secara detail apa yang ada di gambar ini dalam Bahasa Indonesia.",
      );
      final imagePart = DataPart('image/jpeg', imageBytes);

      // 3. Panggil API
      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      setState(() {
        _analysisResult = response.text ?? "Gagal mendapatkan respon dari AI.";
      });
    } catch (e) {
      setState(() {
        _analysisResult = "Terjadi kesalahan: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Image Analyzer"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Gambar
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : const Center(child: Text("Belum ada gambar")),
            ),
            const SizedBox(height: 16),

            // Tombol Ambil Foto
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Kamera"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Galeri"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tombol Analisis
            ElevatedButton(
              onPressed: (_selectedImage == null || _isLoading)
                  ? null
                  : _analyzeWithGemini,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Analisis Sekarang",
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 24),

            // Hasil Analisis
            const Text(
              "Hasil Analisis:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _analysisResult,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
