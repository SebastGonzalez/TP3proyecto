import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prueba1/features/monsters/domain/models/monster.dart';
import 'package:prueba1/features/monsters/application/providers/mymonster_provider.dart';
import 'package:prueba1/shared/presentation/widgets/app_page_app_bar.dart';

class PokedexScreen extends ConsumerStatefulWidget {
  const PokedexScreen({super.key});

  @override
  ConsumerState<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends ConsumerState<PokedexScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshMonstersCatalog(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final monstersAsync = ref.watch(monstersProvider);

    return Scaffold(
      appBar: const AppPageAppBar(title: 'Pokédex'),
      body: monstersAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (monsters) => _ListView(monsters: monsters),
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  final List<Monster> monsters;

  const _ListView({super.key, required this.monsters});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: monsters.length,
      itemBuilder: (context, index) {
        return _ListItem(monster: monsters[index]);
      },
    );
  }
}

class _ListItem extends StatelessWidget {
  final Monster monster;

  const _ListItem({super.key, required this.monster});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: SizedBox(
            width: 50,
            height: 50,
            child: Image.asset(
              monster.imagePath,
              fit: BoxFit.cover,
            ),
          ),
        title: Text(monster.name),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tier: ${monster.level}'),
            Text(monster.rarity.label),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {
          context.push('/details', extra: monster);
        },
      ),
    );
  }
}
