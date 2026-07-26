# Rebotfox düzeltmeleri v2

- Flutter 3.44 ile uyumsuz font_awesome_flutter 10.7.0, 10.12.0 sürümüne yükseltildi.
- page_transition 2.1.0, 2.2.2 sürümüne yükseltildi.
- CreateRepairRequest sayfasına eksik /index.dart importu eklendi.
- RepairRowWidget içindeki tanımsız statusColor ve status erişimleri repairDoc alanına bağlandı.
- RepairRowWidget repairDoc parametresi demo satırlarının derlenebilmesi için opsiyonel yapıldı.
- Hatalı takip/müşteri metni düzeltildi.

Komutlar:
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome
