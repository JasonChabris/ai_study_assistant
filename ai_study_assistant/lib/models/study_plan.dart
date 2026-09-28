/// 学习计划任务
class StudyTask {
  final String id;
  final String title;
  final String subject;
  final String type; // 刷题/知识点复习/背诵
  final int estimatedMinutes;
  bool completed;

  StudyTask({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.estimatedMinutes,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'type': type,
        'estimatedMinutes': estimatedMinutes,
        'completed': completed,
      };

  factory StudyTask.fromJson(Map<String, dynamic> json) => StudyTask(
        id: json['id'],
        title: json['title'] ?? '',
        subject: json['subject'] ?? '数学',
        type: json['type'] ?? '刷题',
        estimatedMinutes: json['estimatedMinutes'] ?? 30,
        completed: json['completed'] ?? false,
      );
}

/// 每日学习计划
class DailyPlan {
  final String date; // YYYY-MM-DD
  final List<StudyTask> tasks;
  final List<String> weakPoints;

  DailyPlan({
    required this.date,
    required this.tasks,
    required this.weakPoints,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'weakPoints': weakPoints,
      };

  factory DailyPlan.fromJson(Map<String, dynamic> json) => DailyPlan(
        date: json['date'] ?? '',
        tasks: (json['tasks'] as List?)
                ?.map((t) => StudyTask.fromJson(t))
                .toList() ??
            [],
        weakPoints: (json['weakPoints'] as List?)?.cast<String>() ?? [],
      );
}
