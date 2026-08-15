import 'dart:io' show Platform;

/// Single place to switch product-level features off per platform.
class FeatureFlags {
  FeatureFlags._();

  /// Dose calculators (`/calc`, `/renal-calc`).
  ///
  /// App Store guideline 1.4.2 says drug dosage calculators must come from a
  /// manufacturer, hospital, university, pharmacy or other approved entity.
  /// We ship them because they are teaching aids built on published formulas
  /// and the user must acknowledge that before every use — but if review ever
  /// rejects on 1.4.2, set this to `!Platform.isIOS` and the tools disappear
  /// from iOS entirely (tiles, tools tab and routes) with no other edits.
  static const bool doseToolsEnabled = true;

  /// Kept so the override above is a one-word change.
  static bool get doseToolsOnThisPlatform =>
      doseToolsEnabled || !Platform.isIOS;
}
