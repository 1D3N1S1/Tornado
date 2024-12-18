//+------------------------------------------------------------------+
//|                                                   GridManiac.mq5 |
//|                                                          Denis M |
//|                                               https://mobdora.ru |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>

#include "Include\DKStdLib\Common\DKStdLib.mqh"
#include "Include\DKStdLib\Logger\DKLogger.mqh"

#include "Include\DKStdLib\TradingManager\CDKGridOneDirStepPos.mqh"
#include "Include\DKStdLib\License\DKLicense.mqh"

#property script_show_inputs

input     group                    "0. ЛИЦЕНЗИЯ"
string                   InpLicenseSalt                       = "Springfield-3Grids-MT5-Bot.v1.mq5";                       // Salt
input     string                   InpLicenseKey                        = "9605131:2026.09.01:a536fd6ef39d5b95fb3f08f9e2a3ae23";       // Введите лицензионный ключ без пробелов и переносов строк

input     group                    "1. СЕТКА A"
input     uint                     InpMaxTradesA                        = 5;                                    // MaxTrades: Максимальный размер сетки
input     double                   InpLotsA                             = 0.1;                                  // Lots: Начальный объем ордера сетки
input     double                   InpLotsExponentA                     = 1.5;                                  // LotsExponent: Коэффициент увеличения объема ордера сетки
input     uint                     InpStepA                             = 300;                                  // Step: Расстояние в пунктах для открытия следующего ордера сетки
input     uint                     InpTakeProfitA                       = 300;                                  // Take Profit: Расстояние от безубыточной точки сетки до фиксации прибыли в пунктах
input     ENUM_TIMEFRAMES          InpRSITimeFrameA                     = PERIOD_M1;                            // Таймфрейм для RSI
input     ulong                    InpMaxSlippageA                      = 2;                                    // Максимальный проскальзывание для рыночных операций, пункты
input     long                     InpMagicA                            = 1020304050607080901;                           // Magic-номер сетки
string                   InpGridNameA                         = "A";                                  // Имя сетки A

input     group                    "2. СЕТКА B"
input     bool                     InpEnabledB                          = true;                                 // Сетка включена
input     uint                     InpMaxTradesB                        = 5;                                    // MaxTrades: Максимальный размер сетки
input     double                   InpLotsB                             = 0.1;                                  // Lots: Начальный объем ордера сетки
input     double                   InpLotsExponentB                     = 1.5;                                  // LotsExponent: Коэффициент увеличения объема ордера сетки
input     uint                     InpStepB                             = 300;                                  // Step: Расстояние в пунктах для открытия следующего ордера сетки
input     uint                     InpTakeProfitB                       = 300;                                  // Take Profit: Расстояние от безубыточной точки сетки до фиксации прибыли в пунктах
input     ENUM_TIMEFRAMES          InpRSITimeFrameB                     = PERIOD_H1;                            // Таймфрейм для RSI
input     ulong                    InpMaxSlippageB                      = 2;                                    // Максимальный проскальзывание для рыночных операций, пункты
input     long                     InpMagicB                            = 1020304050607080902;                           // Magic-номер сетки
string                   InpGridNameB                         = "B";                                  // Имя сетки B

input     group                    "3. СЕТКА C"
input     bool                     InpEnabledC                          = true;                                 // Сетка включена
input     uint                     InpMaxTradesC                        = 5;                                    // MaxTrades: Максимальный размер сетки
input     double                   InpLotsC                             = 0.1;                                  // Lots: Начальный объем ордера сетки
input     double                   InpLotsExponentC                     = 1.5;                                  // LotsExponent: Коэффициент увеличения объема ордера сетки
input     uint                     InpStepC                             = 300;                                  // Step: Расстояние в пунктах для открытия следующего ордера сетки
input     uint                     InpTakeProfitC                       = 300;                                  // Take Profit: Расстояние от безубыточной точки сетки до фиксации прибыли в пунктах
input     ENUM_TIMEFRAMES          InpRSITimeFrameC                     = PERIOD_D1;                            // Таймфрейм для RSI
input     ulong                    InpMaxSlippageC                      = 2;                                    // Максимальный проскальзывание для рыночных операций, пункты
input     long                     InpMagicC                            = 1020304050607080903;                           // Magic-номер сетки
string                   InpGridNameC                         = "C";                                  // Имя сетки C

input     group                    "4. MISC SETTINGS"
input     uint                     InpRSIMAPeriod                       = 14;                                   // RSI: Период MA, бары
input     ENUM_APPLIED_PRICE       InpRSIAppliedPrice                   = PRICE_CLOSE;                          // RSI: Применяемая цена
sinput    LogLevel                 InpLogLevel                          = LogLevel(INFO);                       // Уровень логирования

int                      InpOpenNewGridMaxDelaySec            = 60 * 60;                              // Максимальная задержка между началом новой сетки, сек
int                      InpReleaseDate                       = 20231115;                             // Дата релиза
string                   BOT_GLOBAL_PREFIX                    = "SF";                                 // Глобальный префикс


DKLogger                           m_logger_a;
DKLogger                           m_logger_b;
DKLogger                           m_logger_c;

CTrade                             m_trade_a;
CTrade                             m_trade_b;
CTrade                             m_trade_c;

CDKGridOneDirStepPos               m_grid_a;
CDKGridOneDirStepPos               m_grid_b;
CDKGridOneDirStepPos               m_grid_c;

int                                m_grid_b_sleep_till;
int                                m_grid_c_sleep_till;

// Глобальные переменные
input double InpManualSlPercentage = 0.0; // Процент для ручного SL
input double InpManualTpPercentage = 0.0; // Процент для ручного TP
input bool InpUseManualSlTp = false;

enum AdjustmentMode {
   AUTOMATIC,
   MANUAL
};

AdjustmentMode adjustmentMode = AdjustmentMode::AUTOMATIC;

//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| BOT'S LOGIC
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void InitTrade(CTrade& aTrade, const long aMagic, const ulong aSlippage)
{
   aTrade.SetExpertMagicNumber(aMagic);
   aTrade.SetMarginMode();
   aTrade.SetTypeFillingBySymbol(_Symbol);
   aTrade.SetDeviationInPoints(aSlippage);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetRSI(int aRSIHandle, int aBuffer, int aIndex)
{
   double RSIArr[];
   if(CopyBuffer(aRSIHandle, aBuffer, aIndex, 1, RSIArr) >= 0) {
      return RSIArr[0];
   }
   return -1;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_POSITION_TYPE GetRSI(const ENUM_TIMEFRAMES aPeriod)
{
   int RSIHandle = iRSI(_Symbol, aPeriod, InpRSIMAPeriod, InpRSIAppliedPrice);
   double RSIMainLine = GetRSI(RSIHandle, MAIN_LINE, 1);
   double RSISignalLine = GetRSI(RSIHandle, SIGNAL_LINE, 1);
   return (RSIMainLine <= 50) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ShowComment()
{
   string text = StringFormat("\n"+
                              "GRID %s (%s):\n"+
                              "=======\n"+
                              "%s\n\n"+
                              "GRID %s (%s):\n"+
                              "=======\n"+
                              "%s\n\n"+
                              "GRID %s (%s):\n"+
                              "=======\n"+
                              "%s\n\n",
                              InpGridNameA,
                              m_grid_a.GetID(),
                              StringFormat("Dir: %s\n", EnumToString(m_grid_a.GetDirection())) + m_grid_a.GetDescription(),
                              InpGridNameB,
                              m_grid_b.GetID(),
                              StringFormat("Dir: %s\n", EnumToString(m_grid_b.GetDirection())) + m_grid_b.GetDescription() + StringFormat("Seed: %.1f\n", m_grid_b_sleep_till / 60),
                              InpGridNameC,
                              m_grid_c.GetID(),
                              StringFormat("Dir: %s\n", EnumToString(m_grid_c.GetDirection())) + m_grid_c.GetDescription() + StringFormat("Seed: %.1f\n", m_grid_c_sleep_till / 60));
   Comment(text);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
// Функция для изменения уровней SL и TP позиции с проверкой на минимальный уровень стопов
bool ModifyPositionWithCheck(ulong ticket, double new_sl, double new_tp)
{
   MqlTradeRequest request;
   MqlTradeResult result;
   request.action = TRADE_ACTION_SLTP;
   request.position = ticket;
   request.symbol = Symbol();
   request.sl = new_sl;
   request.tp = new_tp;
// Попытка изменить позицию
   if (!OrderSend(request, result)) {
      // Если ошибка RETCODE=10016, проверяем минимальный уровень стопов
      if (result.retcode == 10016) { // invalid stops
         long minStops = SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
         // Получаем текущую цену
         double current_price = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                                ? SymbolInfoDouble(Symbol(), SYMBOL_BID)
                                : SymbolInfoDouble(Symbol(), SYMBOL_ASK);
         // Корректируем уровни SL и TP
         if (new_sl > 0)
            request.sl = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                         ? current_price - minStops * _Point
                         : current_price + minStops * _Point;
         if (new_tp > 0)
            request.tp = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                         ? current_price + minStops * _Point
                         : current_price - minStops * _Point;
         // Повторная попытка изменить позицию с обновленными уровнями
         if (!OrderSend(request, result)) {
            Print("Ошибка изменения позиции: ", result.comment);
            return false;
         }
      } else {
         // Выводим другие ошибки, если они возникают
         Print("Ошибка OrderSend: ", result.comment);
         return false;
      }
   }
   Print("Позиция успешно изменена: SL=", request.sl, " TP=", request.tp);
   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
// Check exp. date
//string expar = (string)InpReleaseDate;
//if (TimeCurrent() > StringToTime(expar) + 31 * 24 * 60 * 60) {
//  MessageBox("Developer version is expired", "Error", MB_OK | MB_ICONERROR);
//  return(INIT_FAILED);
//}
// Check license
   CAccountInfo account;
   if (!IsLicenseValid(InpLicenseKey, account.Login(), InpLicenseSalt)) {
      MessageBox("Ваш лицензионный ключ недействителен", "Ошибка", MB_OK | MB_ICONERROR);
      return(INIT_FAILED);
   }
   MathSrand(GetTickCount());
   EventSetTimer(1);
   m_logger_a.Name = BOT_GLOBAL_PREFIX + ":" + InpGridNameA;
   m_logger_a.Level = InpLogLevel;
   if (MQL5InfoInteger(MQL5_DEBUGGING)) {
      m_logger_a.Level = LogLevel(DEBUG);
   }
   m_logger_b.Name = BOT_GLOBAL_PREFIX + ":" + InpGridNameB;
   m_logger_b.Level = m_logger_a.Level;
   m_logger_c.Name = BOT_GLOBAL_PREFIX + ":" + InpGridNameC;
   m_logger_c.Level = m_logger_a.Level;
   if (InpMagicA == InpMagicB || InpMagicA == InpMagicC || InpMagicB == InpMagicC) {
      MessageBox("Установите разные Magic для всех сеток", "Ошибка", MB_OK | MB_ICONERROR);
      return(INIT_FAILED);
   }
   InitTrade(m_trade_a, InpMagicA, InpMaxSlippageA);
   InitTrade(m_trade_b, InpMagicB, InpMaxSlippageB);
   InitTrade(m_trade_c, InpMagicC, InpMaxSlippageC);
   m_grid_a.SetLogger(GetPointer(m_logger_a));
   m_grid_b.SetLogger(GetPointer(m_logger_b));
   m_grid_c.SetLogger(GetPointer(m_logger_c));
   m_grid_a.Init(_Symbol, GetRSI(InpRSITimeFrameA), InpMaxTradesA, InpLotsA, InpStepA, InpLotsExponentA, InpTakeProfitA, InpGridNameA, InpMagicA, m_trade_a);
   m_logger_a.Info(StringFormat("Grid init: VER=%s | GID=%s | MAGIC=%I64u | DIR=%s | MAX_SIZE=%d | LOT=%f | STEP=%d | RATIO=%f | TP=%d",
                                TimeToString(__DATETIME__), m_grid_a.GetID(), InpMagicA, EnumToString(m_grid_a.GetDirection()), InpMaxTradesA, InpLotsA, InpStepA,
                                InpLotsExponentA, InpTakeProfitA));
   m_grid_b.Init(_Symbol, GetRSI(InpRSITimeFrameB), InpMaxTradesB, InpLotsB, InpStepB, InpLotsExponentB, InpTakeProfitB, InpGridNameB, InpMagicB, m_trade_b);
   m_logger_b.Info(StringFormat("Grid init: VER=%s | GID=%s | MAGIC=%I64u | DIR=%s | MAX_SIZE=%d | LOT=%f | STEP=%d | RATIO=%f | TP=%d",
                                TimeToString(__DATETIME__), m_grid_b.GetID(), InpMagicB, EnumToString(m_grid_b.GetDirection()), InpMaxTradesB, InpLotsB, InpStepB,
                                InpLotsExponentB, InpTakeProfitB));
   m_grid_c.Init(_Symbol, GetRSI(InpRSITimeFrameC), InpMaxTradesC, InpLotsC, InpStepC, InpLotsExponentC, InpTakeProfitC, InpGridNameC, InpMagicC, m_trade_c);
   m_logger_c.Info(StringFormat("Grid init: VER=%s | GID=%s | MAGIC=%I64u | DIR=%s | MAX_SIZE=%d | LOT=%f | STEP=%d | RATIO=%f | TP=%d",
                                TimeToString(__DATETIME__), m_grid_c.GetID(), InpMagicC, EnumToString(m_grid_c.GetDirection()), InpMaxTradesC, InpLotsC, InpStepC,
                                InpLotsExponentC, InpTakeProfitC));
   OnTrade(); // Load open positions
   m_grid_b_sleep_till = (int)(InpOpenNewGridMaxDelaySec * MathRand() / 32768);
   m_grid_c_sleep_till = (int)(InpOpenNewGridMaxDelaySec * MathRand() / 32768);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()

{
   ShowComment();
   if (m_grid_a.Size() <= 0) {
      m_grid_a.SetDirection(GetRSI(InpRSITimeFrameA));
   }
   m_grid_a.OpenNext();
// Используем глобальную переменную
   if (InpUseManualSlTp) {
      adjustmentMode = AdjustmentMode::MANUAL;
   } else {
      adjustmentMode = AdjustmentMode::AUTOMATIC;
   }
// Передаем параметры в функцию настройки SL/TP
   SetSLTPWithAutoAdjust(m_grid_a, adjustmentMode, InpManualSlPercentage, InpManualTpPercentage);
   m_grid_a.SetTPFromAverage();
}


// Функция для установки SL/TP с автоматической корректировкой

void SetSLTPWithAutoAdjust(CDKGridOneDirStepPos &grid, AdjustmentMode mode, double manualSlPercentage, double manualTpPercentage)

{
   CDKPositionInfo pos;
   if (grid.Get(0, pos)) { // Получить первую позицию в сетке
      double sl = 0, tp = 0;
      double minStops = SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL) * _Point; // Минимальный уровень стопов
      long direction = PositionGetInteger(POSITION_TYPE); // Получаем тип позиции (BUY или SELL)
      double currentPrice = (direction == POSITION_TYPE_BUY)
                            ? SymbolInfoDouble(Symbol(), SYMBOL_BID)
                            : SymbolInfoDouble(Symbol(), SYMBOL_ASK);
      // Режим автоматической корректировки
      if (mode == AdjustmentMode::AUTOMATIC) {
         if (direction == POSITION_TYPE_BUY) {
            sl = currentPrice - (InpStepA * _Point);
            tp = currentPrice + (InpTakeProfitA * _Point);
         } else {
            sl = currentPrice + (InpStepA * _Point);
            tp = currentPrice - (InpTakeProfitA * _Point);
         }
         // Корректируем уровни, если они меньше минимального уровня стопов
         if (MathAbs(currentPrice - sl) < minStops) {
            sl = (direction == POSITION_TYPE_BUY) ? currentPrice - minStops : currentPrice + minStops;
         }
         if (MathAbs(currentPrice - tp) < minStops) {
            tp = (direction == POSITION_TYPE_BUY) ? currentPrice + minStops : currentPrice - minStops;
         }
      }
      // Режим ручной настройки
      else if (mode == AdjustmentMode::MANUAL) {
         sl = currentPrice * (1 - manualSlPercentage / 100);
         tp = currentPrice * (1 + manualTpPercentage / 100);
      }
      // Применяем изменения
      if (!ModifyPositionWithCheck(pos.Ticket(), sl, tp)) {
         Print("Ошибка установки SL/TP для позиции ", pos.Ticket());
      }
   }
}
//+------------------------------------------------------------------+
//| Функция для обработки таймеров                                    |
//+------------------------------------------------------------------+
void OnTimer()
{
   EventKillTimer();
}

//+------------------------------------------------------------------+
//| Обработка торговых позиций                                       |
//+------------------------------------------------------------------+
void OnTrade()
{
   if (m_grid_a.OpenPosCount() != m_grid_a.Size()) {
      m_logger_a.Debug(StringFormat("OnTrade(): Open pos count not equal grid size: GID=%s | SIZE=%d | OPEN_POS_CNT=%d",
                                    m_grid_a.GetID(), m_grid_a.Size(), m_grid_a.OpenPosCount()));
      m_grid_a.Load();
   }
   if (InpEnabledB && m_grid_b.OpenPosCount() != m_grid_b.Size()) {
      m_logger_b.Debug(StringFormat("OnTrade(): Open pos count not equal grid size: GID=%s | SIZE=%d | OPEN_POS_CNT=%d",
                                    m_grid_b.GetID(), m_grid_b.Size(), m_grid_b.OpenPosCount()));
      m_grid_b.Load();
   }
   if (InpEnabledC && m_grid_c.OpenPosCount() != m_grid_c.Size()) {
      m_logger_c.Debug(StringFormat("OnTrade(): Open pos count not equal grid size: GID=%s | SIZE=%d | OPEN_POS_CNT=%d",
                                    m_grid_c.GetID(), m_grid_c.Size(), m_grid_c.OpenPosCount()));
      m_grid_c.Load();
   }
}
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
