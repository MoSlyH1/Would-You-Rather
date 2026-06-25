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
  String? _chosen; // 'a' | 'b' | null  (null = not yet voted)
  bool _voting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final qs = await Api.fetchQuestions(category: _category);
      qs.shuffle(Random());
      setState(() {
        _deck = qs;
        _pos = 0;
        _chosen = null;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Question? get _current => _deck.isEmpty ? null : _deck[_pos % _deck.length];

  Future<void> _vote(String choice) async {
    final q = _current;
    if (q == null || _chosen != null || _voting) return;
    setState(() {
      _voting = true;
      _chosen = choice; // optimistic
    });
    try {
      final res = await Api.vote(q.id, choice);
      setState(() {
        q.votesA = res['votes_a']!;
        q.votesB = res['votes_b']!;
      });
    } catch (_) {
      // keep optimistic local bump so the UI still feels responsive
      setState(() {
        if (choice == 'a') q.votesA++;
        if (choice == 'b') q.votesB++;
      });
    } finally {
      setState(() => _voting = false);
    }
  }

  void _next() {
    setState(() {
      _pos++;
      _chosen = null;
      if (_pos % _deck.length == 0) _deck.shuffle(Random());
    });
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          const Text('Would You ',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const Text('Rather',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.crimson)),
          const Spacer(),
          Text('@jad',
              style: TextStyle(color: AppTheme.muted.withOpacity(0.8), fontSize: 13)),
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
            selectedColor: c == 'All' ? AppTheme.crimson : AppTheme.categoryColor(c),
            side: BorderSide(color: Colors.white.withOpacity(0.06)),
            onSelected: (_) {
              if (_category != c) {
                _category = c;
                _load();
              }
            },
          );
        },
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _centerMsg(Icons.cloud_off, 'Could not load questions', _error!,
          action: _load);
    }
    final q = _current;
    if (q == null) {
      return _centerMsg(Icons.inbox_outlined, 'No questions here yet',
          'Be the first to submit one for this category!');
    }

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 760;
      final cardA = _ChoiceCard(
        text: q.optionA,
        color: AppTheme.optionA,
        percent: q.percentA,
        revealed: _chosen != null,
        picked: _chosen == 'a',
        onTap: () => _vote('a'),
      );
      final cardB = _ChoiceCard(
        text: q.optionB,
        color: AppTheme.optionB,
        percent: q.percentB,
        revealed: _chosen != null,
        picked: _chosen == 'b',
        onTap: () => _vote('b'),
      );

      final pair = wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cardA),
                Center(child: _orBadge()),
                Expanded(child: cardB),
              ],
            )
          : Column(children: [
              Expanded(child: cardA),
              _orBadge(),
              Expanded(child: cardB),
            ]);

      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                _catTag(q),
                const SizedBox(height: 8),
                Expanded(child: pair),
                const SizedBox(height: 10),
                _footer(q),
              ],
            ),
          ),
        ),
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

  Widget _orBadge() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
            color: AppTheme.bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Text('OR',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    );
  }

  Widget _footer(Question q) {
    if (_chosen == null) {
      return Text('Tap a side to choose',
          style: TextStyle(color: AppTheme.muted, fontSize: 13));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('${q.totalVotes} vote${q.totalVotes == 1 ? '' : 's'}',
            style: TextStyle(color: AppTheme.muted, fontSize: 13)),
        FilledButton.icon(
          onPressed: _next,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.crimson),
          icon: const Icon(Icons.skip_next),
          label: const Text('Next'),
        ),
      ],
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
  final String text;
  final Color color;
  final double percent;
  final bool revealed;
  final bool picked;
  final VoidCallback onTap;

  const _ChoiceCard({
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
    return Padding(
      padding: const EdgeInsets.all(6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: picked ? color : Colors.white.withOpacity(0.07),
              width: picked ? 2.5 : 1,
            ),
            boxShadow: picked
                ? [BoxShadow(color: color.withOpacity(0.35), blurRadius: 22)]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // reveal fill bar
              if (revealed)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: LayoutBuilder(builder: (_, cc) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      height: cc.maxHeight * percent,
                      color: color.withOpacity(0.30),
                    );
                  }),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Center(
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 19,
                              height: 1.25,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (revealed) ...[
                      const SizedBox(height: 12),
                      Text('$pct%',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: color)),
                    ],
                  ],
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
