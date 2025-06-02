import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/constants.dart';
import '../providers/compass_provider.dart';

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
        title: compassTitle,
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
                        style: const TextStyle(
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
                        parallelToGround,
                        style: const TextStyle(
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
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
            style: const TextStyle(
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
      bool isSelected = compassProvider.selectedAxis == axis;

      return GestureDetector(
        onTap: () => compassProvider.onAxisSelected(axis),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.red : Colors.grey,
                  width: 2,
                ),
                color: isSelected ? Colors.red : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.circle,
                      size: 10,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.red : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    });
  }
}
