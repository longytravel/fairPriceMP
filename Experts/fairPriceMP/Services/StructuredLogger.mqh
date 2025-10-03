//+------------------------------------------------------------------+
//|                                            StructuredLogger.mqh |
//|                                     Copyright 2025, fairPriceMP |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, fairPriceMP"
#property strict

//+------------------------------------------------------------------+
//| Structured Logger Service                                         |
//| Enforces ASCII-only logging with event codes (max 10 chars)      |
//+------------------------------------------------------------------+
class StructuredLogger
{
private:
   string m_logFilePath;
   int    m_fileHandle;
   bool   m_fileLoggingEnabled;

   //+------------------------------------------------------------------+
   //| Validate ASCII-only string                                        |
   //+------------------------------------------------------------------+
   bool IsAsciiOnly(const string &str)
   {
      for(int i = 0; i < StringLen(str); i++)
      {
         ushort ch = StringGetCharacter(str, i);
         if(ch > 127)
            return false;
      }
      return true;
   }

   //+------------------------------------------------------------------+
   //| Sanitize string to ASCII-only                                     |
   //+------------------------------------------------------------------+
   string SanitizeToAscii(const string &str)
   {
      string result = "";
      for(int i = 0; i < StringLen(str); i++)
      {
         ushort ch = StringGetCharacter(str, i);
         if(ch <= 127)
            result += ShortToString(ch);
         else
            result += "?";  // Replace non-ASCII with placeholder
      }
      return result;
   }

public:
   //+------------------------------------------------------------------+
   //| Constructor                                                        |
   //+------------------------------------------------------------------+
   StructuredLogger()
   {
      m_logFilePath = "";
      m_fileHandle = INVALID_HANDLE;
      m_fileLoggingEnabled = false;
   }

   //+------------------------------------------------------------------+
   //| Destructor                                                         |
   //+------------------------------------------------------------------+
   ~StructuredLogger()
   {
      CloseLogFile();
   }

   //+------------------------------------------------------------------+
   //| Initialize file logging                                           |
   //+------------------------------------------------------------------+
   bool InitFileLogging(const string filePath)
   {
      m_logFilePath = SanitizeToAscii(filePath);

      // Open file in append mode
      m_fileHandle = FileOpen(m_logFilePath, FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_SHARE_READ);

      if(m_fileHandle == INVALID_HANDLE)
      {
         Print("ERROR: Failed to open log file: ", m_logFilePath, " Error: ", GetLastError());
         return false;
      }

      FileSeek(m_fileHandle, 0, SEEK_END);  // Move to end for appending
      m_fileLoggingEnabled = true;

      LogInfo("INIT", "StructuredLogger initialized");
      return true;
   }

   //+------------------------------------------------------------------+
   //| Close log file                                                     |
   //+------------------------------------------------------------------+
   void CloseLogFile()
   {
      if(m_fileHandle != INVALID_HANDLE)
      {
         FileClose(m_fileHandle);
         m_fileHandle = INVALID_HANDLE;
         m_fileLoggingEnabled = false;
      }
   }

   //+------------------------------------------------------------------+
   //| Log with event code (max 10 chars, UPPER_SNAKE_CASE)             |
   //+------------------------------------------------------------------+
   void LogEvent(const string eventCode, const string symbol, const string message)
   {
      // Validate and sanitize inputs
      string code = SanitizeToAscii(eventCode);
      string sym = SanitizeToAscii(symbol);
      string msg = SanitizeToAscii(message);

      // Truncate event code to 10 chars if needed
      if(StringLen(code) > 10)
         code = StringSubstr(code, 0, 10);

      // Format: [TIMESTAMP] [EVENT_CODE] [SYMBOL] MESSAGE
      string timestamp = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
      string logEntry = StringFormat("[%s] [%-10s] [%s] %s",
                                     timestamp, code, sym, msg);

      // Output to terminal
      Print(logEntry);

      // Output to file if enabled
      if(m_fileLoggingEnabled && m_fileHandle != INVALID_HANDLE)
      {
         FileWrite(m_fileHandle, logEntry);
         FileFlush(m_fileHandle);
      }
   }

   //+------------------------------------------------------------------+
   //| Log info message                                                  |
   //+------------------------------------------------------------------+
   void LogInfo(const string eventCode, const string message)
   {
      LogEvent(eventCode, "", message);
   }

   //+------------------------------------------------------------------+
   //| Log error with error code                                         |
   //+------------------------------------------------------------------+
   void LogError(const string eventCode, const string symbol, const string message, int errorCode)
   {
      string msg = StringFormat("%s | Error: %d", message, errorCode);
      LogEvent(eventCode, symbol, msg);
   }

   //+------------------------------------------------------------------+
   //| Log trade execution result                                        |
   //+------------------------------------------------------------------+
   void LogTradeResult(const string eventCode, const string symbol, const string operation,
                       int resultCode, const string details = "")
   {
      string msg = StringFormat("Operation: %s | Result: %d", operation, resultCode);
      if(StringLen(details) > 0)
         msg += " | " + details;

      LogEvent(eventCode, symbol, msg);
   }
};
