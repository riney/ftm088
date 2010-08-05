#define DEBUG_PORT Serial
const int DEBUG_BAUD = 9600;

void init_debug(void) {
  DEBUG_PORT.begin(DEBUG_BAUD);
}

void debug(const char c[]) {
  DEBUG_PORT.print(c);
}

void debugln(const char c[]) {
  DEBUG_PORT.println(c);
}
