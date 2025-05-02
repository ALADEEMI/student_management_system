import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static const String _keyUsername = 'username';
  static const String _keyEmail = 'email';
  static const String _keyName = 'name';
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyRememberMe = 'rememberMe';
  static const String _keyKeepMeSignedIn = 'keepMeSignedIn';
  static const String _keyPassword = 'password'; // For Keep Me Signed In functionality
  static const String _keyLastLoginIdentifier = 'lastLoginIdentifier'; // To store the last login identifier (username or email)

  static Future<void> saveUserData(String username, String? email, String name, {bool rememberMe = false, bool keepMeSignedIn = false, String? password, String? loginIdentifier}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    if (email != null) await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyName, name);
    await prefs.setBool(_keyIsLoggedIn, true);
    
    // Save the login identifier that was used (username or email)
    if (loginIdentifier != null) {
      await prefs.setString(_keyLastLoginIdentifier, loginIdentifier);
    }
    
    // Save Remember Me and Keep Me Signed In preferences
    await prefs.setBool(_keyRememberMe, rememberMe);
    await prefs.setBool(_keyKeepMeSignedIn, keepMeSignedIn);
    
    // If Keep Me Signed In is enabled, store the password securely
    // Note: In a production app, you should use a more secure storage solution
    if (keepMeSignedIn && password != null) {
      await prefs.setString(_keyPassword, password);
    } else {
      // Remove password if Keep Me Signed In is disabled
      await prefs.remove(_keyPassword);
    }
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }
  
  static Future<String?> getLastLoginIdentifier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastLoginIdentifier);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    bool keepMeSignedIn = prefs.getBool(_keyKeepMeSignedIn) ?? false;
    bool isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    
    // Only consider the user logged in if Keep Me Signed In is enabled
    return isLoggedIn && keepMeSignedIn;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if Remember Me is enabled before clearing
    bool rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    String? lastLoginIdentifier = rememberMe ? prefs.getString(_keyLastLoginIdentifier) : null;
    
    // Clear all data
    await prefs.clear();
    
    // If Remember Me was enabled, restore just the last login identifier
    if (rememberMe && lastLoginIdentifier != null) {
      await prefs.setString(_keyLastLoginIdentifier, lastLoginIdentifier);
      await prefs.setBool(_keyRememberMe, true);
    }
  }

  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }
  
  static Future<bool> getKeepMeSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyKeepMeSignedIn) ?? false;
  }
  
  static Future<String?> getStoredPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPassword);
  }
  
  static Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, value);
    
    // If Remember Me is disabled, also disable Keep Me Signed In
    if (!value) {
      await prefs.setBool(_keyKeepMeSignedIn, false);
      await prefs.remove(_keyPassword);
    }
  }
  
  static Future<void> setKeepMeSignedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyKeepMeSignedIn, value);
    
    // If Keep Me Signed In is enabled, also enable Remember Me
    if (value) {
      await prefs.setBool(_keyRememberMe, true);
    }
    
    // If Keep Me Signed In is disabled, remove stored password
    if (!value) {
      await prefs.remove(_keyPassword);
    }
  }
}