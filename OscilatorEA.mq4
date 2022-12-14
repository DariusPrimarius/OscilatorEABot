//+------------------------------------------------------------------+
//|                                                  OscilatorEA.mq4 |
//|                                                DariuszZiemliński |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property script_show_inputs

int check               = 0;
int initial_deposit     = 0;
extern double rsiT      = 0;     // timeframe for RSI
extern double RSIP      = 14;    // period for RSI
extern int rsiRangeH    = 70;
extern int rsiRangeL    = 30;
double adxB             = 0;
double adxP             = 0;
double adxM             = 0;
double StochB           = 0;
double StochS           = 0;
double lot              = 0.01;
int ticket              = 0;
int rsiP                = RSIP;
int magic_num           = 666;
string name             = "OscilatorEA";
extern int profitCounter= 100;
int array[]; // Average of past proffits
extern double profit    = 2.5;
int rsiPeriod           = 7;
extern int timer        = 10000;
extern int timedRsip    = 5;
extern int startTime    =8;
extern int finishTime   =20;
bool resetTimer         =False;
enum closing
  {
   r=0,     // RSI direction change
   p=1,     // Profits
   b=2,     // Both Metods
   t=3,     // Both Metods with timer
  };
enum RSIperiod
  {
   off=0,    // off
   on=1,     // on
  };
input closing mode=t;
input RSIperiod dynamicPeriod = off;
//+------------------------------------------------------------------+
void OnTick()
  {
   if((Hour()>=startTime)&&(Hour()<=finishTime))
  {
   if(OrdersTotal()==0)
        {
         MakeOrder();
        }
      switch(mode)
        {
         case 0:
            CheckStatus2();
            break;
         case 1:
            CheckStatus();
            break;
         case 2:
            CheckStatus2();
            CheckStatus();
            break;
         case 3:
            CheckStatus2();
            CheckStatus();
            Timer();
            ResetTimer();
            break;
        }
      switch(dynamicPeriod)
        {
         case 1:
            DynamicRSIperiod();
            break;
         case 0:
            break;

        }
     }
  }

//+------------------------------------------------------------------+
void CloseOrders()
  {
   for(int i = 0; i == OrdersTotal() ; i++)
     {
      check = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if(OrderType() == OP_BUY)
         check = OrderClose(ticket, OrderLots(), Bid, NULL, NULL);
      if(OrderType() == OP_SELL)
         check = OrderClose(ticket, OrderLots(), Ask, NULL, NULL);
     }
  }
//+------------------------------------------------------------------+
void BuyOrder()
  {
   RefreshRates();
   ticket = OrderSend(Symbol(), OP_BUY, lot, Ask, 0, 0, 0, name,
                      magic_num, 0, clrHotPink);
  }
//+------------------------------------------------------------------+
void SellOrder()
  {
   RefreshRates();
   ticket = OrderSend(Symbol(), OP_SELL, lot, Bid, 0, 0, 0, name,
                      magic_num, 0, clrHotPink);
  }
//+------------------------------------------------------------------+
void MakeOrder()
  {
   RefreshRates();
   if(iRSI(Symbol(), rsiT, rsiP, 1,0)>rsiRangeH)
      SellOrder();

   if(iRSI(Symbol(), rsiT, rsiP, 1,0)<rsiRangeL)
      BuyOrder();

   adxB= iADX(Symbol(), 0, 7, 1,MODE_MAIN,0);
   adxP= iADX(Symbol(), 0, 7, 1,MODE_PLUSDI,0);
   adxM= iADX(Symbol(), 0, 7, 1,MODE_MINUSDI,0);
   StochB= iStochastic(Symbol(), 0, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
   StochS= iStochastic(Symbol(), 0, 5, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 0);
  }
//+------------------------------------------------------------------+
void CheckStatus2()
  {

   if(OrderSelect(ticket, SELECT_BY_TICKET)==TRUE)
     {
      if(OrderType() == OP_BUY)
        {
         if(iRSI(Symbol(), rsiT, rsiP, 1,0)>rsiRangeH)
           {
            RefreshRates();
            check = OrderClose(ticket, lot, OrderClosePrice(), 3, clrRed);
            profitCounter += 1;
            checkProfit(profitCounter);
           }
        }
      if(OrderType() == OP_SELL)
        {
         if(iRSI(Symbol(), rsiT, rsiP, 1,0)<rsiRangeL)
           {
            RefreshRates();
            check = OrderClose(ticket, lot, OrderClosePrice(), 3, clrRed);
            profitCounter += 1;
            checkProfit(profitCounter);
           }
        }
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckStatus()
  {

   if(OrderSelect(ticket, SELECT_BY_TICKET)==TRUE)
     {
      if(OrderType() == OP_BUY)
        {
         if(OrderProfit()>profit)
           {
            RefreshRates();
            check = OrderClose(ticket, lot, OrderClosePrice(), 3, clrRed);
            profitCounter += 1;
            checkProfit(profitCounter);
           }
        }
      if(OrderType() == OP_SELL)
        {
         if(OrderProfit()>profit)
           {
            RefreshRates();
            check = OrderClose(ticket, lot, OrderClosePrice(), 3, clrRed);
            profitCounter += 1;
            checkProfit(profitCounter);

           }
        }
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DynamicRSIperiod()
  {
   int arrayIndex;
   double arraySum;
   double avg;

   for(arrayIndex = 0; arrayIndex >= ArraySize(array); arrayIndex++)
      arraySum += array[arrayIndex];

   avg = arraySum/ArraySize(array);
   if(arraySum>=50)
      if(rsiP<=24)
         rsiP +=3;
   if(arraySum<=-50)
      if(rsiP>=3)
         rsiP -=3;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkProfit(int i)
  {
   if(OrderProfit()>0.5)
     {
      array[i] += 1;
     }
   else
     {
      if(OrderProfit()<0.5)
        {
         array[i] -= 1;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Timer()
  {

   if(OrderSelect(ticket, SELECT_BY_TICKET)==TRUE)
     {
      if(TimeCurrent()-OrderOpenTime()>timer)
        {
         rsiP=timedRsip;
         resetTimer=True;
         
        }
     }
  }

void ResetTimer()
{
      if(OrderOpenTime()<100)
         rsiP=14;
}


//+------------------------------------------------------------------+
int OnInit()
  {
   Print("Checkpoint Init started");
   initial_deposit = AccountBalance();
   ArrayResize(array,profitCounter);
   profitCounter = 0;

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
