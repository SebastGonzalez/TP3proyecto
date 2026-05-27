import 'package:flutter/material.dart';

/// Skeleton solo para [MyMonsterScreen]. Otras pantallas usan [CircularProgressIndicator].
class MonsterCollectionGridSkeleton extends StatefulWidget {
  const MonsterCollectionGridSkeleton({
    super.key,
    this.itemCount = 6,
  });

  final int itemCount;

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 0.78,
  );

  @override
  State<MonsterCollectionGridSkeleton> createState() =>
      _MonsterCollectionGridSkeletonState();
}

class _MonsterCollectionGridSkeletonState
    extends State<MonsterCollectionGridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = 0.35 + _pulse.value * 0.25;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: MonsterCollectionGridSkeleton._gridDelegate,
          itemCount: widget.itemCount,
          itemBuilder: (_, __) => _SkeletonCard(opacity: t),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300.withValues(alpha: opacity);
    final dark = Colors.grey.shade400.withValues(alpha: opacity);

    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: dark,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 10,
                width: 56,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra superior de stats mientras carga.
class MonsterCollectionStatsSkeleton extends StatelessWidget {
  const MonsterCollectionStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        height: 16,
        width: 140,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
