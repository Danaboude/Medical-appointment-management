import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static bool _updaterStarted = false;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    if (!_updaterStarted) {
      _instance.startAppointmentStatusUpdater();
      _updaterStarted = true;
    }
    return _database!;
  }

  void startAppointmentStatusUpdater() {
    // Run the check once at startup, then every 2 hours.
    updatePastAppointmentsStatus();
    Timer.periodic(const Duration(hours: 2), (timer) {
      updatePastAppointmentsStatus();
    });
  }

  Future<void> updatePastAppointmentsStatus() async {
    final db = await database;
    final now = DateTime.now();
    // Assuming appointment_date is stored in a format like 'YYYY-MM-DD HH:MM:SS'
    final formattedDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    try {
      int count = await db.rawUpdate('''
        UPDATE Appointments
        SET status = ?
        WHERE status = ? AND appointment_date <= ?
      ''', ['منجز', 'محجوز', formattedDateTime]);
      if (count > 0) {
        print('Updated $count appointments to "منجز"');
      }
    } catch (e) {
      print('Error updating appointment statuses: $e');
    }
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'clinc_database.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Patients (
        patient_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        birth_date TEXT,
        gender TEXT,
        address TEXT,
        phone TEXT,
        marital_status TEXT,
        file_number TEXT UNIQUE NOT NULL,
        first_visit_date TEXT,
        xray_image TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE Treatments (
        treatment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        diagnosis TEXT,
        treatment TEXT,
        tooth_number TEXT,
        agreed_amount REAL,
        agreed_amount_paid REAL DEFAULT 0.0,
        treatment_date TEXT,
        status TEXT DEFAULT 'قيد التنفيذ',
        expenses REAL DEFAULT 0.0,
        laboratory_name TEXT,
        FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE Invoices (
        invoice_id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        invoice_date TEXT NOT NULL,
        total_amount REAL,
        status TEXT DEFAULT 'مسودة',
        FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE Invoice_Treatments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        treatment_id INTEGER NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES Invoices(invoice_id) ON DELETE CASCADE,
        FOREIGN KEY (treatment_id) REFERENCES Treatments(treatment_id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE Payments (
        payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        method TEXT DEFAULT 'نقدي',
        FOREIGN KEY (invoice_id) REFERENCES Invoices(invoice_id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE Expenses (
        expense_id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT,
        amount REAL NOT NULL,
        expense_date TEXT NOT NULL,
        category TEXT DEFAULT 'أخرى'
      )
    ''');
    await db.execute('''
      CREATE TABLE Appointments (
        appointment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        appointment_date TEXT NOT NULL,
        notes TEXT,
        doctor_notes TEXT,
        status TEXT DEFAULT 'محجوز',
        FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE Treatments ADD COLUMN agreed_amount_paid REAL DEFAULT 0.0;');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE Treatments ADD COLUMN expenses REAL DEFAULT 0.0;');
      await db.execute('ALTER TABLE Treatments ADD COLUMN laboratory_name TEXT;');
    }
    if (oldVersion < 4) {
      await db.transaction((txn) async {
        await txn.execute('''
          CREATE TABLE Patients_new (
            patient_id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            birth_date TEXT,
            gender TEXT,
            address TEXT,
            phone TEXT,
            marital_status TEXT,
            file_number TEXT UNIQUE NOT NULL,
            first_visit_date TEXT,
            xray_image TEXT
          )
        ''');

        await txn.execute('''
          INSERT INTO Patients_new (patient_id, name, gender, address, phone, marital_status, file_number, first_visit_date, xray_image, birth_date)
          SELECT patient_id, name, gender, address, phone, marital_status, file_number, first_visit_date, xray_image,
                 CASE WHEN age IS NOT NULL THEN (CAST(strftime('%Y', 'now') AS INTEGER) - age) || '-01-01' ELSE NULL END
          FROM Patients
        ''');

        await txn.execute('DROP TABLE Patients');
        await txn.execute('ALTER TABLE Patients_new RENAME TO Patients');
      });
    }
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> clearDatabase() async {
    final db = await database;
    final tables = [
      'Payments',
      'Invoice_Treatments',
      'Appointments',
      'Expenses',
      'Invoices',
      'Treatments',
      'Patients'
    ];
    await db.execute('PRAGMA foreign_keys = OFF');
    for (var table in tables) {
      await db.delete(table);
    }
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _insertInitialData(Database db) async {
    try {
      String jsonString = await rootBundle.loadString('assets/data/sample_data.json');
      final data = json.decode(jsonString);

      // Insert Patients
      if (data['patients'] != null) {
        for (var patient in data['patients']) {
          await db.insert('Patients', patient, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert Appointments
      if (data['appointments'] != null) {
        for (var appointment in data['appointments']) {
          await db.insert('Appointments', appointment, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert Treatments
      if (data['treatments'] != null) {
        for (var treatment in data['treatments']) {
          await db.insert('Treatments', treatment, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert Invoices
      if (data['invoices'] != null) {
        for (var invoice in data['invoices']) {
          await db.insert('Invoices', invoice, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert Invoice_Treatments
      if (data['invoice_treatments'] != null) {
        for (var invoiceTreatment in data['invoice_treatments']) {
          await db.insert('Invoice_Treatments', invoiceTreatment, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert Payments
      if (data['payments'] != null) {
        for (var payment in data['payments']) {
          await db.insert('Payments', payment, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // Insert Expenses
      if (data['expenses'] != null) {
        for (var expense in data['expenses']) {
          await db.insert('Expenses', expense, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  Future<void> checkAndInsertInitialData() async {
    final db = await database;
    // Check if patients table is empty, assuming if patients table is empty, then no data has been loaded
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM Patients'));
    if (count == 0) {
      await _insertInitialData(db);
    }
  }
}

class BackupService {
  final DatabaseService _databaseService = DatabaseService();

  Future<String?> exportData() async {
    try {
      final db = await _databaseService.database;
      final tables = [
        'Patients',
        'Appointments',
        'Treatments',
        'Invoices',
        'Invoice_Treatments',
        'Payments',
        'Expenses'
      ];
      final Map<String, List<Map<String, dynamic>>> allData = {};

      for (var table in tables) {
        final List<Map<String, dynamic>> tableData = await db.query(table);
        allData[table] = tableData;
      }

      final String jsonData = json.encode(allData);

      final tempDir = await getTemporaryDirectory();
      final backupDir = Directory('${tempDir.path}/backup');
      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }
      await backupDir.create();

      final jsonFile = File('${backupDir.path}/backup.json');
      await jsonFile.writeAsString(jsonData);

      final imagesDir = Directory('${backupDir.path}/images');
      await imagesDir.create();

      final patients = allData['Patients'] ?? [];
      for (var patient in patients) {
        final xrayPath = patient['xray_image'];
        if (xrayPath != null && xrayPath.isNotEmpty) {
          final imageFile = File(xrayPath);
          if (await imageFile.exists()) {
            final imageName = basename(imageFile.path);
            await imageFile.copy('${imagesDir.path}/$imageName');
          }
        }
      }

      final zipFilePath = '${tempDir.path}/clinc_backup_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.zip';
      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);
      await encoder.addDirectory(backupDir);
      encoder.close();

      return zipFilePath;
    } catch (e) {
      print('Export failed: $e');
      return null;
    }
  }

  Future<bool> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['zip']);
      if (result == null) return false; // User canceled picker

      final zipFile = File(result.files.single.path!);
      final tempDir = await getTemporaryDirectory();
      final importDir = Directory('${tempDir.path}/import');
      if (await importDir.exists()) {
        await importDir.delete(recursive: true);
      }
      await importDir.create();

      final archive = ZipDecoder().decodeBytes(zipFile.readAsBytesSync());
      for (final file in archive) {
        final filename = file.name;
        final path = '${importDir.path}/$filename';
        if (file.isFile) {
          final data = file.content as List<int>;
          File(path)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(path).create(recursive: true);
        }
      }

      final jsonFile = File('${importDir.path}/backup/backup.json');
      if (!await jsonFile.exists()) {
        throw Exception("backup.json not found in archive");
      }
      final jsonData = await jsonFile.readAsString();
      final allData = json.decode(jsonData) as Map<String, dynamic>;

      await _databaseService.clearDatabase();

      final db = await _databaseService.database;
      final tables = [
        'Patients',
        'Treatments',
        'Appointments',
        'Invoices',
        'Invoice_Treatments',
        'Payments',
        'Expenses'
      ];

      final imagesDir = Directory('${importDir.path}/backup/images');
      final appDocsDir = await getApplicationDocumentsDirectory();
      final newImagesDir = Directory('${appDocsDir.path}/xray_images');
      if (!await newImagesDir.exists()) {
        await newImagesDir.create(recursive: true);
      }

      List<Map<String, dynamic>> patients = List<Map<String, dynamic>>.from(allData['Patients'] ?? []);
      for (var i = 0; i < patients.length; i++) {
        var patient = patients[i];
        final oldImagePath = patient['xray_image'];
        if (oldImagePath != null && oldImagePath.isNotEmpty) {
          final imageName = basename(oldImagePath);
          final oldImageFile = File('${imagesDir.path}/$imageName');
          if (await oldImageFile.exists()) {
            final newImagePath = '${newImagesDir.path}/$imageName';
            await oldImageFile.copy(newImagePath);
            patients[i]['xray_image'] = newImagePath;
          }
        }
      }
      allData['Patients'] = patients;

      await db.execute('PRAGMA foreign_keys = OFF');
      final batch = db.batch();

      for (var table in tables) {
        List<Map<String, dynamic>> tableData = List<Map<String, dynamic>>.from(allData[table] ?? []);
        for (var row in tableData) {
          batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      await batch.commit(noResult: true);
      await db.execute('PRAGMA foreign_keys = ON');

      return true;
    } catch (e) {
      print('Import failed: $e');
      return false;
    }
  }
}
