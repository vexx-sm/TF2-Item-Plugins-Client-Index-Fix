/**
 * Represents a weapon's Halloween spell stack configuration.
 */
enum struct TFInventory_Weapons_Slot_Spells {
    /**
     * Boolean value that controls if Halloween spells are active for this weapon.
     */
    bool isActive;

    /**
     * Bitfield that holds the enabled Halloween spells for this weapon.
     */
    int spells;

    /**
     * Resets all properties to their default values.
     *
     * @return void
     */
    void Reset() {
        // Reset all properties to their default values.
        this.spells = 0;
    }
}

/**
 * Represents a weapon's killstreak configuration.
 */
enum struct TFInventory_Weapons_Slot_Killstreak {
    /**
     * Controls if the killstreak configuration is active.
     */
    bool isActive;

    /**
     * If specified, the killstreak tier to use for this weapon.
     *
     * - 0 - None
     * - 1 - Basic
     * - 2 - Specialized
     * - 3 - Professional
     */
    int tier;

    /**
     * If specified, the killstreak sheen to use for this weapon.
     *
     * Note that the sheen will only be applied if the killstreak tier is Specialized.
     *
     * - 0 - None
     * - 1 - Team Shine
     * - 2 - Deadly Daffodil
     * - 3 - Manndarin
     * - 4 - Mean Green
     * - 5 - Agonizing Emerald
     * - 6 - Villanious Violet
     * - 7 - Hot Rod
     */
    int sheen;

    /**
     * If specified, the killstreak effect to use for this weapon.
     *
     * Note that the effect will only be applied if the killstreak tier is Professional.
     *
     * - 0 - None
     * - 2002 - Fire Horns
     * - 2003 - Cerebral Discharge
     * - 2004 - Tornado
     * - 2005 - Flames
     * - 2006 - Singularity
     * - 2007 - Incinerator
     * - 2008 - Hypno-Beam
     */
    int killstreaker;

    /**
     * Resets all properties to their default values.
     *
     * @return void
     */
    void Reset() {
        // Disable the killstreak configuration.
        this.isActive = false;

        // Reset all properties to their default values.
        this.tier = 0;
        this.sheen = 0;
        this.killstreaker = 0;
    }
}

/**
 * Represents a slot within an inventory's customizable options.
 */
enum struct TFInventory_Weapons_Slot {
    /** The client ID this inventory configuration belongs to. */
    int client;

    /** The class this specific configuration is for. */
    int class;

    /**
     * An indicator for when this slot is actively overriden.
     *
     * If this is active, the slot's information will be used when the user's weapons are parsed.
     * Whenever not active, user-equipped weapons will be used instead.
     */
    bool isActiveOverride;

    /**
     * The slot ID this slot represents.
     *
     * 0 - Primary Weapon
     * 1 - Secondary Weapon
     * 2 - Melee Weapon
     * 3 - PDA Slot 1
     * 4 - PDA Slot 2
     * 5 - Building Slot 1
     */
    int slotId;

    /** If specified and active override, the weapon definition index to use for this slot. */
    int weaponDefIndex;

    /**
     * Special item definition index used to track stock weapon conversions.
     *
     * If this is set, it means all overrides in this slot are for a stock weapon that requires conversion to its strange variant.
     * All overrides will be applied to this index instead of the weaponDefIndex.
     */
    int stockWeaponDefIndex;

    /** If specified and active override, the weapon quality to use for this slot. */
    int quality;

    /** If specified and active override, the weapon level to use for this slot. */
    int level;

    /** Controls if the weapon should be australium. */
    bool isAustralium;

    /** Controls if the weapon should be festive. */
    bool isFestive;

    /**
     * Property that specifies a War Paint ID to use for this slot.
     *
     * @see tf/resource/tf_proto_obj_defs_english.txt for War Paint IDs and their corresponding names.
     */
    int warPaintId;

    /**
     * If a War Paint is specified, this property specifies the wear of the War Paint.
     *
     * Wear is specified in a percentage value from 0 to 1, however the display name will show up in between the following values:
     * - 0.0 and 0.2: Factory New
     * - 0.4: Minimal Wear
     * - 0.6: Field-Tested
     * - 0.8: Well-Worn
     * - 1.0: Battle Scarred
     */
    float warPaintWear;

    /**
     * Specifies a weapon unusual effect ID to use for this slot.
     */
    int unusualEffectId;

    /**
     * If halloween is active, the weapon's halloween spell configuration.
     */
    TFInventory_Weapons_Slot_Spells halloweenSpell;

    /**
     * If specified, the weapon's killstreak configuration.
     */
    TFInventory_Weapons_Slot_Killstreak killstreak;

    /**
     * Resets all properties to their default values.
     *
     * @return void
     */
    void Reset(bool fullReset = false) {
        // Disable the slot override.
        this.isActiveOverride = false;

        if (fullReset) {
            // Reset all properties to their default values.
            this.weaponDefIndex = -1;
            this.stockWeaponDefIndex = -1;
            this.quality = -1;
            this.level = -1;
            this.isAustralium = false;
            this.isFestive = false;
            this.warPaintId = -1;
            this.warPaintWear = -1.0;
            this.unusualEffectId = -1;

            this.halloweenSpell.Reset();
            this.killstreak.Reset();
        }
    }
}

/**
 * Optional configuration options for the user on how their inventory changes behave.
 */
enum struct TFInventory_Weapons_Options {
    /**
     * Controls if custom descriptions and names are kept on overriden weapons.
     */
    bool keepCustomNames;
}
