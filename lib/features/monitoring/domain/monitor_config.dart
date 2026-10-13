class MonitorConfig {
  /// Ambang batas kemiringan (T_high), default 15 derajat (rentang 5 - 40)
  final double tiltToleranceDeg;

  /// Ambang batas pemulihan normal (T_low = T_high / 2)
  double get tiltRecoveryDeg => tiltToleranceDeg / 2.0;

  /// Ambang batas lonjakan z-score percepatan (k)
  final double kZScoreHigh;

  /// Ambang batas pemulihan z-score (k_low)
  final double kZScoreLow;

  /// Jumlah jendela berturut-turut untuk memicu pelanggaran
  final int consecutiveWindows;

  /// Epsilon batas bawah standar deviasi agar tidak terjadi pembagian dengan nol
  final double epsilonStd;

  /// Konstanta waktu low-pass filter (tau ~ 0.1 detik)
  final double lpfTau;

  /// Bobot filter komplementer (beta = 0.98)
  final double compBeta;

  /// Ukuran sliding window (25 sampel = 0.5 detik pada 50 Hz)
  final int windowSize;

  /// Hop size pergeseran jendela (12 sampel)
  final int hopSize;

  /// Maksimal standar deviasi yang diizinkan saat kalibrasi meja diam (m/s^2)
  final double maxCalibrationStd;

  const MonitorConfig({
    this.tiltToleranceDeg = 15.0,
    this.kZScoreHigh = 6.0,
    this.kZScoreLow = 3.0,
    this.consecutiveWindows = 2,
    this.epsilonStd = 0.05,
    this.lpfTau = 0.1,
    this.compBeta = 0.98,
    this.windowSize = 25,
    this.hopSize = 12,
    this.maxCalibrationStd = 0.35,
  });

  MonitorConfig copyWith({
    double? tiltToleranceDeg,
    double? kZScoreHigh,
    double? kZScoreLow,
  }) {
    return MonitorConfig(
      tiltToleranceDeg: tiltToleranceDeg ?? this.tiltToleranceDeg,
      kZScoreHigh: kZScoreHigh ?? this.kZScoreHigh,
      kZScoreLow: kZScoreLow ?? this.kZScoreLow,
      consecutiveWindows: consecutiveWindows,
      epsilonStd: epsilonStd,
      lpfTau: lpfTau,
      compBeta: compBeta,
      windowSize: windowSize,
      hopSize: hopSize,
      maxCalibrationStd: maxCalibrationStd,
    );
  }
}
