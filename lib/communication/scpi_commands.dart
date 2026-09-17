class ScpiCommands {
  // IEEE 488.2 Common Commands
  static const String reset = "*RST";
  static const String identify = "*IDN?";
  static const String test = "*TST?";
  static const String clearStatus = "*CLS";
  static const String eventStatusEnable = "*ESE";
  static const String eventStatusEnableQuery = "*ESE?";
  static const String eventStatusRegisterQuery = "*ESR?";
  static const String operationComplete = "*OPC";
  static const String operationCompleteQuery = "*OPC?";
  static const String serviceRequestEnable = "*SRE";
  static const String serviceRequestEnableQuery = "*SRE?";
  static const String statusByteQuery = "*STB?";
  static const String wait = "*WAI";
  static const String systemErrorNextQuery = "SYST:ERR:NEXT?";
  static const String systemErrorCountQuery = "SYST:ERR:COUN?";
  static const String systemVersionQuery = "SYST:VERS?";

  // Communication & Transport
  static const String commTransport = "COMM:TRAN";
  static const String commTransportQuery = "COMM:TRAN?";
  static const String commWifiStatusQuery = "COMM:WIFI:STAT?";

  // Digital Multimeter (DMM) / DC Voltage
  static const String measureVoltageDcQuery = "MEAS:VOLT:DC?";
  static const String configureVoltageDc = "CONF:VOLT:DC";
  static const String initiateVoltageDc = "INIT:VOLT:DC";
  static const String fetchVoltageDcQuery = "FETC:VOLT:DC?";
  static const String readVoltageDcQuery = "READ:VOLT:DC?";

  // Logic Analyzer (LA)
  static const String laConfigurePinBase = "LA:CONF:PINB";
  static const String laConfigurePinBaseQuery = "LA:CONF:PINB?";
  static const String laConfigurePinCount = "LA:CONF:PINC";
  static const String laConfigurePinCountQuery = "LA:CONF:PINC?";
  static const String laConfigureSamples = "LA:CONF:SAMP";
  static const String laConfigureSamplesQuery = "LA:CONF:SAMP?";
  static const String laConfigureDivider = "LA:CONF:DIV";
  static const String laConfigureDividerQuery = "LA:CONF:DIV?";
  static const String laConfigureRateQuery = "LA:CONF:RATE?";

  static const String laConfigureTriggerPin = "LA:CONF:TRIG:PIN";
  static const String laConfigureTriggerPinQuery = "LA:CONF:TRIG:PIN?";
  static const String laConfigureTriggerLevel = "LA:CONF:TRIG:LEV";
  static const String laConfigureTriggerLevelQuery = "LA:CONF:TRIG:LEV?";
  static const String laConfigureTriggerMode = "LA:CONF:TRIG:MODE";
  static const String laConfigureTriggerModeQuery = "LA:CONF:TRIG:MODE?";

  static const String laInitiate = "LA:INIT";
  static const String laFetchDataQuery = "LA:FETC?";
  static const String laReadQuery = "LA:READ?";
  static const String laStatusQuery = "LA:STAT?";
  static const String laMetadataQuery = "LA:MET?";

  static const String laStreamStart = "LA:STREAM:STAR";
  static const String laStreamStop = "LA:STREAM:STOP";
  static const String laStreamStatusQuery = "LA:STREAM:STAT?";
  static const String laWifiReadQuery = "LA:WIFI:READ?";

  // Oscilloscope (DSO)
  static const String dsoConfigureChannel = "DSO:CONF:CHAN";
  static const String dsoConfigureChannelQuery = "DSO:CONF:CHAN?";
  static const String dsoConfigureGpioQuery = "DSO:CONF:GPIO?";
  static const String dsoConfigureSamples = "DSO:CONF:SAMP";
  static const String dsoConfigureSamplesQuery = "DSO:CONF:SAMP?";
  static const String dsoConfigureRate = "DSO:CONF:RATE";
  static const String dsoConfigureRateQuery = "DSO:CONF:RATE?";

  static const String dsoConfigureTriggerLevel = "DSO:CONF:TRIG:LEV";
  static const String dsoConfigureTriggerLevelQuery = "DSO:CONF:TRIG:LEV?";
  static const String dsoConfigureTriggerMode = "DSO:CONF:TRIG:MODE";
  static const String dsoConfigureTriggerModeQuery = "DSO:CONF:TRIG:MODE?";
  static const String dsoConfigureTriggerSlope = "DSO:CONF:TRIG:SLOP";
  static const String dsoConfigureTriggerSlopeQuery = "DSO:CONF:TRIG:SLOP?";

  static const String dsoInitiate = "DSO:INIT";
  static const String dsoFetchDataQuery = "DSO:FETC?";
  static const String dsoReadQuery = "DSO:READ?";
  static const String dsoStatusQuery = "DSO:STAT?";

  static const String dsoStreamStart = "DSO:STREAM:STAR";
  static const String dsoStreamStop = "DSO:STREAM:STOP";
  static const String dsoStreamStatusQuery = "DSO:STREAM:STAT?";
  static const String dsoWifiReadQuery = "DSO:WIFI:READ?";

  // Mixed-Signal Oscilloscope (MSO)
  static const String msoConfigureDigitalPinBase = "MSO:CONF:DIG:PINB";
  static const String msoConfigureDigitalPinBaseQuery = "MSO:CONF:DIG:PINB?";
  static const String msoConfigureDigitalPinCount = "MSO:CONF:DIG:PINC";
  static const String msoConfigureDigitalPinCountQuery = "MSO:CONF:DIG:PINC?";
  static const String msoConfigureAnalogChannel = "MSO:CONF:ANAL:CHAN";
  static const String msoConfigureAnalogChannelQuery = "MSO:CONF:ANAL:CHAN?";

  static const String msoConfigureSamples = "MSO:CONF:SAMP";
  static const String msoConfigureSamplesQuery = "MSO:CONF:SAMP?";
  static const String msoConfigureRate = "MSO:CONF:RATE";
  static const String msoConfigureRateQuery = "MSO:CONF:RATE?";

  static const String msoConfigureTriggerPin = "MSO:CONF:TRIG:PIN";
  static const String msoConfigureTriggerPinQuery = "MSO:CONF:TRIG:PIN?";
  static const String msoConfigureTriggerLevel = "MSO:CONF:TRIG:LEV";
  static const String msoConfigureTriggerLevelQuery = "MSO:CONF:TRIG:LEV?";
  static const String msoConfigureTriggerMode = "MSO:CONF:TRIG:MODE";
  static const String msoConfigureTriggerModeQuery = "MSO:CONF:TRIG:MODE?";

  static const String msoInitiate = "MSO:INIT";
  static const String msoFetchDigitalQuery = "MSO:FETC:DIG?";
  static const String msoFetchAnalogQuery = "MSO:FETC:ANAL?";
  static const String msoReadDigitalQuery = "MSO:READ:DIG?";
  static const String msoReadAnalogQuery = "MSO:READ:ANAL?";
  static const String msoStatusQuery = "MSO:STAT?";
  static const String msoMetadataQuery = "MSO:MET?";
  static const String msoWifiReadQuery = "MSO:WIFI:READ?";

  // Built-in Test Signals
  static const String testSquare = "TEST:SQU";
  static const String testSquareQuery = "TEST:SQU?";
  static const String testSquareConfigure = "TEST:SQU:CONF";
  static const String testSquarePinQuery = "TEST:SQU:PIN?";
  static const String testSquareFrequencyQuery = "TEST:SQU:FREQ?";

  static const String testAnalog = "TEST:ANAL";
  static const String testAnalogQuery = "TEST:ANAL?";
  static const String testAnalogConfigure = "TEST:ANAL:CONF";
  static const String testAnalogPinQuery = "TEST:ANAL:PIN?";
  static const String testAnalogFrequencyQuery = "TEST:ANAL:FREQ?";
  static const String testAnalogDutyQuery = "TEST:ANAL:DUTY?";

  // External Bus: I2C Gateway
  static const String busI2cOpen = "BUS:I2C:OPEN";
  static const String busI2cOpenQuery = "BUS:I2C:OPEN?";
  static const String busI2cClose = "BUS:I2C:CLOS";
  static const String busI2cConfigureBus = "BUS:I2C:CONF:BUS";
  static const String busI2cConfigureBusQuery = "BUS:I2C:CONF:BUS?";
  static const String busI2cConfigureRate = "BUS:I2C:CONF:RATE";
  static const String busI2cConfigureRateQuery = "BUS:I2C:CONF:RATE?";
  static const String busI2cConfigureAddress = "BUS:I2C:CONF:ADDR";
  static const String busI2cConfigureAddressQuery = "BUS:I2C:CONF:ADDR?";
  static const String busI2cConfigureTimeout = "BUS:I2C:CONF:TIME";
  static const String busI2cConfigureTimeoutQuery = "BUS:I2C:CONF:TIME?";
  static const String busI2cScanQuery = "BUS:I2C:SCAN?";
  static const String busI2cWrite = "BUS:I2C:WRIT";
  static const String busI2cReadQuery = "BUS:I2C:READ?";
  static const String busI2cTransactQuery = "BUS:I2C:TRAN?";

  // External Bus: UART Gateway
  static const String busUartOpen = "BUS:UART:OPEN";
  static const String busUartOpenQuery = "BUS:UART:OPEN?";
  static const String busUartClose = "BUS:UART:CLOS";
  static const String busUartConfigureBus = "BUS:UART:CONF:BUS";
  static const String busUartConfigureBusQuery = "BUS:UART:CONF:BUS?";
  static const String busUartConfigureBaud = "BUS:UART:CONF:BAUD";
  static const String busUartConfigureBaudQuery = "BUS:UART:CONF:BAUD?";
  static const String busUartConfigureTimeout = "BUS:UART:CONF:TIME";
  static const String busUartConfigureTimeoutQuery = "BUS:UART:CONF:TIME?";
  static const String busUartWrite = "BUS:UART:WRIT";
  static const String busUartReadQuery = "BUS:UART:READ?";
  static const String busUartAvailableQuery = "BUS:UART:AVAIL?";
  static const String busUartClear = "BUS:UART:CLE";
  static const String busUartFlush = "BUS:UART:FLUS";
  static const String busUartTransactQuery = "BUS:UART:TRAN?";
}
