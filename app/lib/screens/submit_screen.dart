import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';

class SubmitScreen extends StatefulWidget {
  const SubmitScreen({super.key});
  @override
  State<SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<SubmitScreen> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  String _category = 'Community';
  bool _sending = false;
  String? _ok;
  String? _err;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _ok = null;
      _err = null;
    });
    try {
      final msg = await Api.submit(_a.text, _b.text, _category);
      setState(() {
        _ok = msg;
        _a.clear();
        _b.clear();
      });
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Submit a question',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'New questions go to a review queue. If it is good, it goes live — '
              'if not, it gets removed.',
              style: TextStyle(color: AppTheme.muted),
            ),
            const SizedBox(height: 22),
            _label('Would you rather…'),
            _field(_a, 'e.g. Live in Beirut'),
            const SizedBox(height: 6),
            Center(
                child: Text('OR',
                    style: TextStyle(
                        color: AppTheme.crimson,
                        fontWeight: FontWeight.w900,
                        fontSize: 16))),
            const SizedBox(height: 6),
            _field(_b, 'e.g. Live in the mountains'),
            const SizedBox(height: 18),
            _label('Category'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppTheme.categorySubmit.map((c) {
                final sel = c == _category;
                return ChoiceChip(
                  label: Text(c),
                  selected: sel,
                  showCheckmark: false,
                  backgroundColor: AppTheme.card,
                  selectedColor: AppTheme.categoryColor(c),
                  labelStyle: TextStyle(
                      color: sel ? Colors.white : AppTheme.muted,
                      fontWeight: FontWeight.w600),
                  onSelected: (_) => setState(() => _category = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            if (_ok != null) _banner(_ok!, AppTheme.optionB, Icons.check_circle),
            if (_err != null) _banner(_err!, AppTheme.crimson, Icons.error_outline),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _sending ? null : _send,
                style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.crimson,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: Text(_sending ? 'Sending…' : 'Submit for review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      );

  Widget _field(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      maxLength: 200,
      maxLines: 2,
      minLines: 1,
      style: const TextStyle(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppTheme.card,
        counterStyle: TextStyle(color: AppTheme.muted),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _banner(String msg, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
    );
  }
}
