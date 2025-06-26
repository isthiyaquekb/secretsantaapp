class EmployeePair {
  final String picker;
  final String picked;

  EmployeePair({required this.picker, required this.picked,});

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