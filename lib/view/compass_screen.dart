import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import '../l10n/app_localizations.dart';
import '../providers/compass_provider.dart';
import '../providers/locator.dart';
import '../theme/colors.dart';

class CompassScreen extends StatelessWidget {
  const CompassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CompassProvider(),
      child: const CompassScreenContent(),
    );
  }
}

class CompassScreenContent extends StatefulWidget {
  const CompassScreenContent({super.key});

  @override
  State<CompassScreenContent> createState() => _CompassScreenContentState();
}

class _CompassScreenContentState extends State<CompassScreenContent> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  static const String compassIcon = 'assets/icons/compass_icon.png';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompassProvider>().initializeSensors();
    });
  }

  @override
  void dispose() {
    context.read<CompassProvider>().disposeSensors();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompassProvider>(
        builder: (context, compassProvider, child) {
      return CommonScaffold(
        title: appLocalizations.compassTitle,
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Transform.rotate(
                      angle: compassProvider.currentDegree,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          compassIcon,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Text(
                        compassProvider
                            .getDegreeForAxis(compassProvider.selectedAxis)
                            .round()
                            .toStringAsFixed(1),
                        style: TextStyle(
                          color: blackTextColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAxisColumn(
                              'Bx', compassProvider.magnetometerEvent.x),
                          _buildAxisColumn(
                              'By', compassProvider.magnetometerEvent.y),
                          _buildAxisColumn(
                              'Bz', compassProvider.magnetometerEvent.z),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        appLocalizations.parallelToGround,
                        style: TextStyle(
                          color: blackTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAxisSelector(context, 'X', 'X axis'),
                          _buildAxisSelector(context, 'Y', 'Y axis'),
                          _buildAxisSelector(context, 'Z', 'Z axis'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAxisColumn(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: blackTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: blackTextColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAxisSelector(BuildContext context, String axis, String label) {
    return Consumer<CompassProvider>(
        builder: (context, compassProvider, child) {
      return Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup(
              groupValue: compassProvider.selectedAxis,
              onChanged: (String? value) {
                if (value != null) {
                  compassProvider.onAxisSelected(value);
                }
              },
              child: Radio<String>(
                value: axis,
                activeColor: radioButtonActiveColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: compassProvider.selectedAxis == axis
                    ? radioButtonActiveColor
                    : blackTextColor,
                fontWeight: compassProvider.selectedAxis == axis
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    });
  }
}
