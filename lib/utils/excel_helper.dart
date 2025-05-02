import 'dart:io';
import 'package:excel/excel.dart';
import '../models/student.dart';
import '../models/course.dart';

class ExcelHelper {
  /// Import students from an Excel file
  static Future<List<Student>> importStudentsFromExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final students = <Student>[];

    // Get the first sheet
    final sheet = excel.tables.keys.first;
    final rows = excel.tables[sheet]!.rows;

    // Skip header row
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      
      // Check if row has data
      if (row.isEmpty || row[0]?.value == null) continue;

      // Extract student data
      final name = row[0]?.value?.toString() ?? '';
      final email = row.length > 1 ? row[1]?.value?.toString() ?? '' : '';
      final phone = row.length > 2 ? row[2]?.value?.toString() ?? '' : '';
      final address = row.length > 3 ? row[3]?.value?.toString() ?? '' : '';

      // Create student object
      if (name.isNotEmpty) {
        students.add(Student(
          name: name,
          email: email,
          phone: phone,
          address: address,
        ));
      }
    }

    return students;
  }

  /// Import courses from an Excel file
  static Future<List<Course>> importCoursesFromExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final courses = <Course>[];

    // Get the first sheet
    final sheet = excel.tables.keys.first;
    final rows = excel.tables[sheet]!.rows;

    // Skip header row
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      
      // Check if row has data
      if (row.isEmpty || row[0]?.value == null) continue;

      // Extract course data
      final title = row[0]?.value?.toString() ?? '';
      final code = row.length > 1 ? row[1]?.value?.toString() ?? '' : '';
      final description = row.length > 2 ? row[2]?.value?.toString() ?? '' : '';
      final creditHoursStr = row.length > 3 ? row[3]?.value?.toString() ?? '2' : '2';
      final courseTypeStr = row.length > 4 ? row[4]?.value?.toString() ?? '0' : '0';
      
      // Parse numeric values
      int creditHours = 2;
      try {
        creditHours = int.parse(creditHoursStr);
      } catch (e) {
        // Default to 3 if parsing fails
      }
      
      int courseTypeInt = 0;
      try {
        courseTypeInt = int.parse(courseTypeStr);
      } catch (e) {
        // Default to 0 (theory) if parsing fails
      }
      
      // Ensure courseType is valid
      final courseType = CourseType.values[courseTypeInt.clamp(0, CourseType.values.length - 1)];

      // Create course object
      if (title.isNotEmpty && code.isNotEmpty) {
        courses.add(Course(
          title: title,
          code: code,
          description: description,
          creditHours: creditHours,
          courseType: courseType,
        ));
      }
    }

    return courses;
  }
}