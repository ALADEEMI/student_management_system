import 'package:flutter/material.dart';

enum AttendanceStatus {
  present,
  absent,
  excused,
  late,
}

enum AssignmentStatus {
  submitted,
  notSubmitted,
  incomplete,
  noAssignment,
}

class Attendance {
  final int? id;
  final int studentId;
  final int courseId;
  final DateTime date;
  final AttendanceStatus status;
  final AssignmentStatus? assignmentStatus;
  final String? notes;
  final String sessionType;
  final int sessionNumber;

  Attendance({
    this.id,
    required this.studentId,
    required this.courseId,
    required this.date,
    required this.status,
    this.assignmentStatus,
    this.notes,
    required this.sessionType,
    required this.sessionNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'course_id': courseId,
      'date': date.toIso8601String(),
      'status': status.toString().split('.').last,
      'assignment_status': assignmentStatus?.toString().split('.').last,
      'notes': notes,
      'session_type': sessionType,
      'session_number': sessionNumber,
    };
  }

  static Attendance fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      studentId: map['student_id'],
      courseId: map['course_id'],
      date: DateTime.parse(map['date']),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
      ),
      assignmentStatus: map['assignment_status'] != null
          ? AssignmentStatus.values.firstWhere(
              (e) => e.toString().split('.').last == map['assignment_status'],
            )
          : null,
      notes: map['notes'],
      sessionType: map['session_type'],
      sessionNumber: map['session_number'],
    );
  }

  static Color getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.excused:
        return Colors.blue;
      case AttendanceStatus.late:
        return Colors.orange;
    }
  }

  static IconData getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.excused:
        return Icons.assignment_late;
      case AttendanceStatus.late:
        return Icons.access_time;
    }
  }
  
  static Color getAssignmentStatusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.submitted:
        return Colors.green;
      case AssignmentStatus.notSubmitted:
        return Colors.red;
      case AssignmentStatus.incomplete:
        return Colors.amber;
      case AssignmentStatus.noAssignment:
        return Colors.grey;
    }
  }
  
  static IconData getAssignmentStatusIcon(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.submitted:
        return Icons.assignment_turned_in;
      case AssignmentStatus.notSubmitted:
        return Icons.assignment_late;
      case AssignmentStatus.incomplete:
        return Icons.assignment;
      case AssignmentStatus.noAssignment:
        return Icons.block;
    }
  }
}