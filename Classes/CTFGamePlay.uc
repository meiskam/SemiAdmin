// ====================================================================
//  Class:  SemiAdmin.CTFGamePlay
//  Parent: SemiAdminGames.TeamGamePlayInfo
//
//  <Enter a description here>
// ====================================================================

class CTFGamePlay extends TeamGamePlayInfo;

// NO CONFIGURABLE PARAMETERS

// CTF Does not allow to have anything else than 2 teams.
function bool AllowSettingsName(string sname, int level)
{
	if (sname == "MaxTeams")
		return false;

	return Super.AllowSettingsName(sname, level);
}

defaultproperties
{
     GameShortName="CTF"
     GameDescription="CatchTheFlag"
     MyGameClass=Class'Botpack.CTFGame'
}
