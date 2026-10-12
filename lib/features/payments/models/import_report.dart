class ImportReport {
  int acceptedRows = 0;
  int rejectedRows = 0;
  final List<Map<String, dynamic>> _errors = [];

  void accept() => acceptedRows++;

  void reject(int row, String matricule, String reason) {
    rejectedRows++;
    _errors.add({'row': row, 'matricule': matricule, 'reason': reason});
  }

  void addGlobalError(String reason) {
    _errors.add({'row': 0, 'matricule': '', 'reason': reason});
  }

  List<Map<String, dynamic>> get errorsJson => List.unmodifiable(_errors);

  bool get hasErrors => rejectedRows > 0;
  bool get isEmpty => acceptedRows == 0;
}
