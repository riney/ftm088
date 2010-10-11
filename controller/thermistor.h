#include <math.h>

//Thermistor code tested with the following wiring:
//   (Ground)-----[Thermistor]------\ /------[10k ohm resistor]-----(+5vdc ref voltage)
//                               input pin

//Note that multipliers are in use for the SHH coefficients, due to limited
//floating point precision in the arduino environment.
// A ==      1,000 multiplier
// B ==     10,000 multiplier
// C == 10,000,000 multiplier

struct steinhart_hart_coefficient {
  double A;
  double B;
  double C;
};

double conversion_therm(double RawADC, steinhart_hart_coefficient curve_data) {
  long Resistance;  
  double LogR;
  double Kelvin;
  double Farenheit;
  long RefR = 10000;
  long RefV = 5;
  double Volts;
  int divA = 1000;
  int divB = 10000;
  long divC = 10000000;
 
  Volts = (RawADC / 1024) * RefV;
  Resistance = ((RefR * Volts) / (RefV - Volts));
  LogR = log(Resistance);
  Kelvin = 1 / ((curve_data.A / divA) + ((curve_data.B / divB) * LogR) + ((curve_data.C / divC) * LogR * LogR * LogR));
  Farenheit = (((Kelvin - 273.15) * 9.0)/ 5.0) + 32.0;
  return Farenheit;
}

