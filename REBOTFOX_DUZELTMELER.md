# Rebotfox düzeltme paketi

Bu paket yüklenen FlutterFlow kaynak kodu üzerinde yapılan güvenli düzeltmeleri içerir.

## Düzeltilenler

- Tamir talebi sayfa açılır açılmaz boş Firestore belgesi oluşturuyordu; kaldırıldı.
- Gönder butonunda çift tıklama koruması ve yükleme durumu eklendi.
- Ad, telefon, marka, model ve sorun açıklaması için doğrulama eklendi.
- Başarılı/başarısız kayıt bildirimleri eklendi.
- Açılış ekranındaki boş ağ görselleri ve internet bağımlı Lottie kaldırıldı.
- Açılış ekranı responsive hâle getirildi ve otomatik ana sayfa yönlendirmesi eklendi.
- Türkçe yerel ayar (`tr-TR`) ve Material 3 etkinleştirildi.
- Firestore kuralları, tüm kayıtların herkese açık okunmasını engelleyecek şekilde sıkılaştırıldı.

## Önemli

Ekran görüntüsünde görülen `step_indicator_widget.dart` dosyası bu ZIP içinde bulunmuyor. Bu nedenle o 9 hata bu paketteki kaynak koddan üretilemiyor. FlutterFlow'dan hata görülen en güncel sürümü tekrar dışa aktarırsanız ilgili component doğrudan düzeltilebilir.

## Çalıştırma

```bash
flutter pub get
flutter analyze
flutter run
```

APK:

```bash
flutter build apk --release
```

## Firebase

`firebase/firestore.rules` dosyasını Firebase Console üzerinden yayınlamadan yeni kurallar aktif olmaz.
Mevcut uygulamada kullanıcı doğrulaması ve admin rol sistemi bulunmadığı için admin paneli güvenli biçimde Firestore güncellemesi yapacak şekilde açılamadı. Bunun için Firebase Authentication ve rol tabanlı kurallar eklenmelidir.
