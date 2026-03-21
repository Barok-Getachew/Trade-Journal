class DailyReview {
  final String id;
  final String userId;
  final String accountId;
  final DateTime reviewDate;
  final String? emotionalState;
  final String? mistakesMade;
  final String? wentWell;
  final int planAdherence; // 1–10
  final int disciplineScore; // 1–10
  final String? equityScreenshotUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyReview({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.reviewDate,
    this.emotionalState,
    this.mistakesMade,
    this.wentWell,
    this.planAdherence = 5,
    this.disciplineScore = 5,
    this.equityScreenshotUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyReview.fromMap(Map<String, dynamic> map) => DailyReview(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        accountId: map['account_id'] as String,
        reviewDate: DateTime.parse(map['review_date'] as String),
        emotionalState: map['emotional_state'] as String?,
        mistakesMade: map['mistakes_made'] as String?,
        wentWell: map['went_well'] as String?,
        planAdherence: map['plan_adherence'] as int? ?? 5,
        disciplineScore: map['discipline_score'] as int? ?? 5,
        equityScreenshotUrl: map['equity_screenshot_url'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'account_id': accountId,
        'review_date': reviewDate.toIso8601String().substring(0, 10),
        'emotional_state': emotionalState,
        'mistakes_made': mistakesMade,
        'went_well': wentWell,
        'plan_adherence': planAdherence,
        'discipline_score': disciplineScore,
        'equity_screenshot_url': equityScreenshotUrl,
      };

  DailyReview copyWith({
    String? id,
    String? userId,
    String? accountId,
    DateTime? reviewDate,
    String? emotionalState,
    String? mistakesMade,
    String? wentWell,
    int? planAdherence,
    int? disciplineScore,
    String? equityScreenshotUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      DailyReview(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        accountId: accountId ?? this.accountId,
        reviewDate: reviewDate ?? this.reviewDate,
        emotionalState: emotionalState ?? this.emotionalState,
        mistakesMade: mistakesMade ?? this.mistakesMade,
        wentWell: wentWell ?? this.wentWell,
        planAdherence: planAdherence ?? this.planAdherence,
        disciplineScore: disciplineScore ?? this.disciplineScore,
        equityScreenshotUrl: equityScreenshotUrl ?? this.equityScreenshotUrl,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
