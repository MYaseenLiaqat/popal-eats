import '../models/reel.dart';

/// Placeholder catalog until reels API is available.
const placeholderReels = <Reel>[
  Reel(
    id: 'reel-1',
    kind: ReelKind.recipe,
    title: 'Smoky chicken tikka bowls',
    creatorName: 'Home Kitchen',
    caption: 'A weeknight-friendly Lahore classic with charred edges and fresh salad.',
    durationLabel: '0:45',
  ),
  Reel(
    id: 'reel-2',
    kind: ReelKind.chef,
    title: 'Street-style bun kabab',
    creatorName: 'Old Anarkali Stall',
    caption: 'Crispy patty, chutney, and the perfect soft bun — watch the build.',
    durationLabel: '1:02',
  ),
  Reel(
    id: 'reel-3',
    kind: ReelKind.recipe,
    title: 'Quick daal chawal for two',
    creatorName: 'Comfort Food Club',
    caption: 'Minimal ingredients, maximum flavor — ready before your rice finishes.',
    durationLabel: '0:38',
  ),
  Reel(
    id: 'reel-4',
    kind: ReelKind.chef,
    title: 'Behind the grill at a burger spot',
    creatorName: 'Gulberg Grill',
    caption: 'See how the smash patty gets its crust and why the queue stays long.',
    durationLabel: '1:15',
  ),
  Reel(
    id: 'reel-5',
    kind: ReelKind.recipe,
    title: 'Crispy fish pakora platter',
    creatorName: 'Coastal Lahore',
    caption: 'Light batter, bright lemon, and a mint raita dip you can meal-prep.',
    durationLabel: '0:52',
  ),
];
