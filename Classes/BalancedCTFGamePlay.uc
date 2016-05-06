// ====================================================================
//  Class:  SemiAdmin.BalancedCTFGamePlay
//  Parent: SemiAdminGames.TeamGamePlayInfo
//
//  <Enter a description here>
// ====================================================================

class BalancedCTFGamePlay extends TeamGamePlayInfo;

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
     GameShortName="B-CTF"
     GameDescription="BalancedCaptureTheFlag"
     MyGameClass=None
}
