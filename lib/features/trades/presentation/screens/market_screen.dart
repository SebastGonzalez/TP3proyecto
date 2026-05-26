import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prueba1/features/monsters/domain/models/owned_monster.dart';
import 'package:prueba1/features/monsters/domain/models/monster.dart';
import 'package:prueba1/features/trades/domain/models/trade_request.dart';
import 'package:prueba1/features/monsters/application/providers/captured_monsters_provider.dart';
import 'package:prueba1/features/monsters/application/providers/mymonster_provider.dart';
import 'package:prueba1/features/monsters/application/providers/owned_monsters_provider.dart';
import 'package:prueba1/features/trades/application/controllers/trade_controller_provider.dart';
import 'package:prueba1/features/trades/application/providers/trade_provider.dart';
import 'package:prueba1/shared/presentation/widgets/app_page_app_bar.dart';
import 'package:prueba1/presentation/widgets/gatcha_reveal.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  /// Navega directamente a crear un trade con un monstruo owned específico.
  static Future<void> createTradeFor(
    BuildContext context,
    WidgetRef ref, {
    required String ownedMonsterId,
    required String monsterName,
    required String monsterImagePath,
  }) async {
    final trade = await ref
        .read(tradeControllerProvider)
        .createTrade(
          ownedMonsterId: ownedMonsterId,
          monsterName: monsterName,
          monsterImagePath: monsterImagePath,
        );
    if (trade == null) return;
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _TradeCodeDisplay(
          trade: trade,
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  /// Abre la pantalla de código de un trade existente (copiar / cancelar).
  static void openTradeCode(BuildContext context, TradeRequest trade) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _TradeCodeDisplay(
          trade: trade,
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(myPendingTradesProvider);
      ref.invalidate(capturedMonstersAsyncProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppPageAppBar(title: 'Intercambio'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Text(
              'Intercambiá monstruos con otro jugador usando un código.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 28),
            _ActionButton(
              icon: Icons.upload_outlined,
              label: 'Crear propuesta',
              subtitle: 'Elegí tu monstruo y generá un código',
              onTap: () => _navigateCreate(context),
            ),
            const SizedBox(height: 14),
            _ActionButton(
              icon: Icons.download_outlined,
              label: 'Ingresar código',
              subtitle: 'Recibí un código de otro jugador',
              onTap: () => _navigateEnterCode(context),
            ),
            const SizedBox(height: 28),
            const _ProposedTradesSection(),
            const _WaitingTradesSection(),
            const _PendingTradesSection(),
          ],
        ),
      ),
    );
  }

  void _navigateCreate(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _CreateTradeScreen()));
  }

  void _navigateEnterCode(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _EnterCodeScreen()));
  }
}

// ---------------------------------------------------------------------------
// Action button
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF7B1FA2), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Proposed trades (User A confirms/rejects here)
// ---------------------------------------------------------------------------

class _ProposedTradesSection extends ConsumerWidget {
  const _ProposedTradesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposedAsync = ref.watch(myProposedTradesProvider);
    return proposedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (trades) {
        if (trades.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROPUESTAS RECIBIDAS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.orange.shade700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            for (final trade in trades) _ProposedTradeTile(trade: trade),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _ProposedTradeTile extends ConsumerStatefulWidget {
  const _ProposedTradeTile({required this.trade});
  final TradeRequest trade;

  @override
  ConsumerState<_ProposedTradeTile> createState() => _ProposedTradeTileState();
}

class _ProposedTradeTileState extends ConsumerState<_ProposedTradeTile> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final trade = widget.trade;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (trade.fromMonsterImagePath != null)
                Image.asset(trade.fromMonsterImagePath!, width: 40, height: 40),
              const SizedBox(width: 8),
              const Icon(Icons.swap_horiz, size: 20),
              const SizedBox(width: 8),
              if (trade.toMonsterImagePath != null)
                Image.asset(trade.toMonsterImagePath!, width: 40, height: 40),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dás: ${trade.fromMonsterName}  →  Recibís: ${trade.toMonsterName ?? "?"}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : _reject,
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : _confirm,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Aceptar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    final suppressionKey = completedTradeRevealSuppressionKey(
      widget.trade.fromUserId,
      widget.trade.id,
    );
    try {
      final suppressedIds = ref.read(
        suppressedCompletedTradeRevealIdsProvider.notifier,
      );
      suppressedIds.state = {...suppressedIds.state, suppressionKey};

      await ref.read(tradeControllerProvider).confirmTrade(widget.trade);
      if (mounted) {
        ref.invalidate(ownedMonstersProvider);
      }

      final catalog = await ref.read(monstersProvider.future);
      final receivedName = widget.trade.toMonsterName;
      Monster? received;
      if (receivedName != null) {
        received = catalog.where((m) => m.name == receivedName).firstOrNull;
      }
      if (received != null && mounted) {
        await showGatchaReveal(context, received);
      }
      await ref
          .read(tradeControllerProvider)
          .markCompletedRevealSeen(widget.trade);
      suppressedIds.state = Set<String>.of(suppressedIds.state)
        ..remove(suppressionKey);
    } catch (e) {
      final suppressedIds = ref.read(
        suppressedCompletedTradeRevealIdsProvider.notifier,
      );
      suppressedIds.state = Set<String>.of(suppressedIds.state)
        ..remove(suppressionKey);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _loading = true);
    try {
      await ref.read(tradeControllerProvider).rejectProposal(widget.trade);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }
}

// ---------------------------------------------------------------------------
// Waiting trades (User B waiting for User A's response)
// ---------------------------------------------------------------------------

class _WaitingTradesSection extends ConsumerWidget {
  const _WaitingTradesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waitingAsync = ref.watch(myWaitingTradesProvider);
    return waitingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (trades) {
        if (trades.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ESPERANDO RESPUESTA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            for (final trade in trades) _WaitingTradeTile(trade: trade),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _WaitingTradeTile extends ConsumerWidget {
  const _WaitingTradeTile({required this.trade});
  final TradeRequest trade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          if (trade.toMonsterImagePath != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Image.asset(
                trade.toMonsterImagePath!,
                width: 40,
                height: 40,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ofreciste: ${trade.toMonsterName ?? "?"}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Por: ${trade.fromMonsterName}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(tradeControllerProvider).withdrawProposal(trade);
            },
            child: const Text('Retirar', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending trades list
// ---------------------------------------------------------------------------

class _PendingTradesSection extends ConsumerWidget {
  const _PendingTradesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(myPendingTradesProvider);
    final ownedIds = ref
        .watch(capturedMonstersProvider)
        .map((o) => o.id)
        .toSet();
    return pendingAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (trades) {
        final active = trades
            .where(
              (t) => !t.isExpired && ownedIds.contains(t.fromOwnedMonsterId),
            )
            .toList();
        if (active.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mis propuestas activas',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            for (final trade in active) _PendingTradeTile(trade: trade),
          ],
        );
      },
    );
  }
}

class _PendingTradeTile extends ConsumerWidget {
  const _PendingTradeTile({required this.trade});
  final TradeRequest trade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _TradeCodeDisplay(
              trade: trade,
              onCancel: () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            if (trade.fromMonsterImagePath != null)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Image.asset(
                  trade.fromMonsterImagePath!,
                  width: 40,
                  height: 40,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trade.fromMonsterName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Código: ${trade.code}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create Trade Screen
// ---------------------------------------------------------------------------

class _CreateTradeScreen extends ConsumerStatefulWidget {
  const _CreateTradeScreen();

  @override
  ConsumerState<_CreateTradeScreen> createState() => _CreateTradeScreenState();
}

class _CreateTradeScreenState extends ConsumerState<_CreateTradeScreen> {
  TradeRequest? _createdTrade;
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    if (_createdTrade != null) {
      return _TradeCodeDisplay(
        trade: _createdTrade!,
        onCancel: () => Navigator.of(context).pop(),
      );
    }

    final ownedAsync = ref.watch(capturedMonstersAsyncProvider);
    return Scaffold(
      appBar: const AppPageAppBar(title: 'Elegí tu monstruo'),
      body: ownedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (owned) {
          if (owned.isEmpty) {
            return const Center(child: Text('No tenés monstruos'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: owned.length,
            itemBuilder: (_, i) => _MonsterPickTile(
              owned: owned[i],
              enabled: !_creating,
              onTap: () => _createTrade(owned[i]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createTrade(OwnedMonster owned) async {
    if (!ref.read(tradeControllerProvider).hasCurrentUser) return;
    setState(() => _creating = true);
    try {
      final trade = await ref
          .read(tradeControllerProvider)
          .createTradeFromOwned(owned);
      if (trade == null) return;
      if (!mounted) return;
      setState(() => _createdTrade = trade);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _creating = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Trade Code Display (User A waits here)
// ---------------------------------------------------------------------------

class _TradeCodeDisplay extends ConsumerWidget {
  const _TradeCodeDisplay({required this.trade, required this.onCancel});
  final TradeRequest trade;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const AppPageAppBar(title: 'Tu código de trade'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Compartí este código con el otro jugador',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: trade.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Código copiado'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF7B1FA2),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _formatCode(trade.code),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: Color(0xFF7B1FA2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Toca para copiar',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              if (trade.fromMonsterImagePath != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Image.asset(
                    trade.fromMonsterImagePath!,
                    width: 80,
                    height: 80,
                  ),
                ),
              Text(
                'Ofrecés: ${trade.fromMonsterName}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Expira en 10 minutos',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(tradeControllerProvider).cancelTrade(trade);
                  onCancel();
                },
                child: const Text('Cancelar trade'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCode(String code) {
    if (code.length != 6) return code;
    return '${code.substring(0, 3)} ${code.substring(3)}';
  }
}

// ---------------------------------------------------------------------------
// Enter Code Screen (User B)
// ---------------------------------------------------------------------------

class _EnterCodeScreen extends ConsumerStatefulWidget {
  const _EnterCodeScreen();

  @override
  ConsumerState<_EnterCodeScreen> createState() => _EnterCodeScreenState();
}

class _EnterCodeScreenState extends ConsumerState<_EnterCodeScreen> {
  final _codeCtrl = TextEditingController();
  TradeRequest? _foundTrade;
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final code = _codeCtrl.text.trim();
    if (code.length < 6) {
      setState(() => _error = 'Ingresá 6 caracteres');
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    final trade = await ref.read(tradeControllerProvider).findByCode(code);
    if (!mounted) return;
    if (trade == null) {
      setState(() {
        _error = 'Código no encontrado o expirado';
        _searching = false;
      });
      return;
    }
    if (ref.read(tradeControllerProvider).isOwnTrade(trade)) {
      setState(() {
        _error = 'No podés aceptar tu propio trade';
        _searching = false;
      });
      return;
    }
    setState(() {
      _foundTrade = trade;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_foundTrade != null) {
      return _AcceptTradeScreen(
        trade: _foundTrade!,
        onDone: () => Navigator.of(context).pop(),
      );
    }

    return Scaffold(
      appBar: const AppPageAppBar(title: 'Ingresar código'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Ingresá el código que te compartieron',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'ABC123',
                errorText: _error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _searching ? null : _search,
                child: _searching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Buscar trade'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Accept Trade Screen (User B picks monster + confirms)
// ---------------------------------------------------------------------------

class _AcceptTradeScreen extends ConsumerStatefulWidget {
  const _AcceptTradeScreen({required this.trade, required this.onDone});
  final TradeRequest trade;
  final VoidCallback onDone;

  @override
  ConsumerState<_AcceptTradeScreen> createState() => _AcceptTradeScreenState();
}

class _AcceptTradeScreenState extends ConsumerState<_AcceptTradeScreen> {
  OwnedMonster? _selected;
  bool _executing = false;

  @override
  Widget build(BuildContext context) {
    final ownedAsync = ref.watch(capturedMonstersAsyncProvider);

    return Scaffold(
      appBar: const AppPageAppBar(title: 'Aceptar trade'),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF3E5F5),
            child: Column(
              children: [
                const Text(
                  'Te ofrecen:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7B1FA2)),
                ),
                const SizedBox(height: 8),
                if (widget.trade.fromMonsterImagePath != null)
                  Image.asset(
                    widget.trade.fromMonsterImagePath!,
                    width: 64,
                    height: 64,
                  ),
                const SizedBox(height: 6),
                Text(
                  widget.trade.fromMonsterName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Elegí qué monstruo das a cambio:',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: ownedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (owned) {
                if (owned.isEmpty) {
                  return const Center(child: Text('No tenés monstruos'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: owned.length,
                  itemBuilder: (_, i) => _MonsterPickTile(
                    owned: owned[i],
                    selected: _selected?.id == owned[i].id,
                    enabled: !_executing,
                    onTap: () => setState(() => _selected = owned[i]),
                  ),
                );
              },
            ),
          ),
          if (_selected != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _executing ? null : _execute,
                    child: _executing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Proponer: ${_selected!.monster.name}'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _execute() async {
    final selected = _selected;
    if (selected == null) return;
    if (!ref.read(tradeControllerProvider).hasCurrentUser) return;
    setState(() => _executing = true);
    try {
      await ref
          .read(tradeControllerProvider)
          .proposeTrade(trade: widget.trade, selected: selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Propuesta enviada. Esperando confirmación...'),
        ),
      );
      widget.onDone();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _executing = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Monster pick tile (shared)
// ---------------------------------------------------------------------------

class _MonsterPickTile extends StatelessWidget {
  const _MonsterPickTile({
    required this.owned,
    required this.onTap,
    this.selected = false,
    this.enabled = true,
  });

  final OwnedMonster owned;
  final VoidCallback onTap;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        color: selected ? const Color(0xFFE8F5E9) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: selected
              ? const BorderSide(color: Color(0xFF4CAF50), width: 2)
              : BorderSide.none,
        ),
        child: ListTile(
          leading: Image.asset(owned.monster.imagePath, width: 48, height: 48),
          title: Text(
            owned.monster.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            owned.monster.rarity.label,
            style: TextStyle(color: owned.monster.rarity.color, fontSize: 12),
          ),
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }
}
