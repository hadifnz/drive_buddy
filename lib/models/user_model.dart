import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 2) // We use ID 2 (Car was 0, TripSession was 1)
class User extends HiveObject {
  @HiveField(0)
  late String username;

  @HiveField(1)
  late String password; // In a real app, hash this! For thesis, plain text is okay.

  @HiveField(2)
  late String fullName;

  @HiveField(3)
  late String email;

  @HiveField(4)
  late String phone;

  User({
    required this.username,
    required this.password,
    required this.fullName,
    required this.email,
    required this.phone,
  });
}