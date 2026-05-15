enum AppMode {
  collector,
  farmerClaim,
}

class AppConfig {
  // Mode flag: switch to test farmer claim
  static const AppMode currentMode = AppMode.collector;

  // ML & Camera Quality Gates
  static const double yoloConfidenceThreshold = 0.55;
  static const double minBrightness = 30.0;
  static const double maxBrightness = 200.0;

  static const List<String> shotSequence = [
    'S01_FRONT',
    'S02_FRONT_L',
    'S03_FRONT_R',
    'S04_HEAD_L',
    'S05_HEAD_R',
    'S06_EARTAG',
    'VID',
  ];
}
