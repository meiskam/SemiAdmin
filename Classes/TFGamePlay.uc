// ====================================================================
//  Class:  SemiAdmin.TrueFragsCTFGamePlay
//  Parent: SemiAdminGames.TeamGamePlayInfo
//
//  <Enter a description here>
// ====================================================================

class TFGamePlay extends TeamGamePlayInfo;

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
     GameShortName="TFCTF"
     GameDescription="True Frags CTF"
     MyGameClass=None
}
