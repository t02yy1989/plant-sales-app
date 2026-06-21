import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/plant_service.dart';
import '../widgets/role_guard.dart';
import 'login_screen.dart';
import 'sell_dialog.dart';
import 'purchase_screen.dart';
import 'plant_master_screen.dart';
import 'report_screen.dart';
import 'label_print_screen.dart';
import 'user_management_screen.dart';

class StockListScreen extends StatefulWidget {
  final String role;
  const StockListScreen({super.key, required this.role});

  @override
  State<StockListScreen> createState() => _StockListScreenState();
}

class _StockListScreenState extends State<StockListScreen> {
  List<Map<String, dynamic>> _plants = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _selectedCategory;
  String _searchText = '';
  String _username = '';

  bool get _isExecutive => widget.role == 'executive' || widget.role == 'admin';

  @override
  void initState() {
    super.initState();
    _load();
    AuthService.getUsername().then((u) {
      if (mounted) setState(() { _username = u ?? ''; });
    });
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    try {
      final plants = await PlantService.getPlants();
      if (!mounted) return;
      setState(() {
        _plants = plants;
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _applyFilter() {
    _filtered = _plants.where((p) {
      final matchCat = _selectedCategory == null || p['category'] == _selectedCategory;
      final q = _searchText.toLowerCase();
      final matchSearch = q.isEmpty ||
          (p['name'] as String).toLowerCase().contains(q) ||
          (p['plant_code'] as String).toLowerCase().contains(q);
      return matchCat && matchSearch;
    }).toList();
  }

  List<String> get _categories {
    final cats = _plants.map((p) => p['category'] as String?).whereType<String>().toSet().toList();
    cats.sort();
    return cats;
  }

  Future<void> _openSellDialog(Map<String, dynamic> plant) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => SellDialog(initialPlant: plant),
    );
    if (result == true) _load();
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('植物販売在庫管理'),
        actions: [
          Text(_username, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout, tooltip: 'ログアウト'),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _buildTable()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          DropdownButton<String?>(
            value: _selectedCategory,
            hint: const Text('カテゴリ'),
            items: [
              const DropdownMenuItem(value: null, child: Text('すべて')),
              ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
            ],
            onChanged: (v) => setState(() { _selectedCategory = v; _applyFilter(); }),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: '品名・管理番号で検索',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() { _searchText = v; _applyFilter(); }),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: '更新'),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.green.shade100),
          columns: [
            const DataColumn(label: Text('管理番号')),
            const DataColumn(label: Text('品名')),
            const DataColumn(label: Text('カテゴリ')),
            const DataColumn(label: Text('単位')),
            const DataColumn(label: Text('売価'), numeric: true),
            if (_isExecutive) const DataColumn(label: Text('仕入値'), numeric: true),
            const DataColumn(label: Text('在庫'), numeric: true),
            const DataColumn(label: Text('操作')),
          ],
          rows: _filtered.map((p) {
            final stock = p['stock'] as int? ?? 0;
            final lowStock = stock <= 0;
            return DataRow(
              color: MaterialStateProperty.all(lowStock ? Colors.red.shade50 : null),
              cells: [
                DataCell(Text(p['plant_code'] as String, style: const TextStyle(fontFamily: 'monospace'))),
                DataCell(Text(p['name'] as String)),
                DataCell(Text(p['category'] as String? ?? '')),
                DataCell(Text(p['unit'] as String? ?? '')),
                DataCell(Text('¥${p['sale_price']}')),
                if (_isExecutive) DataCell(Text('¥${p['purchase_price'] ?? 0}')),
                DataCell(Text(
                  '$stock',
                  style: TextStyle(
                    color: lowStock ? Colors.red : null,
                    fontWeight: lowStock ? FontWeight.bold : null,
                  ),
                )),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _openSellDialog(p),
                      child: const Text('販売'),
                    ),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.green.shade700),
            child: const Text('メニュー', style: TextStyle(color: Colors.white, fontSize: 20)),
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('在庫一覧'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          RoleGuard(
            allowedRoles: const ['executive', 'admin'],
            currentRole: widget.role,
            child: ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('仕入れ'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => PurchaseScreen(role: widget.role)));
              },
            ),
          ),
          RoleGuard(
            allowedRoles: const ['executive', 'admin'],
            currentRole: widget.role,
            child: ListTile(
              leading: const Icon(Icons.eco),
              title: const Text('マスタ管理'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => PlantMasterScreen(role: widget.role))).then((_) => _load());
              },
            ),
          ),
          RoleGuard(
            allowedRoles: const ['executive', 'admin'],
            currentRole: widget.role,
            child: ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('レポート'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(role: widget.role)));
              },
            ),
          ),
          RoleGuard(
            allowedRoles: const ['executive', 'admin'],
            currentRole: widget.role,
            child: ListTile(
              leading: const Icon(Icons.label),
              title: const Text('ラベル印刷'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => LabelPrintScreen(role: widget.role)));
              },
            ),
          ),
          RoleGuard(
            allowedRoles: const ['admin'],
            currentRole: widget.role,
            child: ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('ユーザー管理'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => UserManagementScreen(role: widget.role)));
              },
            ),
          ),
        ],
      ),
    );
  }
}
