const int MAX_POINTS = 5;
const int IO_RATE = 500;       //Time between input and output interactions in ms
const int SERIAL_RATE = 2000;  //Time between serial updates on point data in ms


//Point Types
const int POINT_UNDEFINED = 0;
const int POINT_DINPUT = 1;
const int POINT_AINPUT = 2;
const int POINT_DOUTPUT = 3;

//Alarm Types
const int ALM_NONE = 0;           //No alarm defined
const int ALM_GRTRTHAN_AP1 = 1;   //Alarm when greater than AP1
const int ALM_LESSTHAN_AP1 = 2;   //Alarm when less than AP1
const int ALM_OOR_AP1_AP2 = 3;    //Alarm when out of range specified by AP1 and AP2

//Conversion Types
const int CONV_NONE = 0;
const int CONV_THERM_10K_Z = 1;

//Convenient point list index definitions here
const int TEC1_HOT_THERM = 0;

struct alarm_data {
  boolean value;     //Whether or not the alarm condition is true
  boolean state;     //Whether or not the alarm is enabled for checking
  int type;          //What type of alarm check should be used
  float ap1;         //Alarm point data for comparison in checks
  float ap2;         //Alarm point data for comparison in checks
};
  
struct io_point {
  double value;      //Current value of the point
  byte precision;     //Digits of precision when printing value
  char name[32];     //Text name of the point for reference, 16 chars max
  int pin;           //Arduino pin number
  int type;          //Type of point, analog/digital input/output
  int conv_type;     //Type of conversion from raw read value to engineering units
  alarm_data alarm;
};

io_point points[MAX_POINTS];
unsigned long last_io_update;
unsigned long last_serial_update;
unsigned long current_time;
int serial_count;  //counter to step through point list for serial updates

void initialize_pointlist() {
  int i = 0;
  while (i < MAX_POINTS) {
    points[i].value = 0;
    points[i].precision = 0;
    strlcpy(points[i].name, "UNDEFINED", sizeof(points[i].name));
    points[i].pin = 0;
    points[i].type = POINT_UNDEFINED;
    points[i].conv_type = CONV_NONE;
    points[i].alarm.value = false;
    points[i].alarm.state = false;
    points[i].alarm.type = ALM_NONE;
    points[i].alarm.ap1 = 0;
    points[i].alarm.ap2 = 0;
    i++;
  }
  return;
}

//This is where new points will be added, in load_pointlist().  Note that if you add points you should
//always double check the defined MAX_POINTS at the head of this sketch.

void load_pointlist() {
  points[0].value = 0;
  points[0].precision = 1;
  strlcpy(points[0].name, "TEC1 Hot Therm", sizeof(points[0].name));
  points[0].pin = 0;
  points[0].type = POINT_AINPUT;
  points[0].conv_type = CONV_THERM_10K_Z;
  points[0].alarm.value = false;
  points[0].alarm.state = false;
  points[0].alarm.type = ALM_NONE;
  points[0].alarm.ap1 = 0;
  points[0].alarm.ap2 = 0;
  return;
}
  
void configure_points() {
  int i = 0;
  while (i < MAX_POINTS) {
    switch (points[i].type) {
      case POINT_DINPUT:
        pinMode(points[i].pin, INPUT);
        break;
      case POINT_AINPUT:
        //No actual pin config needed for analog inputs
        //Unless some are being used as extra digitals
        //Cross that bridge if we come to it
        break;
      case POINT_DOUTPUT:
        pinMode(points[i].pin, OUTPUT);
        break;
      default:
        break;
    }
    i++;
  }
}

double conversion_therm_10k_z(double RawADC) {
  long Resistance;  
  double LogR;
  double Kelvin;
  double Farenheit;
  double A = 0.001124963847380;
  double B = 0.000234766149049;
  double C = 0.000000085609586;
  long RefR = 10000;
  long RefV = 5;
  double Volts;
 
  Volts = (RawADC / 1024) * RefV;
  Resistance = ((RefR * Volts) / (RefV - Volts));
  LogR = log(Resistance);
  Kelvin = 1 / (A + (B * LogR) + (C * LogR * LogR * LogR));
  Farenheit = (((Kelvin - 273.15) * 9.0)/ 5.0) + 32.0;
  return Farenheit;
}

void do_input_update() {
  //input gather here
  int i = 0;
  double raw_input = 0;
  while (i < MAX_POINTS) {
    switch (points[i].type) {
      case POINT_AINPUT:
        //read the analog input
        raw_input = analogRead(points[i].pin);
        //perform any required conversion
        switch (points[i].conv_type) {
          case CONV_THERM_10K_Z:
            points[i].value = conversion_therm_10k_z(raw_input);
            break;
          default:
            points[i].value = raw_input;
            break;
        }
        break;
      case POINT_DINPUT:
        //read the digital input
        //perform any required conversion
        break;
      default:
        break;
    }
    i++;
  }
  return;
}

void do_alarm_update() {
  //alarm condition checks here
  return;
}

void do_actuation_logic() {
  //io actuation logic processed here
  return;
}

void do_output_update() {
  //use values to set output pin states here
  return;
}

void do_serial_update() {
  //report on one point per pass here, stepping through the full array
  //until encountering an unconfigured point in the array or running to the end.
  int serial_initial = serial_count;
  while ((serial_count < MAX_POINTS) && (points[serial_count].type == POINT_UNDEFINED)) {
    serial_count++;
  }
  
  //If we ran to the end, then start over and scan up to the initial starting point
  if (serial_count >= MAX_POINTS) {
    serial_count = 0;
    while ((serial_count <= serial_initial) && (points[serial_count].type == POINT_UNDEFINED)) {
      serial_count++;
    }
  }
  
  //Print an output line with the point name, a pad of '.'s, and then the value formatted
  //to the correct precision.
  debug("PrimaryIO - ");
  debug(points[serial_count].name);
  int i = 0;
  int strlen = sizeof(points[serial_count].name);
  while (i <= (36 - strlen)) {
    debug(".");
    i++;
  }
  debugDouble(points[serial_count].value, points[serial_count].precision);
  debugln("");
  
  //Increment serial_count for the next pass
  serial_count++;

  return;
}


void init_primaryio() {
 //Serial.begin(9600);
 debugln("PrimaryIO - Begin initialization.");
 initialize_pointlist();
 debugln("PrimaryIO - Load point attributes.");
 load_pointlist();
 debugln("PrimaryIO - Configure IO pins.");
 configure_points();
 last_io_update = 0;
 last_serial_update = 0;
 serial_count = 0;
 debugln("PrimaryIO - Initialization complete.");
}

void update_primaryio() {
  current_time = millis();
  //millis() overflows about every 50 days and resets to 0.  Should never be an issue, but
  //including a rough hack to reset timing just in case.  Considered a more accurate fix to retain
  //timing since last update, but it just isn't worth fooling with in this case.
  if (current_time < last_io_update) {
    last_io_update = 0;
    last_serial_update = 0;
  }
    
  if (current_time >= (last_io_update + IO_RATE)) {
    do_input_update();
    do_alarm_update();
    do_actuation_logic();
    do_output_update();
    last_io_update = current_time;
  }
  if (current_time >= (last_serial_update + SERIAL_RATE)) {
    do_serial_update();
    last_serial_update = current_time;
  }
}
  
