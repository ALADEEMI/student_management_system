import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/student.dart';
import '../models/enrollment.dart';
import '../utils/database_helper.dart';

class EnrollmentScreen extends StatefulWidget {
  final Course course;

  const EnrollmentScreen({Key? key, required this.course}) : super(key: key);

  @override
  _EnrollmentScreenState createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  List<Student> _allStudents = [];
  List<Student> _enrolledStudents = [];
  List<Student> _availableStudents = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load all students
      _allStudents = await DatabaseHelper.instance.getAllStudents();
      
      // Load enrolled students
      final enrolledStudentsMap = await DatabaseHelper.instance.getCourseStudents(widget.course.id!);
      _enrolledStudents = enrolledStudentsMap.map((map) => Student(
        id: map['id'],
        name: map['name'],
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
        address: map['address'] ?? '',
      )).toList();

      // Calculate available students
      _availableStudents = _allStudents.where((student) =>
        !_enrolledStudents.any((enrolled) => enrolled.id == student.id)
      ).toList();
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _enrollStudent(Student student) async {
    try {
      final enrollment = Enrollment(
        studentId: student.id!,
        courseId: widget.course.id!,
        enrollmentDate: DateTime.now().toIso8601String(),
      );
      await DatabaseHelper.instance.enrollStudentInCourse(enrollment);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل الطالب في الكورس بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error enrolling student: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تسجيل الطالب'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeEnrollment(Student student) async {
    try {
      final enrollments = await DatabaseHelper.instance.getEnrollmentsByStudent(student.id!);
      final courseEnrollment = enrollments.firstWhere(
        (e) => e.courseId == widget.course.id,
      );
      await DatabaseHelper.instance.removeEnrollment(courseEnrollment.id!);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء تسجيل الطالب من الكورس'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error removing enrollment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء إلغاء تسجيل الطالب'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('إدارة التسجيل - ${widget.course.title}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الطلاب المسجلين'),
              Tab(text: 'الطلاب المتاحين'),
            ],
          ),
        ),
        body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              children: [
                // Enrolled Students Tab
                _buildStudentsList(
                  _enrolledStudents,
                  onTap: _removeEnrollment,
                  actionIcon: Icons.remove_circle,
                  actionColor: Colors.red,
                  emptyMessage: 'لا يوجد طلاب مسجلين في هذا الكورس',
                ),
                // Available Students Tab
                _buildStudentsList(
                  _availableStudents,
                  onTap: _enrollStudent,
                  actionIcon: Icons.add_circle,
                  actionColor: Colors.green,
                  emptyMessage: 'لا يوجد طلاب متاحين للتسجيل',
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildStudentsList(
    List<Student> students, {
    required Function(Student) onTap,
    required IconData actionIcon,
    required Color actionColor,
    required String emptyMessage,
  }) {
    if (students.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                student.name[0].toUpperCase(),
                style: TextStyle(color: Colors.blue.shade800),
              ),
            ),
            title: Text(student.name),
            subtitle: Text(student.email),
            trailing: IconButton(
              icon: Icon(actionIcon, color: actionColor),
              onPressed: () => onTap(student),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}