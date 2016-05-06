// ====================================================================
//  Class:  SemiAdminGames.GamePlayInfo
//  Parent: SemiAdmin.PlayInfo
//
//  TODO: Validation for specific parameters
// ====================================================================

class GamePlayInfo extends PlayInfo;

var string              GameShortName;
var string				GameDescription;
var private string		MyClassName;
var Class<GameInfo>		MyGameClass;
var bool				bSupportsMutators;

function string InfoInit(SemiAdminMutator MyOwner)
{
	MyClass = MyGameClass;

	Super.InfoInit(myOwner);
}

function bool BuildSettingsList()
{
	if (!Super.BuildSettingsList()) return false;
	
	GlobalOwner = MyClassName;
	
	AddLocalSetting ("NoMonsters", "bool", 1, "No Monsters");
	AddGlobalSetting("MuteSpectators", "bool", 1, "Mute Spectators");
	AddLocalSetting ("HumansOnly", "bool", 1, "Humans Only");
	AddLocalSetting ("CoopWeaponMode", "bool", 1, "Coop Weapon Mode");
	AddLocalSetting ("ClassicDeathmessages", "bool", 1, "Classic Death Messages");
	AddGlobalSetting("LowGore", "bool", 1, "Low Gore");
	AddGlobalSetting("VeryLowGore", "bool", 1, "Very Low Gore");
	AddGlobalSetting("NoCheating", "bool", 1, "No Cheating");
	AddGlobalSetting("AllowFOV", "bool", 1, "Allow FOV");
	AddGlobalSetting("LocalLog", "bool", 2, "Local ngStats");
	AddGlobalSetting("WorldLog", "bool", 2, "World ngStats");
	AddGlobalSetting("BatchLocal", "bool", 2, "Batch Local");
	AddGlobalSetting("MaxSpectators", "int", 0, "Max Spectators");
	AddGlobalSetting("MaxPlayers", "int", 0, "Max Players");
	AddGlobalSetting("GameSpeed", "float", 0, "Game Speed");
	AddGlobalSetting("GamePassword", "string", 2, "Game Password");
	AddGlobalSetting("AdminPassword", "string", 255, "Admin Password");	// Level 255 is Master Admin only
	
	return !bError;
}

function bool GetSetValue(int index, out string Value, optional bool bReadOnly)
{
    bError=false;
	if (Settings[index].Owner == MyClassName)
	{
//	    log("checking"@Settings[index].Name@"readonly="@bReadOnly);
		switch (Settings[index].Name)
		{
		// Bool
//		case "":				return BoolValue(MyGameClass.default., Value);
		case "NoMonsters":
		    if (USL<10 && ! bReadOnly) return false;
	        MyGameClass.default.bNoMonsters = BoolValue(MyGameClass.default.bNoMonsters, Value); 
		    break;
		case "MuteSpectators":			
		    if (USL<10 && ! bReadOnly) return false;
		    MyGameClass.default.bMuteSpectators = BoolValue(MyGameClass.default.bMuteSpectators, Value); 
		    break;
		case "HumansOnly":				
		    if (USL<10 && ! bReadOnly) return false;
		    MyGameClass.default.bHumansOnly = BoolValue(MyGameClass.default.bHumansOnly, Value); 
		    break;
		case "CoopWeaponMode":			
		    if (USL<10 && ! bReadOnly) return false;
		    MyGameClass.default.bCoopWeaponMode = BoolValue(MyGameClass.default.bCoopWeaponMode, Value); 
		    break;
		case "ClassicDeathmessages":	
		    if (USL<10 && ! bReadOnly) return false;
		    MyGameClass.default.bClassicDeathmessages = BoolValue(MyGameClass.default.bClassicDeathmessages, Value); 
		    break;
		case "LowGore":					
		    if (USL<10 && ! bReadOnly) return false;
		    MyGameClass.default.bLowGore = BoolValue(MyGameClass.default.bLowGore, Value); 
		    break;
		case "VeryLowGore":				
		    if (USL<10 && ! bReadOnly) return false;
		    MyGameClass.default.bVeryLowGore = BoolValue(MyGameClass.default.bVeryLowGore, Value); 
		    break;
		case "NoCheating":				
		    if (USL<10 && ! bReadOnly) return false;
		    MyGameClass.default.bNoCheating = BoolValue(MyGameClass.default.bNoCheating, Value); 
		    break;
		case "AllowFOV":				
		    if (USL<10 && ! bReadOnly) return false;
		    MyGameClass.default.bAllowFOV = BoolValue(MyGameClass.default.bAllowFOV, Value); 
		    break;
		case "LocalLog":				
		    if (USL<50 && ! bReadOnly) return false;
		    MyGameClass.default.bLocalLog = BoolValue(MyGameClass.default.bLocalLog, Value); 
		    break;
		case "WorldLog":				
		    if (USL<50 && ! bReadOnly) return false;
		    MyGameClass.default.bWorldLog = BoolValue(MyGameClass.default.bWorldLog, Value); 
		    break;
		case "BatchLocal":				
		    if (USL<50 && ! bReadOnly) return false;
		    MyGameClass.default.bBatchLocal = BoolValue(MyGameClass.default.bBatchLocal, Value); 
		    break;
		// Int
//		case "":				bValid = IntValue(MyGameClass.default., Value); break;
		case "MaxSpectators":			
		    if (USL<10 && ! bReadOnly) return false;
		    return IntValue(MyGameClass.default.MaxSpectators, Value);
		case "MaxPlayers":				
		    if (USL<10 && ! bReadOnly) return false;
		    return IntValue(MyGameClass.default.MaxPlayers, Value);
		// Floats		
//		case "":				bValid = FloatValue(MyGameClass.default., Value); break;
		case "AutoAim":					
		    if (USL<10 && ! bReadOnly) return false;
		    return FloatValue(MyGameClass.default.AutoAim, Value);
		case "GameSpeed":				
		    if (USL<50 && ! bReadOnly) return false;
		    return FloatValue(MyGameClass.default.GameSpeed, Value);
		// Strings
		case "GamePassword":			
		    if (USL<100 ) return false;
		    return ChangeFromConsole(index, Value);
		case "AdminPassword":			
		    if (USL<250) return false;
		    return ChangeFromConsole(index, Value);
		}
		return !bError;
	}
	return Super.GetSetValue(index, Value,bReadonly);
}

function bool AllowSettingsName(string sname, int level)
{
    
	return true;
}

function bool RequiresReload()
{

}

function bool RequiresNewIni()
{
}

defaultproperties
{
     MyClassName="Engine.GameInfo"
     MyGameClass=Class'Engine.GameInfo'
     bSupportsMutators=True
}
