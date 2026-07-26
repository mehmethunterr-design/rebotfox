# Rebotfox Firebase Android bağlantısı

Bu sürümde Android Firebase yapılandırması eklendi.

## Eklenen / doğrulanan ayarlar

- Firebase proje kimliği: `rebotfox-4ab5a`
- Android paket adı: `com.mycompany.rebotfox`
- `android/app/google-services.json` mevcut
- Google Services Gradle eklentisi etkin
- `firebase_core`, `cloud_firestore`, `firebase_auth` ve `firebase_storage` paketleri mevcut
- `main.dart` uygulama açılmadan önce Firebase'i başlatıyor

## Çalıştırma

Bu sürümü Android telefon veya Android emülatöründe çalıştırın:

```powershell
flutter clean
flutter pub get
flutter run
```

Chrome çalıştırması için ayrıca Firebase Web uygulaması oluşturulmalı ve Web yapılandırması eklenmelidir.

## Test

Uygulama açılır ve terminalde `FirebaseException` görünmezse temel Android bağlantısı tamamdır.
