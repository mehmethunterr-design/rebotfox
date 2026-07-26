# Rebotfox Marka Entegrasyonu v2

Bu sürümde:

- Minimal yuvarlak Rebotfox logosu uygulamaya eklendi.
- Animasyonlu Flutter splash ekranı eklendi.
- Android native açılış görseli güncellendi.
- Android launcher ikonları güncellendi.
- iOS AppIcon ve LaunchImage dosyaları güncellendi.
- Web favicon ve PWA ikonları güncellendi.
- Ana sayfa üst marka alanı gerçek logo ile değiştirildi.
- Tema ve mevcut işlevsel ekranlar korundu.

## Çalıştırma

```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

## Android APK

```powershell
flutter build apk --release
```

Bir sonraki aşama Firebase Core, Authentication, Firestore ve Storage bağlantısıdır.
