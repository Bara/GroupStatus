#pragma semicolon 1

#include <sourcemod>
#include <SteamWorks>
#include <webfix>

#pragma newdecls required

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientValid(%1))

bool g_bStatus[MAXPLAYERS + 1] = { false, ... };

ConVar g_cGroupID = null;
ConVar g_cGroupURL = null;

public Plugin myinfo =
{
	name = "[Outbreak] Group Status",
	author = "Bara",
	description = "",
	version = "1.0.0",
	url = "outbreak.community"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("GroupStatus_IsClientInGroup", Native_InGroup);
    RegPluginLibrary("groupstatus");

    return APLRes_Success;
}

public void OnPluginStart()
{
    RegConsoleCmd("sm_group", Command_Group);
    RegConsoleCmd("sm_join", Command_Group);
    RegConsoleCmd("sm_refresh", Command_Refresh);

    g_cGroupID = CreateConVar("groupstatus_id", "", "ID of the group");
    g_cGroupURL = CreateConVar("groupstatus_url", "", "Custom url naem of the group");

    AutoExecConfig();
}

public void OnClientPostAdminCheck(int client)
{
    UpdateGroupStatus(client);
}

public int Native_InGroup(Handle plugin, int numParams)
{
    return g_bStatus[GetNativeCell(1)];
}

public Action Command_Group(int client, int args)
{
    if (!IsClientValid(client))
    {
        return Plugin_Continue;
    }

    char sURL[128], sName[32];
    g_cGroupURL.GetString(sName, sizeof(sName));
    Format(sURL, sizeof(sURL), "https://steamcommunity.com/groups/%s", sName);
    WebFix_OpenUrl(client, "Easy Web Shortcuts", sURL);

    return Plugin_Continue;
}

public Action Command_Refresh(int client, int args)
{
    if (!IsClientValid(client))
    {
        return Plugin_Continue;
    }

    UpdateGroupStatus(client);

    return Plugin_Continue;
}

bool UpdateGroupStatus(int client)
{
    SteamWorks_GetUserGroupStatus(client, g_cGroupID.IntValue);
}

stock bool IsClientValid(int client, bool bots = false)
{
	if (client > 0 && client <= MaxClients)
	{
		if(IsClientInGame(client) && (bots || !IsFakeClient(client)) && !IsClientSourceTV(client))
		{
			return true;
		}
	}
	
	return false;
}

public int SteamWorks_OnClientGroupStatus(int authid, int groupid, bool isMember, bool isOfficer)
{
    int client = GetUserAuthID(authid);

    if (!IsClientValid(client))
    {
        return;
    }

    if (groupid == g_cGroupID.IntValue && isMember)
    {
        g_bStatus[client] = true;
        PrintToChat(client, "You are in our steam group!");
    }
    else
    {
        g_bStatus[client] = false;
        PrintToChat(client, "You aren't in our steam group!");
    }
}

int GetUserAuthID(int authid)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientValid(i))
        {
            char[] charauth = new char[64];
            char[] authchar = new char[64];
            GetClientAuthId(i, AuthId_Steam3, charauth, 64);
            IntToString(authid, authchar, 64);
            if (StrContains(charauth, authchar) != -1)
            {
                return i;
            }
        }
	}

	return -1;
}
