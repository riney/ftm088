#define DEBUG_PORT Serial
const int DEBUG_BAUD = 9600;

void init_debug(void) {
  DEBUG_PORT.begin(DEBUG_BAUD);
}

void debug(const char c[]) {
  DEBUG_PORT.print(c);
}

void debug(int c) {
  DEBUG_PORT.print(c, BYTE);
}

void debugln(const char c[]) {
  DEBUG_PORT.println(c);
}

void debugDouble(double val, byte precision) {
  // prints val with number of decimal places determine by precision
  // precision is a number from 0 to 6 indicating the desired decimal places
  // example: printDouble(3.1415, 2); // prints 3.14 (two decimal places)
  DEBUG_PORT.print(int(val));  //prints the int part
  if( precision > 0) {
    DEBUG_PORT.print("."); // print the decimal point
    unsigned long frac, mult = 1;
    byte padding = precision -1;
    while(precision--) mult *=10;
    if(val >= 0) frac = (val - int(val)) * mult; else frac = (int(val) - val) * mult;
    unsigned long frac1 = frac;
    while(frac1 /= 10) padding--;
    while(padding--) DEBUG_PORT.print("0");
    DEBUG_PORT.print(frac,DEC) ;
  }
}
