import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prueba1/monsters/data/sacrifice_repository.dart';
import 'package:prueba1/monsters/domain/sacrifice_challenge.dart';
import 'package:prueba1/features/monsters/application/providers/mymonster_provider.dart';
import 'package:prueba1/presentation/providers/sacrifice_challenges_provider.dart';
import 'package:prueba1/presentation/widgets/app_page_app_bar.dart';
import 'package:prueba1/presentation/providers/sacrifice_progress_provider.dart';
import 'package:prueba1/features/monsters/presentation/widgets/monster_card_tile.dart';

class SacrificeScreen extends ConsumerStatefulWidget {
  const SacrificeScreen({super.key});

  @override
  ConsumerState<SacrificeScreen> createState() => _SacrificeScreenState();
}

class _SacrificeScreenState extends ConsumerState<SacrificeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshMonstersCatalog(ref);
      ref.invalidate(sacrificeChallengesProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncChallenges = ref.watch(sacrificeChallengesProvider);
    final completed = ref.watch(sacrificeProgressProvider);

    return Scaffold(
      appBar: const AppPageAppBar(title: 'Fusión'),
      body: asyncChallenges.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error cargando desafíos: $e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (state) {
          if (state.challenges.isNotEmpty) {
            return _SacrificeGrid(
              challenges: state.challenges,
              completed: completed,
            );
          }
          return _EmptySacrificesMessage(state: state);
        },
      ),
    );
  }
}

class _EmptySacrificesMessage extends StatelessWidget {
  const _EmptySacrificesMessage({required this.state});

  final SacrificeChallengesState state;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(color: Colors.grey.shade700, height: 1.4);

    if (state.activeDocumentsCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No hay desafíos activos',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'En Firestore, colección "sbc", cada documento que quieras '
                'mostrar tiene que tener el campo active en true (boolean).\n\n'
                'Si el documento no tiene active o está en false, no aparece en esta pantalla.',
                textAlign: TextAlign.center,
                style: textStyle,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange.shade300),
            const SizedBox(height: 16),
            Text(
              'Hay ${state.activeDocumentsCount} desafío(s) con active: true, '
              'pero no se pudieron mostrar',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Revisá en cada documento:\n'
              '• rewardName (string) = mismo valor que name del monstruo en "monsters".\n'
              '• slots (array) con rarezas y/o nombres de monstruo.\n'
              '• active debe seguir en true.',
              textAlign: TextAlign.center,
              style: textStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _SacrificeGrid extends StatelessWidget {
  const _SacrificeGrid({
    required this.challenges,
    required this.completed,
  });

  final List<SacrificeChallenge> challenges;
  final Set<String> completed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Elegí un desafío estilo SBC: entrás, completás la condición '
            'con monstruos de tu colección y te llevás una recompensa.',
            style: TextStyle(color: Colors.grey.shade800, height: 1.35),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: challenges.length,
            itemBuilder: (context, i) {
              final c = challenges[i];
              final isDone = completed.contains(c.id);
              return _SacrificeGridCell(challenge: c, isDone: isDone);
            },
          ),
        ),
      ],
    );
  }
}

class _SacrificeGridCell extends StatelessWidget {
  const _SacrificeGridCell({
    required this.challenge,
    required this.isDone,
  });

  final SacrificeChallenge challenge;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final c = challenge;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(
          opacity: isDone ? 0.5 : 1,
          child: MonsterCardTile(
            monster: c.reward,
            rarityColor: c.reward.rarity.color,
            onTap: () => context.push(
              '/sacrifice/challenge',
              extra: c,
            ),
          ),
        ),
        if (isDone)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Completado',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
