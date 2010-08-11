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
 
  Volts = (RawADC / 1024) * RefV;
  Resistance = ((RefR * Volts) / (RefV - Volts));
  LogR = log(Resistance);
  Kelvin = 1 / (curve_data.A + (curve_data.B * LogR) + (curve_data.C * LogR * LogR * LogR));
  Farenheit = (((Kelvin - 273.15) * 9.0)/ 5.0) + 32.0;
  return Farenheit;
}
