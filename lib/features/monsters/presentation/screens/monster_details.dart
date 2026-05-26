import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/features/monsters/domain/models/monster.dart';
import 'package:prueba1/monsters/domain/trade_request.dart';
import 'package:prueba1/presentation/providers/home_companion_provider.dart';
import 'package:prueba1/presentation/providers/trade_provider.dart';
import 'package:prueba1/presentation/screens/market_screen.dart';
import 'package:prueba1/presentation/widgets/app_page_app_bar.dart';

class MonsterDetails extends ConsumerWidget {
  const MonsterDetails({super.key, required this.monster});

  final Monster monster;

  bool get _isOwnedInstance =>
      monster.ownedInstanceId != null && monster.ownedInstanceId!.isNotEmpty;

  Future<void> _toggleHomeCompanion(BuildContext context, WidgetRef ref) async {
    final ownedId = monster.ownedInstanceId!;
    final notifier = ref.read(homeCompanionProvider.notifier);
    final isCompanion = ref.read(homeCompanionProvider) == ownedId;

    if (isCompanion) {
      await notifier.clear();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${monster.name} ya no te acompaña en la home'),
        ),
      );
    } else {
      await notifier.setCompanion(ownedId, monster: monster);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${monster.name} te acompañará en la home'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownedId = monster.ownedInstanceId;
    final isCompanion =
        ownedId != null && ref.watch(homeCompanionProvider) == ownedId;

    return Scaffold(
      appBar: AppPageAppBar(
        title: monster.name,
        actions: [
          if (_isOwnedInstance)
            IconButton(
              tooltip: isCompanion
                  ? 'Quitar compañero de la home'
                  : 'Elegir compañero en la home',
              onPressed: () => _toggleHomeCompanion(context, ref),
              icon: Icon(
                isCompanion ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isCompanion ? Colors.amber.shade700 : null,
              ),
            ),
        ],
      ),
      body: _DetailView(monster: monster, ref: ref),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView({required this.monster, required this.ref});

  final Monster monster;
  final WidgetRef ref;

  bool get _isOwnedInstance =>
      monster.ownedInstanceId != null && monster.ownedInstanceId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rarityColor = monster.rarity.color;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 320,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  rarityColor.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
            child: SizedBox(
              width: 400,
              height: 400,
              child: Image.asset(
                monster.imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: rarityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: rarityColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        monster.rarity.label.toUpperCase(),
                        style: TextStyle(
                          color: rarityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Tier ${monster.level}',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_isOwnedInstance) ...[
                      const Spacer(),
                      _TradeButton(monster: monster, ref: ref),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'DESCRIPCIÓN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  monster.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TradeButton extends StatelessWidget {
  const _TradeButton({required this.monster, required this.ref});

  final Monster monster;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final pendingTrades = ref.watch(myPendingTradesProvider).value ?? [];
    final proposedTrades = ref.watch(myProposedTradesProvider).value ?? [];

    final inTrade = pendingTrades.any(
            (t) => t.fromOwnedMonsterId == monster.ownedInstanceId) ||
        proposedTrades.any(
            (t) => t.fromOwnedMonsterId == monster.ownedInstanceId);

    if (inTrade) {
      final trade = pendingTrades.cast<TradeRequest?>().firstWhere(
                (t) => t!.fromOwnedMonsterId == monster.ownedInstanceId,
                orElse: () => null,
              ) ??
          proposedTrades.cast<TradeRequest?>().firstWhere(
                (t) => t!.fromOwnedMonsterId == monster.ownedInstanceId,
                orElse: () => null,
              );
      return FilledButton.icon(
        onPressed: trade != null
            ? () => MarketScreen.openTradeCode(context, trade)
            : null,
        icon: const Icon(Icons.hourglass_top, size: 14),
        label: const Text('En intercambio'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF795548),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          textStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => MarketScreen.createTradeFor(
        context,
        ref,
        ownedMonsterId: monster.ownedInstanceId!,
        monsterName: monster.name,
        monsterImagePath: monster.imagePath,
      ),
      icon: const Icon(Icons.swap_horiz, size: 16),
      label: const Text('Intercambiar'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
