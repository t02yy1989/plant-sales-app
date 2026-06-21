import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../services/plant_service.dart';

class LabelPrintScreen extends StatefulWidget {
  final String role;
  const LabelPrintScreen({super.key, required this.role});

  @override
  State<LabelPrintScreen> createState() => _LabelPrintScreenState();
}

class _LabelPrintScreenState extends State<LabelPrintScreen> {
  List<Map<String, dynamic>> _plants = [];
  final Set<int> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plants = await PlantService.getPlants();
    if (mounted) setState(() { _plants = plants; _loading = false; });
  }

  void _print() {
    final items = _plants.where((p) => _selected.contains(p['id'] as int));
    if (items.isEmpty) return;

    final labels = items.map((p) => '''
      <div class="label">
        <div class="code">${p['plant_code']}</div>
        <div class="name">${p['name']}</div>
        <div class="price">¥${p['sale_price']}</div>
      </div>
    ''').join('');

    final html_ = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  body { margin: 0; font-family: sans-serif; }
  .label {
    width: 90mm; height: 55mm;
    border: 1px solid #ccc;
    margin: 4mm;
    padding: 6mm;
    display: inline-block;
    vertical-align: top;
    box-sizing: border-box;
  }
  .code { font-size: 18pt; font-weight: bold; font-family: monospace; }
  .name { font-size: 14pt; margin: 4mm 0; }
  .price { font-size: 16pt; font-weight: bold; color: #c00; }
  @media print {
    body { margin: 0; }
    @page { margin: 10mm; }
  }
</style>
</head>
<body>
$labels
<script>window.onload = function() { window.print(); window.close(); }</script>
</body>
</html>
''';

    final blob = html.Blob([html_], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ラベル印刷'),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: Text('印刷 (${_selected.length}件)'),
            onPressed: _selected.isEmpty ? null : _print,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _selected.addAll(_plants.map((p) => p['id'] as int))),
                        child: const Text('すべて選択'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _selected.clear()),
                        child: const Text('すべて解除'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.green.shade100),
                      columns: const [
                        DataColumn(label: Text('選択')),
                        DataColumn(label: Text('管理番号')),
                        DataColumn(label: Text('品名')),
                        DataColumn(label: Text('売価'), numeric: true),
                      ],
                      rows: _plants.map((p) {
                        final id = p['id'] as int;
                        return DataRow(cells: [
                          DataCell(Checkbox(
                            value: _selected.contains(id),
                            onChanged: (v) => setState(() {
                              if (v == true) { _selected.add(id); } else { _selected.remove(id); }
                            }),
                          )),
                          DataCell(Text(p['plant_code'] as String, style: const TextStyle(fontFamily: 'monospace'))),
                          DataCell(Text(p['name'] as String)),
                          DataCell(Text('¥${p['sale_price']}')),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
