// ====================================================================
//  Class:  SemiAdmin.DeathMatchGamePlayInfo
//  Parent: SemiAdminGames.TournamentGamePlayInfo
//
//  <Enter a description here>
// ====================================================================

class DeathMatchGamePlayInfo extends TournamentGamePlayInfo;

var private string		MyClassName;

function bool BuildSettingsList()
{
	if (!Super.BuildSettingsList()) return false;
	
	GlobalOwner = "Botpack.DeathMatchPlus";
	
	AddGlobalSetting("MinPlayers", "int", 1, "Minimum Players");		// bots fill in to guarantee this level in net game
	AddLocalSetting ("FragLimit", "int", 1, "Frag Limit"); 
	AddLocalSetting ("TimeLimit", "int", 1, "Time Limit"); // time limit in minutes
	AddGlobalSetting("ChangeLevels", "bool", 2, "Auto-Advance Maps");
	AddGlobalSetting("HardCoreMode", "bool", 1, "Hardcore Mode");
	AddGlobalSetting("MegaSpeed", "bool", 1, "Mega Speed");
	AddGlobalSetting("AltScoring", "bool", 2, "Alternate Scoring");
	AddLocalSetting ("MultiWeaponStay", "bool", 1, "MultiWeapon Stay");
	AddLocalSetting ("ForceRespawn", "bool", 0, "Force Respawn");
	AddGlobalSetting("Tournament", "bool", 0, "Tournament Mode");
	AddGlobalSetting("NetWait", "int", 2, "Start of Game Delay"); // time to wait for players in netgames w/ bNetReady (typically team games)
	AddGlobalSetting("RestartWait", "int", 2, "Restart Delay");
	AddLocalSetting ("UseTranslocator", "bool", 1, "Enable Translocator");
	
	return !bError;
}

function bool GetSetValue(int index, out string Value, optional bool bReadOnly)
{
local class<DeathMatchPlus> MyLocalClass;

	if (Settings[index].Owner == MyClassName)
	{
		MyLocalClass = class<DeathMatchPlus>(MyGameClass);
		switch (Settings[index].Name)
		{
		// Bool
		case "ChangeLevels":	
		    if (USL<50 && ! bReadOnly) return false;		
		    MyLocalClass.default.bChangeLevels = BoolValue(MyLocalClass.default.bChangeLevels, Value); break;
		case "HardCoreMode":			
		    if (USL<10 && ! bReadOnly) return false;		
		    MyLocalClass.default.bHardCoreMode = BoolValue(MyLocalClass.default.bHardCoreMode, Value); break;
		case "MegaSpeed":				
		    if (USL<10 && ! bReadOnly) return false;		
		    MyLocalClass.default.bMegaSpeed = BoolValue(MyLocalClass.default.bMegaSpeed, Value); break;
		case "AltScoring":				
		    if (USL<10 && ! bReadOnly) return false;		
		    MyLocalClass.default.bAltScoring = BoolValue(MyLocalClass.default.bAltScoring, Value); break;
		case "MultiWeaponStay":			
		    if (USL<10 && ! bReadOnly) return false;		
		    MyLocalClass.default.bMultiWeaponStay = BoolValue(MyLocalClass.default.bMultiWeaponStay, Value); break;
		case "ForceRespawn":			
		    if (USL<10 && ! bReadOnly) return false;		
		    MyLocalClass.default.bForceRespawn = BoolValue(MyLocalClass.default.bForceRespawn, Value); break;
		case "Tournament":				
		    if (USL<10 && ! bReadOnly) return false;		
		    MyLocalClass.default.bTournament = BoolValue(MyLocalClass.default.bTournament, Value); break;
		case "UseTranslocator":			
		    if (USL<10 && ! bReadOnly) return false;		
		    MyLocalClass.default.bUseTranslocator = BoolValue(MyLocalClass.default.bUseTranslocator, Value); break;
		// Int
		case "MinPlayers":				
		    if (USL<10 && ! bReadOnly) return false;		
		    return IntValue(MyLocalClass.default.MinPlayers, Value);
		case "FragLimit":				
		    if (USL<10 && ! bReadOnly) return false;		
		    return IntValue(MyLocalClass.default.FragLimit, Value);
		case "TimeLimit":				
		    if (USL<10 && ! bReadOnly) return false;		
		    return IntValue(MyLocalClass.default.TimeLimit, Value);
		case "NetWait":					
		    if (USL<10 && ! bReadOnly) return false;		
		    return IntValue(MyLocalClass.default.NetWait, Value);
		case "RestartWait":				
		    if (USL<10 && ! bReadOnly) return false;		
		    return IntValue(MyLocalClass.default.RestartWait, Value);
		// Floats		
		case "AirControl":				
		    if (USL<10 && ! bReadOnly) return false;		
		    return FloatValue(MyLocalClass.default.AirControl, Value);
		}
		return !bError;
	}
	return Super.GetSetValue(index, Value,bReadonly);
}

defaultproperties
{
     MyClassName="Botpack.DeathMatchPlus"
     GameShortName="DMP"
     GameDescription="DeathMatchPlus"
     MyGameClass=Class'Botpack.DeathMatchPlus'
     bCanModify=True
}
