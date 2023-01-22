#include <Adafruit_GFX.h>    // Core graphics library
#include <MCUFRIEND_kbv.h>   // Hardware-specific library
#include "pics.h"
//----------for the TMP36 temp sensor---------
#define aref_voltage 3.3
int tempPin = 5;

MCUFRIEND_kbv tft;

int xNamePos = 66;
int yNamePos[2] = {18 , 44};
int txtSize = 6;
int componentNameTxtSize = 2;
int componentSelector;
String *inData;
int idText;
String allData[3][4] = {
  {"", "", "", ""}, //index 0:nameData
  {"---", "---", "---", "---"},
  {"---", "---", "---", "---"}
};
static const uint8_t *main_img[] = {cpu_img, gpu_img, mobo_img, epd_bitmap_water_black};
static const uint8_t *sensors_img[2][3] = {
  {
    temp_img,
    usage_img, 
    ram_img
  },
  {
    temp_img,
    usage_img,
    epd_bitmap_flash_ard
  }
};
static const uint8_t *symbols_img[2][3] = {
  {
    tempSymbol_img,
    usageSymbol_img, 
    usageSymbol_img
  },
  {
    tempSymbol_img, 
    usageSymbol_img, 
    epd_bitmap_mv
  }
};
boolean printName = false;

void setup() {
  Serial.begin(9600);
  //------------INIT FOR MCUFRIEND_KVB LIBRARY
  uint16_t ID = tft.readID();
  if (ID == 0xD3) ID = 0x9481;
  tft.begin(ID);
  tft.setRotation(1);
  tft.fillScreen(TFT_BLACK);
  //--------------tmp36 temp sensor setup
  analogReference(EXTERNAL);
  //-------------building interface------------------------
  for (int i = 0; i < 2; i++) {
    int x = 240 * i;
    tft.drawRect(x + 1, 1, 63, 63, TFT_BLUE);
    tft.drawRect(x, 0, 63, 63, TFT_DARKGREY);
    tft.fillRect(x + 60, 5, 20, 25, TFT_BLACK);
    //bigmodule
    tft.drawRect(x + 1, 1, 239, 255, TFT_BLUE);
    tft.drawRect(x, 0, 239, 255, TFT_DARKGREY);
    //smallmodule
    tft.drawRect(x + 1, 257, 239, 63, TFT_BLUE);
    tft.drawRect(x, 256, 239, 63, TFT_DARKGREY);
    tft. drawLine(x + 18, 65, x + 18, 225, TFT_BLUE); //bigmodule_treestruct
    tft. drawLine(x + 17, 64, x + 17, 224, TFT_DARKGREY);
    for (int r = 1; r < 4; r++) {
      int y = 64 * r;
      //bigmodule_separators
      tft.drawLine(x + 84 + 1, y + 1, x + 237 + 1, y + 1, TFT_BLUE);
      tft.drawLine(x + 84, y, x + 237, y, TFT_DARKGREY);
      ///BIGMODULE_TREE_BRANCHES
      tft.drawLine(x + 18, y + 32 + 1, x + 36, y + 32 + 1, TFT_BLUE);
      tft.drawLine(x + 17, y + 32, x + 35, y + 32, TFT_DARKGREY);
      ///BIGMODULE_SENSOR_SQUARE
      tft.drawRect(x + 36, y + 8, 48, 48, TFT_DARKGREY);
      tft.drawRect(x + 35, y + 7, 48, 48, TFT_BLUE);
    }
  }
  //draw icons
  for (int i = 0; i < 2; i++) {
    int x = 240 * i;
    //int y = 64 * i;
    //main icons /gpu cpu top icons
    tft.drawBitmap(x + 1, 1, main_img[i], 64, 64, TFT_DARKGREY);
    tft.drawBitmap(x, 0, main_img[i], 64, 64, TFT_BLUE);

    // Hide Mobo Image, aka placeholder, remove if, if  you want to display image bottom left
    if(main_img[i + 2] != mobo_img) {
      //main icons for small modules, e.g. flash, usage symbol
      tft.drawBitmap(x + 1, 257, main_img[i + 2], 64, 64, TFT_DARKGREY);
      tft.drawBitmap(x, 256, main_img[i + 2], 64, 64, TFT_BLUE);
      //symbols icons for small modules e.g. temp symbol, percentage, ...
      tft.drawBitmap(x + 193, 265, symbols_img[0][0], 48, 48, TFT_WHITE);
      tft.drawBitmap(x + 192, 264, symbols_img[0][0], 48, 48, TFT_BLUE);
    }
    for (int ii = 1; ii < 4; ii++) {
      int y = 64 * ii;
      //sensors icons e.g. gpu img 
      tft.drawBitmap(x + 36, y + 9, sensors_img[i][ii - 1], 48, 48, TFT_DARKGREY);
      tft.drawBitmap(x + 35, y + 8, sensors_img[i][ii - 1], 48, 48, TFT_BLUE);
      //symbols icons % and temp
      tft.drawBitmap(x + 193, y + 9, symbols_img[i][ii - 1], 48, 48, TFT_WHITE);//WHITE SHADOW
      tft.drawBitmap(x + 192, y + 8, symbols_img[i][ii - 1], 48, 48, TFT_BLUE);//RED ICON
    }
  }
  //print values placeholders
  printName = true;
  printData();
  
}

void loop() {
  printName = true;
  while (Serial.available() > 0)
  {
    String recieved = Serial.readStringUntil(';');
    //-------HANDSHAKE---------
    if (recieved == "*****") {
      Serial.println('R');
      break;
    }
    else if (recieved.indexOf(':') != -1 ) {
      int lastIndex = recieved.indexOf(':');
      int nextIndex;
      componentSelector = recieved[lastIndex - 1] - '0';
      switch (componentSelector) {
        case 0:
          printName = true;
        case 1:
        case 2:
          for (int i = 0; i < 4; i ++) {
            nextIndex = recieved.indexOf(',', lastIndex + 1);
            allData[componentSelector][i] = recieved.substring(lastIndex + 1, nextIndex);
            lastIndex = nextIndex;
          }
          break;
        case 3:
          /////-------EXTENRAL CASE SENSOR FUNCION CALL-----
          //allData[2][3] = readExtTemp();
          printData();
          break;
      }
    }
  }
}

void printData() {
  if (printName == true) {
    //print the names
    tft.setTextSize(componentNameTxtSize);
    tft.setTextColor(TFT_BLUE, TFT_BLACK);
    for (int i = 0; i < 4; i++) {
      int x = 241 * (i / 2);
      tft.setCursor(xNamePos + x, yNamePos[i % 2]);
      tft.print(allData[0][i]);
    }
    printName = false;
  }
  //print the values
  tft.setTextSize(txtSize);
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  for (int i = 0; i < 2; i++) {
    int x = 90 + (241 * i);
    for (int ii = 1; ii < 5; ii++) {
      // move lower left text more left
      if (i == 0 && ii == 4) {
        x = 40 + (241 * i);
      }
      int y = 10 + (64 * ii);
      tft.setCursor(x, y);
      tft.print(allData[i + 1][ii - 1]);
    }
  }
}

String readExtTemp() {

  int tRead = 0;
  for (int i = 0; i < 16; i++) {
    tRead = tRead + analogRead(tempPin);
  }
  int tempReading = tRead / 16;
  float voltage = (tempReading * aref_voltage) / 1024;
  int temperatureC = (voltage - 0.5) * 100 ;
  String outValue = String(temperatureC);
  if (temperatureC > 100) {
    outValue = "---";
  }
  while (outValue.length() < 3) {
    outValue = " " + outValue;
  }
  return outValue;
}
