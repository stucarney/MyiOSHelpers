#import "DDLog.h"

#import "DDLogMacros.h"
#import "DDAssertMacros.h"

// Loggers
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#import "DDFileLogger.h"

// Formatterws
#import "PrettyClassInformationLogFormatter.h"

// ========================= Overrides ========================================
// --> per https://github.com/robbiehanson/CocoaLumberjack/wiki/CustomLogLevels
// ----------------------------------------------------------------------------

// Are we in a DEBUG build? If so, let's make logging synchronous
#ifdef DEBUG
    // NO: We're in a Debug build. As such, let's configure logging to flush right away.
    // Undefine the asynchronous defaults:
    #undef LOG_ASYNC_VERBOSE
    #undef LOG_ASYNC_INFO
    #undef LOG_ASYNC_WARN

    // Define the logs levels to be synchronous:
    #define LOG_ASYNC_VERBOSE   (NO && LOG_ASYNC_ENABLED)   // Debug logging will be synchronous
    #define LOG_ASYNC_INFO      (NO && LOG_ASYNC_ENABLED)   // Info logging will be synchronous
    #define LOG_ASYNC_WARN      (NO && LOG_ASYNC_ENABLED)   // Warn logging will be synchronous

#endif

