#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <retakes>
#include <myweaponallocator>

ConVar g_hHoldtime, g_hDelay;
float g_fHoldTime = 3.0, g_fDelay = 1.5;

public Plugin myinfo = 
{
	name = "Retake Bomsite HUD in New HTML HUD",
	author = "Cruze",
	description = "Displays bombsite in hud at roundstart.",
	version = "1.14",
	url = "http://steamcommunity.com/profiles/76561198132924835"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	
	g_hHoldtime = CreateConVar("sm_retakehud_holdtime", "3.0", "Hold time for the hud.", _, true, 1.0);
	g_hDelay = CreateConVar("sm_retakehud_delay", "1.5", "Delay after roundstart to display hud.");
	HookConVarChange(g_hHoldtime, OnCvarChange);
	HookConVarChange(g_hDelay, OnCvarChange);
	
	AutoExecConfig(true, "retakes-bombsiteinnewhud");
	
	LoadTranslations("retakesnewhud.phrases");
}

public int OnCvarChange(ConVar convar, const char[] oldVal, const char[] newVal)
{
	if(strcmp(oldVal, newVal) == 0)
	{
		return;
	}
	g_fHoldTime = g_hHoldtime.FloatValue;
	g_fDelay = g_hDelay.FloatValue;
}

public void OnAutoConfigsBuffered()
{
	g_fHoldTime = g_hHoldtime.FloatValue;
	g_fDelay = g_hDelay.FloatValue;
}

public Action Event_RoundStart(Event ev, const char[] name, bool dbc)
{
	if(IsWarmup())
    {
        return;
    }
	CreateTimer(g_fDelay, Timer_DisplayHUD);
}

public Action Timer_DisplayHUD(Handle timer)
{
	char sBuffer[256], sRound[64], sBombsite[8];
	int team = -1;
	MyWeaponAllocator_GetRoundName(sRound);
	Format(sBombsite, 8, "%s", Retakes_GetCurrrentBombsite() == BombsiteA ? "A" : "B");
	for(int i = 1; i <= MaxClients; i++) if(IsClientInGame(i) && !IsFakeClient(i))
	{
		team = GetClientTeam(i);
		if(team == 2)
		{
			if(!HasBomb(i))
			{
				Format(sBuffer, 256, "%T", "T_MSG", i, sBombsite, sRound);
			}
			else
			{
				Format(sBuffer, 256, "%T\n\n%T", "T_MSG", i, sBombsite, sRound, "PLANTER_MSG", i);
			}
		}
		else if(team == 3)
		{
			Format(sBuffer, 256, "%T", "CT_MSG", i, sBombsite, sRound);
		}
		DisplayHTMLHud(i, sBuffer);
		CreateTimer(g_fHoldTime, Timer_ClearHud, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_ClearHud(Handle timer, any userid)
{
	int client;
	if((client = GetClientOfUserId(userid)) == 0)
	{
		return;
	}
	if(!IsClientInGame(client))
	{
		return;
	}
	if(IsFakeClient(client))
	{
		return;
	}
	ClearHTMLHud(client);
}

void DisplayHTMLHud(int client, char[] sMsg)
{
	Event event = CreateEvent("cs_win_panel_round");

	if(event != null)
	{
		event.SetString("funfact_token", sMsg);

		event.FireToClient(client);
	}

	event.Cancel();
}

void ClearHTMLHud(int client)
{
	Event event = CreateEvent("round_start");

	if(event != null)
	{
		event.FireToClient(client);
	}

	event.Cancel(); 
}

stock bool HasBomb(int client)
{
    return GetPlayerWeaponSlot(client, CS_SLOT_C4) != -1;
}

stock bool IsWarmup()
{
    return GameRules_GetProp("m_bWarmupPeriod") == 1;
}
