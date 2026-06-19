import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/onboarding_option.dart';
import '../providers/onboarding_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/onboarding/allergy_choice_chip.dart';
import '../widgets/onboarding/cuisine_thumbnail_tile.dart';
import '../widgets/ui/app_ui_widgets.dart';

class PreferenceOnboardingScreen extends StatefulWidget {
  const PreferenceOnboardingScreen({super.key});

  @override
  State<PreferenceOnboardingScreen> createState() => _PreferenceOnboardingScreenState();
}

class _PreferenceOnboardingScreenState extends State<PreferenceOnboardingScreen> {
  final PageController _pageController = PageController();
  int _step = 0;
  final Set<String> _selectedInterests = {};
  final Set<String> _selectedAllergies = {};

  static const _maxInterests = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OnboardingProvider>().loadOptions();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  IconData _iconForInterest(String key) {
    const icons = {
      'burger': Icons.lunch_dining,
      'pizza': Icons.local_pizza,
      'biryani': Icons.rice_bowl,
      'bbq': Icons.outdoor_grill,
      'chinese': Icons.ramen_dining,
      'italian': Icons.dinner_dining,
      'shawarma': Icons.kebab_dining,
      'desserts': Icons.cake_outlined,
      'healthy': Icons.eco_outlined,
      'cafe': Icons.local_cafe,
      'sushi': Icons.set_meal,
      'pakistani': Icons.restaurant,
      'fast_food': Icons.fastfood,
      'seafood': Icons.set_meal_outlined,
      'sandwiches': Icons.breakfast_dining,
    };
    return icons[key] ?? Icons.restaurant_menu;
  }

  IconData _iconForAllergy(String key) {
    const icons = {
      'peanuts': Icons.warning_amber_rounded,
      'tree_nuts': Icons.park_outlined,
      'shellfish': Icons.water,
      'fish': Icons.phishing,
      'eggs': Icons.egg_alt_outlined,
      'milk': Icons.local_drink_outlined,
      'dairy': Icons.icecream_outlined,
      'gluten': Icons.grain,
      'wheat': Icons.grass,
      'nuts': Icons.circle_outlined,
    };
    return icons[key] ?? Icons.health_and_safety_outlined;
  }

  Future<void> _skip() async {
    final provider = context.read<OnboardingProvider>();
    final ok = await provider.skip();
    if (!mounted) return;
    if (!ok) {
      _showError(provider.error ?? 'Could not skip onboarding');
    }
  }

  Future<void> _finish() async {
    final provider = context.read<OnboardingProvider>();
    final ok = await provider.complete(
      favoriteCuisines: _selectedInterests.toList(),
      allergies: _selectedAllergies.toList(),
    );
    if (!mounted) return;
    if (!ok) {
      _showError(provider.error ?? 'Could not save preferences');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _nextStep() {
    if (_step == 0) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  Widget _buildProgress() {
    return Row(
      children: List.generate(2, (index) {
        final active = index <= _step;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(right: index == 0 ? 8 : 0),
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: active ? AppColors.goldGradient : null,
              color: active ? null : AppColors.surfaceLight,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInterestsGrid({
    required List<OnboardingOption> options,
    required Set<String> selected,
    required void Function(String key) onToggle,
    required IconData Function(String key) iconFor,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 2,
        childAspectRatio: 0.72,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        return CuisineThumbnailTile(
          label: option.displayName,
          icon: iconFor(option.key),
          selected: selected.contains(option.key),
          accent: AppColors.gold,
          onTap: () => onToggle(option.key),
        );
      },
    );
  }

  Widget _buildAllergyChips({
    required List<OnboardingOption> options,
    required Set<String> selected,
    required void Function(String key) onToggle,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option.key);
            return AllergyChoiceChip(
              label: option.displayName,
              selected: isSelected,
              onSelected: (_) => onToggle(option.key),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OnboardingProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF15151C), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    if (_step > 0)
                      IconButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        icon: const Icon(Icons.arrow_back),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        'Personalize your feed',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: provider.loading ? null : _skip,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _buildProgress(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _step == 0
                        ? 'What do you love to eat?'
                        : 'Any allergies we should know about?',
                    key: ValueKey(_step),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _step == 0
                        ? 'Pick up to $_maxInterests cuisines. We\'ll tailor recommendations for you.'
                        : 'Optional — tap any allergens to exclude risky dishes.',
                    key: ValueKey('sub_$_step'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              Expanded(
                child: provider.optionsLoading && provider.options == null
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      )
                    : provider.options == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              EmptyState(
                                icon: Icons.cloud_off_outlined,
                                title: 'Could not load options',
                                subtitle: provider.error ?? 'Check your connection',
                              ),
                              TextButton(
                                onPressed: () => provider.loadOptions(),
                                child: const Text('Retry'),
                              ),
                            ],
                          )
                        : PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            onPageChanged: (index) => setState(() => _step = index),
                            children: [
                              _buildInterestsGrid(
                                options: provider.options!.foodInterests,
                                selected: _selectedInterests,
                                iconFor: _iconForInterest,
                                onToggle: (key) {
                                  setState(() {
                                    if (_selectedInterests.contains(key)) {
                                      _selectedInterests.remove(key);
                                    } else if (_selectedInterests.length < _maxInterests) {
                                      _selectedInterests.add(key);
                                    }
                                  });
                                },
                              ),
                              _buildAllergyChips(
                                options: provider.options!.allergies,
                                selected: _selectedAllergies,
                                onToggle: (key) {
                                  setState(() {
                                    if (_selectedAllergies.contains(key)) {
                                      _selectedAllergies.remove(key);
                                    } else {
                                      _selectedAllergies.add(key);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_step == 0)
                      Text(
                        '${_selectedInterests.length} / $_maxInterests selected',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (_step == 1)
                      Text(
                        '${_selectedAllergies.length} allerg${_selectedAllergies.length == 1 ? 'y' : 'ies'} selected',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 10),
                    GoldActionButton(
                      label: _step == 0 ? 'Continue' : 'Finish setup',
                      icon: _step == 0 ? Icons.arrow_forward : Icons.check_circle_outline,
                      loading: provider.loading,
                      onPressed: provider.loading ? null : _nextStep,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
