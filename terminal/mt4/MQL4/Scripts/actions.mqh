#property strict

ENUM_TIMEFRAMES StringToTimeframe(string timeframe)
{
  if (timeframe == "M1")
  {
    return PERIOD_M1;
  }
  if (timeframe == "M5")
  {
    return PERIOD_M5;
  }
  if (timeframe == "M15")
  {
    return PERIOD_M15;
  }
  if (timeframe == "M30")
  {
    return PERIOD_M30;
  }
  if (timeframe == "H1")
  {
    return PERIOD_H1;
  }
  if (timeframe == "H4")
  {
    return PERIOD_H4;
  }
  if (timeframe == "D1")
  {
    return PERIOD_D1;
  }
  if (timeframe == "W1")
  {
    return PERIOD_W1;
  }
  if (timeframe == "MN1")
  {
    return PERIOD_MN1;
  }
  return PERIOD_CURRENT;
}

string OrderTypeString(long type)
{
  switch (type)
  {
  case OP_BUY:
    return "BUY";
  case OP_SELL:
    return "SELL";
  case OP_BUYLIMIT:
    return "BUY_LIMIT";
  case OP_SELLLIMIT:
    return "SELL_LIMIT";
  case OP_BUYSTOP:
    return "BUY_STOP";
  case OP_SELLSTOP:
    return "SELL_STOP";
  }
  return "UNKNOWN";
}

string getDateTime()
{
  return TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
}

double NormalizePrice(string symbol, double price)
{
  double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
  return MathRound(price / tickSize) * tickSize;
}

string FXAccountInfo()
{
  string result = "{";
  result += StringFormat("\"login\":%I64d,", AccountInfoInteger(ACCOUNT_LOGIN));
  result += StringFormat("\"trade_mode\":%I64d,", AccountInfoInteger(ACCOUNT_TRADE_MODE));
  result += StringFormat("\"leverage\":%I64d,", AccountInfoInteger(ACCOUNT_LEVERAGE));
  result += StringFormat("\"limit_orders\":%I64d,", AccountInfoInteger(ACCOUNT_LIMIT_ORDERS));
  result += StringFormat("\"margin_so_mode\":%I64d,", AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE));
  result += StringFormat("\"trade_allowed\":%I64d,", AccountInfoInteger(ACCOUNT_TRADE_ALLOWED));
  result += StringFormat("\"trade_expert\":%I64d,", AccountInfoInteger(ACCOUNT_TRADE_EXPERT));
  result += StringFormat("\"balance\":%f,", AccountInfoDouble(ACCOUNT_BALANCE));
  result += StringFormat("\"credit\":%f,", AccountInfoDouble(ACCOUNT_CREDIT));
  result += StringFormat("\"profit\":%f,", AccountInfoDouble(ACCOUNT_PROFIT));
  result += StringFormat("\"equity\":%f,", AccountInfoDouble(ACCOUNT_EQUITY));
  result += StringFormat("\"margin\":%f,", AccountInfoDouble(ACCOUNT_MARGIN));
  result += StringFormat("\"margin_free\":%f,", AccountInfoDouble(ACCOUNT_MARGIN_FREE));
  result += StringFormat("\"margin_level\":%f,", AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
  result += StringFormat("\"margin_so_call\":%f,", AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL));
  result += StringFormat("\"margin_so_so\":%f,", AccountInfoDouble(ACCOUNT_MARGIN_SO_SO));
  result += StringFormat("\"name\":\"%s\",", AccountInfoString(ACCOUNT_NAME));
  result += StringFormat("\"server\":\"%s\",", AccountInfoString(ACCOUNT_SERVER));
  result += StringFormat("\"currency\":\"%s\",", AccountInfoString(ACCOUNT_CURRENCY));
  result += StringFormat("\"company\":\"%s\",", AccountInfoString(ACCOUNT_COMPANY));
  result += StringFormat("\"is_demo\":%I64d,", IsDemo());
  result += StringFormat("\"success\":%I64d", true);
  result += "}";
  return result;
}

string FXSymbols()
{
  string result = "{";
  long total = SymbolsTotal(false);
  for (long i = 0; i < total; i++)
  {
    if (i > 0)
      result += ",";
    result += StringFormat("\"data[%d]\":\"%s\"", i, SymbolName(i, false));
  }
  result += StringFormat(",\"success\":%I64d}", true);
  return result;
}

string FXSymbolInfo(const string symbol)
{
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  MqlTick tick;
  if (!SymbolInfoTick(symbol, tick))
  {
    return "{\"success\":0,\"error\":404}";
  }
  string description = SymbolInfoString(symbol, SYMBOL_DESCRIPTION);
  StringReplace(description, "=", "_");
  StringReplace(description, ",", "_");

  string result = "{";
  result += StringFormat("\"data\":{\"time\":%I64d,", (long)SymbolInfoInteger(symbol, SYMBOL_TIME));
  result += StringFormat("\"digits\":%I64d,", (long)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
  result += StringFormat("\"spread_float\":%I64d,", (long)SymbolInfoInteger(symbol, SYMBOL_SPREAD_FLOAT));
  result += StringFormat("\"spread\":%I64d,", (long)SymbolInfoInteger(symbol, SYMBOL_SPREAD));
  result += StringFormat("\"trade_cal_mode\":%I64d,", (long)SymbolInfoInteger(symbol, SYMBOL_TRADE_CALC_MODE));
  result += StringFormat("\"trade_mode\":%I64d,", (long)SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE));
  result += StringFormat("\"start_time\":%I64d,", (long)SymbolInfoInteger(symbol, SYMBOL_START_TIME));
  result += StringFormat("\"expiration_time\":%I64d,", (long)SymbolInfoInteger(symbol, SYMBOL_EXPIRATION_TIME));
  result += StringFormat("\"trade_stops_level\":%I64d,", (long)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL));
  result += StringFormat("\"trade_freeze_level\":%I64d,", (long)SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL));
  result += StringFormat("\"trade_exemode\":%I64d,", (long)SymbolInfoInteger(symbol, SYMBOL_TRADE_EXEMODE));
  result += StringFormat("\"swap_mode\":%I64d,", (long)SymbolInfoInteger(symbol, SYMBOL_SWAP_MODE));
  result += StringFormat("\"swap_rollover3days\":%I64d,", (long)SymbolInfoInteger(symbol, SYMBOL_SWAP_ROLLOVER3DAYS));
  result += StringFormat("\"bid\":%f,", tick.bid);
  result += StringFormat("\"ask\":%f,", tick.ask);
  result += StringFormat("\"point\":%f,", SymbolInfoDouble(symbol, SYMBOL_POINT));
  result += StringFormat("\"tick_value\":%f,", SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE));
  result += StringFormat("\"tick_size\":%f,", SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE));
  result += StringFormat("\"trade_contract_size\":%f,", SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE));
  result += StringFormat("\"volume_min\":%f,", SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN));
  result += StringFormat("\"volume_max\":%f,", SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX));
  result += StringFormat("\"volume_step\":%f,", SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP));
  result += StringFormat("\"swap_long\":%f,", SymbolInfoDouble(symbol, SYMBOL_SWAP_LONG));
  result += StringFormat("\"swap_short\":%f,", SymbolInfoDouble(symbol, SYMBOL_SWAP_SHORT));
  result += StringFormat("\"margin_initial\":%f,", SymbolInfoDouble(symbol, SYMBOL_MARGIN_INITIAL));
  result += StringFormat("\"margin_maintenance\":%f,", SymbolInfoDouble(symbol, SYMBOL_MARGIN_MAINTENANCE));
  result += StringFormat("\"currency_base\":\"%s\",", SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE));
  result += StringFormat("\"currency_profit\":\"%s\",", SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT));
  result += StringFormat("\"currency_margin\":\"%s\",", SymbolInfoString(symbol, SYMBOL_CURRENCY_MARGIN));
  result += StringFormat("\"description\":\"%s\",", description);
  result += StringFormat("\"path\":\"%s\"", SymbolInfoString(symbol, SYMBOL_PATH));
  result += "},\"success\":1}";
  return result;
}

string FXBuyLimit(string symbol, double volume, double price, double sl = 0, double tp = 0, long magic = 0)
{
  string result = "{";
  price = NormalizePrice(symbol, price);
  sl = NormalizePrice(symbol, sl);
  tp = NormalizePrice(symbol, tp);
  long ticket = OrderSend(symbol, OP_BUYLIMIT, volume, price, 10, sl, tp, StringFormat("%g|%s", price, getDateTime()), magic);
  result += StringFormat("\"success\":%I64d", ticket >= 0);
  if (ticket < 0)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXSellLimit(string symbol, double volume, double price, double sl = 0, double tp = 0, long magic = 0)
{
  string result = "{";
  price = NormalizePrice(symbol, price);
  sl = NormalizePrice(symbol, sl);
  tp = NormalizePrice(symbol, tp);
  long ticket = OrderSend(symbol, OP_SELLLIMIT, volume, price, 10, sl, tp, StringFormat("%g|%s", price, getDateTime()), magic);
  result += StringFormat("\"success\":%I64d", ticket >= 0);
  if (ticket < 0)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXBuyStop(string symbol, double volume, double price, double sl = 0, double tp = 0, long magic = 0)
{
  string result = "{";
  price = NormalizePrice(symbol, price);
  sl = NormalizePrice(symbol, sl);
  tp = NormalizePrice(symbol, tp);
  long ticket = OrderSend(symbol, OP_BUYSTOP, volume, price, 10, sl, tp, StringFormat("%g|%s", price, getDateTime()), magic);
  result += StringFormat("\"success\":%I64d", ticket >= 0);
  if (ticket < 0)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXSellStop(string symbol, double volume, double price, double sl = 0, double tp = 0, long magic = 0)
{
  string result = "{";
  price = NormalizePrice(symbol, price);
  sl = NormalizePrice(symbol, sl);
  tp = NormalizePrice(symbol, tp);
  long ticket = OrderSend(symbol, OP_SELLSTOP, volume, price, 10, sl, tp, StringFormat("%g|%s", price, getDateTime()), magic);
  result += StringFormat("\"success\":%I64d", ticket >= 0);
  if (ticket < 0)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXBuy(string symbol, double volume, double price = 0, double sl = 0, double tp = 0, long magic = 0)
{
  string result = "{";
  MqlTick tick;
  if (price == 0)
  {
    RefreshRates();
    if (!SymbolInfoTick(symbol, tick))
    {
      return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
    }
    price = tick.ask;
  }
  price = NormalizePrice(symbol, price);
  sl = NormalizePrice(symbol, sl);
  tp = NormalizePrice(symbol, tp);
  long ticket = OrderSend(symbol, OP_BUY, volume, price, 10, sl, tp, StringFormat("%g|%s", price, getDateTime()), magic);
  result += StringFormat("\"success\":%I64d", ticket >= 0);
  if (ticket < 0)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXSell(string symbol, double volume, double price = 0, double sl = 0, double tp = 0, long magic = 0)
{
  string result = "{";
  MqlTick tick;
  if (price == 0)
  {
    RefreshRates();
    if (!SymbolInfoTick(symbol, tick))
    {
      return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
    }
    price = tick.bid;
  }
  price = NormalizePrice(symbol, price);
  sl = NormalizePrice(symbol, sl);
  tp = NormalizePrice(symbol, tp);
  long ticket = OrderSend(symbol, OP_SELL, volume, price, 10, sl, tp, StringFormat("%g|%s", price, getDateTime()), magic);
  result += StringFormat("\"success\":%I64d", ticket >= 0);
  if (ticket < 0)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXOrders(string symbol = "", long offset = 0, long limit = 20, long magic = 0)
{
  string result = "{";
  long total = OrdersTotal();
  long count = 0;
  long index = 0;

  limit = MathMin(100, limit);
  result += "\"data\":[";
  for (long pos = total - 1; pos >= 0; pos--)
  {
    if (OrderSelect(pos, SELECT_BY_POS) == false)
    {
      continue;
    }
    if (OrderType() == OP_BUY || OrderType() == OP_SELL)
    {
      continue;
    }
    if (symbol != "" && OrderSymbol() != symbol)
    {
      continue;
    }
    if (magic != 0 && OrderMagicNumber() != magic)
    {
      continue;
    }
    if (count < limit + offset && count >= offset)
    {
      if (index > 0)
      {
        result += ",";
      }
      result += "{";
      result += StringFormat("\"ticket\":%I64d,", OrderTicket());
      result += StringFormat("\"type\":\"%s\",", OrderTypeString(OrderType()));
      result += StringFormat("\"price\":%f,", OrderOpenPrice());
      result += StringFormat("\"volume\":%f,", OrderLots());
      result += StringFormat("\"sl\":%f,", OrderStopLoss());
      result += StringFormat("\"tp\":%f,", OrderTakeProfit());
      result += StringFormat("\"open_time\":%I64d,", OrderOpenTime());
      result += StringFormat("\"expiration_time\":%I64d,", OrderExpiration());
      result += StringFormat("\"magic\":%I64d", OrderMagicNumber());
      result += "}";
      index++;
    }
    count++;
  }
  result += "],";
  result += StringFormat("\"total\":%I64d,", count);
  result += StringFormat("\"limit\":%I64d,", limit);
  result += StringFormat("\"success\":%I64d", true);
  result += "}";
  return result;
}

string FXOrdersTotal(string symbol = "", long magic = 0)
{
  string result = "{";
  long total = OrdersTotal();
  long count = 0;
  for (long pos = 0; pos < total; pos++)
  {
    if (OrderSelect(pos, SELECT_BY_POS) == false)
    {
      continue;
    }
    if (OrderType() == OP_BUY || OrderType() == OP_SELL)
    {
      continue;
    }
    if (symbol != "" && OrderSymbol() != symbol)
    {
      continue;
    }
    if (magic != 0 && OrderMagicNumber() != magic)
    {
      continue;
    }
    count++;
  }
  result += StringFormat("\"data\":%I64d,", count);
  result += StringFormat("\"success\":%I64d", true);
  result += "}";
  return result;
}

string FXPositions(string symbol = "", long offset = 0, long limit = 20, long magic = 0)
{
  string result = "{";
  long total = OrdersTotal();
  long count = 0;
  long index = 0;

  limit = MathMin(100, limit);

  result += "\"data\":[";
  for (long pos = total - 1; pos >= 0; pos--)
  {
    if (OrderSelect(pos, SELECT_BY_POS) == false)
    {
      continue;
    }
    if (OrderType() != OP_BUY && OrderType() != OP_SELL)
    {
      continue;
    }
    if (symbol != "" && OrderSymbol() != symbol)
    {
      continue;
    }
    if (magic != 0 && OrderMagicNumber() != magic)
    {
      continue;
    }

    if (count < limit + offset && count >= offset)
    {
      if (index > 0)
        result += ",";
      result += "{";
      result += StringFormat("\"ticket\":%I64d,", OrderTicket());
      result += StringFormat("\"type\":\"%s\",", OrderTypeString(OrderType()));
      result += StringFormat("\"symbol\":\"%s\",", OrderSymbol());
      result += StringFormat("\"price\":%f,", OrderOpenPrice());
      result += StringFormat("\"volume\":%f,", OrderLots());
      result += StringFormat("\"profit\":%f,", OrderProfit());
      result += StringFormat("\"swap\":%f,", OrderSwap());
      result += StringFormat("\"sl\":%f,", OrderStopLoss());
      result += StringFormat("\"tp\":%f,", OrderTakeProfit());
      result += StringFormat("\"open_time\":%I64d,", OrderOpenTime());
      result += StringFormat("\"magic\":%I64d", OrderMagicNumber());
      result += "}";
      index++;
    }
    count++;
  }
  result += "],";
  result += StringFormat("\"total\":%I64d,", count);
  result += StringFormat("\"limit\":%I64d,", limit);
  result += StringFormat("\"success\":%I64d", true);
  result += "}";
  return result;
}

string FXPositionsTotal(string symbol = "", long magic = 0)
{
  string result = "{";
  long total = OrdersTotal();
  long count = 0;
  for (long pos = total - 1; pos >= 0; pos--)
  {
    if (OrderSelect(pos, SELECT_BY_POS) == false)
    {
      continue;
    }
    if (OrderType() != OP_BUY && OrderType() != OP_SELL)
    {
      continue;
    }
    if (symbol != "" && OrderSymbol() != symbol)
    {
      continue;
    }
    if (magic != 0 && OrderMagicNumber() != magic)
    {
      continue;
    }
    count++;
  }
  result += StringFormat("\"data\":%I64d,", count);
  result += StringFormat("\"success\":%I64d", true);
  result += "}";
  return result;
}

string FXOrderModify(long ticket, double price, double sl = 0, double tp = 0, long expiration = 0)
{
  string result = "{";
  if (!OrderSelect(ticket, SELECT_BY_TICKET))
  {
    return "{\"success\":0,\"error\":404}";
  }
  if (OrderType() == OP_BUY || OrderType() == OP_SELL)
  {
    return "{\"success\":0,\"error\":404}";
  }
  string symbol = OrderSymbol();
  price = NormalizePrice(symbol, price);
  sl = NormalizePrice(symbol, sl);
  tp = NormalizePrice(symbol, tp);
  bool success = OrderModify(ticket, price, sl, tp, expiration);
  result += StringFormat("\"success\":%I64d", success);
  if (!success)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXOrderDelete(long ticket)
{
  string result = "{";
  bool success = OrderDelete(ticket);
  result += StringFormat("\"success\":%I64d", success);
  if (!success)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXPositionModify(long ticket, double sl, double tp)
{
  string result = "{";
  if (!OrderSelect(ticket, SELECT_BY_TICKET))
  {
    return "{\"success\":0,\"error\":404}";
  }
  if (OrderType() != OP_BUY && OrderType() != OP_SELL)
  {
    return "{\"success\":0,\"error\":404}";
  }
  string symbol = OrderSymbol();
  sl = NormalizePrice(symbol, sl);
  tp = NormalizePrice(symbol, tp);
  bool success = OrderModify(ticket, OrderOpenPrice(), sl, tp, 0);
  result += StringFormat("\"success\":%I64d", success);
  if (!success)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXPositionClose(long ticket)
{
  string result = "{";
  if (!OrderSelect(ticket, SELECT_BY_TICKET))
  {
    return "{\"success\":0,\"error\":404}";
  }
  if (OrderType() != OP_BUY && OrderType() != OP_SELL)
  {
    return "{\"success\":0,\"error\":404}";
  }

  string symbol = OrderSymbol();
  double lotSize = OrderLots();
  int retries = 10;
  bool success = false;
  int error = 0;

  do
  {
    RefreshRates();
    double ask = MarketInfo(symbol, MODE_ASK);
    double bid = MarketInfo(symbol, MODE_BID);
    double closePrice = (OrderType() == OP_BUY) ? bid : ask;
    success = OrderClose(ticket, lotSize, closePrice, 10);
    error = GetLastError();
  } while (retries-- > 0 && !success && error == ERR_INVALID_PRICE);

  result += StringFormat("\"success\":%I64d", success);
  if (!success)
  {
    result += StringFormat(",\"error\":%I64d", error);
  }
  result += "}";
  return result;
}

string FXRates(string symbol, string timeframe, long start_pos, long count)
{
  SymbolSelect(symbol, true);
  MqlRates rates[];

  ENUM_TIMEFRAMES tf = StringToTimeframe(timeframe);

  long copied = CopyRates(symbol, tf, (int)start_pos, count, rates);
  if (copied != count || copied <= 0)
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }

  string result = "{\"data\":[";
  for (long i = 0; i < copied; i++)
  {
    if (i > 0)
      result += ",";
    result += StringFormat("{\"time\":%I64d,", rates[i].time);
    result += StringFormat("\"open\":%f,", rates[i].open);
    result += StringFormat("\"high\":%f,", rates[i].high);
    result += StringFormat("\"low\":%f,", rates[i].low);
    result += StringFormat("\"close\":%f,", rates[i].close);
    result += StringFormat("\"tick_volume\":%f,", rates[i].tick_volume);
    result += StringFormat("\"spread\":%f,", rates[i].spread);
    result += StringFormat("\"real_volume\":%f}", rates[i].real_volume);
  }
  result += StringFormat("],\"success\":%I64d}", true);
  return result;
}

string FXTick(string symbol)
{
  if (!SymbolSelect(symbol, true))
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }
  MqlTick tick;
  if (!SymbolInfoTick(symbol, tick))
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }
  string result = "{";
  result += "\"data\":{";
  result += StringFormat("\"time\":%I64d,", tick.time);
  result += StringFormat("\"bid\":%f,", tick.bid);
  result += StringFormat("\"ask\":%f,", tick.ask);
  result += StringFormat("\"last\":%f,", tick.last);
  result += StringFormat("\"volume\":%f", tick.volume);
  result += "},";
  result += StringFormat("\"success\":%I64d", true);
  result += "}";
  return result;
}

string FXPositionCloseAll(string symbol = "", long magic = 0)
{
  MqlTick tick;
  if (!SymbolInfoTick(symbol, tick))
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }
  string result = "{";
  long total = OrdersTotal();

  double ask = tick.ask;
  double bid = tick.bid;
  bool success = true;
  int error = 0;

  for (long pos = 0; pos < total; pos++)
  {
    if (OrderSelect(pos, SELECT_BY_POS) == false)
    {
      continue;
    }
    if (OrderType() != OP_BUY && OrderType() != OP_SELL)
    {
      continue;
    }
    if (symbol != "" && OrderSymbol() != symbol)
    {
      continue;
    }
    if (magic != 0 && OrderMagicNumber() != magic)
    {
      continue;
    }

    double closePrice = OrderType() == OP_BUY ? bid : ask;
    bool closed = OrderClose(OrderTicket(), OrderLots(), closePrice, 10);
    if (!closed)
    {
      success = false;
      error = GetLastError();
    }
  }
  result += StringFormat("\"success\":%I64d", success);
  if (!success)
  {
    result += StringFormat(",\"error\":%d", error);
  }
  result += "}";
  return result;
}

string FXPositionHistory(string symbol = "", long offset = 0, long limit = 20, long magic = 0)
{
  string result = "{\"data\":[";
  long count = 0;
  long index = 0;
  long deals = OrdersHistoryTotal();

  limit = MathMin(limit, 100);

  for (long i = deals - 1; i >= 0; i--)
  {
    if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == false)
    {
      continue;
    }
    long deal_ticket = OrderTicket();
    long deal_type = OrderType();
    if (
        (deal_type != OP_BUY && deal_type != OP_SELL) ||
        (symbol != "" && OrderSymbol() != symbol) ||
        (magic != 0 && OrderMagicNumber() != magic))
    {
      continue;
    }

    if (count < limit + offset && count >= offset)
    {
      if (index > 0)
        result += ",";
      result += "{";
      result += StringFormat("\"ticket\":%I64d,", deal_ticket);
      result += StringFormat("\"type\":\"%s\",", OrderTypeString(OrderType()));
      result += StringFormat("\"symbol\":\"%s\",", OrderSymbol());
      result += StringFormat("\"open_price\":%f,", OrderOpenPrice());
      result += StringFormat("\"close_price\":%f,", OrderClosePrice());
      result += StringFormat("\"volume\":%f,", OrderLots());
      result += StringFormat("\"profit\":%f,", OrderProfit());
      result += StringFormat("\"swap\":%f,", OrderSwap());
      result += StringFormat("\"commission\":%f,", OrderCommission());
      result += StringFormat("\"open_time\":%I64d,", OrderOpenTime());
      result += StringFormat("\"close_time\":%I64d,", OrderCloseTime());
      result += StringFormat("\"magic\":%I64d", OrderMagicNumber());
      result += "}";
      index++;
    }
    count++;
  }
  result += "],";
  result += StringFormat("\"total\":%I64d,", count);
  result += StringFormat("\"limit\":%I64d,", limit);
  result += StringFormat("\"success\":%I64d", true);
  result += "}";
  return result;
}

string FXPositionHistoryTotal(string symbol = "", long magic = 0)
{
  string result = "{";
  long count = 0;
  long deals = OrdersHistoryTotal();

  for (long i = deals - 1; i >= 0; i--)
  {
    if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == false)
    {
      continue;
    }
    long deal_ticket = OrderTicket();
    long deal_type = OrderType();
    if (
        (deal_type != OP_BUY && deal_type != OP_SELL) ||
        (symbol != "" && OrderSymbol() != symbol) ||
        (magic != 0 && OrderMagicNumber() != magic))
    {
      continue;
    }
    count++;
  }
  result += StringFormat("\"data\":%I64d,", count);
  result += StringFormat("\"success\":%I64d", true);
  result += "}";
  return result;
}

string FXTimeCurrent()
{
  string result = "{";
  result += StringFormat("\"data\":%I64d,", TimeCurrent());
  result += StringFormat("\"success\":%I64d", true);
  result += "}";
  return result;
}

string FXiAC(string symbol, string timeframe, int shift = 0)
{
  double value = iAC(symbol, StringToTimeframe(timeframe), shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiAD(string symbol, string timeframe, int shift = 0)
{
  double value = iAD(symbol, StringToTimeframe(timeframe), shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiADX(string symbol, string timeframe, int period = 14, int applied_price = PRICE_CLOSE, int mode = MODE_MAIN, int shift = 0)
{
  double value = iADX(symbol, StringToTimeframe(timeframe), period, applied_price, mode, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiADXWilder(string symbol, string timeframe, int period = 14, int applied_price = PRICE_CLOSE, int mode = MODE_MAIN, int shift = 0)
{
  double value = iADXWilder(symbol, StringToTimeframe(timeframe), period, applied_price, mode, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiAlligator(string symbol, string timeframe, int jaw_period = 13, int jaw_shift = 8, int teeth_period = 8, int teeth_shift = 5, int lips_period = 5, int lips_shift = 3, int ma_method = MODE_SMMA, int applied_price = PRICE_MEDIAN, int mode = 0, int shift = 0)
{
  double value = iAlligator(symbol, StringToTimeframe(timeframe), jaw_period, jaw_shift, teeth_period, teeth_shift, lips_period, lips_shift, ma_method, applied_price, mode, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiAMA(string symbol, string timeframe, int period = 9, int fast_ema = 2, int slow_ema = 30, int applied_price = PRICE_CLOSE, int shift = 0)
{
  double value = iAMA(symbol, StringToTimeframe(timeframe), period, fast_ema, slow_ema, applied_price, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiAO(string symbol, string timeframe, int shift = 0)
{
  double value = iAO(symbol, StringToTimeframe(timeframe), shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiATR(string symbol, string timeframe, int period = 14, int shift = 0)
{
  double value = iATR(symbol, StringToTimeframe(timeframe), period, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiBearsPower(string symbol, string timeframe, int period = 13, int applied_price = PRICE_CLOSE, int shift = 0)
{
  double value = iBearsPower(symbol, StringToTimeframe(timeframe), period, applied_price, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiBands(string symbol, string timeframe, int period = 20, int deviation = 2, int bands_shift = 0, int applied_price = PRICE_CLOSE, int mode = MODE_MAIN, int shift = 0)
{
  double value = iBands(symbol, StringToTimeframe(timeframe), period, deviation, bands_shift, applied_price, mode, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiBullsPower(string symbol, string timeframe, int period = 13, int applied_price = PRICE_CLOSE, int shift = 0)
{
  double value = iBullsPower(symbol, StringToTimeframe(timeframe), period, applied_price, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiCCI(string symbol, string timeframe, int period = 14, int applied_price = PRICE_TYPICAL, int shift = 0)
{
  double value = iCCI(symbol, StringToTimeframe(timeframe), period, applied_price, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiChaikin(string symbol, string timeframe, int fast_ema_period = 3, int slow_ema_period = 10, int shift = 0)
{
  double value = iChaikin(symbol, StringToTimeframe(timeframe), fast_ema_period, slow_ema_period, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiCustom(string symbol, string timeframe, string indicator, int shift = 0)
{
  double value = iCustom(symbol, StringToTimeframe(timeframe), indicator, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiDEMA(string symbol, string timeframe, int period = 14, int applied_price = PRICE_CLOSE, int shift = 0)
{
  double value = iDEMA(symbol, StringToTimeframe(timeframe), period, applied_price, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiDeMarker(string symbol, string timeframe, int period = 14, int shift = 0)
{
  double value = iDeMarker(symbol, StringToTimeframe(timeframe), period, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiEnvelopes(string symbol, string timeframe, int ma_period = 14, int ma_method = MODE_SMA, int ma_shift = 0, double deviation = 0.1, int applied_price = PRICE_CLOSE, int mode = MODE_MAIN, int shift = 0)
{
  double value = iEnvelopes(symbol, StringToTimeframe(timeframe), ma_period, ma_method, ma_shift, deviation, applied_price, mode, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiForce(string symbol, string timeframe, int period = 13, int ma_method = MODE_SMA, int applied_price = PRICE_CLOSE, int shift = 0)
{
  double value = iForce(symbol, StringToTimeframe(timeframe), period, ma_method, applied_price, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiFractals(string symbol, string timeframe, int mode = MODE_UPPER, int shift = 0)
{
  double value = iFractals(symbol, StringToTimeframe(timeframe), mode, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiFrAMA(string symbol, string timeframe, int period = 14, int fast_ema = 2, int slow_ema = 30, int applied_price = PRICE_CLOSE, int shift = 0)
{
  double value = iFrAMA(symbol, StringToTimeframe(timeframe), period, fast_ema, slow_ema, applied_price, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiGator(string symbol, string timeframe, int mode = 0, int shift = 0)
{
  double value = iGator(symbol, StringToTimeframe(timeframe), mode, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiIchimoku(string symbol, string timeframe, int tenkan_sen = 9, int kijun_sen = 26, int senkou_span_b = 52, int mode = 0, int shift = 0)
{
  double value = iIchimoku(symbol, StringToTimeframe(timeframe), tenkan_sen, kijun_sen, senkou_span_b, mode, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiBWMFI(string symbol, string timeframe, int shift = 0)
{
  double value = iBWMFI(symbol, StringToTimeframe(timeframe), shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiMomentum(string symbol, string timeframe, int period = 14, int applied_price = PRICE_CLOSE, int shift = 0)
{
  double value = iMomentum(symbol, StringToTimeframe(timeframe), period, applied_price, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiMFI(string symbol, string timeframe, int period = 14, int shift = 0)
{
  double value = iMFI(symbol, StringToTimeframe(timeframe), period, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiMA(string symbol, string timeframe, int period = 14, int ma_shift = 0, int ma_method = MODE_SMA, int applied_price = PRICE_CLOSE, int shift = 0)
{
  double value = iMA(symbol, StringToTimeframe(timeframe), period, ma_shift, ma_method, applied_price, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiOsMA(string symbol, string timeframe, int fast_ema_period = 12, int slow_ema_period = 26, int signal_period = 9, int applied_price = PRICE_CLOSE, int shift = 0)
{
  double value = iOsMA(symbol, StringToTimeframe(timeframe), fast_ema_period, slow_ema_period, signal_period, applied_price, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiMACD(string symbol, string timeframe, int fast_ema_period = 12, int slow_ema_period = 26, int signal_period = 9, int applied_price = PRICE_CLOSE, int mode = MODE_MAIN, int shift = 0)
{
  double value = iMACD(symbol, StringToTimeframe(timeframe), fast_ema_period, slow_ema_period, signal_period, applied_price, mode, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiOBV(string symbol, string timeframe, int applied_price = PRICE_CLOSE, int shift = 0)
{
  double value = iOBV(symbol, StringToTimeframe(timeframe), applied_price, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiSAR(string symbol, string timeframe, double step = 0.02, double maximum = 0.2, int shift = 0)
{
  double value = iSAR(symbol, StringToTimeframe(timeframe), step, maximum, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiRSI(string symbol, string timeframe, int period = 14, int applied_price = PRICE_CLOSE, int shift = 0)
{
  double value = iRSI(symbol, StringToTimeframe(timeframe), period, applied_price, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiRVI(string symbol, string timeframe, int period = 10, int mode = MODE_MAIN, int shift = 0)
{
  double value = iRVI(symbol, StringToTimeframe(timeframe), period, mode, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiStdDev(string symbol, string timeframe, int ma_period = 20, int ma_shift = 0, int ma_method = MODE_SMA, int applied_price = PRICE_CLOSE, int shift = 0)
{
  double value = iStdDev(symbol, StringToTimeframe(timeframe), ma_period, ma_shift, ma_method, applied_price, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiStochastic(string symbol, string timeframe, int k_period = 5, int d_period = 3, int slowing = 3, int method = MODE_SMA, int price_field = 0, int mode = MODE_MAIN, int shift = 0)
{
  double value = iStochastic(symbol, StringToTimeframe(timeframe), k_period, d_period, slowing, method, price_field, mode, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiTEMA(string symbol, string timeframe, int period = 14, int applied_price = PRICE_CLOSE, int shift = 0)
{
  double value = iTEMA(symbol, StringToTimeframe(timeframe), period, applied_price, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiTriX(string symbol, string timeframe, int period = 14, int applied_price = PRICE_CLOSE, int shift = 0)
{
  double value = iTriX(symbol, StringToTimeframe(timeframe), period, applied_price, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiWPR(string symbol, string timeframe, int period = 14, int shift = 0)
{
  double value = iWPR(symbol, StringToTimeframe(timeframe), period, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiVIDyA(string symbol, string timeframe, int period = 9, int alpha = 12, int applied_price = PRICE_CLOSE, int shift = 0)
{
  double value = iVIDyA(symbol, StringToTimeframe(timeframe), period, alpha, applied_price, shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}

string FXiVolumes(string symbol, string timeframe, int shift = 0)
{
  double value = iVolumes(symbol, StringToTimeframe(timeframe), shift);
  return StringFormat("{\"data\":%f,\"success\":1}", value);
}
