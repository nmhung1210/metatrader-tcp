#property strict

#include <Trade\Trade.mqh>
CTrade trader;

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

string OrderTypeString(int type)
{
  switch (type)
  {
  case ORDER_TYPE_BUY_LIMIT:
    return "BUY_LIMIT";
  case ORDER_TYPE_SELL_LIMIT:
    return "SELL_LIMIT";
  case ORDER_TYPE_BUY_STOP:
    return "BUY_STOP";
  case ORDER_TYPE_SELL_STOP:
    return "SELL_STOP";
  }
  return "UNKNOWN";
}

string PositionTypeString(int type)
{
  switch (type)
  {
  case POSITION_TYPE_BUY:
    return "BUY";
  case POSITION_TYPE_SELL:
    return "SELL";
  }
  return "UNKNOWN";
}

string DealCloseTypeString(int type)
{
  switch (type)
  {
  case DEAL_TYPE_BUY: // Close the SELL by the BUY
    return "SELL";
  case DEAL_TYPE_SELL:
    return "BUY";
  }
  return "UNKNOWN";
}

double NormalizePrice(string symbol, double price)
{
  double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
  return MathRound(price / tickSize) * tickSize;
}

string getDateTime()
{
  return TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
}

string FXAccountInfo()
{
  ENUM_ACCOUNT_TRADE_MODE tradeMode = (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
  bool isDemo = tradeMode == ACCOUNT_TRADE_MODE_DEMO;
  string result = "";
  result += "{";
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
  result += StringFormat("\"is_demo\":%I64d", isDemo);
  result += "}";
  return StringFormat("{\"data\":%s, \"success\":%I64d}", result, true);
}

string FXSymbols()
{
  string result = "";
  long total = SymbolsTotal(false);
  result += "[";
  for (int i = 0; i < total; i++)
  {
    result += StringFormat("\"%s\"", SymbolName(i, false));
    if (i < total - 1)
      result += ",";
  }
  result += "]";
  result = StringFormat("{\"data\":%s,\"success\":%I64d}", result, true);
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
  result += "\"data\":{";
  result += StringFormat("\"time\":%I64d,", (long)SymbolInfoInteger(symbol, SYMBOL_TIME));
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
  result += "},";
  result += StringFormat("\"success\":%I64d", true);
  result += "}";
  return result;
}

string FXBuyLimit(string symbol, double volume, double price, double sl = 0, double tp = 0, long magic = 0)
{
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  trader.SetExpertMagicNumber(magic);
  string result = "{";
  price = NormalizePrice(symbol, price);
  sl = NormalizePrice(symbol, sl);
  tp = NormalizePrice(symbol, tp);
  bool success = trader.BuyLimit(volume, price, symbol, sl, tp, ORDER_TIME_GTC, 0, StringFormat("%g | %s", price, getDateTime()));
  result += StringFormat("\"success\":%I64d", success);
  if (!success)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXSellLimit(string symbol, double volume, double price, double sl = 0, double tp = 0, long magic = 0)
{
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  string result = "{";
  price = NormalizePrice(symbol, price);
  sl = NormalizePrice(symbol, sl);
  tp = NormalizePrice(symbol, tp);
  bool success = trader.SellLimit(volume, price, symbol, sl, tp, ORDER_TIME_GTC, 0, StringFormat("%g | %s", price, getDateTime()));
  result += StringFormat("\"success\":%I64d", success);
  if (!success)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXBuyStop(string symbol, double volume, double price, double sl = 0, double tp = 0, long magic = 0)
{
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  string result = "{";
  price = NormalizePrice(symbol, price);
  sl = NormalizePrice(symbol, sl);
  tp = NormalizePrice(symbol, tp);
  bool success = trader.BuyStop(volume, price, symbol, sl, tp, ORDER_TIME_GTC, 0, StringFormat("%g | %s", price, getDateTime()));
  result += StringFormat("\"success\":%I64d", success);
  if (!success)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXSellStop(string symbol, double volume, double price, double sl = 0, double tp = 0, long magic = 0)
{
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  string result = "{";
  price = NormalizePrice(symbol, price);
  sl = NormalizePrice(symbol, sl);
  tp = NormalizePrice(symbol, tp);
  bool success = trader.SellStop(volume, price, symbol, sl, tp, ORDER_TIME_GTC, 0, StringFormat("%g | %s", price, getDateTime()));
  result += StringFormat("\"success\":%I64d", success);
  if (!success)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXBuy(string symbol, double volume, double price = 0, double sl = 0, double tp = 0, long magic = 0)
{
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  string result = "{";
  price = NormalizePrice(symbol, price);
  sl = NormalizePrice(symbol, sl);
  tp = NormalizePrice(symbol, tp);
  bool success = trader.Buy(volume, symbol, price, sl, tp, StringFormat("%g | %s", price, getDateTime()));
  result += StringFormat("\"success\":%I64d", success);
  if (!success)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXSell(string symbol, double volume, double price = 0, double sl = 0, double tp = 0, long magic = 0)
{
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  price = NormalizePrice(symbol, price);
  sl = NormalizePrice(symbol, sl);
  tp = NormalizePrice(symbol, tp);
  bool success = trader.Sell(volume, symbol, price, sl, tp, StringFormat("%g | %s", price, getDateTime()));

  string result = "{";
  result += StringFormat("\"success\":%I64d", success);
  if (!success)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXOrders(string symbol = "", long offset = 0, long limit = 20, long magic = 0)
{
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  string result = "";
  int total = OrdersTotal();
  int count = 0;
  int index = 0;

  limit = MathMin(100, limit);
  result += "{\"data\":[";
  for (int pos = total - 1; pos >= 0; pos--)
  {
    if (OrderGetTicket(pos) <= 0)
    {
      continue;
    }
    if (symbol != "" && OrderGetString(ORDER_SYMBOL) != symbol)
    {
      continue;
    }
    if (magic != 0 && OrderGetInteger(ORDER_MAGIC) != magic)
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
      result += StringFormat("\"ticket\":%I64d,", OrderGetInteger(ORDER_TICKET));
      result += StringFormat("\"type\":\"%s\",", OrderTypeString(OrderGetInteger(ORDER_TYPE)));
      result += StringFormat("\"price\":%f,", OrderGetDouble(ORDER_PRICE_OPEN));
      result += StringFormat("\"volume\":%f,", OrderGetDouble(ORDER_VOLUME_CURRENT));
      result += StringFormat("\"sl\":%f,", OrderGetDouble(ORDER_SL));
      result += StringFormat("\"tp\":%f,", OrderGetDouble(ORDER_TP));
      result += StringFormat("\"open_time\":%I64d,", OrderGetInteger(ORDER_TIME_SETUP));
      result += StringFormat("\"expiration_time\":%I64d,", OrderGetInteger(ORDER_TIME_EXPIRATION));
      result += StringFormat("\"magic\":%I64d", OrderGetInteger(ORDER_MAGIC));
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
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  string result = "";
  long total = OrdersTotal();
  long count = 0;
  for (long pos = 0; pos < total; pos++)
  {
    if (OrderGetTicket(pos) <= 0)
    {
      continue;
    }
    if (symbol != "" && OrderGetString(ORDER_SYMBOL) != symbol)
    {
      continue;
    }
    if (magic != 0 && OrderGetInteger(ORDER_MAGIC) != magic)
    {
      continue;
    }
    count++;
  }
  result += StringFormat("{\"data\":%I64d,\"success\":%I64d}", count, true);
  return result;
}

string FXPositions(string symbol = "", long offset = 0, long limit = 20, long magic = 0)
{
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  string result = "";
  long total = PositionsTotal();
  long count = 0;
  long index = 0;

  limit = MathMin(100, limit);

  result += "{\"data\":[";
  for (long pos = total - 1; pos >= 0; pos--)
  {
    long ticket = PositionGetTicket(pos);
    if (PositionSelectByTicket(ticket) == false)
    {
      continue;
    }
    if (symbol != "" && PositionGetString(POSITION_SYMBOL) != symbol)
    {
      continue;
    }
    if (magic != 0 && PositionGetInteger(POSITION_MAGIC) != magic)
    {
      continue;
    }
    if (count < limit + offset && count >= offset)
    {
      if (index > 0)
        result += ",";
      result += "{";
      result += StringFormat("\"ticket\":%I64d,", ticket);
      result += StringFormat("\"type\":\"%s\",", PositionTypeString(PositionGetInteger(POSITION_TYPE)));
      result += StringFormat("\"symbol\":\"%s\",", PositionGetString(POSITION_SYMBOL));
      result += StringFormat("\"price\":%f,", PositionGetDouble(POSITION_PRICE_OPEN));
      result += StringFormat("\"volume\":%f,", PositionGetDouble(POSITION_VOLUME));
      result += StringFormat("\"profit\":%f,", PositionGetDouble(POSITION_PROFIT));
      result += StringFormat("\"swap\":%f,", PositionGetDouble(POSITION_SWAP));
      result += StringFormat("\"sl\":%f,", PositionGetDouble(POSITION_SL));
      result += StringFormat("\"tp\":%f,", PositionGetDouble(POSITION_TP));
      result += StringFormat("\"open_time\":%I64d,", PositionGetInteger(POSITION_TIME));
      result += StringFormat("\"magic\":%I64d", PositionGetInteger(POSITION_MAGIC));
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
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  string result = "";
  long total = PositionsTotal();
  long count = 0;

  for (long pos = total - 1; pos >= 0; pos--)
  {
    long ticket = PositionGetTicket(pos);
    if (PositionSelectByTicket(ticket) == false)
    {
      continue;
    }
    if (symbol != "" && PositionGetString(POSITION_SYMBOL) != symbol)
    {
      continue;
    }
    if (magic != 0 && PositionGetInteger(POSITION_MAGIC) != magic)
    {
      continue;
    }
    count++;
  }
  result += StringFormat("{\"data\":%I64d,\"success\":%I64d}", count, true);
  return result;
}

string FXOrderModify(const ulong ticket, double price, double sl = 0, double tp = 0, long expiration = 0)
{
  string result = "";
  if (!OrderSelect(ticket))
  {
    return "{\"success\":0,\"error\":404}";
  }
  string symbol = OrderGetString(ORDER_SYMBOL);
  price = NormalizePrice(symbol, price);
  sl = NormalizePrice(symbol, sl);
  tp = NormalizePrice(symbol, tp);
  bool success = trader.OrderModify(ticket, price, sl, tp, ORDER_TIME_GTC, 0, StringFormat("%g | %s", price, getDateTime()));
  result += StringFormat("{\"success\":%I64d", success);
  if (!success)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXOrderDelete(const ulong ticket)
{
  string result = "{";
  bool success = trader.OrderDelete(ticket);
  result += StringFormat("\"success\":%I64d", success);
  if (!success)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXPositionModify(const ulong ticket, double sl, double tp)
{
  string result = "{";
  if (!PositionSelectByTicket(ticket))
  {
    return "{\"success\":0,\"error\":404}";
  }
  string symbol = PositionGetString(POSITION_SYMBOL);
  sl = NormalizePrice(symbol, sl);
  tp = NormalizePrice(symbol, tp);
  bool success = trader.PositionModify(ticket, sl, tp);
  result += StringFormat("\"success\":%I64d", success);
  if (!success)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXPositionClose(const ulong ticket)
{
  string result = "{";
  if (!PositionSelectByTicket(ticket))
  {
    return "{\"success\":0,\"error\":404}";
  }
  bool success = trader.PositionClose(ticket);
  result += StringFormat("\"success\":%I64d", success);
  if (!success)
  {
    result += StringFormat(",\"error\":%I64d", GetLastError());
  }
  result += "}";
  return result;
}

string FXRates(string symbol, string timeframe, long start_pos, long count)
{
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  MqlRates rates[];
  ArraySetAsSeries(rates, true);

  ENUM_TIMEFRAMES tf = StringToTimeframe(timeframe);
  string result = "";

  long copied = CopyRates(symbol, tf, (int)start_pos, count, rates);
  if (copied != count || copied <= 0)
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }

  result += "{\"data\":[";
  for (long i = 0; i < copied; i++)
  {
    if (i > 0)
    {
      result += ",";
    }
    result += "{";
    result += StringFormat("\"time\":%I64d,", rates[i].time);
    result += StringFormat("\"open\":%f,", rates[i].open);
    result += StringFormat("\"high\":%f,", rates[i].high);
    result += StringFormat("\"low\":%f,", rates[i].low);
    result += StringFormat("\"close\":%f,", rates[i].close);
    result += StringFormat("\"tick_volume\":%f,", rates[i].tick_volume);
    result += StringFormat("\"spread\":%f,", rates[i].spread);
    result += StringFormat("\"real_volume\":%f", rates[i].real_volume);
    result += "}";
  }
  result += "],";
  result += StringFormat("\"success\":%I64d", true);
  result += "}";
  return result;
}

string FXTick(string symbol)
{
  string result = "";
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  MqlTick tick;
  if (!SymbolInfoTick(symbol, tick))
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }
  result += "{";
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
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  string result = "{";
  long total = PositionsTotal();
  long closed = 0;
  for (long pos = 0; pos < total; pos++)
  {
    long ticket = PositionGetTicket(pos);
    if (PositionSelectByTicket(ticket) == false)
    {
      continue;
    }
    if (symbol != "" && PositionGetString(POSITION_SYMBOL) != symbol)
    {
      continue;
    }
    if (magic != 0 && PositionGetInteger(POSITION_MAGIC) != magic)
    {
      continue;
    }
    if (trader.PositionClose(ticket))
      closed++;
  }
  result += StringFormat("\"closed\":%I64d,", closed);
  result += StringFormat("\"success\":%I64d", true);
  result += "}";
  return result;
}

string HistoryDealGetEntryInfo(long count, long position_id)
{
  string result = "";
  HistorySelect(0, TimeCurrent());
  long deals = HistoryDealsTotal();
  for (long i = deals - 1; i >= 0; i--)
  {
    long deal_ticket = HistoryDealGetTicket(i);
    long entry_type = HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
    long pos_id = HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
    if (entry_type != DEAL_ENTRY_IN || position_id != pos_id)
    {
      continue;
    }
    double open_price = HistoryDealGetDouble(deal_ticket, DEAL_PRICE);
    long open_time = HistoryDealGetInteger(deal_ticket, DEAL_TIME);
    result = StringFormat("{\"open_price\":%f,\"open_time\":%I64d,\"success\":1}", open_price, open_time);
    return result;
  }
  return "{\"success\":0}";
}

string FXPositionHistory(string symbol = "", long offset = 0, long limit = 20, long magic = 0)
{
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }

  string result = "";
  long count = 0;
  long index = 0;

  HistorySelect(0, TimeCurrent());
  long deals = HistoryDealsTotal();

  limit = MathMin(limit, 100);

  result += "{\"data\":[";
  for (long i = deals - 1; i >= 0; i--)
  {
    long deal_ticket = HistoryDealGetTicket(i);
    long deal_type = HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
    long entry_type = HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
    long possition_id = HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
    string deal_symbol = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);
    long deal_magic = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
    if (
        entry_type != DEAL_ENTRY_OUT ||
        (deal_type != DEAL_TYPE_BUY && deal_type != DEAL_TYPE_SELL) ||
        (symbol != "" && deal_symbol != symbol) ||
        (magic != 0 && deal_magic != magic))
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
      result += StringFormat("\"ticket\":%I64d,", possition_id);
      result += StringFormat("\"type\":\"%s\",", DealCloseTypeString(deal_type));
      result += StringFormat("\"symbol\":\"%s\",", deal_symbol);
      result += StringFormat("\"close_price\":%f,", HistoryDealGetDouble(deal_ticket, DEAL_PRICE));
      result += StringFormat("\"volume\":%f,", HistoryDealGetDouble(deal_ticket, DEAL_VOLUME));
      result += StringFormat("\"profit\":%f,", HistoryDealGetDouble(deal_ticket, DEAL_PROFIT));
      result += StringFormat("\"swap\":%f,", HistoryDealGetDouble(deal_ticket, DEAL_SWAP));
      result += StringFormat("\"commission\":%f,", HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION));
      result += StringFormat("\"close_time\":%I64d,", HistoryDealGetInteger(deal_ticket, DEAL_TIME));
      result += StringFormat("\"magic\":%I64d", deal_magic);

      // Add open info
      string entryInfo = HistoryDealGetEntryInfo(index, possition_id);
      if (StringFind(entryInfo, "\"success\":1") >= 0)
      {
        // Remove leading '{' and trailing '}'
        entryInfo = StringSubstr(entryInfo, 1, StringLen(entryInfo) - 2);
        result += "," + entryInfo;
      }

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
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }

  string result = "";
  long count = 0;

  HistorySelect(0, TimeCurrent());
  long deals = HistoryDealsTotal();

  for (long i = deals - 1; i >= 0; i--)
  {
    long deal_ticket = HistoryDealGetTicket(i);
    long deal_type = HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
    long entry_type = HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
    long possition_id = HistoryDealGetInteger(deal_ticket, DEAL_POSITION_ID);
    string deal_symbol = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);
    long deal_magic = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
    if (
        entry_type != DEAL_ENTRY_OUT ||
        (deal_type != DEAL_TYPE_BUY && deal_type != DEAL_TYPE_SELL) ||
        (symbol != "" && deal_symbol != symbol) ||
        (magic != 0 && deal_magic != magic))
    {
      continue;
    }
    count++;
  }
  result += StringFormat("{\"data\":%I64d,\"success\":%I64d}", count, true);
  return result;
}

string FXTimeCurrent()
{
  string result = "";
  result += StringFormat("{\"data\":%I64d,", TimeCurrent());
  result += StringFormat("\"success\":%I64d}", true);
  return result;
}

// Techical Indicators
// iMA - Moving Average
string FXiMA(string symbol, string timeframe, int period)
{
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  MqlRates rates[];
  ArraySetAsSeries(rates, true);
  ENUM_TIMEFRAMES tf = StringToTimeframe(timeframe);
  long copied = CopyRates(symbol, tf, 0, period, rates);
  if (copied != period || copied <= 0)
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }
  int handle = iMA(symbol, tf, period, 0, MODE_LWMA, PRICE_WEIGHTED);
  if (handle == INVALID_HANDLE)
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }
  double values[];
  if (!CopyBuffer(handle, 0, 0, 2, values))
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }
  IndicatorRelease(handle);
  return StringFormat("{\"data\":%f,\"success\":1}", values[0]);
}

// iRSI - Relative Strength Index
string FXiRSI(string symbol, string timeframe, int period)
{
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  MqlRates rates[];
  ArraySetAsSeries(rates, true);
  ENUM_TIMEFRAMES tf = StringToTimeframe(timeframe);
  long copied = CopyRates(symbol, tf, 0, period, rates);
  if (copied != period || copied <= 0)
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }
  int handle = iRSI(symbol, tf, period, PRICE_WEIGHTED);
  if (handle == INVALID_HANDLE)
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }
  double values[];
  if (!CopyBuffer(handle, 0, 0, 2, values))
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }
  IndicatorRelease(handle);
  return StringFormat("{\"data\":%f,\"success\":1}", values[0]);
}

string FXiMomentum(string symbol, string timeframe, int period)
{
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  MqlRates rates[];
  ArraySetAsSeries(rates, true);
  ENUM_TIMEFRAMES tf = StringToTimeframe(timeframe);
  long copied = CopyRates(symbol, tf, 0, period, rates);
  if (copied != period || copied <= 0)
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }
  int handle = iMomentum(symbol, tf, period, PRICE_WEIGHTED);
  if (handle == INVALID_HANDLE)
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }
  double values[];
  if (!CopyBuffer(handle, 0, 0, 2, values))
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }
  IndicatorRelease(handle);
  return StringFormat("{\"data\":%f,\"success\":1}", values[0]);
}

string FXiForce(string symbol, string timeframe, int period)
{
  if (!SymbolSelect(symbol, true))
  {
    return "{\"success\":0,\"error\":404}";
  }
  MqlRates rates[];
  ArraySetAsSeries(rates, true);
  ENUM_TIMEFRAMES tf = StringToTimeframe(timeframe);
  long copied = CopyRates(symbol, tf, 0, period, rates);
  if (copied != period || copied <= 0)
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }
  int handle = iForce(symbol, tf, period, MODE_LWMA, VOLUME_TICK);
  if (handle == INVALID_HANDLE)
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }
  double values[];
  if (!CopyBuffer(handle, 0, 0, 2, values))
  {
    return StringFormat("{\"success\":0,\"error\":%I64d}", GetLastError());
  }
  IndicatorRelease(handle);
  return StringFormat("{\"data\":%f,\"success\":1}", values[0]);
}
