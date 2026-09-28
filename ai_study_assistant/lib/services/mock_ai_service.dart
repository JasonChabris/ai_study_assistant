import '../models/exam.dart';
import '../models/knowledge_point.dart';

/// 模拟 AI 服务层。
/// 实际项目中这里应通过 dio 调用 Java 后端 + 大模型接口；
/// 当前用本地模拟数据保证前端可独立运行演示。
/// 接入真实接口时，将各方法替换为 HTTP 调用即可。
class MockAiService {
  static final MockAiService _instance = MockAiService._();
  factory MockAiService() => _instance;
  MockAiService._();

  /// 模拟网络延迟
  Future<T> _delay<T>(T Function() body, [int ms = 800]) async {
    await Future.delayed(Duration(milliseconds: ms));
    return body();
  }

  /// 发送文字提问，获取 AI 回复
  Future<String> askQuestion(String question) async {
    return _delay(() {
      final q = question.trim();
      if (q.isEmpty) return '请输入你的问题～';
      if (q.contains('作文')) {
        return _essayGrading(q);
      }
      if (q.contains('知识点') || q.contains('讲解') || q.contains('什么是')) {
        return _knowledgeExplain(q);
      }
      return _generalAnswer(q);
    }, 1200);
  }

  String _generalAnswer(String q) {
    return '''关于「$q」，为你梳理如下：

**一、解题思路**
1. 先明确题目考查的核心知识点，定位到对应学科模块；
2. 拆解已知条件与求解目标，找出两者之间的联系；
3. 选择合适的方法/公式建立关系，逐步推导；
4. 代入数值计算，注意单位换算与有效数字。

**二、详细步骤**
- 第一步：审题，圈出关键词与限制条件；
- 第二步：回忆相关定理/公式，列出已知量；
- 第三步：列式求解，化简到最终结果；
- 第四步：检验结果是否合理，是否符合题意。

**三、易错点提醒**
⚠️ 容易忽略题目中的隐含条件；
⚠️ 计算过程中符号、单位容易出错；
⚠️ 最后一步忘记检验，建议反向验证一遍。

**四、知识延伸**
这道题考察的是本章节的核心应用，建议结合同类题再练习 2-3 道，巩固解题套路。如有具体题目，可以拍照发给我，我帮你逐题详解～''';
  }

  String _knowledgeExplain(String q) {
    return '''「$q」通俗讲解：

**核心概念**
把它想象成一个生活中的常见模型，先理解本质，再记定义。

**重点掌握**
1. 定义与内涵：……（结合课本原话理解）
2. 公式/定理：牢记适用条件，不要死记硬背；
3. 典型应用：会判断什么时候用、怎么用。

**记忆技巧**
编成一句话口诀或画成思维导图，比反复阅读效率高很多。

**难点突破**
这块内容的难点在于灵活应用，建议先做基础题，再挑战综合题，循序渐进。''';
  }

  String _essayGrading(String q) {
    return '''作文批改报告：

**评分**：38 / 50（良）

**优点**
- 立意明确，结构完整；
- 部分语句运用了修辞手法，表达生动。

**问题与修改建议**
1. 错别字：注意"的/地/得"的区分；
2. 语病：第3句主谓搭配不当，建议改写；
3. 逻辑：段落之间过渡稍显生硬，可增加过渡句；
4. 建议开头点题、结尾升华，使结构更紧凑。

**修改后范文片段参考**
（此处根据你的作文主题生成一段润色示范……）

继续加油，多写多改会有明显进步！''';
  }

  /// 知识点梳理
  Future<KnowledgeResult> buildKnowledge({
    required String subject,
    required String grade,
    required String keyword,
  }) async {
    return _delay(() {
      final k = keyword.isEmpty ? '核心知识点' : keyword;
      return KnowledgeResult(
        subject: subject,
        grade: grade,
        keyword: k,
        overview:
            '$subject「$k」是$grade阶段的重要内容，本模块围绕其定义、性质、应用三个维度展开，建议结合思维导图系统复习。',
        nodes: [
          KnowledgeNode(
            title: '$k · 基础概念',
            detail: '理解定义、符号表示与基本性质，是后续应用的前提',
            level: '重点',
            children: [
              KnowledgeNode(
                  title: '定义辨析',
                  detail: '注意相近概念的区别与联系',
                  level: '重点'),
              KnowledgeNode(
                  title: '基本性质',
                  detail: '牢记性质成立的前提条件',
                  level: '了解'),
            ],
          ),
          KnowledgeNode(
            title: '$k · 核心公式/定理',
            detail: '掌握推导过程，会正向、逆向使用',
            level: '难点',
            children: [
              KnowledgeNode(
                  title: '公式应用',
                  detail: '明确每个符号含义与单位',
                  level: '难点'),
              KnowledgeNode(
                  title: '常见变形',
                  detail: '掌握 2-3 种常见等价变形',
                  level: '重点'),
            ],
          ),
          KnowledgeNode(
            title: '$k · 典型应用',
            detail: '结合真题体会解题套路',
            level: '重点',
            children: [
              KnowledgeNode(
                  title: '基础题型',
                  detail: '直接套用公式，熟练计算',
                  level: '了解'),
              KnowledgeNode(
                  title: '综合题型',
                  detail: '多知识点交叉，注意分类讨论',
                  level: '难点'),
            ],
          ),
        ],
        mistakes: [
          '忽略公式成立的前提条件',
          '混淆相似概念',
          '计算时单位换算错误',
          '综合题漏解、漏分类讨论',
        ],
        createdAt: DateTime.now(),
      );
    }, 1000);
  }

  /// 生成模拟试题
  Future<List<ExamQuestion>> generateExam(ExamConfig config) async {
    return _delay(() {
      final List<ExamQuestion> result = [];
      final types = config.types.isEmpty ? ['选择'] : config.types;
      for (int i = 0; i < config.count; i++) {
        final type = types[i % types.length];
        result.add(_buildQuestion(i + 1, type, config));
      }
      return result;
    }, 1500);
  }

  ExamQuestion _buildQuestion(int index, String type, ExamConfig config) {
    final subj = config.subject;
    final kRange = config.knowledgeRange.isEmpty ? '核心知识点' : config.knowledgeRange;
    final diff = config.difficulty;

    if (type == '选择') {
      return ExamQuestion(
        id: 'q_$index',
        type: '选择',
        subject: subj,
        stem: '（$subj · $kRange）第$index题：下列关于$kRange的说法，正确的是？',
        options: [
          'A. 该知识点的性质一定适用于所有情况',
          'B. 该知识点需要满足特定前提才能使用',
          'C. 该知识点与其他章节没有关联',
          'D. 以上说法都不正确',
        ],
        answer: 'B',
        analysis: '本题考查$kRange的适用条件。任何公式/定理都有成立的前提，只有在满足前提时才能使用，故选 B。',
        difficulty: diff,
        knowledge: kRange,
      );
    } else if (type == '填空') {
      return ExamQuestion(
      id: 'q_$index',
      type: '填空',
      subject: subj,
      stem: '（$subj · $kRange）第$index题：在$kRange相关计算中，需特别注意______的统一与检验。',
      options: const [],
      answer: '单位',
      analysis: '此类填空题考查细节，单位统一是避免低级错误的关键，填"单位"。',
      difficulty: diff,
      knowledge: kRange,
    );
    } else if (type == '计算') {
      return ExamQuestion(
      id: 'q_$index',
      type: '计算',
      subject: subj,
      stem: '（$subj · $kRange）第$index题：已知相关条件，试运用$kRange求解最终结果（写出完整过程）。',
      options: const [],
      answer: '第一步列式；第二步代入；第三步化简；第四步检验。最终结果需结合题意给出。',
      analysis: '计算题按步骤给分，务必写出公式、代入、化简、检验四步，注意书写规范。',
      difficulty: diff,
      knowledge: kRange,
    );
    } else {
      return ExamQuestion(
      id: 'q_$index',
      type: '简答',
      subject: subj,
      stem: '（$subj · $kRange）第$index题：请简述$kRange的主要内容及其在实际中的应用。',
      options: const [],
      answer: '应包含：定义/原理、关键性质、1-2 个典型应用场景、注意事项。',
      analysis: '简答题按要点给分，建议分点作答，逻辑清晰，先总后分。',
      difficulty: diff,
      knowledge: kRange,
    );
    }
  }

  /// 生成每日学习计划
  Future<List<String>> generatePlanWeakPoints() async {
    return _delay(() => [
          '函数单调性判断',
          '文言文实词推断',
          '英语时态语态',
          '物理受力分析',
        ], 600);
  }
}
