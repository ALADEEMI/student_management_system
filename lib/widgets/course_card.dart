// lib/widgets/course_card.dart
import 'package:flutter/material.dart';
import '../models/course.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final Function onDelete;
  final Function onEdit;
  final Function onViewStudents;
  final Function onManageEnrollments;
  final Function onManageAttendance;
  final int index; // Added index parameter for sequential numbering

  const CourseCard({
    Key? key,
    required this.course,
    required this.onDelete,
    required this.onEdit,
    required this.onViewStudents,
    required this.onManageEnrollments,
    required this.onManageAttendance,
    required this.index, // Added required index parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${course.title}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.indigo),
                      onPressed: () => onManageAttendance(course),
                      tooltip: 'إدارة الحضور',
                    ),
                    IconButton(
                      icon: const Icon(Icons.people, color: Colors.green),
                      onPressed: () => onManageEnrollments(course),
                      tooltip: 'إدارة التسجيل',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => onEdit(course),
                      tooltip: 'تعديل',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => onDelete(course.id),
                      tooltip: 'حذف',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('الرقم: ${index + 1}'),
            Text('الكود: ${course.code}'),
            // Text('الوصف: ${course.description}'),
            // Text('الساعات المعتمدة: ${course.creditHours} ساعة'),
            // Text('نوع الكورس: ${getCourseTypeInArabic(course.courseType)}'),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.people),
                  label: const Text('عرض الطلاب المسجلين'),
                  onPressed: () => onViewStudents(course, index),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

  String getCourseTypeInArabic(CourseType type) {
    switch (type) {
      case CourseType.theory:
        return 'نظري';
      case CourseType.practical:
        return 'عملي';
      case CourseType.theoryAndPractical:
        return 'نظري وعملي';
    }
  }
