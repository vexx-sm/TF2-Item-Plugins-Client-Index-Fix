#include "tf2itemplugin_cosmetics_menus_handlers.sp"

/**
 * Initializes the user inventory data for a player when joining.
 *
 * @param client Client index to initialize the inventory for.
 *
 * @return void
 */
stock void TF2ItemPlugin_InitializeInventory(int client)
{
	// Go through each class and slot to initialize their inventory to default values.
	for (int i = 0; i < MAXPLAYERS + 1; i++)
	{
		for (int j = 0; j < MAX_CLASSES; j++)
		{
			for (int x = 0; x < MAX_COSMETICS; x++)
			{
				// Set the client, class, and slot ID for this inventory slot beforehand.
				g_inventories[i][j][x].client = client;
				g_inventories[i][j][x].class  = j;
				g_inventories[i][j][x].slotId = x;

				// Reset the inventory slot fully.
				g_inventories[i][j][x].Reset(true);
			}
		}
	}
}

/**
 * Generates the main menu where the user can visualize their equipped cosmetics.
 *
 * @param client Client index to generate the menu for.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_MainMenu(int client)
{
	// Create a new menu instance.
	Menu mainMenu = new Menu(MainMenuHandler);

	// Obtain the client's current class.
	int class	  = TF2_GetPlayerClassInt(client);

	// Obtain the class' name for visual representation.
	char className[32];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	// Set the title of the menu.
	mainMenu.SetTitle("Cosmetics / %s", className);

	// Begin iterating over the user's `tf_wearable` entities.
	int cosmetic = -1, cosmeticAmount = 0;
	while ((cosmetic = FindEntityByClassname(cosmetic, "tf_wearable")) != -1)
	{
		// Is this cosmetic from this user?
		int owner = GetEntPropEnt(cosmetic, Prop_Send, "m_hOwnerEntity");

		// Skip if its not their cosmetic.
		if (owner != client)
			continue;

		// Obtain the item definition index for this cosmetic.
		int itemDefIndex = GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex");

		// Ignore wearable weapons (Gunboats, Shields, etc).
		if (TF2ItemPlugin_IsCosmeticWearableWeapon(itemDefIndex))
			continue;

		// Obtain the cosmetic's name.
		char cosmeticName[64], cosmeticEntityIdStr[24];
		TF2Econ_GetItemName(itemDefIndex, cosmeticName, sizeof(cosmeticName));
		IntToString(cosmetic, cosmeticEntityIdStr, sizeof(cosmeticEntityIdStr));

		// Add the item to the menu.
		mainMenu.AddItem(cosmeticEntityIdStr, cosmeticName);

		// Increment the cosmetic amount found.
		cosmeticAmount++;
	}

	// If no cosmetics were found, display a message.
	if (!cosmeticAmount)
		mainMenu.AddItem("", "No compatible cosmetics were found equipped on you.");

	// Add some information about the usage for cosmetics.
	mainMenu.AddItem("", "Only modifiable and actively overriden cosmetics will have changes take effect.", ITEMDRAW_DISABLED);
	mainMenu.AddItem("", "Remember to activate the override to visualize them.", ITEMDRAW_DISABLED);

	// Add database options for preferences.
	mainMenu.AddItem("load", "Load my preferences", g_isConnected ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	mainMenu.AddItem("save", "Save my preferences", g_isConnected ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	mainMenu.AddItem("reset", "Reset my current preferences");
	mainMenu.AddItem("delete", "Delete my saved preferences", g_isConnected ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Set the exit button.
	mainMenu.ExitButton = true;

	// Display the menu to the client.
	mainMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Generates a menu for the client to alter their cosmetic preferences.
 *
 * @param client The client index to generate the menu for.
 * @param slot The slot index to generate the menu for.
 * @param cosmetic The cosmetic entity index to generate the menu for.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_CosmeticMenu(int client, int slot, int cosmetic)
{
	// Create a new menu instance.
	Menu cosmeticMenu = new Menu(CosmeticMenuHandler);

	// Obtain the client's current class.
	int class		  = TF2_GetPlayerClassInt(client);

	// Obtain the class' name for visual representation.
	char className[32];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	// Obtain the cosmetic's name for visual representation.
	int	 itemDefIndex = GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex");

	char cosmeticName[64];
	TF2Econ_GetItemName(itemDefIndex, cosmeticName, sizeof(cosmeticName));

	// Set the title of the menu.
	cosmeticMenu.SetTitle("Cosmetics / %s / %s", className, cosmeticName);

	// Embed data in hidden menu options first.
	char cosmeticEntityStr[12], slotStr[4];
	IntToString(cosmetic, cosmeticEntityStr, sizeof(cosmeticEntityStr));
	IntToString(slot, slotStr, sizeof(slotStr));

	cosmeticMenu.AddItem(cosmeticEntityStr, "cosmeticId", ITEMDRAW_IGNORE);
	cosmeticMenu.AddItem(slotStr, "slotId", ITEMDRAW_IGNORE);

	// Obtain the user's inventory.
	TFInventory_Cosmetics_Slot inventory;
	inventory = g_inventories[client][class][slot];

	// Add an option to activate overrides.
	cosmeticMenu.AddItem("override", inventory.isActiveOverride ? "[X] Active changes" : "[ ] Active changes");

	// Add some information about the current configuration.
	char informationCosmetic[64];
	if (inventory.itemDefIndex != -1) TF2Econ_GetItemName(inventory.itemDefIndex, informationCosmetic, sizeof(informationCosmetic));
	else strcopy(informationCosmetic, sizeof(informationCosmetic), "No cosmetic set");
	Format(informationCosmetic, sizeof(informationCosmetic), "Actively set for \"%s\"", informationCosmetic);

	cosmeticMenu.AddItem("", informationCosmetic, ITEMDRAW_DISABLED);

	// Add the Unusual effect option.
	char currentUnusualEffectName[64];
	if (inventory.unusualEffect != -1)
	{
		// Obtain the set unusual effect ID.
		TF2ItemPlugin_GetUnusualEffectName(inventory.unusualEffect, currentUnusualEffectName, sizeof(currentUnusualEffectName));

		// Format the unusual effect name.
		Format(currentUnusualEffectName, sizeof(currentUnusualEffectName), "Unusual Effect: %s", currentUnusualEffectName);
	}
	else strcopy(currentUnusualEffectName, sizeof(currentUnusualEffectName), "Unusual Effect");

	bool canUnusual = TF2ItemPlugin_CanCosmeticBeUnusual(itemDefIndex);
	cosmeticMenu.AddItem("unusual", canUnusual ? currentUnusualEffectName : "Cosmetic cannot equip Unusual effects.", canUnusual && inventory.isActiveOverride ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Add the paint options.
	bool canPaint = TF2ItemPlugin_CanCosmeticBePainted(itemDefIndex);
	cosmeticMenu.AddItem("paint", canPaint ? "Paint Options" : "Cosmetic cannot be painted.", canPaint && inventory.isActiveOverride ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Add the Halloween options.
	cosmeticMenu.AddItem("halloween", "Halloween Options", inventory.isActiveOverride ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Set the exit-back button.
	cosmeticMenu.ExitBackButton = true;

	// Display the menu to the client.
	cosmeticMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Generates a menu for the client to select (or search) for an Unusual effect.
 *
 * @param client The client index to generate the menu for.
 * @param slot The slot index to generate the menu for.
 * @param cosmetic The cosmetic entity index to generate the menu for.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_UnusualMenu(int client, int slot, int cosmetic)
{
	// Create a new menu instance.
	Menu unusualMenu = new Menu(UnusualMenuHandler);

	// Obtain the client's current class.
	int class		 = TF2_GetPlayerClassInt(client);

	// Obtain the class' name for visual representation.
	char className[32];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	// Obtain the cosmetic's name for visual representation.
	int	 itemDefIndex = GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex");

	char cosmeticName[64];
	TF2Econ_GetItemName(itemDefIndex, cosmeticName, sizeof(cosmeticName));

	// Set the title of the menu.
	unusualMenu.SetTitle("Cosmetics / %s / %s / Unusual Effects", className, cosmeticName);

	// Embed data in hidden menu options first.
	char cosmeticEntityStr[12], slotStr[4];
	IntToString(cosmetic, cosmeticEntityStr, sizeof(cosmeticEntityStr));
	IntToString(slot, slotStr, sizeof(slotStr));

	unusualMenu.AddItem(cosmeticEntityStr, "cosmeticId", ITEMDRAW_IGNORE);
	unusualMenu.AddItem(slotStr, "slotId", ITEMDRAW_IGNORE);

	// Obtain the user's inventory.
	TFInventory_Cosmetics_Slot inventory;
	inventory = g_inventories[client][class][slot];

	// Add the search option.
	unusualMenu.AddItem("search", "Search an Unusual effect by name");

	// Add a clear option for no Unusual effect.
	unusualMenu.AddItem("clear", "Clear my current selection", inventory.unusualEffect != -1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Add an information item that displays the current Unusual effect.
	char currentUnusualEffectName[64];
	if (inventory.unusualEffect != -1)
	{
		// Obtain the set unusual effect ID.
		TF2ItemPlugin_GetUnusualEffectName(inventory.unusualEffect, currentUnusualEffectName, sizeof(currentUnusualEffectName));

		// Format the unusual effect name.
		Format(currentUnusualEffectName, sizeof(currentUnusualEffectName), "Current Unusual Effect: %s", currentUnusualEffectName);
	}
	else strcopy(currentUnusualEffectName, sizeof(currentUnusualEffectName), "Current Unusual Effect: None selected");

	unusualMenu.AddItem("", currentUnusualEffectName, ITEMDRAW_DISABLED);

	// Add the Unusual effect options.
	for (int i = 0; i < MAX_UNUSUAL_EFFECTS; i++)
	{
		// Skip if the Unusual effect is not set at this index.
		if (g_unusualEffects[i] == null)
			continue;

		// Obtain the Unusual effect ID.
		int unusualEffectId = -1;
		g_unusualEffects[i].GetValue("id", unusualEffectId);

		// Obtain the Unusual effect name.
		char unusualEffectName[64], unusualEffectIdString[12];
		g_unusualEffects[i].GetString("name", unusualEffectName, sizeof(unusualEffectName));
		IntToString(unusualEffectId, unusualEffectIdString, sizeof(unusualEffectIdString));

		// Add the Unusual effect to the menu.
		unusualMenu.AddItem(unusualEffectIdString, unusualEffectName);
	}

	// Set the exit-back button.
	unusualMenu.ExitBackButton = true;

	// Display the menu to the client.
	unusualMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Generates a results menu for after a search is done on the Unusual effects menu.
 *
 * @param client Client index to build the menu for.
 * @param slot Slot ID to configure.
 * @param cosmetic Cosmetic entity index to configure.
 * @param results Array of results to display.
 * @param resultsCount Amount of results to display.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_UnusualMenu_SearchResults(int client, int slot, int cosmetic, StringMap[] results, int resultsCount)
{
	// Create the new menu handle.
	Menu unusualSearchResultsMenu = new Menu(UnusualMenuHandler);

	// Obtain the client's current class.
	int class					  = TF2_GetPlayerClassInt(client);

	// Obtain the class' name for visual representation.
	char className[32];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	// Obtain the cosmetic's name for visual representation.
	int	 itemDefIndex = GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex");

	char cosmeticName[64];
	TF2Econ_GetItemName(itemDefIndex, cosmeticName, sizeof(cosmeticName));

	// Set the title of the menu.
	unusualSearchResultsMenu.SetTitle("Cosmetics / %s / %s / Unusual Effects / Search Results", className, cosmeticName);

	// Add hidden data for the cosmetic and slot.
	char cosmeticEntityStr[12], slotStr[4];
	IntToString(cosmetic, cosmeticEntityStr, sizeof(cosmeticEntityStr));
	IntToString(slot, slotStr, sizeof(slotStr));

	unusualSearchResultsMenu.AddItem(cosmeticEntityStr, "cosmeticId", ITEMDRAW_IGNORE);
	unusualSearchResultsMenu.AddItem(slotStr, "slotId", ITEMDRAW_IGNORE);

	// Add an informative item about the results.
	unusualSearchResultsMenu.AddItem("", "If your results are not what you expected, you can go back and search again.", ITEMDRAW_DISABLED);
	unusualSearchResultsMenu.AddItem("", "Below are the search results for your query:", ITEMDRAW_DISABLED);

	// Iterate over the list to find the war paint.
	for (int i = 0; i < resultsCount; i++)
	{
		if (results[i] == null) continue;

		// Get their ID.
		int id = -1;
		results[i].GetValue("id", id);

		// Skip invalid ID numbers.
		if (id == -1) continue;

		// Get the war paint name.
		char unusualName[128];
		results[i].GetString("name", unusualName, sizeof(unusualName));

		// Add the war paint to the menu.
		char unusualIdStr[12];
		IntToString(id, unusualIdStr, sizeof(unusualIdStr));

		unusualSearchResultsMenu.AddItem(unusualIdStr, unusualName);
	}

	// Configure the menu's options.
	unusualSearchResultsMenu.ExitBackButton = true;

	// Display the menu.
	unusualSearchResultsMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Generates a menu to configure paint values for a cosmetic.
 *
 * @param client Client index to build the menu for.
 * @param slot Slot ID to configure.
 * @param cosmetic Cosmetic entity index to configure.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_PaintMenu(int client, int slot, int cosmetic)
{
	// Create the new menu handle.
	Menu paintMenu = new Menu(PaintMenuHandler);

	// Obtain the client's current class.
	int class	   = TF2_GetPlayerClassInt(client);

	// Obtain the class' name for visual representation.
	char className[32];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	// Obtain the cosmetic's name for visual representation.
	int	 itemDefIndex = GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex");

	char cosmeticName[64];
	TF2Econ_GetItemName(itemDefIndex, cosmeticName, sizeof(cosmeticName));

	// Set the title of the menu.
	paintMenu.SetTitle("Cosmetics / %s / %s / Paint Options", className, cosmeticName);

	// Add hidden data for the cosmetic and slot.
	char cosmeticEntityStr[12], slotStr[4];
	IntToString(cosmetic, cosmeticEntityStr, sizeof(cosmeticEntityStr));
	IntToString(slot, slotStr, sizeof(slotStr));

	paintMenu.AddItem(cosmeticEntityStr, "cosmeticId", ITEMDRAW_IGNORE);
	paintMenu.AddItem(slotStr, "slotId", ITEMDRAW_IGNORE);

	// Obtain the user's inventory.
	TFInventory_Cosmetics_Slot inventory;
	inventory = g_inventories[client][class][slot];

	// Add the override option to allow paint changes.
	paintMenu.AddItem("override", inventory.paint.isActiveOverride ? "[X] Active changes" : "[ ] Active changes", ITEMDRAW_DEFAULT);

	// Add an option to select normal paint and spell paint.
	char paintName[64];
	if (inventory.paint.paintIndex != -1) TF2ItemPlugin_GetPaintName(inventory.paint.paintIndex, paintName, sizeof(paintName));
	else strcopy(paintName, sizeof(paintName), "No paint set");

	Format(paintName, sizeof(paintName), "Paint Color: %s", paintName);

	paintMenu.AddItem("paint", paintName, inventory.paint.isActiveOverride ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	char spellPaintName[64];
	if (inventory.paint.halloweenSpellPaintId != -1) TF2ItemPlugin_GetSpellPaintName(inventory.paint.halloweenSpellPaintId, spellPaintName, sizeof(spellPaintName));
	else strcopy(spellPaintName, sizeof(spellPaintName), "No spell paint set");

	Format(spellPaintName, sizeof(spellPaintName), "Spell Paint: %s", spellPaintName);

	paintMenu.AddItem("spellPaint", spellPaintName, inventory.paint.isActiveOverride ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Set the exit-back button.
	paintMenu.ExitBackButton = true;

	// Display the menu to the client.
	paintMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Generates a new menu with all possible paint colors to select from.
 *
 * @param client Client index to build the menu for.
 * @param slot Slot ID to configure.
 * @param cosmetic Cosmetic entity index to configure.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_PaintMenu_Colors(int client, int slot, int cosmetic)
{
	// Create the new menu handle.
	Menu paintColorsMenu = new Menu(PaintColorsMenuHandler);

	// Obtain the client's current class.
	int class			 = TF2_GetPlayerClassInt(client);

	// Obtain the class' name for visual representation.
	char className[32];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	// Obtain the cosmetic's name for visual representation.
	int	 itemDefIndex = GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex");

	char cosmeticName[64];
	TF2Econ_GetItemName(itemDefIndex, cosmeticName, sizeof(cosmeticName));

	// Set the title of the menu.
	paintColorsMenu.SetTitle("Cosmetics / %s / %s / Paint Options / Paint Colors", className, cosmeticName);

	// Add hidden data for the cosmetic and slot.
	char cosmeticEntityStr[12], slotStr[4];
	IntToString(cosmetic, cosmeticEntityStr, sizeof(cosmeticEntityStr));
	IntToString(slot, slotStr, sizeof(slotStr));

	paintColorsMenu.AddItem(cosmeticEntityStr, "cosmeticId", ITEMDRAW_IGNORE);
	paintColorsMenu.AddItem(slotStr, "slotId", ITEMDRAW_IGNORE);

	// Obtain the user's inventory.
	TFInventory_Cosmetics_Slot inventory;
	inventory = g_inventories[client][class][slot];

	// Add a clear option for no paint.
	paintColorsMenu.AddItem("clear", "Clear my current selection", inventory.paint.paintIndex != -1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Add an informative item about the paint colors.
	paintColorsMenu.AddItem("", "Select a paint color to apply to your cosmetic.", ITEMDRAW_DISABLED);

	// Add the paint colors to the menu.
	for (int i = TF2CosmeticPaint_IndubitablyGreen; i <= TF2CosmeticPaint_CreamSpirit; i++)
	{
		// Obtain the paint color name.
		char paintColorName[128];
		TF2ItemPlugin_GetPaintName(i, paintColorName, sizeof(paintColorName));

		// Convert the paint ID to a string.
		char paintColorIdStr[12];
		IntToString(i, paintColorIdStr, sizeof(paintColorIdStr));

		// Format the menu option to select the paint depending on if it's already set.
		Format(paintColorName, sizeof(paintColorName), inventory.paint.paintIndex == i ? "[X] %s" : "[ ] %s", paintColorName);

		// Add the paint color to the menu.
		paintColorsMenu.AddItem(paintColorIdStr, paintColorName);
	}

	// Set the exit-back button.
	paintColorsMenu.ExitBackButton = true;

	// Display the menu to the client.
	paintColorsMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Generates a menu with all possible Halloween spell paints to select from.
 *
 * @param client Client index to build the menu for.
 * @param slot Slot ID to configure.
 * @param cosmetic Cosmetic entity index to configure.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_PaintMenu_SpellPaints(int client, int slot, int cosmetic)
{
	// Create the new menu handle.
	Menu spellPaintsMenu = new Menu(SpellPaintsMenuHandler);

	// Obtain the client's current class.
	int class			 = TF2_GetPlayerClassInt(client);

	// Obtain the class' name for visual representation.
	char className[32];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	// Obtain the cosmetic's name for visual representation.
	int	 itemDefIndex = GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex");

	char cosmeticName[64];
	TF2Econ_GetItemName(itemDefIndex, cosmeticName, sizeof(cosmeticName));

	// Set the title of the menu.
	spellPaintsMenu.SetTitle("Cosmetics / %s / %s / Paint Options / Spell Paints", className, cosmeticName);

	// Add hidden data for the cosmetic and slot.
	char cosmeticEntityStr[12], slotStr[4];
	IntToString(cosmetic, cosmeticEntityStr, sizeof(cosmeticEntityStr));
	IntToString(slot, slotStr, sizeof(slotStr));

	spellPaintsMenu.AddItem(cosmeticEntityStr, "cosmeticId", ITEMDRAW_IGNORE);
	spellPaintsMenu.AddItem(slotStr, "slotId", ITEMDRAW_IGNORE);

	// Obtain the user's inventory.
	TFInventory_Cosmetics_Slot inventory;
	inventory = g_inventories[client][class][slot];

	// Add a clear option for no spell paint.
	spellPaintsMenu.AddItem("clear", "Clear my current selection", inventory.paint.halloweenSpellPaintId != -1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Add an informative item about the spell paints.
	spellPaintsMenu.AddItem("", "Select a Halloween spell paint to apply to your cosmetic.", ITEMDRAW_DISABLED);
	spellPaintsMenu.AddItem("", "Remember these will only show up if the server has Halloween mode enabled.", ITEMDRAW_DISABLED);

	// Add the spell paints to the menu.
	for (int i = TF2CosmeticPaint_Spell_DieJob; i <= TF2CosmeticPaint_Spell_SinisterStaining; i++)
	{
		// Obtain the spell paint name.
		char spellPaintName[128];
		TF2ItemPlugin_GetSpellPaintName(i, spellPaintName, sizeof(spellPaintName));

		// Convert the spell paint ID to a string.
		char spellPaintIdStr[12];
		IntToString(i, spellPaintIdStr, sizeof(spellPaintIdStr));

		// Format the menu option to select the spell paint depending on if it's already set.
		Format(spellPaintName, sizeof(spellPaintName), inventory.paint.halloweenSpellPaintId == i ? "[X] %s" : "[ ] %s", spellPaintName);

		// Add the spell paint to the menu.
		spellPaintsMenu.AddItem(spellPaintIdStr, spellPaintName);
	}

	// Set the exit-back button.
	spellPaintsMenu.ExitBackButton = true;

	// Display the menu to the client.
	spellPaintsMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Builds a menu to configure Halloween attributes for a cosmetic.
 *
 * @param client Client index to build the menu for.
 * @param slot Slot ID to configure.
 * @param cosmetic Cosmetic entity index to configure.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_HalloweenMenu(int client, int slot, int cosmetic)
{
	// Create the new menu handle.
	Menu halloweenMenu = new Menu(HalloweenMenuHandler);

	// Obtain the client's current class.
	int class		   = TF2_GetPlayerClassInt(client);

	// Obtain the class' name for visual representation.
	char className[32];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	// Obtain the cosmetic's name for visual representation.
	int	 itemDefIndex = GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex");

	char cosmeticName[64];
	TF2Econ_GetItemName(itemDefIndex, cosmeticName, sizeof(cosmeticName));

	// Set the title of the menu.
	halloweenMenu.SetTitle("Cosmetics / %s / %s / Halloween Options", className, cosmeticName);

	// Add hidden data for the cosmetic and slot.
	char cosmeticEntityStr[12], slotStr[4];
	IntToString(cosmetic, cosmeticEntityStr, sizeof(cosmeticEntityStr));
	IntToString(slot, slotStr, sizeof(slotStr));

	halloweenMenu.AddItem(cosmeticEntityStr, "cosmeticId", ITEMDRAW_IGNORE);
	halloweenMenu.AddItem(slotStr, "slotId", ITEMDRAW_IGNORE);

	// Obtain the user's inventory.
	TFInventory_Cosmetics_Slot inventory;
	inventory = g_inventories[client][class][slot];

	// Add the Halloween override option.
	halloweenMenu.AddItem("override", inventory.halloween.isActiveOverride ? "[X] Active changes" : "[ ] Active changes", ITEMDRAW_DEFAULT);

	// Add an option for Halloween footprints.
	int	 halloweenFootprintsId = inventory.halloween.halloweenFootstepsIndex;
	char halloweenFootprintsName[64];
	if (halloweenFootprintsId != -1)
	{
		TF2ItemPlugin_GetFootstepsName(halloweenFootprintsId, halloweenFootprintsName, sizeof(halloweenFootprintsName));
		Format(halloweenFootprintsName, sizeof(halloweenFootprintsName), "Footprints: %s", halloweenFootprintsName);
	}
	else strcopy(halloweenFootprintsName, sizeof(halloweenFootprintsName), "No footprints");

	halloweenMenu.AddItem("footprints", halloweenFootprintsName, inventory.halloween.isActiveOverride ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Add an option for Halloween voice modulation.
	halloweenMenu.AddItem("voiceModulation", inventory.halloween.halloweenVoiceModulation ? "[X] Voices from Below" : "[ ] Voices from Below", inventory.halloween.isActiveOverride ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Set the exit-back button.
	halloweenMenu.ExitBackButton = true;

	// Display the menu to the client.
	halloweenMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Builds a minimal menu to confirm the saving of a player's preferences.
 *
 * @param client Client index to build the menu for.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_PreferenceSaveMenu(int client)
{
	// Construct a new menu instance.
	Menu saveMenu = new Menu(PreferenceSaveMenuHandler);

	// Set the menu title.
	saveMenu.SetTitle("Confirm Save");

	saveMenu.AddItem("", "Are you sure you want to save your current preferences?", ITEMDRAW_DISABLED);
	saveMenu.AddItem("", "This will overwrite your current cloud saved preferences.", ITEMDRAW_DISABLED);

	// Add the confirmation options.
	saveMenu.AddItem("confirm", "Yes, save them.");
	saveMenu.AddItem("cancel", "No, thanks.");

	// Configure the menu's options.
	saveMenu.ExitBackButton = true;

	// Display the menu.
	saveMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Builds a minimal menu to confirm the deletion of a player's saved preferences.
 *
 * @param client Client index to build the menu for.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_PreferenceDeleteMenu(int client)
{
	// Construct a new menu instance.
	Menu deleteMenu = new Menu(PreferenceDeleteMenuHandler);

	// Set the menu title.
	deleteMenu.SetTitle("Confirm Deletion");

	deleteMenu.AddItem("", "Are you sure you want to delete your saved preferences?", ITEMDRAW_DISABLED);
	deleteMenu.AddItem("", "This action is IRREVERSIBLE.", ITEMDRAW_DISABLED);

	// Add the confirmation options.
	deleteMenu.AddItem("confirm", "Yes, delete them all.");
	deleteMenu.AddItem("cancel", "No, thanks.");

	// Configure the menu's options.
	deleteMenu.ExitBackButton = true;

	// Display the menu.
	deleteMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Generates a menu listing all possible Halloween footprints to select from.
 *
 * @param client Client index to build the menu for.
 * @param slot Slot ID to configure.
 * @param cosmetic Cosmetic entity index to configure.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_HalloweenMenu_Footprints(int client, int slot, int cosmetic)
{
	// Create the new menu handle.
	Menu halloweenFootprintsMenu = new Menu(HalloweenFootprintsMenuHandler);

	// Obtain the client's current class.
	int class					 = TF2_GetPlayerClassInt(client);

	// Obtain the class' name for visual representation.
	char className[32];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	// Obtain the cosmetic's name for visual representation.
	int	 itemDefIndex = GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex");

	char cosmeticName[64];
	TF2Econ_GetItemName(itemDefIndex, cosmeticName, sizeof(cosmeticName));

	// Set the title of the menu.
	halloweenFootprintsMenu.SetTitle("Cosmetics / %s / %s / Halloween Options / Footprints", className, cosmeticName);

	// Add hidden data for the cosmetic and slot.
	char cosmeticEntityStr[12], slotStr[4];
	IntToString(cosmetic, cosmeticEntityStr, sizeof(cosmeticEntityStr));
	IntToString(slot, slotStr, sizeof(slotStr));

	halloweenFootprintsMenu.AddItem(cosmeticEntityStr, "cosmeticId", ITEMDRAW_IGNORE);
	halloweenFootprintsMenu.AddItem(slotStr, "slotId", ITEMDRAW_IGNORE);

	// Obtain the user's inventory.
	TFInventory_Cosmetics_Slot inventory;
	inventory = g_inventories[client][class][slot];

	// Add a clear option for no footprints.
	halloweenFootprintsMenu.AddItem("clear", "Clear my current selection", inventory.halloween.halloweenFootstepsIndex != -1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Add an informative item about the footprints.
	halloweenFootprintsMenu.AddItem("", "Select a Halloween footprint to apply to your cosmetic.", ITEMDRAW_DISABLED);
	halloweenFootprintsMenu.AddItem("", "Remember these will only show up if the server has Halloween mode enabled.", ITEMDRAW_DISABLED);

	// Add the footprints to the menu.
	for (int i = TF2Cosmetic_Footsteps_TeamSpirit; i <= TF2Cosmetic_Footsteps_Gangreen; i++)
	{
		// Obtain the footprint name.
		char footprintName[128];
		TF2ItemPlugin_GetFootstepsName(i, footprintName, sizeof(footprintName));

		// Convert the footprint ID to a string.
		char footprintIdStr[12];
		IntToString(i, footprintIdStr, sizeof(footprintIdStr));

		// Format the menu option to select the footprint depending on if it's already set.
		Format(footprintName, sizeof(footprintName), inventory.halloween.halloweenFootstepsIndex == i ? "[X] %s" : "[ ] %s", footprintName);

		// Add the footprint to the menu.
		halloweenFootprintsMenu.AddItem(footprintIdStr, footprintName);
	}

	// Set the exit-back button.
	halloweenFootprintsMenu.ExitBackButton = true;

	// Display the menu to the client.
	halloweenFootprintsMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Rebuilds a menu depending on the origin to make sure changes take effect correctly.
 *
 * @param timer Timer handle that triggered this action.
 * @param data DataPack instance containing the client and slot to rebuild the menu for.
 *
 * @return Action
 */
public Action TF2ItemPlugin_Menus_HandleMenuRebuild(Handle timer, DataPack data)
{
	// Reset the DataPack to its initial index.
	data.Reset();

	// Obtain the client and slot from the data pack.
	int	 client = data.ReadCell(), slot = data.ReadCell(), itemDefIndex = data.ReadCell();

	char rebuildAction[24];
	data.ReadString(rebuildAction, sizeof(rebuildAction));

	// If the client is dead, return and do nothing.
	if (!IsPlayerAlive(client)) return Plugin_Stop;

	// Obtain the client's cosmetic that matches this item index.
	int cosmetic = -1;
	while ((cosmetic = FindEntityByClassname(cosmetic, "tf_wearable")) != -1)
	{
		// Obtain the item definition index for this cosmetic.
		int cosmeticItemDefIndex = GetEntProp(cosmetic, Prop_Send, "m_iItemDefinitionIndex");

		// Skip if the item definition index does not match.
		if (cosmeticItemDefIndex != itemDefIndex)
			continue;

		// Obtain the owner of this cosmetic.
		int owner = GetEntPropEnt(cosmetic, Prop_Send, "m_hOwnerEntity");

		// Skip if the owner does not match.
		if (owner != client)
			continue;

		// Break the loop if the cosmetic is found.
		break;
	}

	// If the entity is not valid, return and do nothing.
	if (!IsValidEdict(cosmetic)) return Plugin_Stop;

	// Rebuild the desired menu.
	if (StrEqual(rebuildAction, "rebuild_cosmetic")) TF2ItemPlugin_Menus_CosmeticMenu(client, slot, cosmetic);
	if (StrEqual(rebuildAction, "rebuild_paint")) TF2ItemPlugin_Menus_PaintMenu(client, slot, cosmetic);
	if (StrEqual(rebuildAction, "rebuild_halloween")) TF2ItemPlugin_Menus_HalloweenMenu(client, slot, cosmetic);

	// Free up the data pack.
	delete data;

	return Plugin_Stop;
}
