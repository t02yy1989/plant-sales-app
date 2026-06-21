import 'package:flutter/material.dart';
import '../services/api_client.dart';

class UserManagementScreen extends StatefulWidget {
  final String role;
  const UserManagementScreen({super.key, required this.role});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    try {
      final data = await ApiClient.get('/users');
      if (mounted) setState(() { _users = List<Map<String, dynamic>>.from(data as List); });
    } catch (_) {} finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _openDialog([Map<String, dynamic>? user]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _UserEditDialog(user: user),
    );
    if (result == true) _load();
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final isActive = user['is_active'] as bool;
    await ApiClient.put('/users/${user['id']}', {'is_active': !isActive});
    _load();
  }

  String _roleLabel(String role) {
    const labels = {'admin': '管理者', 'executive': '経営者', 'employee': 'スタッフ'};
    return labels[role] ?? role;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザー管理'),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('新規ユーザー'),
            onPressed: () => _openDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.green.shade100),
                columns: const [
                  DataColumn(label: Text('ユーザー名')),
                  DataColumn(label: Text('ロール')),
                  DataColumn(label: Text('状態')),
                  DataColumn(label: Text('操作')),
                ],
                rows: _users.map((u) => DataRow(cells: [
                  DataCell(Text(u['username'] as String)),
                  DataCell(Text(_roleLabel(u['role'] as String))),
                  DataCell(Chip(
                    label: Text(u['is_active'] == true ? '有効' : '無効'),
                    backgroundColor: u['is_active'] == true ? Colors.green.shade100 : Colors.grey.shade200,
                  )),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(onPressed: () => _openDialog(u), child: const Text('編集')),
                      TextButton(
                        onPressed: () => _toggleActive(u),
                        style: TextButton.styleFrom(
                          foregroundColor: u['is_active'] == true ? Colors.red : Colors.green,
                        ),
                        child: Text(u['is_active'] == true ? '無効化' : '有効化'),
                      ),
                    ],
                  )),
                ])).toList(),
              ),
            ),
    );
  }
}

class _UserEditDialog extends StatefulWidget {
  final Map<String, dynamic>? user;
  const _UserEditDialog({this.user});

  @override
  State<_UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<_UserEditDialog> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'employee';
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _usernameCtrl.text = widget.user!['username'] as String;
      _role = widget.user!['role'] as String;
    }
  }

  Future<void> _submit() async {
    if (!_isEdit && _usernameCtrl.text.trim().isEmpty) {
      setState(() { _error = 'ユーザー名を入力してください'; });
      return;
    }
    if (!_isEdit && _passwordCtrl.text.isEmpty) {
      setState(() { _error = 'パスワードを入力してください'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      if (_isEdit) {
        final body = <String, dynamic>{'role': _role};
        if (_passwordCtrl.text.isNotEmpty) body['password'] = _passwordCtrl.text;
        await ApiClient.put('/users/${widget.user!['id']}', body);
      } else {
        await ApiClient.post('/users', {
          'username': _usernameCtrl.text.trim(),
          'password': _passwordCtrl.text,
          'role': _role,
        });
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
      title: Text(_isEdit ? 'ユーザーを編集' : 'ユーザーを新規登録'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameCtrl,
              readOnly: _isEdit,
              decoration: const InputDecoration(labelText: 'ユーザー名', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: _isEdit ? '新しいパスワード（変更する場合のみ）' : 'パスワード',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'ロール', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'employee', child: Text('スタッフ')),
                DropdownMenuItem(value: 'executive', child: Text('経営者')),
                DropdownMenuItem(value: 'admin', child: Text('管理者')),
              ],
              onChanged: (v) => setState(() { _role = v!; }),
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
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_isEdit ? '更新' : '登録'),
        ),
      ],
    );
  }
}
