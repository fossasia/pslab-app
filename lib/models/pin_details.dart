import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class PinDetails {
  final String name;
  final String description;
  final Color pinColor;

  PinDetails(this.name, this.description, this.pinColor);

  static List<PinDetails> getAllPins(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return [
      PinDetails(l10n.pin_gnd_name, l10n.pin_gnd_desc, const Color(0xFF00FFFF)),
      PinDetails(l10n.pin_vdd_name, l10n.pin_vdd_desc, const Color(0xFF800080)),
      PinDetails(l10n.pin_vcc_name, l10n.pin_vcc_desc, const Color(0xFF00FF00)),
      PinDetails(l10n.pin_vin_name, l10n.pin_vin_desc, const Color(0xFF505050)),
      PinDetails(l10n.pin_up_name, l10n.pin_up_desc, const Color(0xFF606060)),
      PinDetails(
          l10n.pin_down_name, l10n.pin_down_desc, const Color(0xFF707070)),
      PinDetails(l10n.pin_bat_name, l10n.pin_bat_desc, const Color(0xFF808080)),
      PinDetails(l10n.pin_rxd_name, l10n.pin_rxd_desc, const Color(0xFFFF7F2A)),
      PinDetails(l10n.pin_txd_name, l10n.pin_txd_desc, const Color(0xFFFFB380)),
      PinDetails(l10n.pin_enp_name, l10n.pin_enp_desc, const Color(0xFFFF9955)),
      PinDetails(l10n.pin_mcl_name, l10n.pin_mcl_desc, const Color(0xFFFF0066)),
      PinDetails(l10n.pin_pgd_name, l10n.pin_pgd_desc, const Color(0xFFD40055)),
      PinDetails(l10n.pin_pgc_name, l10n.pin_pgc_desc, const Color(0xFFAA0044)),
      PinDetails(l10n.pin_ena_name, l10n.pin_ena_desc, const Color(0xFF777777)),
      PinDetails(l10n.pin_sta_name, l10n.pin_sta_desc, const Color(0xFF888888)),
      PinDetails(l10n.pin_cs1_name, l10n.pin_cs1_desc, const Color(0xFF000080)),
      PinDetails(l10n.pin_sdi_name, l10n.pin_sdi_desc, const Color(0xFFC8B7BE)),
      PinDetails(l10n.pin_sdo_name, l10n.pin_sdo_desc, const Color(0xFF916F7C)),
      PinDetails(l10n.pin_sck_name, l10n.pin_sck_desc, const Color(0xFFAC939D)),
      PinDetails(l10n.pin_sda_name, l10n.pin_sda_desc, const Color(0xFFF4D7E3)),
      PinDetails(l10n.pin_scl_name, l10n.pin_scl_desc, const Color(0xFFE9AFC6)),
      PinDetails(l10n.pin_pcs_name, l10n.pin_pcs_desc, const Color(0xFF5FBCD3)),
      PinDetails(l10n.pin_pv3_name, l10n.pin_pv3_desc, const Color(0xFFD7EEF4)),
      PinDetails(l10n.pin_pv2_name, l10n.pin_pv2_desc, const Color(0xFFAFDDE9)),
      PinDetails(l10n.pin_pv1_name, l10n.pin_pv1_desc, const Color(0xFF87CDDE)),
      PinDetails(l10n.pin_si1_name, l10n.pin_si1_desc, const Color(0xFFF4D7EE)),
      PinDetails(l10n.pin_si2_name, l10n.pin_si2_desc, const Color(0xFFE9AFDD)),
      PinDetails(l10n.pin_sq1_name, l10n.pin_sq1_desc, const Color(0xFFDE87CD)),
      PinDetails(l10n.pin_sq2_name, l10n.pin_sq2_desc, const Color(0xFFD35FBC)),
      PinDetails(l10n.pin_sq3_name, l10n.pin_sq3_desc, const Color(0xFFC837AB)),
      PinDetails(l10n.pin_sq4_name, l10n.pin_sq4_desc, const Color(0xFFA02C89)),
      PinDetails(l10n.pin_la1_name, l10n.pin_la1_desc, const Color(0xFFD5FFE6)),
      PinDetails(l10n.pin_la2_name, l10n.pin_la2_desc, const Color(0xFFAAFFCC)),
      PinDetails(l10n.pin_la3_name, l10n.pin_la3_desc, const Color(0xFF80FFB3)),
      PinDetails(l10n.pin_la4_name, l10n.pin_la4_desc, const Color(0xFF55FF99)),
      PinDetails(l10n.pin_ch1_name, l10n.pin_ch1_desc, const Color(0xFFAACCFF)),
      PinDetails(l10n.pin_ch2_name, l10n.pin_ch2_desc, const Color(0xFF80B3FF)),
      PinDetails(l10n.pin_ch3_name, l10n.pin_ch3_desc, const Color(0xFF5599FF)),
      PinDetails(l10n.pin_ac1_name, l10n.pin_ac1_desc, const Color(0xFF0000FF)),
      PinDetails(l10n.pin_chg_name, l10n.pin_chg_desc, const Color(0xFF6600FF)),
      PinDetails(l10n.pin_mic_name, l10n.pin_mic_desc, const Color(0xFF7F2AFF)),
      PinDetails(l10n.pin_frq_name, l10n.pin_frq_desc, const Color(0xFF9955FF)),
      PinDetails(l10n.pin_vol_name, l10n.pin_vol_desc, const Color(0xFFE5D5FF)),
      PinDetails(l10n.pin_cap_name, l10n.pin_cap_desc, const Color(0xFFB380FF)),
      PinDetails(l10n.pin_res_name, l10n.pin_res_desc, const Color(0xFFCCAAFF)),
    ];
  }
}
