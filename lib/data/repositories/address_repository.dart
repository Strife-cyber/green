import '../models/address.dart';

/// Saved delivery addresses (BUY-08).
abstract class AddressRepository {
  Future<List<Address>> list();
  Future<Address> create(CreateAddressInput input);
  Future<Address> update(String id, CreateAddressInput input);
  Future<void> delete(String id);
  Future<void> setDefault(String id);
}

class CreateAddressInput {
  final String label;
  final String recipientName;
  final String phone;
  final String region;
  final String addressLine;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  const CreateAddressInput({
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.region,
    required this.addressLine,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });
}
