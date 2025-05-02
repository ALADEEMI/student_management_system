import 'package:flutter/material.dart';
import '../models/course.dart';
import '../utils/database_helper.dart';

class EditCourseScreen extends StatefulWidget {
  final Course course;

  const EditCourseScreen({Key? key, required this.course}) : super(key: key);

  @override
  _EditCourseScreenState createState() => _EditCourseScreenState();
}

class _EditCourseScreenState extends State<EditCourseScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;
  late int _creditHours;
  bool _isLoading = false;
  late CourseType _selectedCourseType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course.title);
    _codeController = TextEditingController(text: widget.course.code);
    _descriptionController = TextEditingController(text: widget.course.description);
    _creditHours = widget.course.creditHours;
    _selectedCourseType = widget.course.courseType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل بيانات الكورس'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان الكورس',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال عنوان الكورس';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'كود الكورس',
                  prefixIcon: Icon(Icons.code),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال كود الكورس';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'وصف الكورس',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نوع الكورس',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile<CourseType>(
                        title: const Text('نظري'),
                        value: CourseType.theory,
                        groupValue: _selectedCourseType,
                        onChanged: (CourseType? value) {
                          setState(() {
                            _selectedCourseType = value!;
                          });
                        },
                      ),
                      RadioListTile<CourseType>(
                        title: const Text('عملي'),
                        value: CourseType.practical,
                        groupValue: _selectedCourseType,
                        onChanged: (CourseType? value) {
                          setState(() {
                            _selectedCourseType = value!;
                          });
                        },
                      ),
                      RadioListTile<CourseType>(
                        title: const Text('نظري وعملي'),
                        value: CourseType.theoryAndPractical,
                        groupValue: _selectedCourseType,
                        onChanged: (CourseType? value) {
                          setState(() {
                            _selectedCourseType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الساعات المعتمدة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('1'),
                          Expanded(
                            child: Slider(
                              value: _creditHours.toDouble(),
                              min: 1,
                              max: 5,
                              divisions: 4,
                              label: _creditHours.toString(),
                              onChanged: (value) {
                                setState(() {
                                  _creditHours = value.toInt();
                                });
                              },
                            ),
                          ),
                          const Text('5'),
                        ],
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '$_creditHours ساعات',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _updateCourse,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'حفظ التغييرات',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateCourse() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedCourse = Course(
          id: widget.course.id,
          title: _titleController.text,
          code: _codeController.text,
          description: _descriptionController.text,
          creditHours: _creditHours,
          courseType: _selectedCourseType,
        );

        await DatabaseHelper.instance.updateCourse(updatedCourse);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث بيانات الكورس بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
