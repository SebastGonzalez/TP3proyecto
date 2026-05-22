import 'package:flutter/material.dart';

/// Chip de insignia (solo el badge dorado).
class CompleteDexBadge extends StatelessWidget {
  const CompleteDexBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB300), Color(0xFFFF6B00)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, color: Colors.white, size: 18),
          SizedBox(width: 6),
          Text(
            'Colección completa',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Insignia + leyenda debajo (la leyenda no va dentro del chip).
class CompleteDexAward extends StatelessWidget {
  const CompleteDexAward({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CompleteDexBadge(),
        const SizedBox(height: 6),
        Text(
          'Capturaste todas las especies',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
