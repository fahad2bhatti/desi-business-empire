import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Ids that have a real photo in assets/images/ID.jpg. Anything not listed
/// keeps its drawn art.
const _photoIds = {
  'goal_taps',
  'goal_levels',
  'goal_income',
  'goal_worth',
  'goal_trophy',
  'car',
  'sedan',
  'suv',
  'cruiser',
  'luxsuv',
  'cayenne',
  'sportscar',
  'gt3',
  'gt2',
  'jet',
  'helicopter',
  'rentacar',
  'room',
  'flat',
  'familyhome',
  'bungalow',
  'villa',
  'mansion',
  'house',
  'farmhouse',
  'r8',
  'gtr',
  'airbus',
  'rescue',
  'navyheli',
  'huey',
  'apache',
  'chinook',
  'unitid',
  'etihaad',
  'kanada',
  'cottage',
  'townhouse',
  'chalet',
  'poolvilla',
  'samosa',
  'chai',
  'chaat',
  'rickshaw',
  'taxi',
  'loader',
  'bus',
  'transport',
  'factory',
  'hall',
  'restaurant',
  'mechanic',
  'cloth',
  'mobile',
  'kiryana',
  'pendant',
  'goldset',
  'longset',
  'kundan',
  'bridal',
  'temple',
  'jewellery',
  'diamondset',
  'emerald',
  'popart',
  'canvas',
  'floral',
  'modernart',
  'abstract',
  'gallery',
  'painting',
  'oldmasters',
  'museum',
  'watch',
  'wstreet',
  'wskeleton',
  'wdress',
  'wvintage',
  'wdiver',
  'sailboat',
  'sportyacht',
  'flybridge',
  'yacht',
  'darkyacht',
  'superyacht',
  'megayacht',
  'kidsbike',
  'cruiserbike',
  'hunter',
  'adventure',
  'r25',
  'gsx8t',
  'gsxr750',
  'r1',
  'gsxr1000',
  'ninjah2',
  'motorbike',
  'plot',
  'shopspace',
  'apartments',
  'plaza',
};

bool hasPhoto(String id) => _photoIds.contains(id);

/// 16:9 photo, cropped to fill. Collapses if the asset file is missing.
class PhotoBanner extends StatelessWidget {
  const PhotoBanner({super.key, required this.id, this.dimmed = false});

  final String id;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/$id.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          if (dimmed) const ColoredBox(color: Color(0x66000000)),
        ],
      ),
    );
  }
}

/// Small square photo with rounded corners, for list rows. Shows [fallback]
/// when [id] has no photo or the file is missing.
class PhotoThumb extends StatelessWidget {
  const PhotoThumb({
    super.key,
    required this.id,
    required this.fallback,
    this.size = 48,
  });

  final String id;
  final Widget fallback;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!hasPhoto(id)) {
      return fallback;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: SizedBox.square(
        dimension: size,
        child: Image.asset(
          'assets/images/$id.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }
}
