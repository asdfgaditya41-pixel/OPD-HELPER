import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'skin_result.dart';

/// Service that communicates with the Hugging Face Inference API.
class SkinCheckerService {
  /// The Hugging Face Inference API endpoint for the Skin Disease model.
  static const String _apiUrl =
      'https://router.huggingface.co/hf-inference/models/Jayanth2002/dinov2-base-finetuned-SkinDisease';

  /// ⚠️ IMPORTANT: Replace this with your actual Hugging Face Access Token.
  /// You can get one for free at https://huggingface.co/settings/tokens
  static const String _hfToken = 'YOUR_HF_TOKEN_HERE';

  /// Sends the [imageFile] directly to Hugging Face and returns a [SkinResult].
  Future<SkinResult> predict(File imageFile) async {
    final bytes = await imageFile.readAsBytes();

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $_hfToken',
        'Content-Type': 'application/octet-stream',
      },
      body: bytes,
    ).timeout(const Duration(seconds: 60)); // Long timeout for cold starts

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      
      // The API returns a list of prediction dictionaries.
      // E.g., [{"label": "Melanoma", "score": 0.95}, ...]
      if (jsonResponse is List && jsonResponse.isNotEmpty) {
        final topResult = jsonResponse.first as Map<String, dynamic>;
        
        return SkinResult(
          disease: topResult['label'] as String,
          confidence: (topResult['score'] as num).toDouble(),
        );
      } else {
        throw const HttpException('Unexpected JSON format from API');
      }
    } else if (response.statusCode == 503) {
      // 503 means the model is loading (cold start)
      final jsonResponse = jsonDecode(response.body);
      final estimatedTime = jsonResponse['estimated_time'] ?? 20;
      throw HttpException(
        'Model is waking up. Please wait ~${estimatedTime.round()} seconds and click Analyze again.',
      );
    } else {
      throw HttpException(
        'Prediction failed (${response.statusCode}): ${response.body}',
      );
    }
  }
}
