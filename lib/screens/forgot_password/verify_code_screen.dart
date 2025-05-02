import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'reset_password_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String identifier;

  const VerifyCodeScreen({super.key, required this.identifier});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _verificationCodeController = TextEditingController();
  bool _isLoading = false;
  late String _verificationCode;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _generateAndSendVerificationCode();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked');
      },
    );
  }

  Future<void> _generateAndSendVerificationCode() async {
    // Generate a random 6-digit code
    _verificationCode = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    
    // Request notification permissions and ensure they're granted before showing notification
    bool permissionGranted = await _requestNotificationPermissions();
    
    // Add a small delay to ensure the system has fully processed the permission
    if (permissionGranted) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    const androidDetails = AndroidNotificationDetails(
      'password_reset',
      'Password Reset',
      channelDescription: 'Notifications for password reset process',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.show(
      0,
      'رمز التحقق',
      'رمز التحقق الخاص بك هو: $_verificationCode',
      details,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق من الرمز'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'تم إرسال رمز التحقق إلى تطبيقك',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _verificationCodeController,
                  decoration: const InputDecoration(
                    labelText: 'رمز التحقق',
                    prefixIcon: Icon(Icons.security),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال رمز التحقق';
                    }
                    if (value != _verificationCode) {
                      return 'رمز التحقق غير صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _verifyCode,
                        style: ElevatedButton.styleFrom(
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(30),
                          ),
                         ),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Text(
                            'تحقق',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _generateAndSendVerificationCode,
                  child: const Text('إعادة إرسال الرمز'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _verifyCode() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(
            identifier: widget.identifier,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _verificationCodeController.dispose();
    super.dispose();
  }
  
  // Helper method to request notification permissions and return the result
  Future<bool> _requestNotificationPermissions() async {
    // For Android
    final androidPlatform = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlatform != null) {
      final bool? granted = await androidPlatform.requestNotificationsPermission();
      return granted ?? false;
    }
    
    // For iOS
    final iosPlatform = _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlatform != null) {
      final bool? granted = await iosPlatform.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    
    return false;
  }
}