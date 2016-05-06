// ====================================================================
//  Class:  SemiAdmin.SemiAdminMutator
//  Parent: Engine.Mutator
//

class SemiAdminMutator extends SemiAdminBase;

// -- in config for GamePlay ---
var config string GameEditClasses[64]; 
var config string ReasonMessage[64];
var config string AbuseMessage[128];
var config string Mutes[128];
var string CurrentMutes;
var syslog	syslogobj;	// Where syslog is
var WarnedList WarnedList;
var bool bSomeOption;
var config bool	bUseSyslog;
struct antispamstruct
{
	var PlayerReplicationInfo	PlayerPRI;
	var string			Message;
	var float			Time;
};
var antispamstruct antispam[25];

// --- current session ---
var private int CurID;		// Set by IsAdmin
var string UsedName;		// Set by IsValidLogin()

// --- editing a game ---
var bool bEditingGame;
var class<GamePlayInfo> GamePlayInfoClass;
var SemiAdminSpectator SAS;

var const enum SA_Action
{
	Warning, 
	Kick, 
	Ban, 
	Mute,
	UnMute,
	Respawn,
	ZeroFrag,
	NoAction	
} Action;

var config string SA_ActionCodes[7];

var config int USLServerSettings;
var config int USLMapListChange;
var config int USLMapChange;
var config int USLMapNext;
var config int USLMapRestart;
var config int USLGameTypeChange;
var config int USLMutatorsChange;
var config int USLGamePause;
var config int USLGameStop;
var config int USLGameEdit;
var config int USLGameApplyChanges;
var config int USLWarningIssue;
var config int USLWarningClear;
var config int USLReasonAdd;
var config int USLReasonDelete;
var config int USLReasonEdit;
var config int USLWhipMuteAdd;
var config int USLWhipMuteDelete;
var config int USLWhipZeroFrag;
var config int USLWhipRespawn;
var config int USLServerUnBanIP;
var config int USLServerBanIP;
var config int USLGameConsoleView;
var config int USLGameConsoleSend;
var config int USLGameViewSettings;
var config int USLGameViewBots;
var config int USLGameViewMutators;
var config int USLServerMinPlayers;
var config int USLServerKick;
var config int USLServerWhip;
var config int USLServerViewSettings;
var config int USLServerViewBans; 
var config int USLServerRestart;
var config int USLServerManageBots;  
var config int USLAddRemoveBots;

var config bool         bLogChat;
var config bool         bLogPlayersOnRespawn;
var GamePlayInfo		GamePI;
var CommandList			CList;
var int                 OldMinPlayers;

var bool                Paused;
var bool                Stopped;
var bool PickupsRespawnHealth;
var bool PickupsRespawnWeapon;
var bool PickupsRespawnAmmo;
var bool PickupsRespawnArmor;
var bool PickupsRespawnPowerup;

var float OldTimeDilation;

var string MutateString2;

function PreBeginPlay()
{
	UnMuteAll();
	SetTimer(5.0, true);
	GetSAS();
	WarnedList=Spawn(class'WarnedList');
	super.PreBeginPlay();
}

event Timer()
{
	CleanDisconnected();
}


function Mutate(string MutateString, PlayerPawn Sender)
{
    local bool bValid;
    local string AdminPassword;
    SenderIP=GetPlayerIP(Sender);
	Issuer = Sender;
	ParseCommandLine(MutateString);
	MutateString2 = MutateString;
	if (Command == "PLI" || Command == "PLIST" || Command == "PLAYERLIST" || Command == "IDLIST" || Command == "IPLIST" )
	{
		if (!IsAdmin(Sender))
		{
			if (NumParams != 2)
			{
				Sender.ClientMessage("You must provide your username and password");
				return;
			}
    	    
			if(IsValidLogin(Params[0], Params[1]))
			{
				LoginAdmin(Sender,"silent");
				if ((Command != "PLI") && (IsMasterAdmin()))
				{
					PlayerList();
					LogoutAdmin("silent");
				}
			}
			else
			{
				WriteLog(Sender.PlayerReplicationInfo.PlayerName@"Failed Login as"@UsedName@"from"@SenderIP, 'SemiAdmin');
				Level.Game.BroadcastMessage( Issuer.PlayerReplicationInfo.PlayerName@"tried to log into"@UsedName@"and did NOT become a limited administrator." );
			}
		}
		else if (Command != "PLI") PlayerList();
	}
	
	else if (Command == "ALI")
	{
		if (!IsAdmin(Sender))
		{
			if (NumParams != 2)
			{
				Sender.ClientMessage("You must provide your username and password");
				return;
			}
    	    
			if(IsValidLogin(Params[0], Params[1]))
			{
    			if (NumParams >= 3)
				LoginAdmin(Sender,Params[2]);
			else
				LoginAdmin(Sender);
			}
			else
			{
				WriteLog(Sender.PlayerReplicationInfo.PlayerName@"Failed Login as"@UsedName@"from"@SenderIP, 'SemiAdmin');
				Level.Game.BroadcastMessage( Issuer.PlayerReplicationInfo.PlayerName@"tried to log into"@UsedName@"and did NOT become a limited administrator." );
			}
		}
		else
			Sender.ClientMessage("You are already logged in!");
	}

	else if (Command == "ADMINLOGIN")
	{
		AdminPassword = ConsoleCommand( "get gameinfo adminpassword" );

		if (AdminPassword == "")
		{
			Sender.ClientMessage("No AdminPassword found, not allowing logins");
			return;
		}

		if (Params[0] == AdminPassword)
		{
			Sender.ClientMessage("You became a server administrator.");
			Sender.bAdmin = True;
			Sender.PlayerReplicationInfo.bAdmin = False;
			Log("Administrator"@Sender.PlayerReplicationInfo.PlayerName@"logged in with SemiAdmin.");
		}
		else Sender.ClientMessage("Incorrect Password");
	}

	else if (Command == "ADMINLOGOUT")
	{
		if (Sender.bAdmin)
		{
			Sender.ClientMessage("You gave up administrator abilities.");
			Sender.bAdmin = False;
			Sender.PlayerReplicationInfo.bAdmin = False;
			Log("Administrator ("$Sender.PlayerReplicationInfo.PlayerName$") logged out with SemiAdmin.");
		}
	}

	else if (Command == "SUICIDE")
	{
		Sender.Health = 0;
		Sender.Died( None, 'AdminSuicide', Sender.Location );
	}

	else if (IsAdmin(Sender))
	{
		if (Command == "ALO")
			LogoutAdmin();
		else if (Command == "PLO")
			LogoutAdmin("silent");
		else if (Command == "USERLIST")
			Userlist();
		else if (!DoAdminCommand() && (IsMasterAdmin() || Sender.bAdmin))
			DoMasterAdminCommand();
		
	}

	DoFreeCommand();

	Super.Mutate(MutateString, Sender);
}

function DoFreeCommand()
{
	if (Command ~= "NEXTMAPS")		NextMaps();
//	else if (Command ~= "SATEST")	DoTest();
	else Super.DoFreeCommand();
}

function bool DoAdminCommand()
{
	if (HandleKick())         return true;
	else if (HandleSA_Action())     return true;
	else if (HandleBan())     return true;
	else if (HandleMaps())    return true;
	else if (HandleGame())    return true;
	else if (HandleLadder())  return true;
	else if (HandleBots())    return true;
	else if (HandleSummon())  return true;
	else if (HandleFull())    return true;
	
	return Super.DoAdminCommand();
}

function DoMasterAdminCommand()
{
}

function DoTest()
{
}

function bool HandleSA_Action()
{
    local string cmds;

    
    cmds="ABUSECODES|ABUSE|REASONCODES|REASON|";
    cmds=cmds$"WARN|WARNID|WARNPART|WARNLIST|WARNINGS|WARNINGSID|";
    cmds=cmds$"RESPAWN|RESPAWNID|RESPAWNPART|";
    cmds=cmds$"ZEROFRAG|ZEROFRAGID|ZEROFRAGPART|";
    cmds=cmds$"MUTE|MUTEID|MUTEPART|";
    cmds=cmds$"UNMUTE|UNMUTEID|UNMUTEPART|UNMUTEALL|UNMUTEFREE";
    
	if (!IsPartOf(Command, cmds))
		return false;

	if (!CanSA_ActionPlayers(SA_Action.NoAction))
	{
		LogNoPrivs();
		return true;
	}
	
	if (Command == "REASONCODES")		LogMessage(ReasonCodes());
	else if (Command == "REASON")		HandleReasonSubCmd();	

	else if (Command == "ABUSECODES")	LogMessage(AbuseCodes());
	else if (Command == "ABUSE")		HandleAbuseSubCmd();	

	else if (Command == "WARN")		LogMessage(SA_ActionByName(SA_Action.Warning));
	else if (Command == "WARNID")		LogMessage(SA_ActionById(SA_Action.Warning));
	else if (Command == "WARNPART")		LogMessage(SA_ActionWild(SA_Action.Warning));
	else if (Command == "WARNLIST")		LogMessage(PlayerList());
	else if (Command == "WARNINGS")		LogMessage(WarningsByName());
	else if (Command == "WARNINGSID")	LogMessage(WarningsByID());

	else if ((Command == "RESPAWN") ||
		(Command == "RESPAWNPART"))	LogMessage(SA_ActionWild(SA_Action.Respawn));
	else if (Command == "RESPAWNID")	LogMessage(SA_ActionById(SA_Action.Respawn));

	else if (Command == "ZEROFRAG")		LogMessage(SA_ActionWild(SA_Action.ZEROFRAG));
	else if (Command == "ZEROFRAGID")	LogMessage(SA_ActionById(SA_Action.ZEROFRAG));
	else if (Command == "ZEROFRAGPART")	LogMessage(SA_ActionWild(SA_Action.ZEROFRAG));
	
	else if ((Command == "MUTE") || 
		(Command == "MUTEPART"))	LogMessage(SA_ActionWild(SA_Action.MUTE));
	else if (Command == "MUTEID")		LogMessage(SA_ActionById(SA_Action.MUTE));
		
	else if ((Command == "UNMUTE") ||
		(Command == "UNMUTEPART"))	LogMessage(SA_ActionWild(SA_Action.UNMUTE));
	else if (Command == "UNMUTEID")		LogMessage(SA_ActionById(SA_Action.UNMUTE));
	else if (Command == "UNMUTEALL")	LogMessage(UnMuteAll());
	else if (Command == "UNMUTEFREE")	LogMessage(UnMuteFree());
		
	return true;
}



function bool HandleKick()
{
	if (!IsPartOf(Command, "KICK|KICKID|KICKLIST|KICKPART"))
		return false;

	if (!CanKickPlayers()  || CurrentUserSecLevel() < USLServerKick)
	{
		LogNoPrivs();
		return true;
	}
	
	if ((Command == "KICK") ||
		(Command == "KICKPART"))	LogMessage(KickWild());
	else if (Command == "KICKID")		LogMessage(KickById());
	else if (Command == "KICKLIST")		LogMessage(PlayerList());
	
	return true;
}

function bool HandleBan()
{
	if (!IsPartOf(Command, "BAN|BANID|BANIP"))
		return false;

	if (!CanBanPlayers() || CurrentUserSecLevel() < USLServerBanIP)
	{
		LogNoPrivs();
		return true;
	}
	
	if (Command == "BAN")			LogMessage(Ban());
	else if (Command == "BANID")		LogMessage(BanId());
	else if (Command == "BANIP")		LogMessage(BanIp());

	return true;
}

function bool HandleMaps()
{
	if (!IsPartOf(Command, "MAP"))
		return false;

	if (!CanChangeMaps())
	{
		LogNoPrivs();
		return true;
	}
		
	if (Command == "MAP")			HandleMapSubCmd();
	
	return true;
}

function HandleMapSubCmd()
{
	if (SubCmd == "HELP")					HelpMap();
	else if (SubCmd == "NEXT")
	{
		if (CurrentUserSecLevel() >= USLMapNext)	LogMessage(NextMap());
	}
	else if (SubCmd == "RESTART")
	{
		if (CurrentUserSecLevel() >= USLMapRestart)	LogMessage(RestartMap());
	}
	else
	{
		if (CurrentUserSecLevel() >= USLMapChange)	LogMessage(GotoMap());
	}
}

function bool HandleGame()
{
	if (!IsPartOf(Command, "GAME|SET|DEL|MUTATORS|MAPLIST|STOP|START|PAUSE|UNPAUSE"))
		return false;

	if (!CanChangeGame() )
	{
		LogNoPrivs();
		return true;
	}
	
	if (Command == "GAME")				HandleGameSubCmd();
//	else if (Command == "MUTATORS")		HandleMutatorsSubCmd();
//	else if (Command == "MAPLIST")		HandleMaplistSubCmd();
	
	return true;
}

function HandleGameSubCmd()
{
	if (SubCmd == "HELP")						HelpGame();
	else if (SubCmd == "EDIT")
	{
		if (CurrentUserSecLevel() >= USLGameEdit)		LogMessage(GameStartEdit());
	}
	else if (SubCmd == "SET")
	{
		if (CurrentUserSecLevel() >= USLGameEdit)		LogMessage(GameSetCmd());
	}
	else if (SubCmd == "DEL")
	{
		if (CurrentUserSecLevel() >= USLGameEdit)		LogMessage(GameSetDelCmd());
	}
	else if (SubCmd == "GET")
	{
		if (CurrentUserSecLevel() >= USLGameEdit)		LogMessage(GameGetCmd());
	}
//	else if (SubCmd == "SAVE")					LogMessage(GameSave());
//	else if (SubCmd == "LOAD")					LogMessage(GameLoad())
	else if (SubCmd == "APPLYCHANGES")
	{
		if (CurrentUserSecLevel() >= USLGameApplyChanges)	LogMessage(GameApplyChanges());
	}
	else if (SubCmd == "CHANGETO")
	{
		if (CurrentUserSecLevel() >= USLGameEdit)		LogMessage(GameChangeTo());
	}
	else if (SubCmd == "PAUSE")
	{
		if (CurrentUserSecLevel() >= USLGamePause)		LogMessage(GamePause());
	}
	else if (SubCmd == "UNPAUSE")
	{
		if (CurrentUserSecLevel() >= USLGamePause)		LogMessage(GameUnPause());
	}
	else if (SubCmd == "STOP")
	{
		if (CurrentUserSecLevel() >= USLGameStop)		LogMessage(GameStop());
	}
	else if (SubCmd == "START")
	{
		if(CurrentUserSecLevel() >= USLGameStop)		LogMessage(GameStart());
	}
}

function HandleMutatorsSubCmd()
{
//	if (SubCmd == "HELP")				HelpMutators();
//	else if (SubCmd == "ADD")			LogMessage(GameMutatorsAdd());
//	else if (SubCmd == "DEL")			LogMessage(GameMutatorsDel());
//	else if (SubCmd == "CLEAR")			LogMessage(GameMutatorsClear());
//	else if (SubCmd == "LIST")			LogMessage(GameMutatorsList());
//	else						LogMessage(GameMutatorsSet());
}

function HandleMaplistSubCmd()
{
//	if (SubCmd == "HELP")				HelpMaplist();
//	else if (SubCmd == "ADD")			LogMessage(GameMaplistAdd());
//	else if (SubCmd == "DEL")			LogMessage(GameMaplistDel());
//	else if (SubCmd == "CLEAR")			LogMessage(GameMaplistClear());
//	else if (SubCmd == "LIST")			LogMessage(GameMaplistList());
//	else						LogMessage(GameMaplistSet());
}

function bool HandleLadder()
{
	if (!IsPartOf(Command, "LADDER"))
		return false;
	
	LogMessage("@Not Implemented yet!");
	return true;
}

function bool HandleBots()
{
	if (!IsPartOf(Command, "KILLBOTS|DELBOT|ADDBOT"))
		return false;

	if (!CanManageBots() || CurrentUserSecLevel() < USLServerManageBots)
	{
		LogNoPrivs();
		return true;
	}
	if (Command == "KILLBOTS")	LogMessage(KillBots());
	else if (Command == "DELBOT")	LogMessage(DelBot());
	else if (Command == "ADDBOT")   LogMessage(AddBot());
	return true;
}

function bool HandleSummon()
{
	if (!IsPartOf(Command, "SUMMON"))
		return false;
		
	if (!CanSummonItems())
	{
		LogNoPrivs();
		return true;
	}

	if (Command == "SUMMON")	LogMessage(SummonItem());
	return true;
}

function bool HandleFull()
{
	//if (!CanDoFull())
	//{
	//	LogNoPrivs();
	//	return true;
	//}
	if (HandleFly())		return true;
	else if (HandleGoto())		return true;
	else if (HandleGod())		return true;
	else if (HandleSlap())		return true;
	else if (HandleBoost())		return true;
	else if (HandleVisible())	return true;
	else if (HandleAdmin())		return true;
	return false;
}

function bool HandleFly()
{
	if (!IsPartOf(Command, "FLY|WALK|GHOST"))
		return false;
	if (!CanDoFly())
	{
		LogNoPrivs();
		return true;
	}
	if (Command == "FLY")		FullFly();
	else if (Command == "WALK")	FullWalk();
	else if (Command == "GHOST")	FullGhost();
	return true;
}

function bool HandleGoto()
{
	if (!IsPartOf(Command, "GOTO|LOCATION|GOTOXYZ"))
		return false;
	if (!CanDoGoto())
	{
		LogNoPrivs();
		return true;
	}
	if (Command == "GOTO")		FullGoto();
	else if (Command == "GOTOXYZ")	FullGotoXYZ();
	else if (Command == "LOCATION")	FullLocation();
	return true;
}

function bool HandleGod()
{
	if (!IsPartOf(Command, "GOD|HEALTH"))
		return false;
	if (!CanDoGod())
	{
		LogNoPrivs();
		return true;
	}
	if (Command == "GOD")		FullGod();
	else if (Command == "HEALTH")	FullHealth();
	return true;
}

function bool HandleSlap()
{
	if (!IsPartOf(Command, "SLAP|SLAPQUIET|QUIETSLAP|SLAPSILENT|SILENTSLAP|EXPLODE|EXPLODEQUIET|QUIETEXPLODE|EXPLODESILENT|SILENTEXPLODE"))
		return false;
	if (!CanDoSlap())
	{
		LogNoPrivs();
		return true;
	}
	if 	 (Command == "SLAP")			FullSlap(false);
	else if ((Command == "SLAPQUIET") ||
		 (Command == "QUIETSLAP") ||
		 (Command == "SLAPSILENT") ||
		 (Command == "SILENTSLAP"))		FullSlap(true);
	else if  (Command == "EXPLODE")			FullExplode(false);
	else if ((Command == "EXPLODEQUIET") ||
		 (Command == "QUIETEXPLODE") ||
		 (Command == "EXPLODESILENT") ||
		 (Command == "SILENTEXPLODE"))		FullExplode(true);
	return true;
}

function bool HandleBoost()
{
	if (!IsPartOf(Command, "BOOST|BOUNCE"))
		return false;
	if (!CanDoBoost())
	{
		LogNoPrivs();
		return true;
	}
	if (Command == "BOOST")		FullBoost();
	else if (Command == "BOUNCE")	FullBounce();
	return true;
}

function bool HandleVisible()
{
	if (!IsPartOf(Command, "VISIBLE"))
		return false;
	if (!CanDoVisible())
	{
		LogNoPrivs();
		return true;
	}
	if (Command == "VISIBLE")	FullVisible();
	return true;
}

function bool HandleAdmin()
{
	local string cmds;
	cmds="ADMIN|RENAME|CHANGENAME|RENAMEID|CHANGENAMEID|";
	cmds=cmds$"QUIETRENAME|QUIETCHANGENAME|RENAMEQUIET|";
	cmds=cmds$"CHANGENAMEQUIET|SILENTRENAME|SILENTCHANGENAME|";
	cmds=cmds$"RENAMESILENT|CHANGENAMESILENT|QUIETRENAMEID|";
	cmds=cmds$"QUIETCHANGENAMEID|RENAMEIDQUIET|CHANGENAMEIDQUIET|";
	cmds=cmds$"SILENTRENAMEID|SILENTCHANGENAMEID|RENAMEIDSILENT|CHANGENAMEIDSILENT|";
	cmds=cmds$"TEAMCHANGE|CHANGETEAM|SWITCHTEAM|TEAMSWITCH";

	if (!IsPartOf(Command, cmds))
		return false;
	if (!CanDoAdmin())
	{
		LogNoPrivs();
		return true;
	}
	if (Command == "ADMIN")				FullAdmin();
	else if ((Command == "RENAME") ||
		 (Command == "CHANGENAME"))		FullName(false,false);
	else if ((Command == "RENAMEID") ||
		 (Command == "CHANGENAMEID"))		FullName(true,false);
	else if ((Command == "QUIETRENAME") ||
		 (Command == "QUIETCHANGENAME") ||
		 (Command == "RENAMEQUIET") ||
		 (Command == "CHANGENAMEQUIET") ||
		 (Command == "SILENTRENAME") ||
		 (Command == "SILENTCHANGENAME") ||
		 (Command == "RENAMESILENT") ||
		 (Command == "CHANGENAMESILENT"))	FullName(false,true);
	else if ((Command == "QUIETRENAMEID") ||
		 (Command == "QUIETCHANGENAMEID") ||
		 (Command == "RENAMEIDQUIET") ||
		 (Command == "CHANGENAMEIDQUIET") ||
		 (Command == "SILENTRENAMEID") ||
		 (Command == "SILENTCHANGENAMEID") ||
		 (Command == "RENAMEIDSILENT") ||
		 (Command == "CHANGENAMEIDSILENT"))	FullName(true,true);
	else if ((Command == "TEAMCHANGE") ||
		 (Command == "CHANGETEAM") ||
		 (Command == "SWITCHTEAM") ||
		 (Command == "TEAMSWITCH"))		FullTeam();

	return true;
}
	
// ###############################################
// ## LOGIN/LOGOUT ASSESSMENT
// ###############################################

function bool WebLogin(PlayerPawn Sender)
{
	Issuer = Sender;
	Admin.User = Users[CurID];
	Admin.Group = FindGroup(Users[CurID].Group);
	Admin.PRI = Sender.PlayerReplicationInfo;
	Admins[NumLogged] = Admin;
	NumLogged++;
	bIsWebAdmin = true;
}

function WebLogout()
{
	Unlog(CurID);
	bIsWebAdmin = false;	
}

function LogWithTime(string s1, string s2)
{
    local string AbsoluteTime;
    TournamentGameInfo(Level.Game).GetTimeStamp(AbsoluteTime);
    WriteLog(s1$": "$AbsoluteTime$":"$chr(9)$s2);
}

function ModifyPlayer(Pawn Other)
{
    local PlayerPawn PP;
    local string IP;
    
    if (bLogPlayersOnRespawn)
    {
        PP=PlayerPawn(Other);
        if (PP!=None) 
        {        
            LogWithTime("SpawnLog","IP:"$PP.GetPlayerNetworkAddress()$chr(9)$"NICK:'"$PP.PlayerReplicationInfo.PlayerName$"'");
                
        }
    }
	Super.ModifyPlayer(Other);
}

function string GetPlayerIP(PlayerPawn PP)
{
    local string IP;
    IP=PP.GetPlayerNetworkAddress();
    return Left(IP, InStr(IP, ":"));
}

function LoginAdmin(PlayerPawn Sender, optional string silent)
{
	Admin.User = Users[CurID];
	Admin.Group = FindGroup(Users[CurID].Group);
	Admin.PRI = Sender.PlayerReplicationInfo;
	Admins[NumLogged] = Admin;
	NumLogged++;
	// Tell Everyone
	if (silent~="silent")
	{
    		Issuer.ClientMessage("Welcome, silent"@Issuer.PlayerReplicationInfo.PlayerName@". This is SemiAdmin"@Version);
    		LogServerMessage(Issuer.PlayerReplicationInfo.PlayerName@"silently became a limited administrator from"@SenderIP);
	}
	else
	{
    		Level.Game.BroadcastMessage( Issuer.PlayerReplicationInfo.PlayerName@"logged into"@Admin.User.Name@"and became a limited administrator." );
	    	Issuer.ClientMessage("Welcome"@Issuer.PlayerReplicationInfo.PlayerName@". This is SemiAdmin"@Version);
    		LogServerMessage(Issuer.PlayerReplicationInfo.PlayerName@"logged into"@Admin.User.Name@"and became a limited administrator from"@SenderIP);
	}
	ClearParams();
}

function LogoutAdmin( optional string silent )
{
local int i, idx;
	// Tell the user they logged out
	Issuer.ClientMessage("You ("@Admin.User.Name@") logged out of SemiAdmin"@Version);

	// Find LogID from CurID
	for (i = 0; i<NumLogged; i++)
		if (Admins[i] == Admin)
			Unlog(i);

	// Set there Collision to hit everything
	Issuer.SetCollision(true, true, true);

	// Tell Everyone
	if (! (silent~="silent"))
    	Level.Game.BroadcastMessage( Issuer.PlayerReplicationInfo.PlayerName@"gave up limited administrator abilities." );
	LogServerMessage(Issuer.PlayerReplicationInfo.PlayerName@"gave up his limited admin abilities from"@SenderIP); 
	Issuer.SetCollision(true, true , true);
	if (Issuer.ReducedDamageType == 'All') 
	{
		Issuer.ReducedDamageType = 'None';
	}
}

function bool IsAdmin(PlayerPawn Sender)
{
local int i;

	// Clean Disconnected Admins
	CleanDisconnected();
	
	for (i = 0; i<NumLogged; i++)
	{
		if (Admins[i].PRI == Sender.PlayerReplicationInfo)
		{
			Admin = Admins[i];
			CurID = FindUserId(Admin.User.Name);
			return true;
		}
	}
		
	return false;
}

//HOBBIT ADDED

//function bool IsMsterAdmin(PlayerPawn Sender)
//{
//local int i;
//
//	// Clean Disconnected Admins
//	CleanDisconnected();
//	
//	for (i = 0; i<NumLogged; i++)
//	{
//		if (Admins[i].PRI == Sender.PlayerReplicationInfo)
//		{
//			Admin = Admins[i];
//			CurID = FindUserId(Admin.User.Name);
//			if (string(Admins[i].group) = string(FindAdminGroup.Name))
//			{
//				return true;
//			}
//		}
//	}	
//	return false;
//}
//END HOBBIT ADDED

function CleanDisconnected()
{
local int i;
local Pawn aPawn;
local bool bNotFound;

	bNotFound = true;
	while (bNotFound)
	{
		bNotFound = false;
		for (i = 0; i<NumLogged; i++)
		{
			if (i < NumLogged)
			{
				for (aPawn = Level.PawnList; aPawn != None; aPawn = aPawn.NextPawn)
					if (aPawn.PlayerReplicationInfo == Admins[i].PRI)
						break;

				if (aPawn == None)
				{
					// Not logged anymore
					LogServerMessage(Admins[i].User.Name@"was found disconnected, forced to logout");
					unlog(i);
					bNotFound = true;
					break;
				}
			}
		}		
	} 
}

function bool IsValidLogin(string uname, string upass)
{
local int i;

	if (FindAdminGroup() == NoneGroup)
	{
		NewGroup("admin", "", 65535);
		LogMessage("Admin group was created");
		SaveConfig();
	}

	if (NumUsers == 0)
	{
		NewUser("admin", "admin", FindAdminGroup().Name);
		// If it was the first run
		/*
		Users[0].Username = "admin";
		Users[0].Password = "admin";
		Users[0].Group = FindAdminGroup().Name;
		NumUsers++;
		*/
		LogMessage("Admin account was created and Associated to group '"$Users[0].Group$"'");
		SaveConfig();
	}

	if (uname == "")
	{
		UsedName = "Empty Name";
		return false;
	}
	if (upass == "")
	{
		UsedName = uname@"with no password";
		return false;
	}
	if (!CheckUserName(uname))
	{
		UsedName = uname@": Invalid characters in name";
		return false;
	}
	if (!CheckPassword(upass))
	{
		UsedName = uname@": Invalid characters in password";
		return false;
	}
	
	// Find uname in list of users
	for (i = 0; i<NumUsers; i++)
	{
		if (Users[i].Name == uname)
		{
			if (Users[i].Password != upass)
			{
				UsedName = uname@"with invalid password";
				return false;
			}
			CurID = i;
			return true;
		}
	}
	UsedName = "Unknown username:"@uname;
	return false;
}

// ###############################################
// ## NO SPECIAL PRIVILEGES REQUIRED
// ###############################################

// ###############################################
// ## WARNINGLIST FUNCTIONS
// ###############################################

function string GetAllWarnings(WarnedList theList, string lookfor, out int i)
{
    // returns a string of all warnings containing a particular string
    // e.g. get warnings for "PLAYERNAME" 
    local string warning, result;
    
    warning=theList.FindFirstWarningText(lookfor);
    while (warning!="")
    {
        i++;
		result=result$chr(10)$warning;
        warning=theList.FindNextWarningText(lookfor);
    }    
    return result;    
}

function string ClearAllWarningsFor(WarnedList theList, string lookfor, out int i)
{
    // clears all warnings containing a particular string
    // retuns a string of all the warnings cleared
    // e.g. clear warnings for "PLAYERNAME" 
    local string warning, result;
    
    warning=theList.FindFirstWarningText(lookfor);
    while (warning!="")
    {
        i++;
        theList.Warned[theList.FindWarningTextIndex]="";
   	    LogServerMessage(Issuer.PlayerReplicationInfo.PlayerName@"cleared Warning:"@warning);
     
		result=result$chr(10)$warning;        		
        warning=theList.FindNextWarningText(lookfor);
    }    
    if (i>0) theList.SaveConfig();
    return result;    
}

// ###############################################
// ## SA_Action MANAGEMENT
// ###############################################
// mutate warnings <playername> 
function string WarningsByName()
{
    // count&list the warnings for a player
local int i;
local string playername,warnings;
        
	if (NumParams < 1)
	{
		Issuer.ClientMessage("format: warnings <playername> [clear]");
		return "";
	}

    playername=Params[0];
    
    if(Params[1]~="clear")
    {
        if (CurrentUserSecLevel() < USLWarningIssue)
            return "@You must have a higher security level to clear warnings";
            
        warnings=ClearAllWarningsFor(WarnedList,playername,i);
		if (warnings!="") 
		{
		    Issuer.ClientMessage(warnings);
            LogServerMessage(Issuer.PlayerReplicationInfo.PlayerName@"cleared"@i@"warnings for '"$playername$"'");        
        }
        Issuer.ClientMessage(i@"warnings cleared for '"$playername$"'");
    }
    else
    {
        warnings=GetAllWarnings(WarnedList,playername,i);
		if (warnings!="") Issuer.ClientMessage(warnings);
        Issuer.ClientMessage(i@"warnings found for '"$playername$"'");
    }

	return "";		    
}

// mutate warningsid <playername> [clear]
function string WarningsById()
{

    // count&list the warnings for a player
local int i;
local string playername,warnings;
local Pawn aPawn, NextPawn;
        
	if (NumParams < 1)
	{
		Issuer.ClientMessage("format: warningsid <playerid> [clear]");
		return "";
	}

    aPawn=Level.PawnList;
    while (aPawn!=None)
    {
    	if ( aPawn.bIsPlayer && string(aPawn.PlayerReplicationInfo.PlayerID)==Params[0] && (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
        {
            playername=aPawn.PlayerReplicationInfo.PlayerName;
            break;
        }
        aPawn=aPawn.NextPawn;   
    }
    
    if(Params[1]~="clear")
    {
        if (CurrentUserSecLevel() < USLWarningClear)
            return "@You must have a higher security level to clear warnings";

        warnings=ClearAllWarningsFor(WarnedList,playername,i);
		if (warnings!="") 
		{
		    Issuer.ClientMessage(warnings);
            LogServerMessage(Issuer.PlayerReplicationInfo.PlayerName@"cleared"@i@"warnings for '"$playername$"'");        
        }
        Issuer.ClientMessage(i@"warnings cleared for '"$playername$"'");
    }
    else
    {
        warnings=GetAllWarnings(WarnedList,playername,i);
		if (warnings!="") Issuer.ClientMessage(warnings);
        Issuer.ClientMessage(i@"warnings found for '"$playername$"'");
    }

	return "";	    
}


function string SA_ActionByName(SA_Action action)
{
local Pawn aPawn, NextPawn;
local int i, SA_Actioned, failed, prvt, reason;

	if (!CanSA_ActionPlayers(action))
	{
		LogNoPrivs();
		return "";
	}
	    
    if (Params[0]~="private") prvt=1;
    reason = int(Params[prvt]);
//    WriteLog("pcl: '"$Params[prvt]$"'");
    
	if (NumParams < prvt+2)
	{
		Issuer.ClientMessage("format: warn|respawn [private] <reasonid> <playername> [playername...]");
		return "";
	}


	for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
	{
		NextPawn = aPawn.NextPawn;
		for (i = prvt+1; i<NumParams; i++)
		{
			if ( aPawn.bIsPlayer
				&& aPawn.PlayerReplicationInfo.PlayerName~=Params[i]
				&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
			{
				if (SA_ActionByPRI(aPawn, aPawn.PlayerReplicationInfo, action, reason, prvt))
					SA_Actioned++;
				else
					failed++;
				break;
			}
		}
	}
//	SendSA_ActionResults(SA_Actioned, failed);
	return "";	
}

function string UnMuteAll()
{
local int i;
    
    for(i=0; i<128; i++)
        Mutes[i]="";

    SaveConfig();
    CurrentMutes="";
    return "@All Mutes successfully removed!";
}

function string UnMuteFree()
{
local string thisParam, NewMutes;

	if (NumParams < 1)
	{
		Issuer.ClientMessage("format: unmutefree <freetext> [freetext...]");
		return "";
	}
	
	thisParam=PopParam();
	    
	while(thisParam!="")
	{
	    UnMute(thisParam);
    	thisParam=PopParam();    
	}

    return "@Mutes successfully removed!";

    
}

// mutate warnid|respawnid <private> <playerid> 
function string SA_ActionById(SA_Action action)
{
local Pawn aPawn, NextPawn;
local int i, SA_Actioned, failed, prvt, reason;
//    WriteLog("SAM: action="$action@"Params[0]="$params[0]@"Params[1]="$params[1]@"Params[2]="$params[2]);
	if (!CanSA_ActionPlayers(action))
	{
		LogNoPrivs();
		return "";
	}
    
    if (Params[0]~="private") prvt=1;
    reason = int(Params[prvt]);
//    WriteLog("pcl: '"$Params[prvt]$"'");
    
	if (NumParams < prvt+2)
	{
		Issuer.ClientMessage("format: warnid|respawnid|muteid|unmuteid|zerofrag [private] <reasonid> <playerid> [playerid...]");
//		WriteLog("format: warnid|respawnid|muteid|unmuteid|zerofrag [private] <reasonid> <playerid> [playerid...]");
		return "";
	}


	for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
	{
		NextPawn = aPawn.NextPawn;
		for (i = prvt+1; i<NumParams; i++)
		{
			if ( aPawn.bIsPlayer
				&& string(aPawn.PlayerReplicationInfo.PlayerID)==Params[i]
				&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
			{
				if (SA_ActionByPRI(aPawn, aPawn.PlayerReplicationInfo, action, reason, prvt))
					SA_Actioned++;
				else
					failed++;
				break;
			}
		}
	}
//	SendSA_ActionResults(SA_Actioned, failed);
	return "";	
}

function string SA_ActionWild(SA_Action action)
{
local Pawn aPawn, NextPawn;
local int i, SA_Actioned, failed, prvt, reason;
    
	if (!CanSA_ActionPlayers(action))
	{
		LogNoPrivs();
		return "";
	}
    
    if (Params[0]~="private") prvt=1;
    reason = int(Params[prvt]);
//    WriteLog("pcl: '"$Params[prvt]$"'");
    
	if (NumParams < prvt+1)
	{
		Issuer.ClientMessage("format: warnpart|respawnpart [private] <partialname> [partialname...]");
		return "";
	}

	for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
	{
		NextPawn = aPawn.NextPawn;
		for (i = prvt; i<NumParams; i++)
		{
			if ( aPawn.bIsPlayer
				&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i])
				&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
			{
				if (SA_ActionByPRI(aPawn, aPawn.PlayerReplicationInfo, action, reason,  prvt))
					SA_Actioned++;
				else
					failed++;
				break;
			}
		}
	}
//	SendSA_ActionResults(SA_Actioned, failed);
	return "";	
}

function string PlayerList()
{
local Pawn aPawn;
local PlayerReplicationInfo aPRI; 
local string list, playerIP;
    
	for( aPawn=Level.PawnList; aPawn!=None; aPawn=aPawn.NextPawn )
	{
		if ( aPawn.bIsPlayer && NetConnection(PlayerPawn(aPawn).Player)!=None)
		{
			aPRI = aPawn.PlayerReplicationInfo;
			PlayerIP=GetPlayerIP(PlayerPawn(aPawn));
//			list = list@Right("    "$aPRI.PlayerID, 4)@":"@aPRI.PlayerName@"@"@PlayerIP;
//			Issuer.ClientMessage(Right("    "$aPRI.PlayerID, 4)@":"@aPRI.PlayerName);
			Issuer.ClientMessage(Right("    "$aPRI.PlayerID, 4)@":"@aPRI.PlayerName@"@"@PlayerIP);
		}
	}
//	Issuer.ClientMessage(list);
	return "";
}

function HandleReasonSubCmd()
{
	
	if (SubCmd == "ADD" && CurrentUserSecLevel() >= USLReasonAdd) 
	    LogMessage(AddReason());
	else if (SubCmd == "EDIT" && CurrentUserSecLevel() >= USLReasonEdit)		
	    LogMessage(EditReason());
	else if (SubCmd == "LIST")		LogMessage(ReasonCodes());
}

function HandleAbuseSubCmd()
{
	if (SubCmd == "ADD")			LogMessage(AddAbuse());
	else if (SubCmd == "EDIT")		LogMessage(EditAbuse());
	else if (SubCmd == "LIST")		LogMessage(AbuseCodes());
}

function string EditAbuse()
{
local string thisParam, Abuse;
local int Abusecode;

	PopParam();	// Pop SubCmd
	Abusecode=int(PopParam());  // Abusecode
	
	thisParam=PopParam();
	if (thisParam=="")
		return "Invalid number of parameters"; 
	    
	while(thisParam!="")
	{
	    if(Abuse=="") 
	        Abuse=thisParam;
	    else
	        Abuse=Abuse@thisParam;
    	thisParam=PopParam();    
	}
    AbuseMessage[Abusecode]=Abuse;
    SaveConfig();
    return "@Abuse["@Abusecode@"]='"$Abuse$"' successfully updated!";

}

function string AddAbuse()
{
local string thisParam, Abuse;
local int i;
local bool done;

	PopParam();	// Pop SubCmd
	thisParam=PopParam();
	if (thisParam=="")
		return "Invalid number of parameters"; 
	    
	while(thisParam!="")
	{
	    if(Abuse=="") 
	        Abuse=thisParam;
	    else
	        Abuse=Abuse@thisParam;
    	thisParam=PopParam();    
	}
	
//	if (Abusecode
    for (i=0; i<64; i++)
    {
        if (AbuseMessage[i] == "")
        {
            AbuseMessage[i]=Abuse;
            done=true;
            SaveConfig();
            break;
        }
    }
	
    if(done)
    	return "@Abuse["@i@"]='"$Abuse$"' successfully added!";
    else
    	return "@Abuse was not added!";

}

function string AbuseCodes()
{
local string list;
local int i;    
    
    for (i=0; i<64; i++)
    {
        if (AbuseMessage[i] != "")
    	    Issuer.ClientMessage(i$": "$AbuseMessage[i]);
	}
	return "";
}


function string EditReason()
{
local string thisParam, reason;
local int reasoncode;

	PopParam();	// Pop SubCmd
	reasoncode=int(PopParam());  // reasoncode
	
	thisParam=PopParam();
	if (thisParam=="")
		return "Invalid number of parameters"; 
	    
	while(thisParam!="")
	{
	    if(reason=="") 
	        reason=thisParam;
	    else
	        reason=reason@thisParam;
    	thisParam=PopParam();    
	}
    ReasonMessage[reasoncode]=reason;
    SaveConfig();
    return "@Reason["@reasoncode@"]='"$reason$"' successfully updated!";

}

function string AddReason()
{
local string thisParam, reason;
local int i;
local bool done;

	PopParam();	// Pop SubCmd
	thisParam=PopParam();
	if (thisParam=="")
		return "Invalid number of parameters"; 
	    
	while(thisParam!="")
	{
	    if(reason=="") 
	        reason=thisParam;
	    else
	        reason=reason@thisParam;
    	thisParam=PopParam();    
	}
	
//	if (reasoncode
    for (i=0; i<64; i++)
    {
        if (ReasonMessage[i] == "")
        {
            ReasonMessage[i]=reason;
            done=true;
            SaveConfig();
            break;
        }
	}
	
	if(done)
    	return "@Reason["@i@"]='"$reason$"' successfully added!";
    else
    	return "@Reason was not added!";

}

function string ReasonCodes()
{
local string list;
local int i;    
    
    for (i=0; i<64; i++)
    {
        if (ReasonMessage[i] != "") 
    	    Issuer.ClientMessage(i$": "$ReasonMessage[i]);
	}
	return "";
}



function string UnMute(string unmuteText)
{
local int i;
local string NewMutes;
local bool muted1;
    
    NewMutes="";
    muted1=false;
    // unmute the nick and IP
    for(i=0; i<128; i++)
    {        
        if (Mutes[i]!="")                
        {    
//            WriteLog("pcl: Mutes["$i$"]="$Mutes[i]$"  IP="$IP$"   playername="$playername);
            
            if (Mutes[i]==unmuteText)
            {
                //WriteLog("pcl: Resetting Mutes["$i$"]");

                Mutes[i]="";
                //if (muted1) break; 
                muted1=true;
            } 
            else
                NewMutes=NewMutes$"+"$Mutes[i]$"+";
        }
    }
    if (muted1) 
    {
//        WriteLog ("pcl: Saving Config");
        SaveConfig();
    } 
    CurrentMutes=NewMutes;
    return NewMutes;    
}



function bool SA_ActionByPRI(Pawn aPawn, PlayerReplicationInfo pPRI, SA_Action action, int reasoncode, int isPrivate )
{
local int logid, i, j;
local string reason; 
local string AbsoluteTime,actionText, IP, playername, NewMutes;
local bool success, muted1, muted2, bQuiet;
    
    TournamentGameInfo(Level.Game).GetTimeStamp(AbsoluteTime);
    actionText=SA_ActionCodes[action];

    reason=ReasonMessage[reasoncode];
    if (reason=="") reason="General Conduct";
//    warning = "'"$reasoncode$"' "@warning;
    
	if (!pPRI.bIsABot)
	{
		// Before Warning the player, make sure he's not a logged admin
/*
		logid = FindLoggedByPRI(pPRI);
		if (logid != -1)
		{
			if (CanManageUsers())
				Unlog(logid);
			else
			{
				TellIssuer(pPRI.PlayerName@"is a currently logged admin and cannot be Warned");
				return false;
			}
		}
*/
	    switch (action)
		{
		case SA_Action.Warning:
			break;
			
		case SA_Action.Respawn:
		    aPawn.Died(None,'Admin',vect(0,0,0));
			break;
			
		case SA_Action.ZeroFrag:
		    pPRI.Score=-1;
			break;

		case SA_Action.UnMute:
		    bQuiet=true;
		    playername=pPRI.PlayerName;
		    Level.Game.BroadcastMessage(playername@"is no longer muted.");
		    IP=GetPlayerIP(PlayerPawn(aPawn));
		    UnMute(playername);
		    UnMute(IP);
            break;
            
		case SA_Action.Mute:
		    bQuiet=true;
		    playername=pPRI.PlayerName;
		    IP=GetPlayerIP(PlayerPawn(aPawn));
		    Level.Game.BroadcastMessage(playername@"has been muted.");
		    // mute the nick
		    j=-1;
		    muted1=false;
		    for(i=0; i<128; i++)
		    {
                if (Mutes[i]==playername)
                {
                    muted1=true;
                    break;
                } 
                else if (Mutes[i]=="" && j==-1)
                {
                    j=i;
                }
		    }
		    if (! muted1 && j>=0)
		    {
		        Mutes[j]=playername;
		        CurrentMutes=CurrentMutes$"+"$playername$"+";
		        if (pPRI.voicetype!=None) pPRI.voicetype = None;
		        SaveConfig();
		    }
            
            // mute the IP address
		    j=-1;
		    muted2=false;
		    for(i=0; i<128; i++)
		    {
                if (Mutes[i]==IP)
                {
                    muted2=true;
                    break;
                } 
                else if (Mutes[i]=="" && j==-1)
                {
                    j=i;
                }
		    }
		    if (! muted2 && j>=0)
		    {
		        Mutes[j]=IP;
		        CurrentMutes=CurrentMutes$"+"$IP$"+";
		        if (pPRI.voicetype!=None) pPRI.voicetype = None;
		        SaveConfig();
		    }
			break;
		}    
	if (bQuiet)
	{
		
	}
        else if (isPrivate==0)
        {
		Level.Game.BroadcastMessage( Admin.User.Name@"issued"@actionText@"to"@pPRI.PlayerName@"for"@reason );
		PlayerPawn (aPawn).ClientMessage("Admin"@actionText@":"@reason);
		PlayerPawn (aPawn).SetProgressTime (20);
		PlayerPawn (aPawn).SetProgressMessage ("Admin"@actionText@":"@reason, 0);
		WarnedList.LogWarning("time,"@AbsoluteTime@"admin,"@Admin.User.Name@"player,"@pPRI.PlayerName@"IP,"@GetPlayerIP(PlayerPawn(aPawn))@"action,"@actionText@"reason,"@reason);
		LogServerMessage(Admin.User.Name@actionText@pPRI.PlayerName@"for"@reasoncode@":"@reason);
		Issuer.ClientMessage("You performed "@actionText@"on"@pPRI.PlayerName@"for"@reasoncode@":"@reason);
        }
        else if (isPrivate!=0)
        {
		PlayerPawn (aPawn).SetProgressTime (20);
		PlayerPawn (aPawn).SetProgressMessage ("Admin"@actionText@":"@reason, 0);
		WarnedList.LogWarning("time,"@AbsoluteTime@"admin,"@Admin.User.Name@"player,"@pPRI.PlayerName@"IP,"@GetPlayerIP(PlayerPawn(aPawn))@"private action,"@actionText@"reason,"@reason);
		LogServerMessage(Admin.User.Name@"private"@actionText@pPRI.PlayerName@"for"@reasoncode@":"@reason);
		Issuer.ClientMessage("You performed private"@actionText@"on"@pPRI.PlayerName@"for"@reasoncode@":"@reason);
        }            


	}

	return true;
}

function SendSA_ActionResults(int Warned, int failed)
{
local string msg;

	if ((Warned + failed) != 0)
	{
		msg = "";
		
		if (Warned > 0)
		{
			msg = "You successfully Warned"@Warned@"player";
			if (Warned > 1)
				msg = msg $ "s";
			if (failed > 0)
				msg = msg $ " and ";
		}
		if (failed > 0)
		{
			if (Warned == 0)
				msg = msg $ "You ";
			else
				msg = msg $ "you ";
				
			msg = msg $ "failed to Warn"@failed@"player";
			if (failed > 1)
				msg = msg $ "s";
		}			
	}
	else
		msg = "No players matched you criteria";
		
	Issuer.ClientMessage(msg);
}


// ###############################################
// ## KICK MANAGEMENT
// ###############################################

function string KickById()
{
local Pawn aPawn, NextPawn;
local int i, kicked, failed;

	if (NumParams < 1)
	{
		Issuer.ClientMessage("You must provide at least one ID to kick");
		return "";
	}

	for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
	{
		NextPawn = aPawn.NextPawn;
		for (i = 0; i<NumParams; i++)
		{
			if ( aPawn.bIsPlayer
				&& string(aPawn.PlayerReplicationInfo.PlayerID)==Params[i]
				&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
			{
				if (KickByPRI(aPawn, aPawn.PlayerReplicationInfo))
					kicked++;
				else
					failed++;
				break;
			}
		}
	}
	SendKickResults(kicked, failed);
	return "";	
}

function string KickWild()
{
local Pawn aPawn, NextPawn;
local int i, kicked, failed;

	if (NumParams < 1)
	{
		Issuer.ClientMessage("You must provide at least one ID to kick");
		return "";
	}

	for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
	{
		NextPawn = aPawn.NextPawn;
		for (i = 0; i<NumParams; i++)
		{
			if ( aPawn.bIsPlayer
				&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i])
				&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
			{
				if (KickByPRI(aPawn, aPawn.PlayerReplicationInfo))
					kicked++;
				else
					failed++;
				break;
			}
		}
	}
	SendKickResults(kicked, failed);
	return "";	
}

function bool KickByPRI(Pawn aPawn, PlayerReplicationInfo pPRI)
{
local int logid;

	if (!pPRI.bIsABot)
	{
		// Before kicking the player, make sure he's not a logged admin
		logid = FindLoggedByPRI(pPRI);
		if (logid != -1)
		{
			if (CanManageUsers())
				Unlog(logid);
			else
			{
				TellIssuer(pPRI.PlayerName@"is a currently logged admin and cannot be kicked");
				return false;
			}
		}
		LogServerMessage(Admin.User.Name@"has kicked"@pPRI.PlayerName);
		Issuer.ClientMessage("You just kicked"@pPRI.PlayerName);
		Level.Game.BroadcastMessage(pPRI.PlayerName@"was kicked by the administrator.");
	}
	aPawn.Destroy();
	return true;
}

function SendKickResults(int kicked, int failed)
{
local string msg;

	if ((kicked + failed) != 0)
	{
		msg = "";
		
		if (kicked > 0)
		{
			msg = "You successfully kicked"@kicked@"player";
			if (kicked > 1)
				msg = msg $ "s";
			if (failed > 0)
				msg = msg $ " and ";
		}
		if (failed > 0)
		{
			if (kicked == 0)
				msg = msg $ "You ";
			else
				msg = msg $ "you ";
				
			msg = msg $ "failed to kick"@failed@"player";
			if (failed > 1)
				msg = msg $ "s";
		}			
	}
	else
		msg = "No players matched you criteria";
		
	Issuer.ClientMessage(msg);
}

// ###############################################
// ## BANNING PLAYERS
// ###############################################

function string Ban()
{
local int logid;
local Pawn aPawn;

	if (NumParams == 0)
		return "@You must give the name of the player to ban";
	
	if (NumParams > 1)
		return "@You cannot ban more than 1 player at a time";
		
	for (aPawn = Level.PawnList; aPawn != None; aPawn = aPawn.NextPawn)
		if (PlayerPawn(aPawn) != None && NetConnection(PlayerPawn(aPawn).Player) != None
			&& aPawn.PlayerReplicationInfo != None && WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[0]))
				break; 				
				
	if (aPawn == None)
		return "@Player name to ban was not found!";
		
	logid = FindLoggedByPRI(aPawn.PlayerReplicationInfo);
	if (((logid != -1 ) && !IsMasterAdmin()) || PlayerPawn(aPawn).bAdmin)
		return "Cannot Ban a logged administrator";
		
	BanByName(aPawn.PlayerReplicationInfo.PlayerName);
	Level.Game.BroadcastMessage(aPawn.PlayerReplicationInfo.PlayerName@"was banned by the administrator.");
	return "Player should have been successfully banned";
}

function string BanId()
{
local int logid, ParamId;
local Pawn aPawn;
local string msg; 

	if (NumParams == 0)
		return "@You must give the ID of the player to ban";
	
	if (NumParams > 1)
		return "@You cannot ban more than 1 player at a time";
	
	if (!IsInteger(Params[0]))
		return "@You have to provide a valid number for the player ID";
	
	ParamId = int(Params[0]);
	
	for (aPawn = Level.PawnList; aPawn != None; aPawn = aPawn.NextPawn)
		if (PlayerPawn(aPawn) != None && NetConnection(PlayerPawn(aPawn).Player) != None
			&& aPawn.PlayerReplicationInfo != None && aPawn.PlayerReplicationInfo.PlayerID == ParamId)
				break; 				
				
	if (aPawn == None)
		return "@The PlayerID you gave didnt match any current players!";
		
	logid = FindLoggedByPRI(aPawn.PlayerReplicationInfo);
	if (((logid != -1 ) && !IsMasterAdmin()) || PlayerPawn(aPawn).bAdmin)
		return "Cannot Ban a logged administrator";
	
	msg = "Player"@aPawn.PlayerReplicationInfo.PlayerName@"should have been successfully banned";
	BanByName(aPawn.PlayerReplicationInfo.PlayerName);
	return msg;
}

function string BanIp()
{
local int logid;
local Pawn aPawn;
local string msg, ParamIp; 

	if (NumParams == 0)
		return "@You must give the IP of the player to ban";
	
	if (NumParams > 1)
		return "@You cannot ban more than 1 player at a time";
	
	ParamIp = Params[0];
	
	for (aPawn = Level.PawnList; aPawn != None; aPawn = aPawn.NextPawn)
		if (PlayerPawn(aPawn) != None && NetConnection(PlayerPawn(aPawn).Player) != None
			&& aPawn.PlayerReplicationInfo != None && GetPlayerIP(PlayerPawn(aPawn)) == ParamIp)
				break; 				
				
	if (aPawn == None)
		return "@The Player IP you gave didnt match any current players!";
		
	logid = FindLoggedByPRI(aPawn.PlayerReplicationInfo);
	if (((logid != -1 ) && !IsMasterAdmin()) || PlayerPawn(aPawn).bAdmin)
		return "Cannot Ban a logged administrator";
	
	msg = "Player"@aPawn.PlayerReplicationInfo.PlayerName@"should have been successfully banned";
	BanByName(aPawn.PlayerReplicationInfo.PlayerName);
	return msg;
}

function BanByName(string s)
{
local bool bOldAdmin;

	bOldAdmin = Issuer.bAdmin;
	Issuer.bAdmin = true;
	Issuer.KickBan(s);
	Issuer.bAdmin = bOldAdmin;
}

// ###############################################
// ## MAPS CHANGING
// ###############################################

function string NextMap()
{
local DeathMatchPlus DMP;
local string NextMap;
local MapList myList;

	DMP = DeathMatchPlus(Level.Game);
	if (!DMP.bAlreadyChanged)
	{
		myList = spawn(DMP.MapListType);
		NextMap = myList.GetNextMap();
		myList.Destroy();
		if ( NextMap == "" )
			NextMap = DMP.GetMapName(DMP.MapPrefix, NextMap,1);

		if ( NextMap != "" )
		{
			Level.ServerTravel(NextMap, false);
			return "";
		}
	}
	
	Level.ServerTravel("?Restart" , false);
	return "";
}

function string GetNextMap(MapList lst, string CurrentMap)
{
local int i, MapNum;

	if ( CurrentMap != "" )
	{
		if ( Right(CurrentMap,4) ~= ".unr" )
			CurrentMap = CurrentMap;
		else
			CurrentMap = CurrentMap$".unr";

		for ( i=0; i<ArrayCount(lst.Maps); i++ )
		{
			if ( CurrentMap ~= lst.Maps[i] )
			{
				MapNum = i;
				break;
			}
		}
	}
	
	// search vs. w/ or w/out .unr extension

	MapNum++;
	if ( MapNum > ArrayCount(lst.Maps) - 1 )
		MapNum = 0;
	if ( lst.Maps[MapNum] == "" )
		MapNum = 0;
	
	return lst.Maps[MapNum];
}

function NextMaps()
{
local DeathMatchPlus DMP;
local string NextMap1, NextMap2, NextMap3;
local MapList myList;
local int MapNum, NumMaps;

	DMP = DeathMatchPlus(Level.Game);
	myList = spawn(DMP.MapListType);
	MapNum = myList.MapNum;
	NextMap1 = myList.GetNextMap();
	NextMap2 = GetNextMap(myList, NextMap1);
	NextMap3 = GetNextMap(myList, NextMap2);
	myList.MapNum = MapNum;
	myList.SaveConfig();
	myList.Destroy();

	if (NextMap1 == "")
	{
		Issuer.ClientMessage("The Map List Is Not Well Configured");
		return;
	}
	
	NumMaps = 1;
	if (NextMap2 != NextMap1 && NextMap2 != "") NumMaps++;
	If (NextMap3 != NextMap2 && NextMap3 != "") NumMaps++;

	MapNum = 2;
	Issuer.ClientMessage("Next"@NumMaps@"Maps:");
	Issuer.ClientMessage("1)"@NextMap1);
	if (NextMap2 != NextMap1 && NextMap2 != "")
	{
		Issuer.ClientMessage(string(MapNum)$")"@NextMap2);
		MapNum++;
	}
	if (NextMap3 != NextMap2 && NextMap3 != "")
		Issuer.ClientMessage(string(MapNum)$")"@NextMap3);
}

function string GotoMap()
{
local DeathMatchPlus DMP;

	if (NumParams == 0)
		return "@Invalid: You must provide a map name";

	if (NumParams != 1)
		return "@Invalid: Too many parameters specified";
	
	DMP = DeathMatchPlus(Level.Game);
	if (!DMP.bAlreadyChanged)
		Level.ServerTravel(Params[0] , false);

	return "";
}

function string RestartMap()
{
local DeathMatchPlus DMP;

	DMP = DeathMatchPlus(Level.Game);
	if (!DMP.bAlreadyChanged)
	{
		WriteLog("Restarting map");
		Level.ServerTravel("?restart" , false);
	}

	return "";
}

// ###############################################
// ## BOTS MANAGEMENT
// ###############################################

function string KillBots()
{
local Pawn aPawn, NextPawn;

	OldMinPlayers=DeathMatchPlus(Level.Game).MinPlayers;
	DeathMatchPlus(Level.Game).MinPlayers = 0;
	for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
	{
		NextPawn = aPawn.NextPawn;
		if ( aPawn.IsA('Bot'))
		{
			aPawn.Destroy();
		}
			
	}
	return "";
}

function string DelBot()
{
local int i, maxbots;
local DeathMatchPlus DMP;

	DMP = DeathMatchPlus(Level.Game);

	if (NumParams == 0)
	{
		if (DMP.MinPlayers < 1)
			return "Min Setting Reached: "@DMP.MinPlayers;
			
		// Just delete any bot
		DMP.MinPlayers--;
		return "@New Minimum number of players:"@DMP.MinPlayers@". A bot should leave soon";
	}
	else if (NumParams == 1 && IsInteger(Params[0]))
	{
		DelNumBots(int(Params[0]));
		return "@New Minimum number of players:"@DMP.MinPlayers@". Some bots should leave soon";
	}
	else
	{
		//@@TODO: Delete named bots
	}
}

function int DelNumBots(int num)
{
local DeathMatchPlus DMP;

	DMP = DeathMatchPlus(Level.Game);
	
	if ((DMP.MinPlayers - num) < 1)
		DMP.MinPlayers = 0;
	else
		DMP.MinPlayers -= num;
    
	return DMP.MinPlayers;
}

function string AddBot()
{
local int i, maxbots;
local DeathMatchPlus DMP;

	DMP = DeathMatchPlus(Level.Game);
	if (NumParams == 0)
	{
		// Just add a bot
		DMP.ForceAddBot();
	}
	else if (NumParams == 1 && IsInteger(Params[0]))
	{
		i = int(Params[0]);
		maxbots = 32 - (DMP.NumPlayers + DMP.NumBots);
		i = Clamp(i, 0, maxbots); 
		if (i == 0)
			return "@No Bots were added";
			
		maxbots = i;
		for (i = 0; i<maxbots; i++)
			DMP.ForceAddBot();
	}
	else
	{
		for (i = 0; i<NumParams; i++)
		{
			if ( DeathMatchPlus(Level.Game) != None )	
				DeathMatchPlus(Level.Game).BotConfig.DesiredName = Params[i];
				
			Level.Game.ForceAddBot();
		}	
	}
}

// ###############################################
// ## GAME MANAGEMENT
// ###############################################

// Game Type Selection
// mutate game edit [gametype]
function string GameStartEdit()
{
local int idx;
local string GameToEdit, ErrMsg;

	if (bEditingGame)		return "@Already editing a game type";
	if (NumParams != 1 && NumParams != 2)
		return "@Invalid number of parameters";
	
	if (NumParams == 1)
		idx = FindGameEditTypeByClass(Level.Game.Class);
	else
		idx = FindGameEditType(Params[1]);
		
	if (idx == -1)
		return "@Invalid game type '"$Params[1]$"'";
	
	Issuer.ClientMessage("Found the game");
	Issuer.ClientMessage("Description is"@GamePlayInfoClass.default.GameDescription);
	
	GamePI = Spawn(GamePlayInfoClass);
	if (GamePI == None)
	{
		GamePlayInfoClass = None;
		return "Unable to spawn GamePlayInfo object";
	}

	ErrMsg = GamePI.InfoInit(self);
	if (ErrMsg != "")
	{
		GamePI.Destroy();
		GamePI = None;
		GamePlayInfoClass = None;
		return ErrMsg;
	}
	bEditingGame = true;
	return "";
}

final function int FindGameEditType(string sinfo)
{
local int i;

	for (i = 0; GameEditClasses[i] != ""; i++)
	{
		if (LoadGameEditClass(GameEditClasses[i]))
		{
//		WriteLog ("pcl:sinfo="$sinfo);
//        WriteLog("pcl:GamePlayInfoClass.default.GameShortName="$GamePlayInfoClass.default.GameShortName);
//        WriteLog("pcl:GamePlayInfoClass.default.GameDescription="$GamePlayInfoClass.default.GameDescription);
//        WriteLog("pcl:string(GamePlayInfoClass.default.MyGameClass)="$string(GamePlayInfoClass.default.MyGameClass));
//        WriteLog("pcl:string(GamePlayInfoClass)="$string(GamePlayInfoClass));
//        WriteLog("");
			if (	   GamePlayInfoClass.default.GameShortName ~= sinfo
					|| GamePlayInfoClass.default.GameDescription ~= sinfo
					|| string(GamePlayInfoClass.default.MyGameClass) ~= sinfo)
				{
        		    WriteLog("pcl: sinfo="$sinfo@"i="$i);
				    return i;
				}
		}
	}
	return -1;
}

final function int FindGameEditTypeByClass(Class<GameInfo> cGame)
{
local int i;

	for (i = 0; GameEditClasses[i] != ""; i++)
	{
		if (LoadGameEditClass(GameEditClasses[i]))
		{
			if (GamePlayInfoClass.default.MyGameClass == cGame)
				return i;
		}
	}
	return -1;
}

final function bool LoadGameEditClass(string sclass)
{
	GamePlayInfoClass = class<GamePlayInfo>(DynamicLoadObject(sclass, class'Class'));
//	WriteLog("pcl: GamePlayInfoClass="$string(GamePlayInfoClass));
	return (GamePlayInfoClass != None);
}

// mutate game start
function string GameStart()
{
local DeathMatchPlus DMP;
local Pawn aPawn;

    if(!Stopped)
        return "Game is not Stopped";
    Stopped=false;
	DMP = DeathMatchPlus(Level.Game);

	for (aPawn = Level.PawnList; aPawn != None; aPawn = aPawn.NextPawn)
	{
    	if (PlayerPawn(aPawn) != None && aPawn.PlayerReplicationInfo != None)	
    	{
        	if (NetConnection(PlayerPawn(aPawn).Player) != None   )
        	{
    
				aPawn.PlayerRestartState = aPawn.Default.PlayerRestartState;
//				DMP.RestartPlayer(aPawn);
//            	aPawn.TakeDamage( 10000, aPawn ,aPawn.Location,vect(0,0,0) , 'admin_pause');
            	
//				aPawn.PlayerReplicationInfo.Score=0;
//				aPawn.PlayerReplicationInfo.Deaths=0;
//				aPawn.GotoState(aPawn.Default.PlayerRestartState);
            }
        }
    }    
    DMP.MinPlayers=OldMinPlayers;
    WriteLog("Numbots="$DMP.NumBots);
    WriteLog("MinPlayers="$DMP.MinPlayers);
    
//	while ( DMP.NeedPlayers() )
//		DMP.AddBot();
//	DMP.bRequireReady = false;
	DMP.RemainingTime = 60 * DMP.TimeLimit;
    DMP.bNetReady=true;
	
//	DMP.StartMatch();
    

}

// ============================================================================
// PickupsRespawn
//  From JailBreak
// Respawns the selected subset of pickups in the map.
// ============================================================================

function PickupsRespawn() 
{
    local Pickup ThisPickup;
    local Weapon ThisWeapon;
    PickupsRespawnHealth=true;
    PickupsRespawnWeapon=true;
    PickupsRespawnAmmo=true;
    PickupsRespawnArmor=true;
    PickupsRespawnPowerup=true;


  if (PickupsRespawnAmmo || PickupsRespawnPowerup || PickupsRespawnHealth || PickupsRespawnHealth)
    foreach AllActors(class'Pickup', ThisPickup)
      if (ThisPickup.IsInState('Sleeping') &&
          ((PickupsRespawnHealth  && (ThisPickup.IsA('Health')             ||
                                      ThisPickup.IsA('TournamentHealth'))) ||
           (PickupsRespawnAmmo    && (ThisPickup.IsA('Ammo')))             ||
           (PickupsRespawnArmor   && (ThisPickup.IsA('Armor')              ||
                                      ThisPickup.IsA('Armor2')             ||
                                      ThisPickup.IsA('Suits')              ||
                                      ThisPickup.IsA('ThighPads')))        ||
           (PickupsRespawnPowerup && (ThisPickup.IsA('Amplifier')          ||
                                      ThisPickup.IsA('UDamage')            ||
                                      ThisPickup.IsA('Invisibility')       ||
                                      ThisPickup.IsA('JumpBoots')          ||
                                      ThisPickup.IsA('UT_JumpBoots')       ||
                                      ThisPickup.IsA('SCUBAGear')          ||
                                      ThisPickup.IsA('UT_Invisibility')    ||
                                      ThisPickup.IsA('UT_ShieldBelt')))))
        ThisPickup.GotoState('Pickup');
  
    foreach AllActors(class'Weapon', ThisWeapon)
      if (ThisWeapon.IsInState('Dropped'))
        ThisWeapon.Destroy();

  if (PickupsRespawnWeapon)
    foreach AllActors(class'Weapon', ThisWeapon)
      if (ThisWeapon.IsInState('Sleeping'))
        ThisWeapon.GotoState('Pickup');
  }

function GetSAS()
{
	foreach AllActors(class 'SemiAdminSpectator',SAS)
	{
		return;
	}    
}

function ClearProgress ()
{
  local DeathMatchPlus DMP;
  local GameReplicationInfo GRI;
  local Pawn p;
  
  DMP = DeathMatchPlus(Level.Game);

  for (p = DMP.level.pawnlist; p != none; p = p.nextpawn) {
    if (p.IsA ('PlayerPawn')) {
      PlayerPawn (p).ClearProgressMessages ();
    }
  }
}

function SetProgress (string s, int index, optional int time)
{
  local DeathMatchPlus DMP;
  local GameReplicationInfo GRI;
  local Pawn p;
  
  DMP = DeathMatchPlus(Level.Game);

  if (time == 0)
    time = 10000;

  for (p = DMP.level.pawnlist; p != none; p = p.nextpawn) {
    if (p.IsA ('PlayerPawn')) {
      PlayerPawn (p).SetProgressTime (time);
      PlayerPawn (p).SetProgressMessage (s, index);
    }
  }
}
// mutate game pause
function string GamePause()
{
    
local DeathMatchPlus DMP;
local GameReplicationInfo GRI;

if (paused) return "Game is already Paused";

    Paused=true;
	DMP = DeathMatchPlus(Level.Game);

    if (SAS!=None)
    {
      GRI=DMP.GameReplicationInfo;
      OldTimeDilation=DMP.Level.TimeDilation;
      DMP.Level.TimeDilation=0;
  
      Level.Pauser=Issuer.PlayerReplicationInfo.PlayerName;
        ClearProgress ();
        SetProgress (Issuer.PlayerReplicationInfo.PlayerName$" has paused the game", 0);
      
   
    }        
}

// mutate game unpause
function string GameUnPause()
{
    
local DeathMatchPlus DMP;
local GameReplicationInfo GRI;

if (! paused) return "Game is not Paused";

    Paused=false;
	DMP = DeathMatchPlus(Level.Game);

    if (SAS!=None)
    {
        GRI=DMP.GameReplicationInfo;
        
        DMP.Level.TimeDilation=OldTimeDilation;        
        DMP.level.pauser = "";
        ClearProgress ();
        SetProgress (Issuer.PlayerReplicationInfo.PlayerName$" has unpaused the game", 0,5);
        Level.Pauser="";
        
		GRI.RemainingMinute = DMP.RemainingTime;
        
        
    }    
}

// mutate game stop
function string GameStop()
{
local DeathMatchPlus DMP;
local TeamGamePlus  TGP;
local int i;
local Pawn aPawn;

	
	DMP = DeathMatchPlus(Level.Game);

    if(Stopped)
        return "Game has not Started or is already Stopped";

    Stopped=true;
    DMP.bRequireReady=true;
    DMP.Countdown=1000;
    DMP.bNetReady=false;
       
	for (aPawn = Level.PawnList; aPawn != None; aPawn = aPawn.NextPawn)
	{
    	if (PlayerPawn(aPawn) != None && aPawn.PlayerReplicationInfo != None)	
    	{
        	if (NetConnection(PlayerPawn(aPawn).Player) != None   )
        	{
            	aPawn.PlayerRestartState = 'PlayerSpectating';
            	aPawn.TakeDamage( 10000, aPawn ,aPawn.Location,vect(0,0,0) , 'admin_stop');
            	
//				aPawn.GotoState(aPawn.PlayerRestartState);
				// reset player deaths and frags
				aPawn.PlayerReplicationInfo.Score=0;
				aPawn.PlayerReplicationInfo.Deaths=0;

				aPawn.DieCount=0;
				aPawn.ItemCount=0;
				aPawn.KillCount=0;
				aPawn.SecretCount=0;
				aPawn.Spree=0;

                // reset scores in team games
            	TGP=TeamGamePlus(Level.Game);
            
            	if (TGP!=None)
                	for ( i=1; i<TGP.MaxTeams; i++ )
                	    TGP.Teams[i].Score=0;
				
            	
            	
        	} 
    	}	
    	
    }
    KillBots();
    PickupsRespawn();
    return "";	
}	
		

// mutate game applychanges <bReloadMap>
function string GameApplyChanges()
{
	if (GamePI == None)
		return "You must use 'mutate game edit <gametype>' first";

	if (NumParams > 2)
		return "Invalid number of parameters";
		
	if (!IsBool(Params[1]))
		return "Not a valid parameter '"$Params[1]$"'";
		
	if(!GamePI.ApplyChanges())
		return "Could not apply changes (bug?)";
		
	WriteLog("Game settings have been saved");
	GamePI.Destroy();
	GamePI = None;
	GamePlayInfoClass = None;
	if (IsPartOf(Params[1], "Y|YES|1|TRUE|ON"))
	{
		LogServerMessage("Restarting the map");
		RestartMap();
	}
}

// mutate game changeto <newtype>
function string GameChangeTo()
{
local string mutators, oldurl, newurl;
local class<GameInfo> newgameclass;
local MapList myList;
local DeathMatchPlus DMP;

	// Find the game class of the mentioned game to change to
	if (GamePI != None)
		return "@finish editing game settings before changing game";
		
	DMP = DeathMatchPlus(Level.Game);
	if (DMP.bAlreadyChanged)
		return "@Map already changing";

	if (FindGameEditType(Params[1]) != -1)
	{
		newgameclass = GamePlayInfoClass.default.MyGameClass;
		if (newgameclass == Level.Game.class)
			return "@Already a"@Params[1]@"game";
			
		// Check for new Ini requirement
		// Ok, now, lets check for 
		if (level.game.MapPrefix != newgameclass.default.MapPrefix)
		{
			myList = spawn(newgameclass.default.MapListType);
			newurl = myList.GetNextMap();
			myList.SaveConfig();
			myList.Destroy();
		}
		else
			newurl = GetCurrentMapName();
		newurl = newurl$"?game="$string(newgameclass);
		// Humm mutators
		if (GamePlayInfoClass.default.bSupportsMutators)
		{
			// Handle Mutators
		} 	
		Level.ServerTravel(newurl, false);
		return "@Game changing to"@newurl; 
	}
	return "";
}

function string GetCurrentMapName()
{
local string map, url;
local int p;

	url = Level.GetLocalURL();
	p = Instr(url, "/");
	if (p != -1)
		url = mid(url, p+1);
	p = Instr(url, "?");
	if (p == -1)
		return url;

	return left(url, p);
}

// mutate game set <setting> <value>
function string GameSetCmd()
{
local string value;
local int i;

	if (GamePI == None)
		return "You must use 'mutate game edit <gametype>' first";
		
	if (NumParams != 3)
		return "Invalid number of parameters";
		
	if (!GamePI.Set(Params[1], Params[2]))
		return "Invalid game property";
		
	Issuer.ClientMessage(Params[1]@"="@Params[2]);
}

// mutate game del <setting>
function string GameSetDelCmd()
{
local string value;
local int i;

	if (GamePI == None)
		return "You must use 'mutate game edit <gametype>' first";
		
	if (NumParams != 2)
		return "Invalid number of parameters";
		
	if (!GamePI.Set(Params[1], ""))
		return "Invalid game property";
		
	Issuer.ClientMessage(Params[1]@"=");
}

// mutate game get <*|setting>
function string GameGetCmd()
{
local string value;
local int i;

	if (GamePI == None)
		return "You must use 'mutate game edit <gametype>' first";
		
	if (NumParams != 2)
		return "Invalid number of parameters";
	
	if (Params[1] == "*")
	{
		// List all available parameters
		for (i = 0; i<GamePI.NumSettings; i++)
		{
			GamePI.Get(GamePI.GetSettingName(i), value,false);
			Issuer.ClientMessage(GamePI.GetSettingName(i)@"-"@value);
		}
	}
	else if (!GamePI.Get(Params[1], value,false))
	{
		return "Invalid game property";
		Issuer.ClientMessage(Params[1]@"="@value);
	}
}


// ###############################################
// ## SUMMONING ITEMS
// ###############################################

function string SummonItem()
{
local class<actor> NewClass;
local string ClassName, ObjName;

	if (NumParams != 1)
		return "@Invalid number of parameters";

	ObjName = PopParam();
	ClassName = ObjName;
	
	if( instr(ClassName,".")==-1 )
		ClassName = "Botpack." $ ClassName;

	WriteLog( "Fabricate " $ ClassName );
	NewClass = class<actor>( DynamicLoadObject( ClassName, class'Class' ) );
	if( NewClass==None )
		return "@Invalid object name '"$ObjName$"'";
	
	Issuer.Spawn( NewClass,,,Issuer.Location + 72 * Vector(Issuer.Rotation) + vect(0,0,1) * 15 );
} 


// ###############################################
// ## FULL COMMANDS
// ###############################################

function FullFly()
{
   local Pawn aPawn, NextPawn;
   local int i;
	if (NumParams == 0)
	{
		Issuer.UnderWaterTime = Issuer.Default.UnderWaterTime;
		Issuer.SetCollision(true);
		Issuer.bCollideWorld = true;
		Issuer.GotoState('CheatFlying');
		Issuer.ClientMessage("Now flying.");
	}
	else 
	{
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			for (i = 0; i<NumParams; i++)
			{
				if ( aPawn.IsA('PlayerPawn')
					&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i])
					&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
				{
					aPawn.UnderWaterTime = Issuer.Default.UnderWaterTime;
					aPawn.SetCollision(true);
					aPawn.bCollideWorld = true;
					aPawn.GotoState('CheatFlying');
					Issuer.ClientMessage(aPawn.PlayerReplicationInfo.PlayerName@" is now flying.");
				}
			}
		}
	}
}

function FullWalk()
{
local Pawn aPawn, NextPawn;
local int i;
	if (NumParams == 0)
	{
		Issuer.UnderWaterTime = Issuer.Default.UnderWaterTime;	
		Issuer.SetCollision(true);
		Issuer.SetPhysics(PHYS_Walking);
		Issuer.GotoState('PlayerWalking');
		Issuer.bCollideWorld = true;
		Issuer.ClientReStart();
		Issuer.ClientMessage("Now walking once again.");
	}
	else 
	{
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			for (i = 0; i<NumParams; i++)
			{
				if ( aPawn.IsA('PlayerPawn')
					&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i])
					&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
				{
					aPawn.UnderWaterTime = aPawn.Default.UnderWaterTime;	
					aPawn.SetCollision(true);
					aPawn.SetPhysics(PHYS_Walking);
					aPawn.GotoState('PlayerWalking');
					aPawn.bCollideWorld = true;
					aPawn.ClientReStart();
					Issuer.ClientMessage(aPawn.PlayerReplicationInfo.PlayerName@" is now walking once again.");
				}
			}
		}
	}
}

function FullGhost()
{
local Pawn aPawn, NextPawn;
local int i;
	if (NumParams == 0)
	{
		Issuer.UnderWaterTime = -1.0;	
		Issuer.SetCollision(false, false, false);
		Issuer.bCollideWorld = false;
		Issuer.GotoState('CheatFlying');
		Issuer.ClientMessage("Now ghosting.");
	}
	else 
	{
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			for (i = 0; i<NumParams; i++)
			{
				if ( aPawn.IsA('PlayerPawn')
					&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i])
					&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
				{
					aPawn.UnderWaterTime = -1.0;	
					aPawn.SetCollision(false, false, false);
					aPawn.bCollideWorld = false;
					aPawn.GotoState('CheatFlying');
					Issuer.ClientMessage(aPawn.PlayerReplicationInfo.PlayerName@" is now ghosting.");
				}
			}
		}
	}
}

function FullGod()
{
local Pawn aPawn, NextPawn;
local int i, oot;
//	if (NumParams < 1)
//	{
//		Issuer.ClientMessage("Syntax: mutate god [username...]");
//	}
	
	if (Caps(Params[NumParams-1])=="OFF") oot=0;
	else if (Caps(Params[NumParams-1])=="ON") oot=1;
	else oot=2;
	if (oot!=2) Numparams--;
	if (NumParams == 0)
	{
		if (oot==0)
		{
			Issuer.ReducedDamageType = 'None';
			Issuer.ClientMessage("God Mode off");
		}
		else if (oot==1)
		{
			Issuer.ReducedDamageType = 'All';
			Issuer.ClientMessage("God Mode on");
		}
		else
		{		
			if (Issuer.ReducedDamageType == 'All') 
			{
				Issuer.ReducedDamageType = 'None';
				Issuer.ClientMessage("God Mode off");
			}
			else
			{
				Issuer.ReducedDamageType = 'All';
				Issuer.ClientMessage("God Mode on");
			}
		}
	}

	else 
	{
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			for (i = 0; i<NumParams; i++)
			{
				if ( aPawn.IsA('PlayerPawn')
					&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i])
					&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
				{
					if (((oot==2) && (aPawn.ReducedDamageType == 'All')) || (oot==0))
					{
						aPawn.ReducedDamageType = 'None';
						Issuer.ClientMessage(aPawn.PlayerReplicationInfo.PlayerName@"'s God Mode now off");
					}
					else if (((oot==2) && (aPawn.ReducedDamageType != 'All')) || (oot==1))
					{
						aPawn.ReducedDamageType = 'All';
						Issuer.ClientMessage(aPawn.PlayerReplicationInfo.PlayerName@"'s God Mode now on");
					}
				}
			}
		}
	}
}

function FullHealth()
{
local Pawn aPawn, NextPawn;
local int i;

	if (NumParams < 1)
	{
		Issuer.ClientMessage("Syntax: mutate health [username...] <# of health>");
	}

	else if (NumParams < 2)
	{
		Issuer.Health = Int(Params[NumParams-1]);
		Issuer.ClientMessage("Your Health is now "@Int(Params[NumParams-1]));
	}

	else 
	{
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			for (i = 0; i<(NumParams-1); i++)
			{
				if ( aPawn.IsA('PlayerPawn')
					&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i])
					&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
				{
					aPawn.Health = Int(Params[NumParams-1]);
					Issuer.ClientMessage(aPawn.PlayerReplicationInfo.PlayerName$"'s Health is now"@Int(Params[NumParams-1]));
				}
			}
		}
	}
}

function FullGoto()
{
local Pawn aPawn, NextPawn, bPawn;
local int i;
local bool bBlockTemp;

	if (NumParams == 1)
	{
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			if ( aPawn.IsA('PlayerPawn')
				&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[0])
				&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
			{
				bBlockTemp = Issuer.bBlockPlayers;
				Issuer.bBlockPlayers = false;
				Issuer.SetLocation(aPawn.Location);   //goto that user
				Issuer.bBlockPlayers = bBlockTemp;
				Issuer.ClientMessage("You teleported to"@aPawn.PlayerReplicationInfo.PlayerName);
			}
		}
	}
	else if (NumParams >= 2)
	{
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			if ( aPawn.IsA('PlayerPawn')
				&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[0])
				&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
			{
				for( bPawn=Level.PawnList; bPawn!=None; bPawn=NextPawn )
				{
					for (i = 1; i<NumParams; i++)
					{
						NextPawn = bPawn.NextPawn;
						if ( bPawn.IsA('PlayerPawn')
							&& WildCapsCompare(bPawn.PlayerReplicationInfo.PlayerName, Params[i])
							&& (PlayerPawn(bPawn)==None || NetConnection(PlayerPawn(bPawn).Player)!=None ) )
						{
							bBlockTemp = Issuer.bBlockPlayers;
							bPawn.bBlockPlayers = false;
							bPawn.SetLocation(aPawn.Location);   //have bPawn goto aPawn
							bPawn.bBlockPlayers = bBlockTemp;
							Issuer.ClientMessage(bPawn.PlayerReplicationInfo.PlayerName@"teleported to"@aPawn.PlayerReplicationInfo.PlayerName);
						}
					}
				}
			}
		}
	}
	else
	{
		Issuer.ClientMessage("Syntax: mutate goto <destination user> [participating user...]");
	}
}

function FullGotoXYZ()
{
local Pawn aPawn, NextPawn, bPawn;
local int i;

	if (NumParams == 3)
	{
		Issuer.SetLocation(vect(1,0,0)*float(Params[0])+vect(0,1,0)*float(Params[1])+vect(0,0,1)*float(Params[2]));
		Issuer.ClientMessage("You teleported to ("@float(Params[0])@","@float(Params[1])@","@float(Params[2])@")");
	}
	else if (NumParams >= 4)
	{
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			for (i = 3; i<NumParams; i++)
			{
				if ( aPawn.IsA('PlayerPawn')
					&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i])
					&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
				{
					aPawn.SetLocation(vect(1,0,0)*float(Params[0])+vect(0,1,0)*float(Params[1])+vect(0,0,1)*float(Params[2]));
					Issuer.ClientMessage(aPawn.PlayerReplicationInfo.PlayerName@"teleported to ("@float(Params[0])@","@float(Params[1])@","@float(Params[2])@")");
				}
			}
		}
	}
	else
	{
		Issuer.ClientMessage("Syntax: mutate gotoXYZ <x-coord> <y-coord> <z-coord> [participating user...]");
	}
}

function FullLocation()
{
local Pawn aPawn, NextPawn;
local int i;

	if (NumParams == 0)
	{
		Issuer.ClientMessage(Issuer.Location);
	}
	else if (NumParams >= 1)
	{
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			for (i = 0; i<NumParams; i++)
			{
				if ( aPawn.IsA('PlayerPawn')
					&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i])
					&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
				{
					Issuer.ClientMessage(aPawn.PlayerReplicationInfo.PlayerName@"'s location is "@aPawn.Location);
				}
			}
		}
	}
}

function FullSlap(bool Quiet)
{
local Pawn aPawn, NextPawn;
local int Hardness, i;

	if (NumParams < 1)
	{
		Issuer.ClientMessage("Syntax: mutate slap <username...> [strength]");
	}
	else 
	{
		if (!IsInteger(Params[NumParams-1]))
		{
			Hardness = 1;
		}
		else 
		{
			Hardness = int(Params[NumParams-1]);
			if (Hardness <= 0) 
			{
				Hardness = 1;
			}
			Numparams--;
		}
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			for (i = 0; i<NumParams; i++)
			{
				if ( aPawn.IsA('PlayerPawn')
					&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i])
					&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
				{
					aPawn.SetPhysics(PHYS_Falling);
					aPawn.velocity.z+=(Hardness*(rand(174)+1));
					aPawn.velocity.y+=(Hardness*(rand(501)-250));
					aPawn.velocity.x+=(Hardness*(rand(501)-250));
					if (Quiet) Issuer.ClientMessage("You slapped"@aPawn.PlayerReplicationInfo.PlayerName@"with a strength of"@Hardness);
					else Level.Game.BroadcastMessage(aPawn.PlayerReplicationInfo.PlayerName@"was slapped with a strength of"@Hardness);
				}
			}
		}
	}
}

function FullBoost()
{
local Pawn aPawn, NextPawn;
local int i;

	if (NumParams < 1)
	{
		Issuer.ClientMessage("Syntax: mutate boost [username...] <multiplier>");
	}

	else if (NumParams < 2)
	{
		Issuer.Velocity *= Float(Params[NumParams-1]);
		Issuer.ClientMessage("Your Velocity has been multiplied by"@Float(Params[NumParams-1]));
	}

	else 
	{
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			for (i = 0; i<(NumParams-1); i++)
			{
				if ( aPawn.IsA('PlayerPawn')
					&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i])
					&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
				{
					aPawn.Velocity *= Float(Params[NumParams-1]);
					Issuer.ClientMessage(aPawn.PlayerReplicationInfo.PlayerName@"'s Velocity has been multiplied by"@Float(Params[NumParams-1]));
				}
			}
		}
	}
}

function FullBounce() // mutate bounce [username...]
{
local Pawn aPawn, NextPawn;
local int i;

	if (NumParams < 1)
	{
		Issuer.Velocity.Z *= -1;
		Issuer.ClientMessage("Your Z Velocity has been multiplied by -1");
	}

	else 
	{
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			for (i = 0; i<NumParams; i++)
			{
				if ( aPawn.IsA('PlayerPawn')
					&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i])
					&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
				{
					aPawn.Velocity.Z *= -1;
					Issuer.ClientMessage(aPawn.PlayerReplicationInfo.PlayerName@"'s Z Velocity has been multiplied by -1");
				}
			}
		}
	}
}

function FullVisible()
{
local Pawn aPawn, NextPawn;
local int i, oot;
	
	if (Params[NumParams-1]=="0") oot=0;
	else if (Params[NumParams-1]=="1") oot=1;
	else oot=2;
	if (oot!=2) Numparams--;
	if (NumParams == 0)
	{
		if (((oot==2) && (Issuer.bHidden)) || (oot==0))
		{
			Issuer.bHidden = true;
			Issuer.Visibility = 0;
			Issuer.ClientMessage("You are now invisible");
		}
		else if (((oot==2) && (!Issuer.bHidden)) || (oot==1))
		{
			Issuer.bHidden = false;
			Issuer.Visibility = Issuer.Default.Visibility;
			Issuer.ClientMessage("You are now visible");
		}
	}

	else 
	{
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			for (i = 0; i<NumParams; i++)
			{
				if ( aPawn.IsA('PlayerPawn')
					&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i])
					&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
				{
					if (((oot==2) && (aPawn.ReducedDamageType == 'All')) || (oot==0))
					{
						aPawn.bHidden = true;
						aPawn.Visibility = 0;
						Issuer.ClientMessage(aPawn.PlayerReplicationInfo.PlayerName@"is now invisible");
					}
					else if (((oot==2) && (aPawn.ReducedDamageType != 'All')) || (oot==1))
					{
						aPawn.bHidden = false;
						aPawn.Visibility = aPawn.Default.Visibility;
						Issuer.ClientMessage(aPawn.PlayerReplicationInfo.PlayerName@"is now invisible");
					}
				}
			}
		}
	}
}

function FullName(bool id, bool Quiet)
{
local Pawn aPawn, NextPawn;
local int i;

	if (NumParams < 1)
	{
		Issuer.ClientMessage("Syntax: mutate rename [username...] <newnick>");
	}

	else if (NumParams < 2)
	{
		if (!Quiet) Level.Game.BroadcastMessage(Issuer.PlayerReplicationInfo.PlayerName@"is now known as"@Params[NumParams-1]$".");
		Issuer.PlayerReplicationInfo.PlayerName=Params[NumParams-1];
	}

	else 
	{
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			for (i = 0; i<(NumParams-1); i++)
			{
				if ( aPawn.IsA('PlayerPawn')
					&& ( ( (!id) && ( WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i]) ) ) || ( ( id ) && ( aPawn.PlayerReplicationInfo.PlayerID==int(Params[i]) ) ) )
					&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
				{
					if (!Quiet) Level.Game.BroadcastMessage(aPawn.PlayerReplicationInfo.PlayerName@"is now known as"@Params[NumParams-1]$".");
					aPawn.PlayerReplicationInfo.PlayerName=Params[NumParams-1];
				}
			}
		}
	}
}

function FullTeam()
{
local Pawn aPawn, NextPawn;
local int i, oot, OldTeam;
	
	if (Caps(Params[NumParams-1])=="RED") oot=0;
	else if (Caps(Params[NumParams-1])=="BLUE") oot=1;
	else if (Caps(Params[NumParams-1])=="GREEN") oot=2;
	else if (Caps(Params[NumParams-1])=="GOLD") oot=3;
	else if (Caps(Params[NumParams-1])=="YELLOW") oot=3;
	else oot=5;
	if (oot!=5) Numparams--;
	if (NumParams == 0)
	{
		if (((oot==5) && (Issuer.PlayerReplicationInfo.Team==1)) || (oot==0))
		{
			OldTeam = Issuer.PlayerReplicationInfo.Team;
			Level.Game.ChangeTeam(Issuer, 0);
			if ( Level.Game.bTeamGame && (Issuer.PlayerReplicationInfo.Team != OldTeam) )
				Issuer.Died( None, '', Location );
			else Issuer.ClientMessage("Error switching the team");
		}
		else if (((oot==5) && (Issuer.PlayerReplicationInfo.Team==0)) || (oot==1))
		{
			OldTeam = Issuer.PlayerReplicationInfo.Team;
			Level.Game.ChangeTeam(Issuer, 1);
			if ( Level.Game.bTeamGame && (Issuer.PlayerReplicationInfo.Team != OldTeam) )
				Issuer.Died( None, '', Location );
			else Issuer.ClientMessage("Error switching the team");
		}
		else if (oot==2)
		{
			OldTeam = Issuer.PlayerReplicationInfo.Team;
			Level.Game.ChangeTeam(Issuer, 2);
			if ( Level.Game.bTeamGame && (Issuer.PlayerReplicationInfo.Team != OldTeam) )
				Issuer.Died( None, '', Location );
			else Issuer.ClientMessage("Error switching the team");
		}
		else if (oot==3)
		{
			OldTeam = Issuer.PlayerReplicationInfo.Team;
			Level.Game.ChangeTeam(Issuer, 3);
			if ( Level.Game.bTeamGame && (Issuer.PlayerReplicationInfo.Team != OldTeam) )
				Issuer.Died( None, '', Location );
			else Issuer.ClientMessage("Error switching the team");
		}
		
	}

	else 
	{
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			for (i = 0; i<NumParams; i++)
			{
				if ( aPawn.IsA('PlayerPawn')
					&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i])
					&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
				{
					if (((oot==5) && (aPawn.PlayerReplicationInfo.Team==1)) || (oot==0))
					{
						OldTeam = aPawn.PlayerReplicationInfo.Team;
						Level.Game.ChangeTeam(aPawn, 0);
						if ( Level.Game.bTeamGame && (aPawn.PlayerReplicationInfo.Team != OldTeam) )
							aPawn.Died( None, '', Location );
						else Issuer.ClientMessage("Error switching the team");
					}
					else if (((oot==5) && (aPawn.PlayerReplicationInfo.Team==0)) || (oot==1))
					{
						OldTeam = aPawn.PlayerReplicationInfo.Team;
						Level.Game.ChangeTeam(aPawn, 1);
						if ( Level.Game.bTeamGame && (aPawn.PlayerReplicationInfo.Team != OldTeam) )
							aPawn.Died( None, '', Location );
						else Issuer.ClientMessage("Error switching the team");
					}
					else if (oot==2)
					{
						OldTeam = aPawn.PlayerReplicationInfo.Team;
						Level.Game.ChangeTeam(aPawn, 2);
						if ( Level.Game.bTeamGame && (aPawn.PlayerReplicationInfo.Team != OldTeam) )
							aPawn.Died( None, '', Location );
						else Issuer.ClientMessage("Error switching the team");
					}
					else if (oot==3)
					{
						OldTeam = aPawn.PlayerReplicationInfo.Team;
						Level.Game.ChangeTeam(aPawn, 3);
						if ( Level.Game.bTeamGame && (aPawn.PlayerReplicationInfo.Team != OldTeam) )
							aPawn.Died( None, '', Location );
						else Issuer.ClientMessage("Error switching the team");
					}
				}
			}
		}
	}
}

function FullSpec()
{
   local Pawn aPawn, NextPawn;
   local int i;
	if (NumParams == 0)
	{
		//issuer specs the next player
	}
	else 
	{
		for( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			for (i = 0; i<NumParams; i++)
			{
				if ( aPawn.IsA('PlayerPawn')
					&& ( WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i]) || WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerID, int(Params[i])) )
					&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
				{
					//issuer specs apawn
				}
			}
		}
	}
}

function FullAdmin()
{
	local string Result;
	Result = ConsoleCommand( Mid(MutateString2,6) );
	if( Result!="" )
		Issuer.ClientMessage( Result );
}

function Userlist()
{
local int i, j;
local string msg;

	for (i = 0; i<NumUsers; i++)
	{
		msg = i$")"@Users[i].Name@"-"@Users[i].Group;
		
		for (j = 0; j<NumLogged; j++)
			if (Admins[j].User == Users[i])
			{
				msg = msg@"- [Logged In]"@Admins[j].PRI.PlayerName;
				break;
			}
		Issuer.ClientMessage(msg);
	}
}

function FullExplode(bool Quiet)
{
local Pawn aPawn, NextPawn;
local int i;
	if (NumParams < 1)
	{
		Issuer.Health=-1000;
		Issuer.Died(None, 'AdminSuicide', Issuer.Location);
		if (!Quiet) Level.Game.BroadcastMessage(Issuer.PlayerReplicationInfo.PlayerName@"exploded.");
		
	}
	else
	{
		for ( aPawn=Level.PawnList; aPawn!=None; aPawn=NextPawn )
		{
			NextPawn = aPawn.NextPawn;
			for (i = 0; i<(NumParams); i++)
			{
				if ( aPawn.IsA('PlayerPawn')
					&& WildCapsCompare(aPawn.PlayerReplicationInfo.PlayerName, Params[i])
					&& (PlayerPawn(aPawn)==None || NetConnection(PlayerPawn(aPawn).Player)!=None ) )
				{
					aPawn.Health=-1000;
					aPawn.Died(None, 'AdminSuicide', aPawn.Location);
					if (Quiet) Issuer.ClientMessage("You exploded"@aPawn.PlayerReplicationInfo.PlayerName$".");
					else Level.Game.BroadcastMessage(aPawn.PlayerReplicationInfo.PlayerName@"exploded.");
				}
			}
		}
	}
}

// ###############################################
// ## PRIVILEGES ASSESSMENT
// ###############################################

final function bool CanKickPlayers()
{
	return HasPrivilege("K") || HasPrivilege("B") || CanManageUsers();
}


final function bool CanSA_actionPlayers(SA_Action action)
{
    switch (action)
	{
    	case SA_Action.Warning:
    	    if (CurrentUserSecLevel() < USLWarningIssue || ! HasPrivilege("W")) return false;
    		break;
    		
    	case SA_Action.Respawn:	    
    	    if (CurrentUserSecLevel() < USLWhipRespawn || ! HasPrivilege("Z")) return false;
    		break;
    		
    	case SA_Action.ZeroFrag:
    	    if (CurrentUserSecLevel() < USLWhipZeroFrag || ! HasPrivilege("Z")) return false;
    		break;
    
    	case SA_Action.UnMute:
    	    if (CurrentUserSecLevel() < USLWhipMuteDelete || ! HasPrivilege("Z")) return false;
    		break;
            
    	case SA_Action.Mute:
    	    if (CurrentUserSecLevel() < USLWhipMuteAdd || ! HasPrivilege("Z")) return false;
    		break;

	}
	return  true;
}

final function bool CanBanPlayers()
{
	return HasPrivilege("B");
}

final function bool CanChangeMaps()
{
	return HasPrivilege("M") || HasPrivilege("G") || CanManageUsers();
}

final function bool CanChangeGame()
{
	return HasPrivilege("G") || CanManageUsers();
}

final function bool CanSetLadder()
{
	return HasPrivilege("L") || CanManageUsers();
}

final function bool CanSummonItems()
{
	return HasPrivilege("S") || CanManageUsers();
}

final function bool CanManageBots()
{
	return HasPrivilege("O") || CanManageUsers();
}

final function bool CanDoFull()
{
	return HasPrivilege("F");
}

final function bool CanDoFly()
{
	return HasPrivilege("A") || HasPrivilege("F");
}

final function bool CanDoGoto()
{
	return HasPrivilege("H") || HasPrivilege("F");
}

final function bool CanDoGod()
{
	return HasPrivilege("D") || HasPrivilege("F");
}

final function bool CanDoSlap()
{
	return HasPrivilege("C") || HasPrivilege("F");
}

final function bool CanDoBoost()
{
	return HasPrivilege("E") || HasPrivilege("F");
}

final function bool CanDoVisible()
{
	return HasPrivilege("V") || HasPrivilege("F");
}

final function bool CanDoAdmin()
{
	return HasPrivilege("P") || HasPrivilege("F");
}

function PostBeginPlay() {
 
    Super.PostBeginPlay();

    syslogobj = None;

    if (bUseSyslog)
    {
        foreach Level.AllActors(class'syslog', syslogobj)
	    {
	        if (String(syslogobj.Class) == "SemiAdmin.syslog")
		    break;
	    }
    }

    if (syslogobj != None)
    {
        WriteLog("SemiAdmin "$version$": using syslog",'SemiAdmin');
    }
			
    Level.Game.RegisterMessageMutator(Self);
//  Level.Game.RegisterDamageMutator(Self);
    GetCurrentMutes();
}

function GetCurrentMutes()
{
    local int i;
    CurrentMutes="";
    // initialise the current mutes
    for (i=0; i<128; i++)
    {
        if (Mutes[i]!="")
            CurrentMutes=CurrentMutes$"+"$Mutes[i]$"+";
    }
    
}
function bool MutatorTeamMessage( Actor Sender, Pawn Receiver, PlayerReplicationInfo PRI, coerce string S, name Type, optional bool bBeep )
{
    local bool bIsToLog, breakout;
    local int a,b;
//    WriteLog("pcl: Type="$Type$"  msg="$s$   );
//WriteLog("Sender = "$Sender$" Receiver = "$Receiver$" PRI = "$PRI$" S ="$S$" Type = "$Type$" time ="@Level.TimeSeconds);

//    if (String(Type)=="TeamSay") 
//        bIsToLog=true;
//    else if(Receiver.IsA('SemiAdminSpectator')) 
//        bIsToLog=true;


    If (PlayerMuted(Sender)) 
    {
        if (bLogChat) WriteLog ( Type$" (muted):"@Pawn(Sender).PlayerReplicationInfo.PlayerName@":"@s   );
        return false;
    }

    if (Level.TimeSeconds == antispam[0].Time) bIsToLog=false;
    else bIsToLog=true;

    if (bIsToLog)
    {
        for (a=23;a>=0;a--)
        {
            antispam[a+1].PlayerPRI = antispam[a].PlayerPRI;
            antispam[a+1].Message = antispam[a].Message;
            antispam[a+1].Time = antispam[a].Time;
        }
        antispam[0].PlayerPRI = PRI;
        antispam[0].Message = S;
        antispam[0].Time = Level.TimeSeconds;

        breakout=false;
        for (a=1;a<24;a++)
        {
            if (breakout) break;
            for (b=1;b<24;b++)
            {
                if (breakout) break;
                if ((a!=b) && (antispam[a].PlayerPRI != None) && (antispam[b].PlayerPRI != None) && (antispam[0].PlayerPRI == antispam[a].PlayerPRI) && (antispam[0].PlayerPRI == antispam[b].PlayerPRI) && (antispam[a].Time+5>Level.TimeSeconds) && (antispam[b].Time+5>Level.TimeSeconds) && (antispam[0].Message == antispam[a].Message) && (antispam[0].Message == antispam[b].Message) && (FindLoggedByPRI(PRI) == -1))
                {
                    SA_ActionByPRI(Pawn(Sender), PRI, SA_Action.MUTE, 0, 0);
                    breakout=true;
                    break;
                }
            }
        }
    }

    if (bLogChat && bIsToLog) WriteLog ( Type$":"@Pawn(Sender).PlayerReplicationInfo.PlayerName@":"@s   );

	if ( NextMessageMutator != None )
		return NextMessageMutator.MutatorTeamMessage( Sender, Receiver, PRI, S, Type, bBeep );
	else
		return true;
}

function bool PlayerMuted(Actor Sender)
{
    // see if this player should be muted
    local PlayerPawn PP;
    local string IP, playername;


    PP=PlayerPawn(Sender);
    if (PP!=None)
    {
        //IP="@"$GetPlayerIP(PP)$"@";
        //playername="@"$PP.PlayerReplicationInfo.PlayerName$"@";
        IP=GetPlayerIP(PP);
        playername=PP.PlayerReplicationInfo.PlayerName;

        //WriteLog ("pcl: "$IP$chr(9)$playername$chr(9)$CurrentMutes);
        
        if(InStr(CurrentMutes,"+"$IP$"+") != -1 || InStr(CurrentMutes,"+"$playername$"+") != -1)
        {
            //WriteLog("pcl: muted");
            return true;
        }
    }
    //else
        //WriteLog("pcl: PP is none");
    
    return false;
}
    
function bool MutatorBroadcastMessage( Actor Sender, Pawn Receiver, out coerce string Msg, optional bool bBeep, out optional name Type )
{
    local bool bIsToLog;

    //WriteLog("pcl: Type="$Type$"  msg="$msg   );
    
    if(Receiver.IsA('SemiAdminSpectator')) bIsToLog=true;

    If (PlayerMuted(Sender)) 
    {
        if (bLogChat && bIsToLog) WriteLog ( Type$" (muted):"@msg   );
        return false;
    }
    
    if (bLogChat && bIsToLog) WriteLog ( "Broadcast"@Type$":"@String(Receiver)@":"@msg   );
	if ( NextMessageMutator != None )
		return NextMessageMutator.MutatorBroadcastMessage( Sender, Receiver, Msg, bBeep, Type );
	else
		return true;
}

function bool MutatorBroadcastLocalizedMessage( Actor Sender, Pawn Receiver, out class<LocalMessage> Message, out optional int Switch, out optional PlayerReplicationInfo RelatedPRI_1, out optional PlayerReplicationInfo RelatedPRI_2, out optional Object OptionalObject )
{

	if ( NextMessageMutator != None )
		return NextMessageMutator.MutatorBroadcastLocalizedMessage( Sender, Receiver, Message, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject );
	else
		return true;
}

function WriteLog(string message, optional name package)
{
    if (string(package)~="none") package='SemiAdmin';
    if(syslogobj != None)
		syslogobj.SendSyslog(SLF_LOCAL1, SLS_DEBUG, String(package), message);
	log(message);
        
}

function bool PreventDeath(Pawn Killed, Pawn Killer, name damageType, vector HitLocation)
{
	if (PlayerPawn(Killed).ReducedDamageType == 'All' && damageType!='AdminSuicide') 
	{
		Killed.Health=Killed.Default.Health;

		Killed.UnderWaterTime = Killed.Default.UnderWaterTime;	
		Killed.SetCollision(true);
		Killed.SetPhysics(PHYS_Walking);
		Killed.GotoState('PlayerWalking');
		Killed.bCollideWorld = true;
		Killed.ClientReStart();


		Killed.SetCollision(true, true, true);
		Killed.bHidden = false;
		Killed.Visibility = Killed.Default.Visibility;
		Level.Game.AddDefaultInventory(Killed);
		return true;
	}
	else if ( NextMutator != None )
		return NextMutator.PreventDeath(Killed,Killer, damageType,HitLocation);
	else return false;
}

///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////

   ///    ///  //////////  ///         ////////
   ///    ///  ///         ///         ///    ///
   ///    ///  ///         ///         ///    /// 
   //////////  ////////    ///         ////////
   ///    ///  ///         ///         ///
   ///    ///  ///         ///         ///
   ///    ///  //////////  //////////  ///

///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////

function HelpMap()
{
	HelpMsg("available commands for 'map'");
	HelpMsg("mutate map next");
	HelpMsg("mutate map restart");
	HelpMsg("mutate map <mapname>");
}

function HelpGame()
{
	HelpMsg("available commands for 'game'");
	HelpMsg("mutate game edit [type]");
	HelpMsg("mutate game get [parameter]");
	HelpMsg("mutate game set <parameter> <value>");
	HelpMsg("mutate game applychanges");
	HelpMsg("mutate game changeto");
	HelpMsg("mutate game save [slot]");
	HelpMsg("mutate game load [slot]");
}

defaultproperties
{
     GameEditClasses(0)="SemiAdmin.DeathMatchGamePlayInfo"
     GameEditClasses(1)="SemiAdmin.DarkMatchGamePlayInfo"
     GameEditClasses(2)="SemiAdmin.LMSGamePlay"
     GameEditClasses(3)="SemiAdmin.TeamGamePlayInfo"
     GameEditClasses(4)="SemiAdmin.AssaultGamePlay"
     GameEditClasses(5)="SemiAdmin.CTFGamePlay"
     GameEditClasses(6)="SemiAdmin.DOMGamePlay"
     GameEditClasses(7)="SemiAdmin.TFGamePlay"
     ReasonMessage(0)="Abusive language is not permitted"
     ReasonMessage(1)="Spawn camping is not permitted"
     ReasonMessage(2)="Piston camping is not permitted"
     ReasonMessage(60)="You will be Un-Muted for the next map"
     AbuseMessage(0)="Abuse Message 0"
     bUseSyslog=True
     SA_ActionCodes(0)="Warning"
     SA_ActionCodes(1)="Kick"
     SA_ActionCodes(2)="Ban"
     SA_ActionCodes(3)="Mute"
     SA_ActionCodes(4)="UnMute"
     SA_ActionCodes(5)="Respawn"
     SA_ActionCodes(6)="ZeroFrag"
     USLServerSettings=254
     USLMapListChange=50
     USLMapChange=50
     USLMapNext=10
     USLMapRestart=10
     USLGameTypeChange=50
     USLMutatorsChange=50
     USLGamePause=10
     USLGameStop=10
     USLGameEdit=250
     USLGameApplyChanges=100
     USLWarningIssue=3
     USLWarningClear=3
     USLReasonAdd=3
     USLReasonDelete=10
     USLReasonEdit=3
     USLWhipMuteAdd=2
     USLWhipMuteDelete=2
     USLWhipZeroFrag=2
     USLWhipRespawn=2
     USLServerUnBanIP=5
     USLServerBanIP=5
     USLGameConsoleView=1
     USLGameConsoleSend=5
     USLGameViewSettings=1
     USLGameViewBots=1
     USLGameViewMutators=1
     USLServerMinPlayers=10
     USLServerKick=5
     USLServerWhip=5
     USLServerViewSettings=5
     USLServerViewBans=5
     USLServerRestart=50
     USLServerManageBots=5
     USLAddRemoveBots=10
     bLogChat=True
     Users(0)=(Name="admin",Password="admin",Group="admin")
     Groups(0)=(Name="admin",SecLevel=65535)
     NumUsers=3
     NumGroups=2
}
