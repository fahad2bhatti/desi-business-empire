import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Icon for each business and property id. Kept in the UI layer so the
/// economy config stays pure data.
IconData iconFor(String id) => switch (id) {
  'samosa' => Icons.bakery_dining,
  'chai' => Icons.local_cafe,
  'chaat' => Icons.shopping_basket,
  'rickshaw' => Icons.electric_rickshaw,
  'kiryana' => Icons.local_grocery_store,
  'mobile' => Icons.phone_android,
  'cloth' => Icons.checkroom,
  'mechanic' => Icons.build,
  'restaurant' => Icons.restaurant,
  'transport' => Icons.local_shipping,
  'hall' => Icons.celebration,
  'factory' => Icons.factory,
  'plot' => Icons.landscape,
  'shopspace' => Icons.storefront,
  'house' => Icons.house,
  'apartments' => Icons.apartment,
  'plaza' => Icons.location_city,
  'farmhouse' => Icons.cottage,
  _ => Icons.business,
};

/// The coloured sign every business and property carries: a rounded tile
/// in its category colour. Dimmed when not owned.
class SignTile extends StatelessWidget {
  const SignTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 52,
    this.dimmed = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final c = dimmed ? context.palette.inkMuted : color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: dimmed ? 0.10 : 0.18),
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: c.withValues(alpha: dimmed ? 0.15 : 0.45)),
      ),
      child: Icon(icon, color: c, size: size * 0.5),
    );
  }
}
