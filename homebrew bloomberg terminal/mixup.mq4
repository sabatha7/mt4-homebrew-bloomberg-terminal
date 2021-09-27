//+------------------------------------------------------------------+
//|                                                        mixup.mq4 |
//|                                              Copyright 2021, FOS |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, FOS"
#property link      ""
#property version   "1.00"
#property strict

string Output ="";
string OutputInverse="";
string OutputSet ="";
string OutputInverseSet="";
string OutputInfo = "";
string OutputInfoSet = "";
int history = 36;
string fn = "set.csv";

string pairs[] =
  {
   "USDCNH",
   "GBPUSD"
  };

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   double Result = reStart();
     {
      Print(Result);
      char InputArray[];
      StringToCharArray(StringFormat("%s|%s",OutputInfo, OutputInfoSet), InputArray);
      char OutputArray[];
      string Headers;
      int Request = WebRequest("post","http://localhost",NULL,5000,InputArray,OutputArray, Headers);
      Print(GetLastError());
     }
   OutputInfo = "";
   OutputInfoSet = "";
//delete knn;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class POINT
  {
public:
   double            x;
   int               y;
                     POINT(double x, int y) {this.x = x; this.y = y;}
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class BarInformation
  {
public:
   datetime          timestamp;
   double            open;
   double            high;
   double            close;
   double            low;

                     BarInformation(datetime timestamp, double open, double high, double close, double low)
     {
      this.timestamp = timestamp;
      this.open = open;
      this.high = high;
      this.close = close;
      this.low = low;
     }
  };

struct N
  {
   double            error;
   BarInformation    *bar_as_compared;
   string            pair;
   string            pathto;
  };

N knn[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void resize_array()
  {
//---
   N init_one, init_two, init_three;
   init_one.bar_as_compared = new BarInformation(0, 0, 0, 0, 0);
   init_one.error = 0;
   init_two.bar_as_compared = new BarInformation(0, 0, 0, 0, 0);
   init_two.error = 0;
   init_three.bar_as_compared = new BarInformation(0, 0, 0, 0, 0);
   init_three.error = 0;
   ArrayResize(knn, 3);
   knn[0] = init_one;
   knn[1] = init_two;
   knn[2] = init_three;
//---
  }
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
double reStart()
  {
//---
   ObjectsDeleteAll(0, 0);
   resize_array();

   int j = 1; // leading bar
   int i = 2; // trailing bar
   bool HasTried = false;
     {
      if(isRedBar(j) && isBlueBar(i))
        {
         conduct_procedure();
         HasTried = true;
        }

      if(isRedBar(i) && isBlueBar(j))
        {
         conduct_procedure();
         HasTried = true;
        }

      if((!isBlueBar(j) && !isRedBar(j) && (isRedBar(i) || isBlueBar(i))))
        {
         conduct_procedure();
         HasTried = true;
        }

      if(((!isBlueBar(i) && !isRedBar(i)) && (isRedBar(j) || isBlueBar(j))))
        {
         conduct_procedure();
         HasTried = true;
        }
     }
   if(HasTried)
     {
      for(int c=0; c<3; ++c)
        {
         PrintFormat("\"%s\"\n{\ndate: %s\n\tsignal is directional\n\t%s", _Symbol, TimeToString(knn[c].bar_as_compared.timestamp), pairs[0]);
        }
      return knn[0].error;
     }
   return (knn[0].error);
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
void conduct_procedure()
  {
   for(int pair_in_array_pairs=0; pair_in_array_pairs<ArraySize(pairs); ++pair_in_array_pairs)
     {
      string directory = StringFormat("samples//%s//200-40//36 bars(30)", pairs[pair_in_array_pairs]);
      int handle = FileOpen(StringFormat("%s//%s", directory, fn), FILE_READ|FILE_CSV, ";");

      string str = "";

      if(handle!=INVALID_HANDLE)
        {

         int counter = 0;

         while(!FileIsEnding(handle)) //loop through each line in file
           {
            str += FileReadString(handle); //read csv line
            str += ";";
            str += FileReadString(handle); //read csv line
            str += ";";
            str += FileReadString(handle); //read csv line
            str += ";";
            str += FileReadString(handle); //read csv line
            str += ";";
            str += FileReadString(handle); //read csv line

            if(counter > 0)
              {

               string res[];
               StringSplit(str, ';', res);
               BarInformation *this_bar;
               this_bar = new BarInformation(StringToTime(res[0]), res[1], res[2], res[3], res[4]);
               MqlDateTime ct;
               TimeToStruct(this_bar.timestamp,ct);
               Print(StringFormat("%s at %d-%d-%d", pairs[pair_in_array_pairs], ct.year, ct.mon, ct.day));

                 {
                  double se = compute_se(this_bar, pairs[pair_in_array_pairs]);
                  double seInverted =  compute_se_inverted(this_bar, pairs[pair_in_array_pairs]);

                  se = se < seInverted ? se: seInverted;
                  if(se == -1000000)
                     break;
                  if(!(se == -100000))
                    {
                     //Print(se);
                     for(int i=0; i<3; ++i)
                       {
                        if(knn[i].error == 0)
                          {
                           knn[i].error = se;
                           knn[i].bar_as_compared = this_bar;
                           knn[i].pair = StringFormat("%s//%s", pairs[pair_in_array_pairs], fn);
                           string TimeStamp = TimeToString(this_bar.timestamp);
                           StringReplace(TimeStamp, ".", "-");
                           StringReplace(TimeStamp, ":", "_");
                           knn[i].pathto = StringFormat("samples//%s//200-40//36 bars(30)//%s",  knn[i].pair, TimeStamp);
                           if(i==0)
                             {
                              OutputInfo = se == seInverted? OutputInverse: Output;
                              OutputInfoSet = se == seInverted? OutputInverseSet: OutputSet;
                             }
                           break;
                          }

                        if(knn[i].error > se)
                          {
                           knn[i].error = se;
                           knn[i].bar_as_compared = this_bar;
                           knn[i].pair = StringFormat("%s//%s", pairs[pair_in_array_pairs], fn);
                           string TimeStamp = TimeToString(this_bar.timestamp);
                           StringReplace(TimeStamp, ".", "-");
                           StringReplace(TimeStamp, ":", "_");
                           knn[i].pathto = StringFormat("samples//%s//200-40//36 bars(30)//%s",  knn[i].pair, TimeStamp);
                           if(i==0)
                             {
                              OutputInfo = se == seInverted? OutputInverse: Output;
                              OutputInfoSet = se == seInverted? OutputInverseSet: OutputSet;
                             }
                           break;
                          }
                       }
                    }
                 }
              }

            str = "";
            counter+=1;
           }
         FileClose(handle);
        }
      else
         Print(GetLastError());
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double compute_se(BarInformation *bar, string pair)
  {
   MqlDateTime ct;
   TimeToStruct(bar.timestamp,ct);

   if(pair == "USDCNH") // weighting covid data on chineses pair
     {
      if(ct.year < 2020)
         return -1000000;
     }
   if(pair == "GBPUSD")
     {
      if(ct.year < 2013)
         return -1000000;
      if(ct.year > 2015)
         return -100000;
     }
   if(pair == "EURCAD")
     {
      if(ct.year != 2020)
         return -100000;
      if(ct.mon > 6)
         return -1000000;
     }
   Output = "";
   OutputSet = "";
   string TimeStamp = TimeToString(bar.timestamp);
   StringReplace(TimeStamp, ".", "-");
   StringReplace(TimeStamp, ":", "_");
   string dir = StringFormat("samples//%s//200-40//36 bars(30)//%s", pair, TimeStamp);

   string mopath = StringFormat("%s//%s", dir, "open_m-1.txt"); // slopes
   string mhpath = StringFormat("%s//%s", dir, "high_m-1.txt"); // slopers
   string mcpath = StringFormat("%s//%s", dir, "close_m-1.txt"); // slopes
   string mlpath = StringFormat("%s//%s", dir, "low_m-1.txt"); // slopes

   if(!FileIsExist(mopath) || !FileIsExist(mhpath) || !FileIsExist(mcpath) || !FileIsExist(mlpath))
      return 100000;

   string mopens[];
   string mhighs[];
   string mclosings[];
   string mlows[];
   string sep = ",";
   ushort usep = StringGetCharacter(sep, 0);
   StringSplit(readFile(mopath, FILE_TXT), usep, mopens);
   StringSplit(readFile(mhpath, FILE_TXT), usep, mhighs);
   StringSplit(readFile(mcpath, FILE_TXT), usep, mclosings);
   StringSplit(readFile(mlpath, FILE_TXT), usep, mlows);

   double standard_error_hl = 0;
   double standard_error_ll = 0;
   double standard_error_ol = 0;
   double standard_error_cl = 0;
   int bar_shifting =1;
   int next_bar_shifting=2;
   int size = history;

     {
      double se_totalo = 0; // standard error total
      double se_totalh = 0; // standard error total
      double se_totalc = 0; // standard error total
      double se_totall = 0; // standard error total

      double spriceo = 0;
      double spriceh = 0;
      double spricec = 0;
      double spricel = 0;

      for(int i = 0; i<size; ++i)
        {

         int this_shift = bar_shifting + i; // for the test
         int next_shift = next_bar_shifting + i; // for the test

         double high = iHigh(_Symbol, PERIOD_CURRENT, this_shift); // csv file fetches trailing bar so we covert to a leading bar
         double low = iLow(_Symbol, PERIOD_CURRENT, this_shift);
         double open = iOpen(_Symbol, PERIOD_CURRENT, this_shift);
         double close = iClose(_Symbol, PERIOD_CURRENT, this_shift);

         double nopen = iOpen(_Symbol, PERIOD_CURRENT, next_shift); // refers to the next bar
         double nhigh = iHigh(_Symbol, PERIOD_CURRENT, next_shift);
         double nclose = iClose(_Symbol, PERIOD_CURRENT, next_shift);
         double nlow = iLow(_Symbol, PERIOD_CURRENT, next_shift);

         double oslope = ((nopen - open)/1); // some measurement of a slope
         double hslope = ((nhigh - high)/1); // some measurement of a slope
         double cslope = ((nclose - close)/1); // some measurement of a slope
         double lslope = ((nlow - low)/1); // some measurement of a slope

         double set_slopeo = StringToDouble(mopens[i]);
         double set_slopeh = StringToDouble(mhighs[i]);
         double set_slopec = StringToDouble(mclosings[i]);
         double set_slopel = StringToDouble(mlows[i]);

         double od = set_slopeo - oslope;
         double hd = set_slopeh - hslope;
         double cd = set_slopec - cslope;
         double ld = set_slopel - lslope;

         se_totalo += MathPow(od, 2);
         se_totalh += MathPow(hd, 2);
         se_totalc += MathPow(cd, 2);
         se_totall += MathPow(ld, 2);

         Output += StringFormat("%f,", (oslope+hslope+cslope+lslope)/4);
         OutputSet += StringFormat("%f,", (set_slopeo+set_slopeh+set_slopec+set_slopel)/4);
        }

      standard_error_ol = (se_totalo)/((size-1)-2);
      standard_error_hl = (se_totalh)/((size-1)-2);
      standard_error_cl = (se_totalc)/((size-1)-2);
      standard_error_ll = (se_totall)/((size-1)-2);
     }
   //Output += StringFormat("\"%s\",\"%s\"",pair,TimeStamp);
   //OutputSet += StringFormat("\"%s\",\"%s\"]", pair,TimeStamp);
   return (standard_error_hl + standard_error_ll + standard_error_ol + standard_error_cl)/4;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double compute_se_inverted(BarInformation *bar, string pair)
  {
   MqlDateTime ct;
   TimeToStruct(bar.timestamp,ct);
   if(pair == "USDCNH") // weighting covid data on chineses pair
     {
      if(ct.year < 2020)
         return -1000000;
     }
   if(pair == "GBPUSD")
     {
      if(ct.year < 2013)
         return -1000000;
      if(ct.year > 2015)
         return -100000;
     }
   if(pair == "EURCAD")
     {
      if(ct.year != 2020)
         return -100000;
      if(ct.mon > 6)
         return -1000000;
     }
   OutputInverse = "";
   OutputInverseSet = "";
   string TimeStamp = TimeToString(bar.timestamp);
   StringReplace(TimeStamp, ".", "-");
   StringReplace(TimeStamp, ":", "_");
   string dir = StringFormat("samples//%s//200-40//36 bars(30)//%s", pair, TimeStamp);

   string mopath = StringFormat("%s//%s", dir, "open_m-1.txt"); // slopes
   string mhpath = StringFormat("%s//%s", dir, "high_m-1.txt"); // slopers
   string mcpath = StringFormat("%s//%s", dir, "close_m-1.txt"); // slopes
   string mlpath = StringFormat("%s//%s", dir, "low_m-1.txt"); // slopes

   if(!FileIsExist(mopath) || !FileIsExist(mhpath) || !FileIsExist(mcpath) || !FileIsExist(mlpath))
      return 100000;

   string mopens[];
   string mhighs[];
   string mclosings[];
   string mlows[];
   string sep = ",";
   ushort usep = StringGetCharacter(sep, 0);
   StringSplit(readFile(mopath, FILE_TXT), usep, mopens);
   StringSplit(readFile(mhpath, FILE_TXT), usep, mhighs);
   StringSplit(readFile(mcpath, FILE_TXT), usep, mclosings);
   StringSplit(readFile(mlpath, FILE_TXT), usep, mlows);

   double standard_error_hl = 0;
   double standard_error_ll = 0;
   double standard_error_ol = 0;
   double standard_error_cl = 0;
   int bar_shifting =1;
   int next_bar_shifting=2;
   int size = history;

     {
      double se_totalo = 0; // standard error total
      double se_totalh = 0; // standard error total
      double se_totalc = 0; // standard error total
      double se_totall = 0; // standard error total

      double spriceo = 0;
      double spriceh = 0;
      double spricec = 0;
      double spricel = 0;

      for(int i = 0; i<size; ++i)
        {

         int this_shift = bar_shifting + i; // for the test
         int next_shift = next_bar_shifting + i; // for the test

         double high = iHigh(_Symbol, PERIOD_CURRENT, this_shift); // csv file fetches trailing bar so we covert to a leading bar
         double low = iLow(_Symbol, PERIOD_CURRENT, this_shift);
         double open = iOpen(_Symbol, PERIOD_CURRENT, this_shift);
         double close = iClose(_Symbol, PERIOD_CURRENT, this_shift);

         double nopen = iOpen(_Symbol, PERIOD_CURRENT, next_shift); // refers to the next bar
         double nhigh = iHigh(_Symbol, PERIOD_CURRENT, next_shift);
         double nclose = iClose(_Symbol, PERIOD_CURRENT, next_shift);
         double nlow = iLow(_Symbol, PERIOD_CURRENT, next_shift);

         double oslope = ((nopen - open)/1); // some measurement of a slope
         double hslope = ((nhigh - high)/1); // some measurement of a slope
         double cslope = ((nclose - close)/1); // some measurement of a slope
         double lslope = ((nlow - low)/1); // some measurement of a slope

         double set_slopeo = StringToDouble(mopens[i]) * -1;
         double set_slopeh = StringToDouble(mhighs[i]) * -1;
         double set_slopec = StringToDouble(mclosings[i]) * -1;
         double set_slopel = StringToDouble(mlows[i]) * -1;

         double od = set_slopeo - oslope;
         double hd = set_slopeh - hslope;
         double cd = set_slopec - cslope;
         double ld = set_slopel - lslope;

         se_totalo += MathPow(od, 2);
         se_totalh += MathPow(hd, 2);
         se_totalc += MathPow(cd, 2);
         se_totall += MathPow(ld, 2);

         OutputInverse += StringFormat("%f,", (oslope+hslope+cslope+lslope)/4);
         OutputInverseSet += StringFormat("%f,", (set_slopeo+set_slopeh+set_slopec+set_slopel)/4);
        }

      standard_error_ol = (se_totalo)/((size-1)-2);
      standard_error_hl = (se_totalh)/((size-1)-2);
      standard_error_cl = (se_totalc)/((size-1)-2);
      standard_error_ll = (se_totall)/((size-1)-2);
     }
   OutputInverse += StringFormat("\"%s\",\"%s\"",pair,TimeStamp);
   OutputInverseSet += StringFormat("\"%s\",\"%s\"", pair,TimeStamp);
   return (standard_error_hl + standard_error_ll + standard_error_ol + standard_error_cl)/4;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string readFile(string file_name, int flag_file_type=FILE_CSV)
  {
   int o = FileOpen(file_name, FILE_READ|flag_file_type);
   if(o > 0)
     {
      string str = "";
      while(!FileIsEnding(o))
        {
         //--- find out how many symbols are used for writing the time
         int str_size=FileReadInteger(o,INT_VALUE);
         //--- read the string
         str+=FileReadString(o,str_size);
        }
      FileClose(o);
      return str;
     }
   else
     {
      Print(GetLastError());
     }
   return NULL;
  }

//+------------------------------------------------------------------+
