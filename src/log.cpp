
//==============================================================================
//
//  log.cpp
//
//==============================================================================
//  cybercastor - made in quebec 2020 <cybercastor@icloud.com>
//==============================================================================



#include "stdafx.h"
#include "log.h"
#include <stdio.h>
#include <stdarg.h>
#include <ctype.h>
#include <wtypes.h>

//==============================================================================
// ConsoleOut
// Used by the ServiceTerminal
//==============================================================================
void __cdecl ConsoleOut(std::string color, const char *format, ...)
{
	char    buf[4096], *p = buf;
	va_list args;
	int     n;

	va_start(args, format);
	n = vsnprintf(p, sizeof buf - 3, format, args); // buf-3 is room for CR/LF/NUL
	va_end(args);

	p += (n < 0) ? sizeof buf - 3 : n;

	while (p > buf  &&  isspace(p[-1]))
		*--p = '\0';

	*p++ = '\r';
	*p++ = '\n';
	*p = '\0';


	EndOfLineEscapeTag Format{ color, ANSI_TEXT_COLOR_RESET };
	std::clog << Format << buf;
}

void __cdecl ConsoleOutNoRl(std::string color, const char *format, ...)
{
	char    buf[4096], *p = buf;
	va_list args;
	int     n;

	va_start(args, format);
	n = vsnprintf(p, sizeof buf - 3, format, args); // buf-3 is room for CR/LF/NUL
	va_end(args);

	p += (n < 0) ? sizeof buf - 3 : n;

	while (p > buf  &&  isspace(p[-1]))
		*--p = '\0';

	*p++ = ' ';
	
	*p = '\0';


	EndOfLineEscapeTag Format{ color, ANSI_TEXT_COLOR_RESET };
	std::clog << Format << buf;
}


void __cdecl ConsoleLog(const char *format, ...)
{
	char    buf[4096], *p = buf;
	va_list args;
	int     n;

	va_start(args, format);
	n = vsnprintf(p, sizeof buf - 3, format, args); // buf-3 is room for CR/LF/NUL
	va_end(args);

	p += (n < 0) ? sizeof buf - 3 : n;

	while (p > buf  &&  isspace(p[-1]))
		*--p = '\0';

	*p++ = '\r';
	*p++ = '\n';
	*p = '\0';

	EndOfLineEscapeTag FormatText{ CONSOLE_COLOR_YELLOW, ANSI_TEXT_COLOR_RESET };
	std::clog << FormatText << buf;
}

void __cdecl ConsoleTrace(const char *format, ...)
{
	char    buf[4096], *p = buf;
	va_list args;
	int     n;

	va_start(args, format);
	n = vsnprintf(p, sizeof buf - 3, format, args); // buf-3 is room for CR/LF/NUL
	va_end(args);

	p += (n < 0) ? sizeof buf - 3 : n;

	while (p > buf  &&  isspace(p[-1]))
		*--p = '\0';

	//*p++ = '\r';
	//*p++ = '\n';
	*p = '\0';


	EndOfLineEscapeTag FormatText{ CONSOLE_COLOR_BKGRND_YELLOW, ANSI_TEXT_COLOR_RESET };
	EndOfLineEscapeTag FormatReset{ ANSI_TEXT_COLOR_BLACK, ANSI_TEXT_COLOR_RESET };
	std::clog << FormatText << buf;
	std::clog << FormatReset << "";
}
void __cdecl ConsoleProcess(unsigned int id,const char *name)
{
	char    buf[32], *p = buf;
	sprintf(buf, "[%5d]",id);	
	EndOfLineEscapeTag FormatId{ ANSI_TEXT_COLOR_BLUE_BRIGHT, ANSI_TEXT_COLOR_RESET };
	EndOfLineEscapeTag FormatName{ ANSI_TEXT_COLOR_WHITE, ANSI_TEXT_COLOR_RESET };

	std::clog << FormatId << p << "\t";
	std::clog << FormatName << name << "\n";
}
void __cdecl ConsoleProcessDenied(unsigned int id,const char *name)
{
	char    buf[32], *p = buf;
	sprintf(buf, "[%5d]",id);	
	EndOfLineEscapeTag FormatId{ ANSI_TEXT_COLOR_MAGENTA_BRIGHT, ANSI_TEXT_COLOR_RESET };
	EndOfLineEscapeTag FormatName{ ANSI_TEXT_COLOR_YELLOW, ANSI_TEXT_COLOR_RESET };

	std::clog << FormatId << p << "\t";
	std::clog << FormatName << name << "\n";


}
void __cdecl ConsoleProcessPath(unsigned int id,const char *name,const char *path)
{
	char    buf[32], *p = buf;
	sprintf(buf, "[%5d]",id);

	EndOfLineEscapeTag FormatId{ ANSI_TEXT_COLOR_BLUE_BRIGHT, ANSI_TEXT_COLOR_RESET };
	EndOfLineEscapeTag FormatName{ ANSI_TEXT_COLOR_WHITE, ANSI_TEXT_COLOR_RESET };
	EndOfLineEscapeTag FormatPath{ ANSI_TEXT_COLOR_BLACK_BRIGHT, ANSI_TEXT_COLOR_RESET };
	std::clog << FormatId << p << "\t";
	if(strlen(name)<8){
		std::clog << FormatName << name << "\t\t";
	}else if(strlen(name)>14){
		std::clog << FormatName << name << "\n\t\t";	
	}else{
		std::clog << FormatName << name << "\t";	
	
	}
	
	std::clog << FormatPath << path << "\n";
}
void __cdecl ConsoleTitle( const char *title, std::string color )
{
	EndOfLineEscapeTag FormatTitle{ color, ANSI_TEXT_COLOR_RESET };
	EndOfLineEscapeTag FormatName{ BLACK_UNDERLINED, ANSI_TEXT_COLOR_RESET };
	std::clog << FormatTitle << title;
	std::clog << FormatName << " ";
}
void __cdecl ConsoleInfo(const char *title, std::string color)
{
	EndOfLineEscapeTag FormatTitle{ color, ANSI_TEXT_COLOR_RESET };
	EndOfLineEscapeTag FormatName{ BLACK_UNDERLINED, ANSI_TEXT_COLOR_RESET };
	std::clog << FormatTitle << title;
	std::clog << FormatName << " ";
}


//==============================================================================
// SystemDebugOutput
// Kernel-mode and Win32 debug output
//   - Win32 OutputDebugString
//   - Kernel - mode DbgPrint
// You can monitor this stream using Debugview from SysInternals
// https://docs.microsoft.com/en-us/sysinternals/downloads/debugview
//==============================================================================
void __cdecl SystemDebugOutput(const wchar_t *channel, const char *format, ...)
{
#ifndef FINAL
	char    buf[4096], *p = buf;
	va_list args;
	int     n;

	va_start(args, format);
	n = vsnprintf(p, sizeof buf - 3, format, args); // buf-3 is room for CR/LF/NUL
	va_end(args);

	p += (n < 0) ? sizeof buf - 3 : n;

	while (p > buf  &&  isspace(p[-1]))
		*--p = '\0';

	*p++ = '\r';
	*p++ = '\n';
	*p = '\0';

	OutputDebugStringA(buf);
#ifdef KERNEL_DEBUG
	DbgPrint(buf);
#endif // KERNEL_DEBUG

#endif // FINAL
}
