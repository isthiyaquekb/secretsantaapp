class EmployeePair {
  final String picker;
  final String picked;
  final String? giftIdea;
  final bool hasDrawn;

  EmployeePair({
    required this.picker,
    required this.picked,
    this.giftIdea,
    this.hasDrawn = false,
  });

  EmployeePair copyWith({
    String? picker,
    String? picked,
    String? giftIdea,
    bool? hasDrawn,
  }) {
    return EmployeePair(
      picker: picker ?? this.picker,
      picked: picked ?? this.picked,
      giftIdea: giftIdea ?? this.giftIdea,
      hasDrawn: hasDrawn ?? this.hasDrawn,
    );
  }

  Map<String, dynamic> toJson() => {
    'picker': picker,
    'picked': picked,
    'giftIdea': giftIdea,
    'hasDrawn': hasDrawn,
  };

  factory EmployeePair.fromJson(Map<String, dynamic> json) => EmployeePair(
    picker: json['picker'] as String,
    picked: json['picked'] as String,
    giftIdea: json['giftIdea'] as String?,
    hasDrawn: json['hasDrawn'] as bool? ?? false,
  );

  @override
  String toString() {
    return '$picker picks $picked';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmployeePair &&
        picker == other.picker &&
        picked == other.picked;
  }

  @override
  int get hashCode => Object.hash(picker, picked);
}
