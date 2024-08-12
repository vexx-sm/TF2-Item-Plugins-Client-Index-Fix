/** Global variable used to check if a player is currently searching for an Unusual effect by name on chat. */
bool	 g_isSearchingForUnusual[MAXPLAYERS + 1];

/** Global variable that saves menu state between a search and the results. */
DataPack g_searchData[MAXPLAYERS + 1];

/**
 * Function that provides an integrity check for in-between menu actions.
 *
 * This prevents the handling of invalid or unexpected menu actions with deleted/invalid entity indices.
 *
 * @param client The client index whose menu action is being handled.
 * @param slot The slot index that is being checked.
 * @param cosmetic The cosmetic entity index that is being modified.
 *
 * @return True if everything is okay.
 */
bool	 TF2ItemPlugin_Menus_ValidateMenuAction(int client, int slot, int cosmetic)
{
	// Ensure the client is valid.
	if (client < 1 || !IsClientInGame(client) || IsClientObserver(client) || IsClientSourceTV(client) || !IsPlayerAlive(client))
		return false;

	// Ensure the slot is valid.
	if (slot < 0 || slot >= MAX_COSMETICS)
		return false;

	// Ensure the cosmetic is a valid entity.
	if (!IsValidEdict(cosmetic))
		return false;

	// Ensure the cosmetic is a wearable.
	char classname[64];
	GetEdictClassname(cosmetic, classname, sizeof(classname));

	if (StrContains(classname, "tf_wearable") == -1)
		return false;

	// Everything is fine.
	return true;
}

/**
 * Handles the main menu selections.
 */
public int MainMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected cosmetic.
			char option[12];
			menu.GetItem(param, option, sizeof(option));

			// First handle preset options.

			if (StrEqual(option, "load"))
			{
				// Launch a lookup for the player's preferences on SQLite.
				TF2ItemPlugin_SQL_SearchPlayerPreferences(client);

				// Print a message to their chat to inform them of the load.
				CPrintToChat(client, "%s Searching for your preferences...", PLUGIN_CHATTAG);

				return 0;
			}

			if (StrEqual(option, "save"))
			{
				// Open a confirmation dialog.
				TF2ItemPlugin_Menus_PreferenceSaveMenu(client);

				return 0;
			}

			if (StrEqual(option, "delete"))
			{
				// Open a confirmation dialog.
				TF2ItemPlugin_Menus_PreferenceDeleteMenu(client);

				return 0;
			}

			if (StrEqual(option, "reset"))
			{
				// Initialize the client's inventory again.
				TF2ItemPlugin_InitializeInventory(client);

				// Inform the client.
				CPrintToChat(client, "%s Your cosmetic preferences have been reset.", PLUGIN_CHATTAG);

				return 0;
			}

			// Convert the option to an integer (cosmetic entity index).
			int	 cosmetic		= StringToInt(option);

			// Perform an integrity check.
			bool integrityCheck = TF2ItemPlugin_Menus_ValidateMenuAction(client, param, cosmetic);
			if (!integrityCheck) return 0;

			// Render the cosmetic menu.
			TF2ItemPlugin_Menus_CosmeticMenu(client, param, cosmetic);
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

public int CosmeticMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	// Obtain the menu hidden data values.
	int	 cosmetic = -1, slot = -1;

	char cosmeticStr[12], slotStr[12];
	menu.GetItem(0, cosmeticStr, sizeof(cosmeticStr));
	menu.GetItem(1, slotStr, sizeof(slotStr));

	cosmetic			= StringToInt(cosmeticStr);
	slot				= StringToInt(slotStr);

	// Perform an integrity check.
	bool integrityCheck = TF2ItemPlugin_Menus_ValidateMenuAction(client, slot, cosmetic);
	if (!integrityCheck) return 0;

	// Obtain the item definition index of the cosmetic.
	int itemDefIndex = GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex");

	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option.
			char option[12];
			menu.GetItem(param, option, sizeof(option));

			// Handle the option.
			if (StrEqual(option, "override"))
			{
				// Toggle the slot's override status.
				TF2ItemPlugin_ToggleCosmeticSlotOverride(client, slot, itemDefIndex);

				// Rebuild the menu again.
				TF2ItemPlugin_Menus_CosmeticMenu(client, slot, cosmetic);

				return 0;
			}

			if (StrEqual(option, "unusual"))
			{
				// Open the Unusual effects menu.
				TF2ItemPlugin_Menus_UnusualMenu(client, slot, cosmetic);

				return 0;
			}

			if (StrEqual(option, "paint"))
			{
				// Open the paint menu.
				TF2ItemPlugin_Menus_PaintMenu(client, slot, cosmetic);

				return 0;
			}

			if (StrEqual(option, "halloween"))
			{
				// Open the Halloween menu.
				TF2ItemPlugin_Menus_HalloweenMenu(client, slot, cosmetic);

				return 0;
			}
		}
		case MenuAction_Cancel:
		{
			if (param == MenuCancel_ExitBack)
				// Render the previous menu.
				TF2ItemPlugin_Menus_MainMenu(client);
		}
	}

	return 0;
}

public int UnusualMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	// Obtain the menu hidden data values.
	int	 cosmetic = -1, slot = -1;

	char cosmeticStr[12], slotStr[12];
	menu.GetItem(0, cosmeticStr, sizeof(cosmeticStr));
	menu.GetItem(1, slotStr, sizeof(slotStr));

	cosmetic			= StringToInt(cosmeticStr);
	slot				= StringToInt(slotStr);

	// Perform an integrity check.
	bool integrityCheck = TF2ItemPlugin_Menus_ValidateMenuAction(client, slot, cosmetic);
	if (!integrityCheck) return 0;

	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option.
			char option[12];
			menu.GetItem(param, option, sizeof(option));

			// Handle preset options first.
			if (StrEqual(option, "clear"))
			{
				// Clear the unusual effect override.
				TF2ItemPlugin_SetCosmeticSlotUnusualEffect(client, slot, -1);

				// Rebuild the previous menu.
				TF2ItemPlugin_Menus_CosmeticMenu(client, slot, cosmetic);

				return 0;
			}

			if (StrEqual(option, "search"))
			{
				// Set the player as searching for a Unusual effect by name.
				g_isSearchingForUnusual[client] = true;

				// Build a DataPack to transfer cosmetic & slot information to the search handler.
				DataPack data					= new DataPack();
				data.WriteCell(slot);
				data.WriteCell(cosmetic);

				g_searchData[client] = data;

				// Initiate a timer to timeout the user's search.
				float timeOut		 = g_cvar_cosmetics_searchTimeout.FloatValue;
				CreateTimer(timeOut, TF2ItemPlugin_UnusualSearchTimeoutHandler, client, TIMER_FLAG_NO_MAPCHANGE);

				// Print a message to the player's chat to inform them of the search.
				CPrintToChat(client, "%s Enter the name of the Unusual effect you want to search for. You have %d second(s).", PLUGIN_CHATTAG, RoundToNearest(timeOut));

				return 0;
			}

			// Convert the option to an integer (unusual effect ID).
			int unusualEffect = StringToInt(option);

			// Set the unusual effect override.
			TF2ItemPlugin_SetCosmeticSlotUnusualEffect(client, slot, unusualEffect);

			// Rebuild the previous menu.
			DataPack data = new DataPack();
			data.WriteCell(client);
			data.WriteCell(slot);
			data.WriteCell(GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex"));
			data.WriteString("rebuild_cosmetic");

			CreateTimer(0.1, TF2ItemPlugin_Menus_HandleMenuRebuild, data);
		}
		case MenuAction_Cancel:
		{
			if (param == MenuCancel_ExitBack)
				// Render the previous menu.
				TF2ItemPlugin_Menus_CosmeticMenu(client, slot, cosmetic);
		}
	}

	return 0;
}

public int PaintMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	// Obtain the menu hidden data values.
	int	 cosmetic = -1, slot = -1;

	char cosmeticStr[12], slotStr[12];
	menu.GetItem(0, cosmeticStr, sizeof(cosmeticStr));
	menu.GetItem(1, slotStr, sizeof(slotStr));

	cosmetic			= StringToInt(cosmeticStr);
	slot				= StringToInt(slotStr);

	// Perform an integrity check.
	bool integrityCheck = TF2ItemPlugin_Menus_ValidateMenuAction(client, slot, cosmetic);
	if (!integrityCheck) return 0;

	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option.
			char option[12];
			menu.GetItem(param, option, sizeof(option));

			// Handle preset options first.
			if (StrEqual(option, "override"))
				// Toggle the slot's paint override status.
				TF2ItemPlugin_ToggleCosmeticSlotPaintOverride(client, slot);

			if (StrEqual(option, "paint"))
			{
				// Open the paint menu.
				TF2ItemPlugin_Menus_PaintMenu_Colors(client, slot, cosmetic);

				return 0;
			}

			if (StrEqual(option, "spellPaint"))
			{
				// Open the spell paint menu.
				TF2ItemPlugin_Menus_PaintMenu_SpellPaints(client, slot, cosmetic);

				return 0;
			}

			// Rebuild the previous menu.
			DataPack data = new DataPack();
			data.WriteCell(client);
			data.WriteCell(slot);
			data.WriteCell(GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex"));
			data.WriteString("rebuild_paint");

			CreateTimer(0.1, TF2ItemPlugin_Menus_HandleMenuRebuild, data);
		}
		case MenuAction_Cancel:
		{
			if (param == MenuCancel_ExitBack)
				// Render the previous menu.
				TF2ItemPlugin_Menus_CosmeticMenu(client, slot, cosmetic);
		}
	}

	return 0;
}

public int PaintColorsMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	// Obtain the menu hidden data values.
	int	 cosmetic = -1, slot = -1;

	char cosmeticStr[12], slotStr[12];
	menu.GetItem(0, cosmeticStr, sizeof(cosmeticStr));
	menu.GetItem(1, slotStr, sizeof(slotStr));

	cosmetic			= StringToInt(cosmeticStr);
	slot				= StringToInt(slotStr);

	// Perform an integrity check.
	bool integrityCheck = TF2ItemPlugin_Menus_ValidateMenuAction(client, slot, cosmetic);
	if (!integrityCheck) return 0;

	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option.
			char option[12];
			menu.GetItem(param, option, sizeof(option));

			// If the clear option was selected, clear the paint override.
			if (StrEqual(option, "clear"))
			{
				// Clear the paint override.
				TF2ItemPlugin_SetCosmeticSlotPaintColor(client, slot, -1);

				// Rebuild the previous menu.
				DataPack data = new DataPack();
				data.WriteCell(client);
				data.WriteCell(slot);
				data.WriteCell(GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex"));
				data.WriteString("rebuild_cosmetic");

				CreateTimer(0.1, TF2ItemPlugin_Menus_HandleMenuRebuild, data);

				return 0;
			}

			// Convert the option to an integer (color index).
			int color = StringToInt(option);

			// Set the paint color override.
			TF2ItemPlugin_SetCosmeticSlotPaintColor(client, slot, color);

			// Rebuild the previous menu.
			DataPack data = new DataPack();
			data.WriteCell(client);
			data.WriteCell(slot);
			data.WriteCell(GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex"));
			data.WriteString("rebuild_paint");

			CreateTimer(0.1, TF2ItemPlugin_Menus_HandleMenuRebuild, data);
		}
		case MenuAction_Cancel:
		{
			if (param == MenuCancel_ExitBack)
				// Render the previous menu.
				TF2ItemPlugin_Menus_PaintMenu(client, slot, cosmetic);
		}
	}

	return 0;
}

public int SpellPaintsMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	// Obtain the menu hidden data values.
	int	 cosmetic = -1, slot = -1;

	char cosmeticStr[12], slotStr[12];
	menu.GetItem(0, cosmeticStr, sizeof(cosmeticStr));
	menu.GetItem(1, slotStr, sizeof(slotStr));

	cosmetic			= StringToInt(cosmeticStr);
	slot				= StringToInt(slotStr);

	// Perform an integrity check.
	bool integrityCheck = TF2ItemPlugin_Menus_ValidateMenuAction(client, slot, cosmetic);
	if (!integrityCheck) return 0;

	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option.
			char option[12];
			menu.GetItem(param, option, sizeof(option));

			// If the clear option was selected, clear the paint override.
			if (StrEqual(option, "clear"))
			{
				// Clear the paint override.
				TF2ItemPlugin_SetCosmeticSlotHalloweenSpellPaint(client, slot, -1);

				// Rebuild the previous menu.
				DataPack data = new DataPack();
				data.WriteCell(client);
				data.WriteCell(slot);
				data.WriteCell(GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex"));
				data.WriteString("rebuild_paint");

				CreateTimer(0.1, TF2ItemPlugin_Menus_HandleMenuRebuild, data);

				return 0;
			}

			// Convert the option to an integer (spell index).
			int spell = StringToInt(option);

			// Set the paint color override.
			TF2ItemPlugin_SetCosmeticSlotHalloweenSpellPaint(client, slot, spell);

			// Rebuild the previous menu.
			DataPack data = new DataPack();
			data.WriteCell(client);
			data.WriteCell(slot);
			data.WriteCell(GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex"));
			data.WriteString("rebuild_paint");

			CreateTimer(0.1, TF2ItemPlugin_Menus_HandleMenuRebuild, data);
		}
		case MenuAction_Cancel:
		{
			if (param == MenuCancel_ExitBack)
				// Render the previous menu.
				TF2ItemPlugin_Menus_PaintMenu(client, slot, cosmetic);
		}
	}

	return 0;
}

public int HalloweenMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	// Obtain the menu hidden data values.
	int	 cosmetic = -1, slot = -1;

	char cosmeticStr[12], slotStr[12];
	menu.GetItem(0, cosmeticStr, sizeof(cosmeticStr));
	menu.GetItem(1, slotStr, sizeof(slotStr));

	cosmetic			= StringToInt(cosmeticStr);
	slot				= StringToInt(slotStr);

	// Perform an integrity check.
	bool integrityCheck = TF2ItemPlugin_Menus_ValidateMenuAction(client, slot, cosmetic);
	if (!integrityCheck) return 0;

	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option.
			char option[24];
			menu.GetItem(param, option, sizeof(option));

			// Handle set options.
			if (StrEqual(option, "footprints"))
			{
				// Open the footsteps menu.
				TF2ItemPlugin_Menus_HalloweenMenu_Footprints(client, slot, cosmetic);

				return 0;
			}

			if (StrEqual(option, "override"))
				// Toggle the slot's halloween override status.
				TF2ItemPlugin_ToggleCosmeticSlotHalloweenOverride(client, slot);

			if (StrEqual(option, "voiceModulation"))
				// Toggle the voice modulation override.
				TF2ItemPlugin_ToggleCosmeticSlotHalloweenVoiceModulation(client, slot);

			// Rebuild the previous menu.
			DataPack data = new DataPack();
			data.WriteCell(client);
			data.WriteCell(slot);
			data.WriteCell(GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex"));
			data.WriteString("rebuild_halloween");

			CreateTimer(0.1, TF2ItemPlugin_Menus_HandleMenuRebuild, data);
		}
		case MenuAction_Cancel:
		{
			if (param == MenuCancel_ExitBack)
				// Render the previous menu.
				TF2ItemPlugin_Menus_CosmeticMenu(client, slot, cosmetic);
		}
	}

	return 0;
}

public int HalloweenFootprintsMenuHandler(Menu menu, MenuAction action, int client, int param)
{
	// Obtain the menu hidden data values.
	int	 cosmetic = -1, slot = -1;

	char cosmeticStr[12], slotStr[12];
	menu.GetItem(0, cosmeticStr, sizeof(cosmeticStr));
	menu.GetItem(1, slotStr, sizeof(slotStr));

	cosmetic			= StringToInt(cosmeticStr);
	slot				= StringToInt(slotStr);

	// Perform an integrity check.
	bool integrityCheck = TF2ItemPlugin_Menus_ValidateMenuAction(client, slot, cosmetic);
	if (!integrityCheck) return 0;

	switch (action)
	{
		case MenuAction_Select:
		{
			// Obtain the selected option.
			char option[12];
			menu.GetItem(param, option, sizeof(option));

			// If the clear option was selected, clear the paint override.
			if (StrEqual(option, "clear"))
			{
				// Clear the paint override.
				TF2ItemPlugin_SetCosmeticSlotHalloweenFootsteps(client, slot, -1);

				// Rebuild the previous menu.
				DataPack data = new DataPack();
				data.WriteCell(client);
				data.WriteCell(slot);
				data.WriteCell(GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex"));
				data.WriteString("rebuild_halloween");

				CreateTimer(0.1, TF2ItemPlugin_Menus_HandleMenuRebuild, data);

				return 0;
			}

			// Convert the option to an integer (footstep index).
			int footsteps = StringToInt(option);

			// Set the paint color override.
			TF2ItemPlugin_SetCosmeticSlotHalloweenFootsteps(client, slot, footsteps);

			// Rebuild the previous menu.
			DataPack data = new DataPack();
			data.WriteCell(client);
			data.WriteCell(slot);
			data.WriteCell(GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex"));
			data.WriteString("rebuild_halloween");

			CreateTimer(0.1, TF2ItemPlugin_Menus_HandleMenuRebuild, data);
		}
		case MenuAction_Cancel:
		{
			if (param == MenuCancel_ExitBack)
				// Render the previous menu.
				TF2ItemPlugin_Menus_HalloweenMenu(client, slot, cosmetic);
		}
	}

	return 0;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] query)
{
	// Ignore non-searching players.
	if (!g_isSearchingForUnusual[client]) return Plugin_Continue;

	// Take the query and search for an Unusual effect with that name (or ID) (case-insensitive).
	StringMap unusualEffects[MAX_UNUSUAL_EFFECTS];

	int		  lastInsertedUnusualIndex = 0;
	for (int i = 0; i < MAX_UNUSUAL_EFFECTS; i++)
	{
		if (g_unusualEffects[i] == null) continue;

		// Obtain the unusual effect name.
		char unusualName[128];
		g_unusualEffects[i].GetString("name", unusualName, sizeof(unusualName));

		// Check if the Unusual effect name contains the query.
		if (StrContains(unusualName, query, false) != -1)
		{
			// Store the Unusual information on the global variable.
			unusualEffects[lastInsertedUnusualIndex] = new StringMap();

			int id									 = -1;
			g_unusualEffects[i].GetValue("id", id);

			unusualEffects[lastInsertedUnusualIndex].SetValue("id", id);
			unusualEffects[lastInsertedUnusualIndex].SetString("name", unusualName);

			lastInsertedUnusualIndex++;
		}
	}

	// Turn off the search status.
	g_isSearchingForUnusual[client] = false;

	// Fetch the DataPack from the global.
	DataPack data					= g_searchData[client];
	data.Reset();

	int slot = data.ReadCell(), cosmetic = data.ReadCell();

	// Clear the old DataPack.
	delete g_searchData[client];

	// Build and open the results menu with the result unusuals.
	TF2ItemPlugin_Menus_UnusualMenu_SearchResults(client, slot, cosmetic, unusualEffects, lastInsertedUnusualIndex + 1);

	return Plugin_Handled;
}

public Action TF2ItemPlugin_UnusualSearchTimeoutHandler(Handle timer, int client)
{
	if (!g_isSearchingForUnusual[client]) return Plugin_Stop;

	// Reset the player's search status.
	g_isSearchingForUnusual[client] = false;

	// Print a message to the player's chat to inform them of the timeout.
	CPrintToChat(client, "%s Your War Paint search has timed out.", PLUGIN_CHATTAG);

	return Plugin_Stop;
}