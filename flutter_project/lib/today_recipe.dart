import 'dart:math';
import 'package:flutter/material.dart';
import 'models/recipe.dart'; // Recipe 클래스

class TodayRecipeCard extends StatelessWidget {
  final List<Recipe> recipes;

  const TodayRecipeCard({super.key, required this.recipes});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Recipe>(
      future: _fetchTodayRecipe(recipes),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final recipe = snapshot.data!;
        return Card(
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(recipe.imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('오늘의 추천: ${recipe.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(recipe.description),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Recipe> _fetchTodayRecipe(List<Recipe> list) async {
    await Future.delayed(const Duration(milliseconds: 300)); // 가짜 로딩
    final now = DateTime.now();
    final seed = int.parse('${now.year}${now.month}${now.day}');
    final random = Random(seed);
    return list[random.nextInt(list.length)];
  }
}
