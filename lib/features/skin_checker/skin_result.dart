/// Simple model for the skin-disease prediction response.
class SkinResult {
  final String disease;
  final double confidence;

  const SkinResult({required this.disease, required this.confidence});

  factory SkinResult.fromJson(Map<String, dynamic> json) {
    return SkinResult(
      disease: json['disease'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  /// Confidence as a human-readable percentage string.
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
}
