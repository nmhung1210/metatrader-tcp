#include "socket.mqh"
#include "actions.mqh"

input long PORT = 5555;
input string UUID = "none";
static ClientSocket *gSocket;

void OnReady()
{
  gSocket = new ClientSocket("127.0.0.1", (ushort)PORT);
}

void OnConnected()
{
  Print("Connected!");
  gSocket.Send(UUID + "\r\n");
}

void OnDisconnected()
{
  Print("Disconnected!");
  delete gSocket;
  Sleep(1000);
  gSocket = new ClientSocket("127.0.0.1", (ushort)PORT);
}

string OnMessage(string msg)
{
  uint start = GetTickCount();
  string args[];
  long len = StringSplit(msg, StringGetCharacter(",", 0), args);
  if (len <= 1)
  {
    return "";
  }
  string uuid = args[0];
  string action = args[1];
  string params[];
  ArrayCopy(params, args, 0, 2, WHOLE_ARRAY);
  string result = OnAction(action, params);
  uint time = GetTickCount() - start;
  return StringFormat("uuid=%s,time=%d,%s", uuid, time, result);
}

string OnAction(string action, string &args[])
{
  if (action == "AccountInfo")
  {
    return FXAccountInfo();
  }
  if (action == "Symbols")
  {
    return FXSymbols();
  }
  if (action == "SymbolInfo")
  {
    return FXSymbolInfo(args[0]);
  }
  //
  if (action == "BuyLimit")
  {
    return FXBuyLimit(
        args[0],                   // symbol
        StringToDouble(args[1]),   // volume
        StringToDouble(args[2]),   // price
        StringToDouble(args[3]),   // sl
        StringToDouble(args[4]),   // tp
        StringToInteger(args[5])); // magic
  }
  //
  if (action == "SellLimit")
  {
    return FXSellLimit(
        args[0],                   // symbol
        StringToDouble(args[1]),   // volume
        StringToDouble(args[2]),   // price
        StringToDouble(args[3]),   // sl
        StringToDouble(args[4]),   // tp
        StringToInteger(args[5])); // magic
  }

  //
  if (action == "BuyStop")
  {
    return FXBuyStop(
        args[0],                   // symbol
        StringToDouble(args[1]),   // volume
        StringToDouble(args[2]),   // price
        StringToDouble(args[3]),   // sl
        StringToDouble(args[4]),   // tp
        StringToInteger(args[5])); // magic
  }

  //
  if (action == "SellStop")
  {
    return FXSellStop(
        args[0],                   // symbol
        StringToDouble(args[1]),   // volume
        StringToDouble(args[2]),   // price
        StringToDouble(args[3]),   // sl
        StringToDouble(args[4]),   // tp
        StringToInteger(args[5])); // magic
  }

  //
  if (action == "Buy")
  {
    return FXBuy(
        args[0],                   // symbol
        StringToDouble(args[1]),   // volume
        StringToDouble(args[2]),   // price
        StringToDouble(args[3]),   // sl
        StringToDouble(args[4]),   // tp
        StringToInteger(args[5])); // magic
  }

  //
  if (action == "Sell")
  {
    return FXSell(
        args[0],                   // symbol
        StringToDouble(args[1]),   // volume
        StringToDouble(args[2]),   // price
        StringToDouble(args[3]),   // sl
        StringToDouble(args[4]),   // tp
        StringToInteger(args[5])); // magic
  }

  //
  if (action == "Orders")
  {
    return FXOrders(
        args[0],                  // symbol
        StringToInteger(args[1]), // offset
        StringToInteger(args[2]), // limit
        StringToInteger(args[3])  // magic
    );
  }

  //
  if (action == "OrdersTotal")
  {
    return FXOrdersTotal(
        args[0],                 // symbol
        StringToInteger(args[1]) // magic
    );
  }

  //
  if (action == "Positions")
  {
    return FXPositions(
        args[0],                  // symbol
        StringToInteger(args[1]), // offset
        StringToInteger(args[2]), // limit
        StringToInteger(args[3])  // magic
    );
  }

  //
  if (action == "PositionsTotal")
  {
    return FXPositionsTotal(
        args[0],                 // symbol
        StringToInteger(args[1]) // magic
    );
  }

  //
  if (action == "OrderModify")
  {
    return FXOrderModify(
        StringToInteger(args[0]),  // ticket
        StringToDouble(args[1]),   // price
        StringToDouble(args[2]),   // sl
        StringToDouble(args[3]),   // tp
        StringToInteger(args[4])); // expiration
  }

  //
  if (action == "OrderDelete")
  {
    return FXOrderDelete(StringToInteger(args[0])); // ticket
  }

  //
  if (action == "PositionModify")
  {
    return FXPositionModify(
        StringToInteger(args[0]), // ticket
        StringToDouble(args[1]),  // sl
        StringToDouble(args[2])); // tp
  }

  //
  if (action == "PositionClose")
  {
    return FXPositionClose(StringToInteger(args[0])); // ticket
  }

  //
  if (action == "PositionCloseAll")
  {
    return FXPositionCloseAll(
        args[0],                   // symbol
        StringToInteger(args[1])); // magic
  }

  //
  if (action == "Rates")
  {
    return FXRates(
        args[0],                  // symbol
        args[1],                  // timeframe
        StringToInteger(args[2]), // start_pos
        StringToInteger(args[3])  // count
    );
  }

  //
  if (action == "Tick")
  {
    return FXTick(
        args[0] // symbol
    );
  }

  //
  if (action == "PositionHistory")
  {
    return FXPositionHistory(
        args[0],                  // symbol
        StringToInteger(args[1]), // offset
        StringToInteger(args[2]), // limit
        StringToInteger(args[3])  // magic
    );
  }

  //
  if (action == "PositionHistoryTotal")
  {
    return FXPositionHistoryTotal(
        args[0],                 // symbol
        StringToInteger(args[1]) // magic
    );
  }

  //
  if (action == "TimeCurrent")
  {
    return FXTimeCurrent();
  }

  // --- Technical indicator integrations using actions.mqh wrappers ---
  if (action == "iAC")
    return FXiAC(
        args[0],                  // symbol
        args[1],                  // timeframe
        StringToInteger(args[2]), // shift
        StringToInteger(args[3])  // count
    );
  if (action == "iAD")
    return FXiAD(
        args[0],
        args[1],
        StringToInteger(args[2]),
        StringToInteger(args[3]));
  if (action == "iADX")
    return FXiADX(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // applied_price
        StringToInteger(args[4]), // mode
        StringToInteger(args[5]), // shift
        StringToInteger(args[6])  // count
    );
  if (action == "iADXWilder")
    return FXiADXWilder(
        args[0],
        args[1],
        StringToInteger(args[2]),
        StringToInteger(args[3]),
        StringToInteger(args[4]),
        StringToInteger(args[5]),
        StringToInteger(args[6]));
  if (action == "iAlligator")
    return FXiAlligator(
        args[0],
        args[1],
        StringToInteger(args[2]),  // jaw_period
        StringToInteger(args[3]),  // jaw_shift
        StringToInteger(args[4]),  // teeth_period
        StringToInteger(args[5]),  // teeth_shift
        StringToInteger(args[6]),  // lips_period
        StringToInteger(args[7]),  // lips_shift
        StringToInteger(args[8]),  // ma_method
        StringToInteger(args[9]),  // applied_price
        StringToInteger(args[10]), // mode
        StringToInteger(args[11]), // shift
        StringToInteger(args[12])  // count
    );
  if (action == "iAMA")
    return FXiAMA(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // fast_ema
        StringToInteger(args[4]), // slow_ema
        StringToInteger(args[5]), // applied_price
        StringToInteger(args[6]), // shift
        StringToInteger(args[7])  // count
    );
  if (action == "iAO")
    return FXiAO(
        args[0],
        args[1],
        StringToInteger(args[2]),
        StringToInteger(args[3]));
  if (action == "iATR")
    return FXiATR(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // shift
        StringToInteger(args[4])  // count
    );
  if (action == "iBearsPower")
    return FXiBearsPower(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // applied_price
        StringToInteger(args[4]), // shift
        StringToInteger(args[5])  // count
    );
  if (action == "iBands")
    return FXiBands(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToDouble(args[3]),  // deviation
        StringToInteger(args[4]), // bands_shift
        StringToInteger(args[5]), // applied_price
        StringToInteger(args[6]), // mode
        StringToInteger(args[7]), // shift
        StringToInteger(args[8])  // count
    );
  if (action == "iBullsPower")
    return FXiBullsPower(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // applied_price
        StringToInteger(args[4]), // shift
        StringToInteger(args[5])  // count
    );
  if (action == "iCCI")
    return FXiCCI(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // applied_price
        StringToInteger(args[4]), // shift
        StringToInteger(args[5])  // count
    );
  if (action == "iChaikin")
    return FXiChaikin(
        args[0],
        args[1],
        StringToInteger(args[2]), // fast_ema_period
        StringToInteger(args[3]), // slow_ema_period
        StringToInteger(args[4]), // shift
        StringToInteger(args[5])  // count
    );

  if (action == "iDEMA")
    return FXiDEMA(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // applied_price
        StringToInteger(args[4]), // shift
        StringToInteger(args[5])  // count
    );
  if (action == "iDeMarker")
    return FXiDeMarker(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // shift
        StringToInteger(args[4])  // count
    );
  if (action == "iEnvelopes")
    return FXiEnvelopes(
        args[0],
        args[1],
        StringToInteger(args[2]), // ma_period
        StringToInteger(args[3]), // ma_method
        StringToInteger(args[4]), // ma_shift
        StringToDouble(args[5]),  // deviation
        StringToInteger(args[6]), // applied_price
        StringToInteger(args[7]), // mode
        StringToInteger(args[8]), // shift
        StringToInteger(args[9])  // count
    );
  if (action == "iForce")
    return FXiForce(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // ma_method
        StringToInteger(args[4]), // applied_price
        StringToInteger(args[5]), // shift
        StringToInteger(args[6])  // count
    );
  if (action == "iFractals")
    return FXiFractals(
        args[0],
        args[1],
        StringToInteger(args[2]), // mode
        StringToInteger(args[3]), // shift
        StringToInteger(args[4])  // count
    );
  if (action == "iFrAMA")
    return FXiFrAMA(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // fast_ema
        StringToInteger(args[4]), // slow_ema
        StringToInteger(args[5]), // applied_price
        StringToInteger(args[6]), // shift
        StringToInteger(args[7])  // count
    );
  if (action == "iGator")
    return FXiGator(
        args[0],
        args[1],
        StringToInteger(args[2]), // mode
        StringToInteger(args[3]), // shift
        StringToInteger(args[4])  // count
    );
  if (action == "iIchimoku")
    return FXiIchimoku(
        args[0],
        args[1],
        StringToInteger(args[2]), // tenkan_sen
        StringToInteger(args[3]), // kijun_sen
        StringToInteger(args[4]), // senkou_span_b
        StringToInteger(args[5]), // mode
        StringToInteger(args[6]), // shift
        StringToInteger(args[7])  // count
    );
  if (action == "iBWMFI")
    return FXiBWMFI(
        args[0],
        args[1],
        StringToInteger(args[2]), // shift
        StringToInteger(args[3])  // count
    );
  if (action == "iMomentum")
    return FXiMomentum(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // applied_price
        StringToInteger(args[4]), // shift
        StringToInteger(args[5])  // count
    );
  if (action == "iMFI")
    return FXiMFI(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // shift
        StringToInteger(args[4])  // count
    );
  if (action == "iMA")
    return FXiMA(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // ma_shift
        StringToInteger(args[4]), // ma_method
        StringToInteger(args[5]), // applied_price
        StringToInteger(args[6]), // shift
        StringToInteger(args[7])  // count
    );
  if (action == "iOsMA")
    return FXiOsMA(
        args[0],
        args[1],
        StringToInteger(args[2]), // fast_ema_period
        StringToInteger(args[3]), // slow_ema_period
        StringToInteger(args[4]), // signal_period
        StringToInteger(args[5]), // applied_price
        StringToInteger(args[6]), // shift
        StringToInteger(args[7])  // count
    );
  if (action == "iMACD")
    return FXiMACD(
        args[0],
        args[1],
        StringToInteger(args[2]), // fast_ema_period
        StringToInteger(args[3]), // slow_ema_period
        StringToInteger(args[4]), // signal_period
        StringToInteger(args[5]), // applied_price
        StringToInteger(args[6]), // mode
        StringToInteger(args[7]), // shift
        StringToInteger(args[8])  // count
    );
  if (action == "iOBV")
    return FXiOBV(
        args[0],
        args[1],
        StringToInteger(args[2]), // applied_price
        StringToInteger(args[3]), // shift
        StringToInteger(args[4])  // count
    );
  if (action == "iSAR")
    return FXiSAR(
        args[0],
        args[1],
        StringToDouble(args[2]),  // step
        StringToDouble(args[3]),  // maximum
        StringToInteger(args[4]), // shift
        StringToInteger(args[5])  // count
    );
  if (action == "iRSI")
    return FXiRSI(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // applied_price
        StringToInteger(args[4]), // shift
        StringToInteger(args[5])  // count
    );
  if (action == "iRVI")
    return FXiRVI(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // mode
        StringToInteger(args[4]), // shift
        StringToInteger(args[5])  // count
    );
  if (action == "iStdDev")
    return FXiStdDev(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToDouble(args[3]),  // deviation
        StringToInteger(args[4]), // ma_method
        StringToInteger(args[5]), // applied_price
        StringToInteger(args[6]), // shift
        StringToInteger(args[7])  // count
    );
  if (action == "iStochastic")
    return FXiStochastic(
        args[0],
        args[1],
        StringToInteger(args[2]), // Kperiod
        StringToInteger(args[3]), // Dperiod
        StringToInteger(args[4]), // slowing
        StringToInteger(args[5]), // method
        StringToInteger(args[6]), // price_field
        StringToInteger(args[7]), // mode
        StringToInteger(args[8]), // shift
        StringToInteger(args[9])  // count
    );
  if (action == "iTEMA")
    return FXiTEMA(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // applied_price
        StringToInteger(args[4]), // shift
        StringToInteger(args[5])  // count
    );
  if (action == "iTriX")
    return FXiTriX(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // applied_price
        StringToInteger(args[4]), // shift
        StringToInteger(args[5])  // count
    );
  if (action == "iWPR")
    return FXiWPR(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToInteger(args[3]), // shift
        StringToInteger(args[4])  // count
    );
  if (action == "iVIDyA")
    return FXiVIDyA(
        args[0],
        args[1],
        StringToInteger(args[2]), // period
        StringToDouble(args[3]),  // alpha
        StringToInteger(args[4]), // applied_price
        StringToInteger(args[5]), // shift
        StringToInteger(args[6])  // count
    );
  if (action == "iVolumes")
    return FXiVolumes(
        args[0],
        args[1],
        StringToInteger(args[2]), // type
        StringToInteger(args[3]), // shift
        StringToInteger(args[4])  // count
    );

  return "";
}

void OnStart()
{
  Print(StringFormat("Starting uid=%s gwport=%d...", UUID, PORT));
  bool isReady = false;
  bool isConnected = false;
  while (true)
  {
    Sleep(1000);
    if (AccountInfoInteger(ACCOUNT_LOGIN) == 0 ||
        AccountInfoString(ACCOUNT_NAME) == "" ||
        AccountInfoString(ACCOUNT_COMPANY) == "" ||
        AccountInfoString(ACCOUNT_CURRENCY) == "")
    {
      continue;
    }
    if (!isReady)
    {
      isReady = true;
      OnReady();
      continue;
    }
    if (!isConnected && gSocket.IsSocketConnected())
    {
      isConnected = true;
      OnConnected();
      continue;
    }

    while (isConnected)
    {
      if (!gSocket.IsSocketConnected())
      {
        isConnected = false;
        OnDisconnected();
        break;
        ;
      }
      string msg = gSocket.Receive("\r\n");
      if (msg != "")
      {
        string reply = OnMessage(msg);
        gSocket.Send(reply + "\r\n");
      }
      else
      {
        Sleep(100);
      }
    }
  }
}