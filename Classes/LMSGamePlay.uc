// ====================================================================
//  Class:  SemiAdmin.LMSGamePlay
//  Parent: SemiAdminGames.DeathMatchPlayInfo
//
//  <Enter a description here>
// ====================================================================

class LMSGamePlay extends DeathMatchGamePlayInfo;

var private string		MyClassName;

function bool BuildSettingsList()
{
	if (!Super.BuildSettingsList()) return false;
	
	GlobalOwner = MyClassName;
	
	AddGlobalSetting("HighDetailGhosts", "bool", 2, "Detailed Ghosts");
	
	return !bError;
}

function bool GetSetValue(int index, out string Value, optional bool bReadOnly)
{
local class<LastManStanding> MyLocalClass;

	if (Settings[index].Owner == MyClassName)
	{
		MyLocalClass = class<LastManStanding>(MyGameClass);
		switch (Settings[index].Name)
		{
		// Bool
		case "HighDetailGhosts":			
		    if (USL<10 && ! bReadOnly) return false;		
		    MyLocalClass.default.bHighDetailGhosts = BoolValue(MyLocalClass.default.bHighDetailGhosts, Value); break;
		}
		return !bError;
	}
	return Super.GetSetValue(index, Value,bReadonly);
}

defaultproperties
{
     MyClassName="Botpack.LastManStanding"
     GameShortName="LMS"
     GameDescription="LastManStanding"
     MyGameClass=Class'Botpack.LastManStanding'
}
