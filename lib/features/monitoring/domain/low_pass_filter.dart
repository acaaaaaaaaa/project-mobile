/// Exponential Moving Average (EMA) Low-Pass Filter per sumbu
class LowPassFilter {
  final double tau; // Konstanta waktu (~0.1 s)
  double? _lastOutput;

  LowPassFilter({this.tau = 0.1});

  double? get lastOutput => _lastOutput;

  void reset() {
    _lastOutput = null;
  }

  /// Filter nilai baru dengan interval waktu dt (dalam detik)
  double filter(double input, double dt) {
    if (_lastOutput == null) {
      _lastOutput = input;
      return input;
    }
    final alpha = dt / (tau + dt);
    _lastOutput = _lastOutput! + alpha * (input - _lastOutput!);
    return _lastOutput!;
  }
}

class Vector3LowPassFilter {
  final LowPassFilter fx;
  final LowPassFilter fy;
  final LowPassFilter fz;

  Vector3LowPassFilter({double tau = 0.1})
      : fx = LowPassFilter(tau: tau),
        fy = LowPassFilter(tau: tau),
        fz = LowPassFilter(tau: tau);

  void reset() {
    fx.reset();
    fy.reset();
    fz.reset();
  }

  ({double x, double y, double z}) filter(double x, double y, double z, double dt) {
    return (
      x: fx.filter(x, dt),
      y: fy.filter(y, dt),
      z: fz.filter(z, dt),
    );
  }
}
