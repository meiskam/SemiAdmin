//////////////////////////////////////////////////////////////////////////
//
// Unreal Tournament Syslog
// ------------------------
//
// Programmed by PurplePants@purplemetalflake.co.uk
//
// Copyright © PurplePants, 2003
//
//////////////////////////////////////////////////////////////////////////

class syslog extends UdpLink config(system);

var string			sApplication;	// This application
var string			sVersion;		// The version of this application
var string			ServerAddr;		// Address of this server

var IpAddr			syslogServer;		// IP and port of syslog server		

var config string	syslogIP;		// IP address of syslog server
var config int		syslogPort;		// Port of syslog server
var config bool		bEnabled;		// True if syslog is enabled
var bool			bRunning;		// True if syslog is currently active
var bool			bInitialised;
var config bool		bDebugLog;		// True if debug info is written to the UT log
var config int		LogLevel;		// syslog ignores priorities above this value
var config bool		bShortHeader;	// False for RFC compliance, true for less wastage

var string 			MonthString[12];	// List of short month names


// syslog priority values
enum SLSeverity
{
	SLS_EMERGENCY,
	SLS_ALERT,
	SLS_CRITICAL,
	SLS_ERROR,
	SLS_WARNING,
	SLS_NOTICE,
	SLS_INFO,
	SLS_DEBUG,
};

// syslog facility values
enum SLFacility
{
	SLF_KERNEL,
	SLF_USER,
	SLF_MAIL,
	SLF_SYSTEM,
	SLF_SECURITY,
	SLF_SYSLOGD,
	SLF_PRINTER,
	SLF_NEWS,
	SLF_UUCP,
	SLF_CLOCK,
	SLF_AUTH,
	SLF_FTP,
	SLF_NTP,
	SLF_AUDIT,
	SLF_ALERT,
	SLF_CLOCK2,
	SLF_LOCAL0,
	SLF_LOCAL1,
	SLF_LOCAL2,
	SLF_LOCAL3,
	SLF_LOCAL4,
	SLF_LOCAL5,
	SLF_LOCAL6,
	SLF_LOCAL7,
};


// Get syslog up and running before doing owt else
function PreBeginPlay()
{
	if (bInitialised)
		return;
	bInitialised = TRUE;

	StartUpSyslog();
}

// Shut syslog down nicely
function ShutDownSyslog()
{
	if (bRunning)	// Don't bother if it's not already running
		{
		SendSyslog(SLF_SYSLOGD, SLS_DEBUG, sApplication, sVersion$" Halted");
		bRunning = False;
		Log(sApplication$": "$sVersion$" Halted");
		}
}

// Start up syslog properly
function StartUpSyslog()
{
	local IpAddr LocalIP;

	bRunning = False;

	if (bEnabled)	// but only if it's enabled :)
		{
		Log(sApplication$": "$sVersion$" Starting");
		// Set up vars for faster access later...
		GetLocalIP(LocalIP);
		LocalIP.Port = Level.Game.GetServerPort();
		if (bShortHeader)
			ServerAddr = "["$LocalIP.Port$"]";
		else
			ServerAddr = IpAddrToString(LocalIP);

		if (syslogIP == "")		// No IP means not set up, can't do anything
			{
			bEnabled = False;
			Log(sApplication$": no IP - disabled");
			}
		else
			{
			syslogServer.Port = syslogPort;
			if (BindPort() == 0)
				{
				Log(sApplication$": Could not bind to port "$syslogPort$" - halted");
				}
			else
				{
				Log(sApplication$": syslogd IP = "$syslogIP$":"$syslogPort);
				Resolve(syslogIP);
				}
			}
		}
}

// We get here after our Resolve call, with the address sorted out
event Resolved(IpAddr Addr)
{
	syslogServer.Addr = Addr.Addr;
	bRunning = TRUE;	// All set up now, off we go
	SendSyslog(SLF_SYSLOGD, SLS_DEBUG, sApplication, sVersion$" Started");
}

// Bum address passed - we're shafted
event ResolveFailed()
{
	Log(sApplication$": Domain resolution failed - not started");
}

// Call this to disable syslog immediately
function SyslogDisable()
{
	ShutDownSyslog();
	bEnabled = False;
}

// Call this to enable syslog immediately
function SyslogEnable()
{
	bEnabled = True;
	StartUpSyslog();
}

// Generate a timestamp for the syslog message
function string SyslogTimestamp()
{
	local string TimeNow;

	if (bShortHeader)
		{
		TimeNow = MonthString[Level.Month];
		if (Level.Day < 10)
			TimeNow = TimeNow$"  "$Level.Day;
		else
			TimeNow = TimeNow$" "$Level.Day;
		}
	else
		{
		TimeNow = string(Level.Year);

		if (Level.Month < 10)
			TimeNow = TimeNow$"-0"$Level.Month;
		else
			TimeNow = TimeNow$"-"$Level.Month;

		if (Level.Day < 10)
			TimeNow = TimeNow$"-0"$Level.Day;
		else
			TimeNow = TimeNow$"-"$Level.Day;
		}


	if (Level.Hour < 10)
		TimeNow = TimeNow$" 0"$Level.Hour;
	else
		TimeNow = TimeNow$" "$Level.Hour;

	if (Level.Minute < 10)
		TimeNow = TimeNow$":0"$Level.Minute;
	else
		TimeNow = TimeNow$":"$Level.Minute;

	if (Level.Second < 10)
		TimeNow = TimeNow$":0"$Level.Second;
	else
		TimeNow = TimeNow$":"$Level.Second;

	return TimeNow;
}

// Do the biz and send off a syslog message
function SendSyslog(SLFacility Facility, SLSeverity Severity, string Process, string Message)
{
	local int Priority;


	if (bRunning)
		{
		Priority = (Facility * 8) + (Severity);
		if (bDebugLog)
			{
			Log(sApplication$": Priority = "$Priority$", Process = "$Process$", IP = "$IpAddrToString(syslogServer));
			Log(sApplication$": Message = "$Message);
			}
		if (Severity <= LogLevel)
				SendText(syslogServer, "<"$Priority$">"$SyslogTimestamp()$" "$ServerAddr$" "$Process$": "$Message);
		else
			{
			if (bDebugLog)
				Log(sApplication$": Message not logged (Severity > LogLevel)");
			}
		}
}

defaultproperties
{
     sApplication="syslog"
     sVersion="V0.2b"
     syslogIP="127.0.0.1" // IP address of syslogd server
     syslogPort=514
     bEnabled=True
     LogLevel=7
     bShortHeader=True
     MonthString(0)="Jan"
     MonthString(1)="Feb"
     MonthString(2)="Mar"
     MonthString(3)="Apr"
     MonthString(4)="May"
     MonthString(5)="Jun"
     MonthString(6)="Jul"
     MonthString(7)="Aug"
     MonthString(8)="Sep"
     MonthString(9)="Oct"
     MonthString(10)="Nov"
     MonthString(11)="Dec"
     RemoteRole=ROLE_None
}
