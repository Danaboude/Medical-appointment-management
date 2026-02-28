import 'dart:io';

import 'package:clinc/models/appointment.dart';
import 'package:clinc/models/invoice.dart';
import 'package:clinc/models/treatment.dart';
import 'package:clinc/screens/invoice_form_screen.dart';
import 'package:clinc/services/xray_analysis_service.dart'; // Import the new service
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../l10n/localization_helpers.dart';
import '../models/patient.dart';
import '../providers/appointment_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/treatment_provider.dart';
import 'appointment_form_screen.dart';
import 'invoice_detail_screen.dart';
import 'treatment_form_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  XRayAnalysisResult? _xrayAnalysisResult;
  bool _isLoadingXRayAnalysis = false;
  String? _xrayAnalysisError;
  bool _isAnalysisPerformed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isAnalysisPerformed && widget.patient.xrayImage != null && widget.patient.xrayImage!.isNotEmpty) {
      _isAnalysisPerformed = true;
      _performXRayAnalysis(widget.patient.xrayImage!);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _performXRayAnalysis(String imagePath) async {
    setState(() {
      _isLoadingXRayAnalysis = true;
      _xrayAnalysisError = null;
    });

    try {
      final locale = AppLocalizations.of(context)!.localeName;
      final result = await XRayAnalysisService().analyzeXRayImage(imagePath, widget.patient.name, locale);
      setState(() {
        _xrayAnalysisResult = result;
        // If the Python script returns an error status, set the error message
        if (result.analysisStatus == 'error') {
          _xrayAnalysisError = result.errorMessage ?? 'Unknown analysis error';
        }
      });
    } catch (e) {
      setState(() {
        _xrayAnalysisError = e.toString();
      });
    } finally {
      setState(() {
        _isLoadingXRayAnalysis = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.patient.name),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildWideLayout(context);
          } else {
            return _buildNarrowLayout(context);
          }
        }),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 400,
          child: _buildPatientDetailsCard(context),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: _buildTabs(context, isScrollable: true),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildPatientDetailsCard(context)),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5, // Give tabs a constrained height
          child: _buildTabs(context, isScrollable: false),
        ),
      ],
    );
  }

    Widget _buildPatientDetailsCard(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final treatmentProvider = Provider.of<TreatmentProvider>(context);
    final patientTreatments = treatmentProvider.treatments
        .where((t) => t.patientId == widget.patient.patientId)
        .toList();

    final double totalExpenses = patientTreatments.fold(
        0.0, (sum, treatment) => sum + (treatment.expenses ?? 0.0));
    final double totalAgreedAmount = patientTreatments.fold(
        0.0, (sum, treatment) => sum + (treatment.agreedAmount ?? 0.0));
    final double totalProfit = totalAgreedAmount - totalExpenses;
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            Text(
              appLocalizations.financialSummary,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.trending_down,
              appLocalizations.totalExpensesLabel,
              NumberFormat.currency(
                      locale: appLocalizations.localeName,
                      symbol: appLocalizations.currencySymbol)
                  .format(totalExpenses),
            ),
            _buildDetailRow(
              context,
              Icons.trending_up,
              appLocalizations.totalProfits,
              NumberFormat.currency(
                      locale: appLocalizations.localeName,
                      symbol: appLocalizations.currencySymbol)
                  .format(totalProfit),
            ),
            const Divider(height: 32),
            Text(widget.patient.name,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                '${appLocalizations.fileNumber}: ${widget.patient.fileNumber}',
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 32),
            _buildDetailRow(context, Icons.phone_outlined,
                appLocalizations.phone, widget.patient.phone),
            _buildDetailRow(context, Icons.cake_outlined,
                appLocalizations.age, widget.patient.age?.toString()),
            _buildDetailRow(context, Icons.person_outline,
                appLocalizations.gender, widget.patient.gender != null ? getLocalizedGender(widget.patient.gender!, appLocalizations) : null),
            _buildDetailRow(
                context,
                Icons.favorite_border,
                appLocalizations.maritalStatus,
                widget.patient.maritalStatus != null ? getLocalizedMaritalStatus(widget.patient.maritalStatus!, appLocalizations) : null),
            _buildDetailRow(context, Icons.home_outlined,
                appLocalizations.address, widget.patient.address),
            _buildDetailRow(
                context,
                Icons.calendar_today_outlined,
                appLocalizations.firstVisitDate,
                widget.patient.firstVisitDate != null
                    ? DateFormat.yMd(appLocalizations.localeName)
                        .format(DateTime.parse(widget.patient.firstVisitDate!))
                    : null),
            if (widget.patient.xrayImage != null &&
                widget.patient.xrayImage!.isNotEmpty) ...[
              const Divider(height: 32),
              _buildXrayImage(context),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildXrayImage(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final imageFile = File(widget.patient.xrayImage!);
    final imageExists = imageFile.existsSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalizations.xrayGallery,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (imageExists) ...[
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImageViewer(
                      imagePath: widget.patient.xrayImage!),
                ),
              );
            },
            child: Hero(
              tag: widget.patient.xrayImage!,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.file(
                  imageFile,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      appLocalizations.noImageSelected,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildXRayAnalysisSection(context),
        ] else
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                appLocalizations.noImageSelected,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildXRayAnalysisSection(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    if (_isLoadingXRayAnalysis) {
      return const Center(child: CircularProgressIndicator());
    } else if (_xrayAnalysisError != null) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appLocalizations.xRayAnalysisError,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _xrayAnalysisError!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
              ),
            ],
          ),
        ),
      );
    } else if (_xrayAnalysisResult != null) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appLocalizations.xRayAnalysisResults,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                Icons.analytics_outlined,
                appLocalizations.analysisId,
                _xrayAnalysisResult!.analysisId,
              ),
              _buildDetailRow(
                context,
                Icons.access_time,
                appLocalizations.analysisDate,
                _xrayAnalysisResult!.timestamp != null
                    ? DateFormat.yMd(appLocalizations.localeName)
                        .add_jm()
                        .format(_xrayAnalysisResult!.timestamp!)
                    : appLocalizations.na,
              ),
              _buildDetailRow(
                context,
                Icons.image_outlined,
                appLocalizations.imageQuality,
                _xrayAnalysisResult!.imageQuality ?? appLocalizations.na,
              ),
              const Divider(height: 24),
              Text(
                appLocalizations.findings,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              if (_xrayAnalysisResult!.findings.isEmpty)
                Text(appLocalizations.noSpecificFindingsDetected)
              else
                ..._xrayAnalysisResult!.findings.map((finding) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ${finding.area}: ${finding.issue} (${(finding.confidence * 100).toStringAsFixed(0)}% ${appLocalizations.confidence})',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (finding.severity != null && finding.severity!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Text(
                                '${appLocalizations.severity}: ${finding.severity}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          if (finding.recommendation != null && finding.recommendation!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Text(
                                '${appLocalizations.recommendation}: ${finding.recommendation}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                        ],
                      ),
                    )),
              const Divider(height: 24),
              Text(
                appLocalizations.medicalAdviceSummary,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _xrayAnalysisResult!.medicalAdviceSummary ?? appLocalizations.noSummaryAvailable,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (_xrayAnalysisResult!.annotatedImagePath != null &&
                  File(_xrayAnalysisResult!.annotatedImagePath!).existsSync()) ...[
                const SizedBox(height: 24),
                Text(
                  appLocalizations.annotatedImage, // Need to add this localization key
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageViewer(
                            imagePath: _xrayAnalysisResult!.annotatedImagePath!),
                      ),
                    );
                  },
                  child: Hero(
                    tag: _xrayAnalysisResult!.annotatedImagePath!,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.file(
                        File(_xrayAnalysisResult!.annotatedImagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            appLocalizations.errorLoadingImage, // Need to add this localization key
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    debugPrint('Annotated Image Path: ${_xrayAnalysisResult?.annotatedImagePath}'); // Added here
    return const SizedBox.shrink();
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon,
              size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(width: 16),
          Text('$label:', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context, {required bool isScrollable}) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Column(
      children: [
        TabBar(
          tabs: [
            Tab(text: appLocalizations.treatments),
            Tab(text: appLocalizations.invoices),
            Tab(text: appLocalizations.appointments),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              _TreatmentsTab(
                  patientId: widget.patient.patientId!,
                  isScrollable: isScrollable),
              _InvoicesTab(
                  patientId: widget.patient.patientId!,
                  isScrollable: isScrollable),
              _AppointmentsTab(
                  patientId: widget.patient.patientId!,
                  isScrollable: isScrollable),
            ],
          ),
        ),
      ],
    );
  }
}

// Common base class for Tab content to reduce boilerplate

abstract class _BasePatientTab<T> extends StatelessWidget {
  final int patientId;
  final bool isScrollable;

  const _BasePatientTab({required this.patientId, required this.isScrollable});

  @override
  Widget build(BuildContext context) {
    final provider = getProvider(context);
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = getItems(provider);
    if (items.isEmpty) {
      return Center(
          child: Text(getEmptyMessage(AppLocalizations.of(context)!)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      shrinkWrap: !isScrollable,
      physics: isScrollable ? null : const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return buildItemCard(context, items[index]);
      },
    );
  }

  dynamic getProvider(BuildContext context);
  List<T> getItems(dynamic provider);
  String getEmptyMessage(AppLocalizations l10n);
  Widget buildItemCard(BuildContext context, T item);
}

class _TreatmentsTab extends _BasePatientTab<Treatment> {
  const _TreatmentsTab({required super.patientId, required super.isScrollable});

  @override
  dynamic getProvider(BuildContext context) =>
      Provider.of<TreatmentProvider>(context);

  @override
  List<Treatment> getItems(dynamic provider) =>
      (provider as TreatmentProvider)
          .treatments
          .where((t) => t.patientId == patientId)
          .toList();

  @override
  String getEmptyMessage(AppLocalizations l10n) => l10n.noTreatmentsFound;

  @override
  Widget build(BuildContext context) {
    final provider = getProvider(context);
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = getItems(provider);
    final appLocalizations = AppLocalizations.of(context)!;

    final content = items.isEmpty
        ? Center(child: Text(getEmptyMessage(appLocalizations)))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0), // FAB space
            shrinkWrap: !isScrollable,
            physics: isScrollable ? null : const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return buildItemCard(context, items[index]);
            },
          );

    return Stack(
      children: [
        content,
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TreatmentFormScreen(patientId: patientId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget buildItemCard(BuildContext context, Treatment treatment) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(treatment.diagnosis ?? appLocalizations.noDiagnosis),
        subtitle: Text(
            '${appLocalizations.date}: ${DateFormat.yMd(appLocalizations.localeName).format(DateTime.parse(treatment.treatmentDate))} - ${appLocalizations.status}: ${getLocalizedTreatmentStatus(treatment.status, appLocalizations)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TreatmentFormScreen(treatment: treatment),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                _showDeleteConfirmationDialog(context, appLocalizations, () {
                  Provider.of<TreatmentProvider>(context, listen: false)
                      .deleteTreatment(treatment.treatmentId!);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, AppLocalizations appLocalizations, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations.delete),
          content: Text(appLocalizations.deletePatientConfirmation),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(appLocalizations.delete),
              onPressed: () {
                onDelete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class _InvoicesTab extends _BasePatientTab<Invoice> {
  const _InvoicesTab({required super.patientId, required super.isScrollable});

  @override
  dynamic getProvider(BuildContext context) =>
      Provider.of<InvoiceProvider>(context);

  @override
  List<Invoice> getItems(dynamic provider) => (provider as InvoiceProvider)
      .invoices
      .where((inv) => inv.patientId == patientId)
      .toList();

  @override
  String getEmptyMessage(AppLocalizations l10n) => l10n.noInvoicesFound;

  @override
  Widget build(BuildContext context) {
    final provider = getProvider(context);
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = getItems(provider);
    final appLocalizations = AppLocalizations.of(context)!;

    final content = items.isEmpty
        ? Center(child: Text(getEmptyMessage(appLocalizations)))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0), // FAB space
            shrinkWrap: !isScrollable,
            physics: isScrollable ? null : const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return buildItemCard(context, items[index]);
            },
          );

    return content;
  }

  @override
  Widget buildItemCard(BuildContext context, Invoice invoice) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text('${appLocalizations.invoice} #${invoice.invoiceId}'),
        subtitle: Text(
            '${appLocalizations.date}: ${DateFormat.yMd(appLocalizations.localeName).format(DateTime.parse(invoice.invoiceDate))} - ${appLocalizations.total}: ${NumberFormat.currency(locale: appLocalizations.localeName, symbol: appLocalizations.currencySymbol).format(invoice.totalAmount ?? 0)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
           
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                _showDeleteConfirmationDialog(context, appLocalizations, () {
                  Provider.of<InvoiceProvider>(context, listen: false)
                      .deleteInvoice(invoice.invoiceId!);
                });
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InvoiceDetailScreen(invoice: invoice),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, AppLocalizations appLocalizations, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations.delete),
          content: Text(appLocalizations.deletePatientConfirmation),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(appLocalizations.delete),
              onPressed: () {
                onDelete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class _AppointmentsTab extends _BasePatientTab<Appointment> {
  const _AppointmentsTab(
      {required super.patientId, required super.isScrollable});

  @override
  dynamic getProvider(BuildContext context) =>
      Provider.of<AppointmentProvider>(context);

  @override
  List<Appointment> getItems(dynamic provider) =>
      (provider as AppointmentProvider)
          .appointments
          .where((app) => app.patientId == patientId)
          .toList();

  @override
  String getEmptyMessage(AppLocalizations l10n) => l10n.noAppointmentsFound;

  @override
  Widget build(BuildContext context) {
    final provider = getProvider(context);
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = getItems(provider);
    final appLocalizations = AppLocalizations.of(context)!;

    final content = items.isEmpty
        ? Center(child: Text(getEmptyMessage(appLocalizations)))
        : ListView.builder(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0), // FAB space
            shrinkWrap: !isScrollable,
            physics: isScrollable ? null : const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return buildItemCard(context, items[index]);
            },
          );

    return Stack(
      children: [
        content,
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentFormScreen(patientId: patientId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget buildItemCard(BuildContext context, Appointment appointment) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
            appLocalizations.appointmentOn(DateFormat.yMd(appLocalizations.localeName).format(DateTime.parse(appointment.appointmentDate)))),
        subtitle: Text(
            '${appLocalizations.time}: ${DateFormat.jm(appLocalizations.localeName).format(DateTime.parse(appointment.appointmentDate))} - ${appLocalizations.status}: ${getLocalizedAppointmentStatus(appointment.status, appLocalizations)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AppointmentFormScreen(appointment: appointment),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                _showDeleteConfirmationDialog(context, appLocalizations, () {
                  Provider.of<AppointmentProvider>(context, listen: false)
                      .deleteAppointment(appointment.appointmentId!);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, AppLocalizations appLocalizations, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocalizations.delete),
          content: Text(appLocalizations.deletePatientConfirmation),
          actions: <Widget>[
            TextButton(
              child: Text(appLocalizations.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(appLocalizations.delete),
              onPressed: () {
                onDelete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const FullScreenImageViewer({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: imagePath,
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: Image.file(
                  File(imagePath),
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.white, size: 64),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 10,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}