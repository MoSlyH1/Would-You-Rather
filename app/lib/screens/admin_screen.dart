import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _pw = TextEditingController();
  bool _busy = false;
  String? _err;

  bool get _loggedIn => Api.adminToken != null;

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await Api.adminLogin(_pw.text);
      _pw.clear();
      setState(() {});
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  void _logout() {
    Api.adminLogout();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _loggedIn ? _PendingQueue(onLogout: _logout) : _loginView();
  }

  Widget _loginView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, size: 56, color: AppTheme.crimson),
              const SizedBox(height: 12),
              const Text('Admin sign in',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Review and curate the pending queue.',
                  style: TextStyle(color: AppTheme.muted)),
              const SizedBox(height: 22),
              TextField(
                controller: _pw,
                obscureText: true,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: AppTheme.card,
                  prefixIcon: const Icon(Icons.key),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                ),
              ),
              if (_err != null) ...[
                const SizedBox(height: 12),
                Text(_err!, style: const TextStyle(color: AppTheme.crimson)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _login,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.crimson,
                      padding: const EdgeInsets.symmetric(vertical: 15)),
                  child: Text(_busy ? 'Checking…' : 'Sign in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingQueue extends StatefulWidget {
  final VoidCallback onLogout;
  const _PendingQueue({required this.onLogout});
  @override
  State<_PendingQueue> createState() => _PendingQueueState();
}

class _PendingQueueState extends State<_PendingQueue> {
  List<PendingQuestion> _items = [];
  bool _loading = true;
  String? _err;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final items = await Api.pending();
      final stats = await Api.stats();
      setState(() {
        _items = items;
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _err = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _approve(PendingQuestion q) async {
    try {
      await Api.approve(q.id);
      _afterAction(q, 'Approved & live');
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _delete(PendingQuestion q) async {
    try {
      await Api.deleteQuestion(q.id);
      _afterAction(q, 'Deleted');
    } catch (e) {
      _toast(e.toString());
    }
  }

  void _afterAction(PendingQuestion q, String msg) {
    setState(() => _items.removeWhere((x) => x.id == q.id));
    _toast(msg);
    Api.stats().then((s) => setState(() => _stats = s)).catchError((_) => null);
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 2)));
  }

  Future<void> _edit(PendingQuestion q) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _EditDialog(question: q),
    );
    if (result == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
          child: Row(
            children: [
              const Text('Pending queue',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              if (!_loading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppTheme.crimson,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${_items.length}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              const Spacer(),
              IconButton(
                  onPressed: _refresh, icon: const Icon(Icons.refresh)),
              IconButton(
                  tooltip: 'Sign out',
                  onPressed: widget.onLogout,
                  icon: const Icon(Icons.logout)),
            ],
          ),
        ),
        if (_stats.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              _stat('Live', '${_stats['approved']}/${_stats['max_approved']}'),
              const SizedBox(width: 10),
              _stat('Pending', '${_stats['pending']}'),
              const SizedBox(width: 10),
              _stat('Votes', '${_stats['total_votes']}'),
            ]),
          ),
        const SizedBox(height: 8),
        Expanded(child: _list()),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label, style: TextStyle(color: AppTheme.muted, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _list() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_err != null) {
      return Center(child: Text(_err!, style: const TextStyle(color: AppTheme.crimson)));
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.inbox, size: 48, color: AppTheme.muted),
          const SizedBox(height: 10),
          Text('Queue is empty — all caught up!',
              style: TextStyle(color: AppTheme.muted)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: _items.length,
        itemBuilder: (_, i) => _card(_items[i]),
      ),
    );
  }

  Widget _card(PendingQuestion q) {
    final color = AppTheme.categoryColor(q.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.5))),
            child: Text(q.category,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 11)),
          ),
          const SizedBox(height: 12),
          _opt(q.optionA, AppTheme.optionA),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('OR',
                style: TextStyle(
                    color: AppTheme.muted, fontWeight: FontWeight.w800)),
          ),
          _opt(q.optionB, AppTheme.optionB),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _edit(q),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _delete(q),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.crimson,
                      side: const BorderSide(color: AppTheme.crimson)),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _approve(q),
                  style:
                      FilledButton.styleFrom(backgroundColor: AppTheme.optionB),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _opt(String text, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
          width: 4,
          height: 18,
          margin: const EdgeInsets.only(top: 2, right: 10),
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2))),
      Expanded(
          child: Text(text,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.3))),
    ]);
  }
}

class _EditDialog extends StatefulWidget {
  final PendingQuestion question;
  const _EditDialog({required this.question});
  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final _a = TextEditingController(text: widget.question.optionA);
  late final _b = TextEditingController(text: widget.question.optionB);
  late String _category = widget.question.category;
  bool _saving = false;
  String? _err;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _err = null;
    });
    try {
      await Api.editQuestion(widget.question.id, _a.text, _b.text, _category);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.card,
      title: const Text('Edit question'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: _a,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(labelText: 'Option A')),
          const SizedBox(height: 10),
          TextField(
              controller: _b,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(labelText: 'Option B')),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: AppTheme.categorySubmit.map((c) {
              return ChoiceChip(
                label: Text(c, style: const TextStyle(fontSize: 12)),
                selected: c == _category,
                showCheckmark: false,
                selectedColor: AppTheme.categoryColor(c),
                onSelected: (_) => setState(() => _category = c),
              );
            }).toList(),
          ),
          if (_err != null) ...[
            const SizedBox(height: 10),
            Text(_err!, style: const TextStyle(color: AppTheme.crimson)),
          ],
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.crimson),
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}
