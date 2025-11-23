class UserProfile {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final int? phone;
  final String? dob;
  final String? country;
  final String? city;
  final int? zip;
  final String? address;
  final String? profilePic;

  UserProfile({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.dob,
    this.country,
    this.city,
    this.zip,
    this.address,
    this.profilePic,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      dob: json['dob'],
      country: json['country'],
      city: json['city'],
      zip: json['zip'],
      address: json['address'],
      profilePic: json['profilePic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'dob': dob,
      'country': country,
      'city': city,
      'zip': zip,
      'address': address,
      'profilePic': profilePic,
    };
  }
}
