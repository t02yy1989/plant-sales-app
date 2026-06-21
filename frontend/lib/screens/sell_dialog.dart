import 'package:flutter/material.dart';
import '../services/inventory_service.dart';
import '../services/plant_service.dart';

class SellDialog extends StatefulWidget {
  final Map<String, dynamic>? initialPlant;

  const SellDialog({super.key, this.initialPlant});

  @override
  State<SellDialog> createState() => _SellDialogState();
}

class _SellDialogState extends State<SellDialog> {
  final _codeCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _noteCtrl = TextEditingController();
  Map<String, dynamic>? _plant;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialPlant != null) {
      _plant = widget.initialPlant;
      _codeCtrl.text = _plant!['plant_code'] as String;
    }
  }

  Future<void> _searchByCode() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final plant = await PlantService.getPlantByCode(code);
      setState(() { _plant = plant; });
    } catch (e) {
      setState(() { _error = '見つかりません: $code'; _plant = null; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _submit() async {
    if (_plant == null) return;
    final qty = int.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0) {
      setState(() { _error = '数量は1以上の整数を入力してください'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await InventoryService.recordSale(
        plantId: _plant!['id'] as int,
        quantity: qty,
        note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('販売入力'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(
                      labelText: '管理番号',
                      border: OutlineInputBorder(),
                      hintText: 'P001',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _searchByCode(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _searchByCode,
                  child: const Text('検索'),
                ),
              ],
            ),
            if (_plant != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _plant!['name'] as String,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text('売価: ¥${_plant!['sale_price']}  在庫: ${_plant!['stock']}${_plant!['unit']}'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              decoration: const InputDecoration(
                labelText: '販売数量',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
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
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
        ElevatedButton(
          onPressed: (_plant == null || _loading) ? null : _submit,
          child: _loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('販売確定'),
        ),
      ],
    );
  }
}
