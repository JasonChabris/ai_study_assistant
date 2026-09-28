# AI 智能学习助手（Flutter 多端前端）

基于 Flutter 跨端开发的 AI 智能学习助手，适配 **Web / Android / iOS** 三端。
对接 Java 后端接口与 AI 大模型接口，核心功能：智能答疑、知识点梳理、模拟试题生成、错题本、个性化学习计划、学习工具、数据统计。

## 技术栈

- Flutter 3.10+ / Dart 3.0
- 状态管理：Provider
- 网络请求：dio（已预留，当前用 Mock 数据）
- 本地存储：shared_preferences
- 图表：fl_chart
- 三端编译：web / android / ios

## 项目结构

```
lib/
├── main.dart                  # 入口，注入全局 Provider
├── app.dart                   # MaterialApp + 主题
├── theme/app_theme.dart       # 全局主题（低饱和护眼配色）
├── models/                    # 数据模型
│   ├── user.dart              # 用户
│   ├── chat_message.dart      # AI 对话消息/会话
│   ├── wrong_question.dart    # 错题
│   ├── knowledge_point.dart    # 知识点节点
│   ├── exam.dart              # 模拟试题
│   ├── study_plan.dart        # 学习计划/任务
│   └── vocabulary.dart        # 单词/笔记
├── services/
│   ├── storage_service.dart    # 本地存储封装（SP）
│   └── mock_ai_service.dart    # 模拟 AI/后端接口（替换为真实 HTTP 调用即可）
├── providers/                 # 状态管理
│   ├── auth_provider.dart
│   ├── chat_provider.dart
│   ├── wrong_question_provider.dart
│   ├── plan_provider.dart
│   └── tools_provider.dart
└── pages/                     # 11 个页面
    ├── splash_page.dart        # 启动欢迎页（渐变动画）
    ├── login_page.dart         # 登录注册/验证码/游客模式
    ├── main_navigation.dart     # 底部 4 Tab 导航
    ├── home_page.dart           # 首页（五大功能卡片）
    ├── ai_chat_page.dart        # AI 智能答疑（聊天式）
    ├── knowledge_page.dart      # 知识点梳理（列表/思维导图）
    ├── exam_page.dart           # 模拟试题配置+作答+解析
    ├── wrong_question_page.dart # 错题本（分类/收录/复盘）
    ├── study_plan_page.dart     # 学习计划+打卡日历
    ├── tools_page.dart          # 单词背诵/备忘录/计时器
    ├── statistics_page.dart     # 数据统计（柱状图+饼图）
    └── profile_page.dart        # 个人中心
```

## 运行

```bash
# Web（开发预览）
flutter run -d chrome

# Android
flutter run -d <android-device-id>

# iOS
flutter run -d <ios-device-id>

# 构建
flutter build web          # Web
flutter build apk          # Android
flutter build ios          # iOS
```

## 接入真实后端

当前 `lib/services/mock_ai_service.dart` 用本地模拟数据返回 AI 回复、知识点、试题。
接入真实 Java 后端 + 大模型时，将该文件中的方法替换为 dio HTTP 调用：

```dart
// 示例：将 askQuestion 改为真实接口
Future<String> askQuestion(String question) async {
  final resp = await _dio.post('/api/ai/chat', data: {'question': question});
  return resp.data['reply'];
}
```

建议在 `services/` 下新增 `api_service.dart`，统一管理 baseUrl、拦截器、鉴权 token。

## 已实现的功能对照需求

| 需求模块 | 页面 | 状态 |
|---|---|---|
| 启动欢迎页 | splash_page | ✅ |
| 登录注册/游客 | login_page | ✅ |
| 首页功能卡片 | home_page | ✅ |
| AI 文字答疑/历史记录 | ai_chat_page | ✅ |
| 知识点梳理（列表/思维导图） | knowledge_page | ✅ |
| 模拟试题生成+作答+解析 | exam_page | ✅ |
| 错题本（分类/收录/删除） | wrong_question_page | ✅ |
| 学习计划+打卡 | study_plan_page | ✅ |
| 单词/备忘录/计时器 | tools_page | ✅ |
| 数据统计图表 | statistics_page | ✅ |
| 个人中心/退出 | profile_page | ✅ |
