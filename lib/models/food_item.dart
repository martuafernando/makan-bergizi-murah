class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String category;
  final String emoji;

  const FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.category,
    required this.emoji,
  });

  double get nutritionScore {
    // Simple score: high protein + moderate carbs, low fat is better
    return (protein * 2) + (carbs * 0.5) - (fat * 0.3);
  }

  String get priceCategory {
    if (price <= 5000) return 'Murah Banget';
    if (price <= 15000) return 'Terjangkau';
    if (price <= 30000) return 'Sedang';
    return 'Premium';
  }
}

// Sample data
final List<FoodItem> sampleFoods = [
  const FoodItem(
    id: '1',
    name: 'Nasi Telur Dadar',
    description: 'Nasi putih + telur dadar + lalapan. Simpel, kenyang, bergizi.',
    price: 8000,
    calories: 450,
    protein: 15,
    carbs: 60,
    fat: 12,
    category: 'Nasi',
    emoji: '🍳',
  ),
  const FoodItem(
    id: '2',
    name: 'Tempe Goreng + Nasi',
    description: 'Tempe goreng crispy dengan nasi hangat. Protein nabati terbaik!',
    price: 6000,
    calories: 380,
    protein: 18,
    carbs: 55,
    fat: 10,
    category: 'Nasi',
    emoji: '🟫',
  ),
  const FoodItem(
    id: '3',
    name: 'Bubur Ayam',
    description: 'Bubur lembut dengan suwiran ayam, cakwe, dan kecap.',
    price: 10000,
    calories: 320,
    protein: 20,
    carbs: 40,
    fat: 8,
    category: 'Bubur',
    emoji: '🥣',
  ),
  const FoodItem(
    id: '4',
    name: 'Gado-gado',
    description: 'Sayuran rebus dengan saus kacang. Penuh vitamin dan mineral!',
    price: 12000,
    calories: 350,
    protein: 14,
    carbs: 38,
    fat: 15,
    category: 'Sayur',
    emoji: '🥗',
  ),
  const FoodItem(
    id: '5',
    name: 'Mie Ayam',
    description: 'Mie kenyal dengan topping ayam cincang dan bakso.',
    price: 14000,
    calories: 480,
    protein: 22,
    carbs: 65,
    fat: 14,
    category: 'Mie',
    emoji: '🍜',
  ),
  const FoodItem(
    id: '6',
    name: 'Pecel Lele + Nasi',
    description: 'Lele goreng renyah + sambal + lalapan. Ikan = omega-3!',
    price: 15000,
    calories: 520,
    protein: 30,
    carbs: 58,
    fat: 18,
    category: 'Nasi',
    emoji: '🐟',
  ),
];
