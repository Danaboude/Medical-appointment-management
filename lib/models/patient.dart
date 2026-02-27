class Patient {
  int? patientId;
  String name;
  String? birthDate;
  String? gender;
  String? address;
  String? phone;
  String? maritalStatus;
  String fileNumber;
  String? firstVisitDate;
  String? xrayImage;

  Patient({
    this.patientId,
    required this.name,
    int? age,
    this.birthDate,
    this.gender,
    this.address,
    this.phone,
    this.maritalStatus,
    required this.fileNumber,
    this.firstVisitDate,
    this.xrayImage,
  }) {
    if (age != null && birthDate == null) {
      this.birthDate = '${DateTime.now().year - age}-01-01';
    }
  }

  int? get age {
    if (birthDate == null || birthDate!.isEmpty) return null;
    try {
      final birth = DateTime.parse(birthDate!);
      final today = DateTime.now();
      int age = today.year - birth.year;
      if (today.month < birth.month || (today.month == today.month && today.day < birth.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  set age(int? newAge) {
    if (newAge != null) {
      birthDate = '${DateTime.now().year - newAge}-01-01';
    } else {
      birthDate = null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'patient_id': patientId,
      'name': name,
      'birth_date': birthDate,
      'gender': gender,
      'address': address,
      'phone': phone,
      'marital_status': maritalStatus,
      'file_number': fileNumber,
      'first_visit_date': firstVisitDate,
      'xray_image': xrayImage,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      patientId: map['patient_id'],
      name: map['name'],
      birthDate: map['birth_date'],
      gender: map['gender'],
      address: map['address'],
      phone: map['phone'],
      maritalStatus: map['marital_status'],
      fileNumber: map['file_number'],
      firstVisitDate: map['first_visit_date'],
      xrayImage: map['xray_image'],
    );
  }
}
