//Add the SdFat Libraries
#include <SdFat.h>
#include <SdFatUtil.h> 
#include <ctype.h>

//Create the variables to be used by SdFat Library
Sd2Card card;
SdVolume volume;
SdFile root;
SdFile logfile;


char logfile_name[] = "FTM88log.csv";     //Create an array that contains the name of our file.

void init_microsd() {  
  if (USE_LOG_SHIELD) {
    pinMode(10, OUTPUT);       //Pin 10 must be set as an output for the SD communication to work.
    card.init();               //Initialize the SD card and configure the I/O pins.
    volume.init(card);         //Initialize a volume on the SD card.
    root.openRoot(volume);     //Open the root directory in the volume. 
    debugln("MicroSD Card Init Complete");
  } else {
    debugln("Logging shield not enabled - skipping initialization of microSD.");
  }
}

void sdwrite(const char data[]) {
  logfile.open(root, logfile_name, O_CREAT | O_APPEND | O_WRITE);    //Open or create the file 'name' in 'root' for writing to the end of the file.
  logfile.print(data);    //Write the 'contents' array to the end of the file.
  logfile.close();            //Close the file.
}

void formatDouble(char buf[], double val, byte precision) {
  // prints val with number of decimal places determine by precision
  // precision is a number from 0 to 6 indicating the desired decimal places
  // example: printDouble(3.1415, 2); // prints 3.14 (two decimal places)
  sprintf(buf, "%d", (int(val)));  //prints the int part
  if( precision > 0) {
    //DEBUG_PORT.print("."); // print the decimal point
    sprintf(buf, "%s%s", buf, ".");
    unsigned long frac, mult = 1;
    byte padding = precision -1;
    while(precision--) mult *=10;
    if(val >= 0) frac = (val - int(val)) * mult; else frac = (int(val) - val) * mult;
    unsigned long frac1 = frac;
    while(frac1 /= 10) padding--;
    while(padding--) sprintf(buf, "%s0", buf);
    sprintf(buf, "%s%d", buf, frac);
  }
}


void log_point(const int point_index) {
  char valbuffer[32];
  char logbuffer[256];
  if ((points[point_index].type == POINT_DOUTPUT) or (points[point_index].type == POINT_DINPUT)) {
    if (is_on(points[point_index].value)) {
      sprintf(valbuffer, "On");
    } else {
      sprintf(valbuffer, "Off");
    }
  } else {
    formatDouble(valbuffer, points[point_index].value, points[point_index].precision);
  }
  sprintf(logbuffer, "%d/%d/%d %d:%d:%d, %s, %s\n", real_time.month(), real_time.day(), real_time.year(), real_time.hour(), real_time.minute(), real_time.second(), points[point_index].name, valbuffer);
  sdwrite(logbuffer);
  debug("Wrote log data:  ");
  debug(logbuffer);
}
      

