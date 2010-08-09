#define LCD_PORT Serial2
#define LCD_BAUD 9600

void init_lcd(void) {
  debugln("init_lcd");
  LCD_PORT.begin(LCD_BAUD);
  
  /* clear screen, home cursor */
  LCD_PORT.print(12, BYTE);
  debugln("init_lcd done");
}

void lcd_print(const char c[]) {
  LCD_PORT.print(c);
}

void lcd_startup_banner(void) {
  lcd_print("       FTM088       ");
  lcd_print("====================");
  lcd_print("Starting up...");
}
