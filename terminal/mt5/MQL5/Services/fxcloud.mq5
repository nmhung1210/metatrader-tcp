#property service
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
  Print("Connected! " + UUID);
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
  string args[];
  long len = StringSplit(msg, StringGetCharacter(" ", 0), args);
  if (len <= 0)
  {
    return "";
  }
  string action = args[0];
  string params[];
  ArrayCopy(params, args, 0, 1, WHOLE_ARRAY);
  string result = OnAction(action, params);
  return StringFormat("%s", result);
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
        args[0],                   // symbol
        StringToInteger(args[1]),  // offset
        StringToInteger(args[2]),  // limit
        StringToInteger(args[3])); // magic
  }

  //
  if (action == "OrdersTotal")
  {
    return FXOrdersTotal(
        args[0],                   // symbol
        StringToInteger(args[1])); // magic
  }

  //
  if (action == "Positions")
  {
    return FXPositions(
        args[0],                   // symbol
        StringToInteger(args[1]),  // offset
        StringToInteger(args[2]),  // limit
        StringToInteger(args[3])); // magic
  }

  //
  if (action == "PositionsTotal")
  {
    return FXPositionsTotal(
        args[0],                   // symbol
        StringToInteger(args[1])); // magic
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

  if (action == "iMA")
  {
    return FXiMA(
        args[0],                 // symbol
        args[1],                 // timeframe
        StringToInteger(args[2]) // period
    );
  }

  if (action == "iRSI")
  {
    return FXiRSI(
        args[0],                 // symbol
        args[1],                 // timeframe
        StringToInteger(args[2]) // period
    );
  }

  if (action == "iMomentum")
  {
    return FXiMomentum(
        args[0],
        args[1],
        StringToInteger(args[2]));
  }

  if (action == "iForce")
  {
    return FXiForce(
        args[0],
        args[1],
        StringToInteger(args[2]));
  }

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
    Print("update");
    if (
        AccountInfoInteger(ACCOUNT_LOGIN) == 0 ||
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
