class CommandsProto {
  int acknowledge = 254;
  int maxSamples = 10000;
  int dataSplitting = 60;

  int flash = 1;
  int readFlash = 1;
  int writeFlash = 2;
  int writeBulkFlash = 3;
  int readBulkFlash = 4;

  int adc = 2;
  int captureOne = 1;
  int captureTwo = 2;
  int captureDmaSpeed = 3;
  int captureFour = 4;
  int configureTrigger = 5;
  int getCaptureStatus = 6;
  int getCaptureChannel = 7;
  int setPgaGain = 8;
  int getVoltage = 9;
  int getVoltageSummed = 10;
  int startAdcStreaming = 11;
  int selectPgaChannel = 12;
  int capture12Bit = 13;
  int captureMultiple = 14;
  int setHiCapture = 15;
  int setLoCapture = 16;

  int multipointCapacitance = 20;
  int setCap = 21;
  int pulseTrain = 22;

  int spiHeader = 3;
  int startSpi = 1;
  int sendSpi8 = 2;
  int sendSpi16 = 3;
  int stopSpi = 4;
  int setSpiParameters = 5;
  int sendSpi8Burst = 6;
  int sendSpi16Burst = 7;

  int i2cHeader = 4;
  int i2cStart = 1;
  int i2cSend = 2;
  int i2cStop = 3;
  int i2cRestart = 4;
  int i2cReadEnd = 5;
  int i2cReadMore = 6;
  int i2cWait = 7;
  int i2cSendBurst = 8;
  int i2cConfig = 9;
  int i2cStatus = 10;
  int i2cReadBulk = 11;
  int i2cWriteBulk = 12;
  int i2cEnableSmbus = 13;
  int i2cInit = 14;
  int i2cPulldownScl = 15;
  int i2cDisableSmbus = 16;
  int i2cStartScope = 17;

  int uart2 = 5;
  int sendByte = 1;
  int sendInt = 2;
  int sendAddress = 3;
  int setBaud = 4;
  int setMode = 5;
  int readByte = 6;
  int readInt = 7;
  int readUart2Status = 8;

  int dac = 6;
  int setDac = 1;
  int setCalibratedDac = 2;

  int wavegen = 7;
  int setWg = 1;
  int setSqr1 = 3;
  int setSqr2 = 4;
  int setSqrs = 5;
  int tuneSineOscillator = 6;
  int sqr4 = 7;
  int mapReference = 8;
  int setBothWg = 9;
  int setWaveformType = 10;
  int selectFreqRegister = 11;
  int delayGenerator = 12;
  int setSine1 = 13;
  int setSine2 = 14;

  int loadWaveform1 = 15;
  int loadWaveform2 = 16;
  int sqr1Pattern = 17;

  int dout = 8;
  int setState = 1;

  int din = 9;
  int getState = 1;
  int getStates = 2;

  int la1 = 0;
  int la2 = 1;
  int la3 = 2;
  int la4 = 3;
  int lmeter = 4;

  int timing = 10;
  int getTiming = 1;
  int getPulseTime = 2;
  int getDutyCycle = 3;
  int startOneChanLa = 4;
  int startTwoChanLa = 5;
  int startFourChanLa = 6;
  int fetchDmaData = 7;
  int fetchIntDmaData = 8;
  int fetchLongDmaData = 9;
  int getLaProgress = 10;
  int getInitialDigitalStates = 11;

  int timingMeasurements = 12;
  int intervalMeasurements = 13;
  int configureComparator = 14;
  int startAlternateOneChanLa = 15;
  int startThreeChanLa = 16;
  int stopLa = 17;

  int common = 11;
  int getCtmVoltage = 1;
  int getCapacitance = 2;
  int getFrequency = 3;
  int getInductance = 4;
  int getVersion = 5;
  int retrieveBuffer = 8;
  int getHighFrequency = 9;
  int clearBuffer = 10;
  int setRgb1 = 11;
  int readProgramAddress = 12;
  int writeProgramAddress = 13;
  int readDataAddress = 14;
  int writeDataAddress = 15;
  int getCapRange = 16;
  int setRgb2 = 17;
  int readLog = 18;
  int restoreStandalone = 19;
  int getAlternateHighFrequency = 20;
  int setRgb3 = 22;
  int startCtm = 23;
  int stopCtm = 24;
  int startCounting = 25;
  int fetchCount = 26;
  int fillBuffer = 27;

  int setBaudrate = 12;
  int baud9600 = 1;
  int baud14400 = 2;
  int baud19200 = 3;
  int baud28800 = 4;
  int baud38400 = 5;
  int baud57600 = 6;
  int baud115200 = 7;
  int baud230400 = 8;
  int baud1000000 = 9;

  int nrfl01 = 13;
  int nrfSetup = 1;
  int nrfRxMode = 2;
  int nrfTxMode = 3;
  int nrfPowerDown = 4;
  int nrfRxChar = 5;
  int nrfTxChar = 6;
  int nrfHasData = 7;
  int nrfFlush = 8;
  int nrfWriteReg = 9;
  int nrfReadReg = 10;
  int nrfGetStatus = 11;
  int nrfWriteCommand = 12;
  int nrfWritePayload = 13;
  int nrfReadPayload = 14;
  int nrfWriteAddress = 15;
  int nrfTransaction = 16;
  int nrfStartTokenManager = 17;
  int nrfStopTokenManager = 18;
  int nrfTotalTokens = 19;
  int nrfReports = 20;
  int nrfWriteReport = 21;
  int nrfDeleteReportRow = 22;
  int nrfWriteAddresses = 23;

  int nonStandardIo = 14;
  int hx711Header = 1;
  int hcsr04Header = 2;
  int am2302Header = 3;
  int tcd1304Header = 4;
  int stepperMotor = 5;

  int passThroughs = 15;
  int passUart = 1;

  int stopStreaming = 253;
}
