import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/localization_helpers.dart';
import '../models/patient.dart';
import '../providers/patient_provider.dart';

class PatientFormScreen extends StatefulWidget {
  final Patient? patient;

  const PatientFormScreen({super.key, this.patient});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _xrayImageController;
  String? _gender;
  String? _maritalStatus;
  DateTime? _firstVisitDate;
  XFile? _xrayImageFile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient?.name);
    _ageController =
        TextEditingController(text: widget.patient?.age?.toString());
    _addressController = TextEditingController(text: widget.patient?.address);
    _phoneController = TextEditingController(text: widget.patient?.phone);
    _xrayImageController =
        TextEditingController(text: widget.patient?.xrayImage);
    _gender = widget.patient?.gender;
    _maritalStatus = widget.patient?.maritalStatus;
    _firstVisitDate = widget.patient?.firstVisitDate != null
        ? DateTime.parse(widget.patient!.firstVisitDate!)
        : DateTime.now(); // Default to now for new patients
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _xrayImageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _firstVisitDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _firstVisitDate) {
      setState(() {
        _firstVisitDate = picked;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() {
        _xrayImageFile = image;
        _xrayImageController.text = image.path;
      });
    }
  }

  void _savePatient() {
    if (_formKey.currentState!.validate()) {
      final newPatient = Patient(
        patientId: widget.patient?.patientId,
        name: _nameController.text,
        age: int.tryParse(_ageController.text),
        gender: _gender,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        maritalStatus: _maritalStatus,
        fileNumber: widget.patient?.fileNumber ?? '', // Handled by provider
        firstVisitDate: _firstVisitDate?.toIso8601String(),
        xrayImage: _xrayImageController.text.isEmpty
            ? null
            : _xrayImageController.text,
      );

      final provider = Provider.of<PatientProvider>(context, listen: false);
      if (widget.patient == null) {
        provider.addPatient(newPatient);
      } else {
        provider.updatePatient(newPatient);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient == null
            ? appLocalizations.addPatient
            : appLocalizations.editPatientTitle),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // Padding for bottom bar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle(
                      context, appLocalizations.personalInformation),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(appLocalizations.name, context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return appLocalizations.pleaseEnterPatientName;
                      }
                      final patientProvider =
                          Provider.of<PatientProvider>(context, listen: false);
                      final trimmedValue = value.trim().toLowerCase();

                      final isNameExists = patientProvider.patients.any((patient) {
                        if (widget.patient != null &&
                            patient.patientId == widget.patient!.patientId) {
                          return false;
                        }
                        return patient.name.toLowerCase() == trimmedValue;
                      });

                      if (isNameExists) {
                        return appLocalizations.patientNameExists;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ageController,
                          decoration: _inputDecoration(appLocalizations.age, context),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _gender,
                          decoration: _inputDecoration(appLocalizations.gender, context),
                          items: <String>['ذكر', 'أنثى']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(getLocalizedGender(value, appLocalizations)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _gender = newValue;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    value: _maritalStatus,
                    decoration:
                        _inputDecoration(appLocalizations.maritalStatus, context),
                    items: <String>['أعزب', 'متزوج', 'مطلق', 'أرمل']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(getLocalizedMaritalStatus(value, appLocalizations)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _maritalStatus = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(
                      context, appLocalizations.contactInformation),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: _inputDecoration(appLocalizations.phone, context),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _addressController,
                    decoration: _inputDecoration(appLocalizations.address, context),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, appLocalizations.clinicInformation),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration:
                          _inputDecoration(appLocalizations.firstVisitDate, context),
                      child: Text(
                        _firstVisitDate == null
                            ? appLocalizations.selectFirstVisitDate
                            : DateFormat.yMd(appLocalizations.localeName)
                                .format(_firstVisitDate!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, appLocalizations.xrayGallery),
                  const SizedBox(height: 16),
                  _buildImagePicker(context),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface.withAlpha(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: _xrayImageFile != null
                ? Image.file(File(_xrayImageFile!.path), fit: BoxFit.cover)
                : (_xrayImageController.text.isNotEmpty
                    ? Image.file(File(_xrayImageController.text),
                        fit: BoxFit.cover)
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image_not_supported_outlined,
                                size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(appLocalizations.noImageSelected),
                          ],
                        ),
                      )),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.image_outlined),
              label: Text(appLocalizations.gallery),
            ),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(appLocalizations.camera),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  InputDecoration _inputDecoration(String label, BuildContext context) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface.withAlpha(10),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return BottomAppBar(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _savePatient,
          icon: const Icon(Icons.save_outlined),
          label: Text(widget.patient == null
              ? appLocalizations.addPatient
              : appLocalizations.updatePatientButton),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            textStyle: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}

