import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? zetraId;
  final String? photoUrl;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.zetraId,
    this.photoUrl,
  });

  factory User.fromProfileRow(Map<String, dynamic> row) {
    return User(
      id: row['id'] as String,
      email: row['email'] as String? ?? row['zetramail'] as String? ?? '',
      name: row['full_name'] as String? ?? row['username'] as String?,
      zetraId: row['zetra_id'] as String?,
      photoUrl: row['avatar_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, email, name, zetraId, photoUrl];
}
