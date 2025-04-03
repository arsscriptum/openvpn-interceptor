
//==============================================================================
//
//   log.h - exported_h
//
//==============================================================================
//  cybercastor - made in quebec 2020 <cybercastor@icloud.com>
//==============================================================================


#ifndef __CORELIB_LOG_H__
#define __CORELIB_LOG_H__


#include <sstream>
#include <string>
#include <stdio.h>
#include <iostream>
#include <ctime>

typedef std::pair<std::string, std::string> EndOfLineEscapeTag;


struct EndOfLineEscapeStreamScope
{
protected:
    EndOfLineEscapeTag tag;
    std::ostream& os;

    EndOfLineEscapeStreamScope(const EndOfLineEscapeTag& ttag, std::ostream& tout) : tag(ttag),
        os(tout)
    {
        os << tag.first; //you can overload this for custom ostream types with a different color interface
        //this might also have a stack interface for if you need multiple resets
    }
    friend EndOfLineEscapeStreamScope operator<<(std::ostream& out, const EndOfLineEscapeTag& tg);

public:
    template <class T>
    EndOfLineEscapeStreamScope& operator<<(T&& t)
    {
        os << std::forward<T>(t);
        return *this;
    }

    EndOfLineEscapeStreamScope& operator<<(std::ostream& (&M)(std::ostream&))
    {
        M(os);
        return *this;
    }

    ~EndOfLineEscapeStreamScope()
    {
        os << tag.second;
    }
};

inline EndOfLineEscapeStreamScope operator<<(std::ostream& os, const EndOfLineEscapeTag& tg)
{
    return EndOfLineEscapeStreamScope(tg, os);
}

#ifndef DEJA_DISABLED
	#include "DejaLib.h"
#endif

const std::string ANSI_TEXT_COLOR_RESET = "\u001b[0m";
const std::string ANSI_TEXT_COLOR_BLACK = "\u001b[30m";
const std::string ANSI_TEXT_COLOR_RED = "\u001b[31m";
const std::string ANSI_TEXT_COLOR_GREEN = "\u001b[32m";
const std::string ANSI_TEXT_COLOR_YELLOW = "\u001b[33m";
const std::string ANSI_TEXT_COLOR_BLUE = "\u001b[34m";
const std::string ANSI_TEXT_COLOR_MAGENTA = "\u001b[35m";
const std::string ANSI_TEXT_COLOR_CYAN = "\u001b[36m";
const std::string ANSI_TEXT_COLOR_WHITE = "\u001b[37m";
const std::string ANSI_TEXT_COLOR_BLACK_BRIGHT = "\u001b[30;1m";
const std::string ANSI_TEXT_COLOR_RED_BRIGHT = "\u001b[31;1m";
const std::string ANSI_TEXT_COLOR_GREEN_BRIGHT = "\u001b[32;1m";
const std::string ANSI_TEXT_COLOR_YELLOW_BRIGHT = "\u001b[33;1m";
const std::string ANSI_TEXT_COLOR_BLUE_BRIGHT = "\u001b[34;1m";
const std::string ANSI_TEXT_COLOR_MAGENTA_BRIGHT = "\u001b[35;1m";
const std::string ANSI_TEXT_COLOR_CYAN_BRIGHT = "\u001b[36;1m";
const std::string ANSI_TEXT_COLOR_WHITE_BRIGHT = "\u001b[37;1m";
const std::string ANSI_TEXT_COLOR_BLACK_BKGRND = "\u001b[40m";
const std::string ANSI_TEXT_COLOR_RED_BKGRND = "\u001b[41m";
const std::string ANSI_TEXT_COLOR_GREEN_BKGRND = "\u001b[42m";
const std::string ANSI_TEXT_COLOR_YELLOW_BKGRND = "\u001b[43m";
const std::string ANSI_TEXT_COLOR_BLUE_BKGRND = "\u001b[44m";
const std::string ANSI_TEXT_COLOR_MAGENTA_BKGRND = "\u001b[45m";
const std::string ANSI_TEXT_COLOR_CYAN_BKGRND = "\u001b[46m";
const std::string ANSI_TEXT_COLOR_WHITE_BKGRND = "\u001b[47m";

const std::string CONSOLE_COLOR_BKGRND_WHITE_BLUE = "\u001b[37;44;1m";
const std::string CONSOLE_COLOR_BKGRND_WHITE_GREEN = "\u001b[32;44;1m";
const std::string CONSOLE_COLOR_BKGRND_YELLOW = "\u001b[33;41;1m";

const std::string CONSOLE_COLOR_RED_BRIGHT = "\u001b[31;1m";
const std::string CONSOLE_COLOR_GREEN_BRIGHT = "\u001b[32;1m";
const std::string CONSOLE_COLOR_YELLOW_BRIGHT = "\u001b[33;1m";
const std::string CONSOLE_COLOR_MAGENTA_BRIGHT = "\u001b[35;1m";
const std::string CONSOLE_COLOR_CYAN_BRIGHT = "\u001b[36;1m";

const std::string CONSOLE_COLOR_BLUE = "\u001b[34m";
const std::string CONSOLE_COLOR_MAGENTA = "\u001b[35m";
const std::string CONSOLE_COLOR_CYAN = "\u001b[36m";
const std::string CONSOLE_COLOR_RED = "\u001b[31m";
const std::string CONSOLE_COLOR_GREEN = "\u001b[32m";
const std::string CONSOLE_COLOR_YELLOW = "\u001b[33m";

    // Underline
const std::string BLACK_UNDERLINED = "\033[4;30m";  // BLACK
const std::string RED_UNDERLINED = "\033[4;31m";    // RED
const std::string GREEN_UNDERLINED = "\033[4;32m";  // GREEN
const std::string YELLOW_UNDERLINED = "\033[4;33m"; // YELLOW
const std::string BLUE_UNDERLINED = "\033[4;34m";   // BLUE
const std::string PURPLE_UNDERLINED = "\033[4;35m"; // PURPLE
const std::string CYAN_UNDERLINED = "\033[4;36m";   // CYAN
const std::string CYAN_UNDERLINED_B = "\033[4;36m";   // CYAN
const std::string WHITE_UNDERLINED = "\033[4;37m";  // WHITE
const std::string WHITE_UNDERLINED_B = "\033[4;37m";  // WHITE

void __cdecl ConsoleOutNoRl( std::string color, const char *format, ...);
void __cdecl ConsoleOut( std::string color, const char *format, ...);
void __cdecl SystemDebugOutput(const wchar_t *channel, const char *format, ...);
void __cdecl ConsoleLog(const char *format, ...);
void __cdecl ConsoleProcess(unsigned int id,const char *name);
void __cdecl ConsoleProcessDenied(unsigned int id,const char *name);
void __cdecl ConsoleProcessPath(unsigned int id,const char *name,const char *path);
void __cdecl ConsoleTitle(const char *format, std::string color = CYAN_UNDERLINED_B);
void __cdecl ConsoleInfo(const char *format, std::string color = WHITE_UNDERLINED_B);
void __cdecl ConsoleTrace( std::string color, const char *format, ...);
# define COUTCMD( ... ) { ConsoleLog(  __VA_ARGS__ );  }	

# define COUTYRL( ... ) { ConsoleOutNoRl(YELLOW_UNDERLINED,  __VA_ARGS__ );  } 
# define COUTBM( ... )  { ConsoleOutNoRl(CONSOLE_COLOR_YELLOW_BRIGHT,  __VA_ARGS__ );  } 
# define COUTMM( ... )  { ConsoleOutNoRl(CONSOLE_COLOR_RED,  __VA_ARGS__ );  } 
# define COUTGG( ... )  { ConsoleOutNoRl(CONSOLE_COLOR_GREEN_BRIGHT,  __VA_ARGS__ );  } 
# define COUTYY( ... )  { ConsoleOutNoRl(CONSOLE_COLOR_YELLOW,  __VA_ARGS__ );  } 
# define COUTCSNR(...)  { ConsoleOutNoRl(CONSOLE_COLOR_CYAN,  __VA_ARGS__ );  }

# define COUTRS( ... )  { ConsoleOut(CONSOLE_COLOR_RED,  __VA_ARGS__ );  }	
# define COUTR( ... )   { ConsoleOut(CONSOLE_COLOR_RED_BRIGHT,  __VA_ARGS__ );  }	
# define COUTY( ... )   { ConsoleOut(CONSOLE_COLOR_YELLOW,  __VA_ARGS__ );  }	
# define COUTYS( ... )   { ConsoleOut(CONSOLE_COLOR_YELLOW_BRIGHT,  __VA_ARGS__ );  }	
# define COUTCS( ... )  { ConsoleOut(CONSOLE_COLOR_CYAN,  __VA_ARGS__ );  }
# define COUTC( ... )   { ConsoleOut(CONSOLE_COLOR_CYAN_BRIGHT,  __VA_ARGS__ );  }	
# define COUTGS( ... )   { ConsoleOut(CONSOLE_COLOR_GREEN_BRIGHT,  __VA_ARGS__ );  }	
# define COUTG( ... )   { ConsoleOut(CONSOLE_COLOR_GREEN,  __VA_ARGS__ );  }	

# define COUTMS( ... )   { ConsoleOut(CONSOLE_COLOR_MAGENTA_BRIGHT,  __VA_ARGS__ );  }	
# define COUTM( ... )   { ConsoleOut(CONSOLE_COLOR_MAGENTA,  __VA_ARGS__ );  }	

# define COUTBB( ... )  { ConsoleOut(ANSI_TEXT_COLOR_BLACK,  __VA_ARGS__ );  }	

# define COUTTITLE( x ) { ConsoleTitle( x );  } 
# define COUTINFO( x ) { ConsoleInfo( x,CONSOLE_COLOR_BKGRND_WHITE_BLUE  );  }	

# define LOG_CONSOLE( color, ... ) { ConsoleOut( color, __VA_ARGS__ );  }	

#ifndef DEJA_DISABLED
	# define LOG_TRACE DEJA_TRACE	
	# define LOG_INFO DEJA_TRACE
	# define LOG_WARNING DEJA_WARNING
	# define LOG_ERROR DEJA_ERROR
	# define LOG_PROFILE( name )	DEJA_CONTEXT( name );
#else
	/*#ifndef FINAL
		# define LOG_PROFILE( channel, ... )
		# define LOG_TRACE( channel, ... ) { SystemDebugOutput( TEXT("trace: "),  __VA_ARGS__ );  }
		# define LOG_INFO( channel, ... ) {  SystemDebugOutput( TEXT("info: "),  __VA_ARGS__ );  }
		# define LOG_WARNING( channel, ... ){  SystemDebugOutput( TEXT("warning: "),  __VA_ARGS__ );  }
		# define LOG_ERROR( channel, ... ) {  SystemDebugOutput( TEXT("error: "),  __VA_ARGS__ ); }
	#else*/
		# define LOG_PROFILE( channel, ... ) 
		# define LOG_TRACE( channel, ... )
		# define LOG_INFO( channel, ... )
		# define LOG_WARNING( channel, ... )
		# define LOG_ERROR( channel, ... ) 
	//#endif
#endif

void inline pclr(unsigned short attributes) {
    static HANDLE hConsole = NULL;
    if (!hConsole) hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    SetConsoleTextAttribute(hConsole, attributes);
}

#define B_YELLOW    (FOREGROUND_GREEN | FOREGROUND_RED | FOREGROUND_INTENSITY)
#define B_RED       (FOREGROUND_RED | FOREGROUND_INTENSITY)
#define B_GREEN     (FOREGROUND_GREEN | FOREGROUND_INTENSITY)
#define B_BLUE      (FOREGROUND_BLUE | FOREGROUND_INTENSITY)
#define B_WHITE     (FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE | FOREGROUND_INTENSITY)

#define YELLOW  (FOREGROUND_GREEN)
#define RED     (FOREGROUND_RED)
#define GREEN   (FOREGROUND_GREEN)
#define BLUE    (FOREGROUND_BLUE)
#define WHITE   (FOREGROUND_RED | FOREGROUND_GREEN | FOREGROUND_BLUE)

#define $BY ); pclr(B_YELLOW); printf(
#define $BR ); pclr(B_RED); printf(
#define $BG ); pclr(B_GREEN); printf(
#define $BB ); pclr(B_BLUE); printf(
#define $BW ); pclr(B_WHITE); printf(

#define $Y ); pclr(YELLOW); printf(
#define $R ); pclr(RED); printf(
#define $G ); pclr(GREEN); printf(
#define $B ); pclr(BLUE); printf(
#define $W ); pclr(WHITE); printf(

#define $fill(Value) , Value); printf(
#endif //__CORELIB_LOG_H__

