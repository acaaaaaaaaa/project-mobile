import '../../../core/utils/platform_util.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Helper untuk membuka pengaturan baterai dan panduan OEM (Xiaomi, Samsung, Oppo, Vivo)
class OemBatteryHelper {
  OemBatteryHelper._();

  /// Membuka halaman pengaturan optimasi baterai sistem Android
  static Future<bool> openBatteryOptimizationSettings() async {
    if (!AppPlatform.isAndroid) return false;
    try {
      return await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Panduan langkah konfigurasi untuk berbagai merk OEM Android
  static List<OemGuide> get oemGuides => const [
        OemGuide(
          brand: 'Xiaomi / Redmi / POCO (MIUI / HyperOS)',
          steps: [
            'Buka Pengaturan > Aplikasi > Kelola Aplikasi > Kerkom.',
            'Aktifkan toggle "Mulai Otomatis" (Autostart).',
            'Pilih "Penghemat Baterai" > ubah ke "Tidak ada pembatasan" (No restrictions).',
            'Kunci Kerkom di layar Recent Apps (tekan lama kartu aplikasi lalu ketuk ikon gembok).',
          ],
        ),
        OemGuide(
          brand: 'Samsung (One UI)',
          steps: [
            'Buka Pengaturan > Aplikasi > Kerkom > Baterai.',
            'Pilih opsi "Tidak dibatasi" (Unrestricted).',
            'Buka Pengaturan > Perawatan Perangkat > Baterai > Batas Penggunaan Latar Belakang.',
            'Pastikan Kerkom tidak ada dalam "Aplikasi yang tidur lelap" (Never sleeping apps).',
          ],
        ),
        OemGuide(
          brand: 'Oppo / Realme (ColorOS / Realme UI)',
          steps: [
            'Buka Pengaturan > Aplikasi > Manajemen Aplikasi > Kerkom > Penggunaan Baterai.',
            'Aktifkan "Izinkan aktivitas latar belakang" (Allow background activity).',
            'Aktifkan "Izinkan mulai otomatis" (Allow auto-launch).',
          ],
        ),
        OemGuide(
          brand: 'Vivo / iQOO (Funtouch OS / OriginOS)',
          steps: [
            'Buka Pengaturan > Baterai > Pengelolaan konsumsi daya di latar belakang.',
            'Cari Kerkom > pilih "Tingginya konsumsi daya di latar belakang diizinkan" (Allow high background power consumption).',
            'Buka Pengaturan > Aplikasi > Kerkom > Izin > Izinkan mulai otomatis.',
          ],
        ),
      ];
}

class OemGuide {
  final String brand;
  final List<String> steps;

  const OemGuide({required this.brand, required this.steps});
}
