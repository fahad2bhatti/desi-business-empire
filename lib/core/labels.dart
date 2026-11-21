import '../domain/economy/command_result.dart';
import '../domain/economy/economy_config.dart';

/// Player-facing names. Kept in one place for the later localization pass.
String roleName(String role) => switch (role) {
      StaffRole.helper => 'Helper (Chhotu)',
      StaffRole.cook => 'Cook (Karigar)',
      StaffRole.manager => 'Manager',
      _ => role,
    };

String roleDescription(String role, StaffDef d, EconomyConfig c) => switch (role) {
      StaffRole.helper => 'Customers khud serve karta hai: ${d.servePerMin} har minute.',
      StaffRole.cook => 'Saman ho to kadhai khud chalata hai. Aap ko "Tal do" nahi dabana parega.',
      StaffRole.manager =>
        'App band ho to dukan chalata hai, ${c.offlineCapMinutes ~/ 60} ghante tak, sirf maujood saman se. '
            'Helper aur Cook bhi zaroori hain.',
      _ => '',
    };

/// "Takeaway Shop par 300 items becho", "Bari Kadhai L2", "Samosa Stall ka Manager".
String describeRequirement(UnmetRequirement u, EconomyConfig c) => switch (u.kind) {
      RequirementKind.sold => '${c.stage(u.target)?.name ?? u.target} par ${u.need} items becho',
      RequirementKind.upgrade => '${c.upgrade(u.target)?.name ?? u.target} L${u.need}',
      RequirementKind.staff =>
        '${c.stage(u.target)?.name ?? u.target} ka ${roleName(u.role ?? '')}',
    };

/// 17.5 -> "17.5", 14.0 -> "14".
String formatNumber(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
