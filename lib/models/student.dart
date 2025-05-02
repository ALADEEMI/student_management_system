class Student {
  int? id;
  String name;
  String email;
  String phone;
  String address;

  Student(
      {this.id,
      required this.name,
      required this.email,
      required this.phone,
      required this.address});

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      address: map['address'],
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
    };
  }
}
