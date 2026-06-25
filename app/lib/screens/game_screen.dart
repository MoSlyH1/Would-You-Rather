import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String _category = 'All';
  List<Question> _deck = [];
  int _pos = 0;
  bool _loading = true;
  String? _error;
  String? _chosen; // 'a' | 'b' | null
  Timer? _wakeTimer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _wakeTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _slow = false;
    });
    // After a few seconds, tell the user the free server may be waking up.
    _wakeTimer?.cancel();
    _wakeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _loading) setState(() => _slow = true);
    });
    try {
      final qs = await Api.fetchQuestions(category: _category);
      qs.shuffle(Random());
      if (!mounted) return;
      setState(() {
        _deck = qs;
        _pos = 0;
        _chosen = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    } finally {
      _wakeTimer?.cancel();
    }
  }

  Question? get _current => _deck.isEmpty ? null : _deck[_pos % _deck.length];

  // Tap registers the choice instantly. The vote is sent in the background
  // so the user is never waiting on the network to see the result.
void _choose(String choice) {
  final q = _current;
  if (q == null || _chosen != null) return;

  setState(() {
    _chosen = choice;
    if (choice == 'a') {
      q.votesA++;
    } else {
      q.votesB++;
    }
  });

  Api.vote(q.id, choice).then((res) {
    if (!mounted) return;

    setState(() {
      q.votesA = res['votes_a']!;
      q.votesB = res['votes_b']!;
    });

    // Show results briefly, then move on
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _next();
      }
    });
  }).catchError((_) {
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _next();
      }
    });
  });
}

  void _next() {
    setState(() {
      _pos++;
      _chosen = null;
      if (_deck.isNotEmpty && _pos % _deck.length == 0) _deck.shuffle(Random());
    });
  }

  void _pickCategory(String c) {
    if (_category == c) return;
    setState(() => _category = c);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(),
        _categoryBar(),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: [
          const Text('Would You ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const Text('Rather',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.crimson)),
          const Spacer(),
          Text('@jad',
              style: TextStyle(
                  color: AppTheme.muted.withOpacity(0.8), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _categoryBar() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AppTheme.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = AppTheme.categories[i];
          final selected = c == _category;
          return ChoiceChip(
            label: Text(c),
            selected: selected,
            showCheckmark: false,
            labelStyle: TextStyle(
                color: selected ? Colors.white : AppTheme.muted,
                fontWeight: FontWeight.w600),
            backgroundColor: AppTheme.card,
            selectedColor:
                c == 'All' ? AppTheme.crimson : AppTheme.categoryColor(c),
            side: BorderSide(color: Colors.white.withOpacity(0.06)),
            onSelected: (_) => _pickCategory(c),
          );
        },
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            Text(_slow ? 'Waking up the server…' : 'Loading questions…',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            if (_slow) ...[
              const SizedBox(height: 6),
              Text('The free server sleeps when idle.\nFirst load can take up to a minute.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.muted, fontSize: 13)),
            ],
          ],
        ),
      );
    }
    if (_error != null) {
      return _centerMsg(Icons.cloud_off, 'Could not load questions', _error!,
          action: _load);
    }
    final q = _current;
    if (q == null) {
      return _centerMsg(Icons.inbox_outlined, 'No questions here yet',
          'Be the first to submit one for this category!');
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
          child: Column(
            children: [
              _catTag(q),
              const SizedBox(height: 10),
              Expanded(child: _cards(q)),
              const SizedBox(height: 12),
              _footer(q),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cards(Question q) {
    final cardA = _ChoiceCard(
      label: 'A',
      text: q.optionA,
      color: AppTheme.optionA,
      percent: q.percentA,
      revealed: _chosen != null,
      picked: _chosen == 'a',
      onTap: () => _choose('a'),
    );
    final cardB = _ChoiceCard(
      label: 'B',
      text: q.optionB,
      color: AppTheme.optionB,
      percent: q.percentB,
      revealed: _chosen != null,
      picked: _chosen == 'b',
      onTap: () => _choose('b'),
    );

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 720;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: cardA),
            const SizedBox(width: 12),
            Expanded(child: cardB),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cardA),
          const SizedBox(height: 12),
          Expanded(child: cardB),
        ],
      );
    });
  }

  Widget _catTag(Question q) {
    final color = AppTheme.categoryColor(q.category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(q.category,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

Widget _footer(Question q) {
  if (_chosen == null) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text('Tap a card to choose'),
    );
  }

  return SizedBox(
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            '${q.totalVotes} vote${q.totalVotes == 1 ? '' : 's'}',
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _next,
            icon: const Icon(Icons.skip_next),
            label: const Text(
              'Next Question',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _centerMsg(IconData icon, String title, String sub,
      {VoidCallback? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.muted),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.muted)),
            if (action != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: action, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label; // 'A' / 'B'
  final String text;
  final Color color;
  final double percent;
  final bool revealed;
  final bool picked;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.label,
    required this.text,
    required this.color,
    required this.percent,
    required this.revealed,
    required this.picked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (percent * 100).round();
    final dim = revealed && !picked;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: picked ? color : Colors.white.withOpacity(0.08),
          width: picked ? 2.5 : 1,
        ),
        boxShadow: picked
            ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 22)]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: AppTheme.card,
        child: InkWell(
          onTap: revealed ? null : onTap,
          splashColor: color.withOpacity(0.25),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // result fill bar grows from the bottom
              if (revealed)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: LayoutBuilder(builder: (_, cc) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutCubic,
                      height: cc.maxHeight * percent,
                      color: color.withOpacity(0.30),
                    );
                  }),
                ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: dim ? 0.55 : 1,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Center(
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 20,
                                height: 1.25,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      if (revealed) ...[
                        const SizedBox(height: 12),
                        Text('$pct%',
                            style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: color)),
                      ],
                    ],
                  ),
                ),
              ),
              if (picked)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Icon(Icons.check_circle, color: color),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
