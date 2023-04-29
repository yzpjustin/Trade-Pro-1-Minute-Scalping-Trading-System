//+------------------------------------------------------------------+
//|                                     trade pro 1 min scalping.mq5 |
//|                                                     yin zhanpeng |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "yin zhanpeng"
#property version   "1.00"
#include <Trade/Trade.mqh>
input int Infastbar = 20;  // FAST MA
input ENUM_MA_METHOD inpfastmethod = MODE_EMA;  // FAST METHOD
input ENUM_APPLIED_PRICE infastappliedprice = PRICE_CLOSE;  //FAST PRICE

input int Inmediumbar = 50;  // MEDIUM MA
input ENUM_MA_METHOD inpmediummethod = MODE_EMA;  // MEDIUM METHOD
input ENUM_APPLIED_PRICE inmediumappliedprice = PRICE_CLOSE;  // MEDIUM PRICE

input int Inslowtbar = 100;  // SLOW MA
input ENUM_MA_METHOD inpslowmethod = MODE_EMA;  //SLOW METHOD
input ENUM_APPLIED_PRICE inslowappliedprice = PRICE_CLOSE;  //SLOW PRICE

input double inpprofitration = 1.5; //TP/SP RATIO

input double inpvolume = 0.01; //LOT SIZE
input string inptradecomment = "1m scalper"; //TRADE COMMENT
input int inpmagic = 123;  // MAGIC NUM

int skiptrade = -1;


int handlefast;
int handlemedium;
int handleslow;
int handlefractal;

double indicatorbuffer[];

CTrade trade;


int OnInit()
  {
  
  if(!checkinputs()) return (INIT_PARAMETERS_INCORRECT);
  
  handlefast = iMA(_Symbol,PERIOD_CURRENT,Infastbar,0,inpfastmethod,infastappliedprice);
  handlemedium = iMA(_Symbol,PERIOD_CURRENT, Inmediumbar,0,inpmediummethod,inmediumappliedprice);
  handleslow = iMA(_Symbol,PERIOD_CURRENT, Inslowtbar,0,inpslowmethod,inslowappliedprice);
  handlefractal = iFractals(_Symbol,PERIOD_CURRENT);

  
  if( handlefast == INVALID_HANDLE ||  handlemedium == INVALID_HANDLE ||
      handleslow == INVALID_HANDLE || handlefractal == INVALID_HANDLE )
    {
     printf("Faild to create hanldes");
     return (INIT_FAILED);
    }
   
  ArraySetAsSeries( indicatorbuffer, true);
  trade.SetExpertMagicNumber(inpmagic);

   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
  IndicatorRelease(handlefast);
  IndicatorRelease(handlemedium);
  IndicatorRelease(handleslow);
  IndicatorRelease(handlefractal);

   
  }

void OnTick()
  {
  if( !NewBar() ) return;
  
  
  for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
    ulong ticket = PositionGetTicket( i );
    if ( !PositionSelectByTicket(ticket)) continue;
    if ( PositionGetString(POSITION_SYMBOL) != _Symbol ) continue;
    if ( PositionGetInteger (POSITION_MAGIC) != inpmagic ) continue;
    
    return;

    }
  int fractalbar = 3;
  int bar = 1;
  
  int copybars= fractalbar + 1;
  
  if ( CopyBuffer( handlefast, 0, 0, copybars, indicatorbuffer ) < copybars) return;
  double fast = indicatorbuffer[bar];
  double fastf = indicatorbuffer[fractalbar];
  
  
  if ( CopyBuffer( handlemedium, 0, 0, copybars, indicatorbuffer ) < copybars) return;
  double mid = indicatorbuffer[bar];
  double midf = indicatorbuffer[fractalbar];
  
  if ( CopyBuffer( handleslow, 0, 0, copybars, indicatorbuffer ) < copybars) return;
  double slow = indicatorbuffer[bar];
  double slowf = indicatorbuffer[fractalbar];
  
  
  if ( CopyBuffer(handlefractal, UPPER_LINE, 0, copybars, indicatorbuffer ) < copybars ) return;
  double fractalhi = indicatorbuffer[fractalbar];
  
  if ( CopyBuffer(handlefractal, LOWER_LINE, 0, copybars, indicatorbuffer ) < copybars ) return;
  double fractallo = indicatorbuffer[fractalbar];
  
  double close = iClose(_Symbol,PERIOD_CURRENT, bar);
  double sl = 0;
  
  
  if( fast > mid && mid > slow)
    {
     if(close < slow)
       {
        skiptrade = ORDER_TYPE_BUY;
       }
       else if(fastf > midf && midf > slowf)
              {
               if(fractallo != EMPTY_VALUE && fractallo > slowf && fractallo < fastf)
                 {
                  if(skiptrade != ORDER_TYPE_BUY)
                    {
                     sl = (fractallo < midf ) ? slow : mid;
                     opentrade(ORDER_TYPE_BUY, sl);
                    }
                    skiptrade = -1;
                    return;
                 }
              }
    }
    
    if( fast < mid && mid < slow)
       {
        if(close > slow)
          {
           skiptrade = ORDER_TYPE_SELL;
          }
          else if(fastf < midf && midf < slowf)
                 {
                  if(fractalhi != EMPTY_VALUE && fractalhi < slowf && fractalhi < fastf)
                    {
                     if(skiptrade != ORDER_TYPE_SELL)
                       {
                        sl = (fractalhi > midf ) ? slow : mid;
                        opentrade(ORDER_TYPE_SELL, sl);
                       }
                       skiptrade = -1;
                       return;
                    }
                 }
       }




  }

bool NewBar()
{

datetime currenttime =  iTime(Symbol(), Period(), 0);
static datetime previoustime =
0;
if (currenttime == previoustime ) return (false);
return (true);

}


bool checkinputs(){

bool result = true;

if (Infastbar >= Inmediumbar || Inmediumbar >= Inslowtbar){
printf("fast bar must be less than mid bar less than slow bar");

}
return (result);}





void opentrade (ENUM_ORDER_TYPE type, double sl )
{

double price = ( type == ORDER_TYPE_BUY ) ? SymbolInfoDouble( Symbol(), SYMBOL_ASK)
                                          : SymbolInfoDouble( Symbol(), SYMBOL_BID);
                                          
                                          
double tp = price + ((price - sl) * inpprofitration );
trade.PositionOpen(_Symbol, type, inpvolume,price, sl, tp, inptradecomment);
return;


}