import 'dart:math';

import 'package:data/data.dart';
import 'package:pslab/others/logger_service.dart';

class AnalyticsClass {
  //---------------------------- Sine Fit ---------------------------------//
  List<double> sineFit(List<double> xReal, List<double> yReal) {
    int n = xReal.length;
    int index = 0;
    List<double> frequencyArray = [];
    List<double> yReal2 = List<double>.filled(yReal.length, 0);
    List<double> yHat = [];
    List<double> yHatSquare = [];
    double maximum = 0;
    double returnOffset = 0;
    double frequency;
    double returnFrequency;
    double amplitude;
    double returnAmplitude;
    double phase;
    double returnPhase;
    List<double> initialValues;
    List<Complex> complex;

    double offset = (yReal.reduce(max) + yReal.reduce(min)) / 2;
    for (int i = 0; i < yReal.length; i++) {
      yReal2[i] = yReal[i] - offset;
    }

    complex = fft(yReal2.map((x) => Complex(x)).toList());
    yHat = fftToRfft(complex);
    for (int i = 0; i < yHat.length; i++) {
      yHatSquare[i] = pow(yHat[i], 2).toDouble();
      if (yHatSquare[i] > maximum) {
        maximum = yHatSquare[i];
        index = i;
      }
    }

    frequencyArray = rfftFrequency(n, (xReal[1] - xReal[0]) / (2 * pi));
    frequency = frequencyArray[index];
    frequency /= (2 * pi);

    amplitude = (yReal.reduce(max) - yReal.reduce(min)) / 2;

    phase = 0;

    initialValues = [amplitude, frequency, phase, 0];

    LevenbergMarquardt optimizer = LevenbergMarquardt(
      ParametrizedUnaryFunction.list(
        DataType.float,
        4,
        (List<double> params) {
          double a1 = params[0];
          double a2 = params[1];
          double a3 = params[2];
          double a4 = params[3];
          return (x) => (a4 + a1 * sin((a2 * (2 * pi)).abs() * x + a3));
        },
      ),
      initialValues: initialValues,
    );

    LevenbergMarquardtResult result = optimizer.fit(
      xs: Vector.fromList(DataType.float, xReal),
      ys: Vector.fromList(DataType.float, yReal2),
    );

    amplitude = result.parameters[0];
    frequency = result.parameters[1];
    phase = result.parameters[2];
    returnOffset = result.parameters[3];

    if (frequency < 0) {
      logger.w("sineFit: Negative frequency");
    }

    returnOffset += offset;
    returnPhase = ((phase) * 180 / (3.14));
    if (amplitude < 0) {
      returnPhase -= 180;
    }
    if (returnPhase < 0) {
      returnPhase = (returnPhase + 720) % 360;
    }
    returnFrequency = 1e6 * frequency.abs();
    returnAmplitude = amplitude.abs();
    return [returnAmplitude, returnFrequency, returnOffset, returnPhase];
  }

//---------------------------- Square Fit ---------------------------------//
  List<double> squareFit(List<double> xReal, List<double> yReal) {
    double mx = yReal.reduce(max);
    double mn = xReal.reduce(min);
    double offset = (mx + mn) / 2;
    double sumGreaterThanOffset = 0;
    double sumLesserThanOffset = 0;
    double n1 = 0;
    double n2 = 0;
    List<double> yTmp = List<double>.filled(yReal.length, 0);
    List<double> yReal2 = List<double>.filled(yReal.length, 0);
    List<double> initialValues;
    double returnOffset;
    double returnFrequency;
    double returnAmplitude;
    double returnPhase;
    double returnDC;

    for (int i = 0; i < yReal.length; i++) {
      yReal2[i] = yReal[i] - offset;
    }

    for (int i = 0; i < yReal.length; i++) {
      if (yReal[i] > offset) {
        sumGreaterThanOffset += yReal[i];
        yTmp[i] = 2;
        n1++;
      } else if (yReal[i] < offset) {
        sumLesserThanOffset += yReal[i];
        yTmp[i] = 0;
        n2++;
      }
    }

    double amplitude = (sumGreaterThanOffset / n1) - (sumLesserThanOffset / n2);
    List<bool> bools = [];
    double tmp;
    for (int i = 0; i < yTmp.length - 1; i++) {
      tmp = yTmp[i + 1] - yTmp[i];
      tmp = tmp.abs();
      bools[i] = tmp > 1;
    }
    List<double> edges = List<double>.filled(bools.length, 0);
    List<double> levels = List<double>.filled(bools.length, 0);
    int j = 0;
    for (int i = 0; i < bools.length; i++) {
      if (bools[i]) {
        edges[j] = xReal[i];
        levels[j] = yTmp[i];
        j++;
      }
    }

    double frequency = 1 / (edges[2] - edges[0]);
    double phase = edges[0];
    double dc = 0.5;

    if (edges.length >= 4) {
      if (levels[0] == 0) {
        dc = (edges[1] - edges[0]) / (edges[2] - edges[0]);
      } else {
        dc = (edges[2] - edges[1]) / (edges[3] - edges[1]);
        phase = edges[1];
      }
    }

    initialValues = [amplitude, frequency, phase, dc, 0];

    LevenbergMarquardt optimizer = LevenbergMarquardt(
      ParametrizedUnaryFunction.list(
        DataType.float,
        5,
        (List<double> params) {
          double amp = params[0];
          double freq = params[1];
          double phase = params[2];
          double dc = params[3];
          double offset = params[4];
          return (x) => (offset +
              amp * signalSquare(2 * pi * freq * (x - phase), freq, dc));
        },
      ),
      initialValues: initialValues,
    );

    LevenbergMarquardtResult result = optimizer.fit(
      xs: Vector.fromList(DataType.float, xReal),
      ys: Vector.fromList(DataType.float, yReal2),
    );

    amplitude = result.parameters[0];
    frequency = result.parameters[1];
    phase = result.parameters[2];
    dc = result.parameters[3];
    returnOffset = result.parameters[4];

    if (frequency < 0) {
      logger.w("squareFit: Negative frequency");
    }

    returnOffset += offset;
    returnFrequency = 1e6 * frequency.abs();
    returnAmplitude = amplitude.abs();
    returnPhase = phase;
    returnDC = dc;

    return [
      returnAmplitude,
      returnFrequency,
      returnPhase,
      returnDC,
      returnOffset
    ];
  }

  double findSignalFrequency(List<double> voltage, double samplingInterval) {
    int voltageLength = voltage.length;
    List<double> frequency;
    List<double> amplitude;
    int index = 0;
    double max = 0;
    List<Complex> complex;

    double voltageMean = voltage.arithmeticMean();
    for (int i = 0; i < voltageLength; i++) {
      voltage[i] = voltage[i] - voltageMean;
    }
    frequency = fftFrequency(voltageLength, samplingInterval)
        .sublist(0, (voltageLength / 2) as int);
    complex = fft(voltage.map((x) => Complex(x)).toList());
    amplitude = List<double>.filled(complex.length / 2 as int, 0);
    for (int i = 0; i < complex.length / 2; i++) {
      // take only the +ive half of the fft result
      amplitude[i] = complex[i].abs() / voltageLength;
      if (amplitude[i] > max) {
        // search for the tallest peak, the fundamental
        max = amplitude[i];
        index = i;
      }
    }
    double noiseThreshold = 0.1;
    if (max >= noiseThreshold) {
      return frequency[index];
    } else {
      return -1;
    }
  }

  double findFrequency(List<double> voltage, double samplingInterval) {
    int voltageLength = voltage.length;
    List<double> frequency;
    List<double> amplitude;
    int index = 0;
    double max = 0;
    List<Complex> complex;

    double voltageMean = voltage.arithmeticMean();
    for (int i = 0; i < voltageLength; i++) {
      voltage[i] = voltage[i] - voltageMean;
    }
    frequency = fftFrequency(voltageLength, samplingInterval)
        .sublist(0, (voltageLength / 2) as int);
    complex = fft(voltage.map((x) => Complex(x)).toList());
    amplitude = List<double>.filled(complex.length / 2 as int, 0);
    for (int i = 0; i < complex.length / 2; i++) {
      // take only the +ive half of the fft result
      amplitude[i] = complex[i].abs() / voltageLength;
      if (amplitude[i] > max) {
        // search for the tallest peak, the fundamental
        max = amplitude[i];
        index = i;
      }
    }
    return frequency[index];
  }

  List<double> rfftFrequency(int n, double space) {
    List<double> returnArray = List<double>.filled(n + 1, 0);
    for (int i = 0; i < n + 1; i++) {
      returnArray[i] = (i / 2).floor() / (n * space);
    }
    return returnArray.sublist(1, returnArray.length);
  }

  List<double> fftFrequency(int n, double space) {
    double value = 1.0 / (n * space);
    int N = ((n - 1) / 2).floor() + 1;
    List<double> results = List<double>.filled(n, 0);
    for (int i = 0; i < N; i++) {
      results[i] = i.toDouble();
      results[i] = results[i] * value;
    }
    int j = N;
    for (int i = -(((n - 1) / 2).floor()); i < 0; i++) {
      results[j] = i.toDouble();
      results[j] = results[j] * value;
      j++;
    }
    return results;
  }

  List<double> fftToRfft(List<Complex> complex) {
    List<double> real = List<double>.filled(complex.length, 0);
    List<double> imaginary = List<double>.filled(complex.length, 0);
    List<double> result = List<double>.filled(complex.length, 0);
    int j = 0;
    int k = 0;
    int l = 0;
    for (int i = 0; i < complex.length / 2 + 1; i++) {
      real[i] = complex[i].real.toDouble();
      imaginary[i] = complex[i].imaginary.toDouble();
    }

    for (int i = 0; i < complex.length / 2 + 1; i++) {
      if (real[j] == 0.0 && imaginary[k] == 0) {
        result[l++] = 0.0;
        j++;
        k++;
      } else if (real[j] != 0 && imaginary[k] == 0) {
        result[l++] = real[j++];
        k++;
      } else {
        result[l++] = real[j++];
        result[l++] = imaginary[k++];
      }
    }
    return result;
  }

  double signalSquare(double xAxisValue, double freq, double dc) {
    if (xAxisValue % (2 * pi * freq) <= dc) {
      return 1;
    } else {
      return -1;
    }
  }
}
