import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/attendance.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('SSSTUdentt_management.db');
    await _createAttendanceTable(_database!);
    return _database!;
  }

  Future<void> _createAttendanceTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        course_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        assignment_status TEXT,
        notes TEXT,
        session_type TEXT NOT NULL,
        session_number INTEGER NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE,
        FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        email TEXT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        code TEXT NOT NULL,
        description TEXT,
        creditHours INTEGER,
        courseType INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE enrollments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER,
        courseId INTEGER,
        enrollmentDate TEXT,
        FOREIGN KEY (studentId) REFERENCES students (id) ON DELETE CASCADE,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');
  }

  // User operations
  Future<bool> isUsernameExists(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty;
  }

  Future<bool> isEmailExists(String? email) async {
    if (email == null || email.isEmpty) return false;
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  Future<int> createUser(String username, String password, String? email, String name) async {
    final db = await database;
    
    // Check if username already exists
    if (await isUsernameExists(username)) {
      throw Exception('اسم المستخدم موجود بالفعل');
    }

    // Check if email already exists
    if (await isEmailExists(email)) {
      throw Exception('البريد الإلكتروني موجود بالفعل');
    }

    final data = {
      'username': username,
      'password': password,
      'email': email,
      'name': name
    };
    return await db.insert('users', data);
  }

  Future<Map<String, dynamic>?> validateUser(String identifier, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: '(username = ? OR email = ?) AND password = ?',
      whereArgs: [identifier, identifier, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Student operations
  Future<int> createStudent(Student student) async {
    final db = await database;
    return await db.insert('students', student.toMap());
  }

  Future<int> updateStudent(Student student) async {
    final db = await database;
    return await db.update(
      'students',
      student.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    
    // Begin transaction to ensure all operations complete or none do
    await db.transaction((txn) async {
      // Delete attendance records for this student
      await txn.delete(
        'attendance',
        where: 'student_id = ?',
        whereArgs: [id],
      );
      // Delete enrollment records for this student
      await txn.delete(
        'enrollments',
        where: 'studentId = ?',
        whereArgs: [id],
      );
    });
    // Delete the student record
    return await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Student>> getAllStudents() async {
    final db = await database;
    final result = await db.query('students');
    return result.map((json) => Student.fromMap(json)).toList();
  }

  Future<Student?> getStudent(int id) async {
    final db = await database;
    final maps = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    }
    return null;
  }

  // Course operations
  Future<int> createCourse(Course course) async {
    final db = await database;
    return await db.insert('courses', course.toMap());
  }

  Future<List<Map<String, dynamic>>> getCompletedSessions(int courseId) async {
    final db = await database;
    return await db.query(
      'attendance',
      columns: ['session_type', 'session_number'],
      where: 'course_id = ?',
      whereArgs: [courseId],
      distinct: true,
      orderBy: 'session_type ASC, session_number ASC'
    );
  }

  Future<int> updateCourse(Course course) async {
    final db = await database;
    return await db.update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future<int> deleteCourse(int id) async {
    final db = await database;
    
    // Begin transaction to ensure all operations complete or none do
    await db.transaction((txn) async {
      // Delete attendance records for this course
      await txn.delete(
        'attendance',
        where: 'course_id = ?',
        whereArgs: [id],
      );
      
      // Delete enrollment records for this course
      await txn.delete(
        'enrollments',
        where: 'courseId = ?',
        whereArgs: [id],
      );
    });
    
    // Delete the course record
    return await db.delete(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> saveAttendance(Attendance attendance) async {
    final db = await database;
    return await db.insert('attendance', attendance.toMap());
  }
Future<List<Map<String, dynamic>>> getAttendanceForCourseSession(
  int courseId,
  String sessionType,
  int sessionNumber,
) async {
  final db = await database;
  return await db.query(
    'attendance',
    where: '''
      course_id = ? 
      AND session_type = ? 
      AND session_number = ?
    ''',
    whereArgs: [
      courseId,
      sessionType,
      sessionNumber,
    ],
  );
}

  Future<List<Map<String, dynamic>>> getAttendanceForCourse(int courseId, String date) async {
    final db = await database;
    return await db.query(
      'attendance',
      where: 'course_id = ? AND date LIKE ?',
      whereArgs: [courseId, '$date%'],
    );
  }

  Future<List<Map<String, dynamic>>> getStudentAttendance(int studentId, int courseId) async {
    final db = await database;
    return await db.query(
      'attendance',
      where: 'student_id = ? AND course_id = ?',
      whereArgs: [studentId, courseId],
      orderBy: 'date DESC',
    );
  }


  Future<List<Course>> getAllCourses() async {
    final db = await database;
    final result = await db.query('courses');
    return result.map((json) => Course.fromMap(json)).toList();
  }

  Future<Course?> getCourse(int id) async {
    final db = await database;
    final maps = await db.query(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Course.fromMap(maps.first);
    }
    return null;
  }

  // Enrollment operations
  Future<int> enrollStudentInCourse(Enrollment enrollment) async {
    final db = await database;
    return await db.insert('enrollments', enrollment.toMap());
  }

  Future<int> removeEnrollment(int id) async {
    final db = await database;
    return await db.delete(
      'enrollments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Enrollment>> getEnrollmentsByStudent(int studentId) async {
    final db = await database;
    final result = await db.query(
      'enrollments',
      where: 'studentId = ?',
      whereArgs: [studentId],
    );
    return result.map((json) => Enrollment.fromMap(json)).toList();
  }

  Future<List<Enrollment>> getEnrollmentsByCourse(int courseId) async {
    final db = await database;
    final result = await db.query(
      'enrollments',
      where: 'courseId = ?',
      whereArgs: [courseId],
    );
    return result.map((json) => Enrollment.fromMap(json)).toList();
  }

  Future<List<Map<String, dynamic>>> getStudentCourses(int studentId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT c.* 
      FROM courses c 
      JOIN enrollments e ON c.id = e.courseId 
      WHERE e.studentId = ?
    ''', [studentId]);
  }

  Future<List<Map<String, dynamic>>> getCourseStudents(int courseId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT s.* 
      FROM students s 
      JOIN enrollments e ON s.id = e.studentId 
      WHERE e.courseId = ?
    ''', [courseId]);
  }
  
  // Statistics operations
  Future<int> getStudentsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM students');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getCoursesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM courses');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getEnrollmentsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM enrollments');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updatePassword(String username, String newPassword) async {
    final db = await database;
    await db.update(
      'users',
      {'password': newPassword},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<void> deleteAllStudents() async {
    final db = await database;
    await db.delete('students');
    await db.delete('enrollments');
  }

  Future<void> deleteAllCourses() async {
    final db = await database;
    await db.delete('courses');
    await db.delete('enrollments');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}