#pragma semicolon               1
#pragma newdecls                required

#include <sourcemod>
#include <sdktools_sound>
#include <colors>


public Plugin myinfo = {
	name = "TankAnnounce",
	author = "Visor",
	description = "Announce when a Tank has spawned",
	version = "build_0000",
	url = ""
}


#define TRANSLATIONS            "tank_announce.phrases"

#define DEFAULT_NOTIFY_SOUND    "ui/pickup_secret01.wav"

#define SI_CLASS_TANK           8

/*
 * Team.
 */
#define TEAM_INFECTED           3


enum
{
	NOTIFY_SOUND = (1 << 0),
	NOTIFY_CHAT = (1 << 1)
}

char g_sNotifySound[PLATFORM_MAX_PATH];

ConVar
	g_cvNotifyType = null,
	g_cvNotifySound = null
;

/**
 *
 */
public void OnMapStart()
{
	GetConVarString(g_cvNotifySound, g_sNotifySound, sizeof(g_sNotifySound));

	if (!IsSoundExists(g_sNotifySound)) {
		strcopy(g_sNotifySound, sizeof(g_sNotifySound), DEFAULT_NOTIFY_SOUND);
	}

	PrecacheSound(g_sNotifySound);
}

/**
 *
 */
public void OnPluginStart()
{
	LoadTranslations(TRANSLATIONS);

	g_cvNotifyType = CreateConVar("sm_tank_announce_notify_type", \
		"3", \
		"Notify type (0: Disable, 1: Sound, 2: Chat)", \
		_, false, 0.0, true, 3.0 \
	);

	g_cvNotifySound = CreateConVar("sm_tank_announce_notify_sound", \
		DEFAULT_NOTIFY_SOUND, \
		"Path to the sound that is played when tank has spawned" \
	);

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

/**
 *
 */
void Event_PlayerSpawn(Event event, char[] sEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!iClient
	|| !IsClientInGame(iClient)
	|| IsFakeClient(iClient)
	|| !IsClientInfected(iClient)
	|| !IsClientTank(iClient)) {
		return;
	}

	int iNotifyType = GetConVarInt(g_cvNotifyType);

	if (!iNotifyType) {
		return;
	}

	if (iNotifyType & NOTIFY_SOUND) {
		PlayNotifySound();
	}

	if (iNotifyType & NOTIFY_CHAT)
	{
		char sName[MAX_NAME_LENGTH];
		GetClientNameFixed(iClient, sName, sizeof(sName), 18);

		CPrintToChatAll("%t%t", "TAG", "TANK_ANNOUNCE", sName);
	}
}

/**
 *
 */
bool IsSoundExists(const char[] sSoundPath)
{
	char szPath[PLATFORM_MAX_PATH];
	FormatEx(szPath, sizeof(szPath), "sound/%s", sSoundPath);

	return (FileExists(szPath, true));
}

/**
 *
 */
void PlayNotifySound() {
	EmitSoundToAll(g_sNotifySound);
}

/**
 * Returns whether the player is infected.
 */
bool IsClientInfected(int iClient) {
	return (GetClientTeam(iClient) == TEAM_INFECTED);
}

/**
 * Gets the client L4D1/L4D2 zombie class id.
 *
 * @param client     Client index.
 * @return L4D1      1=SMOKER, 2=BOOMER, 3=HUNTER, 4=WITCH, 5=TANK, 6=NOT INFECTED
 * @return L4D2      1=SMOKER, 2=BOOMER, 3=HUNTER, 4=SPITTER, 5=JOCKEY, 6=CHARGER, 7=WITCH, 8=TANK, 9=NOT INFECTED
 */
int GetClientClass(int iClient) {
	return GetEntProp(iClient, Prop_Send, "m_zombieClass");
}

/**
 *
 */
bool IsClientTank(int iClient) {
	return (GetClientClass(iClient) == SI_CLASS_TANK);
}

/**
 *
 */
void GetClientNameFixed(int iClient, char[] name, int length, int iMaxSize)
{
	GetClientName(iClient, name, length);

	if (strlen(name) > iMaxSize)
	{
		name[iMaxSize - 3] = name[iMaxSize - 2] = name[iMaxSize - 1] = '.';
		name[iMaxSize] = '\0';
	}
}
