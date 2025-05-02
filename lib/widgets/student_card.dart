// lib/widgets/student_card.dart
import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../utils/database_helper.dart';

class StudentCard extends StatelessWidget {
  final Student student;
  final Function onDelete;
  final Function onEdit;
  final Function onViewCourses;
  final int index; // Added index parameter for sequential numbering

  const StudentCard({
    Key? key,
    required this.student,
    required this.onDelete,
    required this.onEdit,
    required this.onViewCourses,
    required this.index, // Added required index parameter
  }) : super(key: key);

  Future<void> _showAttendanceHistory(BuildContext context) async {
    final courses = await DatabaseHelper.instance.getStudentCourses(student.id!);
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    Row(
                      children: [
                        const Text(
                          'سجل الحضور للكورسات',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${courses.length}',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                const SizedBox(height: 16),
                Expanded(
                  child: courses.isEmpty
                    ? const Center(child: Text('لا يوجد كورسات مسجلة'))
                    : ListView.builder(
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return Card(
                            child: ListTile(
                              title: Text(course['title']),
                              subtitle: Text('الكود: ${course["code"]}'),
                              onTap: () => _showCourseAttendance(context, course['id'], course['title']),
                            ),
                          );
                        },
                      ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<void> _showCourseAttendance(BuildContext context, int courseId, String courseTitle) async {
    final attendanceRecords = await DatabaseHelper.instance.getStudentAttendance(student.id!, courseId);
    final attendanceCount = attendanceRecords.length;
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'سجل الحضور لكورس $courseTitle',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$attendanceCount',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: attendanceRecords.isEmpty
                    ? const Center(child: Text('لم يتم تسجيل الحضور بعد'))
                    : ListView.builder(
                        itemCount: attendanceRecords.length,
                        itemBuilder: (context, index) {
                          final record = Attendance.fromMap(attendanceRecords[index]);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Attendance.getStatusColor(record.status),
                                child: Icon(
                                  Attendance.getStatusIcon(record.status),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(record.date.toString().split(' ')[0]),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${record.sessionType} ${record.sessionNumber}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    record.status.toString().split('.').last.toUpperCase(),
                                    style: TextStyle(
                                      color: Attendance.getStatusColor(record.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (record.notes?.isNotEmpty ?? false)
                                    Text('ملاحظات: ${record.notes}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<void> _showAssignmentHistory(BuildContext context) async {
    final courses = await DatabaseHelper.instance.getStudentCourses(student.id!);
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'سجل الواجبات للكورسات',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${courses.length}',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: courses.isEmpty
                    ? const Center(child: Text('لا يوجد كورسات مسجلة'))
                    : ListView.builder(
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return Card(
                            child: ListTile(
                              title: Text(course['title']),
                              subtitle: Text('الكود: ${course["code"]}'),
                              onTap: () => _showCourseAssignments(context, course['id'], course['title']),
                            ),
                          );
                        },
                      ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<void> _showCourseAssignments(BuildContext context, int courseId, String courseTitle) async {
    final attendanceRecords = await DatabaseHelper.instance.getStudentAttendance(student.id!, courseId);
    final assignmentRecords = attendanceRecords.where((record) => record['assignment_status'] != null).toList();
    final assignmentCount = assignmentRecords.length;
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'سجل الواجبات لكورس $courseTitle',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$assignmentCount',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: assignmentRecords.isEmpty
                    ? const Center(child: Text('لم يتم تسجيل واجبات بعد'))
                    : ListView.builder(
                        itemCount: assignmentRecords.length,
                        itemBuilder: (context, index) {
                          final record = Attendance.fromMap(assignmentRecords[index]);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Attendance.getAssignmentStatusColor(record.assignmentStatus!),
                                child: Icon(
                                  Attendance.getAssignmentStatusIcon(record.assignmentStatus!),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(record.date.toString().split(' ')[0]),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${record.sessionType} ${record.sessionNumber}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    record.assignmentStatus.toString().split('.').last.toUpperCase(),
                                    style: TextStyle(
                                      color: Attendance.getAssignmentStatusColor(record.assignmentStatus!),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (record.notes?.isNotEmpty ?? false)
                                    Text('ملاحظات: ${record.notes}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${student.name}',
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.assignment, color: Colors.orange),
                      onPressed: () => _showAssignmentHistory(context),
                      tooltip: 'سجل الواجبات',
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.blue),
                      onPressed: () => _showAttendanceHistory(context),
                      tooltip: 'سجل الحضور',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => onEdit(student),
                      tooltip: 'تعديل',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => onDelete(student.id),
                      tooltip: 'حذف',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('الرقم: ${index + 1}'), // Changed to use index + 1 instead of student.id
            Text('البريد الإلكتروني: ${student.email}'),
            // Text('الهاتف: ${student.phone}'),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.book),
                  label: const Text('عرض الكورسات'),
                  onPressed: () => onViewCourses(student),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
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
