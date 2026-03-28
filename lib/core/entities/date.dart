import 'package:equatable/equatable.dart';

class Date extends Equatable {
  final int day;
  final int month;
  final int year;

  const Date({
    required this.day,
    required this.month,
    required this.year,
  });

  DateTime toDateTime() => DateTime(year, month, day);

  factory Date.fromDateTime(DateTime dateTime) {
    return Date(
      day: dateTime.day,
      month: dateTime.month,
      year: dateTime.year,
    );
  }

  factory Date.fromExcelString(String dateString) {
    try {
      final DateTime parsed = DateTime.parse(dateString);
      return Date(day: parsed.day, month: parsed.month, year: parsed.year);
    } catch (_) {
      throw FormatException('Could not parse date string: $dateString');
    }
  }

  factory Date.fromExcelSerial(int serial) {
    // Excel's epoch starts on December 30, 1899
    final baseDate = DateTime(1899, 12, 30);
    return Date.fromDateTime(baseDate.add(Duration(days: serial)));
  }

  /// Returns a short formatted string: DD/MM/YY
  String toReadableString() {
    final monthStr = month.toString().padLeft(2, '0');
    final dayStr = day.toString().padLeft(2, '0');
    final yearStr = year.toString().substring(2);
    return '$dayStr/$monthStr/$yearStr';
  }

  /// Returns a filename-safe string: DD-MM-YYYY
  String toFileNameString() {
    final monthStr = month.toString().padLeft(2, '0');
    final dayStr = day.toString().padLeft(2, '0');
    return '$dayStr-$monthStr-$year';
  }

  /// Returns a full Greek day/month string, e.g. "Δευτέρα 5 Ιαν 2026"
  String toGreekString() {
    const days = [
      'Δευτέρα',
      'Τρίτη',
      'Τετάρτη',
      'Πέμπτη',
      'Παρασκευή',
      'Σάββατο',
      'Κυριακή',
    ];

    const months = [
      'Ιαν', 'Φεβ', 'Μαρ', 'Απρ', 'Μαΐ', 'Ιουν',
      'Ιουλ', 'Αυγ', 'Σεπ', 'Οκτ', 'Νοε', 'Δεκ',
    ];

    final dt = toDateTime();
    return '${days[dt.weekday - 1]} $day ${months[month - 1]} $year';
  }

  @override
  List<Object?> get props => [day, month, year];
}
