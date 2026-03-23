import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../widgets/food_card.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCategory = 'Semua';
  String _sortBy = 'price';

  List<String> get categories {
    final cats = sampleFoods.map((f) => f.category).toSet().toList();
    cats.sort();
    return ['Semua', ...cats];
  }

  List<FoodItem> get filteredFoods {
    var foods = _selectedCategory == 'Semua'
        ? List<FoodItem>.from(sampleFoods)
        : sampleFoods.where((f) => f.category == _selectedCategory).toList();

    switch (_sortBy) {
      case 'price':
        foods.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'calories':
        foods.sort((a, b) => a.calories.compareTo(b.calories));
        break;
      case 'protein':
        foods.sort((a, b) => b.protein.compareTo(a.protein));
        break;
    }
    return foods;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Menu 🍽️'),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Urutkan',
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'price', child: Text('Harga Termurah')),
              PopupMenuItem(value: 'calories', child: Text('Kalori Terendah')),
              PopupMenuItem(value: 'protein', child: Text('Protein Tertinggi')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final selected = cat == _selectedCategory;
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredFoods.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  FoodCard(food: filteredFoods[index], showNutrition: true),
            ),
          ),
        ],
      ),
    );
  }
}
