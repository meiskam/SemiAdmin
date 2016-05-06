class SemiAdminSpectator extends MessagingSpectator
	config;

struct PlayerMessage
{
	var PlayerReplicationInfo 	PRI;
	var String					Text;
	var Name					Type;
	var PlayerMessage 			Next;	// pointer to next message
};

var ListItem MessageList;

var byte ReceivedMsgNum;
var config byte ReceivedMsgMax;

var config bool bClientMessages;
var config bool bTeamMessages;
var config bool bVoiceMessages;
var config bool bLocalizedMessages;

function AddMessage(PlayerReplicationInfo PRI, String S, name Type)
{
	
	local ListItem TempMsg;
	
	TempMsg = new(None) class'ListItem';
	TempMsg.Data = FormatMessage(PRI, S, Type);
	
	if (MessageList == None)
		MessageList = TempMsg;
	else
		MessageList.AddElement(TempMsg);
		
	if ((ReceivedMsgNum++) >= ReceivedMsgMax)
		MessageList.DeleteElement(MessageList); // delete the first element
	
}

	
function String FormatMessage(PlayerReplicationInfo PRI, String Text, name Type)
{
    	local String Message;
	
	// format Say and TeamSay messages
	if (PRI != None) {
		if (Type == 'Say')
			Message = PRI.PlayerName$": "$Text;
		else if (Type == 'TeamSay')
			Message = "["$PRI.PlayerName$"]: "$Text;
		else
			Message = "("$Type$") "$Text;
	}
	else if (Type == 'Console')
		Message = Text;
	else
		Message = "("$Type$") "$Text;
		
	return Message;
}

function ClientMessage( coerce string S, optional name Type, optional bool bBeep )
{
	if (bClientMessages)
		AddMessage(None, S, Type);
		
}

function TeamMessage( PlayerReplicationInfo PRI, coerce string S, name Type, optional bool bBeep )
{
	if (bTeamMessages)
		AddMessage(PRI, S, Type);
		

}

/*
event ClientMessage( coerce string S, optional name Type, optional bool bBeep )
{
  local int i;

  i = InStr (s, ":");
  if (i != -1)
    s = Mid (s, i + 1);

  ParseMessage (s, 255, false);
}

event TeamMessage( PlayerReplicationInfo PRI, coerce string S, name Type, optional bool bBeep )
{
  local int team;
  local bool admin;

  if (pri == none) {
    team = 255;
    admin = false;
  }
  else {
    team = pri.team;
    admin = pri.bAdmin;
  }

  ParseMessage (s, team, admin);
}

function ParseMessage (string s, int team, bool admin)
{
  local int i;
  local string s1, s2;

  //Commands available in any mode
  if (s ~= "autopause") {
    ShowAbout = 7;
    return;
  }

  //Stuff available during play

  if (s ~= "pause") {
    curgame.maxplayers++;
    CalcTeamSizes ();
    forcepause = true;
    GotoState ('Paused');
    return;
  }

  if (s ~= "unpause") {
    curgame.maxplayers--;
    CalcTeamSizes ();
    forcepause = false;
    GotoState ('Unpausing');
    return;
  } 

  for (i = 0; i < 2; i++) {
    if (IsMissing (i)) {
      if (team == i) {
        if (s ~= "go")
          CalcTeamSizes ();
//          forced [i] = 1;
      }

      if (team == OtherTeam (i)) {
        if (s ~= "hold") {
          curpause [i] += 60;
          totalpause [i] += 60;
        }
      }

    }
  }
  if (IsInState ('Waiting') || IsInState ('Ended'))
    return;
}
*/  

function ClientVoiceMessage(PlayerReplicationInfo Sender, PlayerReplicationInfo Recipient, name messagetype, byte messageID)
{
	// do nothing?
}

function ReceiveLocalizedMessage( class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject )
{
	// do nothing?
}

defaultproperties
{
     ReceivedMsgMax=32
     bClientMessages=True
     bTeamMessages=True
     bLocalizedMessages=True
}
