class ServerSemiAdmin expands WebApplication config;

var() class<SemiAdminSpectator> SpectatorType;
var SemiAdminSpectator Spectator;
var SemiAdminMutator SAM;

var	ListItem GameTypeList;

var ListItem IncludeMutators;
var ListItem ExcludeMutators;
var ListItem CurrentBotListItem;
var ListItem FullBotListItem;

var ListItem IncludePrivileges;
var ListItem ExcludePrivileges;

var config string SubPath;

var config string RootPage;
var config string RootMenuPage;
var config string RootGamePage;
var config string RootUsersPage;
var config string RootServerPage;

//Game settings
var config string GameDefPage;
var config string GameMenuPage;
var config string GameIndexPage;
var config string GamePageLev;
var config string GameBotPage;
var config string GamePlayerKickPage;
var config string GamePlayerBanPage;
var config string GamePlayerWhipPage;
var config string GameMutatorPage;
var config string GameMapPage;
var config string GameConsolePage;
var config string GameConsoleLogPage;
var config string GameConsoleSendPage;
var config string MapListPage;
//var config string DefaultSendText;

var config string ServerDefPage;
var config string ServerSettingsPage;
var config string WarningsPage;
var config string ServerMutesPage;
var config string ActivityPage;
var config string ServerReasonsPage;
var config string ServerBansPage;
var config string UsersDefPage;
var config string UsersMenuPage;
var config string UsersAddPage;
var config string UsersEditPage;
var config string UsersBrowsePage;
var config string GroupsAddPage;
var config string GroupsEditPage;
var config string GroupsBrowsePage;
var config string NameSearchPage;

var config string ServerMenuPage;
var config string ServerRestartPage;
var config string HelpPage;
var config string CLHelpPage;
var config string QRGPage;
var config string MessageUHTM;
var config string DefaultBG;
var config string HighlightedBG;

var config string AdminRealm;
var config string ImageDir;

var string colors[4];

var string LastError;
var bool bError;

event Init()
{
	Super.Init();

	if (SpectatorType != None)
		Spectator = Level.Spawn(SpectatorType);
	else
		Spectator = Level.Spawn(class'SemiAdminSpectator');

	// won't change as long as the server is up

	LoadGameTypes();
	LoadBotsList();
	LoadMutators();

}

function string GetGamePlayInfo(string sGameType, out GamePlayInfo MyGamePI)
{
local int 				idx;

	idx = SAM.FindGameEditType(sGameType);

	if (idx == -1)
		return "<tr><td colspan=2>The settings for game type '"$sGameType$"' cannot be set with SemiAdmin</td></tr>";

	MyGamePI = Spectator.Spawn(SAM.GamePlayInfoClass);
	if (MyGamePI == None)
	{
		return "<tr><td colspan=2>Error saving the settings</td></tr>";
	}

	return MyGamePI.InfoInit(SAM);
}

function string GetSetServerInfo(WebRequest Request)
{
    local String sRet, ServerName, AdminName, AdminEmail, MOTDLine1, MOTDLine2, MOTDLine3, MOTDLine4;
    local int GAL,USL;
	
		USL = SAM.CurrentUserSecLevel();
	
	ServerName = class'Engine.GameReplicationInfo'.default.ServerName;
	AdminName = class'Engine.GameReplicationInfo'.default.AdminName;
	AdminEmail = class'Engine.GameReplicationInfo'.default.AdminEmail;
	MOTDLine1 = class'Engine.GameReplicationInfo'.default.MOTDLine1;
	MOTDLine2 = class'Engine.GameReplicationInfo'.default.MOTDLine2;
	MOTDLine3 = class'Engine.GameReplicationInfo'.default.MOTDLine3;
	MOTDLine4 = class'Engine.GameReplicationInfo'.default.MOTDLine4;

	if (Request.GetVariable("Apply", "") != "" && USL >= SAM.USLServerSettings)
	{
		ServerName = Request.GetVariable("ServerName", "");
		AdminName = Request.GetVariable("AdminName", "");
		AdminEmail = Request.GetVariable("AdminEmail", "");
		MOTDLine1 = Request.GetVariable("MOTDLine1", "");
		MOTDLine2 = Request.GetVariable("MOTDLine2", "");
		MOTDLine3 = Request.GetVariable("MOTDLine3", "");
		MOTDLine4 = Request.GetVariable("MOTDLine4", "");
		
		class'Engine.GameReplicationInfo'.Default.ServerName = ServerName;
		class'Engine.GameReplicationInfo'.Default.AdminName = AdminName;
		class'Engine.GameReplicationInfo'.Default.AdminEmail = AdminEmail;
		class'Engine.GameReplicationInfo'.Default.MOTDline1 = MOTDLine1;
		class'Engine.GameReplicationInfo'.Default.MOTDline2 = MOTDLine2;
		class'Engine.GameReplicationInfo'.Default.MOTDline3 = MOTDLine3;
		class'Engine.GameReplicationInfo'.Default.MOTDline4 = MOTDLine4;
		class'Engine.GameReplicationInfo'.Static.StaticSaveConfig();
	}
    sRet="<tr><td nowrap width=\"1%%\">Server Name</td><td><input type=\"text\" name=\"ServerName\" size=\"25\" value=\""$ServerName$"\" ";
    if(USL < SAM.USLServerSettings) sRet=sRet$"disabled";
    sRet=sRet$"></td></tr>"$chr(10)$"      ";
        
    sRet=sRet$"<tr><td nowrap width=\"1%%\">Admin Name</td><td><input type=\"text\" name=\"AdminName\" size=\"25\" value=\""$AdminName$"\" ";
    if(USL < SAM.USLServerSettings) sRet=sRet$"disabled";
    sRet=sRet$"></td></tr>"$chr(10)$"      ";
        
    sRet=sRet$"<tr><td nowrap width=\"1%%\">Admin EMail</td><td><input type=\"text\" name=\"$AdminEMail$\" size=\"25\" value=\""$AdminEMail$"\" ";
    if(USL < SAM.USLServerSettings) sRet=sRet$"disabled";
    sRet=sRet$"></td></tr>"$chr(10)$"      ";
        
    sRet=sRet$"<tr><td nowrap width=\"1%%\">MOTDLine1</td><td><input type=\"text\" name=\"MOTDLine1\" size=\"25\" value=\""$MOTDLine1$"\" ";
    if(USL < SAM.USLServerSettings) sRet=sRet$"disabled";
    sRet=sRet$"></td></tr>"$chr(10)$"      ";
        
    sRet=sRet$"<tr><td nowrap width=\"1%%\">MOTDLine2</td><td><input type=\"text\" name=\"MOTDLine2\" size=\"25\" value=\""$MOTDLine2$"\" ";
    if(USL < SAM.USLServerSettings) sRet=sRet$"disabled";
    sRet=sRet$"></td></tr>"$chr(10)$"      ";
        
    sRet=sRet$"<tr><td nowrap width=\"1%%\">MOTDLine3</td><td><input type=\"text\" name=\"MOTDLine3\" size=\"25\" value=\""$MOTDLine3$"\" ";
    if(USL < SAM.USLServerSettings) sRet=sRet$"disabled";
    sRet=sRet$"></td></tr>"$chr(10)$"      ";
        
    sRet=sRet$"<tr><td nowrap width=\"1%%\">MOTDLine4</td><td><input type=\"text\" name=\"MOTDLine4\" size=\"25\" value=\""$MOTDLine4$"\" ";
    if(USL < SAM.USLServerSettings) sRet=sRet$"disabled";
    sRet=sRet$"></td></tr>"$chr(10)$"      ";

    if(USL>=SAM.USLServerSettings) sRet=sRet$"<tr><td colspan=\"2\" align=\"right\"><input type=\"submit\" name=\"Apply\" value=\"Apply\"></td></tr>";
        
    return sRet;
}

function string GetSetServerReasonInfo(WebRequest Request)
{
    local String sRet;
    local int i,j,GAL,USL;
	
		USL = SAM.CurrentUserSecLevel();
    sRet="";	

	if( Request.GetVariable("Update") !="" )
	{
		i = int(Request.GetVariable("ReasonCode", "-1"));
		if(i >= 0 && i <64)
		
	    if ((SAM.ReasonMessage[i]=="" && USL >= SAM.USLReasonAdd) ||
	        (SAM.ReasonMessage[i]!="" && USL >= SAM.USLReasonEdit))
        {
    	    SAM.ReasonMessage[i] = Request.GetVariable("Reason");
	    	SAM.SaveConfig();
	    }
	}

	if(Request.GetVariable("Delete") != "" && USL >= SAM.USLReasonDelete )
	{
		i = int(Request.GetVariable("ReasonCode", "-1"));
		
		if(i >= 0 && i < 64)
		{
		    SAM.ReasonMessage[i]="";
			SAM.SaveConfig();
		}
	}

	for(i=0; i<64; i++)
	{
        sRet=sRet$"<tr>"$chr(10)$chr(10);
        sRet=sRet$"  <form method=\"post\" action=\""$ServerReasonsPage$"?ReasonCode="$string(i)$"\">"$chr(10);
        sRet=sRet$"  <td align=\"center\">"$chr(10);
        sRet=sRet$"    "$string(i)$chr(10);
        sRet=sRet$"  </td>"$chr(10);
        sRet=sRet$"  <td>"$chr(10);
        sRet=sRet$"    <input type=\"text\" name=\"Reason\" size=\"50%\" value=\""$SAM.ReasonMessage[i]$"\">"$chr(10);
        sRet=sRet$"  </td>"$chr(10);
        sRet=sRet$"  <td>"$chr(10);
        sRet=sRet$"    <nobr>"$chr(10);

        sRet=sRet$"    <input type=\"Submit\" name=\"Delete\" Value=\"Delete\"";
        if(USL < SAM.USLReasonDelete) sRet=sRet$" disabled";
        sRet=sRet$">"$chr(10);
        
        sRet=sRet$"    <input type=\"Submit\" name=\"Update\" Value=\"Update\"";
        if(USL < SAM.USLReasonEdit) sRet=sRet$" disabled";
        sRet=sRet$">"$chr(10);
        
        sRet=sRet$"    </nobr>"$chr(10);
        sRet=sRet$"  </td>"$chr(10);
        sRet=sRet$"  </form>"$chr(10);
        sRet=sRet$"</tr>"$chr(10);			
        
	}
                
    return sRet;

}

function string GetSetServerMuteInfo(WebRequest Request)
{
    local String sRet;
    local int i,j,GAL,USL;
	
	USL = SAM.CurrentUserSecLevel();
    sRet="";	

	if ((Request.GetVariable("New") != "" && USL >= SAM.USLWhipMuteAdd) ||
	    (Request.GetVariable("Update") != "" && USL >= SAM.USLWhipMuteAdd && USL >= SAM.USLWhipMuteDelete))
	{
		i = int(Request.GetVariable("MuteID", "-1"));
		if(i == -1)
			for(i = 0; i<128 && SAM.Mutes[i] != ""; i++);
		if(i < 128)
			SAM.Mutes[i] = Request.GetVariable("Mute");
		SAM.SaveConfig();
	}

	if(Request.GetVariable("Delete") != "" && USL >= SAM.USLWhipMuteDelete )
	{
		i = int(Request.GetVariable("MuteID", "-1"));
		
		if(i >= 0)
		{
			for(i = i; i<127 && SAM.Mutes[i] != ""; i++)
				SAM.Mutes[i] = SAM.Mutes[i + 1];

			if(i == 127)
				SAM.Mutes[127] = "";
			SAM.SaveConfig();
		}
	}

	for(i=0; i<128 && SAM.Mutes[i] != ""; i++)
	{

        sRet=sRet$"<tr>"$chr(10)$chr(10);
        sRet=sRet$"  <form method=\"post\" action=\""$ServerMutesPage$"?MuteID="$string(i)$"\">"$chr(10);
        sRet=sRet$"  <td align=\"center\">"$chr(10);
        sRet=sRet$"    "$string(i)$chr(10);
        sRet=sRet$"  </td>"$chr(10);
        sRet=sRet$"  <td>"$chr(10);
        sRet=sRet$"    <input type=\"text\" name=\"Mute\" size=\"25\" value=\""$SAM.Mutes[i]$"\">"$chr(10);
        sRet=sRet$"  </td>"$chr(10);
        sRet=sRet$"  <td>"$chr(10);
        sRet=sRet$"    <nobr>"$chr(10);

        sRet=sRet$"    <input type=\"Submit\" name=\"Delete\" Value=\"Delete\"";
        if(USL < SAM.USLWhipMuteDelete) sRet=sRet$" disabled";
        sRet=sRet$">"$chr(10);
        
        sRet=sRet$"    <input type=\"Submit\" name=\"Update\" Value=\"Update\"";
        if(USL < SAM.USLWhipMuteAdd || USL < SAM.USLWhipMuteDelete) sRet=sRet$" disabled";
        sRet=sRet$">"$chr(10);

        
        sRet=sRet$"    </nobr>"$chr(10);
        sRet=sRet$"  </td>"$chr(10);
        sRet=sRet$"  </form>"$chr(10);
        sRet=sRet$"</tr>"$chr(10);			
        
	}
    if(USL >= SAM.USLWhipMuteAdd)
    {
        sRet=sRet$"       <tr>"$chr(10);
        sRet=sRet$"          <form method=\"post\" action=\""$ServerMutesPage$"\">"$chr(10);
        sRet=sRet$"          <td>&nbsp;</td>"$chr(10);
        sRet=sRet$"          <td>"$chr(10);
        sRet=sRet$"            <input type=\"text\" name=\"Mute\" size=\"25\">"$chr(10);
        sRet=sRet$"          </td>"$chr(10);
        sRet=sRet$"          <td>"$chr(10);
        sRet=sRet$"            <input type=\"Submit\" name=\"New\" value=\"New\">"$chr(10);
        sRet=sRet$"          </td>"$chr(10);
        sRet=sRet$"          </form>"$chr(10);
        sRet=sRet$"        </tr>"$chr(10);       
    }
                 
    return sRet;

}

function string GetSetServerBanInfo(WebRequest Request)
{
    local String sRet;
    local int i,j,GAL,USL;
	
		USL = SAM.CurrentUserSecLevel();
    sRet="";	

	if( (Request.GetVariable("New") != "" && USL >= SAM.USLServerBanIP) ||
	    (Request.GetVariable("Update") != "" && USL >= SAM.USLServerBanIP && USL >= SAM.USLServerUnbanIP))
	{
		i = int(Request.GetVariable("PolicyNo", "-1"));
		if(i == -1)
			for(i = 0; i<50 && Level.Game.IPPolicies[i] != ""; i++);
		if(i < 50)
			Level.Game.IPPolicies[i] = Request.GetVariable("AcceptDeny")$","$Request.GetVariable("IPMask");
		Level.Game.SaveConfig();
	}

	if(Request.GetVariable("Delete") != "" && USL >= SAM.USLServerUnbanIP )
	{
		i = int(Request.GetVariable("PolicyNo", "-1"));
		
		if(i > 0)
		{
			for(i = i; i<49 && Level.Game.IPPolicies[i] != ""; i++)
				Level.Game.IPPolicies[i] = Level.Game.IPPolicies[i + 1];

			if(i == 49)
				Level.Game.IPPolicies[49] = "";
			Level.Game.SaveConfig();
		}
	}

	for(i=0; i<50 && Level.Game.IPPolicies[i] != ""; i++)
	{
        j = InStr(Level.Game.IPPolicies[i], ",");

        sRet=sRet$"<tr>"$chr(10)$chr(10);
        sRet=sRet$"  <form method=\"post\" action=\""$ServerBansPage$"?PolicyNo="$string(i)$"\">"$chr(10);
        sRet=sRet$"  <td align=\"center\">"$chr(10);
        sRet=sRet$"    "$string(i)$chr(10);
        sRet=sRet$"  </td>"$chr(10);
        sRet=sRet$"  <td>"$chr(10);

		if(Left(Level.Game.IPPolicies[i], j) ~= "DENY")
		{
            sRet=sRet$"    <input type=\"radio\" name=\"AcceptDeny\" value=\"ACCEPT\" >Accept"$chr(10);
            sRet=sRet$"    <input type=\"radio\" name=\"AcceptDeny\" value=\"DENY\" checked>Deny"$chr(10);
		}
		else
		{
            sRet=sRet$"    <input type=\"radio\" name=\"AcceptDeny\" value=\"ACCEPT\" checked>Accept"$chr(10);
            sRet=sRet$"    <input type=\"radio\" name=\"AcceptDeny\" value=\"DENY\" >Deny"$chr(10);
		}

        sRet=sRet$"  </td>"$chr(10);
        sRet=sRet$"  <td>"$chr(10);
        sRet=sRet$"    <input type=\"text\" name=\"IPMask\" size=\"15\" value=\""$Mid(Level.Game.IPPolicies[i], j+1)$"\">"$chr(10);
        sRet=sRet$"  </td>"$chr(10);
        sRet=sRet$"  <td>"$chr(10);
        sRet=sRet$"    <nobr>"$chr(10);

        sRet=sRet$"    <input type=\"Submit\" name=\"Delete\" Value=\"Delete\"";
        if(USL < SAM.USLServerUnbanIP) sRet=sRet$" disabled";
        sRet=sRet$">"$chr(10);
        
        sRet=sRet$"    <input type=\"Submit\" name=\"Update\" Value=\"Update\"";
        if(USL < SAM.USLServerBanIP || USL < SAM.USLServerUnbanIP) sRet=sRet$" disabled";
        sRet=sRet$">"$chr(10);

        
        sRet=sRet$"    </nobr>"$chr(10);
        sRet=sRet$"  </td>"$chr(10);
        sRet=sRet$"  </form>"$chr(10);
        sRet=sRet$"</tr>"$chr(10);			
        
	}
    if(USL >= SAM.USLServerBanIP)
    {
        sRet=sRet$"       <tr>"$chr(10);
        sRet=sRet$"          <form method=\"post\" action=\"%PostAction%\">"$chr(10);
        sRet=sRet$"          <td>&nbsp;</td>"$chr(10);
        sRet=sRet$"          <td>"$chr(10);
        sRet=sRet$"            <input type=\"radio\" name=\"AcceptDeny\" value=\"ACCEPT\">Accept"$chr(10);
        sRet=sRet$"            <input type=\"radio\" name=\"AcceptDeny\" value=\"DENY\" checked>Deny"$chr(10);
        sRet=sRet$"          </td>"$chr(10);
        sRet=sRet$"          <td>"$chr(10);
        sRet=sRet$"            <input type=\"text\" name=\"IPMask\" size=\"15\">"$chr(10);
        sRet=sRet$"          </td>"$chr(10);
        sRet=sRet$"          <td>"$chr(10);
        sRet=sRet$"            <input type=\"Submit\" name=\"New\" value=\"New\">"$chr(10);
        sRet=sRet$"          </td>"$chr(10);
        sRet=sRet$"          </form>"$chr(10);
        sRet=sRet$"        </tr>"$chr(10);       
//        sRet=sRet$"     </table>"$chr(10)$chr(10);
    }
                 
    return sRet;
}

function string GetSetGameInfo(WebRequest Request, string sGameType, bool bChange)
{
local GamePlayInfo MyGamePI;
local string sRet, sName, sType, sDName;
local string value, newval;
local bool bEnabled;
local int i;

	sRet = GetGamePlayInfo(sGameType, MyGamePI);
	if (sRet == "")
	{
	// Make a table rows string, 1 row per setting
		for (i = 0; i<MyGamePI.NumSettings; i++)
		{
			sName = MyGamePI.GetSettingName(i);
			value="";
			if (MyGamePI.Get(sName, value, true))
			{
    			bEnabled=MyGamePI.Get(sName, value,false);
				sDName = MyGamePI.GetSettingDisplayName(i);
				sType = MyGamePI.GetSettingType(i);
//			    log("sdname="$sdname@"enabled="$bEnabled);
				// If Posting Back, Grab changes
				if (bChange)
				{
    				if (sType ~= "bool")
    					newval = Request.GetVariable(sName,"false");
                    else
    					newval = Request.GetVariable(sName,value);

					if ((newval != value) && MyGamePI.Set(sName, newval))
						value = newval;
				}

				sRet = sRet $ "<tr><td>" $ sDName $ "</td><td>";
				if (sType ~= "bool")
				{
					sRet = sRet $ "<input type='checkbox' value='True' name='" $ sName $ "'";
					if (value ~= "true")
						sRet = sRet $ " checked";
					if (! bEnabled)
						sRet = sRet $ " disabled";
						
					sRet = sRet $ ">";
				}
				else if (sType ~= "int")
				{
					sRet = sRet $ "<input type='text' name='" $ sName $ "' value='" $ value $ "' size=8";
					if (! bEnabled)
						sRet = sRet $ " disabled";
					sRet = sRet $ ">";
				}
				else if (sType ~= "float")
				{
					sRet = sRet $ "<input type='text' name='" $ sName $ "' value='" $ value $ "' size=15";
					if (! bEnabled)
						sRet = sRet $ " disabled";
					sRet = sRet $ ">";
				}
				else if (sType ~= "string")
				{
					sRet = sRet $ "<input type='text' name='" $ sName $ "' value='" $ value $ "' size=40";
					if (! bEnabled)
						sRet = sRet $ " disabled";
					sRet = sRet $ ">";
				}
				else if (sType ~= "custom")
				{
				}
				sRet = sRet $ "</td></tr>";
			}
		}
		sRet = sRet $ "<tr><td colspan=2><input type='submit' name='ApplySettings' value='Apply Settings'>&nbsp;&nbsp;<input type='reset' name='CancelSettings' value='Cancel Changes'></td></tr>";
		if (bChange)
			MyGamePI.ApplyChanges();
	}
	MyGamePI.Destroy();
	MyGamePI = None;
	return sRet;
}

// Returns a formatted list of Groups as <option> tags
// Must not forget to show only the Groups that the admin can add users to
function string MakeGroupList(optional string ActiveGrp)
{
local ListItem Groups, TempItem;
local string grpname, OutStr;

	SAM.BeginIter();
	grpname = SAM.NextGroupName();
	while (grpname != "")
	{ 
		TempItem = new(None) class'ListItem';
		TempItem.Tag = grpname;
		TempItem.Data = grpname;
		
		if (Groups == None)
			Groups = TempItem;
		else
			Groups.AddSortedElement(Groups, TempItem);
			
		grpname = SAM.NextGroupName();
	}

	// Now, just make the group list a bunch of <option>
	
	if (Groups == None)
		return "<option value='None'>*** No Groups Defined***";

	OutStr = "";
	for (TempItem = Groups; TempItem != None; TempItem = TempItem.Next)
	{
		OutStr = OutStr$"<option";
		
		if (TempItem.Data == ActiveGrp)
			OutStr = OutStr$" Selected";
			
		OutStr = OutStr$">"$TempItem.Data;
	}
	
	return OutStr;
}

// Must not forget to show only the Users from groups that the admin can manage
function string GetUsersForBrowse()
{
local ListItem Users, TempItem;
local string uname, OutStr;
local int idx;

	SAM.BeginIter();
	uname = SAM.NextUserName();
	while (uname != "")
	{
		TempItem = new(None) class'ListItem';
		TempItem.Tag = uname;
		TempItem.Data = uname;
		
		if (Users == None)
			Users = TempItem;
		else
			Users.AddSortedElement(Users, TempItem);
			
		uname = SAM.NextUserName();
	}

	// Now, just make the group list a bunch of Rows
	
	if (Users == None)
		return "<tr><td>** No Users In List **</td></tr>";

	OutStr = "<tr><td>Name</td><td>Group</td><td>&nbsp;</td></tr>";
	for (TempItem = Users; TempItem != None; TempItem = TempItem.Next)
	{
		idx = SAM.FindUserId(TempItem.Data);
		// Build 1 Group Row
		OutStr = OutStr$"<tr>";
		OutStr = OutStr$"<td><a href='"$UsersEditPage$"?edit="$TempItem.Data$"'>"$TempItem.Data$"</a>&nbsp;&nbsp;&nbsp;</td>";
		if (SAM.CanManageGroup(SAM.GetUserGroup(idx)))
			OutStr = OutStr$"<td><a href='"$GroupsEditPage$"?edit="$SAM.GetUserGroup(idx)$"'>"$SAM.GetUserGroup(idx)$"</a>&nbsp;&nbsp;&nbsp;</td>";
		else
			OutStr = OutStr$"<td>"$SAM.GetUserGroup(idx)$"</td>";
		OutStr = OutStr$"<td><a href='"$UsersBrowsePage$"?delete="$TempItem.Data$"'>Delete</a>&nbsp;&nbsp;&nbsp;</td>";
		OutStr = OutStr$"</tr>";
	}
	return OutStr;
}

// Must not forget to show only the Groups that the admin can add users to
function string GetGroupsForBrowse()
{
local ListItem Groups, TempItem;
local string grpname, OutStr;
local int idx;

	SAM.BeginIter();
	grpname = SAM.NextGroupName();
	while (grpname != "")
	{ 
		TempItem = new(None) class'ListItem';
		TempItem.Tag = grpname;
		TempItem.Data = grpname;
		
		if (Groups == None)
			Groups = TempItem;
		else
			Groups.AddSortedElement(Groups, TempItem);
			
		grpname = SAM.NextGroupName();
	}

	// Now, just make the group list a bunch of Rows
	
	if (Groups == None)
		return "<tr><td>** No Groups In List **</td></tr>";

	OutStr = "<tr><td>Name</td><td>Privileges</td><td>User Sec Lvl</td><td>Game Sec Lvl</td><td>&nbsp;</td></tr>";
	for (TempItem = Groups; TempItem != None; TempItem = TempItem.Next)
	{
		idx = SAM.FindGroupId(TempItem.Data);
		// Build 1 Group Row
		OutStr = OutStr$"<tr>";
		OutStr = OutStr$"<td><a href='"$GroupsEditPage$"?edit="$TempItem.Data$"'>"$TempItem.Data$"</a></td>";
		OutStr = OutStr$"<td>"$SAM.GetGroupPrivs(idx)$"</td>";
		OutStr = OutStr$"<td>"$SAM.GetGroupUSL(idx)$"</td>";
		OutStr = OutStr$"<td>"$SAM.GetGroupGSL(idx)$"</td>";
		OutStr = OutStr$"<td><a href='"$GroupsBrowsePage$"?delete="$TempItem.Data$"'>Delete</a></td>";
		OutStr = OutStr$"</tr>";	
	}
	return OutStr;
}

function string ModifyGroupInfo(string gname, string privs, int usl, int gsl)
{
local bool bIsAdmin;

	// Check new UserSecLevel of Group
	bIsAdmin = SAM.GroupIsAdmin(gname);
	if (bIsAdmin && usl != 255 && SAM.CountMasterAdmins() < 2)
		return "Cannot delete last Master Admin Group";
			
	if (usl < 0 || usl > 255)
		return "Invalid User Security Level value";
		
	// Check new GameSecLevel of Group
	if (gsl < 0 || gsl > 255)
		return "Invalid Game Security Level";
		
	SAM.ModifyGroup(gname, privs, usl, gsl);
	return ""; 
}

function string ModifyUserInfo(string uname, string newname, string upass, string ugrp)
{
	if (SAM.FindUserId(uname) == -1)
		return "User '"$uname$"' was not found in the list.";

	if (!SAM.CheckUserName(newname))
		return "Invalid characters in new Username";		
		
	if (SAM.FindUserId(newname) != -1 && uname != newname)
		return "Username already taken, choose another one.";

	if (!SAM.CanManageGroup(ugrp))
		return "You cannot assign a user to a group you cannot manage yourself.";

	SAM.ModifyUser(uname, newname, upass, ugrp);
	return "";
}

function LoadGameTypes()
{
	local class<GameInfo>	TempClass;
	local String 			NextGame;
	local ListItem	TempItem;
	local int				i, Pos;

	// reinitialize list if needed
	GameTypeList = None;

	// Compile a list of all gametypes.
	TempClass = class'TournamentGameInfo';
	NextGame = Level.GetNextInt("TournamentGameInfo", 0);
	while (NextGame != "")
	{
		Pos = InStr(NextGame, ".");
		TempClass = class<GameInfo>(DynamicLoadObject(NextGame, class'Class'));
//log("pcl: NextGame="$NExtGame);
//log("pcl:TempClass.Default.GameName="$TempClass.Default.GameName);
//log("");
		TempItem = new(None) class'ListItem';
		TempItem.Tag = TempClass.Default.GameName;
		TempItem.Data = NextGame;

		if (GameTypeList == None)
			GameTypeList = TempItem;
		else
			GameTypeList.AddElement(TempItem);

		NextGame = Level.GetNextInt("TournamentGameInfo", ++i);
	}
}

// Loads the list of bots for later access
function LoadBotsList()
{
local DeathMatchPlus	DMP;
local ListItem	TempItem;
local int i;

	DMP = DeathMatchPlus(Level.Game);
	if (DMP != None && DMP.BotConfig != None)
	{
		// Lets start fresh
		FullBotListItem = None;
	
		// Compile a list of all existing bots
		for (i = 0; i<32; i++)
		{
			if (DMP.BotConfig.GetBotName(i) != "" && DMP.BotConfig.CHGetBotClass(i) != None)
			{
				// Add the bot to the list
				TempItem = new(None) class'ListItem';
				TempItem.Tag = DMP.BotConfig.GetBotName(i);
				TempItem.Data = string(i);
		
				if (FullBotListItem == None)
					FullBotListItem = TempItem;
				else
					FullBotListItem.AddSortedElement(FullBotListItem, TempItem);
			}
		}
	}
}

/*function LoadMutators()
{
	local int NumMutatorClasses;
	local string NextMutator, NextDesc;
	local listitem TempItem;
	local Mutator M;
	local int j;
	local int k;

	ExcludeMutators = None;

	Level.GetNextIntDesc("Engine.Mutator", 0, NextMutator, NextDesc);
	while( (NextMutator != "") && (NumMutatorClasses < 50) )
	{
		TempItem = new(None) class'ListItem';

		k = InStr(NextDesc, ",");
		if (k == -1)
			TempItem.Tag = NextDesc;
		else
			TempItem.Tag = Left(NextDesc, k);

		TempItem.Data = NextMutator;

		if (ExcludeMutators == None)
			ExcludeMutators = TempItem;
		else
			ExcludeMutators.AddSortedElement(ExcludeMutators, TempItem);
		NumMutatorClasses++;
		Level.GetNextIntDesc("Engine.Mutator", NumMutatorClasses, NextMutator, NextDesc);
	}

	IncludeMutators = None;

	for (M = Level.Game.BaseMutator.NextMutator; M != None; M = M.NextMutator) 
	{
		TempItem = ExcludeMutators.DeleteElement(ExcludeMutators, String(M.Class));
		
		if (TempItem != None) 
		{
			if (IncludeMutators == None)
				IncludeMutators = TempItem;
			else
				IncludeMutators.AddElement(TempItem);
		}
		
		else log("Unknown Mutator in use: "@String(M.Class));
	}
}

function String UsedMutators()
{
	local ListItem TempItem;
	local String OutStr;

	if(IncludeMutators == None)
		return "";

	OutStr = IncludeMutators.Data;
	for (TempItem = IncludeMutators.Next; TempItem != None; TempItem = TempItem.Next)
	{
		OutStr = OutStr$","$TempItem.Data;
	}

	return OutStr;
}
*/

function String PadLeft(String InStr, int Width, String PadStr)
{
	local String OutStr;

	if (Len(PadStr) == 0)
		PadStr = " ";

	for (OutStr=InStr; Len(OutStr) < Width; OutStr=PadStr$OutStr);

	return Right(OutStr, Width); // in case PadStr is more than one character
}

function ApplyMapList(out ListItem ExcludeMaps, out ListItem IncludeMaps, String GameType, String MapListType)
{
	local class<MapList> MapListClass;
	local ListItem TempItem;
	local int IncludeCount, i;

	MapListClass = Class<MapList>(DynamicLoadObject(MapListType, class'Class'));

	IncludeMaps = None;
	ReloadExcludeMaps(ExcludeMaps, GameType);

	IncludeCount = ArrayCount(MapListClass.Default.Maps);
	for(i=0;i<IncludeCount;i++)
	{
		if(MapListClass.Default.Maps[i] == "")
			break;
		if (ExcludeMaps != None)
		{
			TempItem = ExcludeMaps.DeleteElement(ExcludeMaps, MapListClass.Default.Maps[i]);

			if(TempItem != None)
			{
				if (IncludeMaps == None)
					IncludeMaps = TempItem;
				else
					IncludeMaps.AddElement(TempItem);
			}
			else
				WriteLog("*** Unknown map in Map List: "$MapListClass.Default.Maps[i]);
		}
		else
			WriteLog("*** Empty exclude list, i="$i);
	}
}

function ReloadExcludeMaps(out ListItem ExcludeMaps, String GameType)
{
	local class<GameInfo>	GameClass;
	local string FirstMap, NextMap, TestMap, MapName;
	local ListItem TempItem;

	GameClass = class<GameInfo>(DynamicLoadObject(GameType, class'Class'));

	ExcludeMaps = None;
	if(GameClass.Default.MapPrefix == "")
		return;
	FirstMap = Level.GetMapName(GameClass.Default.MapPrefix, "", 0);
	NextMap = FirstMap;
	while (!(FirstMap ~= TestMap) && FirstMap != "")
	{
		if(!(Left(NextMap, Len(NextMap) - 4) ~= (GameClass.Default.MapPrefix$"-tutorial")))
		{
			// Add the map.
			TempItem = new(None) class'ListItem';
			TempItem.Data = NextMap;

			if(Right(NextMap, 4) ~= ".unr")
				TempItem.Tag = Left(NextMap, Len(NextMap) - 4);
			else
				TempItem.Tag = NextMap;

			if (ExcludeMaps == None)
				ExcludeMaps = TempItem;
			else
				ExcludeMaps.AddSortedElement(ExcludeMaps, TempItem);
		}

		NextMap = Level.GetMapName(GameClass.Default.MapPrefix, NextMap, 1);
		TestMap = NextMap;
	}
}

function ReloadIncludeMaps(out ListItem ExcludeMaps, out ListItem IncludeMaps, String GameType)
{
	local class<GameInfo> GameClass;
	local ListItem TempItem;
	local int i;

	GameClass = class<GameInfo>(DynamicLoadObject(GameType, class'Class'));
	if(GameClass.Default.MapListType == None)
		return;
	if (GameClass != None)
	{
		for (i=0; i<ArrayCount(GameClass.Default.MapListType.Default.Maps) && GameClass.Default.MapListType.Default.Maps[i] != ""; i++)
		{
			// Add the map.
			TempItem = ExcludeMaps.DeleteElement(ExcludeMaps, GameClass.Default.MapListType.Default.Maps[i]);
			if (TempItem == None)
			{
				TempItem = new(None) class'ListItem';
				TempItem.Data = GameClass.Default.MapListType.Default.Maps[i];

				if(Right(TempItem.Data, 4) ~= ".unr")
					TempItem.Tag = Left(TempItem.Data, Len(TempItem.Data) - 4);
				else
					TempItem.Tag = TempItem.Data;
			}
			else
			{
				if (IncludeMaps == None)
					IncludeMaps = TempItem;
				else
					IncludeMaps.AddElement(TempItem);
			}
		}
	}
}

function UpdateDefaultMaps(String GameType, ListItem TempItem)
{
	local class<GameInfo> GameClass;
	local int i;

	GameClass = class<GameInfo>(DynamicLoadObject(GameType, class'Class'));

	for (i=0; i<ArrayCount(GameClass.Default.MapListType.Default.Maps); i++)
	{
		if (TempItem != None)
		{
			GameClass.Default.MapListType.Default.Maps[i] = TempItem.Data;
			TempItem = TempItem.Next;
		}
		else
			GameClass.Default.MapListType.Default.Maps[i] = "";
	}

	GameClass.Static.StaticSaveConfig();
}


function String GenerateGameTypeOptions(String CurrentGameType)
{
	local ListItem TempItem;
	local String SelectedStr, OptionStr;

	for (TempItem = GameTypeList; TempItem != None; TempItem = TempItem.Next)
	{
		if (CurrentGameType ~= TempItem.Data)
			SelectedStr = " selected";
		else
			SelectedStr = "";

		OptionStr = OptionStr$"<option value=\""$TempItem.Data$"\""$SelectedStr$">"$TempItem.Tag$"</option>";
	}
	return OptionStr;
}

function String GenerateReasonOptions()
{
    local string OptionStr, ReasonCode, Reason, list;
    local int i;
    
    for (i=0; i<64; i++)
    {
        ReasonCode=string(i);
        Reason=SAM.ReasonMessage[i];
        if (Reason != "")
            OptionStr = OptionStr$"<option value=\""$ReasonCode$"\">"$ReasonCode$":"@Reason$"</option>";
	}
    return OptionStr;
}


function String GenerateMapListOptions(String GameType, String MapListType)
{
	local class<GameInfo> GameClass;
	local String DefaultBaseClass, NextDefault, NextDesc, SelectedStr, OptionStr;
	local int NumDefaultClasses;

	GameClass = class<GameInfo>(DynamicLoadObject(GameType, class'Class'));
	if(GameClass == None)
		return "";

	DefaultBaseClass = String(GameClass.Default.MapListType);

	if(DefaultBaseClass == "")
		return "";

	NextDefault = "Custom";
	NextDesc = "Custom";

	if(DynamicLoadObject(DefaultBaseClass, class'Class') == None)
		return "";
	while( (NextDefault != "") && (NumDefaultClasses < 50) )
	{
		if (MapListType ~= NextDefault)
			SelectedStr = " selected";
		else
			SelectedStr = "";

		OptionStr = OptionStr$"<option value=\""$NextDefault$"\""$SelectedStr$">"$NextDesc$"</option>";

		Level.GetNextIntDesc(DefaultBaseClass, NumDefaultClasses++, NextDefault, NextDesc);
	}
	return OptionStr;
}

function String GenerateMapListSelect(ListItem MapList, optional string SelectedItem)
{
	local ListItem TempItem;
	local String ResponseStr, SelectedStr;

	if (MapList == None)
		return "<option value=\"\">*** None ***</option>";

	for (TempItem = MapList; TempItem != None; TempItem = TempItem.Next) {
		SelectedStr = "";
		if (TempItem.Data ~= SelectedItem || TempItem.bJustMoved)
			SelectedStr = " selected";
		ResponseStr = ResponseStr$"<option value=\""$TempItem.Data$"\""$SelectedStr$">"$TempItem.Tag$"</option>";
	}
    return ResponseStr;
}

function String GenerateBotListSelect(Listitem BotName, optional string SelectedItem)
{
	local ListItem TempItem;
	local String ResponseStr, SelectedStr;
	
	if (BotName == None)
		return "<option value=\"\">*** No Bots Configured ***</option>";
		
	for (TempItem = BotName; TempItem != None; TempItem = TempItem.Next)
	{
		SelectedStr = "";
		if (TempItem.Data ~= SelectedItem || TempItem.bJustMoved)
			SelectedStr = " selected";
		ResponseStr = ResponseStr$"<option value=\""$TempItem.Data$"\""$SelectedStr$">"$TempItem.Tag$"</option>";
	}
	
	return ResponseStr;
}

function string TeamName(int team)
{
	if (team == 255)
		return "Gray";

	return class'TeamGamePlus'.default.TeamColor[Clamp(team, 0, 3)];
}

function string TeamColor(int team)
{
	if (team == 255)
		return "Gray";
	return Colors[Clamp(team, 0, 3)];
}

function Pawn FindPlayerByName(string S, optional bool bBotOnly)
{
local Pawn aPawn;

	for (aPawn = Level.PawnList; aPawn!=None; aPawn=aPawn.NextPawn )
	{
		if (	aPawn.bIsPlayer	&&	aPawn.PlayerReplicationInfo.PlayerName~=S 
				&&	(PlayerPawn(aPawn)==None || (!bBotOnly && NetConnection(PlayerPawn(aPawn).Player)!=None )) )
		{
			return aPawn;
		}
	}
	return None;
}

function DoAccessError(WebRequest Request, WebResponse Response)
{
	Response.Subst("SmallTitle", GetServerName());
    Response.Subst("Title", "Access Error");
	Response.Subst("Message", "You do not have sufficient privileges to access this function.");
	Response.IncludeUHTM(SubPath$MessageUHTM);
}


//*****************************************************************************
event Query(WebRequest Request, WebResponse Response)
{
local bool bValidLogin;
local int GAL,USL;

	bValidLogin = false;
	foreach Spectator.AllActors(class'SemiAdminMutator', SAM)
	{
		bValidLogin = SAM.IsValidLogin(Request.Username, Request.Password); 
		break;
	}
	
	if ( (!bValidLogin) || (SAM == NONE) )
	{
		Response.FailAuthentication(AdminRealm);
		return;
	}
	
	SAM.WebLogin(Spectator);
	USL = SAM.CurrentUserSecLevel();
	
	Response.Subst("BugAddress", "semiwebadminbug"$Level.EngineVersion$"@no-networks.com");
	Response.Subst("ImageDir", ImageDir);	// Might allow to support skinning
	Response.Subst("HelpPage", HelpPage);
	Response.Subst("CLHelpPage", CLHelpPage);
	Response.Subst("QuickReference", QRGPage);
//	log("SAM.Admin.User.Name="$SAM.Admin.User.Name);
//	Log ("pcl: Request.URI="$Request.URI$" ["$(Mid(Request.URI, 1))$"]"); 
//	Log ("pcl: GAL="$GAL);
	// Match query function.  checks URI and calls appropriate input/output function
	switch (Mid(Request.URI, 1)) 
	{
	case "":
	case RootPage:
  	  	QueryRoot(Request, Response); break;

	case RootMenuPage:
		QueryRootMenu(Request, Response); break;
		
  	case RootGamePage:
  		QueryRootGame(Request, Response); break;

	case RootUsersPage:
  		QueryRootUsers(Request, Response); break;

	case RootServerPage:
  		QueryRootServer(Request, Response); break;

  	case GameDefPage:
  		QueryGameDef(Request, Response); break;

  	case GameMenuPage:
		QueryGameMenu(Request, Response); break;

  	case ServerMenuPage:
		QueryServerMenu(Request, Response); break;

	case GameConsolePage:
		if ( SAM.HasPrivilege("T") && USL >= SAM.USLGameConsoleView )
    		QueryGameConsole(Request, Response); 
		else
		  	DoAccessError(Request, Response);
		break;
		
	case GameConsoleLogPage:
		if ( SAM.HasPrivilege("T") && USL >= SAM.USLGameConsoleView )
    		QueryGameConsoleLog(Request, Response); 
		else
		  	DoAccessError(Request, Response);
		break;
		
	case GameConsoleSendPage:
		if ( SAM.HasPrivilege("T") && USL >= SAM.USLGameConsoleSend )
    		QueryGameConsoleSend(Request, Response); 
		else
		  	DoAccessError(Request, Response);
		break;

	case GamePageLev:
		if ( SAM.HasPrivilege("G") && USL >= SAM.USLGameViewSettings)
			QueryGameLev(Request, Response);
		else
		  	DoAccessError(Request, Response);
		break;

	case GameBotPage:
		if ( SAM.HasPrivilege("O") && USL >= SAM.USLGameViewBots)
			QueryGameBot(Request, Response);
		else
		  	DoAccessError(Request, Response);
//	        Log("pcl: Access Error	Priv="$SAM.HasPrivilege("O")$" USL="$USL$" SAM.USLGameViewBots="$SAM.USLGameViewBots);	  	
		break;

	case GameMutatorPage:
		if ( SAM.HasPrivilege("M") && USL >= SAM.USLGameViewMutators )
			QueryGameMutators(Request, Response);
		else
			DoAccessError(Request, Response);
		break;

	case GameMapPage:
		if ( SAM.HasPrivilege("M")  && USL >= SAM.USLGameViewMutators )
			QueryGameMaps(Request, Response);
		else
			DoAccessError(Request, Response);
		break;

	case GamePlayerKickPage:
		if ( SAM.HasPrivilege("K")   && USL >= SAM.USLServerKick )
			QueryGamePlayerKick(Request, Response);
		else
			DoAccessError(Request, Response);
		break;

	case GamePlayerBanPage:
		if ( SAM.HasPrivilege("B") && USL >= SAM.USLServerBanIP)
			QueryGamePlayerBan(Request, Response);
		else
			DoAccessError(Request, Response);
		break;	
		
	case GamePlayerWhipPage:
		if ( SAM.HasPrivilege("Z") && USL >= SAM.USLServerWhip )
			QueryGamePlayerWhip(Request, Response);
		else
			DoAccessError(Request, Response);
		break;
		
	case UsersDefPage:
		if ( SAM.CanManageUsers() )
			QueryUsersDef(Request, Response);
		else
			DoAccessError(Request, Response);
		break;

	case ServerDefPage:
		if ( SAM.CanManageServer() && USL >= SAM.USLServerViewSettings )
			QueryServerDef(Request, Response);
		else
			DoAccessError(Request, Response);
		break;

	case ServerSettingsPage:
		if ( SAM.CanManageServer() && USL >= SAM.USLServerViewSettings )
			QueryServerSettings(Request, Response);
		else
			DoAccessError(Request, Response);
		break;

	case ServerBansPage:
		if ( SAM.CanManageServer() && USL >= SAM.USLServerViewBans )
			QueryServerBans(Request, Response);
		else
			DoAccessError(Request, Response);
		break;

	case ServerReasonsPage:
	    QueryServerReasons(Request, Response);
		break;

	case ActivityPage:
	    QueryActivity(Request, Response);
		break;

	case WarningsPage:
	    QueryWarnings(Request, Response);
		break;

	case ServerMutesPage:
	    QueryServerMutes(Request, Response);
		break;



	case UsersMenuPage:
		QueryUsersMenu(Request, Response);
		break;

	case UsersAddPage:
		if ( SAM.CanManageUsers() )
			QueryUsersAdd(Request, Response);
		else
			DoAccessError(Request, Response);
		break;

	case UsersEditPage:
		if ( SAM.CanManageUsers() )
			QueryUsersMod(Request, Response);
		else
			DoAccessError(Request, Response);
		break;

	case UsersBrowsePage:
		if ( SAM.CanManageUsers() )
			QueryUsersBrowse(Request, Response);
		else
			DoAccessError(Request, Response);
		break;

	case GroupsAddPage:
		if ( SAM.IsMasterAdmin() )
			QueryGroupsAdd(Request, Response);
		else
			DoAccessError(Request, Response);
		break;

	case GroupsEditPage:
		if ( SAM.IsMasterAdmin())
			QueryGroupsMod(Request, Response);
		else
			DoAccessError(Request, Response);
		break;
	
	case GroupsBrowsePage:
		if ( SAM.IsMasterAdmin() )
			QueryGroupsBrowse(Request, Response);
		else
			DoAccessError(Request, Response); 
		break;

	case NameSearchPage:
		if ( SAM.CanManageUsers() )
			QueryNameSearch(Request, Response);
		else
			DoAccessError(Request, Response); 
		break;
	
	case ServerRestartPage:
		QueryRestart(Request, Response);
		break;
	
	case HelpPage:
		QueryHelpPage(Request, Response);
		break;
		
	case CLHelpPage:
		QueryCLHelpPage(Request, Response);
		break;

	case QRGPage:
		QueryQRGPage(Request, Response);
		break;
	
	default:
		Response.Subst("Title", "Error");
		Response.Subst("Message", "Page not found or enabled.");
		Response.IncludeUHTM(SubPath$MessageUHTM);
	}
	Response.ClearSubst();
	SAM.WebLogout();
}

//*****************************************************************************
function QueryRoot(WebRequest Request, WebResponse Response)
{
	Response.Subst("MenuURI", RootMenuPage);
	Response.Subst("ServerName", GetServerName());
	Response.Subst("MainURI", RootGamePage);
	
	Response.IncludeUHTM(SubPath$RootPage$".uhtm");
}

function QueryRootMenu(WebRequest Request, WebResponse Response)
{
	Response.Subst("DefaultBG", DefaultBG);
	Response.Subst("GameBG", 	DefaultBG);
	Response.Subst("UsersBG",	DefaultBG);
	
	Response.Subst("GameURI",  RootGamePage);
	Response.Subst("MutatorsURI",  GameMutatorPage);
	Response.Subst("MapsURI",  GameMapPage);
	Response.Subst("UsersURI", RootUsersPage);
	Response.Subst("ServerURI", RootServerPage);
	Response.Subst("ServerName", GetServerName());
	
	Response.IncludeUHTM(SubPath$RootMenuPage$".uhtm");
}

function QueryRootGame(WebRequest Request, WebResponse Response)
{
	Response.Subst("IndexURI", GameMenuPage);
	Response.Subst("MainURI", GameDefPage);
	Response.Subst("ServerName", GetServerName());

	Response.IncludeUHTM(SubPath$RootGamePage$".uhtm");
}

function QueryRootUsers(WebRequest Request, WebResponse Response)
{
	Response.Subst("IndexURI", UsersMenuPage);
	Response.Subst("MainURI", UsersDefPage);
	Response.Subst("ServerName", GetServerName());

	Response.IncludeUHTM(SubPath$RootUsersPage$".uhtm");
}

function QueryRootServer(WebRequest Request, WebResponse Response)
{
	Response.Subst("IndexURI", ServerMenuPage);
	Response.Subst("MainURI", ServerDefPage);
	Response.Subst("ServerName", GetServerName());

	Response.IncludeUHTM(SubPath$RootServerPage$".uhtm");
}
//*****************************************************************************
//
//GAME FUNCTIONS
//
//*****************************************************************************

function QueryGameDef(WebRequest Request, WebResponse Response)
{
	QueryMain(Request, Response);
	Response.Subst("ServerName", GetServerName());
	
/*	Response.IncludeUHTM(SubPath$GameDefPage$".uhtm");
	Response.ClearSubst(); */
}

function QueryGameMenu(WebRequest Request, WebResponse Response)
{
	// set background colors
	Response.Subst("DefaultBG", DefaultBG);	// for unused tabs

	Response.Subst("GameBG", 	DefaultBG);
	Response.Subst("BotsBG", DefaultBG);
	Response.Subst("MapsBG", DefaultBG);
	Response.Subst("MutatorsBG", DefaultBG);
	Response.Subst("ConsoleBG", DefaultBG);
	Response.Subst("KickBG", DefaultBG);
	Response.Subst("BanBG", DefaultBG);
	Response.Subst("RestartBG", DefaultBG);
	Response.Subst("HelpBG", DefaultBG);

	// Set URIs
	Response.Subst("Game", GamePageLev);
	Response.Subst("Mutators", GameMutatorPage);
	Response.Subst("Console", GameConsolePage);
	Response.Subst("Maps", GameMapPage);
	Response.Subst("Kick", GamePlayerKickPage);
	Response.Subst("Ban", GamePlayerBanPage);
	Response.Subst("Whip", GamePlayerWhipPage);
	Response.Subst("Bots", GameBotPage);
	Response.Subst("Restart", ServerRestartPage);
	Response.Subst("ServerName", GetServerName());
	
	
	Response.IncludeUHTM(SubPath$GameMenuPage$".uhtm");
}

function QueryServerMenu(WebRequest Request, WebResponse Response)
{
	// set background colors
	Response.Subst("DefaultBG", DefaultBG);	// for unused tabs
	Response.Subst("ServerName", GetServerName());


	// Set URIs
	Response.Subst("Server", ServerSettingsPage);
	Response.Subst("ServerIP", ServerBansPage);
	Response.Subst("ServerMutes", ServerMutesPage);
	Response.Subst("ReasonCodes", ServerReasonsPage);
	Response.Subst("Warnings", WarningsPage);
	Response.Subst("AdminActions", ActivityPage);
	
	Response.IncludeUHTM(SubPath$ServerMenuPage$".uhtm");
}
function QueryGamePlayerKick(WebRequest Request, WebResponse Response)
{
	local string Sort, PlayerListSubst, TempStr, TempTeam, IP, TimeOnS;
	local ListItem PlayerList, TempItem;
	local Pawn P;
	local int i, PawnCount, j, MinPlay;
	local int USL;
	local float TimeOn,FPH;
	
    USL = SAM.CurrentUserSecLevel();

	Sort = Request.GetVariable("Sort", "Name");
	
	for (P=Level.PawnList; P!=None; P=P.NextPawn)
	{
		if(		PlayerPawn(P) != None
			&&	P.PlayerReplicationInfo != None
			&&	NetConnection(PlayerPawn(P).Player) != None)
		{
			if(Request.GetVariable("KickPlayer"$string(P.PlayerReplicationInfo.PlayerID)) != "")
					P.Destroy();
		}
	}

	if (USL >= SAM.USLServerMinPLayers)
	{
		MinPlay = DeathMatchPlus(Level.Game).MinPlayers;
		
		if (Request.GetVariable("SetMinPlayers", "") != "")
		{
			MinPlay = Min(Max(int(Request.GetVariable("MinPlayers", String(0))), 0), 16);
			DeathMatchPlus(Level.Game).MinPlayers = MinPlay;
			Level.Game.SaveConfig();
		}
		
		Response.Subst("MinPlaySubst", "<div align=\"right\">Minimum&nbsp;players:&nbsp;&nbsp;<input type=\"text\" name=\"MinPlayers\" size=\"2\" maxlength=\"2\" value=\""$MinPlay$"\">&nbsp;<input type=\"submit\" name=\"SetMinPlayers\" value=\"Set\"></div>");
	}
	else Response.Subst("MinPlaySubst", "<div align=\"right\">&nbsp;</div>");
	
	for (P=Level.PawnList; P!=None; P=P.NextPawn) {
		if (P.bIsPlayer && !P.bDeleteMe && SemiAdminSpectator(P) == None) {
			PawnCount++;
			TempItem = new(None) class'ListItem';
		    TimeOn = Max(1, (Level.TimeSeconds - P.PlayerReplicationInfo.StartTime));
		    TimeOnS = string(int(TimeOn/60 - 0.5));
		    if ((TimeOn % 60) < 10 )
    		    TimeOnS = TimeOnS $":0"$ string(int(TimeOn % 60));
		    else
		        TimeOnS = TimeOnS $":"$ string(int(TimeOn % 60));
		        
		    FPH = 3600 * P.PlayerReplicationInfo.Score / TimeOn;

			if (P.PlayerReplicationInfo.bIsABot) {
				TempItem.Data = "<tr><td width=\"1%\">&nbsp;</td>";
				TempStr = "&nbsp;(Bot)";
				TempTeam = TeamColor(P.PlayerReplicationInfo.Team);
			}
			else {
				TempItem.Data = "<tr><td align=\"right\" width=\"1%\"><input type=\"checkbox\" name=\"KickPlayer"$P.PlayerReplicationInfo.PlayerID$"\" value=\"kick\"></td>";
				if (P.PlayerReplicationInfo.bIsSpectator)
				{
					TempStr = "&nbsp;(Spectator)";
					TempTeam = "";
				}
				else
				{
					TempStr = "";
					TempTeam = TeamColor(P.PlayerReplicationInfo.Team);
				}
			}
			if(PlayerPawn(P) != None)
			{
				IP = PlayerPawn(P).GetPlayerNetworkAddress();
				IP = Left(IP, InStr(IP, ":"));
			}
			else
				IP = "";
			TempItem.Data = TempItem.Data$"<td align=\"left\">"$P.PlayerReplicationInfo.PlayerName$TempStr$"</td><td align=\"center\" width=\"1%\" bgcolor='"$TempTeam$"'>&nbsp;"$TempTeam$"&nbsp;</td><td align=\"center\" width=\"1%\">"$P.PlayerReplicationInfo.Ping$"</td><td align=\"center\" width=\"1%\">"$int(P.PlayerReplicationInfo.Score)$"</td><td align=\"center\" width=\"1%\">"$int(FPH)$"</td><td align=\"center\" width=\"1%\">"$TimeOnS$"</td><td align=\"center\" width=\"1%\">"$IP$"</td></tr>";

			switch (Sort) {
				case "FPH":
					TempItem.Tag = PadLeft(String(int(FPH)), 5, "0"); break;
				case "TimeOn":
					TempItem.Tag = String(TimeOn); break;
				case "Name":
					TempItem.Tag = P.PlayerReplicationInfo.PlayerName; break;
				case "Team":
					TempItem.Tag = PadLeft(P.PlayerReplicationInfo.TeamName, 2, "0"); break;
				case "Ping":
					TempItem.Tag = PadLeft(String(P.PlayerReplicationInfo.Ping), 4, "0"); break;
				default:
					TempItem.Tag = PadLeft(String(int(P.PlayerReplicationInfo.Score)), 3, "0"); break;
				}
			if (PlayerList == None)
				PlayerList = TempItem;
			else
				PlayerList.AddSortedElement(PlayerList, TempItem);
		}
	}
	if (PawnCount > 0) {
		if (Sort ~= "Score" || Sort ~= "FPH" || Sort ~= "TimeOn")
			for (TempItem=PlayerList; TempItem!=None; TempItem=TempItem.Next)
				PlayerListSubst = TempItem.Data$PlayerListSubst;

		else
			for (TempItem=PlayerList; TempItem!=None; TempItem=TempItem.Next)
				PlayerListSubst = PlayerListSubst$TempItem.Data;
	}
	else
		PlayerListSubst = "<tr align=\"center\"><td colspan=\"4\">** No Players Connected **</td></tr>";

	Response.Subst("PlayerList", PlayerListSubst);
	Response.Subst("CurrentGame", Level.Game.GameReplicationInfo.GameName$" in "$Level.Title);
	Response.Subst("PostAction", GamePlayerKickPage);
	Response.Subst("Sort", Sort);
	Response.Subst("ServerName", GetServerName());
	
	Response.IncludeUHTM(SubPath$GamePlayerKickPage$".uhtm");
}

function QueryGamePlayerBan(WebRequest Request, WebResponse Response)
{
	local string Sort, PlayerListSubst, TempStr, TempTeam, IP, TimeOnS;
	local ListItem PlayerList, TempItem;
	local Pawn P;
	local int i, PawnCount, j, MinPlay;
	local float TimeOn,FPH;
	
	local int GAL,USL;
	
		USL = SAM.CurrentUserSecLevel();
	
	Sort = Request.GetVariable("Sort", "Name");
	
	if (USL >= SAM.USLServerMinPLayers)
	{
		MinPlay = DeathMatchPlus(Level.Game).MinPlayers;
	
		if (Request.GetVariable("SetMinPlayers", "") != "")
		{
			MinPlay = Min(Max(int(Request.GetVariable("MinPlayers", String(0))), 0), 16);
			DeathMatchPlus(Level.Game).MinPlayers = MinPlay;
			Level.Game.SaveConfig();
		}
		
		Response.Subst("MinPlaySubst", "<div align=\"right\">Minimum&nbsp;players:&nbsp;&nbsp;<input type=\"text\" name=\"MinPlayers\" size=\"2\" maxlength=\"2\" value=\""$MinPlay$"\">&nbsp;<input type=\"submit\" name=\"SetMinPlayers\" value=\"Set\"></div>");
	}
	else Response.Subst("MinPlaySubst", "<div align=\"right\">&nbsp;</div>");
	
	
	for (P=Level.PawnList; P!=None; P=P.NextPawn)
	{
		if(		PlayerPawn(P) != None
			&&	P.PlayerReplicationInfo != None
			&&	NetConnection(PlayerPawn(P).Player) != None)
		{
			if(Request.GetVariable("BanPlayer"$string(P.PlayerReplicationInfo.PlayerID)) != "")
			{
				IP = PlayerPawn(P).GetPlayerNetworkAddress();
				if(Level.Game.CheckIPPolicy(IP))
				{
					IP = Left(IP, InStr(IP, ":"));
					WriteLog("Adding IP Ban for: "$IP);
					for(j=0;j<50;j++)
						if(Level.Game.IPPolicies[j] == "")
							break;
					if(j < 50)
						Level.Game.IPPolicies[j] = "DENY,"$IP;
					Level.Game.SaveConfig();
				}
				P.Destroy();
			}
		}
	}

	for (P=Level.PawnList; P!=None; P=P.NextPawn) {
		if (P.bIsPlayer && !P.bDeleteMe && SemiAdminSpectator(P) == None) {
			PawnCount++;
			TempItem = new(None) class'ListItem';

		    
		    TimeOn = Max(1, (Level.TimeSeconds - P.PlayerReplicationInfo.StartTime));
		    TimeOnS = string(int(TimeOn/60 - 0.5));
		    if ((TimeOn % 60) < 10 )
    		    TimeOnS = TimeOnS $":0"$ string(int(TimeOn % 60));
		    else
		        TimeOnS = TimeOnS $":"$ string(int(TimeOn % 60));
		        
		    FPH = 3600 * P.PlayerReplicationInfo.Score / TimeOn;
		    
			if (P.PlayerReplicationInfo.bIsABot) {
				TempItem.Data = "<tr><td width=\"1%\">&nbsp;</td>";
				TempStr = "&nbsp;(Bot)";
				TempTeam = TeamColor(P.PlayerReplicationInfo.Team);

				
			}
			else {
				TempItem.Data = "<tr><td align=\"right\" width=\"1%\"><input type=\"checkbox\" name=\"BanPlayer"$P.PlayerReplicationInfo.PlayerID$"\" value=\"ban\"></td>";
				if (P.PlayerReplicationInfo.bIsSpectator)
				{
					TempStr = "&nbsp;(Spectator)";
					TempTeam = "";
				}
				else
				{
					TempStr = "";
					TempTeam = TeamColor(P.PlayerReplicationInfo.Team);
				}
			}
			if(PlayerPawn(P) != None)
			{
				IP = PlayerPawn(P).GetPlayerNetworkAddress();
				IP = Left(IP, InStr(IP, ":"));
			}
			else
				IP = "";
			TempItem.Data = TempItem.Data$"<td align=\"left\">"$P.PlayerReplicationInfo.PlayerName$TempStr$"</td><td align=\"center\" width=\"1%\" bgcolor='"$TempTeam$"'>&nbsp;<font color=\"#000000\">"$TempTeam$"</font>&nbsp;</td><td align=\"center\" width=\"1%\">"$P.PlayerReplicationInfo.Ping$"</td><td align=\"center\" width=\"1%\">"$int(P.PlayerReplicationInfo.Score)$"</td><td align=\"center\" width=\"1%\">"$int(FPH)$"</td><td align=\"center\" width=\"1%\">"$TimeOnS$"</td><td align=\"center\" width=\"1%\">"$IP$"</td></tr>";
			switch (Sort) {
				case "FPH":
					TempItem.Tag = PadLeft(String(int(FPH)), 5, "0"); break;
				case "TimeOn":
					TempItem.Tag = String(TimeOn); break;
				case "Name":
					TempItem.Tag = P.PlayerReplicationInfo.PlayerName; break;
				case "Team":
					TempItem.Tag = PadLeft(P.PlayerReplicationInfo.TeamName, 2, "0"); break;
				case "Ping":
					TempItem.Tag = PadLeft(String(P.PlayerReplicationInfo.Ping), 4, "0"); break;
				default:
					TempItem.Tag = PadLeft(String(int(P.PlayerReplicationInfo.Score)), 3, "0"); break;
				}
			if (PlayerList == None)
				PlayerList = TempItem;
			else
				PlayerList.AddSortedElement(PlayerList, TempItem);
		}
	}
	if (PawnCount > 0) 
	{
		if (Sort ~= "Score" || Sort ~= "FPH" || Sort ~= "TimeOn")
			for (TempItem=PlayerList; TempItem!=None; TempItem=TempItem.Next)
				PlayerListSubst = TempItem.Data$PlayerListSubst;

		else
			for (TempItem=PlayerList; TempItem!=None; TempItem=TempItem.Next)
				PlayerListSubst = PlayerListSubst$TempItem.Data;
	}
	else
		PlayerListSubst = "<tr align=\"center\"><td colspan=\"4\">** No Players Connected **</td></tr>";

	Response.Subst("PlayerList", PlayerListSubst);
	Response.Subst("CurrentGame", Level.Game.GameReplicationInfo.GameName$" in "$Level.Title);
	Response.Subst("PostAction", GamePlayerBanPage);
	Response.Subst("Sort", Sort);
	Response.Subst("ServerName", GetServerName());
	
	Response.Subst("MinPlayers", String(DeathMatchPlus(Level.Game).MinPlayers));
	Response.IncludeUHTM(SubPath$GamePlayerBanPage$".uhtm");
}



function QueryGamePlayerWhip(WebRequest Request, WebResponse Response)
{
	local string Sort, PlayerListSubst, TempStr, TempTeam, IP,reasonCode;
	local ListItem PlayerList, TempItem;
	local Pawn P;
	local int i, PawnCount, j, MinPlay, pID;
	local bool bWarn, bMute, bUnMute, bZeroFrag, bRespawn;
	
	local int GAL,USL;
	
	USL = SAM.CurrentUserSecLevel();
	
	Sort = Request.GetVariable("Sort", "Name");
	
	if (USL >= SAM.USLServerMinPLayers)
	{
		MinPlay = DeathMatchPlus(Level.Game).MinPlayers;
	
		if (Request.GetVariable("SetMinPlayers", "") != "")
		{
			MinPlay = Min(Max(int(Request.GetVariable("MinPlayers", String(0))), 0), 16);
			DeathMatchPlus(Level.Game).MinPlayers = MinPlay;
			Level.Game.SaveConfig();
		}
		
		Response.Subst("MinPlaySubst", "<div align=\"right\">Minimum&nbsp;players:&nbsp;&nbsp;<input type=\"text\" name=\"MinPlayers\" size=\"2\" maxlength=\"2\" value=\""$MinPlay$"\">&nbsp;<input type=\"submit\" name=\"SetMinPlayers\" value=\"Set\"></div>");
	}
	else Response.Subst("MinPlaySubst", "<div align=\"right\">&nbsp;</div>");
	
	
	for (P=Level.PawnList; P!=None; P=P.NextPawn)
	{
		if(		PlayerPawn(P) != None
			&&	P.PlayerReplicationInfo != None
			&&	NetConnection(PlayerPawn(P).Player) != None)
		{
    	    bWarn=false;
    	    bMute=false;
    	    bUnmute=false;
    	    bRespawn=false;
    	    bZeroFrag=false;
		    pID=P.PlayerReplicationInfo.PlayerID;
			if(Request.GetVariable("WarnPlayer"$string(pID)) != "")
			    bWarn=true;
			if(Request.GetVariable("MutePlayer"$string(pID)) != "")
			    bMute=true;
			if(Request.GetVariable("UnMutePlayer"$string(pID)) != "")
			    bUnMute=true;
			if(Request.GetVariable("RespawnPlayer"$string(pID)) != "")
			    bRespawn=true;
			if(Request.GetVariable("ZeroFragPlayer"$string(pID)) != "")
			    bZeroFrag=true;
            reasonCode=Request.GetVariable("ReasonCode"$string(pID))		    ;
			
			//log("pId="$pid@"bwarn="$bwarn@"bmute="$bmute@"bunmute="$bunmute@"brespawn="$brespawn@"bzerofrag="$bzerofrag@"reasoncode="$reasoncode);
		    SAM.Params[0]="private";
		    SAM.Params[1]=reasonCode;
		    SAM.Params[2]=string(pId);
		    SAM.NumParams=3;
		    
			if (bWarn)
			    SAM.LogMessage(SAM.SA_ActionById(SAM.SA_Action.Warning));
			if (bMute)
			    SAM.LogMessage(SAM.SA_ActionById(SAM.SA_Action.Mute));
			if (bUnMute)
			    SAM.LogMessage(SAM.SA_ActionById(SAM.SA_Action.Unmute));
			if (bReSpawn)
			    SAM.LogMessage(SAM.SA_ActionById(SAM.SA_Action.Respawn));
			if (bZeroFrag)
			    SAM.LogMessage(SAM.SA_ActionById(SAM.SA_Action.ZeroFrag));


		}
	}

	for (P=Level.PawnList; P!=None; P=P.NextPawn) {
		if (P.bIsPlayer && !P.bDeleteMe && SemiAdminSpectator(P) == None) {
			PawnCount++;
			TempItem = new(None) class'ListItem';

			if (P.PlayerReplicationInfo.bIsABot) {
				TempItem.Data = "<tr><td width=\"1%\">&nbsp;</td><td width=\"1%\">&nbsp;</td><td width=\"1%\">&nbsp;</td><td width=\"1%\">&nbsp;</td><td width=\"1%\">&nbsp;</td>";
				TempStr = "&nbsp;(Bot)";
				TempTeam = TeamColor(P.PlayerReplicationInfo.Team);
			}
			else {
				TempItem.Data =           "<tr><td align=\"center\" width=\"1%\"><input type=\"checkbox\" name=\"WarnPlayer"$P.PlayerReplicationInfo.PlayerID$"\" value=\"True\"></td>";
				TempItem.Data = TempItem.Data$"<td align=\"center\" width=\"1%\"><input type=\"checkbox\" name=\"MutePlayer"$P.PlayerReplicationInfo.PlayerID$"\" value=\"True\"></td>";
				TempItem.Data = TempItem.Data$"<td align=\"center\" width=\"1%\"><input type=\"checkbox\" name=\"UnMutePlayer"$P.PlayerReplicationInfo.PlayerID$"\" value=\"True\"></td>";
				TempItem.Data = TempItem.Data$"<td align=\"center\" width=\"1%\"><input type=\"checkbox\" name=\"RespawnPlayer"$P.PlayerReplicationInfo.PlayerID$"\" value=\"True\"></td>";
				TempItem.Data = TempItem.Data$"<td align=\"center\" width=\"1%\"><input type=\"checkbox\" name=\"ZeroFragPlayer"$P.PlayerReplicationInfo.PlayerID$"\" value=\"True\"></td>";

				if (P.PlayerReplicationInfo.bIsSpectator)
				{
					TempStr = "&nbsp;(Spectator)";
					TempTeam = "";
				}
				else
				{
					TempStr = "";
					TempTeam = TeamColor(P.PlayerReplicationInfo.Team);
				}
			}
			if(PlayerPawn(P) != None)
			{
				IP = PlayerPawn(P).GetPlayerNetworkAddress();
				IP = Left(IP, InStr(IP, ":"));
			}
			else
				IP = "";
				
			TempItem.Data = TempItem.Data$"<td align=\"left\">"$P.PlayerReplicationInfo.PlayerName$TempStr$"</td>";
			TempItem.Data = TempItem.Data$"<td align=\"center\" width=\"1%\" bgcolor='"$TempTeam$"'>&nbsp;<font color=\"#000000\">"$TempTeam$"</font>&nbsp;</td>";
			TempItem.Data = TempItem.Data$"<td align=\"center\" width=\"1%\">"$P.PlayerReplicationInfo.Ping$"</td>";
			TempItem.Data = TempItem.Data$"<td align=\"center\" width=\"1%\">"$int(P.PlayerReplicationInfo.Score)$"</td>";
//			TempItem.Data = TempItem.Data$"<td align=\"center\" width=\"1%\">"$IP$"</td>";
			if (P.PlayerReplicationInfo.bIsABot) 			
    			TempItem.Data = TempItem.Data$"</tr>";
			else
    			TempItem.Data = TempItem.Data$"<td align=\"left\"><select name=\"ReasonCode"$P.PlayerReplicationInfo.PlayerID$"\">"$GenerateReasonOptions()$"</select></td></tr>";

			switch (Sort) {
				case "Name":
					TempItem.Tag = P.PlayerReplicationInfo.PlayerName; break;
				case "Team":
					TempItem.Tag = PadLeft(P.PlayerReplicationInfo.TeamName, 2, "0"); break;
				case "Ping":
					TempItem.Tag = PadLeft(String(P.PlayerReplicationInfo.Ping), 4, "0"); break;
				default:
					TempItem.Tag = PadLeft(String(int(P.PlayerReplicationInfo.Score)), 3, "0"); break;
				}
			if (PlayerList == None)
				PlayerList = TempItem;
			else
				PlayerList.AddSortedElement(PlayerList, TempItem);
		}
	}
	if (PawnCount > 0) 
	{
		if (Sort ~= "Score")
			for (TempItem=PlayerList; TempItem!=None; TempItem=TempItem.Next)
				PlayerListSubst = TempItem.Data$PlayerListSubst;

		else
			for (TempItem=PlayerList; TempItem!=None; TempItem=TempItem.Next)
				PlayerListSubst = PlayerListSubst$TempItem.Data;
	}
	else
		PlayerListSubst = "<tr align=\"center\"><td colspan=\"10\">** No Players Connected **</td></tr>";

	Response.Subst("WhipPlayerList", PlayerListSubst);
	Response.Subst("CurrentGame", Level.Game.GameReplicationInfo.GameName$" in "$Level.Title);
	Response.Subst("PostAction", GamePlayerWhipPage);
	Response.Subst("Sort", Sort);
	Response.Subst("ServerName", GetServerName());
	
	Response.Subst("MinPlayers", String(DeathMatchPlus(Level.Game).MinPlayers));
	Response.IncludeUHTM(SubPath$GamePlayerWhipPage$".uhtm");
}


function QueryGameLev(WebRequest Request, WebResponse Response)
{
local ListItem IncludeMaps, ExcludeMaps;
local class<GameInfo> GameClass;
local string NewGameType, SwitchButtonName, MapListSelect, CurrentMap;
local bool bMakeChanges;
local int GAL,USL;
	
		USL = SAM.CurrentUserSecLevel();
	
	if (Request.GetVariable("SwitchGameTypeAndMap", "") != "")
	{
		Level.ServerTravel(Request.GetVariable("MapSelect")$"?game="$Request.GetVariable("GameTypeSelect"), false);
		MessagePage(Response, "Please Wait", "The server is now switching to map '"$Request.GetVariable("MapSelect")$"' and game type '"$Request.GetVariable("GameTypeSelect")$"'.  Please allow 10-15 seconds while the server changes levels.");
		return;
	}
	else if (Request.GetVariable("SwitchMap", "") != "")
	{
		Level.ServerTravel(Request.GetVariable("MapSelect")$"?game="$Level.Game.Class, false);
		MessagePage(Response, "Please Wait", "The server is now switching to map '"$Request.GetVariable("MapSelect")$"'.    Please allow 10-15 seconds while the server changes levels.");
		return;
	}
	
 	bMakeChanges = (Request.GetVariable("ApplySettings", "") != "");
	
	if (bMakeChanges || Request.GetVariable("SwitchGameType", "") != "")
	{
		NewGameType = Request.GetVariable("GameTypeSelect");
		GameClass = class<GameInfo>(DynamicLoadObject(NewGameType, class'Class'));
	}
	else
	{
		GameClass=Level.Game.Class;
		NewGameType=String(GameClass);
	}
	
	ReloadExcludeMaps(ExcludeMaps, NewGameType);
	ReloadIncludeMaps(ExcludeMaps, IncludeMaps, NewGameType);
	
	if (GameClass == Level.Game.Class)
	{
		SwitchButtonName="SwitchMap";
		CurrentMap=Left(string(Level), InStr(string(Level), "."))$".unr";
	}
	else
		SwitchButtonName="SwitchGameTypeAndMap";
	
	
	Response.Subst("GameTypeSelect", "<select name=\"GameTypeSelect\" disabled>"$GenerateGameTypeOptions(NewGameType)$"</select>");
    if (USL<SAM.USLGameTypeChange)
    {
	    Response.Subst("GameTypeSelect", "<select name=\"GameTypeSelect\" disabled>"$GenerateGameTypeOptions(NewGameType)$"</select>");
//	    Response.Subst("GameTypeButton", "<input type=\"submit\" name=\"SwitchGameType\" value=\"Switch\">");
	} else {
	    Response.Subst("GameTypeSelect", "<select name=\"GameTypeSelect\">"$GenerateGameTypeOptions(NewGameType)$"</select>");
	    Response.Subst("GameTypeButton", "<input type=\"submit\" name=\"SwitchGameType\" value=\"Switch\">");
    }
    if (USL<SAM.USLMapChange)
    {
    	Response.Subst("MapSelect", "<select name=\"MapSelect\" disabled>"$GenerateMapListSelect(IncludeMaps, CurrentMap)$"</select>");
//    	Response.Subst("MapButton", "<input type='submit' name='"$SwitchButtonName$"' value=\"Switch\">");
    } else {
    	Response.Subst("MapSelect", "<select name=\"MapSelect\">"$GenerateMapListSelect(IncludeMaps, CurrentMap)$"</select>");
    	Response.Subst("MapButton", "<input type='submit' name='"$SwitchButtonName$"' value=\"Switch\">");
    }
	Response.Subst("PostAction", GamePageLev);
	Response.Subst("CurrentGame", Level.Game.GameReplicationInfo.GameName$" in "$Level.Title);
	Response.Subst("GameParameters", GetSetGameInfo(Request, NewGameType, bMakeChanges));
	Response.Subst("ServerName", GetServerName());
	
	Response.IncludeUHTM(SubPath$GamePageLev$".uhtm");
}

function QueryGameBot(WebRequest Request, WebResponse Response)
{
	local string OutStr, Col1Str, Col2Str, str;
	local string BotLines[32], LeftList, RightList;
	local DeathMatchPlus	DMP;
	local Pawn aPawn;
	local ListItem TempItem;
	local int i, BotCount, maxbots;
	local bool oldstate, newstate;
	local int USL;
	
    USL = SAM.CurrentUserSecLevel();

	if (FullBotListItem == None)
	{
		LoadBotsList();
	}
	
	DMP = DeathMatchPlus(Level.Game);
	if (DMP == None)
	{
		Response.Subst("Title", "Unsupported Game Type");
		Response.Subst("Message", "The Game Type '"$Level.Game.Class$"' is not supported by SemiAdmin");
		Response.IncludeUHTM(SubPath$MessageUHTM);
		return;
	}
	
	
	if (Request.GetVariable("addbotnum", "") != "" && USL>=SAM.USLAddRemoveBots)
	{
		BotCount = int(Request.GetVariable("addnum", "0"));
		if (Request.GetVariable("BotAction", "") == "Add")
		{
			maxbots = 32-(DMP.NumPlayers + DMP.NumBots);
			
			BotCount = Clamp(BotCount, 0, maxbots);
			for (i=0;i<BotCount; i++)
				DMP.ForceAddBot();
		
			// Save the change
		
			if (BotCount == 0)
				StatusError(Response, "No Bots were Added");
			else if (BotCount == 1)
				StatusOk(Response, "1 Bot was Added");
			else				
				StatusOk(Response, BotCount@"Bots were added");
		}
		else if (Request.GetVariable("BotAction", "") == "Remove"  && USL>=SAM.USLAddRemoveBots)
		{
			BotCount = Clamp(BotCount, 0, DMP.NumBots);
		
			DMP.MinPlayers = DMP.NumPlayers + DMP.NumBots - BotCount;
			if (BotCount == 0)
				StatusError(Response, "No Bots Were Removed, They will quit soon");
			else if (BotCount == 1)
				StatusOk(Response, "1 Bot was Removed, it will quit soon");
			else
				StatusOk(Response, BotCount@"Bots were Removed, They will quit soon");
		}
		DMP.SaveConfig();	
	}
	else if (Request.GetVariable("selectbots", "") != ""  && USL>=SAM.USLAddRemoveBots)
	{
		// Read as many bot infos as available
		for (i=0; i<32; i++)
		{
			oldstate=Request.GetVariable("BotX"$i, "") != "";
			newstate=Request.GetVariable("Bot"$i, "") != "";
			
			if (oldstate != newstate)
			{
				if (oldstate)	// remove the bot
				{
					aPawn = FindPlayerByName(DMP.BotConfig.GetBotName(i));
					if (aPawn != None && aPawn.PlayerReplicationInfo.bIsABot)
					{
						DMP.MinPlayers = DMP.NumPlayers + DMP.NumBots - 1;
						aPawn.Destroy();
					}
				}
				else
				{
					DMP.BotConfig.DesiredName = DMP.BotConfig.GetBotName(i);
					Level.Game.ForceAddBot();
				}
			}
		}
		DMP.SaveConfig();
	}

	// Now Build the Bot List
	BotCount=0;
	for (TempItem=FullBotListItem; TempItem!=None; TempItem=TempItem.Next)
	{
		aPawn = FindPlayerByName(TempItem.Tag, true);
		newstate = ( aPawn != None );
	
		str = "<td>";
		if (newstate)
			str = str$"<input type='hidden' name='BotX"$TempItem.Data$"' value='1'>";
		str = str$"<input type='checkbox' name='Bot"$TempItem.Data$"' value='1'";
		if (newstate)
			str = str$" checked";
		str = str$">&nbsp;"$TempItem.Tag$"</td>";
		if (newstate)
			str = str$"<td align=\"center\" bgcolor='"$TeamColor(aPawn.PlayerReplicationInfo.Team)$"'>&nbsp;<font color=\"#000000\">"$TeamColor(aPawn.PlayerReplicationInfo.Team)$"</font>&nbsp;</td>";
		else
			str=str$"<td>&nbsp;</td>";
		BotLines[BotCount++] = str;
	}
	
	LeftList = "";
	RightList = "";
	maxbots = (BotCount+1)/2;
	for (i=0; i<maxbots; i++)
	{
		LeftList = LeftList $ "<tr>" $ BotLines[i] $ "</tr>";
		if (i+maxbots < BotCount)
			RightList = RightList $"<tr>"$ BotLines[i+maxbots]$"</tr>";
	}
	Response.Subst("LeftBotList", LeftList);
	Response.Subst("RightBotList", RightList);
	Response.Subst("PostAction", GameBotPage);
	Response.Subst("ServerName", GetServerName());
	
	Response.IncludeUHTM(SubPath$GameBotPage$".uhtm");	
}

function QueryGameMutators(WebRequest Request, WebResponse Response)
{
	local ListItem TempItem;
	local int Count, i;
    local int GAL,USL;
	
		USL = SAM.CurrentUserSecLevel();
	
	if (Request.GetVariable("AddMutator", "") != "") {
		Count = Request.GetVariableCount("ExcludeMutatorsSelect");
		for (i=0; i<Count; i++)
		{
			if (ExcludeMutators != None)
			{
				TempItem = ExcludeMutators.DeleteElement(ExcludeMutators, Request.GetVariableNumber("ExcludeMutatorsSelect", i));
				if (TempItem != None)
				{
					TempItem.bJustMoved = true;
					if (IncludeMutators == None)
						IncludeMutators = TempItem;
					else
						IncludeMutators.AddElement(TempItem);
				}
				else
					WriteLog("Exclude mutator not found: "$Request.GetVariableNumber("ExcludeMutatorsSelect", i));
			}
		}
	}
	else if (Request.GetVariable("DelMutator", "") != "") {
		Count = Request.GetVariableCount("IncludeMutatorsSelect");
		for (i=0; i<Count; i++)
		{
			if (IncludeMutators != None)
			{
				TempItem = IncludeMutators.DeleteElement(IncludeMutators, Request.GetVariableNumber("IncludeMutatorsSelect", i));
				if (TempItem != None)
				{
					TempItem.bJustMoved = true;
					if (ExcludeMutators == None)
						ExcludeMutators = TempItem;
					else
						ExcludeMutators.AddSortedElement(ExcludeMutators, TempItem);
				}
				else
					WriteLog("Include mutator not found: "$Request.GetVariableNumber("IncludeMutatorsSelect", i));
			}
		}
	}
	else if (Request.GetVariable("AddAllMutators", "") != "")
	{
		while (ExcludeMutators != None)
		{
			TempItem = ExcludeMutators.DeleteElement(ExcludeMutators);
			if (TempItem != None)
			{
				TempItem.bJustMoved = true;
				if (IncludeMutators == None)
					IncludeMutators = TempItem;
				else
					IncludeMutators.AddElement(TempItem);
			}
		}
	}
	else if (Request.GetVariable("DelAllMutators", "") != "")
	{
		while (IncludeMutators != None)
		{
			TempItem = IncludeMutators.DeleteElement(IncludeMutators);
			if (TempItem != None)
			{
				TempItem.bJustMoved = true;
				if (ExcludeMutators == None)
					ExcludeMutators = TempItem;
				else
					ExcludeMutators.AddSortedElement(ExcludeMutators, TempItem);
			}
		}
	}
    if (USL<SAM.USLMutatorsChange)
        Response.Subst("ExcludeMutatorsOptions","<select name=\"ExcludeMutatorsSelect\" size=\"9\" disabled>"$GenerateMutatorListSelect(ExcludeMutators)$"</select>");
    else
	    Response.Subst("ExcludeMutatorsOptions","<select name=\"ExcludeMutatorsSelect\" size=\"9\" multiple>"$GenerateMutatorListSelect(ExcludeMutators)$"</select>");
	
    if (USL<SAM.USLMutatorsChange)
    	Response.Subst("IncludeMutatorsOptions", "<select name=\"IncludeMutatorsSelect\" size=\"9\" disabled>"$GenerateMutatorListSelect(IncludeMutators)$"</select>");
    else
    	Response.Subst("IncludeMutatorsOptions", "<select name=\"IncludeMutatorsSelect\" size=\"9\" multiple>"$GenerateMutatorListSelect(IncludeMutators)$"</select>");
	
	Response.Subst("PostAction", GameMutatorPage);
	Response.Subst("ServerName", GetServerName());
	
	Response.IncludeUHTM(SubPath$GameMutatorPage$".uhtm");
	
}

function LoadMutators()
{
	local int NumMutatorClasses;
	local string NextMutator, NextDesc;
	local listitem TempItem;
	local Mutator M;
	local int j;
	local int k;

	ExcludeMutators = None;

	Level.GetNextIntDesc("Engine.Mutator", 0, NextMutator, NextDesc);
	while( (NextMutator != "") && (NumMutatorClasses < 50) )
	{
		TempItem = new(None) class'ListItem';
		
		k = InStr(NextDesc, ",");
		if (k == -1)
			TempItem.Tag = NextDesc;
		else
			TempItem.Tag = Left(NextDesc, k);

		TempItem.Data = NextMutator;

		if (ExcludeMutators == None)
			ExcludeMutators = TempItem;
		else
			ExcludeMutators.AddSortedElement(ExcludeMutators, TempItem);
		NumMutatorClasses++;
		Level.GetNextIntDesc("Engine.Mutator", NumMutatorClasses, NextMutator, NextDesc);
	}

	IncludeMutators = None;
	
	for (M = Level.Game.BaseMutator.NextMutator; M != None; M = M.NextMutator) {
		TempItem = ExcludeMutators.DeleteElement(ExcludeMutators, String(M.Class));
		
		if (TempItem != None) {
			if (IncludeMutators == None)
				IncludeMutators = TempItem;
			else
				IncludeMutators.AddElement(TempItem);
		}
		else
			WriteLog("Unknown Mutator in use: "@String(M.Class));
	}
}

function String UsedMutators()
{
	local ListItem TempItem;
	local String OutStr;
	
	if(IncludeMutators == None)
		return "";

	OutStr = IncludeMutators.Data;
	for (TempItem = IncludeMutators.Next; TempItem != None; TempItem = TempItem.Next)
	{
		OutStr = OutStr$","$TempItem.Data;
	}
	
	return OutStr;
}

function String GenerateMutatorListSelect(ListItem MutatorList)
{
	local ListItem TempItem;
	local String ResponseStr, SelectedStr;
	
	if (MutatorList == None)
		return "<option value=\"\">*** None ***</option>";
		
	for (TempItem = MutatorList; TempItem != None; TempItem = TempItem.Next) {
		SelectedStr = "";
		if (TempItem.bJustMoved) {
			SelectedStr = " selected";
			TempItem.bJustMoved=false;
		}
		ResponseStr = ResponseStr$"<option value=\""$TempItem.Data$"\""$SelectedStr$">"$TempItem.Tag$"</option>";
	}
	return ResponseStr;
}

function QueryGameConsole(WebRequest Request, WebResponse Response)
{
	local String SendStr, OutStr;

	SendStr = Request.GetVariable("SendText", "");
	if (SendStr != "") {
        Spectator.BroadcastMessage(SAM.Admin.User.Name$": "$SendStr);
/*
		if (Left(SendStr, 4) ~= "say ")
			Spectator.BroadcastMessage(SAM.Admin.User.Name$": "$Mid(SendStr, 4));
		else {
			OutStr = Level.ConsoleCommand(SendStr);
			if (OutStr != "")
				Spectator.AddMessage(None, OutStr, 'Console');
		}
*/
	}
	
	Response.Subst("LogURI", GameConsoleLogPage);
	Response.Subst("SayURI", GameConsoleSendPage);
	Response.Subst("ServerName", GetServerName());
	
	Response.IncludeUHTM(SubPath$GameConsolePage$".uhtm");
}

function QueryGameConsoleLog(WebRequest Request, WebResponse Response)
{
	local ListItem TempItem;
	local String LogSubst, LogStr;
	local int i;

	for (TempItem = Spectator.MessageList; TempItem != None; TempItem = TempItem.Next)
		LogSubst = LogSubst$"&gt; "$TempItem.Data$"<br>";
	
	Response.Subst("LogRefresh", WebServer.ServerURL$Path$"/"$GameConsoleLogPage$"#END");
	Response.Subst("LogText", LogSubst);
	Response.Subst("ServerName", GetServerName());
	
	Response.IncludeUHTM(SubPath$GameConsoleLogPage$".uhtm");
}

function QueryGameConsoleSend(WebRequest Request, WebResponse Response)
{
//	Response.Subst("DefaultSendText", DefaultSendText);
	Response.Subst("PostAction", GameConsolePage);
	Response.Subst("ServerName", GetServerName());
	
	Response.IncludeUHTM(SubPath$GameConsoleSendPage$".uhtm");
}

function QueryGameMaps(WebRequest Request, WebResponse Response)
{
	local String GameType, MapListType;
	local ListItem ExcludeMaps, IncludeMaps, TempItem;
	local int i, Count, MoveCount;
    local int GAL,USL;
	
		USL = SAM.CurrentUserSecLevel();
	
	// load saved entries from the page	
	GameType = Request.GetVariable("GameType");	// provided by index page
	MapListType = Request.GetVariable("MapListType", "Custom");
	if (GameType == "")
		GameType = String(Level.Game.Class);
	
	WriteLog("GameType="$GameType);
	WriteLog("MapListType="$MapListType);
	
	ReloadExcludeMaps(ExcludeMaps, GameType);
	ReloadIncludeMaps(ExcludeMaps, IncludeMaps, GameType);

	if (Request.GetVariable("MapListSet", "") != "" && USL>=SAM.USLMapListChange) {
		MapListType = Request.GetVariable("MapListSelect", "Custom");
		if (MapListType != "Custom")
		{
			ApplyMapList(ExcludeMaps, IncludeMaps, GameType, MapListType);
			
			UpdateDefaultMaps(GameType, IncludeMaps);
		}
	}
	else if (Request.GetVariable("AddMap", "") != "") {
		Count = Request.GetVariableCount("ExcludeMapsSelect");
		for (i=0; i<Count; i++)
		{
			if (ExcludeMaps != None)
			{
				TempItem = ExcludeMaps.DeleteElement(ExcludeMaps, Request.GetVariableNumber("ExcludeMapsSelect", i));
				if (TempItem != None)
				{
					TempItem.bJustMoved = true;
					if (IncludeMaps == None)
						IncludeMaps = TempItem;
					else
						IncludeMaps.AddElement(TempItem);
				}
				else
					WriteLog("Exclude map not found: "$Request.GetVariableNumber("ExcludeMapsSelect", i));
			}
		}
		MapListType = "Custom";
		UpdateDefaultMaps(GameType, IncludeMaps);
	}
	else if (Request.GetVariable("DelMap", "") != "" && Request.GetVariableCount("IncludeMapsSelect") > 0) {
		Count = Request.GetVariableCount("IncludeMapsSelect");
		for (i=0; i<Count; i++)
		{
			if (IncludeMaps != None)
			{
				TempItem = IncludeMaps.DeleteElement(IncludeMaps, Request.GetVariableNumber("IncludeMapsSelect", i));
				if (TempItem != None)
				{
					TempItem.bJustMoved = true;
					if (ExcludeMaps == None)
						ExcludeMaps = TempItem;
					else
						ExcludeMaps.AddSortedElement(ExcludeMaps, TempItem);
				}
				else
					WriteLog("Include map not found: "$Request.GetVariableNumber("IncludeMapsSelect", i));
			}
		}
		MapListType = "Custom";
		UpdateDefaultMaps(GameType, IncludeMaps);
	}
	else if (Request.GetVariable("AddAllMap", "") != "") {
		while (ExcludeMaps != None)
		{
			TempItem = ExcludeMaps.DeleteElement(ExcludeMaps);
			if (TempItem != None)
			{
				TempItem.bJustMoved = true;
				if (IncludeMaps == None)
					IncludeMaps = TempItem;
				else
					IncludeMaps.AddElement(TempItem);
			}
		}
		MapListType = "Custom";
		UpdateDefaultMaps(GameType, IncludeMaps);
	}
	else if (Request.GetVariable("DelAllMap", "") != "") {
		while (IncludeMaps != None)
		{
			TempItem = IncludeMaps.DeleteElement(IncludeMaps);
			if (TempItem != None)
			{
				TempItem.bJustMoved = true;
				if (ExcludeMaps == None)
					ExcludeMaps = TempItem;
				else
					ExcludeMaps.AddSortedElement(ExcludeMaps, TempItem);
			}
		}
		MapListType = "Custom";
		UpdateDefaultMaps(GameType, IncludeMaps);	// IncludeMaps should be None now.
	}
	else if (Request.GetVariable("MoveMap", "") != "") {
		MoveCount = int(Abs(float(Request.GetVariable("MoveMapCount"))));
		if (MoveCount != 0) {
			Count = Request.GetVariableCount("IncludeMapsSelect");
			if (Request.GetVariable("MoveMap") ~= "Down") {
				for (TempItem = IncludeMaps; TempItem.Next != None; TempItem = TempItem.Next);
				for (TempItem = TempItem; TempItem != None; TempItem = TempItem.Prev) {
					for (i=0; i<Count; i++) {
						if (TempItem.Data ~= Request.GetVariableNumber("IncludeMapsSelect", i)) {
							TempItem.bJustMoved = true;
							IncludeMaps.MoveElementDown(IncludeMaps, TempItem, MoveCount);
							break;
						}
					}
				}
			}
			else {
				for (TempItem = IncludeMaps; TempItem != None; TempItem = TempItem.Next) {
					for (i=0; i<Count; i++) {
						if (TempItem.Data ~= Request.GetVariableNumber("IncludeMapsSelect", i)) {
							TempItem.bJustMoved = true;
							IncludeMaps.MoveElementUp(IncludeMaps, TempItem, MoveCount);
							break;
						}
					}
				}
			}
			
			UpdateDefaultMaps(GameType, IncludeMaps);
		}
	}
	
	// Start output here
	
	Response.Subst("MapListType", MapListType);
	
	// Generate maplist options
	Response.Subst("MapListOptions", GenerateMapListOptions(GameType, MapListType));

	// Generate map selects
	Response.Subst("ExcludeMapsOptions", GenerateMapListSelect(ExcludeMaps));
	Response.Subst("IncludeMapsOptions", GenerateMapListSelect(IncludeMaps));
    if (USL>=SAM.USLMapListChange)
	    Response.Subst("UseMapList", "<input type=\"submit\" name=\"MapListSet\" value=\"Use\">");

	Response.Subst("PostAction", GameMapPage);
	Response.Subst("GameType", GameType);
	Response.Subst("ServerName", GetServerName());
	
	Response.IncludeUHTM(SubPath$GameMapPage$".uhtm");
	Response.ClearSubst();
}


function QueryRestart(WebRequest Request, WebResponse Response)
{
	local int GAL,USL;
	
	USL = SAM.CurrentUserSecLevel();

    if (USL < SAM.USLServerRestart) 
    {
    	DoAccessError(Request,Response);
        return;
    }
	Level.ServerTravel(Left(string(Level), InStr(string(Level), "."))$".unr"$"?game="$Level.Game.Class, false);
	Response.Subst("Title", "Please Wait");
	Response.Subst("ServerName", GetServerName());	
	Response.Subst("Message", "The server is now restarting the current map.  Please allow 10-15 seconds while the server changes levels.");
	Response.IncludeUHTM(SubPath$MessageUHTM);
}

function QueryServerDef(WebRequest Request, WebResponse Response)
{

	Response.Subst("Title", Level.Game.GameReplicationInfo.GameName$" in "$Level.Title);	
	Response.Subst("ServerName", GetServerName());
	
	Response.Subst("Message", "SemiAdmin Remote Administration Web-Based Interface"@SAM.Version@"<br><p>Select a link to begin administration</p><p>If anything is unclear, click the Help Page link.</p><p>You will be forwarded to the most applicable area of the Help Page.");
	Response.IncludeUHTM(SubPath$MessageUHTM);

}

function QueryServerMutes(WebRequest Request, WebResponse Response)
{
	Response.Subst("CurrentGame", Level.Game.GameReplicationInfo.GameName$" in "$Level.Title);
	Response.Subst("ServerName", GetServerName());
	Response.Subst("ServerMuteCodes", GetSetServerMuteInfo(Request));
	
	Response.IncludeUHTM(SubPath$ServerMutesPage$".uhtm");
}

function QueryServerReasons(WebRequest Request, WebResponse Response)
{

	Response.Subst("PostAction", ServerReasonsPage);
	Response.Subst("CurrentGame", Level.Game.GameReplicationInfo.GameName$" in "$Level.Title);
	Response.Subst("ServerName", GetServerName());
	Response.Subst("ServerReasonCodes", GetSetServerReasonInfo(Request));
	
	Response.IncludeUHTM(SubPath$ServerReasonsPage$".uhtm");
}

function QueryWarnings(WebRequest Request, WebResponse Response)
{
	Response.Subst("Title", Level.Game.GameReplicationInfo.GameName$" in "$Level.Title);
	Response.Subst("ServerName", GetServerName());
	Response.Subst("SmallTitle", "Warnings Issued");
	
	Response.Subst("Message", "SemiAdmin Remote Administration Web-Based Interface"@SAM.Version@"<br><p>This feature is not ready yet</p>");
	Response.IncludeUHTM(SubPath$MessageUHTM);
}

function QueryActivity(WebRequest Request, WebResponse Response)
{
	Response.Subst("Title", Level.Game.GameReplicationInfo.GameName$" in "$Level.Title);
	Response.Subst("ServerName", GetServerName());
	Response.Subst("SmallTitle", "Admin Activity Log");
	
	Response.Subst("Message", "SemiAdmin Remote Administration Web-Based Interface"@SAM.Version@"<br><p>This feature is not ready yet</p>");
	Response.IncludeUHTM(SubPath$MessageUHTM);
}

function QueryServerSettings(WebRequest Request, WebResponse Response)
{

	Response.Subst("PostAction", ServerSettingsPage);
	Response.Subst("CurrentGame", Level.Game.GameReplicationInfo.GameName$" in "$Level.Title);
	Response.Subst("ServerName", GetServerName());
	Response.Subst("ServerParameters", GetSetServerInfo(Request));
	
	Response.IncludeUHTM(SubPath$ServerSettingsPage$".uhtm");
		
}

function QueryServerBans(WebRequest Request, WebResponse Response)
{

	Response.Subst("PostAction", ServerBansPage);
	Response.Subst("CurrentGame", Level.Game.GameReplicationInfo.GameName$" in "$Level.Title);
	Response.Subst("ServerName", GetServerName());
	Response.Subst("ServerIPBanParameters", GetSetServerBanInfo(Request));
	
	Response.IncludeUHTM(SubPath$ServerBansPage$".uhtm");
		
}

function string GetServerName()
{
    return Level.Game.GameReplicationInfo.Default.ServerName;   
}


//*****************************************************************************
//
//USER FUNCTIONS
//
//*****************************************************************************

function QueryUsersDef(WebRequest Request, WebResponse Response)
{
	Response.Subst("ServerName", GetServerName());
	Response.Subst("SectionTitle", "Users and Groups");
	
	Response.IncludeUHTM(SubPath$UsersDefPage$".uhtm");
}


function QueryUsersMenu(WebRequest Request, WebResponse Response)
{
	local String page;
	// set post action
	Response.Subst("PostAction", UsersMenuPage);

	// Set URIs
	Response.Subst("UsersAddURI", 		UsersAddPage);
	Response.Subst("GroupsAddURI", 		GroupsAddPage);
	Response.Subst("UsersBrowseURI", 	UsersBrowsePage);
	Response.Subst("GroupsBrowseURI", 	GroupsBrowsePage);
	Response.Subst("NameSearchURI", 	NameSearchPage);
	Response.Subst("ServerName", GetServerName());
	
	Response.IncludeUHTM(SubPath$UsersMenuPage$".uhtm");
}

function QueryUsersAdd(WebRequest Request, WebResponse Response)
{
local string uname, upass, ugrp;

	if (Request.GetVariable("Add", "") != "")
	{
		uname = Request.GetVariable("Username");
		upass = Request.GetVariable("Password");
		ugrp = Request.GetVariable("Group");
		// Validate and add the user
		StatusReport(Response, SAM.DoAddUser(uname, upass, ugrp),
			"User '"$uname$"' was successfully added.");
	}
	
	// Build the User Add Page	
	Response.Subst("GroupList", MakeGroupList());
	
	Response.Subst("Title", "Add New Users");
	Response.Subst("SectionTitle", "Add a New User");	
	Response.Subst("ServerName", GetServerName());

	Response.Subst("PostAction", UsersAddPage);
	Response.IncludeUHTM(SubPath$UsersAddPage$".uhtm");
}

function QueryUsersMod(WebRequest Request, WebResponse Response)
{
local string uname, newname, upass, ugrp;
local int i;

	uname = Request.GetVariable("edit", "");
	if (Request.GetVariable("mod", "") != "")
	{
		uname = Request.GetVariable("Oldname");
		newname = Request.GetVariable("Username");
		upass = Request.GetVariable("Password");
		ugrp = Request.GetVariable("Group");

		if (StatusReport(Response, ModifyUserInfo(uname, newname, upass, ugrp),
			"User '"$uname$"' was successfully modified."))
		{
			uname=newname;
		}
	}
	i = SAM.FindUserId(uname);
	Response.Subst("NameValue", uname);
	Response.Subst("PassValue", SAM.GetUserPass(i));
	Response.Subst("GroupList", MakeGroupList(SAM.GetUserGroup(i)));
	Response.Subst("ServerName", GetServerName());

	Response.Subst("Title", "Modify Users");
	Response.Subst("SectionTitle", "Modify a User");	
		
	Response.Subst("PostAction", UsersEditPage);
	Response.IncludeUHTM(SubPath$UsersEditPage$".uhtm");
}

function QueryUsersBrowse(WebRequest Request, WebResponse Response)
{
local string uname, ErrMsg;
local int idx;

	uname = Request.GetVariable("delete", "");
	if (uname != "")
		StatusReport(Response, SAM.DoDelUser(uname), "User '"$uname$"' was successfully Deleted.");			

	// Show the list
	Response.Subst("BrowseList", GetUsersForBrowse());
	Response.Subst("ServerName", GetServerName());

	Response.Subst("Title", "Browse Available Users");
	Response.Subst("SectionTitle", "Browse Available Users");
	Response.IncludeUHTM(SubPath$UsersBrowsePage$".uhtm");
}

function QueryGroupsAdd(WebRequest Request, WebResponse Response)
{
local string gname, gpriv, ggsec, gusec, ErrMsg;
local int i;
local bool bIsAdmin;

	if (Request.GetVariable("Add", "") != "")
	{
		gname = Request.GetVariable("Groupname");
		ggsec = Request.GetVariable("GameSec");
		gusec = Request.GetVariable("UserSec");
		// Validate and add the group
		// parse the privs 
		gpriv = "";
		for (i=0;i<Len(SAM.AllPrivs);i++)
		{
			if (Request.GetVariable("Priv"$Mid(SAM.AllPrivs,i,1), "") != "")
				gpriv = gpriv$Mid(SAM.AllPrivs,i,1);
		}
		StatusReport(Response, SAM.DoAddGroup(gname, gpriv, gusec, ggsec),
			"Group '"$gname$"' Added Successfully!");
	}
	Response.Subst("Title", "Add New Groups");
	Response.Subst("SectionTitle", "Add a New Group");	
	Response.Subst("ServerName", GetServerName());
	
	Response.Subst("PostAction", GroupsAddPage);
	Response.IncludeUHTM(SubPath$GroupsAddPage$".uhtm");
}

function QueryGroupsMod(WebRequest Request, WebResponse Response)
{
local string gname, gpriv, ggsec, gusec, ErrMsg;
local int i;
local bool bIsAdmin;

	gname = Request.GetVariable("edit", "");
	if (Request.GetVariable("mod", "") != "")
	{
		gname = Request.GetVariable("Groupname");
		ggsec = Request.GetVariable("GameSec");
		gusec = Request.GetVariable("UserSec");
		// parse the privs 
		gpriv = "";
		for (i=0;i<Len(SAM.AllPrivs);i++)
		{
			if (Request.GetVariable("Priv"$Mid(SAM.AllPrivs,i,1), "") != "")
				gpriv = gpriv$Mid(SAM.AllPrivs,i,1);
		}
		StatusReport(Response, ModifyGroupInfo(gname, gpriv, int(gusec), int(ggsec)),
				"Group '"$gname$"' Succesfully Modified!"); 
	}
	
	i = SAM.FindGroupId(gname);
	Response.Subst("NameValue", SAM.GetGroupName(i));
	Response.Subst("GameSecValue", string(SAM.GetGroupGSL(i)));
	Response.Subst("UserSecValue", string(SAM.GetGroupUSL(i)));
	gpriv = SAM.GetGroupPrivs(i);
	for (i=0;i<Len(gpriv);i++)
	{
		if (Instr(SAM.AllPrivs, Mid(gpriv,i,1)) != -1)
			Response.Subst("Priv"$Mid(gpriv,i,1)$"Check", " Checked");
	}
	Response.Subst("Title", "Modify Groups");
	Response.Subst("SectionTitle", "Modify a Group");	
	Response.Subst("PostAction", GroupsEditPage);
	Response.Subst("ServerName", GetServerName());
	
	Response.IncludeUHTM(SubPath$GroupsEditPage$".uhtm");
}

function QueryGroupsBrowse(WebRequest Request, WebResponse Response)
{
local string gname, filter;
local int idx;

	gname = Request.GetVariable("delete", "");
	if (gname != "")
	{
		StatusReport(Response, SAM.DoDelGroup(gname), "Group '"$gname$"' was successfully Deleted.");
//		filter=Request.GetVariable("FilterValue");
	}
/*	
	if (Request.GetVariable("Filter", "") != "")
	{
		// Apply Filter to the list
		filter=Request.GetVariable("FilterValue", "");
	}
	else if (Request.GetVariable("ClearFilter", "") != "")
	{
		filter="";
	}
 */
	// Show the list
	Response.Subst("BrowseList", GetGroupsForBrowse());
	Response.Subst("Title", "Browse Available Groups");
	Response.Subst("SectionTitle", "Browse Available Groups");
	Response.Subst("ServerName", GetServerName());
	
	Response.IncludeUHTM(SubPath$GroupsBrowsePage$".uhtm");
}

function QueryNameSearch(WebRequest Request, WebResponse Response)
{
	Response.Subst("Title", "UserName / UserGroup Search");
	Response.Subst("ServerName", GetServerName());

	Response.Subst("Title", "This page is not enabled");
	Response.IncludeUHTM(SubPath$MessageUHTM);
}

function QueryMain(WebRequest Request, WebResponse Response)
{
	Response.Subst("Title", Level.Game.GameReplicationInfo.GameName$" in "$Level.Title);	
	Response.Subst("ServerName", GetServerName());
	
	Response.Subst("Message", "SemiAdmin Remote Administration Web-Based Interface"@SAM.Version@"<br><p>Select a link to begin administration</p><p>If anything is unclear, click the Help Page link.</p><p>You will be forwarded to the most applicable area of the Help Page.");
	Response.IncludeUHTM(SubPath$MessageUHTM);
}
function QueryHelpPage(WebRequest Request, WebResponse Response)
{
	Response.Subst("Title", "SemiAdmin Help Page");
	Response.Subst("ServerName", GetServerName());
	
	Response.IncludeUHTM(SubPath$HelpPage$".uhtm");
}

function QueryCLHelpPage(WebRequest Request, WebResponse Response)
{
	Response.Subst("Title", "SemiAdmin Online Command Line Help Page");
	Response.IncludeUHTM(SubPath$CLHelpPage$".uhtm");
}

function QueryQRGPage(WebRequest Request, WebResponse Response)
{
	Response.Subst("Title", "SemiAdmin Quick Reference Command Line Help Page");
	Response.Subst("ServerName", GetServerName());
	Response.IncludeUHTM(SubPath$QRGPage$".uhtm");
}

function StatusError(WebResponse Response, string Message)
{
	if (Left(Message,1) == "@")
		Message = Mid(Message,1);
		
	Response.Subst("Status", "<p><font size='+1' color='Yellow'>"$Message$"</font></p>");
}

function StatusOk(WebResponse Response, string Message)
{
	Response.Subst("Status", "<p><font size='+1' color='#33cc66'>"$Message$"</font></p>");
}

function bool StatusReport(WebResponse Response, string ErrorMessage, string SuccessMessage)
{
	if (ErrorMessage == "")
		StatusOk(Response, SuccessMessage);
	else
		StatusError(Response, ErrorMessage);

	return ErrorMessage=="";
} 

function MessagePage(WebResponse Response, string Title, string Message)
{
	Response.Subst("Title", Title);
	Response.Subst("Message", Message);
	Response.IncludeUHTM(SubPath$MessageUHTM);
}

function WriteLog(string message, optional name package)
{
    if (SAM!=None)
        SAM.WriteLog(message,package);   
}

defaultproperties
{
     SubPath="SemiWebAdmin/"
     RootPage="root"
     RootMenuPage="mainmenu"
     RootGamePage="root_game"
     RootUsersPage="root_users"
     RootServerPage="root_server"
     GameDefPage="version"
     GameMenuPage="game_menu"
     GameIndexPage="game_index"
     GamePageLev="game_lev"
     GameBotPage="game_bot"
     GamePlayerKickPage="game_player_kick"
     GamePlayerBanPage="game_player_ban"
     GamePlayerWhipPage="game_player_whip"
     GameMutatorPage="game_mutators"
     GameMapPage="game_maplist"
     GameConsolePage="game_console"
     GameConsoleLogPage="game_console_log"
     GameConsoleSendPage="game_console_send"
     ServerDefPage="server"
     ServerSettingsPage="server_settings"
     WarningsPage="server_warnings"
     ServerMutesPage="server_mutes"
     ActivityPage="server_activity"
     ServerReasonsPage="server_reasons"
     ServerBansPage="server_bans"
     UsersDefPage="users"
     UsersMenuPage="users_menu"
     UsersAddPage="users_add"
     UsersEditPage="users_edit"
     UsersBrowsePage="users_browse"
     GroupsAddPage="groups_add"
     GroupsEditPage="groups_edit"
     GroupsBrowsePage="groups_browse"
     NameSearchPage="namesearch"
     ServerMenuPage="server_menu"
     ServerRestartPage="restart"
     HelpPage="help"
     CLHelpPage="clhelp"
     QRGPage="quickreference"
     MessageUHTM="message.uhtm"
     DefaultBG="#aaaaaa"
     HighlightedBG="#ffffff"
     AdminRealm="SemiAdmin Web Interface"
     ImageDir="/images"
     Colors(0)="Red"
     Colors(1)="Blue"
     Colors(2)="Green"
     Colors(3)="Yellow"
}
