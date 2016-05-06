// ====================================================================
//  Class:  SemiAdminGames.TeamGamePlayInfo
//  Parent: SemiAdminGames.DeathMatchGamePlayInfo
//
//  <Enter a description here>
// ====================================================================

class TeamGamePlayInfo extends DeathMatchGamePlayInfo;

var private string		MyClassName;

function bool BuildSettingsList()
{
	if (!Super.BuildSettingsList()) return false;
	
	GlobalOwner = MyClassName;
	
	AddLocalSetting("NoTeamChanges", "bool", 2, "Disallow Team Change");
	AddGlobalSetting("BalanceTeams", "bool", 0, "Bots Balance Teams");	// bots balance teams
	AddGlobalSetting("PlayersBalanceTeams", "bool", 0, "Players Balance Teams");	// players balance teams
	AddLocalSetting("FriendlyFireScale", "float", 2, "Friendly Fire Scale"); //scale friendly fire damage by this value
	AddLocalSetting("MaxTeams", "int", 1, "Maximum Number of Teams"); //Maximum number of teams allowed in (up to MaxAllowedTeams)
	AddLocalSetting("GoalTeamScore", "float", 1, "Team Score Limit"); //like fraglimit
	AddLocalSetting("MaxTeamSize", "int", 1, "Maximum Team Size");

	return !bError;
}

function bool GetSetValue(int index, out string Value, optional bool bReadOnly)
{
local class<TeamGamePlus> MyLocalClass;

	MyLocalClass = class<TeamGamePlus>(MyGameClass);

	if (Settings[index].Owner == MyClassName)
	{
		switch (Settings[index].Name)
		{
		// Bool
		case "NoTeamChanges":			
		    if (USL<10 && ! bReadOnly) return false;		
		    MyLocalClass.default.bNoTeamChanges = BoolValue(MyLocalClass.default.bNoTeamChanges, Value); break;
		case "BalanceTeams":			
		    if (USL<10 && ! bReadOnly) return false;		
		    MyLocalClass.default.bBalanceTeams = BoolValue(MyLocalClass.default.bBalanceTeams, Value); break;
		case "PlayersBalanceTeams":		
		    if (USL<10 && ! bReadOnly) return false;		
		    MyLocalClass.default.bPlayersBalanceTeams = BoolValue(MyLocalClass.default.bPlayersBalanceTeams, Value); break;
		// Int
		case "MaxTeams":				
		    if (USL<10 && ! bReadOnly) return false;		
		    return IntValue(MyLocalClass.default.MaxTeams, Value);
		case "MaxTeamSize":				
		    if (USL<10 && ! bReadOnly) return false;		
		    return IntValue(MyLocalClass.default.MaxTeamSize, Value);
		// Floats		
		case "FriendlyFireScale":		
		    if (USL<10 && ! bReadOnly) return false;		
		    return FloatValue(MyLocalClass.default.FriendlyFireScale, Value);
		case "GoalTeamScore":			
		    if (USL<10 && ! bReadOnly) return false;		
		    return FloatValue(MyLocalClass.default.GoalTeamScore, Value);
		}
		return !bError;
	}
	return Super.GetSetValue(index, Value,bReadonly);
}

function bool AllowSettingsName(string sname, int level)
{
	if (sname == "FragLimit")
		return false;

	return Super.AllowSettingsName(sname, level);
}

defaultproperties
{
     MyClassName="Botpack.TeamGamePlus"
     GameShortName="TDM"
     GameDescription="TeamDeathMatch"
     MyGameClass=Class'Botpack.TeamGamePlus'
}
