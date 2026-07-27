import 'package:firebase_core/firebase_core.dart';

/// Rebotfox'un Windows masaüstü Firebase bağlantısı.
///
/// Windows FlutterFire eklentileri Firebase'in masaüstü C++ SDK'sını kullanır
/// ve yapılandırmanın uygulama tarafından açıkça verilmesini bekler.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAniv9kVInCpa_1BaQ2rhp7mq0TcvYB8NA',
    appId: '1:91320773541:android:5df20908b9c2ab6bff564c',
    messagingSenderId: '91320773541',
    projectId: 'rebotfox-4ab5a',
    authDomain: 'rebotfox-4ab5a.firebaseapp.com',
    storageBucket: 'rebotfox-4ab5a.firebasestorage.app',
  );
}
