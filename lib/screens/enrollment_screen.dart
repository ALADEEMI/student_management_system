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
  List<Student> _filteredEnrolledStudents = [];
  List<Student> _filteredAvailableStudents = [];
  bool _isLoading = true;
  final TextEditingController _enrolledSearchController = TextEditingController();
  final TextEditingController _availableSearchController = TextEditingController();

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
      
      // Initialize filtered lists
      _filteredEnrolledStudents = List.from(_enrolledStudents);
      _filteredAvailableStudents = List.from(_availableStudents);
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

  void _filterEnrolledStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEnrolledStudents = List.from(_enrolledStudents);
      } else {
        _filteredEnrolledStudents = _enrolledStudents.where((student) {
          return student.name.toLowerCase().contains(query.toLowerCase()) ||
              student.email.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _filterAvailableStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAvailableStudents = List.from(_availableStudents);
      } else {
        _filteredAvailableStudents = _availableStudents.where((student) {
          return student.name.toLowerCase().contains(query.toLowerCase()) ||
              student.email.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _enrollAllStudents() async {
    try {
      for (final student in _availableStudents) {
        final enrollment = Enrollment(
          studentId: student.id!,
          courseId: widget.course.id!,
          enrollmentDate: DateTime.now().toIso8601String(),
        );
        await DatabaseHelper.instance.enrollStudentInCourse(enrollment);
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل جميع الطلاب في الكورس بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error enrolling all students: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تسجيل جميع الطلاب'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeAllEnrollments() async {
    try {
      for (final student in _enrolledStudents) {
        final enrollments = await DatabaseHelper.instance.getEnrollmentsByStudent(student.id!);
        final courseEnrollment = enrollments.firstWhere(
          (e) => e.courseId == widget.course.id,
        );
        await DatabaseHelper.instance.removeEnrollment(courseEnrollment.id!);
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء تسجيل جميع الطلاب من الكورس'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error removing all enrollments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء إلغاء تسجيل جميع الطلاب'),
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
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _enrolledSearchController,
                        decoration: InputDecoration(
                          labelText: 'بحث عن طالب مسجل',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _enrolledSearchController.clear();
                              _filterEnrolledStudents('');
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ),
                        onChanged: _filterEnrolledStudents,
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          _buildStudentsList(
                            _filteredEnrolledStudents,
                            onTap: _removeEnrollment,
                            actionIcon: Icons.remove_circle,
                            actionColor: Colors.red,
                            emptyMessage: 'لا يوجد طلاب مسجلين في هذا الكورس',
                          ),
                          if (_enrolledStudents.isNotEmpty)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: FloatingActionButton(
                                backgroundColor: Colors.red,
                                onPressed: _removeAllEnrollments,
                                child: const Icon(Icons.remove_circle_outline),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Available Students Tab
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _availableSearchController,
                        decoration: InputDecoration(
                          labelText: 'بحث عن طالب متاح',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _availableSearchController.clear();
                              _filterAvailableStudents('');
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ),
                        onChanged: _filterAvailableStudents,
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          _buildStudentsList(
                            _filteredAvailableStudents,
                            onTap: _enrollStudent,
                            actionIcon: Icons.add_circle,
                            actionColor: Colors.green,
                            emptyMessage: 'لا يوجد طلاب متاحين للتسجيل',
                          ),
                          if (_availableStudents.isNotEmpty)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: FloatingActionButton(
                                backgroundColor: Colors.green,
                                onPressed: _enrollAllStudents,
                                child: const Icon(Icons.add_circle_outline),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
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
    _enrolledSearchController.dispose();
    _availableSearchController.dispose();
    super.dispose();
  }
}