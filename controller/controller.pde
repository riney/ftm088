/*
  Control software for FTM088.
  Jason Beeland, John Riney
*/
 
/* IO pin assignments */
//const int LED_PIN = 13;
boolean active_heartbeat = false;

void setup()
{
  init_debug();
  debugln("FTM088 start!");
  
  init_phone();
  sms("654564654", "hello world!");
  
  init_primaryio();
  
  //pinMode(LED_PIN, OUTPUT);  // set ledPin pin as output
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
  
  
  //Below blinking actuation and above onboard led pin define and config commented as the delays will actually interrupt processing of other modules.
  //Added this blinking LED into the primaryio actuation as a heartbeat indicator.  Turning active_heartbeat true and false
  //will enable and disable this functionality.
  active_heartbeat = true;
  
  //digitalWrite(LED_PIN, HIGH);  // set the LED on
  //delay(1000);                  // wait for a second
  //digitalWrite(LED_PIN, LOW);   // set the LED off
  //delay(1000); 
}


