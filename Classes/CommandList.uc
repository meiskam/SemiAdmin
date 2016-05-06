// ====================================================================
//  Class:  SemiAdmin.CommandList
//  Parent: Engine.Info
//
//  <Enter a description here>
// ====================================================================

class CommandList extends Info
	config(Commands);

struct Command
{
	var string Group;
	var string Sub;
	var string Variable;
	var string Params;
};

var config Command Commands[100];
var config int NumCommands;
// For quicker access

final function AddCommand(string Group, string Sub, string Params)
{
	Commands[NumCommands].Group = Group;
	Commands[NumCommands].Sub = Sub;
	Commands[NumCommands].Variable = PopArg(Params);
	Commands[NumCommands].Params = Params;
	NumCommands++;
}

final function DelCommand(int index)
{
local int i;

	// We absolutely have to keep commands ordered or it could screw what we try to do
	NumCommands--;
	for (i = index; i<NumCommands; i++)
		Commands[i] = Commands[i+1];

	Commands[i].Group = "";
	Commands[i].Sub = "";
	Commands[i].Variable = "";
	Commands[i].Params = "";
}

final function int GetCommandIndex(string group, string sub)
{
local int i;

	for (i = 0; i<NumCommands; i++)
		if (group ~= Commands[i].Group && sub ~= Commands[i].Sub)
			return i;
	
	return -1;
}

final function int GetCommandVarIndex(string group, string sub, string variable)
{
local int i;

	for (i = 0; i<NumCommands; i++)
		if (group ~= Commands[i].Group && sub ~= Commands[i].Sub && variable ~= Commands[i].variable)
			return i;
	
	return -1;
}

final function string PopArg(out string cmdline)
{
local int p;
local string str;

	// First, clean the extra spaces
	while (cmdline != "" && Left(cmdline, 1) == " ")
		cmdline = Mid(cmdline, 1);

	p = Instr(cmdline, " ");
	if (p == -1)
	{
		str = cmdline;
		cmdline = "";
	}
	else
	{
		str = left(cmdline, p);
		cmdline = mid(cmdline, p+1);
	}
	return str;
}

defaultproperties
{
}
