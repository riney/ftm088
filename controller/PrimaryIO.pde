#include "thermistor.h"

const int MAX_POINTS = 15;
const int IO_RATE = 100;       //Time between input and output interactions in ms
const int SERIAL_RATE = 2000;  //Time between serial updates on point data in ms
const long LOGGING_RATE = 60000;  //Logging interval

//Note that multipliers are in use for the SHH coefficients, due to limited
//floating point precision in the arduino environment.
// A ==      1,000 multiplier
// B ==     10,000 multiplier
// C == 10,000,000 multiplier

steinhart_hart_coefficient conv_therm_10k_z = {
  1.124963847380,
  2.34766149049,
  0.85609586,
};

//Cantherm CWF3AA103G3380 (Digikey 317-1382-ND)
steinhart_hart_coefficient conv_therm_cantherm = {
  0.885276658,
  2.518587355,
  1.907486448,
};

//Epcos B57703M0103G040 (Digikey 495-2169-ND)
steinhart_hart_coefficient conv_therm_epcos = {
  1.125256672,
  2.347204473,
  0.856305273,
};

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

//Alarm Notification Bitflags
const int NOTIFY_NONE = 0;
const int NOTIFY_DEBUG = 1;
const int NOTIFY_LCD = 2;
const int NOTIFY_SMS = 4;
const int NOTIFY_LOG = 5;

//Conversion Types
const int CONV_NONE = 0;
const int CONV_THERM_10K_Z = 1;
const int CONV_THERM_CANTHERM = 2;
const int CONV_THERM_EPCOS = 3;

//Convenient point list index definitions here
const int ONBOARD_LED = 0;
const int TEC1_HOT_TEMP = 1;
const int TEC2_HOT_TEMP = 2;
const int COOLANT_TEMP = 3;
const int KEG_TEMP = 4;
const int PUMP_RELAY = 5;
const int FAN_RELAY = 6;
const int TEC1_RELAY = 7;
const int TEC2_RELAY = 8;
const int RUN_ENABLE = 9;

struct alarm_data {
  boolean value;     //Whether or not the alarm condition is true
  boolean state;     //Whether or not the alarm is enabled for checking
  int notify;        //Bitmask value for what types of notifications of the alarm (and return to normals) should be sent
  boolean sent;      //Whether or not the current condition of the alarm has been sent according to its notification level
  int type;          //What type of alarm check should be used
  float ap1;         //Alarm point data for comparison in checks
  float ap2;         //Alarm point data for comparison in checks
  float db;          //Deadband which must be overcome to have alarm return to normal
                     //  Ex: if alarming when > ap1 (40), with a db of 2, RTN would not occur until temp is < 38
};
  
struct io_point {
  double value;      //Current value of the point
  byte precision;     //Digits of precision when printing value
  char name[32];     //Text name of the point for reference, 16 chars max
  int pin;           //Arduino pin number
  int type;          //Type of point, analog/digital input/output
  int conv_type;     //Type of conversion from raw read value to engineering units
  boolean logged;    //Whether or not the point is logged to SD
  alarm_data alarm;
};

io_point points[MAX_POINTS];
unsigned long last_io_update;
unsigned long last_serial_update;
unsigned long last_log_update;
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
    points[i].logged = false;
    points[i].alarm.value = false;
    points[i].alarm.state = false;
    points[i].alarm.notify = NOTIFY_NONE;
    points[i].alarm.sent = true;                  //Note, initially set to true so we dont get "return to normal" messages from all points on initial runtime
    points[i].alarm.type = ALM_NONE;
    points[i].alarm.ap1 = 0;
    points[i].alarm.ap2 = 0;
    points[i].alarm.db = 0;
    i++;
  }
  return;
}

//This is where new points will be added, in load_pointlist().  Note that if you add points you should
//always double check the defined MAX_POINTS at the head of this sketch.

void load_pointlist() {
  
  strlcpy(points[0].name, "Onboard LED", sizeof(points[0].name));
  points[0].pin = 13;
  points[0].type = POINT_DOUTPUT;
  points[0].precision = 0;
  points[0].conv_type = CONV_NONE;
  points[0].logged = false;
  points[0].alarm.type = ALM_NONE;
  points[0].alarm.state = false;
  points[0].alarm.notify = NOTIFY_NONE;
  points[0].alarm.ap1 = 0;
  points[0].alarm.ap2 = 0;
  points[0].alarm.db = 0;
  
  strlcpy(points[1].name, "TEC1 Hot Temp", sizeof(points[1].name));
  points[1].pin = 8;
  points[1].type = POINT_AINPUT;
  points[1].precision = 1;
  points[1].conv_type = CONV_THERM_EPCOS;
  points[1].logged = true;
  points[1].alarm.type = ALM_NONE;
  points[1].alarm.state = false;
  points[1].alarm.notify = NOTIFY_NONE;
  points[1].alarm.ap1 = 0;
  points[1].alarm.ap2 = 0;
  points[1].alarm.db = 0;
  
  strlcpy(points[2].name, "TEC2 Hot Temp", sizeof(points[2].name));
  points[2].pin = 9;
  points[2].type = POINT_AINPUT;
  points[2].precision = 1;
  points[2].conv_type = CONV_THERM_EPCOS;
  points[2].logged = true;
  points[2].alarm.type = ALM_NONE;
  points[2].alarm.state = false;
  points[2].alarm.notify = NOTIFY_NONE;
  points[2].alarm.ap1 = 0;
  points[2].alarm.ap2 = 0;
  points[2].alarm.db = 0;
  
  strlcpy(points[3].name, "Reservoir Coolant Temp", sizeof(points[3].name));
  points[3].pin = 10;
  points[3].type = POINT_AINPUT;
  points[3].precision = 1;
  points[3].conv_type = CONV_THERM_CANTHERM;
  points[3].logged = true;
  points[3].alarm.type = ALM_NONE;
  points[3].alarm.state = false;
  points[3].alarm.notify = NOTIFY_NONE;
  points[3].alarm.ap1 = 0;
  points[3].alarm.ap2 = 0;
  points[3].alarm.db = 0;
  
  strlcpy(points[4].name, "Keg Temp", sizeof(points[4].name));
  points[4].pin = 11;
  points[4].type = POINT_AINPUT;
  points[4].precision = 1;
  points[4].conv_type = CONV_THERM_EPCOS;
  points[4].logged = true;
  points[4].alarm.type = ALM_NONE;
  points[4].alarm.state = false;
  points[4].alarm.notify = NOTIFY_NONE;
  points[4].alarm.ap1 = 0;
  points[4].alarm.ap2 = 0;
  points[4].alarm.db = 0;
  
  strlcpy(points[5].name, "Pump Relay", sizeof(points[5].name));
  points[5].pin = 22;
  points[5].type = POINT_DOUTPUT;
  points[5].precision = 0;
  points[5].conv_type = CONV_NONE;
  points[5].logged = true;
  points[5].alarm.type = ALM_NONE;
  points[5].alarm.state = false;
  points[5].alarm.notify = NOTIFY_NONE;
  points[5].alarm.ap1 = 0;
  points[5].alarm.ap2 = 0;
  points[5].alarm.db = 0;
  
  strlcpy(points[6].name, "Fan Relay", sizeof(points[6].name));
  points[6].pin = 24;
  points[6].type = POINT_DOUTPUT;
  points[6].precision = 0;
  points[6].conv_type = CONV_NONE;
  points[6].logged = true;
  points[6].alarm.type = ALM_NONE;
  points[6].alarm.state = false;
  points[6].alarm.notify = NOTIFY_NONE;
  points[6].alarm.ap1 = 0;
  points[6].alarm.ap2 = 0;
  points[6].alarm.db = 0;
  
  strlcpy(points[7].name, "TEC1 Relay", sizeof(points[7].name));
  points[7].pin = 26;
  points[7].type = POINT_DOUTPUT;
  points[7].precision = 0;
  points[7].conv_type = CONV_NONE;
  points[7].logged = true;
  points[7].alarm.type = ALM_NONE;
  points[7].alarm.state = false;
  points[7].alarm.notify = NOTIFY_NONE;
  points[7].alarm.ap1 = 0;
  points[7].alarm.ap2 = 0;
  points[7].alarm.db = 0;
  
  strlcpy(points[8].name, "TEC2 Relay", sizeof(points[8].name));
  points[8].pin = 28;
  points[8].type = POINT_DOUTPUT;
  points[8].precision = 0;
  points[8].conv_type = CONV_NONE;
  points[8].logged = true;
  points[8].alarm.type = ALM_NONE;
  points[8].alarm.state = false;
  points[8].alarm.notify = NOTIFY_NONE;
  points[8].alarm.ap1 = 0;
  points[8].alarm.ap2 = 0;
  points[8].alarm.db = 0;
  
  strlcpy(points[9].name, "Run Enable", sizeof(points[9].name));
  points[9].pin = 30;
  points[9].type = POINT_DINPUT;
  points[9].precision = 0;
  points[9].conv_type = CONV_NONE;
  points[9].logged = true;
  points[9].alarm.type = ALM_NONE;
  points[9].alarm.state = false;
  points[9].alarm.notify = NOTIFY_NONE;
  points[9].alarm.ap1 = 0;
  points[9].alarm.ap2 = 0;
  points[9].alarm.db = 0;
  
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


//Helper function just to make for easier logic tests versus digital inputs and outputs
//Intended to be called like:  if (is_on(points[i].value)) { ... }
//Done to keep the values of the points in the array unified rather than having a
//double value element for analog inputs and a boolean value element for digital
//inputs and outputs.
boolean is_on(double point_value) {
  if (point_value > 0.5) {
    return true;
  } else {
    return false;
  }
}

void do_log_update() {
  if (USE_LOG_SHIELD) {
    debugln("Beginning logging update.");
    int i = 0;
    while (i < MAX_POINTS) {
      if ((points[i].type != POINT_UNDEFINED) and (points[i].logged)) {
        log_point(i);
      }
      i++;
    }
    debugln("Finished logging update.");
  } else {
    debugln("Logging shield not enabled - skipping point logging.");
  }
}

void do_input_update() {
  //input gather here
  int i = 0;
  int raw_d_input = 0;
  double raw_input = 0;
  while (i < MAX_POINTS) {
    switch (points[i].type) {
      case POINT_AINPUT:
        //read the analog input
        raw_input = analogRead(points[i].pin);
        //perform any required conversion
        switch (points[i].conv_type) {
          case CONV_THERM_10K_Z:
            points[i].value = conversion_therm(raw_input, conv_therm_10k_z);
            break;
          case CONV_THERM_CANTHERM:
            points[i].value = conversion_therm(raw_input, conv_therm_cantherm);
            break;
          case CONV_THERM_EPCOS:
            points[i].value = conversion_therm(raw_input, conv_therm_epcos);
            break;
          default:
            points[i].value = raw_input;
            break;
        }
        break;
      case POINT_DINPUT:
        //read the digital input
        //perform any required conversion
        raw_d_input = digitalRead(points[i].pin);
        if (raw_d_input == HIGH) {
          points[i].value = 1;
        } else {
          points[i].value = 0;
        }
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

unsigned long last_led_state_change = 0;

void do_actuation_logic() {
  //io actuation logic processed here
  //Timekeeping - Note that current_time is a global that is set in the calling function update_primaryio()
  
  int LED_flash_time = 2000; //time in ms we want the LED to flash in, both on and off
  if (current_time < last_led_state_change) {     //fix for rotating responses from millis()
    last_led_state_change = 0;
  }
  
  //Actuation logic
  
  if (active_heartbeat) {
    if (current_time >= (last_led_state_change + LED_flash_time)) {
      if (is_on(points[ONBOARD_LED].value)) {
        points[ONBOARD_LED].value = 0;
      } else {
        points[ONBOARD_LED].value = 1;
      }
      last_led_state_change = current_time;
    }
  } 
    
  return;
}

void do_output_update() {
  //use values to set output pin states here
  int i = 0;
  while (i < MAX_POINTS) {
    switch (points[i].type) {
      case POINT_DOUTPUT:
        //Set output pin state based on value of the point
        if (is_on(points[i].value)) {
          digitalWrite(points[i].pin, HIGH);
        } else {
          digitalWrite(points[i].pin, LOW);
        }
        break;
      default:
        break;
    }
    i++;
  }
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
  int name_length = strlen(points[serial_count].name);
  while (i <= (36 - name_length)) {
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
 debugln("PrimaryIO - Begin initialization.");
 initialize_pointlist();
 debugln("PrimaryIO - Load point attributes.");
 load_pointlist();
 debugln("PrimaryIO - Configure IO pins.");
 configure_points();
 last_io_update = 0;
 last_serial_update = 0;
 last_log_update = 0;
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
  if (current_time >= (last_log_update + LOGGING_RATE)) {
    do_log_update();
    last_log_update = current_time;
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
  
