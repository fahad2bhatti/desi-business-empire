import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'photos.dart';
import 'vehicle_art.dart';

/// Icon for each business, property, home and item id. Kept in the UI layer
/// so the economy config stays pure data.
IconData iconFor(String id) => switch (id) {
  'samosa' => Icons.bakery_dining,
  'chai' => Icons.local_cafe,
  'chaat' => Icons.shopping_basket,
  'rickshaw' => Icons.electric_rickshaw,
  'taxi' => Icons.local_taxi,
  'loader' => Icons.local_shipping_outlined,
  'bus' => Icons.directions_bus,
  'rentacar' => Icons.car_rental,
  'transport' => Icons.local_shipping,
  'kiryana' => Icons.local_grocery_store,
  'mobile' => Icons.phone_android,
  'cloth' => Icons.checkroom,
  'mechanic' => Icons.build,
  'restaurant' => Icons.restaurant,
  'hall' => Icons.celebration,
  'factory' => Icons.factory,
  'plot' => Icons.landscape,
  'shopspace' => Icons.storefront,
  'house' => Icons.house,
  'apartments' => Icons.apartment,
  'plaza' => Icons.location_city,
  'farmhouse' => Icons.cottage,
  'room' => Icons.bed,
  'flat' => Icons.apartment,
  'familyhome' => Icons.home,
  'bungalow' => Icons.house_siding,
  'villa' => Icons.villa,
  'mansion' => Icons.castle,
  'motorbike' => Icons.two_wheeler,
  'watch' => Icons.watch,
  'car' => Icons.directions_car,
  'sedan' => Icons.directions_car_filled,
  'jewellery' => Icons.diamond,
  'suv' => Icons.airport_shuttle,
  'cruiser' => Icons.airport_shuttle,
  'luxsuv' => Icons.airport_shuttle,
  'cayenne' => Icons.airport_shuttle,
  'gt3' => Icons.speed,
  'gt2' => Icons.speed,
  'sportscar' => Icons.speed,
  'painting' => Icons.palette,
  'helicopter' => Icons.flight_takeoff,
  'yacht' => Icons.sailing,
  'jet' => Icons.flight,
  'cottage' => Icons.cottage,
  'townhouse' => Icons.home_work,
  'chalet' => Icons.cabin,
  'poolvilla' => Icons.villa,
  'r8' => Icons.speed,
  'gtr' => Icons.speed,
  'airbus' => Icons.flight_takeoff,
  'rescue' => Icons.flight_takeoff,
  'navyheli' => Icons.flight_takeoff,
  'huey' => Icons.flight_takeoff,
  'apache' => Icons.flight_takeoff,
  'chinook' => Icons.flight_takeoff,
  'unitid' => Icons.flight,
  'etihaad' => Icons.flight,
  'kanada' => Icons.flight,
  _ => Icons.business,
};

/// Neutral icon tile every business, property and item carries. Colour
/// lives only in the optional [dot] (the category). Faded when not owned.
class SignTile extends StatelessWidget {
  const SignTile({
    super.key,
    required this.icon,
    this.artId,
    this.dot,
    this.size = 52,
    this.dimmed = false,
  });

  final IconData icon;

  /// When this id has a drawn vehicle, it replaces the glyph.
  final String? artId;
  final Color? dot;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: p.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.tile),
            ),
            clipBehavior: Clip.antiAlias,
            child: artId != null && hasPhoto(artId!)
                ? Image.asset(
                    'assets/images/$artId.jpg',
                    fit: BoxFit.cover,
                    color: dimmed ? const Color(0x66000000) : null,
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (_, _, _) => Icon(icon, color: p.ink),
                  )
                : artId != null && hasVehicleArt(artId!)
                ? Center(
                    child: Opacity(
                      opacity: dimmed ? 0.45 : 1,
                      child: VehicleArt(id: artId!, width: size * 0.84),
                    ),
                  )
                : Icon(
                    icon,
                    color: dimmed ? p.inkMuted : p.ink,
                    size: size * 0.55,
                  ),
          ),
          if (dot != null)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dot,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
