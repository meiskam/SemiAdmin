// ====================================================================
//  Class:  SemiAdmin.SemiAdminBase
//  Parent: Engine.Mutator
//
//  SemiAdminBase will be Responsible for:
//  - User/Group management
//  - Base Final Functions
//  - Default Error Message
// ====================================================================

class SemiAdminBase extends Mutator
	abstract;

struct SAUser
{
	var string	Name;
	var string	Password;
	var string	Group;
};

struct SAGroup
{
	var string	Name;
	var string	Privileges;
	var int		SecLevel;
};

struct SAAdmin
{
	var SAUser 					User;
	var SAGroup 				Group;
	var PlayerReplicationInfo	PRI;
};

var string Version;
var string AllPrivs;

// In Config File
var config SAUser	Users[80];		// All the valid users
var config SAGroup	Groups[30];		// All the valid groups
var config int		NumUsers;		// Number of Users that are valid
var config int		NumGroups;		// Number of Groups that are valid

// Default None Values
var SAAdmin NoneAdmin;
var SAUser	NoneUser;
var SAGroup NoneGroup;

// --- current session ---
var SAAdmin Admins[32], Admin;
var int NumLogged, iIter;
var PlayerPawn Issuer; 		// Set by Mutate
var string SenderIP;  		// Sender IP address
var bool bIsWebAdmin;		// Set if the current admin is web admin
var bool bDelGroup;				// Delete group bool

// Command Line
var string Command;	 // Set by ParseCommandLine()
var string SubCmd;	 // Set by ParseCommandLine()
var string Params[50]; // Set by ParseCommandLine()
var int NumParams;   // Set by ParseCommandLine()

function PreBeginPlay()
{
	Log("================================================", 'SemiAdmin');
	Log("Semi Admin"@Version@"registered and activated", 'SemiAdmin');
	Log("================================================", 'SemiAdmin');
	super.PreBeginPlay();
}

function DoFreeCommand()
{
	if (Command == "SAVER")				GetVersion();
}

function bool DoAdminCommand()
{
	if (HandleUsers())	return true;
}

function DoMasterAdminCommand()
{
}

function ClearParams()
{
    // clears the Params array as ther emight be left over
    // params that can confuse commands
    local int i;
    for (i=0; i<NumParams; i++)
        Params[i]="";    
}
// ###############################################
// ## ROOT USERS MAINTENANCE
// ###############################################

final function NewUser(string uname, string upass, string ugrp)
{
	Users[NumUsers].Name = uname;
	Users[NumUsers].Password = upass;
	Users[NumUsers].Group = ugrp;
	NumUsers++;
	SaveConfig();
}

final function bool DestroyUser(int index)
{
	if (NumUsers < 1)
		return false;

	NumUsers--;
	if (index != NumUsers)
		Users[index] = Users[NumUsers];
		
	Users[NumUsers].Name = "";
	Users[NumUsers].Password = "";
	Users[NumUsers].Group = "";
	SaveConfig();
	return true;
}

final function string GetUserName(int index) { return Users[index].Name; }
final function string GetUserPass(int index) { return Users[index].Password; }
final function string GetUserGroup(int index){ return Users[index].Group; }

final function ModifyUser(string oldname, string newname, string password, string group)
{
local int idx;

	idx = FindUserId(oldname);
	Users[idx].Name = newname;
	Users[idx].Password = password;
	Users[idx].Group = group;
	SaveConfig();
}

function SAUser FindUser(string uname)
{
local int i;

	for (i = 0; i<NumUsers; i++)
		if (Users[i].Name == uname)
			return Users[i];
			 
	return NoneUser;
}

function int FindUserId(string uname)
{
local int i;

	for (i = 0; i<NumUsers; i++)
		if (Users[i].Name == uname)
			return i;
	
	return -1;
}

function BeginIter() { iIter = 0; } 

function string NextUsername()
{
	while (iIter < NumUsers)
	{
		// Check which group the user belong to
		if (CanManageGroup(Users[iIter].Group) || Users[iIter] == Admin.User)
			return Users[iIter++].Name;

		iIter++;
	}
	return "";
}

final function int CountMasterAdminUsers()
{
	local int i, cnt, gcnt;
	local string usergroup;
	
	for (i=0;i<NumUsers;i++)
		if (UserIsAdmin(Users[i].Name))
			cnt++;	
	
	return cnt;
}

final function int CountUsersInGroup(string group)
{
	local int i, cnt;
	
	for (i=0;i<NumUsers;i++)
		if (Users[i].Group == group)
			cnt++;
	
	return cnt;
}
	
// ###############################################
// ## ROOT GROUPS MAINTENANCE
// ###############################################

final function NewGroup(string ugrp, string upriv, int SecLevel)
{
	Groups[NumGroups].Name = ugrp;
	Groups[NumGroups].Privileges = upriv;
	Groups[NumGroups].SecLevel = SecLevel;
	NumGroups++;
}

final function bool DestroyGroup(int index)
{
local int i;

	if (NumGroups < 1)
		return false;

	for (i = 0; i<NumUsers; i++)
		if (Users[i].Group == Groups[index].Name)
			return false;

	NumGroups--;
	if (index != NumGroups)
		Groups[index] = Groups[NumGroups];
	Groups[NumGroups].Name = "";
	Groups[NumGroups].Privileges = "";
	Groups[NumGroups].SecLevel = 0;
	SaveConfig();
	return true;
}

final function string GetGroupName(int index) {	return Groups[index].Name; }
final function string GetGroupPrivs(int index){ return Groups[index].Privileges; }
final function int GetGroupUSL(int index)     { return Groups[index].SecLevel >> 8; }
final function int GetGroupGSL(int index)     { return Groups[index].SecLevel & 255; }

final function ModifyGroup(string gname, string privs, int usl, int gsl)
{
local int idx;

	idx = FindGroupId(gname);
	Groups[idx].Privileges = privs;
	Groups[idx].SecLevel = (usl << 8) + gsl;
	SaveConfig();
}


final function bool UserIsAdmin(string Username)
{
	return GroupIsAdmin(FindUser(Username).Group);	 
}

function string NextGroupName()
{
	while (iIter < NumGroups)
	{
		if (CanManageGroup(Groups[iIter].Name))
			return Groups[iIter++].Name;
			
		iIter++;
	}
	return "";
}

final function bool CanManageGroup(string grpname)
{
local SAGroup grp;

	grp = FindGroup(grpname);

	// Check the user's group
	return IsMasterAdmin() || (grp != NoneGroup && ((Admin.Group.SecLevel>>8) > (grp.SecLevel>>8)));
}

final function bool GroupIsAdmin(string Groupname)
{
	return (FindGroup(Groupname).SecLevel >> 8) == 255;
}

final function int CountMasterAdmins()
{
local int i, cnt;

	cnt = 0;
	for (i = 0; i<NumGroups; i++)
		if ((Groups[i].SecLevel >> 8) == 255) 
			cnt++;

	return cnt;
}

final function SAGroup FindGroup(string Groupname)
{
local int i;

	for (i = 0; i<NumGroups; i++)
		if (Groups[i].Name ~= Groupname)
			return Groups[i];
			
	return NoneGroup;
}

final function int FindGroupId(string Groupname)
{
local int i;

	for (i = 0; i<NumGroups; i++)
		if (Groups[i].Name ~= Groupname)
			return i;
			
	return -1;
}

// User
final function SAGroup FindAdminGroup()
{
local int i;

	for (i = 0; i<NumGroups; i++)
		if ((Groups[i].SecLevel >> 8) == 255 && Groups[i].Name == "admin")
			return Groups[i];
			
	for (i = 0; i<NumGroups; i++)
		if ((Groups[i].SecLevel >> 8) == 255)
			return Groups[i];
			
	return NoneGroup;
}

function int FindLoggedUser(string uname)
{
local int i;

	for (i = 0; i<NumLogged; i++)
		if (Admins[i].User.Name == uname)
			return i;

	return -1;
}

function int FindLoggedByPRI(PlayerReplicationInfo pPRI)
{
local int i;

	for (i = 0; i<NumLogged; i++)
		if (Admins[i].PRI == pPRI)
			return i;
			
	return -1;
}

function PlayerPawn LogoutId(int id)
{
local PlayerPawn ppawn;
local Pawn p;

	for (p = Level.PawnList; p != None; p = p.NextPawn)
		if (p.PlayerReplicationInfo == Admins[id].PRI)
		{
			ppawn = PlayerPawn(p);
			break;
		}
	
	// To unlog, remove his entry
	Unlog(id);
	return ppawn;
}

function Unlog(int id)
{
	NumLogged--;
	if (id != NumLogged)
		Admins[id] = Admins[NumLogged];

	Admins[NumLogged] = NoneAdmin;
}

// ###############################################
// ## COMMANDS DISPATCHING
// ###############################################

function bool HandleUsers()
{
	if (!IsPartOf(Command, "USERS|GROUPS"))
		return false;

	if (!CanManageUsers())
	{
		LogNoPrivs();
		return true;
	}
	
	if (Command == "USERS")				HandleUsersSubCmd();
	else if (Command == "GROUPS")		HandleGroupsSubCmd();

	return true;
}

function HandleUsersSubCmd()
{
	if (SubCmd == "HELP")				HelpUsers();
	else if (SubCmd == "ADD")			LogMessage(AddUser());
	else if (SubCmd == "DEL")			LogMessage(DelUser());
	else if (SubCmd == "MOD")			LogMessage(ModUser());
	else if (SubCmd == "LIST")			LogMessage(ListUsers());
}

function HandleGroupsSubCmd()
{
	if (SubCmd == "HELP")				HelpGroups();
	else if (SubCmd == "ADD")			LogMessage(AddGroup());
	else if (SubCmd == "DEL")			LogMessage(DelGroup());
	else if (SubCmd == "MOD")			LogMessage(ModGroup());
	else if (SubCmd == "LIST")			LogMessage(ListGroups());
}

// ###############################################
// ## NO SPECIAL PRIVILEGES REQUIRED
// ###############################################

function GetVersion()
{
	Issuer.ClientMessage("SemiAdmin"@Version);
}

// ###############################################
// ## USERS MANAGEMENT
// ###############################################

// mutate users add <uname> <upass> <ugrp>
function string AddUser()
{
local string uname, ErrMsg;

	PopParam();	// Pop SubCmd
	if (NumParams != 3)
		return "Invalid number of parameters"; 

	uname = PopParam();
	ErrMsg = DoAddUser(uname, PopParam(), PopParam());
	if (ErrMsg != "")
		return ErrMsg;
		
	return "@User '"$uname$"' successfully added!";
}

function string DoAddUser(string uname, string upass, string ugrp)
{
local SAGroup Group;

	if (NumUsers > 49)
		return "Maximum number of Admins Reached, impossible to add more";

	if (!CheckUserName(uname))
		return "Invalid characters in user name";

	if (FindUserId(uname) != -1)
		return "User '"$uname$"' already exists";

	if (!CheckPassword(upass))
		return "Invalid characters in user password";

	Group = FindGroup(ugrp);
	if (Group == NoneGroup)
		return "Invalid group name '"$ugrp$"'";
		
	if (!IsMasterAdmin())
	{
		if ((Admin.Group.SecLevel >> 8) <= (Group.SecLevel >> 8))
			return "You do not have the privileges to add a user to that group";
	}
			
	// All is fine, add the user to the admin list
	NewUser(uname, upass, ugrp);
	LogServerMessage(Admin.User.Name@"has added user"@uname@"to group"@ugrp);
	return "";
}

// mutate users del <uname>
function string DelUser()
{
local string uname, ErrMsg;

	PopParam();	// skip SubCmd
	if (NumParams != 1)
		return "Invalid number of parameters"; 

	uname = PopParam();
	ErrMsg = DoDelUser(uname);
	if (ErrMsg == "")
		return "User '"$uname$"' was successfully removed.";
		
	return ErrMsg;
}

final function string DoDelUser(string uname)
{	
local int i, j, logid, uid, gid;
local string issuername;
local PlayerPawn LoggedPlayer;

bDelGroup = False;

	if (!CheckUserName(uname))
		return "Invalid characters in user name";

	uid = FindUserId(uname);
	if (uid == -1)
		return "User '"$uname$"' does not exist";
		
	// Found the user to delete .. see if it's a Master Admin
	if (GroupIsAdmin(Users[uid].Group))
	{
		// Only a Master Admin can delete a Master Admin
		if (IsMasterAdmin())
		{
			// Do not allow the last MasterAdmin to be deleted
			if (CountMasterAdminUsers() < 2)
				return "You are not allowed to delete the last Master Admin";
			
			// Find out if this Master Admin is the last Master Admin of a Master Admin group
			
			if (CountMasterAdmins() > 1)
				if (CountUsersInGroup(Users[uid].Group) == 1)
				{
					bDelGroup = True;
					gid = FindGroupID(Users[uid].Group);
				}
		}
		else
			return "You are not allowed to delete the user '"$uname$"'";
	}
	// Find if the user about to be removed is currently logged
	logid = FindLoggedUser(uname);
	if (logid != -1)
		LoggedPlayer = LogoutId(logid);
	
	// Keep issuer's name in case he's deleting himself
	issuername = Admin.User.Name;
	// Ok, we can delete it. Replace me by last Admin
	if (!DestroyUser(uid))
		return "Error while destroying the user account";
		
	if (bDelGroup)
	{
		if (!DestroyGroup(gid))
		{
			// We still want to make sure that the user stays deleted, so save config here, then return message about group delete error
			// User should never see this message, since we check the group before setting bDelGroup, but just in case this function is used in later versions for something else...
			SaveConfig();
			return "Error while destroying the admin group containing this user";
		}
	}
			
	// Clear things up
	if (issuername == uname)
	{
		LogServerMessage(uname@"successfully removed itself from the list!");
		TellIssuer("You successfully removed yourself from the list and have been logged out");
	}
	else
	{
		LogServerMessage(issuername@"successfully removed user '"$uname$"' from the list");
		TellIssuer("You successfully removed user '"$uname$"' from the list");
		if (logid != -1 && LoggedPlayer != None)
			LoggedPlayer.ClientMessage(issuername@"has removed you from the admin list, you have been logged out");
	}
	SaveConfig();
	return "";
}

// mutate users mod <user> <name <newname>|pass <newpass>|group <newgroup>>

function string ModUser()
{
local int uid, logid, i;
local string uname, ucmd, uextra;
local SAGroup grp;

	PopParam();	// Skip SubCmd
	if (NumParams != 3)
		return "Invalid number of parameters"; 

	uname = PopParam();
	ucmd = PopParam();
	uextra = PopParam();

	if (!CheckUserName(uname))
		return "Invalid characters in user name";

	uid = FindUserId(uname);
	if (uid == -1)
		return "User '"$uname$"' does not exist";	
	
	logid = FindLoggedUser(uname);
		
	if (ucmd == "name")
	{
		if (logid != -1 && !IsMasterAdmin())
			return "User '"$uname$"' is already logged in, cannot change his name";
		
		if (uname == uextra)
			return "Action invalid: Using same name '"$uname$"'";
			
		if (FindUserId(uextra) != -1)
			return "New username '"$uextra$"' already exists";
			
		if (!CheckUserName(uextra))
			return "Invalid characters in new username";
			
		// Seems like we're OK to go !
		Users[uid].Name = uextra;
		SaveConfig();
		return "User '"$uname$"' has been renamed to '"$uextra$"'";
	}
	else if (ucmd == "pass")
	{
		if (logid != -1 && !IsMasterAdmin())
			return "User '"$uname$"' is already logged in, cannot change his password";
		
		if (!CheckPassword(uextra))
			return "Invalid Characters in new password";
			
		Users[uid].Password = uextra;
		SaveConfig();
		return "Password changed successfully for user '"$uname$"'";
	}
	else if (ucmd == "group")
	{
		if (logid != -1 && !IsMasterAdmin())
			return "User '"$uname$"' is already logged in, cannot change his group";
	
		grp = FindGroup(uextra);
		if (grp.Name == "")
			return "The group '"$uextra$"' does not exist";
			
		Users[uid].Group = uextra;
		if (logid != -1)
		{
			Admins[logid].User.Group = uextra;
		}
		return "Group was changed successfully for user '"$uname$"'";
	}
	else
		return "invalid users subcommand: '"$ucmd$"'";

	return "";		
}

// mutate users list 
function string ListUsers()
{
local int i, j;
local string msg;

	for (i = 0; i<NumUsers; i++)
	{
		msg = i$")"@Users[i].Name@"-";
		if (IsMasterAdmin())
			msg = msg@Users[i].Password@"-";
		msg = msg@Users[i].Group;
		
		for (j = 0; j<NumLogged; j++)
			if (Admins[j].User == Users[i])
			{
				msg = msg@"- [Logged In]"@Admins[j].PRI.PlayerName;
				break;
			}
		Issuer.ClientMessage(msg);
	}
	return "";
}

// ###############################################
// ## GROUPS MANAGEMENT
// ###############################################

// mutate groups add <groupname> <permissions> <seclevel> <grouplevel>
function string AddGroup()
{
local string RetStr, gname;

	PopParam();		// Pop SubCmd
	if (NumParams != 4)
		return "@Error: Invalid number of parameters"; 

	gname = PopParam();
	RetStr = DoAddGroup(gname, Caps(PopParam()), PopParam(), PopParam());
	if (RetStr == "")
		return "Group '"$gname$"' added to the group list";

	return RetStr;
}

final function string DoAddGroup(string uname, string upriv, string usl, string gsl)
{	
local int iusl, igsl, grpid;
local SAGroup Group;

	if (NumUsers > 49)
		return "Error: Maximum number of Admins Reached, impossible to add more";

	if (!CheckUserName(uname))
		return "@Error: Invalid characters in group name";

	grpid = FindGroupId(uname);
	if (grpid != -1)
		return "@Error: Group '"$uname$"' already exists";
		
	iusl = int(usl);
	igsl = int(gsl);
	
	if (!IsInteger(usl) || iusl < 0 || iusl > 255)
		return "@Error: Invalid value for User Security Level";
	
	if (!IsInteger(gsl) || igsl < 0 || igsl > 255)
		return "@Error: Invalid value for Game Level Security";
	
	if (!IsMasterAdmin())
		return "@Error: Only master admins can add groups";

	if (!AllValidChars(upriv, AllPrivs))
		return "@Error: Invalid privileges given. Only use B, G, K, L, M, O or U";

	NewGroup(uname, upriv, (iusl<<8) + igsl);
	SaveConfig();
	return "";
}

// mutate groups del <name>
function string DelGroup()
{
local string gname, ErrMsg;

	PopParam();
	
	if (NumParams != 1)
		return "@Invalid number of parameters";

	gname = PopParam();
	ErrMsg = DoDelGroup(gname);
	if (ErrMsg == "")
		return "Group '"$gname$"' Successfully Removed";
		
	return ErrMsg;
}

final function string DoDelGroup(string gname)
{
local int i, grpid;

	if (!CheckUserName(gname))
		return "@Invalid characters in group name";
	
	grpid = FindGroupId(gname);
	if (grpid == -1)
		return "@Group '"$gname$"' does not exist";

	if (!DestroyGroup(grpid))	
		return "@Cannot delete a group that has assigned users";
		
	return "";	
}

// mutate groups mod <group> <name> <newname>|priv [+|-]<privs>|seclevel <val>|gamelevel <val>>
function string ModGroup()
{
local string ucmd, uname, ugrp, uval, upriv, umsg, unewpriv;
local int grpid, lev, i;
local SAGroup Group, Group2;
local string c;

	PopParam();	// Pop SubCmd
	if (NumParams != 3)
		return "@Invalid number of parameter";
	
	if (!IsMasterAdmin())
		return "@You are not a master admin";
	
	uname = PopParam();
	ucmd = PopParam();
	uval = PopParam();

	grpid = FindGroupId(uname);
	if (grpid == -1)
		return "@Group '"$uname$"' does not exist";
		
	ugrp = Groups[grpid].Name;
	if (ucmd ~= "name")
	{
		if (!CheckUserName(uval))
			return "@Invalid characters in group name";

		Group = FindGroup(uval);
		if (Group != NoneGroup)
			return "@Group name '"$uval$"' already exists";
		
		Groups[grpid].Name = uval;
		umsg = "@Name successfully change to '"$uval$"'";
	}
	else if (ucmd ~= "priv")
	{
		upriv = Groups[grpid].Privileges;
		if (Left(uval, 1) == "+")
		{
			// Add privilege
			unewpriv = Caps(Mid(uval, 1));
			if (unewpriv == "")
				return "@You must specify privileges to add";
				
			for (i = 0; i<Len(unewpriv); i++)
			{
				c = Mid(unewpriv, i, 1);
				if (Instr(AllPrivs, c) == -1)
					return "@Trying to add incorrect privilege '"$c$"'";

				// Ok, can do it
				upriv = AddPrivChar(upriv, c);				
			}
		}
		else if (Left(uval, 1) == "-")
		{
			// Remove privilege
			unewpriv = Caps(Mid(uval, 1));
			if (unewpriv == "")
				return "@You must specify privileges to remove";
			
			for (i = 0; i<Len(unewpriv); i++)
			{
				c = Mid(unewpriv, i, 1);
				if (Instr(AllPrivs, c) == -1)
					return "@Trying to remove unknown Privilege '"$c$"'";
					
				// Ok, accepted
				upriv = DelPrivChar(upriv, c);
			}
		}
		else
		{
			// Set Privileges
			if (!AllValidChars(uval, "BGKLMOU"))
				return "Trying to set invalid Privilege mask : '"$uval$"'";
			
			// All is fine now
			upriv = uval;
		}
		// If we get here its because we have a new Privilege mask
		Groups[grpid].Privileges = upriv;
		umsg = "@Privileges Successfully changed to '"$upriv$"'"; 
	}
	else if (ucmd ~= "seclevel")
	{
		lev = int(uval);
		if (!IsInteger(uval) || lev<0 || lev>255)
			return "@Invalid security value";
			
		Groups[grpid].SecLevel = (Groups[grpid].SecLevel & 255) + (lev << 8);
		umsg = "Security Level succesfully changed";
	}
	else if (ucmd ~= "gamelevel")
	{
		lev = int(uval);
		if (!IsInteger(uval) || lev<0 || lev>255)
			return "@Invalid game security value";
			
		Groups[grpid].SecLevel = (Groups[grpid].SecLevel & 65280) + lev;
		umsg = "@Game level succesfully changed";
	}
	else
		return "@Invalid command specifications";
		
	// Replace all Groups in users that were assigned this group
	for (i = 0; i < NumUsers; i++)
		if (Users[i].Group == ugrp)
			Users[i].Group = Groups[grpid].Name;
			
	// Replace all Logged users
	for (i = 0; i < NumLogged; i++)
		if (Admins[i].Group.Name == ugrp)
			Admins[i].Group = Groups[grpid];
	
	SaveConfig();
	return umsg@"for group '"$ugrp$"'";
}

function string ListGroups()
{
local int i, j, sl, gl;
local string msg;

	for (i = 0; i < NumUsers; i++)
	{
		sl = Groups[i].SecLevel >> 8;
		gl = Groups[i].SecLevel & 255;
		msg = i$")"@Groups[i].Name@"-"@Groups[i].Privileges@"- S:"@sl@" G:"@gl;
		TellIssuer(msg);
	}
	return "";
}

// ###############################################
// ## SERVER LOGGING - CLIENT MESSAGES
// ###############################################

function bool LogMessage(string msg)
{
	if (msg != "")
	{
		if (Left(msg, 1) != "@")
			WriteLog("["@Admin.User.Name@"]"@msg, 'SemiAdmin');
		else
			msg = Mid(msg, 1);
			
		TellIssuer(msg);
	}

	// Helps making things more clear for callers of this command
	return true;	
}

function TellIssuer(string Msg)
{
	if (!bIsWebAdmin)
		Issuer.ClientMessage(Msg);
}

function LogServerMessage(string msg)
{
	if (msg != "")
		WriteLog("["@Admin.User.Name@"]"@msg, 'SemiAdmin');
}

function LogNoPrivs()
{
	LogServerMessage("Tried to use"@Command@"without the privileges!");
	Issuer.ClientMessage("You do not have the privileges to use"@Command);
}

// ###############################################
// ## STRING/PARAMS MANIPULATION
// ###############################################

function ParseCommandLine(string cmdline)
{
local string param;

	Command = Caps(GetNextParam(cmdline));
	SubCmd = "";
	NumParams = 0;
	if (Command != "")
	{
		param = GetNextParam(cmdline);
		while (param != "")
		{
			Params[NumParams] = param;
			NumParams++;
			param = GetNextParam(cmdline);
		}
	}
	if (NumParams > 0)
		SubCmd = Caps(Params[0]);
}

function string GetNextParam(out string source)
{
local int p, pend, slen;
local string copied;

	// Filter pre-spaces
	p = 0;
	slen = Len(source);
	
	while (p<slen && Mid(source, p, 1) == " ")
		p++;
		
	// ok, we are at the beginning of the string
	copied = "";
	while (p<slen && Mid(source, p, 1) != " ")
	{
		copied = copied $ Mid(source, p, 1);
		p++;
	}
	// ok, we have a completed name, trim source
	source = Mid(source, p);
	return copied;
} 

final function string PopParam()
{
local string str;
local int i;

	if (NumParams < 1)
		return "";

	str = Params[0];
	NumParams--;
	for (i = 0; i < NumParams; i++)
		Params[i] = Params[i+1];
	
	Params[i] = "";
	return str;
}

final function bool IsBool(string str)
{
	return IsPartOf(str, "Y|YES|1|TRUE|ON|N|NO|0|FALSE|OFF");
}

final function bool IsInteger(string str)
{
	return AllValidChars(str, "0123456789");
}

final function bool IsFloat(string str)
{
	if (AllValidChars(str, "0123456789-."))
	{
		return (float(str) != 0.0 || AllValidChars(str, "0."));
	}
	return false;
}

final function bool CheckUserName(string uname)
{
local string allow;

	allow = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	return AllValidChars(uname, allow);
}

final function bool CheckPassword(string upass)
{
local string allow;

	allow = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-+_@!#()&^[]{}.:;<>";
	return AllValidChars(upass, allow);
}

final function bool AllValidChars(string source, string limit)
{
local int i;

	for (i = 0; i<Len(source); i++)
		if (Instr(limit, Mid(source, i, 1)) == -1)
			return false;
			
	return true;
}

final function bool WildCapsCompare(string source, string wild)
{
local bool bBegin, bEnd;
local int wlen;


	bBegin = (Left(wild, 1) == "*");
	bEnd = (Right(wild, 1) == "*");
	
	wlen = Len(wild);
	
	if (bBegin) wlen--;
	if (bEnd) wlen--;
	
	if (wlen == 0)
		return false;
	
	source = Caps(source);
	wild = Caps(wild);
	
	if (bBegin && bEnd)
		return Instr(source, Mid(wild, 1, wlen)) != -1;
	else if (bBegin)
		return Right(source, wlen) == Right(wild, wlen);
	else if (bEnd)
		return Left(source, wlen) == Left(wild, wlen);
	
	return wild == source; 
}

function string AddPrivChar(string priv, string c)
{
	if (Instr(priv, c) != -1)
		return priv;
		
	return priv $ c;
}

function string DelPrivChar(string priv, string c)
{
local int i;
local string newpriv;

	if (Instr(priv, c) == -1)
		return priv;
		
	newpriv = "";
	for (i = 0; i<Len(priv); i++)
		if (Mid(priv, i, 1) != c)
			newpriv = newpriv $ Mid(priv, i, 1);

	return newpriv;
}

final function bool IsPartOf(string part, string src)
{
	return Instr("|"$caps(src)$"|", "|"$caps(part)$"|") != -1;
} 

// Function defined in subclass
function bool IsAdmin(PlayerPawn Sender);

// ###############################################
// ## PRIVILEGES ASSESSMENT
// ###############################################

final function bool HasPrivilege(string priv)
{
	return (Instr(Admin.Group.Privileges, priv) != -1) || IsMasterAdmin();
}

final function bool CanManageUsers()
{
	return HasPrivilege("U");
}

final function bool CanManageServer()
{
	return HasPrivilege("G");
}

final function bool IsMasterAdmin()
{
	return CurrentUserSecLevel() == 255;
}

final function int CurrentUserGameLevel()
{
	return Admin.Group.SecLevel & 255;
}

//@@TODO: Implement GamePlay privilege level.
final function int CurrentUserSecLevel()
{
	return Admin.Group.SecLevel >> 8;
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

function HelpUsers()
{
}

function HelpGroups()
{
}

function HelpMsg(string msg)
{
	if (Issuer != None)
		Issuer.ClientMessage(msg);
} 

function WriteLog(string message, optional name package)
{
    if(string(package) ~= "none")
        Log(Message);
    else
        Log(message,package);
}	

defaultproperties
{
     Version="v0.35h"
     AllPrivs="BGKLMOSUWZFAHDCEV"
}

// B = ban
// G = change game
// K = kick
// L = set up ladder
// M = change maps
// O = manage bots
// S = summon
// U = can manage users
// W = warning
// Z = zerofrag, respawn, mute, unmute
// T = ??
// F = do full (all hob commands)
// A = fly, walk, ghost
// H = goto
// D = god, health
// C = slap
// E = boost
// V = in/visible
// 