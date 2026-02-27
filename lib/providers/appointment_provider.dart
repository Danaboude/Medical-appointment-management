import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/appointment.dart';
import '../repositories/appointment_repository.dart';

class AppointmentProvider with ChangeNotifier {
  final AppointmentRepository _appointmentRepository = AppointmentRepository();
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  CalendarFormat get calendarFormat => _calendarFormat;

  AppointmentProvider() {
    _selectedDay = _focusedDay;
    fetchAppointments();
  }

  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      notifyListeners();
    }
  }

  void onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      _calendarFormat = format;
      notifyListeners();
    }
  }

  void onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    notifyListeners();
  }

  void resetCalendar() {
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _calendarFormat = CalendarFormat.month;
    notifyListeners();
  }

  Future<void> fetchAppointments() async {
    _isLoading = true;
    notifyListeners();
    _appointments = await _appointmentRepository.getAppointments();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAppointment(Appointment appointment) async {
    await _appointmentRepository.insertAppointment(appointment);
    await fetchAppointments();
  }

  Future<void> updateAppointment(Appointment appointment) async {
    await _appointmentRepository.updateAppointment(appointment);
    await fetchAppointments();
  }

  Future<void> deleteAppointment(int id) async {
    await _appointmentRepository.deleteAppointment(id);
    await fetchAppointments();
  }

  List<Appointment> getAppointmentsForDate(DateTime date) {
    return _appointments.where((appointment) {
      final appointmentDateTime = DateTime.parse(appointment.appointmentDate);
      return appointmentDateTime.year == date.year &&
             appointmentDateTime.month == date.month &&
             appointmentDateTime.day == date.day;
    }).toList();
  }

  List<Appointment> get appointmentsForSelectedDate {
    if (_selectedDay == null) return [];
    return _appointments.where((appointment) {
      final appointmentDateTime = DateTime.parse(appointment.appointmentDate);
      return appointmentDateTime.year == _selectedDay!.year &&
          appointmentDateTime.month == _selectedDay!.month &&
          appointmentDateTime.day == _selectedDay!.day;
    }).toList();
  }
}
