/** Global variable used to check if a player is currently searching for a War Paint by name on chat. */
bool	 g_isSearchingForWarPaint[MAXPLAYERS + 1];

/** Global variable that saves menu state between a search and the results. */
DataPack g_searchData[MAXPLAYERS + 1];

/**
 * Callback handler for the main menu selections.
 */
public int MainMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the weapon entity ID and its name.
			char weaponEntityStr[12], weaponName[64];
			menu.GetItem(param, weaponEntityStr, sizeof(weaponEntityStr), _, weaponName, sizeof(weaponName));

			// If this is a special option, handle that first.
			if (StrEqual(weaponEntityStr, "reset"))
			{
				// Reset all inventory configurations for the player.
				TF2ItemPlugin_InitializeInventory(client);

				// Print a message to their chat to inform them of the reset.
				CPrintToChat(client, "%s Your weapon preferences have been reset to default values.", PLUGIN_CHATTAG);

				return 0;
			}

			if (StrEqual(weaponEntityStr, "load"))
			{
				// Launch a lookup for the player's preferences on SQLite.
				TF2ItemPlugin_SQL_SearchPlayerPreferences(client);

				// Print a message to their chat to inform them of the load.
				CPrintToChat(client, "%s Searching for your preferences...", PLUGIN_CHATTAG);

				return 0;
			}

			if (StrEqual(weaponEntityStr, "save"))
			{
				// Open a confirmation dialog.
				TF2ItemPlugin_Menus_PreferenceSaveMenu(client);

				return 0;
			}

			if (StrEqual(weaponEntityStr, "delete"))
			{
				// Open a confirmation dialog.
				TF2ItemPlugin_Menus_PreferenceDeleteMenu(client);

				return 0;
			}

			// Convert the string to an integer.
			int weaponEntity = StringToInt(weaponEntityStr);

			// Build and open the weapon menu.
			TF2ItemPlugin_Menus_WeaponMenu(client, param, weaponName, weaponEntity);
		}
	}

	return 0;
}

public int PreferenceSaveMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option.
			char option[64];
			menu.GetItem(param, option, sizeof(option));

			// Handle the selected option.
			if (StrEqual(option, "confirm"))
			{
				// Save the player's preferences to the SQLite database.
				TF2ItemPlugin_SQL_SavePlayerPreferences(client);

				// Print a message to their chat to inform them of the save.
				CPrintToChat(client, "%s Saving your preferences...", PLUGIN_CHATTAG);

				return 0;
			}
		}
	}

	return 0;
}

public int PreferenceDeleteMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option.
			char option[64];
			menu.GetItem(param, option, sizeof(option));

			// Handle the selected option.
			if (StrEqual(option, "confirm"))
			{
				// Delete the player's preferences from the SQLite database.
				TF2ItemPlugin_SQL_DeletePlayerPreferences(client);

				// Print a message to their chat to inform them of the deletion.
				CPrintToChat(client, "%s Deleting your preferences...", PLUGIN_CHATTAG);

				return 0;
			}
		}
	}

	return 0;
}

/**
 * Callback handler for the weapon menu selections.
 */
public int WeaponMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	// Obtain the hidden parameters' information.
	char weaponName[64], weaponStr[12], slotStr[2];
	menu.GetItem(0, weaponName, sizeof(weaponName));
	menu.GetItem(1, weaponStr, sizeof(weaponStr));
	menu.GetItem(2, slotStr, sizeof(slotStr));

	// Convert the weapon string to an integer.
	int weapon = StringToInt(weaponStr), slot = StringToInt(slotStr);

	// If client had changed classes or the weapon entity is no longer valid, return and do nothing.
	if (!IsValidEdict(weapon) || !IsValidEdict(client)) return 0;

	// If the weapon edict is not a weapon, return and do nothing.
	char edictClassName[64];
	GetEdictClassname(weapon, edictClassName, sizeof(edictClassName));

	if (StrContains(edictClassName, "tf_weapon_", false) == -1 && !StrEqual(edictClassName, "saxxy")) return 0;

	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option.
			char option[64];
			menu.GetItem(param, option, sizeof(option));

			// Handle the selected option.
			if (StrEqual(option, "override"))
			{
				// Activate the override for the slot and class.
				int class = TF2_GetPlayerClassInt(client), itemDefinitionIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"),
					quality = GetEntProp(weapon, Prop_Send, "m_iEntityQuality"), level = GetEntProp(weapon, Prop_Send, "m_iEntityLevel");

				// Convert the weapon definition index to a variant if it is a stock weapon.
				int strangeVariantIndex = TF2ItemPlugin_GetStrangeVariant(itemDefinitionIndex);

				// If a stock weapon was converted, set it on the loadout information.
				if (strangeVariantIndex != itemDefinitionIndex && strangeVariantIndex != -1) g_inventories[client][class][slot].stockWeaponDefIndex = itemDefinitionIndex;

				// Toggle the slot override status.
				TF2ItemPlugin_ToggleSlotOverride(client, class, slot, strangeVariantIndex == -1 ? itemDefinitionIndex : strangeVariantIndex, quality, level);
			}

			if (StrEqual(option, "australium"))
				// Toggle the Australium status.
				TF2ItemPlugin_ToggleAustralium(client, slot);

			if (StrEqual(option, "festive"))
				// Toggle the Festive status.
				TF2ItemPlugin_ToggleFestive(client, slot);

			if (StrEqual(option, "killstreak"))
			{
				// Open the sub-menu for the killstreak selection.
				TF2ItemPlugin_Menus_KillstreakMenu(client, slot, weaponName, weapon);

				// Prevent a rebuild of the next menu.
				return 0;
			}

			if (StrEqual(option, "spells"))
			{
				// Open the sub-menu for the Halloween spell selection.
				TF2ItemPlugin_Menus_SpellsMenu(client, slot, weaponName, weapon);

				// Prevent a rebuild of the next menu.
				return 0;
			}

			if (StrEqual(option, "unusual"))
			{
				// Open the sub-menu for the unusual effect selection.
				TF2ItemPlugin_Menus_UnusualMenu(client, slot, weaponName, weapon);

				// Prevent a rebuild of the next menu.
				return 0;
			}

			if (StrEqual(option, "warPaint"))
			{
				// Open the sub-menu for the War Paint selection.
				TF2ItemPlugin_Menus_WarPaintMenu(client, slot, weaponName, weapon);

				// Prevent a rebuild of the next menu.
				return 0;
			}

			if (StrEqual(option, "warPaintWear"))
			{
				// Open the sub-menu for the War Paint wear selection.
				TF2ItemPlugin_Menus_WarPaintWearMenu(client, slot, weaponName, weapon);

				// Prevent a rebuild of the next menu.
				return 0;
			}

			// Rebuild the weapons menu after some miliseconds to allow for the changes to take effect (probably a strange variant being given).
			DataPack data = new DataPack();
			data.WriteCell(client);
			data.WriteCell(slot);
			data.WriteString(weaponName);
			data.WriteString("rebuild_weapons");

			CreateTimer(0.15, TF2ItemPlugin_Menus_HandleMenuRebuild, data, TIMER_FLAG_NO_MAPCHANGE);
		}
		case MenuAction_Cancel:
		{
			// Check if the user tried going back.
			if (param == MenuCancel_ExitBack)
				// Rebuild the main menu.
				TF2ItemPlugin_Menus_MainMenu(client);
		}
	}

	return 0;
}

/**
 * Callback handler for the killstreak menu selections.
 */
public int KillstreakMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	// Obtain the hidden parameters' information.
	char weaponStr[12], slotStr[2], weaponName[64];
	menu.GetItem(0, weaponName, sizeof(weaponName));
	menu.GetItem(1, weaponStr, sizeof(weaponStr));
	menu.GetItem(2, slotStr, sizeof(slotStr));

	// Convert the weapon string to an integer.
	int weapon = StringToInt(weaponStr), slot = StringToInt(slotStr);

	// If client had changed classes or the weapon entity is no longer valid, return and do nothing.
	if (!IsValidEdict(weapon) || !IsValidEdict(client)) return 0;

	// If the weapon edict is not a weapon, return and do nothing.
	char edictClassName[64];
	GetEdictClassname(weapon, edictClassName, sizeof(edictClassName));

	if (StrContains(edictClassName, "tf_weapon_", false) == -1 && !StrEqual(edictClassName, "saxxy")) return 0;

	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option.
			char option[64];
			menu.GetItem(param, option, sizeof(option));

			// Handle the selected option.
			if (StrEqual(option, "override"))
				// Activate the override for the slot and class.
				TF2ItemPlugin_ToggleKillstreakOverride(client, slot);

			if (StrEqual(option, "tier"))
				// Set the killstreak tier accordingly.
				TF2ItemPlugin_ChangeKillstreakTier(client, slot);

			if (StrEqual(option, "sheen"))
			{
				// Open the sub-menu for the sheen selection.
				TF2ItemPlugin_Menus_KillstreakSheenMenu(client, slot, weaponName, weapon);

				// Prevent a rebuild of the next menu.
				return 0;
			}

			if (StrEqual(option, "killstreaker"))
			{
				// Open the sub-menu for the killstreak effect selection.
				TF2ItemPlugin_Menus_KillstreakerMenu(client, slot, weaponName, weapon);

				// Prevent a rebuild of the next menu.
				return 0;
			}

			// Rebuild the killstreak menu after some miliseconds to allow for the changes to take effect.
			DataPack data = new DataPack();
			data.WriteCell(client);
			data.WriteCell(slot);
			data.WriteString(weaponName);
			data.WriteString("rebuild_killstreak");

			CreateTimer(0.15, TF2ItemPlugin_Menus_HandleMenuRebuild, data, TIMER_FLAG_NO_MAPCHANGE);
		}
		case MenuAction_Cancel:
		{
			// Check if the user tried going back.
			if (param == MenuCancel_ExitBack)
				// Rebuild the weapon menu.
				TF2ItemPlugin_Menus_WeaponMenu(client, slot, weaponName, weapon);
		}
	}

	return 0;
}

/**
 * Callback handler for the killstreak sheen menu selections.
 */
public int KillstreakOptionsMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	// Obtain the hidden parameters' information.
	char weaponStr[12], slotStr[2], weaponName[64], optionStr[24];
	menu.GetItem(0, weaponName, sizeof(weaponName));
	menu.GetItem(1, weaponStr, sizeof(weaponStr));
	menu.GetItem(2, slotStr, sizeof(slotStr));
	menu.GetItem(3, optionStr, sizeof(optionStr));

	// Convert the weapon string to an integer.
	int weapon = StringToInt(weaponStr), slot = StringToInt(slotStr);

	// If client had changed classes or the weapon entity is no longer valid, return and do nothing.
	if (!IsValidEdict(weapon) || !IsValidEdict(client)) return 0;

	// If the weapon edict is not a weapon, return and do nothing.
	char edictClassName[64];
	GetEdictClassname(weapon, edictClassName, sizeof(edictClassName));

	if (StrContains(edictClassName, "tf_weapon_", false) == -1 && !StrEqual(edictClassName, "saxxy")) return 0;

	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option.
			char option[64];
			menu.GetItem(param, option, sizeof(option));

			// Transform the option to an integer.
			int effect = StringToInt(option);

			// Handle the selected option.
			if (StrEqual(optionStr, "sheen"))
				// Set the killstreak sheen accordingly.
				TF2ItemPlugin_SetKillstreakSheen(client, slot, effect);
			if (StrEqual(optionStr, "killstreaker"))
				// Set the killstreak effect accordingly.
				TF2ItemPlugin_SetKillstreakerEffect(client, slot, effect);

			// Rebuild the killstreak menu after some miliseconds to allow for the changes to take effect.
			DataPack data = new DataPack();
			data.WriteCell(client);
			data.WriteCell(slot);
			data.WriteString(weaponName);
			data.WriteString("rebuild_killstreak");

			CreateTimer(0.15, TF2ItemPlugin_Menus_HandleMenuRebuild, data, TIMER_FLAG_NO_MAPCHANGE);
		}
		case MenuAction_Cancel:
		{
			// Check if the user tried going back.
			if (param == MenuCancel_ExitBack)
				// Rebuild the killstreak menu.
				TF2ItemPlugin_Menus_KillstreakMenu(client, slot, weaponName, weapon);
		}
	}

	return 0;
}

/**
 * Callback to handle selections in the spells menu.
 */
public int SpellsMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	// Obtain the hidden parameters' information.
	char weaponStr[12], slotStr[2], weaponName[64];
	menu.GetItem(0, weaponName, sizeof(weaponName));
	menu.GetItem(1, weaponStr, sizeof(weaponStr));
	menu.GetItem(2, slotStr, sizeof(slotStr));

	// Convert the weapon string to an integer.
	int weapon = StringToInt(weaponStr), slot = StringToInt(slotStr);

	// If client had changed classes or the weapon entity is no longer valid, return and do nothing.
	if (!IsValidEdict(weapon) || !IsValidEdict(client)) return 0;

	// If the weapon edict is not a weapon, return and do nothing.
	char edictClassName[64];
	GetEdictClassname(weapon, edictClassName, sizeof(edictClassName));

	if (StrContains(edictClassName, "tf_weapon_", false) == -1 && !StrEqual(edictClassName, "saxxy")) return 0;

	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option.
			char option[64];
			menu.GetItem(param, option, sizeof(option));

			// Transform the option to an integer.
			int spell = StringToInt(option);

			// Handle the selected option.
			if (StrEqual(option, "override"))
				// Activate the override for the slot and class.
				TF2ItemPlugin_ToggleSpellOverride(client, slot);

			else {
				// Check if it's already set.
				bool isSet = view_as<bool>(g_inventories[client][TF2_GetPlayerClassInt(client)][slot].halloweenSpell.spells & (1 << spell));

				// Set the Halloween spell accordingly.
				TF2ItemPlugin_SetHalloweenSpell(client, slot, spell, isSet);
			}

			// Rebuild the spells menu after some miliseconds to allow for the changes to take effect.
			DataPack data = new DataPack();
			data.WriteCell(client);
			data.WriteCell(slot);
			data.WriteString(weaponName);
			data.WriteString("rebuild_spells");

			CreateTimer(0.15, TF2ItemPlugin_Menus_HandleMenuRebuild, data, TIMER_FLAG_NO_MAPCHANGE);
		}
		case MenuAction_Cancel:
		{
			// Check if the user tried going back.
			if (param == MenuCancel_ExitBack)
				// Rebuild the weapon menu.
				TF2ItemPlugin_Menus_WeaponMenu(client, slot, weaponName, weapon);
		}
	}

	return 0;
}

/**
 * Callback to handle selections within the unusual effects menu.
 */
public int UnusualMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	// Obtain the hidden parameters' information.
	char weaponStr[12], slotStr[2], weaponName[64];
	menu.GetItem(0, weaponName, sizeof(weaponName));
	menu.GetItem(1, weaponStr, sizeof(weaponStr));
	menu.GetItem(2, slotStr, sizeof(slotStr));

	// Convert the weapon string to an integer.
	int weapon = StringToInt(weaponStr), slot = StringToInt(slotStr);

	// If client had changed classes or the weapon entity is no longer valid, return and do nothing.
	if (!IsValidEdict(weapon) || !IsValidEdict(client)) return 0;

	// If the weapon edict is not a weapon, return and do nothing.
	char edictClassName[64];
	GetEdictClassname(weapon, edictClassName, sizeof(edictClassName));

	if (StrContains(edictClassName, "tf_weapon_", false) == -1 && !StrEqual(edictClassName, "saxxy")) return 0;

	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option.
			char option[64];
			menu.GetItem(param, option, sizeof(option));

			// Transform the option to an integer.
			int effect = StringToInt(option);

			// Handle the selected option.
			if (StrEqual(option, "clear"))
				// Reset the unusual effect to its default value.
				TF2ItemPlugin_SetUnusualEffect(client, slot, -1);

			else
				// Set the unusual effect accordingly.
				TF2ItemPlugin_SetUnusualEffect(client, slot, effect);

			// Rebuild the unusual effects menu after some miliseconds to allow for the changes to take effect.
			DataPack data = new DataPack();
			data.WriteCell(client);
			data.WriteCell(slot);
			data.WriteString(weaponName);
			data.WriteString("rebuild_unusual");

			CreateTimer(0.15, TF2ItemPlugin_Menus_HandleMenuRebuild, data, TIMER_FLAG_NO_MAPCHANGE);
		}
		case MenuAction_Cancel:
		{
			// Check if the user tried going back.
			if (param == MenuCancel_ExitBack)
				// Rebuild the weapon menu.
				TF2ItemPlugin_Menus_WeaponMenu(client, slot, weaponName, weapon);
		}
	}

	return 0;
}

/**
 * Callback that handles War Paint menu selections.
 */
public int WarPaintMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	// Obtain the hidden parameters' information.
	char weaponStr[12], slotStr[2], weaponName[64];
	menu.GetItem(0, weaponName, sizeof(weaponName));
	menu.GetItem(1, weaponStr, sizeof(weaponStr));
	menu.GetItem(2, slotStr, sizeof(slotStr));

	// Convert the weapon string to an integer.
	int weapon = StringToInt(weaponStr), slot = StringToInt(slotStr);

	// If client had changed classes or the weapon entity is no longer valid, return and do nothing.
	if (!IsValidEdict(weapon) || !IsValidEdict(client)) return 0;

	// If the weapon edict is not a weapon, return and do nothing.
	char edictClassName[64];
	GetEdictClassname(weapon, edictClassName, sizeof(edictClassName));

	if (StrContains(edictClassName, "tf_weapon_", false) == -1 && !StrEqual(edictClassName, "saxxy")) return 0;

	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option.
			char option[64];
			menu.GetItem(param, option, sizeof(option));

			// Transform the option to an integer.
			int paint = StringToInt(option);

			// Handle the selected option.
			if (StrEqual(option, "clear"))
				// Reset the War Paint to its default value.
				TF2ItemPlugin_SetWarPaint(client, slot, -1);

			if (StrEqual(option, "search"))
			{
				// Set the player as searching for a War Paint by name.
				g_isSearchingForWarPaint[client] = true;

				// Build a DataPack to transfer weapon & slot information to the search handler.
				DataPack data					 = new DataPack();
				data.WriteCell(slot);
				data.WriteCell(weapon);
				data.WriteString(weaponName);

				g_searchData[client] = data;

				// Initiate a timer to timeout the user's search.
				float timeOut		 = g_cvar_weapons_searchTimeout.FloatValue;
				CreateTimer(timeOut, TF2ItemPlugin_WarPaintSearchTimeoutHandler, client, TIMER_FLAG_NO_MAPCHANGE);

				// Print a message to the player's chat to inform them of the search.
				CPrintToChat(client, "%s Enter the name of the War Paint you want to search for. You have %d second(s).", PLUGIN_CHATTAG, RoundToNearest(timeOut));

				return 0;
			}

			else
				// Set the War Paint accordingly.
				TF2ItemPlugin_SetWarPaint(client, slot, paint);

			// Rebuild the War Paint menu after some miliseconds to allow for the changes to take effect.
			DataPack data = new DataPack();
			data.WriteCell(client);
			data.WriteCell(slot);
			data.WriteString(weaponName);
			data.WriteString("rebuild_war_paint");

			CreateTimer(0.15, TF2ItemPlugin_Menus_HandleMenuRebuild, data, TIMER_FLAG_NO_MAPCHANGE);
		}
		case MenuAction_Cancel:
		{
			// Check if the user tried going back.
			if (param == MenuCancel_ExitBack)
				// Rebuild the weapon menu.
				TF2ItemPlugin_Menus_WeaponMenu(client, slot, weaponName, weapon);
		}
	}

	return 0;
}

public int WarPaintWearMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	// Obtain the hidden parameters' information.
	char weaponStr[12], slotStr[2], weaponName[64];
	menu.GetItem(0, weaponName, sizeof(weaponName));
	menu.GetItem(1, weaponStr, sizeof(weaponStr));
	menu.GetItem(2, slotStr, sizeof(slotStr));

	// Convert the weapon string to an integer.
	int weapon = StringToInt(weaponStr), slot = StringToInt(slotStr);

	// If client had changed classes or the weapon entity is no longer valid, return and do nothing.
	if (!IsValidEdict(weapon) || !IsValidEdict(client)) return 0;

	// If the weapon edict is not a weapon, return and do nothing.
	char edictClassName[64];
	GetEdictClassname(weapon, edictClassName, sizeof(edictClassName));

	if (StrContains(edictClassName, "tf_weapon_", false) == -1 && !StrEqual(edictClassName, "saxxy")) return 0;

	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option.
			char option[64];
			menu.GetItem(param, option, sizeof(option));

			// Transform the option to a float.
			int	  wearIndex = StringToInt(option);

			// Obtain the floating value.
			float wear		= TF2ItemPlugin_GetPaintWearFromIndex(wearIndex);

			// Set the War Paint wear accordingly.
			TF2ItemPlugin_SetWarPaintWear(client, slot, wear);

			// Rebuild the War Paint menu after some miliseconds to allow for the changes to take effect.
			DataPack data = new DataPack();
			data.WriteCell(client);
			data.WriteCell(slot);
			data.WriteString(weaponName);
			data.WriteString("rebuild_war_paint");

			CreateTimer(0.15, TF2ItemPlugin_Menus_HandleMenuRebuild, data, TIMER_FLAG_NO_MAPCHANGE);
		}
		case MenuAction_Cancel:
		{
			// Check if the user tried going back.
			if (param == MenuCancel_ExitBack)
				// Rebuild the weapon menu.
				TF2ItemPlugin_Menus_WeaponMenu(client, slot, weaponName, weapon);
		}
	}

	return 0;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] query)
{
	// Ignore non-searching players.
	if (!g_isSearchingForWarPaint[client]) return Plugin_Continue;

	// Take the query and search for a War Paint with that name (or ID) (case-insensitive).
	StringMap paints[MAX_PAINTS];

	int		  lastInsertedPaintIndex = 0;
	for (int i = 0; i < MAX_PAINTS; i++)
	{
		if (g_paintKits[i] == null) continue;

		// Obtain the paint kit name.
		char paintName[128];
		g_paintKits[i].GetString("name", paintName, sizeof(paintName));

		// Check if the paint name contains the query.
		if (StrContains(paintName, query, false) != -1)
		{
			// Store the paint kit information on the global variable.
			paints[lastInsertedPaintIndex] = new StringMap();

			int id						   = -1;
			g_paintKits[i].GetValue("id", id);

			paints[lastInsertedPaintIndex].SetValue("id", id);
			paints[lastInsertedPaintIndex].SetString("name", paintName);

			lastInsertedPaintIndex++;
		}
	}

	// Turn off the search status.
	g_isSearchingForWarPaint[client] = false;

	// Fetch the DataPack from the global.
	DataPack data					 = g_searchData[client];
	data.Reset();

	int	 slot = data.ReadCell(), weapon = data.ReadCell();
	char weaponName[64];
	data.ReadString(weaponName, sizeof(weaponName));

	// Clear the old DataPack.
	delete g_searchData[client];

	// Build and open the results menu with the result paints.
	TF2ItemPlugin_Menus_WarPaintMenu_SearchResults(client, slot, weaponName, weapon, paints, lastInsertedPaintIndex + 1);

	return Plugin_Handled;
}

public Action TF2ItemPlugin_WarPaintSearchTimeoutHandler(Handle timer, int client)
{
	if (!g_isSearchingForWarPaint[client]) return Plugin_Stop;

	// Reset the player's search status.
	g_isSearchingForWarPaint[client] = false;

	// Print a message to the player's chat to inform them of the timeout.
	CPrintToChat(client, "%s Your War Paint search has timed out.", PLUGIN_CHATTAG);

	return Plugin_Stop;
}