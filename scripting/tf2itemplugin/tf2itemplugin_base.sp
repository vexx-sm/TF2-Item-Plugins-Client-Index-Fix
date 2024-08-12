#include <sourcemod>
#include <lang>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>

#include <SteamWorks>
#include <smjansson>

#include <morecolors>

#include <tf2items>
#include <tf2attributes>
#include <tf_econ_data>

#pragma dynamic 131072

#define PLUGIN_CHATTAG "{mythical}[TF2Items]{white}"

#define MAX_WEAPONS	   3
#define MAX_COSMETICS  3
#define MAX_CLASSES	   9

/**
 * Obtains the class name of a class ID for visual representation.
 *
 * @param class The `TFClassType` class ID to obtain the name for.
 * @param buffer The buffer to store the class name.
 * @param size The size of the buffer.
 *
 * @return void
 */
stock void TF2ItemPlugin_GetTFClassName(TFClassType class, char[] buffer, int size)
{
	switch (class)
	{
		case TFClass_Scout: strcopy(buffer, size, "Scout");
		case TFClass_Soldier: strcopy(buffer, size, "Soldier");
		case TFClass_Pyro: strcopy(buffer, size, "Pyro");
		case TFClass_DemoMan: strcopy(buffer, size, "Demoman");
		case TFClass_Heavy: strcopy(buffer, size, "Heavy");
		case TFClass_Engineer: strcopy(buffer, size, "Engineer");
		case TFClass_Medic: strcopy(buffer, size, "Medic");
		case TFClass_Sniper: strcopy(buffer, size, "Sniper");
		case TFClass_Spy: strcopy(buffer, size, "Spy");
		default: strcopy(buffer, size, "Unknown");
	}
}

/**
 * Obtains the player class of a client and returns it as an integer.
 *
 * @param client Client index to obtain the class for.
 *
 * @return The player class of the client.
 */
stock int TF2_GetPlayerClassInt(int client)
{
	return view_as<int>(TF2_GetPlayerClass(client));
}

/**
 * Applies changes to a user and regenerates their loadout.
 *
 * @param client The client ID to apply the changes for.
 * @param hRegen The handle to the "Regenerate" SDK call.
 * @param clipOff The offset for the clip value.
 * @param ammoOff The offset for the ammo value.
 * @param slot Optional. If set, the slot on which to change after regenerating their loadout.
 *
 * @return void
 */
void TF2ItemPlugin_RegenerateLoadout(int client, Handle& hRegen, int& clipOff, int& ammoOff, int slot = 0)
{
	// Get the actual HP, clip and ammo for the current weapon we're forcing the change on.
	int	  hp   = GetClientHealth(client), clip[2], ammo[2];

	// If the player is a Medic, we would also want to maintain their Übercharge for the change.
	float uber = -1.0;

	if (TF2_GetPlayerClass(client) == TFClass_Medic)
		uber = GetEntPropFloat(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_flChargeLevel");

	// Fill the Ammo and Clip values for later restoration
	for (int i = 0; i < sizeof(clip); i++)
	{
		int wep = GetPlayerWeaponSlot(client, i);
		if (wep != INVALID_ENT_REFERENCE)
		{
			int ammoOff2 = GetEntProp(wep, Prop_Send, "m_iPrimaryAmmoType", 1) * 4 + ammoOff;

			clip[i]		 = GetEntData(wep, clipOff);
			ammo[i]		 = GetEntData(wep, ammoOff2);
		}
	}

	// Remove all weapons from the client.
	TF2_RemoveAllWeapons(client);

	// Call the "Regenerate" function.
	SDKCall(hRegen, client, 0);

	// Restore everything
	SetEntityHealth(client, hp);
	if (uber > -1.0)
	{
		// Create a DataPack to later restore Ubercharge after a short delay.
		DataPack data = new DataPack();
		data.WriteCell(client);
		data.WriteFloat(uber);

		// Create a timer to restore the Übercharge after a short delay.
		CreateTimer(0.1, TF2ItemPlugin_RestoreUber, data);
	}

	for (int i = 0; i < sizeof(clip); i++)
	{
		int wep = GetPlayerWeaponSlot(client, i);
		if (wep != INVALID_ENT_REFERENCE)
		{
			int ammoOff2 = GetEntProp(wep, Prop_Send, "m_iPrimaryAmmoType", 1) * 4 + ammoOff;

			SetEntData(wep, clipOff, clip[i]);
			SetEntData(wep, ammoOff2, ammo[i]);
		}
	}

	// Set active weapon as the changed one
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, slot));
}

public Action TF2ItemPlugin_RestoreUber(Handle timer, DataPack data)
{
	// Reset the DataPack's index to the start.
	data.Reset();

	// Retrieve the client and Übercharge value.
	int	  client  = data.ReadCell();
	float uber	  = data.ReadFloat();

	// Obtain the player's Medigun.
	int	  medigun = GetPlayerWeaponSlot(client, 1);

	// If the Medigun is still valid, restore the Übercharge.
	if (medigun != INVALID_ENT_REFERENCE)
		SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", uber);

	// Destroy the DataPack.
	delete data;

	// Return Plugin_Stop to stop the timer.
	return Plugin_Stop;
}
