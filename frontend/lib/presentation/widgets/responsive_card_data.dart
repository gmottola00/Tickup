import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Enum per distinguere il tipo di card
enum CardType { pool, prize }

/// Classe unificata per gestire la responsività delle card
class ResponsiveCardData {
  final double cardWidth;
  final double imageHeight;
  final double minCardHeight;
  final double padding;
  final double spacing;
  final double borderRadius;
  final TextStyle? titleStyle;
  final TextStyle? bodyTextStyle;
  final double buttonSize;
  final double buttonHeight;

  const ResponsiveCardData({
    required this.cardWidth,
    required this.imageHeight,
    required this.minCardHeight,
    required this.padding,
    required this.spacing,
    required this.borderRadius,
    this.titleStyle,
    this.bodyTextStyle,
    required this.buttonSize,
    required this.buttonHeight,
  });
}

/// Classe per definire i breakpoints responsivi
class _BreakpointData {
  final double maxCardWidth;
  final double aspectRatio;
  final double padding;
  final double spacing;
  final double borderRadius;
  final double buttonSize;
  final double buttonHeight;

  const _BreakpointData({
    required this.maxCardWidth,
    required this.aspectRatio,
    required this.padding,
    required this.spacing,
    required this.borderRadius,
    required this.buttonSize,
    required this.buttonHeight,
  });
}

/// Calcola le dimensioni responsive per le card
ResponsiveCardData calculateResponsiveCardDimensions({
  required double screenWidth,
  required double screenHeight,
  required double availableWidth,
  required double availableHeight,
  required CardType cardType,
}) {
  // Breakpoints responsivi unificati
  late final _BreakpointData breakpointData;

  if (screenWidth >= 1200) {
    // Desktop large
    breakpointData = _BreakpointData(
      maxCardWidth: 400,
      aspectRatio: cardType == CardType.pool ? 0.9 : 0.6,
      padding: 16,
      spacing: 14,
      borderRadius: 16,
      buttonSize: 24,
      buttonHeight: 40,
    );
  } else if (screenWidth >= 992) {
    // Desktop
    breakpointData = _BreakpointData(
      maxCardWidth: 360,
      aspectRatio: cardType == CardType.pool ? 0.85 : 0.58,
      padding: 14,
      spacing: 12,
      borderRadius: 14,
      buttonSize: 22,
      buttonHeight: 38,
    );
  } else if (screenWidth >= 768) {
    // Tablet
    breakpointData = _BreakpointData(
      maxCardWidth: 320,
      aspectRatio: cardType == CardType.pool ? 0.82 : 0.56,
      padding: 12,
      spacing: 10,
      borderRadius: 12,
      buttonSize: 20,
      buttonHeight: 36,
    );
  } else if (screenWidth >= 480) {
    // Mobile large
    breakpointData = _BreakpointData(
      maxCardWidth: double.infinity,
      aspectRatio: cardType == CardType.pool ? 0.78 : 0.54,
      padding: 12,
      spacing: 10,
      borderRadius: 12,
      buttonSize: 20,
      buttonHeight: 36,
    );
  } else {
    // Mobile small
    breakpointData = _BreakpointData(
      maxCardWidth: double.infinity,
      aspectRatio: cardType == CardType.pool ? 1 : 0.52,
      padding: 6,
      spacing: 6,
      borderRadius: 10,
      buttonSize: 18,
      buttonHeight: 34,
    );
  }

  // Calcola larghezza della card
  final cardWidth = breakpointData.maxCardWidth == double.infinity
      ? availableWidth - (breakpointData.padding * 2)
      : math.min(availableWidth - (breakpointData.padding * 2),
          breakpointData.maxCardWidth);

  // Calcola altezza dell'immagine basata sulla larghezza e aspect ratio
  final baseImageHeight = cardWidth * breakpointData.aspectRatio;
  final maxImageHeightRatio = cardType == CardType.pool ? 0.6 : 0.35;
  final maxImageHeight = availableHeight * maxImageHeightRatio;
  final imageHeight = math.min(baseImageHeight, maxImageHeight);

  // Calcola altezza minima della card
  final estimatedContentHeight = cardType == CardType.pool
      ? imageHeight + (breakpointData.spacing * 5) + 140
      : imageHeight +
          (breakpointData.spacing * 6) +
          breakpointData.buttonHeight * 2 +
          80;

  final desiredCardHeight =
      cardType == CardType.pool ? imageHeight / 0.6 : imageHeight / 0.5;

  final maxCardHeightRatio = cardType == CardType.pool ? 0.95 : 0.9;
  final minCardHeight = math.min(
    math.max(estimatedContentHeight, desiredCardHeight),
    availableHeight * maxCardHeightRatio,
  );

  // Calcola stili di testo responsive (opzionali, possono essere null per usare i default del tema)
  TextStyle? titleStyle;
  TextStyle? bodyTextStyle;

  if (screenWidth <= 480) {
    // Mobile: testo più piccolo
    titleStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
    bodyTextStyle = const TextStyle(fontSize: 12);
  } else if (screenWidth <= 768) {
    // Tablet: testo medio
    titleStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    bodyTextStyle = const TextStyle(fontSize: 13);
  }
  // Desktop: usa i default del tema (null)

  return ResponsiveCardData(
    cardWidth: cardWidth,
    imageHeight: imageHeight,
    minCardHeight: minCardHeight,
    padding: breakpointData.padding,
    spacing: breakpointData.spacing,
    borderRadius: breakpointData.borderRadius,
    titleStyle: titleStyle,
    bodyTextStyle: bodyTextStyle,
    buttonSize: breakpointData.buttonSize,
    buttonHeight: breakpointData.buttonHeight,
  );
}
