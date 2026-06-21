import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/report_service.dart';

class ReportScreen extends StatefulWidget {
  final String role;
  const ReportScreen({super.key, required this.role});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _fmt = NumberFormat('#,###');

  DateTime _dailyDate = DateTime.now();
  Map<String, dynamic>? _dailyData;

  DateTime _monthlyDate = DateTime.now();
  Map<String, dynamic>? _monthlyData;

  bool _loadingDaily = false;
  bool _loadingMonthly = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadDaily();
    _loadMonthly();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDaily() async {
    setState(() { _loadingDaily = true; });
    try {
      final data = await ReportService.getDaily(DateFormat('yyyy-MM-dd').format(_dailyDate));
      if (mounted) setState(() { _dailyData = data; });
    } catch (_) {} finally {
      if (mounted) setState(() { _loadingDaily = false; });
    }
  }

  Future<void> _loadMonthly() async {
    setState(() { _loadingMonthly = true; });
    try {
      final data = await ReportService.getMonthly(_monthlyDate.year, _monthlyDate.month);
      if (mounted) setState(() { _monthlyData = data; });
    } catch (_) {} finally {
      if (mounted) setState(() { _loadingMonthly = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('レポート'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [Tab(text: '日別'), Tab(text: '月別')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [_buildDaily(), _buildMonthly()],
      ),
    );
  }

  Widget _buildDaily() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(DateFormat('yyyy/MM/dd').format(_dailyDate)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _dailyDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (d != null) { setState(() { _dailyDate = d; }); _loadDaily(); }
              },
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDaily),
          ]),
          const SizedBox(height: 16),
          if (_loadingDaily)
            const CircularProgressIndicator()
          else if (_dailyData != null)
            _buildSummaryCards(_dailyData!)
          else
            const Text('データがありません'),
        ],
      ),
    );
  }

  Widget _buildMonthly() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(DateFormat('yyyy年MM月').format(_monthlyDate)),
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                  context: context,
                  initialDate: _monthlyDate,
                  firstDate: DateTime(2020),
                  lastDate: now,
                );
                if (d != null) { setState(() { _monthlyDate = d; }); _loadMonthly(); }
              },
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMonthly),
          ]),
          const SizedBox(height: 16),
          if (_loadingMonthly)
            const CircularProgressIndicator()
          else if (_monthlyData != null) ...[
            _buildSummaryCards(_monthlyData!),
            const SizedBox(height: 16),
            const Text('カテゴリ別', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _buildCategoryTable(_monthlyData!['by_category'] as List),
          ] else
            const Text('データがありません'),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> data) {
    return Row(
      children: [
        _card('販売件数', '${data['sale_count']} 件', Colors.blue),
        const SizedBox(width: 16),
        _card('売上合計', '¥${_fmt.format(data['sale_amount'])}', Colors.green),
        const SizedBox(width: 16),
        _card('粗利合計', '¥${_fmt.format(data['gross_profit'])}', Colors.orange),
      ],
    );
  }

  Widget _card(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTable(List cats) {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(Colors.green.shade100),
      columns: const [
        DataColumn(label: Text('カテゴリ')),
        DataColumn(label: Text('件数'), numeric: true),
        DataColumn(label: Text('売上'), numeric: true),
        DataColumn(label: Text('粗利'), numeric: true),
      ],
      rows: cats.map((c) => DataRow(cells: [
        DataCell(Text(c['category'] as String? ?? '未分類')),
        DataCell(Text('${c['sale_count']}')),
        DataCell(Text('¥${_fmt.format(c['sale_amount'])}')),
        DataCell(Text('¥${_fmt.format(c['gross_profit'])}')),
      ])).toList(),
    );
  }
}
