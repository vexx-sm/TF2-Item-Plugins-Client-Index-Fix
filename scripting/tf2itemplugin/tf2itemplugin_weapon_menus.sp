#include "tf2itemplugin_weapon_menus_handlers.sp"

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
			for (int x = 0; x < MAX_WEAPONS; x++)
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
 * Builds and displays the menu used to select a weapon slot to modify.
 *
 * @param client Client index to build the menu for.
 */
void TF2ItemPlugin_Menus_MainMenu(int client)
{
	// Construct a new menu instance.
	Menu main = new Menu(MainMenuHandler);

	// Set the menu title.
	char className[64];
	TF2ItemPlugin_GetTFClassName(TF2_GetPlayerClass(client), className, sizeof(className));

	main.SetTitle("Weapons / %s", className);

	// Loop through each weapon slot.
	for (int i = 0; i < MAX_WEAPONS; i++)
	{
		// Obtain the weapon at said slot.
		int weapon = GetPlayerWeaponSlot(client, i);

		// If the weapon is not valid, skip this slot but do add an empty item (to maintain the slot order).
		if (weapon == -1)
		{
			main.AddItem("", "", ITEMDRAW_IGNORE);
			continue;
		}

		// Obtain the weapon's definition index.
		int	 itemDefinitionIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

		// Obtain the name for this weapon through TFEconData.
		char name[64], weaponEntityStr[12];
		TF2Econ_GetItemName(itemDefinitionIndex, name, sizeof(name));
		Format(weaponEntityStr, sizeof(weaponEntityStr), "%d", weapon);

		// Add the weapon to the menu.
		char itemDefinitionIndexString[12];
		Format(itemDefinitionIndexString, sizeof(itemDefinitionIndexString), "%d", itemDefinitionIndex);

		main.AddItem(weaponEntityStr, name);
	}

	// Add information options first.
	main.AddItem(".", "Remember that your overrides affect your currently equipped weapon.", ITEMDRAW_DISABLED);
	main.AddItem(".", "Select a weapon of your choice to begin.", ITEMDRAW_DISABLED);

	// Add options to reset all configurations.
	main.AddItem("load", "Load my preferences", g_isConnected ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	main.AddItem("save", "Save my preferences", g_isConnected ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	main.AddItem("reset", "Reset my current preferences");
	main.AddItem("delete", "Delete my saved preferences", g_isConnected ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Configure the menu's options.
	main.ExitButton = true;

	// Display the menu.
	main.Display(client, MENU_TIME_FOREVER);
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
 * Builds and displays a menu where a weapon can be configured.
 *
 * @param client Client index to build the menu for.
 * @param slot Slot ID to configure.
 * @param name The name of the selected weapon.
 * @param weapon Weapon entity index referenced for configuration.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_WeaponMenu(int client, int slot, char[] name, int weapon)
{
	// Construct a new menu instance.
	Menu weaponMenu = new Menu(WeaponMenuHandler);

	// Obtain the player's class configuration from their inventory.
	int class		= TF2_GetPlayerClassInt(client);

	// Access the inventory configuration.
	TFInventory_Weapons_Slot inventory;
	inventory = g_inventories[client][class][slot];

	// Set the menu title.
	char className[64];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	weaponMenu.SetTitle("Weapons / %s / %s", className, name);

	// Hidden properties that transfer data to the menu handler.
	char weaponStr[12], slotStr[2];
	Format(weaponStr, sizeof(weaponStr), "%d", weapon);
	Format(slotStr, sizeof(slotStr), "%d", slot);

	weaponMenu.AddItem(name, "weaponName", ITEMDRAW_IGNORE);
	weaponMenu.AddItem(weaponStr, "weaponEntityId", ITEMDRAW_IGNORE);
	weaponMenu.AddItem(slotStr, "weaponSlotId", ITEMDRAW_IGNORE);

	// Add the toggleable override option.
	weaponMenu.AddItem("override", inventory.isActiveOverride ? "[X] Active changes" : "[ ] Active changes");

	// Add an information item.
	weaponMenu.AddItem("", "Remember to activate the override to apply changes.", ITEMDRAW_DISABLED);
	weaponMenu.AddItem("", "Below is the current set configuration for your slot:", ITEMDRAW_DISABLED);

	char infoWeapon[64], infoSlot[32];
	if (inventory.weaponDefIndex != -1) TF2Econ_GetItemName(inventory.weaponDefIndex, infoWeapon, sizeof(infoWeapon));
	else strcopy(infoWeapon, sizeof(infoWeapon), "No weapon set");

	TF2ItemPlugin_GetWeaponSlotName(slot, infoSlot, sizeof(infoSlot));

	Format(infoWeapon, sizeof(infoWeapon), "Actively set for weapon: %s", infoWeapon);
	Format(infoSlot, sizeof(infoSlot), "Affects slot: %s", infoSlot);

	weaponMenu.AddItem("", infoWeapon, ITEMDRAW_DISABLED);
	weaponMenu.AddItem("", infoSlot, ITEMDRAW_DISABLED);

	// Add the Australium option.
	int canAustralium = TF2ItemPlugin_CanItemAustralium(inventory.weaponDefIndex);
	weaponMenu.AddItem("australium", (canAustralium != TF2Weapon_NoAustralium ? (inventory.isAustralium ? "[X] Australium" : "[ ] Australium") : "Weapon cannot be australium"), inventory.isActiveOverride && canAustralium != TF2Weapon_NoAustralium ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Add the Festive option.
	bool canFestivizer = TF2ItemPlugin_CanItemFestivize(inventory.weaponDefIndex);
	weaponMenu.AddItem("festive", (canFestivizer ? (inventory.isFestive ? "[X] Festive" : "[ ] Festive") : "Weapon cannot be festivized"), canFestivizer && inventory.isActiveOverride ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Check if the weapon can be painted.
	bool canBePainted = TF2ItemPlugin_CanItemWarPaint(inventory.weaponDefIndex);

	// Add the War Paint ID option.
	weaponMenu.AddItem("warPaint", canBePainted ? "War Paints" : "Item cannot be painted", inventory.isActiveOverride && canBePainted ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Add the War Paint Wear option.
	char warPaintWear[32];
	TF2ItemPlugin_GetWarPaintWearString(inventory.warPaintWear, warPaintWear, sizeof(warPaintWear));
	Format(warPaintWear, sizeof(warPaintWear), "War Paint Wear: %s", warPaintWear);

	weaponMenu.AddItem("warPaintWear", canBePainted ? warPaintWear : "Item paint wear cannot be changed.", inventory.isActiveOverride && canBePainted ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Add the Unusual Effect ID option.
	char unusualEffect[64];
	TF2ItemPlugin_GetUnusualEffectName(inventory.unusualEffectId, unusualEffect, sizeof(unusualEffect));
	Format(unusualEffect, sizeof(unusualEffect), "Unusual Effect: %s", unusualEffect);

	weaponMenu.AddItem("unusual", unusualEffect, inventory.isActiveOverride ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Add the Killstreak option.
	weaponMenu.AddItem("killstreak", "Killstreak Configuration", inventory.isActiveOverride ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Add the spells option.
	weaponMenu.AddItem("spells", "Halloween Spell Configuration", inventory.isActiveOverride ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Configure the menu's options.
	weaponMenu.ExitBackButton = true;

	// Display the menu.
	weaponMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Generates a menu for the player to adjust their killstreak settings.
 *
 * @param client Client index to build the menu for.
 * @param slot Slot ID to configure.
 * @param name The name of the selected weapon.
 * @param weapon Weapon entity index referenced for configuration.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_KillstreakMenu(int client, int slot, char[] name, int weapon)
{
	// Create the new menu handle.
	Menu killstreakMenu = new Menu(KillstreakMenuHandler);

	// Obtain the player's class configuration from their inventory.
	int class			= TF2_GetPlayerClassInt(client);

	// Access the inventory configuration.
	TFInventory_Weapons_Slot inventory;
	inventory = g_inventories[client][class][slot];

	// Set the menu title.
	char className[64];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	killstreakMenu.SetTitle("Weapons / %s / %s / Killstreaks", className, name);

	// Hidden properties that transfer data to the menu handler.
	char weaponStr[12], slotStr[2];
	Format(weaponStr, sizeof(weaponStr), "%d", weapon);
	Format(slotStr, sizeof(slotStr), "%d", slot);

	killstreakMenu.AddItem(name, "weaponName", ITEMDRAW_IGNORE);
	killstreakMenu.AddItem(weaponStr, "weaponEntityId", ITEMDRAW_IGNORE);
	killstreakMenu.AddItem(slotStr, "weaponSlotId", ITEMDRAW_IGNORE);

	// Add the toggleable override option.
	killstreakMenu.AddItem("override", inventory.isActiveOverride && inventory.killstreak.isActive ? "[X] Override Killstreak Kit" : "[ ] Override Killstreak Kit");

	// Add an information item.
	killstreakMenu.AddItem("", "If you enable the override, your current kit (if any) will be overriden.", ITEMDRAW_DISABLED);

	// Add the Killstreak option.
	char tierName[64];
	TF2ItemPlugin_GetKillstreakTierString(inventory.killstreak.tier, tierName, sizeof(tierName));
	Format(tierName, sizeof(tierName), "Killstreak Tier: %s", tierName);

	killstreakMenu.AddItem("tier", tierName, inventory.isActiveOverride && inventory.killstreak.isActive ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Add the sheen option, but only enable it if the killstreak tier is at least Specialized and the override is active.
	if (inventory.killstreak.tier >= TF2Killstreak_Specialized && inventory.isActiveOverride && inventory.killstreak.isActive)
	{
		char sheenName[64];
		TF2ItemPlugin_GetKillstreakSheenString(inventory.killstreak.sheen, sheenName, sizeof(sheenName));
		Format(sheenName, sizeof(sheenName), "Killstreak Sheen: %s", sheenName);

		killstreakMenu.AddItem("sheen", sheenName, ITEMDRAW_DEFAULT);
	}
	else killstreakMenu.AddItem("", "Tier must be Specialized to set a Sheen.", ITEMDRAW_DISABLED);

	// Add the killstreaker option, but only enable it if the killstreak tier is at least Professional and the override is active.
	if (inventory.killstreak.tier >= TF2Killstreak_Professional && inventory.isActiveOverride && inventory.killstreak.isActive)
	{
		char killstreakerName[64];
		TF2ItemPlugin_GetKillstreakerName(inventory.killstreak.killstreaker, killstreakerName, sizeof(killstreakerName));
		Format(killstreakerName, sizeof(killstreakerName), "Killstreaker: %s", killstreakerName);

		killstreakMenu.AddItem("killstreaker", killstreakerName, ITEMDRAW_DEFAULT);
	}
	else killstreakMenu.AddItem("", "Tier must be Professional to set a Killstreaker.", ITEMDRAW_DISABLED);

	// Configure the menu's options.
	killstreakMenu.ExitBackButton = true;

	// Display the menu.
	killstreakMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Generates a static menu for the player to select a specific Specialized Killstreak sheen.
 *
 * @param client Client index to build the menu for.
 * @param slot Slot ID to configure.
 * @param name The name of the selected weapon.
 * @param weapon Weapon entity index referenced for configuration.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_KillstreakSheenMenu(int client, int slot, char[] name, int weapon)
{
	// Create the new menu handle.
	Menu sheenMenu = new Menu(KillstreakOptionsMenuHandler);

	// Obtain the player's class configuration from their inventory.
	int class	   = TF2_GetPlayerClassInt(client);

	// Access the inventory configuration.
	TFInventory_Weapons_Slot inventory;
	inventory = g_inventories[client][class][slot];

	// Set the menu title.
	char className[64];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	sheenMenu.SetTitle("Weapons / %s / %s / Killstreaks / Sheen", className, name);

	// Hidden properties that transfer data to the menu handler.
	char weaponStr[12], slotStr[2];
	Format(weaponStr, sizeof(weaponStr), "%d", weapon);
	Format(slotStr, sizeof(slotStr), "%d", slot);

	sheenMenu.AddItem(name, "weaponName", ITEMDRAW_IGNORE);
	sheenMenu.AddItem(weaponStr, "weaponEntityId", ITEMDRAW_IGNORE);
	sheenMenu.AddItem(slotStr, "weaponSlotId", ITEMDRAW_IGNORE);
	sheenMenu.AddItem("sheen", "option", ITEMDRAW_IGNORE);

	// Add the sheen options.
	for (int i = 1; i <= TF2Killstreak_Sheen_HotRod; i++)
	{
		char sheenName[64], sheenIdStr[2];
		TF2ItemPlugin_GetKillstreakSheenString(i, sheenName, sizeof(sheenName));
		Format(sheenName, sizeof(sheenName), i == inventory.killstreak.sheen ? "[X] %s" : "[ ] %s", sheenName);
		Format(sheenIdStr, sizeof(sheenIdStr), "%d", i);

		sheenMenu.AddItem(sheenIdStr, sheenName);
	}

	// Configure the menu's options.
	sheenMenu.ExitBackButton = true;

	// Display the menu.
	sheenMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Generates a static menu for the player to select a specific Professional Killstreak effect.
 *
 * @param client Client index to build the menu for.
 * @param slot Slot ID to configure.
 * @param name The name of the selected weapon.
 * @param weapon Weapon entity index referenced for configuration.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_KillstreakerMenu(int client, int slot, char[] name, int weapon)
{
	// Create the new menu handle.
	Menu killstreakerMenu = new Menu(KillstreakOptionsMenuHandler);

	// Obtain the player's class configuration from their inventory.
	int class			  = TF2_GetPlayerClassInt(client);

	// Access the inventory configuration.
	TFInventory_Weapons_Slot inventory;
	inventory = g_inventories[client][class][slot];

	// Set the menu title.
	char className[64];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	killstreakerMenu.SetTitle("Weapons / %s / %s / Killstreaks / Killstreaker", className, name);

	// Hidden properties that transfer data to the menu handler.
	char weaponStr[12], slotStr[2];
	Format(weaponStr, sizeof(weaponStr), "%d", weapon);
	Format(slotStr, sizeof(slotStr), "%d", slot);

	killstreakerMenu.AddItem(name, "weaponName", ITEMDRAW_IGNORE);
	killstreakerMenu.AddItem(weaponStr, "weaponEntityId", ITEMDRAW_IGNORE);
	killstreakerMenu.AddItem(slotStr, "weaponSlotId", ITEMDRAW_IGNORE);
	killstreakerMenu.AddItem("killstreaker", "option", ITEMDRAW_IGNORE);

	// Add the killstreaker options.
	for (int i = TF2Killstreaker_FireHorns; i <= TF2Killstreaker_HypnoBeam; i++)
	{
		char killstreakerName[64], killstreakerIdStr[6];
		TF2ItemPlugin_GetKillstreakerName(i, killstreakerName, sizeof(killstreakerName));
		Format(killstreakerName, sizeof(killstreakerName), i == inventory.killstreak.killstreaker ? "[X] %s" : "[ ] %s", killstreakerName);
		Format(killstreakerIdStr, sizeof(killstreakerIdStr), "%d", i);

		killstreakerMenu.AddItem(killstreakerIdStr, killstreakerName);
	}

	// Configure the menu's options.
	killstreakerMenu.ExitBackButton = true;

	// Display the menu.
	killstreakerMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Generates a static menu to configure set halloween spells on a weapon.
 *
 * @param client Client index to build the menu for.
 * @param slot Slot ID to configure.
 * @param name The name of the selected weapon.
 * @param weapon Weapon entity index referenced for configuration.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_SpellsMenu(int client, int slot, char[] name, int weapon)
{
	// Create the new menu handle.
	Menu spellsMenu = new Menu(SpellsMenuHandler);

	// Obtain the player's class configuration from their inventory.
	int class		= TF2_GetPlayerClassInt(client);

	// Access the inventory configuration.
	TFInventory_Weapons_Slot inventory;
	inventory = g_inventories[client][class][slot];

	// Set the menu title.
	char className[64];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	spellsMenu.SetTitle("Weapons / %s / %s / Spells", className, name);

	// Hidden properties that transfer data to the menu handler.
	char weaponStr[12], slotStr[2];
	Format(weaponStr, sizeof(weaponStr), "%d", weapon);
	Format(slotStr, sizeof(slotStr), "%d", slot);

	spellsMenu.AddItem(name, "weaponName", ITEMDRAW_IGNORE);
	spellsMenu.AddItem(weaponStr, "weaponEntityId", ITEMDRAW_IGNORE);
	spellsMenu.AddItem(slotStr, "weaponSlotId", ITEMDRAW_IGNORE);

	// Check for renderable options.
	bool canRenderSelectable = inventory.isActiveOverride && inventory.halloweenSpell.isActive;

	// Add the override toggle.
	spellsMenu.AddItem("override", inventory.isActiveOverride && inventory.halloweenSpell.isActive ? "[X] Override spells" : "[ ] Override spells");

	// Add an informative message.
	spellsMenu.AddItem("", "Remember spells will only work if the server has Halloween mode enabled.", ITEMDRAW_DISABLED);

	// Add Exorcism (global spell)
	spellsMenu.AddItem("0", inventory.halloweenSpell.spells & WeaponSpell_Exorcism ? "[X] Exorcism" : "[ ] Exorcism", canRenderSelectable ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// For other spells, we need to check the weapon's classname.
	char weaponClassName[64];
	GetEdictClassname(weapon, weaponClassName, sizeof(weaponClassName));

	// Allow Spectral Flames on flamethrowers.
	if (StrEqual(weaponClassName, "tf_weapon_flamethrower") || StrEqual(weaponClassName, "tf_weapon_rocketlauncher_fireball") && view_as<TFClassType>(class) == TFClass_Pyro)
		spellsMenu.AddItem("1", inventory.halloweenSpell.spells & WeaponSpell_SpectralFlames ? "[X] Spectral Flames" : "[ ] Spectral Flames", canRenderSelectable ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Allow Sentry Quad Pumpkins on wrenches.
	if (StrEqual(weaponClassName, "tf_weapon_wrench") || StrEqual(weaponClassName, "tf_weapon_robot_arm") || StrEqual(weaponClassName, "saxxy") && view_as<TFClassType>(class) == TFClass_Engineer)
		spellsMenu.AddItem("2", inventory.halloweenSpell.spells & WeaponSpell_Explosions ? "[X] Sentry Quad Pumpkins" : "[ ] Sentry Quad Pumpkins", canRenderSelectable ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Allow Gourd Grenades on grenade launchers.
	if (StrEqual(weaponClassName, "tf_weapon_grenadelauncher") || StrEqual(weaponClassName, "tf_weapon_pipebomblauncher") || StrEqual(weaponClassName, "tf_weapon_cannon") && view_as<TFClassType>(class) == TFClass_DemoMan)
		spellsMenu.AddItem("2", inventory.halloweenSpell.spells & WeaponSpell_Explosions ? "[X] Gourd Grenades" : "[ ] Gourd Grenades", canRenderSelectable ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Allow Squash Rockets on rocket launchers.
	if (StrEqual(weaponClassName, "tf_weapon_rocketlauncher") || StrEqual(weaponClassName, "tf_weapon_rocketlauncher_directhit") || StrEqual(weaponClassName, "tf_weapon_particle_cannon") || StrEqual(weaponClassName, "tf_weapon_rocketlauncher_airstrike") && view_as<TFClassType>(class) == TFClass_Soldier)
		spellsMenu.AddItem("2", inventory.halloweenSpell.spells & WeaponSpell_Explosions ? "[X] Squash Rockets" : "[ ] Squash Rockets", canRenderSelectable ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Configure the menu's options.
	spellsMenu.ExitBackButton = true;

	// Display the menu.
	spellsMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Generates a menu to set unusual effects on a weapon.
 *
 * @param client Client index to build the menu for.
 * @param slot Slot ID to configure.
 * @param name The name of the selected weapon.
 * @param weapon Weapon entity index referenced for configuration.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_UnusualMenu(int client, int slot, char[] name, int weapon)
{
	// Create the new menu handle.
	Menu unusualMenu = new Menu(UnusualMenuHandler);

	// Obtain the player's class configuration from their inventory.
	int class		 = TF2_GetPlayerClassInt(client);

	// Access the inventory configuration.
	TFInventory_Weapons_Slot inventory;
	inventory = g_inventories[client][class][slot];

	// Set the menu title.
	char className[64];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	unusualMenu.SetTitle("Weapons / %s / %s / Unusual Effects", className, name);

	// Hidden properties that transfer data to the menu handler.
	char weaponStr[12], slotStr[2];
	Format(weaponStr, sizeof(weaponStr), "%d", weapon);
	Format(slotStr, sizeof(slotStr), "%d", slot);

	unusualMenu.AddItem(name, "weaponName", ITEMDRAW_IGNORE);
	unusualMenu.AddItem(weaponStr, "weaponEntityId", ITEMDRAW_IGNORE);
	unusualMenu.AddItem(slotStr, "weaponSlotId", ITEMDRAW_IGNORE);

	// Add a special option to clear the unusual effect.
	unusualMenu.AddItem("clear", "Clear my selection", inventory.unusualEffectId != -1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	// Add an information item to check their unusual override status.
	char unusualEffectName[64];
	TF2ItemPlugin_GetUnusualEffectName(inventory.unusualEffectId, unusualEffectName, sizeof(unusualEffectName));
	Format(unusualEffectName, sizeof(unusualEffectName), "Selected Unusual: %s", inventory.unusualEffectId == -1 ? "No Unusual Effect" : unusualEffectName);

	unusualMenu.AddItem("", inventory.isActiveOverride && inventory.unusualEffectId == -1 ? "No Unusual override yet. Select one." : unusualEffectName, ITEMDRAW_DISABLED);

	// Add the Unusual Effect ID options.
	for (int i = TF2WeaponUnusual_Hot; i <= TF2WeaponUnusual_EnergyOrb; i++)
	{
		// Get the unusual effect name.
		char effectName[64], effectIdStr[5];
		TF2ItemPlugin_GetUnusualEffectName(i, effectName, sizeof(effectName));
		Format(effectName, sizeof(effectName), inventory.unusualEffectId == i ? "[X] %s" : "[ ] %s", effectName);
		Format(effectIdStr, sizeof(effectIdStr), "%d", i);

		// Add the effect to the menu.
		unusualMenu.AddItem(effectIdStr, effectName, ITEMDRAW_DEFAULT);
	}

	// Add the Community Sparkle effect as another option.
	char communitySparkleName[64], communitySparkleEffectIdStr[5];
	TF2ItemPlugin_GetUnusualEffectName(TF2WeaponUnusual_CommunitySparkle, communitySparkleName, sizeof(communitySparkleName));
	Format(communitySparkleName, sizeof(communitySparkleName), inventory.unusualEffectId == TF2WeaponUnusual_CommunitySparkle ? "[X] %s" : "[ ] %s", communitySparkleName);
	Format(communitySparkleEffectIdStr, sizeof(communitySparkleEffectIdStr), "%d", TF2WeaponUnusual_CommunitySparkle);

	unusualMenu.AddItem(communitySparkleEffectIdStr, communitySparkleName, ITEMDRAW_DEFAULT);

	// Configure the menu's options.
	unusualMenu.ExitBackButton = true;

	// Display the menu.
	unusualMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Generates a menu with a list of all war paints to select from.
 *
 * @param client Client index to build the menu for.
 * @param slot Slot ID to configure.
 * @param name The name of the selected weapon.
 * @param weapon Weapon entity index referenced for configuration.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_WarPaintMenu(int client, int slot, char[] name, int weapon)
{
	// Create the new menu handle.
	Menu warPaintMenu = new Menu(WarPaintMenuHandler);

	// Obtain the player's class configuration from their inventory.
	int class		  = TF2_GetPlayerClassInt(client);

	// Access the inventory configuration.
	TFInventory_Weapons_Slot inventory;
	inventory = g_inventories[client][class][slot];

	// Set the menu title.
	char className[64];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	warPaintMenu.SetTitle("Weapons / %s / %s / War Paint", className, name);

	// Hidden properties that transfer data to the menu handler.
	char weaponStr[12], slotStr[2];
	Format(weaponStr, sizeof(weaponStr), "%d", weapon);
	Format(slotStr, sizeof(slotStr), "%d", slot);

	warPaintMenu.AddItem(name, "weaponName", ITEMDRAW_IGNORE);
	warPaintMenu.AddItem(weaponStr, "weaponEntityId", ITEMDRAW_IGNORE);
	warPaintMenu.AddItem(slotStr, "weaponSlotId", ITEMDRAW_IGNORE);

	// Add a special option to clear the war paint.
	warPaintMenu.AddItem("clear", "Clear my selection", inventory.warPaintId != -1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	warPaintMenu.AddItem("search", "Search by name or ID");

	// Add an information item to check their war paint override status.
	char warPaintName[64];
	TF2ItemPlugin_GetWarPaintName(inventory.warPaintId, warPaintName, sizeof(warPaintName));
	Format(warPaintName, sizeof(warPaintName), "Selected War Paint: %s", inventory.warPaintId == -1 ? "No War Paint" : warPaintName);

	warPaintMenu.AddItem("", inventory.isActiveOverride && inventory.warPaintId == -1 ? "No War Paint override yet. Select one." : warPaintName, ITEMDRAW_DISABLED);

	// Iterate over the list to find the war paint.
	for (int i = 0; i < sizeof(g_paintKits); i++)
	{
		if (g_paintKits[i] == null) continue;

		// Get their ID.
		int id = -1;
		g_paintKits[i].GetValue("id", id);

		// Skip invalid ID numbers.
		if (id == -1) continue;

		// Get the war paint name.
		char paintName[128];
		g_paintKits[i].GetString("name", paintName, sizeof(paintName));

		// Add the war paint to the menu.
		char paintIdStr[12];
		IntToString(id, paintIdStr, sizeof(paintIdStr));

		warPaintMenu.AddItem(paintIdStr, paintName);
	}

	// Configure the menu's options.
	warPaintMenu.ExitBackButton = true;

	// Display the menu.
	warPaintMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Generates a results menu for after a search is done on the war paint menu.
 *
 * @param client Client index to build the menu for.
 * @param slot Slot ID to configure.
 * @param name The name of the selected weapon.
 * @param weapon Weapon entity index referenced for configuration.
 * @param results Array of StringMap instances containing the search results.
 * @param resultsCount Number of results in the array.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_WarPaintMenu_SearchResults(int client, int slot, char[] name, int weapon, StringMap[] results, int resultsCount)
{
	// Create the new menu handle.
	Menu warPaintSearchResultsMenu = new Menu(WarPaintMenuHandler);

	// Obtain the player's class configuration from their inventory.
	int class					   = TF2_GetPlayerClassInt(client);

	// Set the menu title.
	char className[64];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	warPaintSearchResultsMenu.SetTitle("Weapons / %s / %s / War Paint / Search Results", className, name);

	// Hidden properties that transfer data to the menu handler.
	char weaponStr[12], slotStr[2];
	Format(weaponStr, sizeof(weaponStr), "%d", weapon);
	Format(slotStr, sizeof(slotStr), "%d", slot);

	warPaintSearchResultsMenu.AddItem(name, "weaponName", ITEMDRAW_IGNORE);
	warPaintSearchResultsMenu.AddItem(weaponStr, "weaponEntityId", ITEMDRAW_IGNORE);
	warPaintSearchResultsMenu.AddItem(slotStr, "weaponSlotId", ITEMDRAW_IGNORE);

	// Add an informative item about the results.
	warPaintSearchResultsMenu.AddItem("", "If your results are not what you expected, you can go back and search again.", ITEMDRAW_DISABLED);
	warPaintSearchResultsMenu.AddItem("", "Below are the search results for your query:", ITEMDRAW_DISABLED);

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
		char paintName[128];
		results[i].GetString("name", paintName, sizeof(paintName));

		// Add the war paint to the menu.
		char paintIdStr[12];
		IntToString(id, paintIdStr, sizeof(paintIdStr));

		warPaintSearchResultsMenu.AddItem(paintIdStr, paintName);
	}

	// Configure the menu's options.
	warPaintSearchResultsMenu.ExitBackButton = true;

	// Display the menu.
	warPaintSearchResultsMenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Generates a menu for the player to select a specific war paint wear.
 *
 * @param client Client index to build the menu for.
 * @param slot Slot ID to configure.
 * @param name The name of the selected weapon.
 * @param weapon Weapon entity index referenced for configuration.
 *
 * @return void
 */
void TF2ItemPlugin_Menus_WarPaintWearMenu(int client, int slot, char[] name, int weapon)
{
	// Create the new menu handle.
	Menu warPaintWearMenu = new Menu(WarPaintWearMenuHandler);

	// Obtain the player's class configuration from their inventory.
	int class			  = TF2_GetPlayerClassInt(client);

	// Access the inventory configuration.
	TFInventory_Weapons_Slot inventory;
	inventory = g_inventories[client][class][slot];

	// Set the menu title.
	char className[64];
	TF2ItemPlugin_GetTFClassName(view_as<TFClassType>(class), className, sizeof(className));

	warPaintWearMenu.SetTitle("Weapons / %s / %s / War Paint / Wear", className, name);

	// Hidden properties that transfer data to the menu handler.
	char weaponStr[12], slotStr[2];
	Format(weaponStr, sizeof(weaponStr), "%d", weapon);
	Format(slotStr, sizeof(slotStr), "%d", slot);

	warPaintWearMenu.AddItem(name, "weaponName", ITEMDRAW_IGNORE);
	warPaintWearMenu.AddItem(weaponStr, "weaponEntityId", ITEMDRAW_IGNORE);
	warPaintWearMenu.AddItem(slotStr, "weaponSlotId", ITEMDRAW_IGNORE);

	// Add the wear options.
	for (int i = TF2Weapon_PaintWear_FactoryNew; i <= TF2Weapon_PaintWear_BattleScarred; i++)
	{
		// Obtain the wear floating value from the integer.
		float value = TF2ItemPlugin_GetPaintWearFromIndex(i);

		char  wearName[64], wearIdStr[2];
		TF2ItemPlugin_GetWarPaintWearString(value, wearName, sizeof(wearName));
		Format(wearName, sizeof(wearName), value == inventory.warPaintWear ? "[X] %s" : "[ ] %s", wearName);
		Format(wearIdStr, sizeof(wearIdStr), "%d", i);

		warPaintWearMenu.AddItem(wearIdStr, wearName);
	}

	// Configure the menu's options.
	warPaintWearMenu.ExitBackButton = true;

	// Display the menu.
	warPaintWearMenu.Display(client, MENU_TIME_FOREVER);
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
	int	 client = data.ReadCell(), slot = data.ReadCell();

	char weaponName[64], rebuildAction[64];
	data.ReadString(weaponName, sizeof(weaponName));
	data.ReadString(rebuildAction, sizeof(rebuildAction));

	// If the client is dead, return and do nothing.
	if (!IsPlayerAlive(client)) return Plugin_Stop;

	// Obtain the client's weapon at that slot.
	int weapon = GetPlayerWeaponSlot(client, slot);

	// If the entity is not valid, return and do nothing.
	if (!IsValidEdict(weapon)) return Plugin_Stop;

	// Rebuild the desired menu.
	if (StrEqual(rebuildAction, "rebuild_weapons") || StrEqual(rebuildAction, "rebuild_unusual") || StrEqual(rebuildAction, "rebuild_war_paint")) TF2ItemPlugin_Menus_WeaponMenu(client, slot, weaponName, weapon);
	if (StrEqual(rebuildAction, "rebuild_killstreak")) TF2ItemPlugin_Menus_KillstreakMenu(client, slot, weaponName, weapon);
	if (StrEqual(rebuildAction, "rebuild_spells")) TF2ItemPlugin_Menus_SpellsMenu(client, slot, weaponName, weapon);

	// Free up the data pack.
	delete data;

	return Plugin_Stop;
}