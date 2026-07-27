# Rebotfox Windows sürümü

Bu proje Windows 10/11 x64 üzerinde çalışan Flutter masaüstü uygulaması olarak
derlenebilir.

## Yerel derleme

Windows bilgisayarda Visual Studio'nun **Desktop development with C++** iş yükü
ve Flutter kurulu olmalıdır.

```powershell
flutter config --enable-windows-desktop
flutter create --platforms=windows --org com.rebotfox --project-name rebotfox .
flutter pub get
flutter analyze
flutter test
flutter build windows --release
```

Çalıştırılabilir dosya:

```text
build\windows\x64\runner\Release\rebotfox.exe
```

`rebotfox.exe` tek başına taşınmamalıdır. `Release` klasöründeki DLL ve `data`
klasörüyle birlikte kullanılmalıdır. GitHub Actions iş akışı bunların tamamını
`Rebotfox-Windows-x64.zip` içinde paketler.

## Windows uyumluluğu

- Firebase Core, Authentication, Firestore ve Storage Windows yapılandırması
  eklendi.
- Fotoğraf ekranında Windows için kamera seçeneği gizlenir; dosya seçici açılır.
- GitHub Actions derlemesi Rebotfox uygulama ikonunu Windows simgesine dönüştürür.
- Android yapılandırması ve APK derleme akışı korunur.
