/// Simple model for a single skin-disease prediction.
class SkinResult {
  final String disease;
  final double confidence;

  /// A brief description of the condition for the expanded detail view.
  final String description;

  const SkinResult({
    required this.disease,
    required this.confidence,
    this.description = '',
  });

  factory SkinResult.fromJson(Map<String, dynamic> json) {
    return SkinResult(
      disease: json['disease'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      description: json['description'] as String? ?? '',
    );
  }

  /// Confidence as a human-readable percentage string.
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';
}
