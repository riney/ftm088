#define PHONE_DEBUG true

#define PHONE_PORT Serial1
#define PHONE_BAUD 4800
#define DELAY_TIME 250
#define PHONE_TIMEOUT 5000

#define RESET_CMD    "AT*SWRESET"
#define XMIT_OFF_CMD "AT+CFUN=0"
#define SMS_MODE_CMD "AT+CMGF=1"
#define MSG_CMD      "AT+CMGS="
#define SIGNAL_CMD   "AT+CSQ"
#define BATT_CMD     "AT+CBC"
#define ECHO_OFF_CMD  "ATE0"
#define AT_RESET_CMD  "ATZ"

void init_phone(void) {
  debugln("init_phone()");
  PHONE_PORT.begin(PHONE_BAUD);
  wait();
  sendln(AT_RESET_CMD);
  if (wait_for_available()) {
    debugln("available bytes!");
  }
  else {
    debugln("timed out");
  }
  char c;
  while(PHONE_PORT.available() > 0) {
    c = PHONE_PORT.read();
    debug(c);
  }
  debugln("init_phone done");

}

boolean wait_for_available(void) {
  unsigned long start = millis();
  while ((millis() - start < PHONE_TIMEOUT) && (!PHONE_PORT.available()));
  return PHONE_PORT.available() > 0;
}

int reset_phone(void) {
  PHONE_PORT.println(RESET_CMD);
}

int enable_transmitter(boolean state) {
  if(state) {
    sendln(RESET_CMD);
  }
  else {
    sendln(XMIT_OFF_CMD);
  }
}

int sms(const char to[], const char text[]) {
  debugln("SMS>");
  sendln(SMS_MODE_CMD);
  wait();
  send(MSG_CMD);
  send("\""); send(to); sendln("\"");
  wait();
  send(text);
  sendln("\26");
  wait();
  
  /* parse for OK */
  debugln("<SMS");
}

int tweet(const char text[]) {
  sms("40404", text);
}

int get_battery(void) {
}

int get_signal(void) {
}

void wait(void) {
  delay(DELAY_TIME);
}

void send(const char s[]) {
  if(PHONE_DEBUG) {
    debug(s);
  }
  PHONE_PORT.print(s);
}

void sendln(const char s[]) {
  if(PHONE_DEBUG) {
    debugln(s);
  }
  PHONE_PORT.println(s);
}
