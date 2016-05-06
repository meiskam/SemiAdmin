// ====================================================================
//  Class:  SemiAdmin.SemiAdminSA
//  Parent: Engine.Actor
//
//  <Enter a description here>
// ====================================================================

class SemiAdminSA expands Info;

function PostBeginPlay()
{
local SemiAdminMutator SAM;

	Super.PostBeginPlay();

	// Make sure it wasn't added as a mutator
	
	foreach AllActors(class 'SemiAdminMutator',SAM)
	{
		return;
	}

	SAM = Level.Spawn(Class'SemiAdminMutator');
	SAM.NextMutator = Level.Game.BaseMutator;
	Level.Game.BaseMutator = SAM;
}

defaultproperties
{
}
