enum CourseType {
  theory,
  practical,
  theoryAndPractical
}

class Course {
  int? id;
  String title;
  String code;
  String description;
  int creditHours;
  CourseType courseType;

  Course(
      {this.id,
      required this.title,
      required this.code,
      required this.description,
      required this.creditHours,
      required this.courseType});

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      title: map['title'],
      code: map['code'],
      description: map['description'],
      creditHours: map['creditHours'],
      courseType: CourseType.values[map['courseType'] ?? 0],
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'code': code,
      'description': description,
      'creditHours': creditHours,
      'courseType': courseType.index,
    };
  }
}
