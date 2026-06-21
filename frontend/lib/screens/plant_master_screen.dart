import 'package:flutter/material.dart';
import '../services/plant_service.dart';

class PlantMasterScreen extends StatefulWidget {
  final String role;
  const PlantMasterScreen({super.key, required this.role});

  @override
  State<PlantMasterScreen> createState() => _PlantMasterScreenState();
}

class _PlantMasterScreenState extends State<PlantMasterScreen> {
  List<Map<String, dynamic>> _plants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    final plants = await PlantService.getPlants();
    if (mounted) setState(() { _plants = plants; _loading = false; });
  }

  Future<void> _openEditDialog([Map<String, dynamic>? plant]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _PlantEditDialog(plant: plant),
    );
    if (result == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> plant) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('「${plant['name']}」を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await PlantService.deletePlant(plant['id'] as int);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('植物マスタ管理'),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('新規登録'),
            onPressed: () => _openEditDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.green.shade100),
                  columns: const [
                    DataColumn(label: Text('管理番号')),
                    DataColumn(label: Text('品名')),
                    DataColumn(label: Text('カテゴリ')),
                    DataColumn(label: Text('売価'), numeric: true),
                    DataColumn(label: Text('仕入値'), numeric: true),
                    DataColumn(label: Text('単位')),
                    DataColumn(label: Text('在庫'), numeric: true),
                    DataColumn(label: Text('操作')),
                  ],
                  rows: _plants.map((p) => DataRow(cells: [
                    DataCell(Text(p['plant_code'] as String, style: const TextStyle(fontFamily: 'monospace'))),
                    DataCell(Text(p['name'] as String)),
                    DataCell(Text(p['category'] as String? ?? '')),
                    DataCell(Text('¥${p['sale_price']}')),
                    DataCell(Text('¥${p['purchase_price'] ?? 0}')),
                    DataCell(Text(p['unit'] as String? ?? '')),
                    DataCell(Text('${p['stock'] ?? 0}')),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(onPressed: () => _openEditDialog(p), child: const Text('編集')),
                        TextButton(
                          onPressed: () => _delete(p),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('削除'),
                        ),
                      ],
                    )),
                  ])).toList(),
                ),
              ),
            ),
    );
  }
}

class _PlantEditDialog extends StatefulWidget {
  final Map<String, dynamic>? plant;
  const _PlantEditDialog({this.plant});

  @override
  State<_PlantEditDialog> createState() => _PlantEditDialogState();
}

class _PlantEditDialogState extends State<_PlantEditDialog> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _sciCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController(text: '0');
  final _purchasePriceCtrl = TextEditingController(text: '0');
  final _unitCtrl = TextEditingController(text: 'ポット');
  final _notesCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.plant != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.plant!;
      _codeCtrl.text = p['plant_code'] as String? ?? '';
      _nameCtrl.text = p['name'] as String? ?? '';
      _sciCtrl.text = p['scientific_name'] as String? ?? '';
      _catCtrl.text = p['category'] as String? ?? '';
      _salePriceCtrl.text = '${p['sale_price'] ?? 0}';
      _purchasePriceCtrl.text = '${p['purchase_price'] ?? 0}';
      _unitCtrl.text = p['unit'] as String? ?? 'ポット';
      _notesCtrl.text = p['notes'] as String? ?? '';
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() { _error = '品名を入力してください'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final body = {
        if (_codeCtrl.text.isNotEmpty) 'plant_code': _codeCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'scientific_name': _sciCtrl.text.trim().isEmpty ? null : _sciCtrl.text.trim(),
        'category': _catCtrl.text.trim().isEmpty ? null : _catCtrl.text.trim(),
        'sale_price': int.tryParse(_salePriceCtrl.text) ?? 0,
        'purchase_price': int.tryParse(_purchasePriceCtrl.text) ?? 0,
        'unit': _unitCtrl.text.trim().isEmpty ? 'ポット' : _unitCtrl.text.trim(),
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      };
      if (_isEdit) {
        await PlantService.updatePlant(widget.plant!['id'] as int, body);
      } else {
        await PlantService.createPlant(body);
      }
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
      title: Text(_isEdit ? '植物を編集' : '植物を新規登録'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isEdit)
                TextField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(labelText: '管理番号', border: OutlineInputBorder()),
                ),
              if (_isEdit) const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: '品名 *', border: OutlineInputBorder()),
                autofocus: !_isEdit,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sciCtrl,
                decoration: const InputDecoration(labelText: '学名', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _catCtrl,
                decoration: const InputDecoration(labelText: 'カテゴリ（例: 草花・低木）', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(
                  controller: _salePriceCtrl,
                  decoration: const InputDecoration(labelText: '売価（円）', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                )),
                const SizedBox(width: 12),
                Expanded(child: TextField(
                  controller: _purchasePriceCtrl,
                  decoration: const InputDecoration(labelText: '仕入値（円）', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                )),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _unitCtrl,
                decoration: const InputDecoration(labelText: '単位', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: '備考', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEdit ? '更新' : '登録'),
        ),
      ],
    );
  }
}
