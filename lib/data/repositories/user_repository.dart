import '../models/user.dart';

/// Own profile update (AUTH-01, DEL-04).
abstract class UserRepository {
  Future<User> updateProfile(UpdateProfileInput input);
}

class UpdateProfileInput {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? region;
  final double? latitude;
  final double? longitude;

  const UpdateProfileInput({
    this.firstName,
    this.lastName,
    this.phone,
    this.region,
    this.latitude,
    this.longitude,
  });
}
