import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'skin_result.dart';

/// Service that communicates with the Hugging Face Inference API.
class SkinCheckerService {
  /// The Hugging Face Inference API endpoint for the Skin Disease model.
  static const String _apiUrl =
      'https://router.huggingface.co/hf-inference/models/Jayanth2002/dinov2-base-finetuned-SkinDisease';

  /// The Hugging Face Access Token loaded from .env
  static final String _hfToken = dotenv.env['HF_TOKEN'] ?? '';

  /// Brief descriptions for known skin conditions returned by the model.
  static const Map<String, String> _diseaseDescriptions = {
    'Acne':
        'A common skin condition where hair follicles become clogged with oil and dead skin cells, causing pimples, blackheads, or whiteheads. Usually appears on the face, chest, and back.',
    'Melanoma':
        'A serious form of skin cancer that develops from melanocytes (pigment-producing cells). Early detection is crucial. Look for asymmetry, irregular borders, uneven color, and diameter larger than 6mm.',
    'Eczema':
        'Also known as atopic dermatitis, it causes the skin to become inflamed, itchy, red, cracked, and rough. It is a chronic condition with periodic flare-ups.',
    'Psoriasis':
        'An autoimmune condition that causes rapid skin cell buildup, resulting in scaling on the skin surface. Patches are typically red, itchy, and sometimes painful.',
    'Rosacea':
        'A chronic skin condition causing redness, visible blood vessels, and sometimes small bumps on the face. Triggers include sun exposure, stress, and spicy foods.',
    'Benign Tumors':
        'Non-cancerous growths on the skin that do not spread to other parts of the body. Common types include moles, skin tags, and seborrheic keratoses.',
    'Malignant Tumors':
        'Cancerous skin growths that can invade surrounding tissues. Early medical evaluation and biopsy are strongly recommended.',
    'Dermatofibroma':
        'A common, harmless skin growth that usually appears on the legs. It feels like a hard lump and is typically brownish in color.',
    'Vascular Lesions':
        'Abnormalities of blood vessels in the skin, including cherry angiomas, spider angiomas, and port-wine stains. Most are benign.',
    'Fungal Infections':
        'Skin infections caused by fungi, including ringworm, athlete\'s foot, and jock itch. They often cause itchy, red, scaly patches.',
    'Warts':
        'Small, rough growths caused by the human papillomavirus (HPV). They are contagious and can appear anywhere on the body.',
    'Basal Cell Carcinoma':
        'The most common type of skin cancer. It grows slowly and rarely spreads, but can cause significant local damage if untreated.',
    'Squamous Cell Carcinoma':
        'A common form of skin cancer arising from squamous cells. It can grow and spread if not treated. UV exposure is a major risk factor.',
    'Seborrheic Keratosis':
        'A common non-cancerous skin growth that appears as a waxy, brown, or black spot. It typically appears in middle-aged and older adults.',
    'Tinea':
        'A fungal infection also known as ringworm. It causes a red, circular, itchy rash. It is highly contagious but treatable with antifungal medication.',
    'Vitiligo':
        'A condition where the skin loses its pigment cells (melanocytes), resulting in discolored patches. It can affect any area of the body.',
  };

  /// Returns the top [count] predictions for the given [imageFile].
  Future<List<SkinResult>> predictTop(File imageFile, {int count = 3}) async {
    final bytes = await imageFile.readAsBytes();

    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Authorization': 'Bearer $_hfToken',
            'Content-Type': 'application/octet-stream',
          },
          body: bytes,
        )
        .timeout(const Duration(seconds: 60)); // Long timeout for cold starts

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      // The API returns a list of prediction dictionaries.
      // E.g., [{"label": "Melanoma", "score": 0.95}, ...]
      if (jsonResponse is List && jsonResponse.isNotEmpty) {
        final topResults = jsonResponse.take(count).map((item) {
          final label = item['label'] as String;
          final score = (item['score'] as num).toDouble();
          return SkinResult(
            disease: label,
            confidence: score,
            description: _getDescription(label),
          );
        }).toList();

        return topResults;

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

  /// Looks up the description for a label, with a fallback.
  static String _getDescription(String label) {
    // Try exact match first
    if (_diseaseDescriptions.containsKey(label)) {
      return _diseaseDescriptions[label]!;
    }
    // Try case-insensitive partial match
    for (final entry in _diseaseDescriptions.entries) {
      if (label.toLowerCase().contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(label.toLowerCase())) {
        return entry.value;
      }
    }
    return 'A skin condition detected by the AI model. Please consult a dermatologist for a proper diagnosis and treatment plan.';
  }
}
