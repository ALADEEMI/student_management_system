class Enrollment {
  int? id;
  int studentId;
  int courseId;
  String enrollmentDate;

  Enrollment(
      {this.id,
      required this.studentId,
      required this.courseId,
      required this.enrollmentDate});

  factory Enrollment.fromMap(Map<String, dynamic> map) {
    return Enrollment(
      id: map['id'],
      studentId: map['studentId'],
      courseId: map['courseId'],
      enrollmentDate: map['enrollmentDate'],
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'courseId': courseId,
      'enrollmentDate': enrollmentDate,
    };
  }
}
