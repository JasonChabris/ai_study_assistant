/// 用户模型
class User {
  final String phone;
  final String nickname;
  final String avatarUrl;
  final String grade; // 小学/初中/高中/大学
  final bool isGuest;

  User({
    required this.phone,
    required this.nickname,
    this.avatarUrl = '',
    this.grade = '高中',
    this.isGuest = false,
  });

  factory User.guest() => User(
        phone: '',
        nickname: '游客同学',
        grade: '高中',
        isGuest: true,
      );

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'nickname': nickname,
        'avatarUrl': avatarUrl,
        'grade': grade,
        'isGuest': isGuest,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        phone: json['phone'] ?? '',
        nickname: json['nickname'] ?? '同学',
        avatarUrl: json['avatarUrl'] ?? '',
        grade: json['grade'] ?? '高中',
        isGuest: json['isGuest'] ?? false,
      );

  User copyWith({String? nickname, String? avatarUrl, String? grade}) {
    return User(
      phone: phone,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      grade: grade ?? this.grade,
      isGuest: isGuest,
    );
  }
}
