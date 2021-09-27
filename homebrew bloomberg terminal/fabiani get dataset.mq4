//+------------------------------------------------------------------+
//|                                          fabiani get dataset.mq4 |
//|                                              Copyright 2021, FOS |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, FOS"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

int  SL = 40;
int TP = 200;
bool IsDirectional = true;
int history = 120; // number of bars for each pattern similarity
string dir = StringFormat("samples//%s//%s//%d bars(%d)", _Symbol, StringFormat("%d-%d", TP, SL), history,_Period);
string fn = "set.csv"; // name of the main file in work

//the program spits out a single set.csv of some entry points
// path % dir//datetime
//also spits out a -1.csv file ; slope, %
//also spits out a +1.csv file ; slope, %
// headings; (str)open; (str)high, (str)close, (str)low
// slope_change_from_n_to_n+1, percentage_change_from_n+1_to_n+2
// percentage_change_from_n_to_n+1, percentage_change_from_n+1_to_n+2

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   ObjectsDeleteAll();
   string header = "OPEN DATETIME SIGNAL;OPEN PRICE SIGNAL;HIGH PRICE SIGNAL;CLOSE PRICE SIGNAL;"
                   + "LOW PRICE SIGNAL";
   writeFile(header, StringFormat("%s//%s", dir, fn));
   int j = 1;
   int i = j;

   datetime tm=TimeCurrent(); // should return the current server timestamp
   MqlDateTime stm;
   TimeToStruct(tm,stm);
   MqlDateTime ctm; // should return timestamp for shift i
   datetime barTime = iTime(_Symbol, PERIOD_CURRENT, j + 1);
   TimeToStruct(barTime,ctm);

// this code will generate a dataset for the current year only
   while(ctm.year > 2019)
     {
      barTime = iTime(_Symbol, PERIOD_CURRENT, j + 1);
      TimeToStruct(barTime,ctm);
      i = j + 1;
      Print(i);

        {
         if((isRedBar(j) && isBlueBar(i)) ||
            (isRedBar(i) && isBlueBar(j)) ||
            (!isBlueBar(j) && !isRedBar(j) && (isRedBar(i) || isBlueBar(i))) ||
            (!isBlueBar(i) && !isRedBar(i) && (isRedBar(j) || isBlueBar(j))))
           {
            if(j - 1 > 0)
              {
               double AverageEntryPrice = (iHigh(_Symbol, PERIOD_CURRENT, j - 1) +
                                           iLow(_Symbol, PERIOD_CURRENT, j - 1) +
                                           iOpen(_Symbol, PERIOD_CURRENT, j - 1) +
                                           iClose(_Symbol, PERIOD_CURRENT, j - 1))/4;
               if(!IsDirectional)
                 {
                  if(isEntrySignal(AverageEntryPrice, j-1, SL, TP))
                    {
                     recordPair(j);
                     draw_rect(i, j, TimeToString(iTime(_Symbol, PERIOD_CURRENT, i))+TimeToString(iTime(_Symbol, PERIOD_CURRENT, j)), true);
                    }
                 }
               else
                 {
                  if(isBuysEntrySignal(AverageEntryPrice, j-1, SL, TP))
                    {
                     recordPair(j);
                     draw_rect(i, j, TimeToString(iTime(_Symbol, PERIOD_CURRENT, i))+TimeToString(iTime(_Symbol, PERIOD_CURRENT, j)), true);
                    }
                  if(isSellEntrySignal(AverageEntryPrice, j-1, SL, TP))
                    {
                     recordPair(j);
                     draw_rect(i, j, TimeToString(iTime(_Symbol, PERIOD_CURRENT, i))+TimeToString(iTime(_Symbol, PERIOD_CURRENT, j)), true);
                    }
                 }
              }
           }
        }

      j = i;
      barTime = iTime(_Symbol, PERIOD_CURRENT, i);
      //Print(j);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isRedBar(int shift)
  {
   if(iOpen(_Symbol, PERIOD_CURRENT, shift) > iClose(_Symbol, PERIOD_CURRENT, shift))
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBlueBar(int shift)
  {
   if(iOpen(_Symbol, PERIOD_CURRENT, shift) < iClose(_Symbol, PERIOD_CURRENT, shift))
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void recordPair(int signalBar)
  {
   datetime signalBardatetime = iTime(_Symbol, PERIOD_CURRENT, signalBar);
   double signalBaropen = iOpen(_Symbol, PERIOD_CURRENT, signalBar);
   double signalBarhigh = iHigh(_Symbol, PERIOD_CURRENT, signalBar);
   double signalBarclose = iClose(_Symbol, PERIOD_CURRENT, signalBar);
   double signalBarlow = iLow(_Symbol, PERIOD_CURRENT, signalBar);

   string output = StringFormat("%s;%f;%f;%f;%f"
                                , TimeToString(signalBardatetime)
                                , signalBaropen
                                , signalBarhigh
                                , signalBarclose
                                , signalBarlow
                               );

   writeFile(output, StringFormat("%s//%s", dir, fn));
   string TimeStamp = TimeToString(signalBardatetime);
   StringReplace(TimeStamp,".", "-");
   StringReplace(TimeStamp,":", "_");
   string save_dir = StringFormat("%s//%s", dir, TimeStamp);

   string oslopes = "";
   string ochanges = "";
   string hslopes = "";
   string hchanges = "";
   string cslopes = "";
   string cchanges = "";
   string lslopes = "";
   string lchanges = "";
   for(int i=signalBar+history; i >= signalBar; --i)
     {
      double open = iOpen(_Symbol, PERIOD_CURRENT, i);
      double high = iHigh(_Symbol, PERIOD_CURRENT, i);
      double close = iClose(_Symbol, PERIOD_CURRENT, i);
      double low = iLow(_Symbol, PERIOD_CURRENT, i);

      double nopen = iOpen(_Symbol, PERIOD_CURRENT, i+1); // refers to the next bar
      double nhigh = iHigh(_Symbol, PERIOD_CURRENT, i+1);
      double nclose = iClose(_Symbol, PERIOD_CURRENT, i+1);
      double nlow = iLow(_Symbol, PERIOD_CURRENT, i+1);

      double oslope = ((nopen - open)/1); // some measurement of a slope

      double hslope = ((nhigh - high)/1); // some measurement of a slope

      double cslope = ((nclose - close)/1); // some measurement of a slope

      double lslope = ((nlow - low)/1); // some measurement of a slope

      if(i == signalBar+history)
        {
         oslopes = StringFormat("%f", oslope);
         hslopes = StringFormat("%f", hslope);
         cslopes = StringFormat("%f", cslope);
         lslopes = StringFormat("%f", lslope);
        }
      else
        {
         oslopes += StringFormat(",%f", oslope);
         hslopes += StringFormat(",%f", hslope);
         cslopes += StringFormat(",%f", cslope);
         lslopes += StringFormat(",%f", lslope);
        }
     }
   writeFile(StringFormat("%s", oslopes), StringFormat("%s//open_m-1.txt", save_dir), FILE_TXT);
   writeFile(StringFormat("%s", hslopes), StringFormat("%s//high_m-1.txt", save_dir), FILE_TXT);
   writeFile(StringFormat("%s", cslopes), StringFormat("%s//close_m-1.txt", save_dir), FILE_TXT);
   writeFile(StringFormat("%s", lslopes), StringFormat("%s//low_m-1.txt", save_dir), FILE_TXT);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void writeFile(string line, string file_name, int flag_file_type=FILE_CSV)
  {
   int o = FileOpen(file_name, FILE_READ|FILE_WRITE|flag_file_type, ";");
   if(o > 0)
     {
      FileSeek(o, 0, SEEK_END);
      FileWrite(o, line);
      FileClose(o);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void draw_rect(int bar1_shift, int bar2_shift, string obj_name, bool isBuy=true)
  {
   int lowest = iLow(_Symbol, PERIOD_CURRENT, bar1_shift) < iLow(_Symbol, PERIOD_CURRENT, bar2_shift)? bar1_shift: bar2_shift;
   int highest = iHigh(_Symbol, PERIOD_CURRENT, bar1_shift) > iHigh(_Symbol, PERIOD_CURRENT, bar2_shift)? bar1_shift: bar2_shift;
   ObjectCreate(_Symbol
                , obj_name
                , OBJ_RECTANGLE
                , 0
                , iTime(_Symbol, PERIOD_CURRENT, bar1_shift)
                , iHigh(_Symbol, PERIOD_CURRENT, highest)
                , iTime(_Symbol, PERIOD_CURRENT, bar2_shift)
                ,iLow(_Symbol, PERIOD_CURRENT, lowest));

   if(isBuy)
     {ObjectSetInteger(0, obj_name, OBJPROP_COLOR, clrBlue);}
   else
     {ObjectSetInteger(0, obj_name, OBJPROP_COLOR, clrRed);}

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isEntrySignal(double entryPrice, int entryBarShift, int slPips, int tpPips)
  {
   bool Output = false;
   int thisBarShift = entryBarShift;
   double slPriceLookingHighs = entryPrice + digitarize(slPips);
   double slPriceLookingLows = entryPrice - digitarize(slPips);
   double tpPriceLookingLows = entryPrice - digitarize(tpPips);
   double tpPriceLookingHighs = entryPrice + digitarize(tpPips);
//double slPriceLookingHighs = entryPrice + slPips;
//double slPriceLookingLows = entryPrice - slPips;
//double tpPriceLookingLows = entryPrice - tpPips;
//double tpPriceLookingHighs = entryPrice + tpPips;

   bool CheckHigherTP = false, CheckLowerTP = false,CheckLowerSL = false, CheckHigherSL = false;
   string oslopes = "";
   string ochanges = "";
   string hslopes = "";
   string hchanges = "";
   string cslopes = "";
   string cchanges = "";
   string lslopes = "";
   string lchanges = "";

   while(thisBarShift > 0)
     {
      if(CheckLowerSL || CheckHigherSL)
         break;

      datetime barTime = iTime(_Symbol, PERIOD_CURRENT, thisBarShift);

      double barHighs = iHigh(_Symbol, PERIOD_CURRENT, thisBarShift);
      double barLows = iLow(_Symbol, PERIOD_CURRENT, thisBarShift);

      if(barLows <= slPriceLookingLows)
         CheckLowerSL = true;

      if(barHighs >= slPriceLookingHighs)
         CheckHigherSL = true;

      if(barLows <= tpPriceLookingLows)
         CheckLowerTP = true;

      if(barHighs >= tpPriceLookingHighs)
         CheckHigherTP = true;

      if(CheckHigherTP && CheckLowerTP && !CheckLowerSL && !CheckHigherSL)
        {
         Print("yes");
         datetime signalBardatetime = iTime(_Symbol, PERIOD_CURRENT, entryBarShift+1);
         string TimeStamp = TimeToString(signalBardatetime);
         StringReplace(TimeStamp,".", "-");
         StringReplace(TimeStamp,":", "_");

         for(int i=entryBarShift; i > thisBarShift; --i)
           {
            double high = iHigh(_Symbol, PERIOD_CURRENT, i);
            double low = iLow(_Symbol, PERIOD_CURRENT, i);
            double open = iOpen(_Symbol, PERIOD_CURRENT, i);
            double close = iClose(_Symbol, PERIOD_CURRENT, i);

            double nopen = iOpen(_Symbol, PERIOD_CURRENT, i - 1); // refers to the next bar
            double nhigh = iHigh(_Symbol, PERIOD_CURRENT, i - 1);
            double nclose = iClose(_Symbol, PERIOD_CURRENT, i - 1);
            double nlow = iLow(_Symbol, PERIOD_CURRENT, i - 1);

            double oslope = ((nopen - open)/1); // some measurement of a slope

            double hslope = ((nhigh - high)/1); // some measurement of a slope

            double cslope = ((nclose - close)/1); // some measurement of a slope

            double lslope = ((nlow - low)/1); // some measurement of a slope

            if(i == entryBarShift)
              {
               oslopes = StringFormat("%f", oslope);
               hslopes = StringFormat("%f", hslope);
               cslopes = StringFormat("%f", cslope);
               lslopes = StringFormat("%f", lslope);
              }
            else
              {
               oslopes += StringFormat(",%f", oslope);
               hslopes += StringFormat(",%f", hslope);
               cslopes += StringFormat(",%f", cslope);
               lslopes += StringFormat(",%f", lslope);
              }
           }
         string save_dir = StringFormat("%s//%s", dir, TimeStamp);
         writeFile(StringFormat("%s", oslopes), StringFormat("%s//open_m+1.txt", save_dir), FILE_TXT);
         writeFile(StringFormat("%s", hslopes), StringFormat("%s//high_m+1.txt", save_dir), FILE_TXT);
         writeFile(StringFormat("%s", cslopes), StringFormat("%s//close_m+1.txt", save_dir), FILE_TXT);
         writeFile(StringFormat("%s", lslopes), StringFormat("%s//low_m+1.txt", save_dir), FILE_TXT);
         return (true);
        }

      thisBarShift -= 1;
     }
   return(Output);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBuysEntrySignal(double entryPrice, int entryBarShift, int slPips, int tpPips)
  {
   bool Output = false;
   int thisBarShift = entryBarShift;
   double slPriceLookingHighs = entryPrice + digitarize(slPips);
   double slPriceLookingLows = entryPrice - digitarize(slPips);
   double tpPriceLookingLows = entryPrice - digitarize(tpPips);
   double tpPriceLookingHighs = entryPrice + digitarize(tpPips);
//double slPriceLookingHighs = entryPrice + slPips;
//double slPriceLookingLows = entryPrice - slPips;
//double tpPriceLookingLows = entryPrice - tpPips;
//double tpPriceLookingHighs = entryPrice + tpPips;

   bool CheckHigherTP = false, CheckLowerTP = false,CheckLowerSL = false, CheckHigherSL = false;
   string oslopes = "";
   string ochanges = "";
   string hslopes = "";
   string hchanges = "";
   string cslopes = "";
   string cchanges = "";
   string lslopes = "";
   string lchanges = "";

   while(thisBarShift > 0)
     {
      if(CheckLowerSL)
         break;

      datetime barTime = iTime(_Symbol, PERIOD_CURRENT, thisBarShift);

      double barHighs = iHigh(_Symbol, PERIOD_CURRENT, thisBarShift);
      double barLows = iLow(_Symbol, PERIOD_CURRENT, thisBarShift);

      if(barLows <= slPriceLookingLows)
         CheckLowerSL = true;

      if(barHighs >= tpPriceLookingHighs)
         CheckHigherTP = true;

      if(CheckHigherTP && !CheckLowerSL)
        {
         Print("yes");
         datetime signalBardatetime = iTime(_Symbol, PERIOD_CURRENT, entryBarShift+1);
         string TimeStamp = TimeToString(signalBardatetime);
         StringReplace(TimeStamp,".", "-");
         StringReplace(TimeStamp,":", "_");

         for(int i=entryBarShift; i > thisBarShift; --i)
           {
            double high = iHigh(_Symbol, PERIOD_CURRENT, i);
            double low = iLow(_Symbol, PERIOD_CURRENT, i);
            double open = iOpen(_Symbol, PERIOD_CURRENT, i);
            double close = iClose(_Symbol, PERIOD_CURRENT, i);

            double nopen = iOpen(_Symbol, PERIOD_CURRENT, i - 1); // refers to the next bar
            double nhigh = iHigh(_Symbol, PERIOD_CURRENT, i - 1);
            double nclose = iClose(_Symbol, PERIOD_CURRENT, i - 1);
            double nlow = iLow(_Symbol, PERIOD_CURRENT, i - 1);

            double oslope = ((nopen - open)/1); // some measurement of a slope

            double hslope = ((nhigh - high)/1); // some measurement of a slope

            double cslope = ((nclose - close)/1); // some measurement of a slope

            double lslope = ((nlow - low)/1); // some measurement of a slope

            if(i == entryBarShift)
              {
               oslopes = StringFormat("%f", oslope);
               hslopes = StringFormat("%f", hslope);
               cslopes = StringFormat("%f", cslope);
               lslopes = StringFormat("%f", lslope);
              }
            else
              {
               oslopes += StringFormat(",%f", oslope);
               hslopes += StringFormat(",%f", hslope);
               cslopes += StringFormat(",%f", cslope);
               lslopes += StringFormat(",%f", lslope);
              }
           }
         string save_dir = StringFormat("%s//%s", dir, TimeStamp);
         writeFile(StringFormat("%s", oslopes), StringFormat("%s//open_m+1.txt", save_dir), FILE_TXT);
         writeFile(StringFormat("%s", hslopes), StringFormat("%s//high_m+1.txt", save_dir), FILE_TXT);
         writeFile(StringFormat("%s", cslopes), StringFormat("%s//close_m+1.txt", save_dir), FILE_TXT);
         writeFile(StringFormat("%s", lslopes), StringFormat("%s//low_m+1.txt", save_dir), FILE_TXT);
         return (true);
        }

      thisBarShift -= 1;
     }
   return(Output);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSuperBuysEntrySignal(double entryPrice, int entryBarShift, int slPips, int tpPips)
  {
   bool Output = false;
   int thisBarShift = entryBarShift;
//double slPriceLookingHighs = entryPrice + digitarize(slPips);
//double slPriceLookingLows = entryPrice - digitarize(slPips);
//double tpPriceLookingLows = entryPrice - digitarize(tpPips);
//double tpPriceLookingHighs = entryPrice + digitarize(tpPips);
   double slPriceLookingHighs = entryPrice + slPips;
   double slPriceLookingLows = entryPrice - slPips;
   double tpPriceLookingLows = entryPrice - tpPips;

   double tpPriceLookingHighs = entryPrice + tpPips;

   bool CheckHigherTP = false, CheckLowerTP = false,CheckLowerSL = false, CheckHigherSL = false;
   string oslopes = "";
   string ochanges = "";
   string hslopes = "";
   string hchanges = "";
   string cslopes = "";
   string cchanges = "";
   string lslopes = "";
   string lchanges = "";

   while(thisBarShift > 0)
     {
      if(CheckLowerSL)
         break;

      datetime barTime = iTime(_Symbol, PERIOD_CURRENT, thisBarShift);

      double barHighs = iHigh(_Symbol, PERIOD_CURRENT, thisBarShift);
      double barLows = iLow(_Symbol, PERIOD_CURRENT, thisBarShift);

      if(barLows <= slPriceLookingLows)
         CheckLowerSL = true;

      if(barHighs >= tpPriceLookingHighs)
         CheckHigherTP = true;

      if(CheckHigherTP && !CheckLowerSL)
        {
         Print("yes");
         datetime signalBardatetime = iTime(_Symbol, PERIOD_CURRENT, entryBarShift+1);
         string TimeStamp = TimeToString(signalBardatetime);
         StringReplace(TimeStamp,".", "-");
         StringReplace(TimeStamp,":", "_");

         for(int i=entryBarShift; i > thisBarShift; --i)
           {
            double high = iHigh(_Symbol, PERIOD_CURRENT, i);
            double low = iLow(_Symbol, PERIOD_CURRENT, i);
            double open = iOpen(_Symbol, PERIOD_CURRENT, i);
            double close = iClose(_Symbol, PERIOD_CURRENT, i);

            double nopen = iOpen(_Symbol, PERIOD_CURRENT, i - 1); // refers to the next bar
            double nhigh = iHigh(_Symbol, PERIOD_CURRENT, i - 1);
            double nclose = iClose(_Symbol, PERIOD_CURRENT, i - 1);
            double nlow = iLow(_Symbol, PERIOD_CURRENT, i - 1);

            double oslope = ((nopen - open)/1); // some measurement of a slope

            double hslope = ((nhigh - high)/1); // some measurement of a slope

            double cslope = ((nclose - close)/1); // some measurement of a slope

            double lslope = ((nlow - low)/1); // some measurement of a slope

            if(i == entryBarShift)
              {
               oslopes = StringFormat("%f", oslope);
               hslopes = StringFormat("%f", hslope);
               cslopes = StringFormat("%f", cslope);
               lslopes = StringFormat("%f", lslope);
              }
            else
              {
               oslopes += StringFormat(",%f", oslope);
               hslopes += StringFormat(",%f", hslope);
               cslopes += StringFormat(",%f", cslope);
               lslopes += StringFormat(",%f", lslope);
              }
           }
         string save_dir = StringFormat("%s//%s", dir, TimeStamp);
         writeFile(StringFormat("%s", oslopes), StringFormat("%s//open_m+1.txt", save_dir), FILE_TXT);
         writeFile(StringFormat("%s", hslopes), StringFormat("%s//high_m+1.txt", save_dir), FILE_TXT);
         writeFile(StringFormat("%s", cslopes), StringFormat("%s//close_m+1.txt", save_dir), FILE_TXT);
         writeFile(StringFormat("%s", lslopes), StringFormat("%s//low_m+1.txt", save_dir), FILE_TXT);
         return (true);
        }
      slPriceLookingLows = barHighs - slPips;
      thisBarShift -= 1;
     }
   return(Output);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSellEntrySignal(double entryPrice, int entryBarShift, int slPips, int tpPips)
  {
   bool Output = false;
   int thisBarShift = entryBarShift;
   double slPriceLookingHighs = entryPrice + digitarize(slPips);
   double slPriceLookingLows = entryPrice - digitarize(slPips);
   double tpPriceLookingLows = entryPrice - digitarize(tpPips);
   double tpPriceLookingHighs = entryPrice + digitarize(tpPips);
//double slPriceLookingHighs = entryPrice + slPips;
//double slPriceLookingLows = entryPrice - slPips;
//double tpPriceLookingLows = entryPrice - tpPips;
//double tpPriceLookingHighs = entryPrice + tpPips;

   bool CheckHigherTP = false, CheckLowerTP = false,CheckLowerSL = false, CheckHigherSL = false;
   string oslopes = "";
   string ochanges = "";
   string hslopes = "";
   string hchanges = "";
   string cslopes = "";
   string cchanges = "";
   string lslopes = "";
   string lchanges = "";

   while(thisBarShift > 0)
     {
      if(CheckHigherSL)
         break;

      datetime barTime = iTime(_Symbol, PERIOD_CURRENT, thisBarShift);

      double barHighs = iHigh(_Symbol, PERIOD_CURRENT, thisBarShift);
      double barLows = iLow(_Symbol, PERIOD_CURRENT, thisBarShift);

      if(barHighs >= slPriceLookingHighs)
         CheckHigherSL = true;

      if(barLows <= tpPriceLookingLows)
         CheckLowerTP = true;

      if(CheckLowerTP && !CheckHigherSL)
        {
         Print("yes");
         datetime signalBardatetime = iTime(_Symbol, PERIOD_CURRENT, entryBarShift+1);
         string TimeStamp = TimeToString(signalBardatetime);
         StringReplace(TimeStamp,".", "-");
         StringReplace(TimeStamp,":", "_");

         for(int i=entryBarShift; i > thisBarShift; --i)
           {
            double high = iHigh(_Symbol, PERIOD_CURRENT, i);
            double low = iLow(_Symbol, PERIOD_CURRENT, i);
            double open = iOpen(_Symbol, PERIOD_CURRENT, i);
            double close = iClose(_Symbol, PERIOD_CURRENT, i);

            double nopen = iOpen(_Symbol, PERIOD_CURRENT, i - 1); // refers to the next bar
            double nhigh = iHigh(_Symbol, PERIOD_CURRENT, i - 1);
            double nclose = iClose(_Symbol, PERIOD_CURRENT, i - 1);
            double nlow = iLow(_Symbol, PERIOD_CURRENT, i - 1);

            double oslope = ((nopen - open)/1); // some measurement of a slope

            double hslope = ((nhigh - high)/1); // some measurement of a slope

            double cslope = ((nclose - close)/1); // some measurement of a slope

            double lslope = ((nlow - low)/1); // some measurement of a slope

            if(i == entryBarShift)
              {
               oslopes = StringFormat("%f", oslope);
               hslopes = StringFormat("%f", hslope);
               cslopes = StringFormat("%f", cslope);
               lslopes = StringFormat("%f", lslope);
              }
            else
              {
               oslopes += StringFormat(",%f", oslope);
               hslopes += StringFormat(",%f", hslope);
               cslopes += StringFormat(",%f", cslope);
               lslopes += StringFormat(",%f", lslope);
              }
           }
         string save_dir = StringFormat("%s//%s", dir, TimeStamp);
         writeFile(StringFormat("%s", oslopes), StringFormat("%s//open_m+1.txt", save_dir), FILE_TXT);
         writeFile(StringFormat("%s", hslopes), StringFormat("%s//high_m+1.txt", save_dir), FILE_TXT);
         writeFile(StringFormat("%s", cslopes), StringFormat("%s//close_m+1.txt", save_dir), FILE_TXT);
         writeFile(StringFormat("%s", lslopes), StringFormat("%s//low_m+1.txt", save_dir), FILE_TXT);
         return (true);
        }

      thisBarShift -= 1;
     }
   return(Output);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isSuperSellEntrySignal(double entryPrice, int entryBarShift, int slPips, int tpPips)
  {
   bool Output = false;
   int thisBarShift = entryBarShift;
//double slPriceLookingHighs = entryPrice + digitarize(slPips);
//double slPriceLookingLows = entryPrice - digitarize(slPips);
//double tpPriceLookingLows = entryPrice - digitarize(tpPips);
//double tpPriceLookingHighs = entryPrice + digitarize(tpPips);
   double slPriceLookingHighs = entryPrice + slPips;
   double slPriceLookingLows = entryPrice - slPips;
   double tpPriceLookingLows = entryPrice - tpPips;

   double tpPriceLookingHighs = entryPrice + tpPips;

   bool CheckHigherTP = false, CheckLowerTP = false,CheckLowerSL = false, CheckHigherSL = false;
   string oslopes = "";
   string ochanges = "";
   string hslopes = "";
   string hchanges = "";
   string cslopes = "";
   string cchanges = "";
   string lslopes = "";
   string lchanges = "";

   while(thisBarShift > 0)
     {
      if(CheckHigherSL)
         break;

      datetime barTime = iTime(_Symbol, PERIOD_CURRENT, thisBarShift);

      double barHighs = iHigh(_Symbol, PERIOD_CURRENT, thisBarShift);
      double barLows = iLow(_Symbol, PERIOD_CURRENT, thisBarShift);

      if(barHighs >= slPriceLookingHighs)
         CheckHigherSL = true;

      if(barLows <= tpPriceLookingLows)
         CheckLowerTP = true;

      if(CheckLowerTP && !CheckHigherSL)
        {
         Print("yes");
         datetime signalBardatetime = iTime(_Symbol, PERIOD_CURRENT, entryBarShift+1);
         string TimeStamp = TimeToString(signalBardatetime);
         StringReplace(TimeStamp,".", "-");
         StringReplace(TimeStamp,":", "_");

         for(int i=entryBarShift; i > thisBarShift; --i)
           {
            double high = iHigh(_Symbol, PERIOD_CURRENT, i);
            double low = iLow(_Symbol, PERIOD_CURRENT, i);
            double open = iOpen(_Symbol, PERIOD_CURRENT, i);
            double close = iClose(_Symbol, PERIOD_CURRENT, i);

            double nopen = iOpen(_Symbol, PERIOD_CURRENT, i - 1); // refers to the next bar
            double nhigh = iHigh(_Symbol, PERIOD_CURRENT, i - 1);
            double nclose = iClose(_Symbol, PERIOD_CURRENT, i - 1);
            double nlow = iLow(_Symbol, PERIOD_CURRENT, i - 1);

            double oslope = ((nopen - open)/1); // some measurement of a slope

            double hslope = ((nhigh - high)/1); // some measurement of a slope

            double cslope = ((nclose - close)/1); // some measurement of a slope

            double lslope = ((nlow - low)/1); // some measurement of a slope

            if(i == entryBarShift)
              {
               oslopes = StringFormat("%f", oslope);
               hslopes = StringFormat("%f", hslope);
               cslopes = StringFormat("%f", cslope);
               lslopes = StringFormat("%f", lslope);
              }
            else
              {
               oslopes += StringFormat(",%f", oslope);
               hslopes += StringFormat(",%f", hslope);
               cslopes += StringFormat(",%f", cslope);
               lslopes += StringFormat(",%f", lslope);
              }
           }
         string save_dir = StringFormat("%s//%s", dir, TimeStamp);
         writeFile(StringFormat("%s", oslopes), StringFormat("%s//open_m+1.txt", save_dir), FILE_TXT);
         writeFile(StringFormat("%s", hslopes), StringFormat("%s//high_m+1.txt", save_dir), FILE_TXT);
         writeFile(StringFormat("%s", cslopes), StringFormat("%s//close_m+1.txt", save_dir), FILE_TXT);
         writeFile(StringFormat("%s", lslopes), StringFormat("%s//low_m+1.txt", save_dir), FILE_TXT);
         return (true);
        }

      slPriceLookingHighs = barLows + slPips;
      thisBarShift -= 1;
     }
   return(Output);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// a useful method when you want to add or subtract a pip from a price
// works good with 4 and five digit brokers
double digitarize(int pip)
  {
   return pip * .0001;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// takes the difference between two prices
// take the difference and convert it to a pip value
// return the amount in pips
double piparize(double biggerPrice, double smallerPrice)
  {
   double difference = biggerPrice - smallerPrice;
   return difference * 10000;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double piparize(double difference)
  {
   return difference * 10000;
  }
//+------------------------------------------------------------------+
