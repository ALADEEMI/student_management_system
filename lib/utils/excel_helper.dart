import 'dart:io';
import 'package:excel/excel.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../utils/database_helper.dart';

class ImportError {
  final int rowNumber;
  final String reason;

  ImportError(this.rowNumber, this.reason);
}

class ImportResult<T> {
  final List<T> successfulImports;
  final List<ImportError> failedImports;
  final int totalRows;

  ImportResult(this.successfulImports, this.failedImports, this.totalRows);

  int get skippedRows => failedImports.length;

  String get summary => "${successfulImports.length} records imported successfully. ${failedImports.length} rows failed due to errors.";
}

class ExcelHelper {
  /// Validate student data based on form validation rules
  static String? _validateStudentData(String name, String email, String phone, String address) {
    // Name validation: Arabic or English letters only
    if (name.isEmpty || !RegExp(r'^[\u0600-\u06FF\s]+$|^[a-zA-Z\s]+$').hasMatch(name)) {
      return 'Invalid name format';
    }

    // Email validation
    if (email.isEmpty || !RegExp(r'^[a-zA-Z0-9_.+-~*&$#%^]+@[a-zA-Z0-9-]+\.(org|gov|edu|mil|int|com)+$').hasMatch(email)) {
      return 'Invalid email format';
    }

    // Phone validation: Yemeni phone number format
    if (phone.isEmpty || !RegExp(r'^(71|73|70|77|78)[0-9]{7}$').hasMatch(phone)) {
      return 'Invalid phone number format';
    }

    // Address validation
    if (address.isEmpty) {
      return 'Address cannot be empty';
    }

    return null;
  }

  /// Import students from an Excel file with validation
  static Future<ImportResult<Student>> importStudentsFromExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final students = <Student>[];
    final existingEmails = <String>{};
    final existingPhones = <String>{};

    int skippedRows = 0;

    // Get the first sheet
    final sheet = excel.tables.keys.first;
    final rows = excel.tables[sheet]!.rows;
    final totalRows = rows.length - 1; // Excluding header row

    final failedImports = <ImportError>[];
    // Skip header row
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      
      // Check if row has data
      if (row.isEmpty || row[0]?.value == null) {
        failedImports.add(ImportError(i, 'Empty row'));
        continue;
      }

      // Extract student data
      final name = row[0]?.value?.toString() ?? '';
      final email = row.length > 1 ? row[1]?.value?.toString() ?? '' : '';
      final phone = row.length > 2 ? row[2]?.value?.toString() ?? '' : '';
      final address = row.length > 3 ? row[3]?.value?.toString() ?? '' : '';

      // Validate student data
      final validationError = _validateStudentData(name, email, phone, address);
      if (validationError == null) {
        // Check for duplicate email
        if (await DatabaseHelper.instance.isStudentEmailExists(email) || existingEmails.contains(email)) {
          failedImports.add(ImportError(i, 'البريد الإلكتروني مستخدم بالفعل'));
          continue;
        }
        
        if (await DatabaseHelper.instance.isStudentPhoneExists(phone) || existingPhones.contains(phone)) {
          failedImports.add(ImportError(i, 'رقم الهاتف مستخدم بالفعل'));
          continue;
        }


        students.add(Student(
          name: name,
          email: email,
          phone: phone,
          address: address,
        ));

        existingEmails.add(email);
        existingPhones.add(phone);
      } else {
        failedImports.add(ImportError(i, validationError));
      }
    }

    return ImportResult(students, failedImports, totalRows);
  }

  /// Validate course data based on form validation rules
  static String? _validateCourseData(String title, String code, String description, int creditHours, int courseType) {
    // Title validation
    if (title.isEmpty) {
      return 'Title cannot be empty';
    }

    // Code validation
    if (code.isEmpty) {
      return 'Code cannot be empty';
    }

    // Credit hours validation (1-5)
    if (creditHours < 1 || creditHours > 5) {
      return 'Credit hours must be between 1 and 5';
    }

    // Course type validation (0-2)
    if (courseType < 0 || courseType > 2) {
      return 'Invalid course type';
    }

    return null;
  }

  /// Import courses from an Excel file with validation
  static Future<ImportResult<Course>> importCoursesFromExcel(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final courses = <Course>[];
    final existingCourses = <String>{};
    int skippedRows = 0;

    // Get the first sheet
    final sheet = excel.tables.keys.first;
    final rows = excel.tables[sheet]!.rows;
    final totalRows = rows.length - 1; // Excluding header row

    final failedImports = <ImportError>[];
    // Skip header row
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      
      // Check if row has data
      if (row.isEmpty || row[0]?.value == null) {
        failedImports.add(ImportError(i, 'Empty row'));
        continue;
      }

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
        failedImports.add(ImportError(i, 'Invalid credit hours format'));
        continue;
      }
      
      int courseTypeInt = 0;
      try {
        courseTypeInt = int.parse(courseTypeStr);
      } catch (e) {
        failedImports.add(ImportError(i, 'Invalid course type format'));
        continue;
      }

      // Validate course data
      final validationError = _validateCourseData(title, code, description, creditHours, courseTypeInt);
      if (validationError == null) {
        // Check for duplicate course title
        if (await DatabaseHelper.instance.isCourseExists(title) || existingCourses.contains(title)) {
          failedImports.add(ImportError(i, 'هذا الكورس موجود بالفعل'));
          continue;
        }

        courses.add(Course(
          title: title,
          code: code,
          description: description,
          creditHours: creditHours,
          courseType: CourseType.values[courseTypeInt],
        ));
        existingCourses.add(title);
      } else {
        failedImports.add(ImportError(i, validationError));
      }
    }

    return ImportResult(courses, failedImports, totalRows);
  }
}