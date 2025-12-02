class Question {
  final int id;
  final QuestionMaterial? material;
  final QuestionUser asker;
  final String questionText;
  final String answerText;
  final QuestionUser? answeredBy;
  final DateTime? answeredAt;
  final String status; // 'open', 'answered', 'closed'
  final int helpfulCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Question({
    required this.id,
    this.material,
    required this.asker,
    required this.questionText,
    required this.answerText,
    this.answeredBy,
    this.answeredAt,
    required this.status,
    required this.helpfulCount,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAnswered => status == 'answered';
  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';
  bool get hasAnswer => answerText.isNotEmpty;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? 0,
      material: json['material'] != null
          ? QuestionMaterial.fromJson(json['material'])
          : null,
      asker: QuestionUser.fromJson(json['asker_info'] ?? json['asker']),
      questionText: json['question_text'] ?? '',
      answerText: json['answer_text'] ?? '',
      answeredBy: json['answerer_info'] != null
          ? QuestionUser.fromJson(json['answerer_info'])
          : (json['answered_by'] != null
              ? QuestionUser.fromJson(json['answered_by'])
              : null),
      answeredAt: json['answered_at'] != null
          ? DateTime.parse(json['answered_at'])
          : null,
      status: json['status'] ?? 'open',
      helpfulCount: json['helpful_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'material': material?.toJson(),
      'asker': asker.toJson(),
      'question_text': questionText,
      'answer_text': answerText,
      'answered_by': answeredBy?.toJson(),
      'answered_at': answeredAt?.toIso8601String(),
      'status': status,
      'helpful_count': helpfulCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class QuestionMaterial {
  final int id;
  final String title;
  final String? description;
  final String? coverImageUrl;

  QuestionMaterial({
    required this.id,
    required this.title,
    this.description,
    this.coverImageUrl,
  });

  factory QuestionMaterial.fromJson(Map<String, dynamic> json) {
    return QuestionMaterial(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      coverImageUrl: json['cover_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cover_image_url': coverImageUrl,
    };
  }
}

class QuestionUser {
  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? profilePictureUrl;

  QuestionUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.profilePictureUrl,
  });

  String get fullName => '$firstName $lastName';

  factory QuestionUser.fromJson(Map<String, dynamic> json) {
    // Handle both formats: full_name or first_name/last_name
    String firstName = '';
    String lastName = '';

    if (json['full_name'] != null) {
      final nameParts = (json['full_name'] as String).split(' ');
      firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    } else {
      firstName = json['first_name'] ?? '';
      lastName = json['last_name'] ?? '';
    }

    return QuestionUser(
      id: json['id'] ?? 0,
      firstName: firstName,
      lastName: lastName,
      email: json['email'],
      profilePictureUrl: json['avatar_url'] ?? json['profile_picture_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'profile_picture_url': profilePictureUrl,
    };
  }
}

class QuestionStats {
  final int total;
  final int open;
  final int answered;
  final int closed;
  final double avgHelpfulCount;

  QuestionStats({
    required this.total,
    required this.open,
    required this.answered,
    required this.closed,
    required this.avgHelpfulCount,
  });

  factory QuestionStats.fromJson(Map<String, dynamic> json) {
    return QuestionStats(
      total: json['total'] ?? 0,
      open: json['open'] ?? 0,
      answered: json['answered'] ?? 0,
      closed: json['closed'] ?? 0,
      avgHelpfulCount: (json['avg_helpful_count'] ?? 0).toDouble(),
    );
  }
}
