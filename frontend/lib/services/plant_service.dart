import 'api_client.dart';

class PlantService {
  static Future<List<Map<String, dynamic>>> getPlants({String? category}) async {
    final data = await ApiClient.get('/plants', query: {'category': category});
    return List<Map<String, dynamic>>.from(data as List);
  }

  static Future<Map<String, dynamic>> getPlantByCode(String code) async {
    final data = await ApiClient.get('/plants/by-code/$code');
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> getPlant(int id) async {
    final data = await ApiClient.get('/plants/$id');
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> createPlant(Map<String, dynamic> body) async {
    final data = await ApiClient.post('/plants', body);
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> updatePlant(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.put('/plants/$id', body);
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> deletePlant(int id) async {
    await ApiClient.delete('/plants/$id');
  }
}
