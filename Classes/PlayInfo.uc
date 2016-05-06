// ====================================================================
//  Class:  SemiAdmin.PlayInfo
//  Parent: Engine.Info
//
//  <Enter a description here>
// ====================================================================

class PlayInfo extends Info;

// Our only configurable parameter
var config	string DefaultServerIniFile;

struct SASetting
{
	var string	Name;
	var string	Type;
	var string	Owner;
	var string  DisplayName;
	var bool	bGlobal;
	var int		Level;
};

// Globals
var SASetting	Settings[100];
//var string  CommandsNames[100];
//var name	CommandsOwner[100];
var int		NumSettings, NumCommands;
var bool	bError;
var bool	bSetting;			// set to false for reading parameter, true to set the parameter
var bool	bStoring;			// When setting, decides if the value will be stored in an array or set directly 
var string  sErrorMsg;
var bool    bCanModify;			// Can this class be modified directly ?
var bool	bRequireRestart;	// Does the server need to be restarted when this is edited ?
var string  GlobalOwner;

var SemiAdminMutator	SAM;	// The Mutator to give feedback to
var int                 USL;    // SAM.CurrentUserSecLevel()
var Class				MyClass;

// Overridables. Will probably add more.
function bool BuildSettingsList()   { bError = false; return true; }
function bool AllowSettingsName(string sname, int level) 
{
    
    return true; 
}
function bool GetSetValue(int index, out string Value, optional bool bReadOnly) { return false; }

function string InfoInit(SemiAdminMutator MyOwner)
{
	SAM = MyOwner;
	USL = SAM.CurrentUserSecLevel();
	
//	Log("MyClass:"@MyClass);
	if (!bCanModify)
		return "Error, cannot modify this game type directly";
	
	BuildSettingsList();
	if (bError)
		return "Too many settings for this game type, you will need to request an upgraged version of SemiAdmin";
		
//	BuildCommandsList();
//	if (bError)
//		return "Too many Commands for this game type, you will need to request an upgraded version of SemiAdmin";

	return "";
}

final function AddLocalSetting(string sname, string stype, int level, string sdname)
{
	AddSetting(sname, stype, level, sdname, false);
} 

final function AddGlobalSetting(string sname, string stype, int level, string sdname)
{
	AddSetting(sname, stype, level, sdname, true);
}

final function AddSetting(string sname, string stype, int level, string sdname, bool bGlobal)
{
	if (HasAccessLevel(level) && AllowSettingsName(sname, level))
	{
		if (NumSettings > 99)
		{
			bError = true;
			return;
		}

		Settings[NumSettings].Name = sname;
		Settings[NumSettings].Type = stype;
		Settings[NumSettings].bGlobal = bGlobal;
		Settings[NumSettings].DisplayName = sdname;
		Settings[NumSettings].Owner = GlobalOwner;
		Settings[NumSettings].Level = level; 
		NumSettings++;
	}
	return;
}

final function bool HasAccessLevel(int level)
{
	// Allow only settings the user level would allow.
	return SAM.CurrentUserGameLevel() >= level;
}

final function bool Set(string Setting, string value)
{
local int index;

	bSetting = true;
	index = GetSettingIndex(Setting);
	if (index == -1)
		return false;
	
	return GetSetValue(index, value);
}

final function bool ApplyChanges()
{
	MyClass.static.StaticSaveConfig();
	return true;
}

final function bool Get(string Setting, out string value, bool bReadOnly)
{
local int index;

	bSetting = false;
	index = GetSettingIndex(Setting);
	if (index == -1)
	{
		Log("Property not found");
		return false;
	}
//	log("Get::Checking"@setting@"breadonly="$bReadOnly);	
	return GetSetValue(index, value, bReadOnly);
}

final function string GetSettingName(int index)
{
	if (index > -1 && index < NumSettings)
		return Settings[index].Name;
		
	return "";
}

final function string GetSettingDisplayName(int index)
{
	if (index > -1 && index < NumSettings)
		return Settings[index].DisplayName;
		
	return "";
}

final function string GetSettingType(int index)
{
	if (index > -1 && index < NumSettings)
		return Settings[index].Type;
		
	return "";
}

final function int GetSettingIndex(string Setting)
{
local int i, index;

	index = -1;
	for (i = 0; i<NumSettings; i++)
	{
		if (Settings[i].Name ~= Setting)
		{
			index = i;
			break;
		}
	}
	return index;
}

final function bool ChangeFromConsole(int index, out string value)
{
	if (bSetting)
		SAM.Issuer.ConsoleCommand("set"@Settings[index].Owner@Settings[index].Name@value);
	else if (bStoring)
		;	// What to store in ?
	else
		value = SAM.Issuer.ConsoleCommand("get"@Settings[index].Owner@Settings[index].Name);
	
	return true;
}

final function bool BoolValue(bool bField, out string value)
{
	bError = false;
	if (bSetting)
	{
		if (IsPartOf(Caps(Value), "Y|YES|1|TRUE|ON"))
			bField = true;
		else if (IsPartOf(Caps(Value), "N|NO|0|FALSE|OFF"))
			bField = false;
		else
		{
			bError = true;
			return bField;
		}
	}
	else if (bStoring)
		;	// Dont know yet where to store
	else
		value = string(bField);

	return bField;
}

final function bool IntValue(out int iField, out string value)
{
local int iNewValue;

	if (bSetting)
	{
		if (!SAM.IsInteger(value))
			return false;

		iNewValue = int(value);
	
		// Todo: Integrate with a Command stack that gets executed only at the end 
		if (iNewValue != iField)
			iField = iNewValue;
	}
	else if (bStoring)
		;
	else
		value = string(iField);
		
	return true;
}

final function bool FloatValue(out float fField, out string value)
{
local float fNewValue;

	if (bSetting)
	{
		if (!SAM.IsFloat(value))
			return false;
		
		fNewValue = float(value);

		if (fNewValue != fField)
			fField = fNewValue;
	}
	else if (bStoring)
		;
	else
		value = string(fField);
		
	return true;
}

final function bool StringValue(out string sField, out string value)
{
	if (bSetting)
	{
		if (value != sField)
			sField = value;
	}
	else if (bStoring)
		;
	else
		value = sField;
		
	return true;
}

final function bool IsPartOf(string part, string src)
{
	return Instr("|"$src$"|", "|"$part$"|") != -1;
}

defaultproperties
{
}
