
//==============================================================================
//
//     main.cpp
//
//============================================================================
//  Copyright (C) Guilaume Plante 2020 <cybercastor@icloud.com>
//==============================================================================



#include "stdafx.h"
#include "win32.h"
#include "cmdline.h"
#include "Shlwapi.h"
#include "log.h"

#include <shlobj.h>  // For SHGetFolderPath
#include <codecvt>
#include <locale>
#include <vector>
#include <unordered_map>
#include <iterator>
#include <regex>
#include <filesystem>
#include <iostream>
#include <sstream>
#include <cstdio>     // fopen, fwrite, fclose
#include <io.h>       // _read, _fileno
#include <string>     // std::string

#include <atomic>     // std::atomic (for thread-safe flag)
#include <windows.h>  // Windows console APIs

static std::atomic<bool> g_stopRequested{ false };

BOOL WINAPI ConsoleCtrlHandler(DWORD ctrlType) {
	if (ctrlType == CTRL_C_EVENT) {
		g_stopRequested = true;
		return TRUE; // handled
	}
	return FALSE;
}


#pragma comment(lib, "shlwapi.lib")  // Needed for SHCreateDirectoryEx

using namespace std;

#pragma message( "Compiling " __FILE__ )
#pragma message( "Last modified on " __TIMESTAMP__ )

std::string GetRegistryOrDefaultLogFilePath();
std::string ReadLogPathFromRegistry();
bool SaveLogPathToRegistry(const std::string& filePath);
std::string GetRegistryOrDefaultPath();
std::string GetAppDataPath(int folder);
std::string ReadFilePathFromRegistry();
bool SaveFilePathToRegistry(const std::string& filePath);
int SaveStdinToFile(const std::string& configPath);
int LogArgumentsToFile(const std::string& logPath, int argc, char* argv[]);
void banner();
void usage();

#include <fstream>
#include <string>
#include <ctime>

static std::string g_logPath = "";

void SetLogPath(const std::string& path) {
	g_logPath = path;
}

void LogMessage(const std::string& message) {
	std::ofstream logFile(g_logPath, std::ios::app);
	if (!logFile) return;

	std::time_t now = std::time(nullptr);
	char timeStr[32];
	std::strftime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", std::localtime(&now));

	logFile << "[" << timeStr << "] " << message << "\n";
}

int main(int argc, char *argv[])
{

#ifdef UNICODE
	const char** argn = (const char**)C::Convert::allocate_argn(argc, argv);
#else
	char** argn = argv;
#endif // UNICODE

	CmdLineUtil::getInstance()->initializeCmdlineParser(argc, argn);

	CmdlineParser* inputParser = CmdLineUtil::getInstance()->getInputParser();

	CmdlineOption cmdlineOptionHelp({ "-h", "--help" }, "display this help");
	
	CmdlineOption cmdlineOptionPath({ "-p", "--path" }, "path");
	CmdlineOption cmdlineOptionLog({ "-l", "--log" }, "log");
	CmdlineOption cmdlineOptionDebug({ "-d", "--debug" }, "debug");
	

	inputParser->addOption(cmdlineOptionHelp);
	
	
	inputParser->addOption(cmdlineOptionDebug); 
	
	inputParser->addOption(cmdlineOptionPath); 
	inputParser->addOption(cmdlineOptionLog);


	bool optHelp = inputParser->isSet(cmdlineOptionHelp);
	bool optDebug = inputParser->isSet(cmdlineOptionDebug);
	bool optPath= inputParser->isSet(cmdlineOptionPath);
	bool optLog = inputParser->isSet(cmdlineOptionLog);
	
	
	char appDataPath[MAX_PATH];
	SHGetFolderPathA(NULL, CSIDL_APPDATA, NULL, 0, appDataPath);

	std::string directory = std::string(appDataPath) + "\\openvpn-intercept";
	std::string argLogfilePath = directory + "\\arguments.log";
	LogArgumentsToFile(argLogfilePath, argc, argv);
	

	string configPath = "";
	string logPath = "";
	if (optPath) {
		configPath = inputParser->getCmdOption("-p");
		SaveFilePathToRegistry(configPath);
		std::ofstream ofs(configPath, std::ios::app); // app = create if not exists
		if (!ofs.is_open()) {
			std::cerr << "ERROR Using config path: " << configPath << std::endl;
			return -1;
		}
		ofs.close();
		if (optDebug) {
			std::cout << "Using config path: " << configPath << std::endl;
		}
	}
	else {
		configPath = GetRegistryOrDefaultPath();
		if (optDebug) {
			std::cout << "Using config path: " << configPath << std::endl;
		}

	}
	if (optLog) {
		logPath = inputParser->getCmdOption("-l");
		SaveLogPathToRegistry(logPath);
		std::ofstream ofs(logPath, std::ios::app); // app = create if not exists
		if (!ofs.is_open()) {
			std::cerr << "ERROR Using log path: " << logPath << std::endl;
			return -1;
		}
		ofs.close();
		SetLogPath(logPath);
		if (optDebug) {
			std::cout << "Using log path: " << logPath << std::endl;
		}
	}
	else {
		logPath = GetRegistryOrDefaultLogFilePath();

		if (optDebug) {
			std::cout << "Using log path: " << logPath << std::endl;
		}
		SetLogPath(logPath);
	}
	
	LogMessage("Intercept started");
	LogMessage("Using log path " + logPath);
	LogMessage("Saving to out file " + configPath);

	

	int bytes = SaveStdinToFile(configPath);
	if (bytes >= 0) {
		LogMessage("Captured " + std::to_string(bytes) + " bytes from stdin.");
	}
	else {
		LogMessage("Failed to capture input.");
	}

	return 0;
}




void banner() {
	std::wcout << std::endl;
	COUTC("openvpn-intercept v2.1\n");
	COUTC("Built on %s\n", __TIMESTAMP__);
	COUTC("Copyright (C) 2000-2021 Guillaume Plante\n");
	std::wcout << std::endl;
}
void usage() {
	COUTCS("Usage: openvpn-intercept [-h][-d][-l][-p] path \n");
	COUTCS("   -d          Debug mode\n");
	COUTCS("   -h          Help\n");
	COUTCS("   -p path     Destination path\n");
	COUTCS("   -l path     Set log path\n");
	std::wcout << std::endl;
}


std::string ReadLogPathFromRegistry() {
	HKEY hKey;
	const char* subkey = "Software\\arsscriptum\\openvpn-intercept";
	char buffer[MAX_PATH];
	DWORD bufferSize = sizeof(buffer);
	std::string result;

	if (RegOpenKeyExA(HKEY_CURRENT_USER, subkey, 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
		if (RegGetValueA(hKey, NULL, "logfile", RRF_RT_REG_SZ, NULL, buffer, &bufferSize) == ERROR_SUCCESS) {
			result = buffer;
		}
		RegCloseKey(hKey);
	}
	return result;
}

std::string ReadFilePathFromRegistry() {
	HKEY hKey;
	const char* subkey = "Software\\arsscriptum\\openvpn-intercept";
	char buffer[MAX_PATH];
	DWORD bufferSize = sizeof(buffer);
	std::string result;

	if (RegOpenKeyExA(HKEY_CURRENT_USER, subkey, 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
		if (RegGetValueA(hKey, NULL, "outfile", RRF_RT_REG_SZ, NULL, buffer, &bufferSize) == ERROR_SUCCESS) {
			result = buffer;
		}
		RegCloseKey(hKey);
	}
	return result;
}

bool SaveLogPathToRegistry(const std::string& filePath) {
	HKEY hKey;
	const char* subkey = "Software\\arsscriptum\\openvpn-intercept";

	if (RegCreateKeyExA(HKEY_CURRENT_USER, subkey, 0, NULL, 0,
		KEY_WRITE, NULL, &hKey, NULL) != ERROR_SUCCESS) {
		return false;
	}

	LONG result = RegSetValueExA(hKey, "logfile", 0, REG_SZ,
		reinterpret_cast<const BYTE*>(filePath.c_str()),
		static_cast<DWORD>(filePath.size() + 1));

	RegCloseKey(hKey);
	return (result == ERROR_SUCCESS);
}


bool SaveFilePathToRegistry(const std::string& filePath) {
	HKEY hKey;
	const char* subkey = "Software\\arsscriptum\\openvpn-intercept";

	if (RegCreateKeyExA(HKEY_CURRENT_USER, subkey, 0, NULL, 0,
		KEY_WRITE, NULL, &hKey, NULL) != ERROR_SUCCESS) {
		return false;
	}

	LONG result = RegSetValueExA(hKey, "outfile", 0, REG_SZ,
		reinterpret_cast<const BYTE*>(filePath.c_str()),
		static_cast<DWORD>(filePath.size() + 1));

	RegCloseKey(hKey);
	return (result == ERROR_SUCCESS);
}

std::string GetAppDataPath(int folder) {
	char path[MAX_PATH];
	if (SHGetFolderPathA(NULL, folder, NULL, 0, path) == S_OK) {
		return std::string(path);
	}
	return "";
}

std::string GetRegistryOrDefaultPath() {
	HKEY hKey;
	const char* subkey = "Software\\arsscriptum\\openvpn-intercept";
	const char* valueName = "outfile";
	char buffer[MAX_PATH];
	DWORD bufferSize = sizeof(buffer);
	std::string result;

	// Try to read from registry
	if (RegOpenKeyExA(HKEY_CURRENT_USER, subkey, 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
		if (RegGetValueA(hKey, NULL, valueName, RRF_RT_REG_SZ, NULL, buffer, &bufferSize) == ERROR_SUCCESS) {
			result = buffer;
			RegCloseKey(hKey);
			return result;
		}
		RegCloseKey(hKey);
	}

	// Use default path in Roaming directory
	char appDataPath[MAX_PATH];
	SHGetFolderPathA(NULL, CSIDL_APPDATA, NULL, 0, appDataPath);

	std::string directory = std::string(appDataPath) + "\\openvpn-intercept";
	std::string filePath = directory + "\\openvpn.cfg";

	// Create directory if it doesn't exist
	SHCreateDirectoryExA(NULL, directory.c_str(), NULL);

	// Create empty file if not exists
	std::ofstream ofs(filePath, std::ios::app); // app = create if not exists
	ofs.close();

	// Save new path to registry
	if (RegCreateKeyExA(HKEY_CURRENT_USER, subkey, 0, NULL, 0,
		KEY_WRITE, NULL, &hKey, NULL) == ERROR_SUCCESS) {
		RegSetValueExA(hKey, valueName, 0, REG_SZ,
			reinterpret_cast<const BYTE*>(filePath.c_str()),
			static_cast<DWORD>(filePath.size() + 1));
		RegCloseKey(hKey);
	}

	return filePath;
}


std::string GetRegistryOrDefaultLogFilePath() {
	HKEY hKey;
	const char* subkey = "Software\\arsscriptum\\openvpn-intercept";
	const char* valueName = "logfile";
	char buffer[MAX_PATH];
	DWORD bufferSize = sizeof(buffer);
	std::string result;

	// Try to read from registry
	if (RegOpenKeyExA(HKEY_CURRENT_USER, subkey, 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
		if (RegGetValueA(hKey, NULL, valueName, RRF_RT_REG_SZ, NULL, buffer, &bufferSize) == ERROR_SUCCESS) {
			result = buffer;
			RegCloseKey(hKey);
			return result;
		}
		RegCloseKey(hKey);
	}

	// Use default path in Roaming directory
	char appDataPath[MAX_PATH];
	SHGetFolderPathA(NULL, CSIDL_APPDATA, NULL, 0, appDataPath);

	std::string directory = std::string(appDataPath) + "\\openvpn-intercept";
	std::string filePath = directory + "\\out.log";

	// Create directory if it doesn't exist
	SHCreateDirectoryExA(NULL, directory.c_str(), NULL);

	// Create empty file if not exists
	std::ofstream ofs(filePath, std::ios::app); // app = create if not exists
	ofs.close();

	// Save new path to registry
	if (RegCreateKeyExA(HKEY_CURRENT_USER, subkey, 0, NULL, 0,
		KEY_WRITE, NULL, &hKey, NULL) == ERROR_SUCCESS) {
		RegSetValueExA(hKey, valueName, 0, REG_SZ,
			reinterpret_cast<const BYTE*>(filePath.c_str()),
			static_cast<DWORD>(filePath.size() + 1));
		RegCloseKey(hKey);
	}

	return filePath;
}
int LogArgumentsToFile(const std::string& logPath, int argc, char* argv[]) {
	std::ofstream logFile(logPath, std::ios::out | std::ios::app);
	if (!logFile.is_open()) {
		return -1;
	}

	for (int i = 0; i < argc; ++i) {
		logFile << "arg[" << i << "]: " << argv[i] << std::endl;
	}

	logFile.close();
	return argc;
}

int SaveStdinToFile(const std::string& configPath) {
	// Register Ctrl+C handler
	SetConsoleCtrlHandler(ConsoleCtrlHandler, TRUE);

	FILE* fp = fopen(configPath.c_str(), "wb");
	if (!fp) return -1;

	char ch;
	int totalBytes = 0;

	while (!g_stopRequested && _read(_fileno(stdin), &ch, 1) > 0) {
		if (fwrite(&ch, 1, 1, fp) != 1) {
			fclose(fp);
			return -1;
		}
		totalBytes++;
	}

	fclose(fp);
	return totalBytes;
}
