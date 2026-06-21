import 'api_client.dart';

class ReportService {
  static Future<Map<String, dynamic>> getDaily(String date) async {
    final data = await ApiClient.get('/report/daily', query: {'date': date});
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> getMonthly(int year, int month) async {
    final data = await ApiClient.get('/report/monthly', query: {
      'year': year.toString(),
      'month': month.toString(),
    });
    return Map<String, dynamic>.from(data as Map);
  }
}
