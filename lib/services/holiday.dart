import 'dart:convert';

import 'package:http/http.dart' as http;

class HolidayService {
  HolidayService._internal();

  static final HolidayService _instance = HolidayService._internal();
  factory HolidayService() => _instance;

  static const String _countryCode = 'ID';
  static const String _baseUrl = 'date.nager.at';
  final Map<int, List<DateTime>> _cache = {};

  /// Returns `true` when the provided date is a public holiday in Indonesia.
  Future<bool> checkIsHoliday(DateTime date) async {
    try {
      final uri = Uri.https(
        _baseUrl,
        '/api/v3/PublicHolidays/${date.year}/$_countryCode',
      );
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        return false;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List) {
        return false;
      }

      final targetDate = DateTime(date.year, date.month, date.day);

      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;

        final dateValue = item['date'];
        if (dateValue is! String) continue;

        final holidayDate = DateTime.tryParse(dateValue);
        if (holidayDate == null) continue;

        final normalizedHolidayDate = DateTime(
          holidayDate.year,
          holidayDate.month,
          holidayDate.day,
        );

        if (normalizedHolidayDate == targetDate) {
          return true;
        }
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<DateTime>> getHolidaysForYear(int year) async {
    // return cached result if available
    if (_cache.containsKey(year)) return _cache[year]!;

    try {
      final uri = Uri.https(
        _baseUrl,
        '/api/v3/PublicHolidays/$year/$_countryCode',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final List data = jsonDecode(response.body);
      final holidays = data
          .map((h) => DateTime.parse(h['date'] as String))
          .toList();

      _cache[year] = holidays; // cache it
      return holidays;
    } catch (_) {
      return [];
    }
  }
}
