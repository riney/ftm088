#define PHONE_DEBUG true

#define PHONE_PORT Serial1
const int PHONE_BAUD = 4800;
const int DELAY_TIME = 250;

#define RESET_CMD    "AT*SWRESET"
#define XMIT_OFF_CMD "AT+CFUN=0"
#define SMS_MODE_CMD "AT+CMGF=1"
#define MSG_CMD      "AT+CMGS="
#define SIGNAL_CMD   "AT+CSQ"
#define BATT_CMD     "AT+CBC"

void init_phone(void) {
  PHONE_PORT.begin(PHONE_BAUD);
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
