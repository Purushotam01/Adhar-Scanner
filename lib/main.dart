import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

void main() {
  runApp(const AadhaarScannerApp());
}

class AadhaarScannerApp extends StatelessWidget {
  const AadhaarScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aadhaar Scanner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TextRecognitionScreen(),
    );
  }
}

class TextRecognitionScreen extends StatefulWidget {
  const TextRecognitionScreen({super.key});

  @override
  TextRecognitionScreenState createState() => TextRecognitionScreenState();
}

class TextRecognitionScreenState extends State<TextRecognitionScreen> {
  File? _imageFile;
  String _extractedText = "";
  Map<String, String> _aadhaarData = {};

  /// Pick Image from Camera or Gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _extractedText = "Processing...";
          _aadhaarData = {};
        });

        final inputImage = InputImage.fromFilePath(pickedFile.path);
        await _processImage(inputImage);
      } else {
        print("No image selected.");
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  /// Process Image and Extract Aadhaar Data
  Future<void> _processImage(InputImage image) async {
    final textRecognizer = TextRecognizer(); // Supports multiple languages including Hindi

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(image);

      setState(() {
        _extractedText = recognizedText.text;
        _aadhaarData = _extractAadhaarData(recognizedText.text);
      });
    } catch (e) {
      setState(() {
        _extractedText = "Error extracting text";
      });
      print("Text recognition error: $e");
    } finally {
      textRecognizer.close(); // Prevent memory leaks
    }
  }

  /// Extract Aadhaar Number, Name, and Date of Birth using Regex
  Map<String, String> _extractAadhaarData(String text) {
    final Map<String, String> data = {};

    RegExp aadhaarRegex = RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b');
    var aadhaarMatch = aadhaarRegex.firstMatch(text);
    if (aadhaarMatch != null) {
      data['Aadhaar Number'] = aadhaarMatch.group(0)!.replaceAll(' ', '');
    }

    RegExp dobRegex = RegExp(r'\b\d{2}/\d{2}/\d{4}\b');
    var dobMatch = dobRegex.firstMatch(text);
    if (dobMatch != null) {
      data['Date of Birth'] = dobMatch.group(0)!;
    }

    if (dobMatch != null) {
      List<String> lines = text.split('\n');
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains(dobMatch.group(0)!)) {
          if (i > 0) {
            data['Name'] = lines[i - 1].trim();
          }
          break;
        }
      }
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aadhaar Scanner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_imageFile != null)
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery), // Allow retapping image
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Image.file(_imageFile!, height: 200),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Extracted Text:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_extractedText.isNotEmpty ? _extractedText : "No text found"),
            const SizedBox(height: 20),
            const Text(
              'Parsed Aadhaar Data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_aadhaarData.isNotEmpty)
              ..._aadhaarData.entries.map((entry) => Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(fontSize: 16),
                  )),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: const Text("Upload Aadhaar Card"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    child: const Text("Capture Aadhaar Card"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
