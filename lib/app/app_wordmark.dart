import 'package:flutter/material.dart';

import 'app_info.dart';
import 'engine_identity.dart';

// PLACEHOLDER: replace with the agreed name and logo. See
// docs/SESSION-NOTES.md, "Decisions awaiting the owner".
/// The app's name as text only: `Saṃsādhanī` in the first engine's colour and
/// `Heritage` in the second's, with a thin dot between. It shrinks to fit a
/// narrow bar and is never cut off.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.size = 20, this.onBar = false});

  /// The font size of the two words.
  final double size;

  /// True on the top bar: the words take two tints that read on the teal bar
  /// instead of the engine colours, which would vanish on it.
  final bool onBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bar = theme.appBarTheme.backgroundColor ?? scheme.primary;
    final (samColor, herColor) = onBar
        ? engineTintsOnBar(scheme, bar)
        : (samsaadhaniiColor(scheme), heritageColor(scheme));
    final dotColor = onBar ? scheme.onPrimary : scheme.onSurfaceVariant;
    final base = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w500,
      letterSpacing: size * 0.04,
    );
    return Semantics(
      label: appDisplayName,
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Saṃsādhanī',
                style: base.copyWith(color: samColor)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size * 0.4),
              child: Text('·',
                  style: base.copyWith(
                      fontWeight: FontWeight.w300,
                      color: dotColor)),
            ),
            Text('Heritage',
                style: base.copyWith(color: herColor)),
          ],
        ),
      ),
    );
  }
}
