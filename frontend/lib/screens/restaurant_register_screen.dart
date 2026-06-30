import 'package:flutter/material.dart';

import '../data/cuisine_catalog.dart';
import '../services/restaurant_owner_service.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_screen_widgets.dart';
import '../widgets/ui/app_ui_widgets.dart';

class RestaurantRegisterScreen extends StatefulWidget {
  const RestaurantRegisterScreen({super.key});

  @override
  State<RestaurantRegisterScreen> createState() => _RestaurantRegisterScreenState();
}

class _RestaurantRegisterScreenState extends State<RestaurantRegisterScreen> {
  final _service = RestaurantOwnerService();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController(text: 'Lahore');
  final _phone = TextEditingController();
  String? _cuisine;
  String _venueType = 'restaurant';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _city.dispose();
    _phone.dispose();
    super.dispose();
  }

  String _venueLabel() => switch (_venueType) {
        'food_chain' => 'Food chain / hotel',
        'home_kitchen' => 'Home kitchen',
        _ => 'Restaurant / dine-in',
      };

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      _showError('Business name is required');
      return;
    }
    if (_address.text.trim().isEmpty) {
      _showError('Address is required');
      return;
    }
    if (_cuisine == null || _cuisine!.isEmpty) {
      _showError('Please select a cuisine type');
      return;
    }

    final custom = _description.text.trim();
    final description = custom.isEmpty
        ? 'Venue type: ${_venueLabel()}. $_cuisine in Lahore'
        : 'Venue type: ${_venueLabel()}. $custom';

    setState(() => _saving = true);
    try {
      await _service.createRestaurant({
        'name': _name.text.trim(),
        'description': description,
        'address': _address.text.trim(),
        'city': _city.text.trim().isNotEmpty ? _city.text.trim() : 'Lahore',
        if (_phone.text.trim().isNotEmpty) 'phone_number': _phone.text.trim(),
        'tags': [_cuisine!, 'venue:$_venueType'],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitted for approval — check Business portal after login')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showError('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppColors.screenPadding),
          children: [
            const AuthBrandedHeader(
              title: 'Register your business',
              subtitle:
                  'Restaurant, food chain, or home kitchen — one portal for orders, menu, and analytics.',
            ),
            const SizedBox(height: 20),
            AuthFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _name,
                    decoration: authInputDecoration(
                      context,
                      label: 'Business name',
                      hint: 'e.g. Spice Garden',
                      icon: Icons.storefront_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _venueType,
                    decoration: authInputDecoration(
                      context,
                      label: 'How do you operate?',
                      icon: Icons.store_mall_directory_outlined,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'restaurant',
                        child: Text('Restaurant / dine-in'),
                      ),
                      DropdownMenuItem(
                        value: 'food_chain',
                        child: Text('Food chain / hotel'),
                      ),
                      DropdownMenuItem(
                        value: 'home_kitchen',
                        child: Text('Home kitchen'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _venueType = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _cuisine,
                    decoration: authInputDecoration(
                      context,
                      label: 'Cuisine type',
                      icon: Icons.restaurant_outlined,
                    ),
                    items: CuisineCatalog.cuisines
                        .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _cuisine = v),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _description,
                    maxLines: 3,
                    decoration: authInputDecoration(
                      context,
                      label: 'Description',
                      hint: 'Tell customers what makes you special',
                      icon: Icons.description_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _address,
                    decoration: authInputDecoration(
                      context,
                      label: 'Address',
                      hint: 'Street, area, Lahore',
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _city,
                    decoration: authInputDecoration(
                      context,
                      label: 'City',
                      icon: Icons.location_city_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: authInputDecoration(
                      context,
                      label: 'Business phone',
                      icon: Icons.phone_outlined,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GoldActionButton(
                    label: 'Submit for approval',
                    icon: Icons.send_outlined,
                    loading: _saving,
                    onPressed: _saving ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
