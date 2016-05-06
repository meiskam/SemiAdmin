//=============================================================================
// WarnedList.
//=============================================================================
class WarnedList extends Info
	config(WarnedList);
	
var config string Warned[1024];
var int NextFree;
var int FindWarningTextIndex;


function LogWarning(string warning)
{
    FindNextFree();
    if(NextFree>=0)
    {
        Warned[NextFree]=warning;
        SaveConfig();
    }
    else
        Log("WarnedList: Failed to find a free slot");
}

function string FindFirstWarningText(string lookfor)
{
    return FindNextWarningText(lookfor,-1);
}

function string FindNextWarningText(string lookfor, optional int start)
{
    local int i;
    if (start!=0) FindWarningTextIndex=start;
    
    for (i=FindWarningTextIndex+1; i<1024; i++)
    {
        if(Warned[i]!="")
        { 
            if(instr(Warned[i],lookfor)!=-1)
            {
//                log("pcl:"@i@"found"@lookfor);
                FindWarningTextIndex=i;          
                return Warned[i];
            }
        }
//    log("pcl:"@i@"Not found"@lookfor);    
    }
    return "";
}

function FindNextFree()
{
    // looks for the next free warning slot
    local int i;
    for (i=NextFree; i<1024; i++)
    {
        if(Warned[i]=="") 
        {
            NextFree=i;
            return;
        }   
    }
}

defaultproperties
{
     Warned(0)="time: 09/20/2003 00:05:53 admin: kuhal player: yf|Kuhal IP: 192.168.1.3:4611 action: Warning reasoncode: 0 reason: Abusive language is not permitted"
}
