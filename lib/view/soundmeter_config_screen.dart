import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/providers/Soundmeter_config_provider.dart';
import 'package:pslab/view/widgets/config_widgets.dart';
import '../theme/colors.dart';

class SoundMeterConfigScreen extends StatefulWidget {
  const SoundMeterConfigScreen({super.key});
  @override
  State<SoundMeterConfigScreen> createState() => _SoundMeterConfigScreenState();
}

class _SoundMeterConfigScreenState extends State<SoundMeterConfigScreen> {
  final TextEditingController _updatePeriodController = TextEditingController();
  final TextEditingController _highLimitController = TextEditingController();
  final TextEditingController _sensorGainController = TextEditingController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<SoundMeterConfigProvider>(context, listen: false);
    });
  }

  @override
  void dispose() {
    _updatePeriodController.dispose();
    _highLimitController.dispose();
    _sensorGainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: appBarColor),
        leading: Builder(builder: (context) {
          return IconButton(
            onPressed: () {
              if (Navigator.canPop(context) &&
                  ModalRoute.of(context)?.settings.name == '/Soundmeter') {
                Navigator.popUntil(context, ModalRoute.withName('/Soundmeter'));
              } else {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/Soundmeter',
                  (route) => route.isFirst,
                );
              }
            },
            icon: Icon(
              Icons.arrow_back,
              color: appBarContentColor,
            ),
          );
        }),
        backgroundColor: primaryRed,
        title: Text(
          'SoundmeterConfigurations',
          style: TextStyle(
            color: appBarContentColor,
            fontSize: 15,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Consumer<SoundMeterConfigProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                child: ConfigCheckboxItem(
                  title: locationData,
                  subtitle: locationDataHint,
                  value: provider.config.includeLocationData,
                  onChanged: (value) {
                    provider.updateIncludeLocationData(value);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
