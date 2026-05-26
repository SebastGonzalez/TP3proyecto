import 'package:flutter/material.dart';
import 'package:prueba1/presentation/widgets/app_page_app_bar.dart';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 2. Importamos tu provider de monedas
import 'package:prueba1/features/shop/application/providers/coin_provider.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  // Configuración del tablero de 5x5
  final int gridSize = 5;
  late List<List<int>> boardValues;
  late List<List<bool>> boardFlipped;
  
  int currentScore = 1; // El puntaje de la ronda empieza multiplicando por 1
  int totalCoins = 0;   // Monedas totales guardadas
  bool gameOver = false;
  bool gameWon = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  // Genera un nuevo tablero matemático respetando la esencia de Voltorb Flip
  void _startNewGame() {
    setState(() {
      boardValues = List.generate(gridSize, (_) => List.generate(gridSize, (_) => 1));
      boardFlipped = List.generate(gridSize, (_) => List.generate(gridSize, (_) => false));
      currentScore = 1;
      gameOver = false;
      gameWon = false;

      final random = Random();

      // Colocar las "X" (Ceros peligrosos) - Entre 4 y 7 por partida para balancear
      int totalX = random.nextInt(4) + 4; 
      while (totalX > 0) {
        int r = random.nextInt(gridSize);
        int c = random.nextInt(gridSize);
        if (boardValues[r][c] == 1) {
          boardValues[r][c] = 0; // 0 representa la X letal
          totalX--;
        }
      }

      // Colocar algunos Multiplicadores (2s y 3s)
      int totalThrees = random.nextInt(3) + 2; // entre 2 y 4 triples
      int totalTwos = random.nextInt(4) + 3;   // entre 3 && 6 dobles

      while (totalThrees > 0) {
        int r = random.nextInt(gridSize);
        int c = random.nextInt(gridSize);
        if (boardValues[r][c] == 1) {
          boardValues[r][c] = 3;
          totalThrees--;
        }
      }

      while (totalTwos > 0) {
        int r = random.nextInt(gridSize);
        int c = random.nextInt(gridSize);
        if (boardValues[r][c] == 1) {
          boardValues[r][c] = 2;
          totalTwos--;
        }
      }
    });
  }

  // Suma de puntos por fila
  int _getRowSum(int row) => boardValues[row].reduce((a, b) => a + b);
  // Conteo de "X" (Ceros) por fila
  int _getRowXCount(int row) => boardValues[row].where((v) => v == 0).length;

  // Suma de puntos por columna
  int _getColSum(int col) {
    int sum = 0;
    for (int r = 0; r < gridSize; r++) { sum += boardValues[r][col]; }
    return sum;
  }
  // Conteo de "X" (Ceros) por columna
  int _getColXCount(int col) {
    int count = 0;
    for (int r = 0; r < gridSize; r++) { if (boardValues[r][col] == 0) count++; }
    return count;
  }

  // Verifica si ya se revelaron todos los 2 y 3 del tablero
  void _checkWinCondition() {
    bool won = true;
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if ((boardValues[r][c] == 2 || boardValues[r][c] == 3) && !boardFlipped[r][c]) {
          won = false;
          break;
        }
      }
    }
    if (won) {
      setState(() {
        gameWon = true;
        ref.read(coinControllerProvider).update((c) => c + currentScore);
      });
    }
  }

  // Al presionar una casilla
  void _flipTile(int row, int col) {
    if (gameOver || gameWon || boardFlipped[row][col]) return;

    setState(() {
      boardFlipped[row][col] = true;
      int value = boardValues[row][col];

      if (value == 0) {
        // Encontró una X: Pierde todo lo acumulado en esta ronda
        gameOver = true;
        currentScore = 0;
        // Revelar todas las X del mapa para que el jugador vea dónde estaban
        for (int r = 0; r < gridSize; r++) {
          for (int c = 0; c < gridSize; c++) {
            if (boardValues[r][c] == 0) boardFlipped[r][c] = true;
          }
        }
      } else {
        // Multiplica si es 2 o 3, si es 1 se mantiene igual (x1)
        if (value > 1) {
          currentScore *= value;
        }
        _checkWinCondition();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: const AppPageAppBar(
        title: 'X Flip - MiniGame',
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Marcador de Monedas / Estado del juego
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox("Ronda actual", "$currentScore 🪙"),
                _buildStatBox("Total acumulado", "$totalCoins 💰"),
              ],
            ),
          ),

          // Contenedor del Tablero + Pistas
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                //gridCount: 6, // 5 casillas + 1 de indicador por fila/columna
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: 36, // Matriz de 6x6
                itemBuilder: (context, index) {
                  int r = index ~/ 6;
                  int c = index % 6;

                  // Esquina inferior derecha (vacía o botón de reset rápido)
                  if (r == 5 && c == 5) {
                    return Container(color: Colors.transparent);
                  }

                  // Pista de fin de Fila (Fila 'r', Columna 5)
                  if (c == 5) {
                    return _buildClueBox(_getRowSum(r), _getRowXCount(r));
                  }

                  // Pista de fin de Columna (Fila 5, Columna 'c')
                  if (r == 5) {
                    return _buildClueBox(_getColSum(c), _getColXCount(c));
                  }

                  // Casilla interactiva del Juego
                  bool isFlipped = boardFlipped[r][c];
                  int cellValue = boardValues[r][c];

                  return GestureDetector(
                    onTap: () => _flipTile(r, c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isFlipped 
                            ? (cellValue == 0 ? Colors.red[700] : Colors.amber[600]) 
                            : Colors.deepPurple[400],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      alignment: Alignment.center,
                      child: isFlipped
                          ? (cellValue == 0 
                              ? const Text('X', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))
                              : Text('$cellValue', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)))
                          : const Icon(Icons.help_outline, color: Colors.white70),
                    ),
                  );
                },
              ),
            ),
          ),

          // Pantalla informativa flotante de estado y botón de acción
          Column(
            children: [
              if (gameOver)
                const Text("¡💥 Boom! Diste con una X. Perdiste.", style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold))
              else if (gameWon)
                const Text("¡🎉 ¡Felicidades! Limpiaste la zona.", style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold))
              else
                const Text("Evita las 'X' y multiplica tus puntos", style: TextStyle(color: Colors.white60, fontSize: 14)),
              
              const SizedBox(height: 12),
              
              ElevatedButton.icon(
                onPressed: _startNewGame,
                icon: const Icon(Icons.refresh),
                label: Text(gameOver || gameWon ? "Jugar de Nuevo" : "Reiniciar Tablero"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Componente visual para los marcadores superiores
  Widget _buildStatBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.deepPurple.shade300),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Componente visual para los bloques de pistas matemáticas exteriores
  Widget _buildClueBox(int sum, int xCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Suma total arriba
          Text('$sum', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 13)),
          const Divider(color: Colors.brown, height: 4, thickness: 1),
          // Cuántas X abajo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('X:', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
              Text('$xCount', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          )
        ],
      ),
    );
  }
}
