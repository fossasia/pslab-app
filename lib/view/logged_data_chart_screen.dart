import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../others/data_chart_analyzer.dart';
import 'widgets/data_chart.dart';

class LoggedDataChartScreen extends StatefulWidget {
  final String fileName;
  final String instrumentName;
  final List<List<dynamic>> data;

  const LoggedDataChartScreen({
    super.key,
    required this.fileName,
    required this.instrumentName,
    required this.data,
  });

  @override
  State<LoggedDataChartScreen> createState() {
    return _LoggedDataChartScreenState();
  }
}

class _LoggedDataChartScreenState extends State<LoggedDataChartScreen> {
  Map<String, InstrumentSeries> analyzedData = {};
  int sampleCount = 0;
  String logTime = 'Unknown';
  String cleanFileName = '';

  final GlobalKey _printKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _processData();
  }

  void _processData() {
    cleanFileName = widget.fileName.split('\\').last.split('/').last;

    int headerIndex = 0;
    for (int i = 0; i < widget.data.length; i++) {
      if (widget.data[i].isNotEmpty &&
          widget.data[i].first.toString().toLowerCase() == 'timestamp') {
        headerIndex = i;
        break;
      }
    }

    if (widget.data.length > headerIndex + 1) {
      sampleCount = widget.data.length - (headerIndex + 1);
      logTime = widget.data[headerIndex + 1][1].toString();
    }

    analyzedData =
        ScientificDataAnalyzer.analyze(widget.instrumentName, widget.data);
  }

  Future<void> _exportToPdf() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF Document...'),
          duration: Duration(seconds: 1),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      RenderRepaintBoundary boundary =
          _printKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        Uint8List pngBytes = byteData.buffer.asUint8List();

        final pdf = pw.Document();
        final imageProvider = pw.MemoryImage(pngBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(imageProvider, fit: pw.BoxFit.contain),
              );
            },
          ),
        );

        await Printing.sharePdf(
          bytes: await pdf.save(),
          filename:
              '${widget.instrumentName.replaceAll(" ", "_")}_Chart_Report.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    }
  }

  List<Widget> _getSpecificMetrics(InstrumentSeries series) {
    final inst = widget.instrumentName.toLowerCase();

    if (inst == 'oscilloscope' ||
        inst == 'wave generator' ||
        inst == 'multimeter') {
      return [
        SpecificMetricText(
            label: 'PEAK-TO-PEAK',
            value: series.peakToPeak.toStringAsFixed(2),
            unit: 'V'),
        SpecificMetricText(
            label: 'RMS VOLTAGE',
            value: series.rms.toStringAsFixed(3),
            unit: 'V'),
        SpecificMetricText(
            label: 'NOISE (σ)',
            value: series.stdDev.toStringAsFixed(3),
            unit: 'V'),
        SpecificMetricText(
            label: 'INTEGRAL',
            value: series.integral.toStringAsFixed(2),
            unit: 'Vs'),
      ];
    } else if (inst == 'accelerometer' ||
        inst == 'gyroscope' ||
        inst == 'compass') {
      return [
        SpecificMetricText(
            label: 'VIBRATION (σ)',
            value: series.stdDev.toStringAsFixed(3),
            unit: ''),
        SpecificMetricText(
            label: 'TOTAL RANGE',
            value: series.peakToPeak.toStringAsFixed(2),
            unit: ''),
        SpecificMetricText(
            label: 'RMS MAGNITUDE',
            value: series.rms.toStringAsFixed(2),
            unit: ''),
        SpecificMetricText(
            label: 'INTEGRAL',
            value: series.integral.toStringAsFixed(2),
            unit: ''),
      ];
    } else if (inst == 'sound meter') {
      return [
        SpecificMetricText(
            label: 'EQUIVALENT (RMS)',
            value: series.rms.toStringAsFixed(1),
            unit: 'dB'),
        SpecificMetricText(
            label: 'DYNAMIC RANGE',
            value: series.peakToPeak.toStringAsFixed(1),
            unit: 'dB'),
        SpecificMetricText(
            label: 'VARIANCE (σ)',
            value: series.stdDev.toStringAsFixed(2),
            unit: ''),
        SpecificMetricText(
            label: 'TOTAL AREA',
            value: series.integral.toStringAsFixed(1),
            unit: ''),
      ];
    } else {
      return [
        SpecificMetricText(
            label: 'TOTAL RANGE',
            value: series.peakToPeak.toStringAsFixed(2),
            unit: ''),
        SpecificMetricText(
            label: 'RMS VALUE', value: series.rms.toStringAsFixed(2), unit: ''),
        SpecificMetricText(
            label: 'DEVIATION (σ)',
            value: series.stdDev.toStringAsFixed(2),
            unit: ''),
        SpecificMetricText(
            label: 'INTEGRAL (∫)',
            value: series.integral.toStringAsFixed(1),
            unit: ''),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: 'LOGGED DATA CHART',
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          tooltip: 'Export to PDF',
          onPressed: _exportToPdf,
        ),
      ],
      body: SingleChildScrollView(
        child: RepaintBoundary(
          key: _printKey,
          child: Container(
            color: scaffoldBackgroundColor,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.instrumentName.toUpperCase(),
                  style: TextStyle(
                      fontSize: 12,
                      color: primaryRed,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  cleanFileName,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 12),
                Text(
                  'Logged: $logTime  |  Samples: $sampleCount',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54),
                ),
                const SizedBox(height: 24),
                if (analyzedData.isEmpty) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: Text(
                        "No visualization data available.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                ] else ...[
                  ...analyzedData.values.map((series) {
                    return _buildSeriesHardwareUI(series);
                  })
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesHardwareUI(InstrumentSeries series) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportGroupBox(
            title: '${series.name} - SIGNAL TREND (CHART)',
            child: MinimalSparkline(spots: series.spots),
          ),
          ReportGroupBox(
            title: '${series.name} - BASE METRICS',
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 16,
              runSpacing: 16,
              children: [
                UniversalStatText(
                    label: 'MEAN (μ)', value: series.mean.toStringAsFixed(2)),
                UniversalStatText(
                    label: 'MAXIMUM',
                    value: series.max.toStringAsFixed(2),
                    isHighlight: true),
                UniversalStatText(
                    label: 'MINIMUM', value: series.min.toStringAsFixed(2)),
              ],
            ),
          ),
          ReportGroupBox(
            title: '${series.name} - SPECIFIC METRICS',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _getSpecificMetrics(series).map((widget) {
                return FractionallySizedBox(
                  widthFactor: 0.45,
                  child: widget,
                );
              }).toList(),
            ),
          ),
          ReportGroupBox(
            title: '${series.name} - SIGNAL DISTRIBUTION',
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'AMPLITUDE ZONES',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          SignalPieChart(
                            low: series.lowZonePct,
                            mid: series.midZonePct,
                            high: series.highZonePct,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'FREQUENCY SPREAD',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          DistributionHistogram(
                            rawValues: series.rawValues,
                            min: series.min,
                            max: series.max,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendDot(Colors.blue.shade400, 'Low'),
                    const SizedBox(width: 12),
                    _legendDot(Colors.grey.shade400, 'Mid'),
                    const SizedBox(width: 12),
                    _legendDot(primaryRed, 'High'),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
      ],
    );
  }
}
