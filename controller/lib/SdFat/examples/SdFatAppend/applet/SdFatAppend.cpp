/*
 * Append Example
 *
 * This sketch shows how to use open for append and the Arduino Print class
 * with SdFat.
 */
#include <SdFat.h>
#include <SdFatUtil.h> // use functions to print strings from flash memory

#include "WProgram.h"
void error_P(const char *str);
void setup(void);
void loop(void);
Sd2Card card;
SdVolume volume;
SdFile root;
SdFile file;

// store error strings in flash to save RAM
#define error(s) error_P(PSTR(s))
void error_P(const char *str)
{
  PgmPrint("error: ");
  SerialPrintln_P(str);
  if (card.errorCode()) {
    PgmPrint("SD error: ");
    Serial.print(card.errorCode(), HEX);
    Serial.print(',');
    Serial.println(card.errorData(), HEX);
  }
  while(1);
}

void setup(void)
{
  Serial.begin(9600);
  Serial.println();
  PgmPrintln("Type any character to start");
  while (!Serial.available());
  
  // initialize the SD card
  pinMode(10, OUTPUT);
  if (!card.init()) error("card.init");

  // initialize a FAT volume
  if (!volume.init(card)) error("volume.init");

  // open the root directory
  if (!root.openRoot(volume)) error("openRoot");
  
  char name[] = "APPEND.TXT";
  PgmPrint("Appending to: ");
  Serial.println(name);
  
  // clear write error
  file.writeError = false;
  
  for (uint8_t i = 0; i < 100; i++) {
    // O_CREAT - create the file if it does not exist
    // O_APPEND - seek to the end of the file prior to each write
    // O_WRITE - open for write
    if (!file.open(root, name, O_CREAT | O_APPEND | O_WRITE)) error("open");
    // print 100 lines to file
    for (uint8_t j = 0; j < 100; j++) {
      file.print("line ");
      file.print(j, DEC);
      file.print(" of pass ");
      file.print(i, DEC);
      file.print(" millis = ");
      file.println(millis());
    }
    if (!file.close() || file.writeError) error("close/write");
    if (i > 0 && i%25 == 0)Serial.println();
    Serial.print('.');
  }
  Serial.println();
  Serial.println("Done");
}
void loop(void){}

int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

