import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/allergy_assets.dart';
import '../data/allergy_catalog.dart';
import '../data/cuisine_catalog.dart';
import '../models/onboarding_option.dart';
import '../providers/onboarding_provider.dart';
import '../theme/app_colors.dart';
import '../utils/preference_feedback.dart';
import '../widgets/onboarding/cuisine_preference_card.dart';
import '../widgets/ui/app_ui_widgets.dart';

class PreferenceOnboardingScreen extends StatefulWidget {
  const PreferenceOnboardingScreen({super.key});

  @override
  State<PreferenceOnboardingScreen> createState() => _PreferenceOnboardingScreenState();
}

class _PreferenceOnboardingScreenState extends State<PreferenceOnboardingScreen> {
  final PageController _pageController = PageController();
  int _step = 0;
  final Set<String> _selectedCuisines = {};
  final Set<String> _selectedAllergies = {};

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

  List<OnboardingOption> _allergyOptions(List<OnboardingOption> options) {
    return AllergyCatalog.optionsFromApi(options);
  }

  Widget _buildAllergyGrid(List<OnboardingOption> options) {
    final columns = _gridColumns(context);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: columns >= 4 ? 0.82 : 0.88,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final selected = _selectedAllergies.contains(option.key);
        return CuisinePreferenceCard(
          label: option.displayName,
          imageAsset: AllergyAssets.pathFor(option.key),
          imageAlignment: AllergyAssets.alignmentFor(option.key),
          selected: selected,
          onTap: () {
            setState(() {
              if (_selectedAllergies.contains(option.key)) {
                _selectedAllergies.remove(option.key);
              } else {
                _selectedAllergies.add(option.key);
              }
            });
          },
        );
      },
    );
  }

  int _gridColumns(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
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
      favoriteCuisines: _selectedCuisines.toList(),
      allergies: _selectedAllergies.toList(),
    );
    if (!mounted) return;
    if (!ok) {
      _showError(provider.error ?? 'Could not save preferences');
    } else {
      showPreferencesSavedFeedback(
        context,
        message: 'Preferences saved — your feed is personalized',
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _goBack() {
    if (_step <= 0) return;
    setState(() => _step = 0);
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _nextStep() {
    if (_step == 0) {
      setState(() => _step = 1);
      _pageController.animateToPage(
        1,
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
              gradient: active ? AppColors.accentGradient : null,
              color: active ? null : AppColors.surfaceLight,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSelectionProgress(int selected, int max, String noun) {
    final fraction = max == 0 ? 0.0 : selected / max;
    return Column(
      children: [
        Text(
          '$selected / $max $noun selected',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 4,
            backgroundColor: AppColors.surfaceLight,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildCuisineGrid() {
    final columns = _gridColumns(context);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: columns >= 4 ? 0.82 : 0.88,
      ),
      itemCount: CuisineCatalog.cuisines.length,
      itemBuilder: (context, index) {
        final cuisine = CuisineCatalog.cuisines[index];
        final selected = _selectedCuisines.contains(cuisine.key);
        return CuisinePreferenceCard(
          label: cuisine.name,
          imageAsset: cuisine.imageAsset,
          description: cuisine.description,
          selected: selected,
          onTap: () {
            setState(() {
              if (_selectedCuisines.contains(cuisine.key)) {
                _selectedCuisines.remove(cuisine.key);
              } else if (_selectedCuisines.length < CuisineCatalog.maxSelections) {
                _selectedCuisines.add(cuisine.key);
              }
            });
          },
        );
      },
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
            colors: [AppColors.surface, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
                child: Row(
                  children: [
                    if (_step > 0)
                      IconButton(
                        onPressed: _goBack,
                        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        'Personalize your feed',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
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
                        ? 'Pick up to ${CuisineCatalog.maxSelections} cuisines. We\'ll tailor recommendations for you.'
                        : 'Optional — tap any allergens to exclude risky dishes.',
                    key: ValueKey('sub_$_step'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ),
              Expanded(
                child: provider.optionsLoading && provider.options == null
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.accent),
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
                              _buildCuisineGrid(),
                              _buildAllergyGrid(
                                _allergyOptions(provider.options!.allergies),
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
                      _buildSelectionProgress(
                        _selectedCuisines.length,
                        CuisineCatalog.maxSelections,
                        'cuisines',
                      )
                    else if (provider.options != null)
                      _buildSelectionProgress(
                        _selectedAllergies.length,
                        AllergyCatalog.count,
                        'allergies',
                      )
                    else
                      Text(
                        '${_selectedAllergies.length} allerg${_selectedAllergies.length == 1 ? 'y' : 'ies'} selected',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
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
