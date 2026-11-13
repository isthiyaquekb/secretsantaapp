class DrawState {
  const DrawState({
    required this.year,
    this.participants = const [],
    this.pairings = const {},
    this.revealed = const {},
    this.exchangeDate,
  });

  final int year;
  final List<String> participants;
  final Map<String, String> pairings; // giver -> receiver
  final Set<String> revealed;
  final DateTime? exchangeDate;

  bool get isDrawn => pairings.isNotEmpty;
  bool get isComplete =>
      isDrawn && participants.isNotEmpty && participants.every(revealed.contains);

  DrawState copyWith({
    int? year,
    List<String>? participants,
    Map<String, String>? pairings,
    Set<String>? revealed,
    DateTime? exchangeDate,
  }) =>
      DrawState(
        year: year ?? this.year,
        participants: participants ?? this.participants,
        pairings: pairings ?? this.pairings,
        revealed: revealed ?? this.revealed,
        exchangeDate: exchangeDate ?? this.exchangeDate,
      );

  Map<String, dynamic> toJson() => {
        'year': year,
        'participants': participants,
        'pairings': pairings,
        'revealed': revealed.toList(),
        'exchangeDate': exchangeDate?.toIso8601String(),
      };

  factory DrawState.fromJson(Map<String, dynamic> j) => DrawState(
        year: j['year'] as int,
        participants: List<String>.from(j['participants'] ?? const []),
        pairings: Map<String, String>.from(j['pairings'] ?? const {}),
        revealed: Set<String>.from(j['revealed'] ?? const []),
        exchangeDate: j['exchangeDate'] == null
            ? null
            : DateTime.parse(j['exchangeDate'] as String),
      );
}

