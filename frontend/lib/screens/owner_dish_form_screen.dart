import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/dish.dart';
import '../services/category_service.dart';
import '../services/restaurant_owner_service.dart';
import '../theme/app_colors.dart';
import '../utils/dish_allergens.dart';
import '../widgets/ui/app_ui_widgets.dart';

class OwnerDishFormScreen extends StatefulWidget {
  const OwnerDishFormScreen({
    super.key,
    required this.restaurantId,
    this.dish,
  });

  final int restaurantId;
  final Dish? dish;

  bool get isEditing => dish != null;

  @override
  State<OwnerDishFormScreen> createState() => _OwnerDishFormScreenState();
}

class _OwnerDishFormScreenState extends State<OwnerDishFormScreen> {
  final _service = RestaurantOwnerService();
  final _categories = CategoryService();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _cuisine = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fats = TextEditingController();
  final _fiber = TextEditingController();
  final _sugar = TextEditingController();
  final _sodium = TextEditingController();
  final _ingredients = TextEditingController();
  final _imageUrl = TextEditingController();

  List<Map<String, dynamic>> _categoryOptions = [];
  int? _categoryId;
  bool _available = true;
  final Set<String> _allergens = {};
  bool _loading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.dish;
    if (d != null) {
      _name.text = d.name;
      _description.text = d.description ?? '';
      _price.text = d.price.toString();
      _cuisine.text = d.cuisine ?? '';
      _calories.text = d.calories?.toString() ?? '';
      _protein.text = d.protein?.toString() ?? '';
      _carbs.text = d.carbs?.toString() ?? '';
      _fats.text = d.fats?.toString() ?? '';
      _fiber.text = d.fiber?.toString() ?? '';
      _sugar.text = d.sugar?.toString() ?? '';
      _sodium.text = d.sodium?.toString() ?? '';
      _ingredients.text = d.ingredients.join(', ');
      _imageUrl.text = d.image ?? '';
      _categoryId = d.categoryId;
      _available = d.isAvailable;
      _allergens.addAll(d.allergens);
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _cuisine.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fats.dispose();
    _fiber.dispose();
    _sugar.dispose();
    _sodium.dispose();
    _ingredients.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _loading = true);
    try {
      final raw = await _categories.list(limit: 100);
      _categoryOptions = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      _categoryId ??= _categoryOptions.isNotEmpty ? _categoryOptions.first['id'] as int? : null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage(int dishId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() => _saving = true);
    try {
      final updated = await _service.uploadDishImage(
        dishId: dishId,
        bytes: file.bytes!,
        filename: file.name,
      );
      _imageUrl.text = updated.image ?? '';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _price.text.trim().isEmpty || _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, price, and category are required')),
      );
      return;
    }

    final body = {
      'restaurant_id': widget.restaurantId,
      'category_id': _categoryId,
      'name': _name.text.trim(),
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'price': double.tryParse(_price.text.trim()) ?? 0,
      'cuisine': _cuisine.text.trim().isEmpty ? null : _cuisine.text.trim(),
      'calories': int.tryParse(_calories.text.trim()),
      'protein': double.tryParse(_protein.text.trim()),
      'carbs': double.tryParse(_carbs.text.trim()),
      'fats': double.tryParse(_fats.text.trim()),
      'fiber': double.tryParse(_fiber.text.trim()),
      'sugar': double.tryParse(_sugar.text.trim()),
      'sodium': double.tryParse(_sodium.text.trim()),
      'ingredients': _ingredients.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      'allergens': _allergens.toList(),
      'image': _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      'is_available': _available,
    };

    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        body.remove('restaurant_id');
        await _service.updateDish(widget.dish!.id, body);
      } else {
        await _service.createDish(body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit dish' : 'New dish'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView(
              padding: const EdgeInsets.all(AppColors.screenPadding),
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Dish name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _price,
                  decoration: const InputDecoration(labelText: 'Price (PKR) *'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category *'),
                  items: _categoryOptions
                      .map(
                        (c) => DropdownMenuItem(
                          value: c['id'] as int?,
                          child: Text(c['name']?.toString() ?? 'Category'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cuisine,
                  decoration: const InputDecoration(labelText: 'Cuisine'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Available'),
                  value: _available,
                  onChanged: (v) => setState(() => _available = v),
                ),
                const SizedBox(height: 8),
                Text('Nutrition', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _nutritionRow('Calories', _calories),
                _nutritionRow('Protein (g)', _protein),
                _nutritionRow('Carbs (g)', _carbs),
                _nutritionRow('Fats (g)', _fats),
                _nutritionRow('Fiber (g)', _fiber),
                _nutritionRow('Sugar (g)', _sugar),
                _nutritionRow('Sodium (mg)', _sodium),
                const SizedBox(height: 12),
                TextField(
                  controller: _ingredients,
                  decoration: const InputDecoration(
                    labelText: 'Ingredients',
                    hintText: 'Comma-separated',
                  ),
                ),
                const SizedBox(height: 12),
                Text('Allergens', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DishAllergens.options.map((entry) {
                    final selected = _allergens.contains(entry.$1);
                    return FilterChip(
                      label: Text(entry.$2),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _allergens.add(entry.$1);
                          } else {
                            _allergens.remove(entry.$1);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _imageUrl,
                  decoration: const InputDecoration(labelText: 'Image URL (optional)'),
                ),
                if (widget.isEditing) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : () => _pickImage(widget.dish!.id),
                    icon: const Icon(Icons.upload_outlined),
                    label: const Text('Upload image'),
                  ),
                ],
                const SizedBox(height: 20),
                GoldActionButton(
                  label: widget.isEditing ? 'Save changes' : 'Create dish',
                  icon: Icons.save_outlined,
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
    );
  }

  Widget _nutritionRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
      ),
    );
  }
}
