import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final String? phoneNumber;
  final bool isVerified;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.phoneNumber,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [id, email, name, photoUrl, phoneNumber, isVerified];
}

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.photoUrl,
    super.phoneNumber,
    super.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      photoUrl: json['photoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'isVerified': isVerified,
    };
  }
}
