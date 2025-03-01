import 'package:flutter/material.dart';

class CardBackFallback extends StatelessWidget {
  final bool isPokemon;
  final BorderRadius borderRadius;
  
  const CardBackFallback({
    super.key,
    this.isPokemon = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPokemon 
                ? [Colors.red.shade700, Colors.red.shade900]
                : [Colors.brown.shade800, Colors.brown.shade900],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isPokemon
                        ? [Colors.yellow.shade600, Colors.orange.shade700]
                        : [Colors.grey.shade400, Colors.grey.shade700],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: isPokemon
                    ? const Icon(Icons.catching_pokemon, color: Colors.white, size: 50)
                    : const Icon(Icons.auto_awesome, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 16),
              Text(
                isPokemon ? 'Pokémon' : 'Magic',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Card Back',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
