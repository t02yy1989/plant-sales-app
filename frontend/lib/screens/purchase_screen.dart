import 'package:flutter/material.dart';
import '../services/plant_service.dart';
import '../services/inventory_service.dart';

class PurchaseScreen extends StatefulWidget {
  final String role;
  const PurchaseScreen({super.key, required this.role});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  List<Map<String, dynamic>> _plants = [];
  Map<String, dynamic>? _selectedPlant;
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    final plants = await PlantService.getPlants();
    if (mounted) setState(() { _plants = plants; });
  }

  Future<void> _submit() async {
    if (_selectedPlant == null) return;
    final qty = int.tryParse(_qtyCtrl.text);
    final price = int.tryParse(_priceCtrl.text) ?? 0;
    if (qty == null || qty <= 0) {
      setState(() { _error = '数量は1以上の整数を入力してください'; });
      return;
    }
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      await InventoryService.recordPurchase(
        plantId: _selectedPlant!['id'] as int,
        quantity: qty,
        unitPrice: price,
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
      );
      setState(() {
        _success = '${_selectedPlant!['name']} を $qty${_selectedPlant!['unit']} 仕入れしました';
        _selectedPlant = null;
        _qtyCtrl.text = '1';
        _priceCtrl.clear();
        _noteCtrl.clear();
      });
      _loadPlants();
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('仕入れ入力')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedPlant,
                    decoration: const InputDecoration(
                      labelText: '植物を選択',
                      border: OutlineInputBorder(),
                    ),
                    items: _plants.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text('[${p['plant_code']}] ${p['name']}'),
                    )).toList(),
                    onChanged: (v) => setState(() { _selectedPlant = v; }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _qtyCtrl,
                    decoration: const InputDecoration(
                      labelText: '仕入れ数量',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(
                      labelText: '仕入れ単価（円）',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'メモ（任意）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  if (_success != null) ...[
                    const SizedBox(height: 8),
                    Text(_success!, style: const TextStyle(color: Colors.green)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: (_selectedPlant == null || _loading) ? null : _submit,
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('仕入れ確定'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
