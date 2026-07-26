# Rebotfox Saf Flutter UI

Bu proje FlutterFlow kodundan bağımsız, saf Flutter ile hazırlanmış çalışan bir Rebotfox uygulama arayüzüdür.

## Çalıştırma

```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

## APK

Android Studio ve Android SDK kurulu olduktan sonra:

```powershell
flutter build apk --release
```

APK: `build/app/outputs/flutter-apk/app-release.apk`

## Demo takip bilgisi

- Takip kodu: `RFX-20260725-483921`
- Telefon: `05551234567`

## Kapsam

- Responsive profesyonel ana sayfa
- Fiyat hesaplama
- Tamir talebi oluşturma
- Otomatik takip kodu
- Cihaz takip ve zaman çizelgesi
- Profil ekranı
- Admin dashboard ve durum güncelleme

Bu sürüm local/mock veriyle çalışır. Firebase entegrasyonu ayrı aşamada eklenmelidir.
