//+------------------------------------------------------------------+
//|                                       ArtificialIntelligence.mq4 |
//|                               Copyright © 2006, Yury V. Reshetov |
//|                               Copyright © 2021, Ch. J. Bruhin    |
//|                                         http://reshetov.xnet.uz/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2021 Ch. J. Bruhin Telegram: quasselcore  https://t.me/quasselcore/"
#property link      "https://t.me/quasselcore/"
//---- input parameters
extern int TrailingStop=100; 
extern int    x1 = 135;
extern int    x2 = 127;
extern int    x3 = 16;
extern int    x4 = 93;
// StopLoss level
extern double sl = 85;
extern double lots = 0.10;
extern int MagicNumber = 888;
static int prevtime = 0;

// added to handle 5 digit pricing
double   myPoint;

int ontick(){
   DoTrail();
}
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {

// added to handle 5 digit pricing
     myPoint = SetPoint(Symbol());

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   
   if(Time[0] == prevtime) 
       return(0);
   prevtime = Time[0];
   int spread = 3;
//----
   if(IsTradeAllowed()) 
     {
       RefreshRates();
       spread = MarketInfo(Symbol(), MODE_SPREAD);
     } 
   else 
     {
       prevtime = Time[1];
       return(0);
     }
   int ticket = -1;
// check for opened position
   int total = OrdersTotal();   
//----
   for(int i = 0; i < total; i++) 
     {
       OrderSelect(i, SELECT_BY_POS, MODE_TRADES); 
       // check for symbol & magic number
       if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) 
         {
           int prevticket = OrderTicket();
           // long position is opened
           if(OrderType() == OP_BUY) 
             {
               // check profit 
               if(Bid > (OrderStopLoss() + (sl * 2  + spread) * myPoint)) 
                 {               
                   if(perceptron() < 0) 
                     { // reverse
                       ticket = OrderSend(Symbol(), OP_SELL, lots * 2, Bid, 3, Ask + sl * myPoint, 0, "AI", MagicNumber, 0, Red); 
                       Sleep(100);
                       //----
                       if(ticket < 0) 
                           prevtime = Time[1];
                       else 
                           OrderCloseBy(ticket, prevticket, Blue);   
                     } 
                   else 
                     { // trailing stop
                       if(!OrderModify(OrderTicket(), OrderOpenPrice(), Bid - sl * myPoint,0, 0, Blue)) 
                         {
                           Sleep(100);
                           prevtime = Time[1];
                         }
                     }
                 }  
               // short position is opened
             } 
           else 
             {
               // check profit 
               if(Ask < (OrderStopLoss() - (sl * 2 + spread) * myPoint)) 
                 {
                   if(perceptron() > 0) 
                     { // reverse
                       ticket = OrderSend(Symbol(), OP_BUY, lots * 2, Ask, 3,Bid - sl * myPoint, 0, "AI", MagicNumber, 0, Blue); 
                       Sleep(100);
                       //----
                       if(ticket < 0) 
                           prevtime = Time[1];
                       else 
                           OrderCloseBy(ticket, prevticket, Blue);   
                     } 
                   else 
                     { // trailing stop
                       if(!OrderModify(OrderTicket(), OrderOpenPrice(), Ask + sl * myPoint,0, 0, Blue)) 
                         {
                           Sleep(100);
                           prevtime = Time[1];
                         }
                     }
                 }  
             }
           // exit
           return(0);
         }
     }
// check for long or short position possibility
   if(perceptron() > 0) 
     { //long
       ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, 3, Bid - sl * myPoint, 0, "AI",MagicNumber, 0, Blue); 
       //----
       if(ticket < 0) 
         {
           Sleep(100);
           prevtime = Time[1];
         }
     } 
   else 
     { // short
       ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, 3, Ask + sl * myPoint, 0, "AI",MagicNumber, 0, Red); 
       if(ticket < 0) 
         {
           Sleep(100);
           prevtime = Time[1];
         }
     }
//--- exit
   return(0);
  }
//+------------------------------------------------------------------+
//| The PERCEPTRON - a perceiving and recognizing function           |
//+------------------------------------------------------------------+
double perceptron() 
  {
  // w1 = int x1 = 135 - 100 = 35
   double w1 = x1 - 100;
   // w2 = intx2 = 127 - 100 )= 27 
   double w2 = x2 - 100; // 127
   // w3 = intx3 = 16 - 100 )= -84 
   double w3 = x3 - 100; // 16 
   // w4 = intx4 = 93 - 100 )= -7 
   double w4 = x4 - 100; // 93
   double a1 = iAC(Symbol(), 0, 0);  //  0.00448
   double a2 = iAC(Symbol(), 0, 7);  // -0.00110
   double a3 = iAC(Symbol(), 0, 14); // -0.00100
   double a4 = iAC(Symbol(), 0, 21); // -0.01310
   
  //Return
  //   w1 * a1 ( 35 *  0.00448) =  4.2336
  // + w2 * a2 ( 27 * -0.00110) = -0.0297
  // + w3 * a3 (-84 * -0.00100) = -0.084
  // + w4 * a4 ( -7 * -0.01310) =  0.0917
  // = 4.2116
   return(w1 * a1 + w2 * a2 + w3 * a3 + w4 * a4);
   
   
  }


// Function to handle 5 digit pricing
// Changes value of myPoint to use 4 digit pricing to replace Point in code
double SetPoint(string mySymbol)
{
   double mPoint, myDigits;
   
   myDigits = MarketInfo (mySymbol, MODE_DIGITS);
   if (myDigits < 4)
      mPoint = 0.01;
   else
      mPoint = 0.0001;
   
   return(mPoint);
}

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Add Trailing SL        |
//+------------------------------------------------------------------+
int DoTrail()
  {
    for (int i = 0; i < OrdersTotal(); i++) {
     OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
     if ( OrderSymbol()==Symbol() && (OrderMagicNumber() == MagicNumber))  // only look if mygrid and symbol...
        {
          
          if (OrderType() == OP_BUY) {
             if(Bid-OrderOpenPrice()>Point*TrailingStop)
             {
                if(OrderStopLoss()<Bid-Point*TrailingStop)
                  {
                     OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),0,Green);
                     return(0);
                  }
             }
          }

          if (OrderType() == OP_SELL) 
          {
             if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
             {
                if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                {
                   OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),0,Red);
                   return(0);
                }
             }
          }
       }
    }
 }
 
