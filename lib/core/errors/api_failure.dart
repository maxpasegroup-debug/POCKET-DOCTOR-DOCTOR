class ApiFailure implements Exception {
  const ApiFailure(this.message, [this.status]);
  final String message;
  final int? status;
  @override
  String toString() => message;
}
