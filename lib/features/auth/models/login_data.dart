class LoginData {
  final String email;
  final String password;

  LoginData({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
    );
  }

  @override
  String toString() {
    return 'LoginData{email: $email, password: [HIDDEN]}';
  }
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final UserData user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access'] ?? '',
      refreshToken: json['refresh'] ?? '',
      user: UserData.fromJson(json['user'] ?? {}),
    );
  }
}

class UserData {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String userRole;
  final bool isVerified;
  final String? profilePicture;

  UserData({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.userRole,
    required this.isVerified,
    this.profilePicture,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      userRole: json['user_role'] ?? '',
      isVerified: json['is_verified'] ?? false,
      profilePicture: json['profile_picture'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'user_role': userRole,
      'is_verified': isVerified,
      'profile_picture': profilePicture,
    };
  }

  String get fullName => '$firstName $lastName';

  @override
  String toString() {
    return 'UserData{id: $id, email: $email, fullName: $fullName, userRole: $userRole, isVerified: $isVerified}';
  }
}
