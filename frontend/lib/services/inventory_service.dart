import 'api_client.dart';

class InventoryService {
  static Future<Map<String, dynamic>> recordSale({
    required int plantId,
    required int quantity,
    String? note,
  }) async {
    final data = await ApiClient.post('/inventory/sale', {
      'plant_id': plantId,
      'quantity': quantity,
      if (note != null) 'note': note,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> recordPurchase({
    required int plantId,
    required int quantity,
    required int unitPrice,
    String? note,
  }) async {
    final data = await ApiClient.post('/inventory/purchase', {
      'plant_id': plantId,
      'quantity': quantity,
      'unit_price': unitPrice,
      if (note != null) 'note': note,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> recordDiscard({
    required int plantId,
    required int quantity,
    String? note,
  }) async {
    final data = await ApiClient.post('/inventory/discard', {
      'plant_id': plantId,
      'quantity': quantity,
      if (note != null) 'note': note,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> recordAdjust({
    required int plantId,
    required int quantity,
    String? note,
  }) async {
    final data = await ApiClient.post('/inventory/adjust', {
      'plant_id': plantId,
      'quantity': quantity,
      if (note != null) 'note': note,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<List<Map<String, dynamic>>> getLogs({
    int? plantId,
    String? type,
    String? dateFrom,
    String? dateTo,
  }) async {
    final data = await ApiClient.get('/inventory/logs', query: {
      if (plantId != null) 'plant_id': plantId.toString(),
      if (type != null) 'type': type,
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null) 'date_to': dateTo,
    });
    return List<Map<String, dynamic>>.from(data as List);
  }
}
