//#include <Wire.h>
//#include "RTClib.h"

RTC_DS1307 RTC;

//DateTime real_time;

void init_rtc () {
  if (USE_LOG_SHIELD) {
    Wire.begin();
    RTC.begin();

    if (! RTC.isrunning()) {
      // following line sets the RTC to the date & time this sketch was compiled
      //RTC.adjust(DateTime(__DATE__, __TIME__));
    }
    real_time = RTC.now();
  }
}

void update_rtc() {
  if (USE_LOG_SHIELD) {
    real_time = RTC.now();
  }
}
