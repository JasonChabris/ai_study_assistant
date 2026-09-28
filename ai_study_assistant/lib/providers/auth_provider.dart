import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/storage_service.dart';

/// 认证状态管理
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _initialized = false;

  User? get user => _user;
  bool get isLoggedIn => _user != null && !_user!.isGuest;
  bool get isGuest => _user?.isGuest ?? false;
  bool get initialized => _initialized;

  /// 启动时恢复登录状态
  Future<void> restore() async {
    final token = await StorageService.getToken();
    final userJson = await StorageService.getUserJson();
    if (token != null && userJson != null) {
      _user = User.fromJson(userJson);
    }
    _initialized = true;
    notifyListeners();
  }

  /// 手机号 + 验证码登录（模拟）
  Future<void> login(String phone, {String nickname = ''}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _user = User(
      phone: phone,
      nickname: nickname.isEmpty ? '同学${phone.substring(phone.length - 4)}' : nickname,
      grade: '高中',
    );
    await StorageService.saveToken('mock_token_$phone');
    await StorageService.saveUserJson(_user!.toJson());
    notifyListeners();
  }

  /// 游客模式
  Future<void> loginAsGuest() async {
    _user = User.guest();
    await StorageService.saveToken(null);
    await StorageService.saveUserJson(_user!.toJson());
    notifyListeners();
  }

  /// 更新个人信息
  Future<void> updateProfile({String? nickname, String? grade}) async {
    if (_user == null) return;
    _user = _user!.copyWith(nickname: nickname, grade: grade);
    await StorageService.saveUserJson(_user!.toJson());
    notifyListeners();
  }

  /// 退出登录
  Future<void> logout() async {
    _user = null;
    await StorageService.saveToken(null);
    await StorageService.remove('user');
    notifyListeners();
  }
}
