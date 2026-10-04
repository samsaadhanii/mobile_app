import 'package:flutter/material.dart';

/// The two engines' identity colours, defined once so every screen that needs
/// to tell them apart uses the same pair. They come from the colour scheme
/// (primary and tertiary), so they meet 4.5 to 1 on the surface in light and
/// dark.
Color samsaadhaniiColor(ColorScheme scheme) => scheme.primary;

Color heritageColor(ColorScheme scheme) => scheme.tertiary;
