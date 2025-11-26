#property service
#include "socket.mqh"
#include "actions.mqh"

input long PORT = 5555;
input string UUID = "none";
input bool ENABLE_LOGGING = true;
static ClientSocket *gSocket;
static int logFileHandle = INVALID_HANDLE;

string GetLogFilename()
{
  return "fxcloud.log";
}

void LogMessage(string message)
{
  if (!ENABLE_LOGGING)
    return;

  string logMsg = message;
  if (StringLen(logMsg) > 256)
  {
    logMsg = StringSubstr(logMsg, 0, 253) + "...";
  }

  string filename = GetLogFilename();
  logFileHandle = FileOpen(filename, FILE_WRITE | FILE_READ | FILE_TXT | FILE_ANSI);

  if (logFileHandle != INVALID_HANDLE)
  {
    FileSeek(logFileHandle, 0, SEEK_END);
    long fileSize = FileTell(logFileHandle);
    
    // If file size exceeds 1MB, truncate it
    if (fileSize > 1024 * 1024)
    {
      FileClose(logFileHandle);
      logFileHandle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_ANSI);
    }
    
    string timestamp = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
    FileWriteString(logFileHandle, StringFormat("[%s] %s\r\n", timestamp, logMsg));
    FileClose(logFileHandle);
  }
}

void OnReady()
{
  gSocket = new ClientSocket("127.0.0.1", (ushort)PORT);
}

void OnConnected()
{
  LogMessage("Connected to gateway on port " + IntegerToString(PORT) + " with UUID: " + UUID);
  gSocket.Send(UUID + "\r\n");
}

void OnDisconnected()
{
  LogMessage("Disconnected from gateway");
  delete gSocket;
  Sleep(1000);
  gSocket = new ClientSocket("127.0.0.1", (ushort)PORT);
}

string OnMessage(string msg)
{
  LogMessage("REQUEST: " + msg);

  string args[];
  long len = StringSplit(msg, StringGetCharacter(" ", 0), args);
  if (len <= 1)
  {
    return "";
  }
  string req_id = args[0];
  string action = args[1];
  string params[];
  ArrayCopy(params, args, 0, 2, WHOLE_ARRAY);

  string result = OnAction(action, params);
  string response = req_id + " " + result;

  LogMessage("RESPONSE: " + response);
  return response;
}

double getDouble(string &args[], int index, double defaultValue = 0.0)
{
  if (index >= ArraySize(args))
  {
    return defaultValue;
  }
  return StringToDouble(args[index]);
}

long getInteger(string &args[], int index, long defaultValue = 0)
{
  if (index >= ArraySize(args))
  {
    return defaultValue;
  }
  return StringToInteger(args[index]);
}

string getString(string &args[], int index, string defaultValue = "")
{
  if (index >= ArraySize(args))
  {
    return defaultValue;
  }
  return args[index];
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
    return FXSymbolInfo(
        getString(args, 0));
  }
  //
  if (action == "BuyLimit")
  {
    return FXBuyLimit(
        getString(args, 0),   // symbol
        getDouble(args, 1),   // volume
        getDouble(args, 2),   // price
        getDouble(args, 3),   // sl
        getDouble(args, 4),   // tp
        getInteger(args, 5)); // magic
  }
  //
  if (action == "SellLimit")
  {
    return FXSellLimit(
        getString(args, 0),   // symbol
        getDouble(args, 1),   // volume
        getDouble(args, 2),   // price
        getDouble(args, 3),   // sl
        getDouble(args, 4),   // tp
        getInteger(args, 5)); // magic
  }

  //
  if (action == "BuyStop")
  {
    return FXBuyStop(
        getString(args, 0),   // symbol
        getDouble(args, 1),   // volume
        getDouble(args, 2),   // price
        getDouble(args, 3),   // sl
        getDouble(args, 4),   // tp
        getInteger(args, 5)); // magic
  }

  //
  if (action == "SellStop")
  {
    return FXSellStop(
        getString(args, 0),   // symbol
        getDouble(args, 1),   // volume
        getDouble(args, 2),   // price
        getDouble(args, 3),   // sl
        getDouble(args, 4),   // tp
        getInteger(args, 5)); // magic
  }

  //
  if (action == "Buy")
  {
    return FXBuy(
        getString(args, 0),   // symbol
        getDouble(args, 1),   // volume
        getDouble(args, 2),   // price
        getDouble(args, 3),   // sl
        getDouble(args, 4),   // tp
        getInteger(args, 5)); // magic
  }

  //
  if (action == "Sell")
  {
    return FXSell(
        getString(args, 0),   // symbol
        getDouble(args, 1),   // volume
        getDouble(args, 2),   // price
        getDouble(args, 3),   // sl
        getDouble(args, 4),   // tp
        getInteger(args, 5)); // magic
  }

  //
  if (action == "Orders")
  {
    return FXOrders(
        getString(args, 0),   // symbol
        getInteger(args, 1),  // offset
        getInteger(args, 2),  // limit
        getInteger(args, 3)); // magic
  }

  //
  if (action == "OrdersTotal")
  {
    return FXOrdersTotal(
        getString(args, 0),   // symbol
        getInteger(args, 1)); // magic
  }

  //
  if (action == "Positions")
  {
    return FXPositions(
        getString(args, 0),   // symbol
        getInteger(args, 1),  // offset
        getInteger(args, 2),  // limit
        getInteger(args, 3)); // magic
  }

  //
  if (action == "PositionsTotal")
  {
    return FXPositionsTotal(
        getString(args, 0),   // symbol
        getInteger(args, 1)); // magic
  }

  //
  if (action == "OrderModify")
  {
    return FXOrderModify(
        getInteger(args, 0),  // ticket
        getDouble(args, 1),   // price
        getDouble(args, 2),   // sl
        getDouble(args, 3),   // tp
        getInteger(args, 4)); // expiration
  }

  //
  if (action == "OrderDelete")
  {
    return FXOrderDelete(getInteger(args, 0)); // ticket
  }

  //
  if (action == "PositionModify")
  {
    return FXPositionModify(
        getInteger(args, 0), // ticket
        getDouble(args, 1),  // sl
        getDouble(args, 2)); // tp
  }

  //
  if (action == "PositionClose")
  {
    return FXPositionClose(getInteger(args, 0)); // ticket
  }

  //
  if (action == "PositionCloseAll")
  {
    return FXPositionCloseAll(
        getString(args, 0),   // symbol
        getInteger(args, 1)); // magic
  }

  //
  if (action == "Rates")
  {
    return FXRates(
        getString(args, 0),  // symbol
        getString(args, 1),  // timeframe
        getInteger(args, 2), // start_pos
        getInteger(args, 3)  // count
    );
  }

  //
  if (action == "Tick")
  {
    return FXTick(
        getString(args, 0) // symbol
    );
  }

  //
  if (action == "PositionHistory")
  {
    return FXPositionHistory(
        getString(args, 0),  // symbol
        getInteger(args, 1), // offset
        getInteger(args, 2), // limit
        getInteger(args, 3)  // magic
    );
  }

  //
  if (action == "PositionHistoryTotal")
  {
    return FXPositionHistoryTotal(
        getString(args, 0), // symbol
        getInteger(args, 1) // magic
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
        getString(args, 0), // symbol
        getString(args, 1), // timeframe
        getInteger(args, 2) // period
    );
  }

  if (action == "iRSI")
  {
    return FXiRSI(
        getString(args, 0), // symbol
        getString(args, 1), // timeframe
        getInteger(args, 2) // period
    );
  }

  if (action == "iMomentum")
  {
    return FXiMomentum(
        getString(args, 0), // symbol
        getString(args, 1), // timeframe
        getInteger(args, 2) // period
    );
  }

  if (action == "iForce")
  {
    return FXiForce(
        getString(args, 0), // symbol
        getString(args, 1), // timeframe
        getInteger(args, 2) // period
    );
  }

  return "{\"success\":0,\"error\":404}";
}

void OnStart()
{
  LogMessage(StringFormat("Starting uid=%s gwport=%d...", UUID, PORT));
  bool isReady = false;
  bool isConnected = false;
  int attempt = 0;
  while (true)
  {
    Sleep(1000);
    if (
        AccountInfoInteger(ACCOUNT_LOGIN) == 0 ||
        AccountInfoString(ACCOUNT_NAME) == "" ||
        AccountInfoString(ACCOUNT_COMPANY) == "" ||
        AccountInfoString(ACCOUNT_CURRENCY) == "")
    {
      SymbolsTotal(false); // Dummy call to refresh account info
      int lastError = GetLastError();
      LogMessage(StringFormat("Waiting for account info... Login=%d, Name=%s, Company=%s, Currency=%s, LastError=%d",
                              AccountInfoInteger(ACCOUNT_LOGIN),
                              AccountInfoString(ACCOUNT_NAME),
                              AccountInfoString(ACCOUNT_COMPANY),
                              AccountInfoString(ACCOUNT_CURRENCY),
                              lastError));
      attempt++;
      if (attempt > 10) {
        LogMessage("Connection failed.");
        delete gSocket;
        break;
      }
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
        Sleep(10);
      }
    }
  }
}
