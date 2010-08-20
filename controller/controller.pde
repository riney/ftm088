/*
  Control software for FTM088.
  Jason Beeland, John Riney
*/
#include <Wire.h>
#include "RTClib.h"
 
boolean active_heartbeat = false;
const boolean USE_LOG_SHIELD = true;
DateTime real_time;


void setup()
{
  init_debug();
  debugln("FTM088 start!");
  init_rtc();
  init_microsd();
  init_phone();
  sms("654564654", "hello world!");
  
  init_primaryio();
  
}

void loop() 
{
  /*
    while forever:
      read sensors
      are we in an alarm condition?
        shutdown
        otherwise, update output states
      switch relays if enough time has elapsed since last time
      update display
      send twitter update if enough time has elapsed since last time
  */
  
  update_primaryio();           //Perform all input/output/alarming/logic functions for primary actuation
  
  
  //Added this blinking LED into the primaryio actuation as a heartbeat indicator.  Turning active_heartbeat true and false
  //will enable and disable this functionality.
  active_heartbeat = true;
  
}


