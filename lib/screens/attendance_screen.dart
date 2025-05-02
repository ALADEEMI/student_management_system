import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/course.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../utils/database_helper.dart';

class AttendanceScreen extends StatefulWidget {
  final Course course;

  const AttendanceScreen({super.key, required this.course});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Student> _students = [];
  bool _isLoading = true;
  final Map<int, AttendanceStatus> _attendanceStatus = {};
  final Map<int, AssignmentStatus> _assignmentStatus = {};
  final Map<int, TextEditingController> _notesControllers = {};
  final Map<int, FocusNode> _notesFocusNodes = {};
  int _currentStudentIndex = 0;
  String _selectedSession = '';
  List<String> _sessions = [];
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  Map<AttendanceStatus, int> _attendanceProgress = {
    AttendanceStatus.present: 0,
    AttendanceStatus.absent: 0,
    AttendanceStatus.late: 0,
    AttendanceStatus.excused: 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _initializeSessions();
  }

  Future<void> _initializeSessions() async {
    List<String> allSessions = [];
    switch (widget.course.courseType) {
      case CourseType.theory:
        allSessions = List.generate(12, (i) => 'Lecture ${i + 1}');
        break;
      case CourseType.practical:
        allSessions = List.generate(12, (i) => 'Lab ${i + 1}');
        break;
      case CourseType.theoryAndPractical:
        allSessions = [
          ...List.generate(12, (i) => 'Lecture ${i + 1}'),
          ...List.generate(12, (i) => 'Lab ${i + 1}'),
        ];
        break;
    }

    // Get completed sessions from database
    final completedSessions = await DatabaseHelper.instance.getCompletedSessions(widget.course.id!);
    final completedSessionStrings = completedSessions.map((session) =>
      '${session['session_type']} ${session['session_number']}'
    ).toList();

    // Filter out completed sessions
    _sessions = allSessions.where((session) => !completedSessionStrings.contains(session)).toList();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      final enrolledStudentsMap = await DatabaseHelper.instance.getCourseStudents(widget.course.id!);

      _students = enrolledStudentsMap.map((map) => Student(
        id: map['id'],
        name: map['name'],
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
        address: map['address'] ?? '',
      )).toList();

      for (var student in _students) {
        _notesControllers[student.id!] = TextEditingController();
        _notesFocusNodes[student.id!] = FocusNode()
          ..addListener(() {
            if (_notesFocusNodes[student.id!]!.hasFocus) {
              Future.delayed(const Duration(milliseconds: 300), () {
                Scrollable.ensureVisible(
                  context,
                  alignment: 0.5,
                  duration: const Duration(milliseconds: 300),
                );
              });
            }
          });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ في تحميل بيانات الطلاب')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateAttendanceProgress() {
    setState(() {
      _attendanceProgress = {
        AttendanceStatus.present: 0,
        AttendanceStatus.absent: 0,
        AttendanceStatus.late: 0,
        AttendanceStatus.excused: 0,
      };

      for (var status in _attendanceStatus.values) {
        _attendanceProgress[status] = (_attendanceProgress[status] ?? 0) + 1;
      }
    });
  }

  void _nextStudent() {
    if (_currentStudentIndex < _students.length - 1) {
      setState(() => _currentStudentIndex++);
    }
  }

  void _previousStudent() {
    if (_currentStudentIndex > 0) {
      setState(() => _currentStudentIndex--);
    }
  }

  void _onDateSelected(DateTime? picked) {
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<String?> _checkDuplicateAttendance(String sessionType, int sessionNumber) async {
    final existingAttendance = await DatabaseHelper.instance.getAttendanceForCourseSession(
      widget.course.id!,
      sessionType,
      sessionNumber,
    );
    
    if (existingAttendance.isNotEmpty) {
      final firstRecord = existingAttendance.first;
      final date = DateTime.parse(firstRecord['date']);
      return DateFormat('yyyy-MM-dd').format(date);
    }
    return null;
  }

  Future<void> _saveAttendance() async {
    if (_selectedSession.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الرجاء تحديد الجلسة أولاً'),
          duration: const Duration(milliseconds: 800),
        ),
      );
      return;
    }

    final parts = _selectedSession.split(' ');
    final sessionType = parts[0];
    final sessionNumber = int.parse(parts[1]);

    final existingDate = await _checkDuplicateAttendance(sessionType, sessionNumber);
    if (existingDate != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل الحضور لهذه الجلسة ($sessionType $sessionNumber) بتاريخ $existingDate مسبقاً!'),
          duration: const Duration(milliseconds: 800),
        ),
      );
      return;
    }

    final missingStudents = _students.where(
      (student) => !_attendanceStatus.containsKey(student.id!) 
    ).toList();

    if (missingStudents.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('هناك ${missingStudents.length} طالب لم يتم تحديد حالة حضورهم'),
          backgroundColor: Colors.orange,
          duration: const Duration(milliseconds: 800),
        ),
      );
      return;
    }
    
    final missingAssignmentStudents = _students.where(
      (student) => !_assignmentStatus.containsKey(student.id!) 
    ).toList();

    if (missingAssignmentStudents.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('هناك ${missingAssignmentStudents.length} طالب لم يتم تحديد حالة تسليم الواجب'),
          backgroundColor: Colors.orange,
          duration: const Duration(milliseconds: 800),
        ),
      );
      return;
    }

    try {
      for (var student in _students) {
        final attendance = Attendance(
          studentId: student.id!,
          courseId: widget.course.id!,
          date: _selectedDate,
          status: _attendanceStatus[student.id!]!,
          assignmentStatus: _assignmentStatus[student.id!],
          notes: _notesControllers[student.id!]!.text.trim(),
          sessionType: sessionType,
          sessionNumber: sessionNumber,
        );
        await DatabaseHelper.instance.saveAttendance(attendance);
      }

      _updateAttendanceProgress();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ بيانات الحضور بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء حفظ الحضور: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var controller in _notesControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _notesFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Widget _buildNavigationButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ElevatedButton(
            onPressed: _currentStudentIndex > 0 ? _previousStudent : null,
            child: const Text('الطالب السابق'),
          ),
          Text('${_currentStudentIndex + 1} / ${_students.length}'),
          ElevatedButton(
            onPressed: _currentStudentIndex < _students.length - 1 ? _nextStudent : null,
            child: const Text('الطالب التالي'),
          ),
        ],
      );

  Widget _buildAttendanceStatusButton(int studentId, AttendanceStatus status) {
    final isSelected = _attendanceStatus[studentId] == status;
    final hasSelection = _attendanceStatus.containsKey(studentId);

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Attendance.getStatusColor(status)
            : (hasSelection ? Colors.grey.shade200 : Colors.orange.shade100),
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: hasSelection ? BorderSide.none : const BorderSide(color: Colors.orange, width: 2),
        ),
      ),
      onPressed: () {
        setState(() => _attendanceStatus[studentId] = status);
        _updateAttendanceProgress();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Attendance.getStatusIcon(status), size: 18),
          const SizedBox(width: 4),
          Text(status.toString().split('.').last.toUpperCase()),
        ],
      ),
    );
  }
  
  Widget _buildAssignmentStatusButton(int studentId, AssignmentStatus status) {
    final isSelected = _assignmentStatus[studentId] == status;
    final hasSelection = _assignmentStatus.containsKey(studentId);
    
    String label;
    switch (status) {
      case AssignmentStatus.submitted:
        label = 'تم التسليم';
        break;
      case AssignmentStatus.notSubmitted:
        label = 'لم يتم التسليم';
        break;
      case AssignmentStatus.incomplete:
        label = 'غير مكتمل';
        break;
      case AssignmentStatus.noAssignment:
        label = 'لا يوجد واجب';
        break;
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Attendance.getAssignmentStatusColor(status)
            : (hasSelection ? Colors.grey.shade200 : Colors.orange.shade100),
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: hasSelection ? BorderSide.none : const BorderSide(color: Colors.orange, width: 2),
        ),
      ),
      onPressed: () {
        setState(() => _assignmentStatus[studentId] = status);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Attendance.getAssignmentStatusIcon(status), size: 18),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildAttendanceProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('حالة الحضور', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: AttendanceStatus.values.map((status) {
              final count = _attendanceProgress[status] ?? 0;
              return Column(
                children: [
                  Radio<AttendanceStatus>(
                    value: status,
                    groupValue: null,
                    onChanged: (AttendanceStatus? value) {
                      if (value != null) {
                        setState(() {
                          for (var student in _students) {
                            _attendanceStatus[student.id!] = value;
                          }
                          _updateAttendanceProgress();
                        });
                      }
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Attendance.getStatusColor(status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(status.toString().split('.').last.toUpperCase()),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentProgress() {
    final assignmentProgress = {
      AssignmentStatus.submitted: 0,
      AssignmentStatus.notSubmitted: 0,
      AssignmentStatus.incomplete: 0,
      AssignmentStatus.noAssignment: 0,
    };

    for (var status in _assignmentStatus.values) {
      assignmentProgress[status] = (assignmentProgress[status] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('حالة الواجبات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: AssignmentStatus.values.map((status) {
              final count = assignmentProgress[status] ?? 0;
              String label;
              switch (status) {
                case AssignmentStatus.submitted:
                  label = 'تم التسليم';
                  break;
                case AssignmentStatus.notSubmitted:
                  label = 'لم يتم التسليم';
                  break;
                case AssignmentStatus.incomplete:
                  label = 'غير مكتمل';
                  break;
                case AssignmentStatus.noAssignment:
                  label = 'لا يوجد واجب';
                  break;
              }
              return Column(
                children: [
                  Radio<AssignmentStatus>(
                    value: status,
                    groupValue: null,
                    onChanged: (AssignmentStatus? value) {
                      if (value != null) {
                        setState(() {
                          for (var student in _students) {
                            _assignmentStatus[student.id!] = value;
                          }
                        });
                      }
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Attendance.getAssignmentStatusColor(status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentAttendanceCard(Student student, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    student.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('رقم الطالب: ${index + 1}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 50,
              runSpacing: 25,
              children: AttendanceStatus.values
                  .map((status) => _buildAttendanceStatusButton(student.id!, status))
                  .toList(),
            ),
            if (!_attendanceStatus.containsKey(student.id!))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'الرجاء تحديد حالة الحضور',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // Assignment Status Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الواجبات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: AssignmentStatus.values.map((status) => 
                    _buildAssignmentStatusButton(student.id!, status)
                  ).toList(),
                ),
                if (!_assignmentStatus.containsKey(student.id!))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'الرجاء تحديد حالة تسليم الواجب',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _notesControllers[student.id!],
              focusNode: _notesFocusNodes[student.id!],
              decoration: InputDecoration(
                hintText: 'إضافة ملاحظات (اختياري)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المادة المحددة', style: TextStyle(color: Colors.grey.shade600)),
              TextButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('حفظ البيانات'),
                onPressed: _saveAttendance,
                style: TextButton.styleFrom(foregroundColor: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.book, color: Colors.blue.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.course.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(widget.course.code, style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSessionDropdown()),
              const SizedBox(width: 16),
              Expanded(child: _buildDatePicker()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('المحاضرة / الجلسة', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedSession.isEmpty ? null : _selectedSession,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: const Text('اختر الجلسة...'),
          items: _sessions.map((session) {
            return DropdownMenuItem<String>(
              value: session,
              child: Text(session),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedSession = value ?? ''),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('التاريخ', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            _onDateSelected(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                const Icon(Icons.calendar_today, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نظام إدارة الحضور'),
        actions: [],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 50,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _students.isEmpty
                        ? const Center(child: Text('لا يوجد طلاب مسجلين في هذه المادة'))
                        : Column(
                            children: [
                              _buildTopPanel(),
                              const Divider(height: 3),
                              _buildAttendanceProgress(),
                              const Divider(height: 3),
                              _buildAssignmentProgress(),
                              const Divider(height: 3),
                              const SizedBox(height: 4),
                              _buildNavigationButtons(),
                              Expanded(
                                child: _buildStudentAttendanceCard(
                                    _students[_currentStudentIndex],
                                    _currentStudentIndex),
                              ),
                            ],
                          ),
              ),
            ),
          );
        },
      ),
    );
  }
}