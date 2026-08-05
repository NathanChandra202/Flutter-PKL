import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🧪 Testing Flutter Secure Storage...');

  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  try {
    // Test write
    print('📝 Writing test token...');
    await storage.write(key: 'test_token', value: 'test123');

    // Test read
    print('📖 Reading test token...');
    String? readToken = await storage.read(key: 'test_token');
    print('Read token: $readToken');

    // Test delete
    print('🗑️ Deleting test token...');
    await storage.delete(key: 'test_token');

    // Test read after delete
    print('📖 Reading after delete...');
    String? deletedToken = await storage.read(key: 'test_token');
    print('Token after delete: $deletedToken');

    if (readToken == 'test123' && deletedToken == null) {
      print('✅ Secure storage working correctly!');
    } else {
      print('❌ Secure storage not working properly');
    }
  } catch (e) {
    print('❌ Secure storage test failed: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Storage Test',
      home: Scaffold(
        appBar: AppBar(title: Text('Storage Test')),
        body: Center(child: Text('Check console for test results')),
      ),
    );
  }
}
