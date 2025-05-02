import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/course.dart';
import '../utils/database_helper.dart';
import '../utils/excel_helper.dart';
import '../widgets/course_card.dart';
import 'add_course_screen.dart';
import 'edit_course_screen.dart';
import 'enrollment_screen.dart';
import 'attendance_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({Key? key}) : super(key: key);

  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Course> _courses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _courses = await DatabaseHelper.instance.getAllCourses();
      _filteredCourses = List.from(_courses);
    } catch (e) {
      print('Error loading courses: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterCourses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCourses = List.from(_courses);
      } else {
        _filteredCourses = _courses.where((course) {
          return course.title.toLowerCase().contains(query.toLowerCase()) ||
              course.code.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _addCourse() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCourseScreen()),
    );
    if (result == true) {
      _loadCourses();
    }
  }

  void _editCourse(Course course) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCourseScreen(course: course),
      ),
    );
    if (result == true) {
      _loadCourses();
    }
  }

  void _manageAttendance(Course course) async {
    // Check for completed sessions
    final completedSessions = await DatabaseHelper.instance.getCompletedSessions(course.id!);
    final allSessions = <String>[];
    
    switch (course.courseType) {
      case CourseType.theory:
        allSessions.addAll(List.generate(12, (i) => 'Lecture ${i + 1}'));
        break;
      case CourseType.practical:
        allSessions.addAll(List.generate(12, (i) => 'Lab ${i + 1}'));
        break;
      case CourseType.theoryAndPractical:
        allSessions.addAll(List.generate(12, (i) => 'Lecture ${i + 1}'));
        allSessions.addAll(List.generate(12, (i) => 'Lab ${i + 1}'));
        break;
    }

    final completedSessionStrings = completedSessions.map((session) =>
      '${session['session_type']} ${session['session_number']}'
    ).toList();

    // Check if all sessions are completed
    if (completedSessionStrings.length >= allSessions.length) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('اكتمال الحضور'),
            content: const Text('تم تسجيل الحضور لجميع الجلسات في هذا المقرر'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // If not all sessions are completed, navigate to attendance screen
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AttendanceScreen(course: course),
        ),
      );
    }
  }

  void _deleteCourse(Course course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف الكورس ${course.title}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteCourse(course.id!);
      _loadCourses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الكورس بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showCourseDetails(Course course, int index) async {
    final students = await DatabaseHelper.instance.getCourseStudents(course.id!);

    if (mounted) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.orange.shade100,
                    child: Text(
                      course.code.substring(0, min(2, course.code.length)),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('رقم: ${index + 1}', style: const TextStyle(color: Colors.grey)),
                        Text('كود: ${course.code}', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildInfoRow(Icons.description, 'الوصف', course.description.isNotEmpty ? course.description : 'لا يوجد وصف'),
              _buildInfoRow(Icons.timer, 'الساعات المعتمدة', '${course.creditHours} ساعات'),
              _buildInfoRow(Icons.type_specimen, ' نوع الكورس', '${getCourseTypeInArabic(course.courseType)} '),
              const Divider(height: 32),
              Row(
                children: [
                  const Icon(Icons.people, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('الطلاب المسجلين',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${students.length}',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (students.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('لا يوجد طلاب مسجلين في هذا الكورس')),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            student['name'].toString().isNotEmpty
                                ? student['name'].toString()[0].toUpperCase()
                                : '?',
                            style: TextStyle(color: Colors.blue.shade800),
                          ),
                        ),
                        title: Text(student['name']),
                        subtitle: Text(student['email'] ?? ''),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;

  Future<void> _importCourses() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final courses = await ExcelHelper.importCoursesFromExcel(file);

        setState(() => _isLoading = true);

        for (final course in courses) {
          await DatabaseHelper.instance.createCourse(course);
        }

        await _loadCourses();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم استيراد ${courses.length} كورس بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء استيراد الكورسات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الكورسات')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'بحث عن كورس',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterCourses('');
                  },
                ),
              ),
              onChanged: _filterCourses,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCourses.isEmpty
                    ? const Center(child: Text('لا توجد كورسات', style: TextStyle(fontSize: 18)))
                    : RefreshIndicator(
                        onRefresh: _loadCourses,
                        child: ListView.builder(
                          itemCount: _filteredCourses.length,
                          itemBuilder: (context, index) {
                            final course = _filteredCourses[index];
                            return CourseCard(
                              course: course,
                              onEdit: _editCourse,
                              onDelete: (id) => _deleteCourse(course),
                              onViewStudents: _showCourseDetails,
                              onManageEnrollments: (course) => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EnrollmentScreen(course: course),
                                ),
                              ),
                              onManageAttendance: _manageAttendance,
                              index: index, // Added index parameter to pass the position in the list
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.green,
            onPressed: _importCourses,
            heroTag: 'import_courses',
            child: const Icon(Icons.upload_file, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _addCourse,
            heroTag: 'add_course',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
