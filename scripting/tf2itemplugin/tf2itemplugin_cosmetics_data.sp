enum struct TFInventory_Cosmetics_Slot_Paint
{
	/** Indicates if there is an active override for the cosmetics' paint colors. */
	bool isActiveOverride;

	/**
	 * The selected paint index.
	 *
	 * This is used by the plugin to identify both colors.
	 */
	int	 paintIndex;

	/**
	 * Paint color value for the 1st paint color (RED team).
	 */
	int	 paintColor1;

	/**
	 * Paint color value for the 2nd paint color (BLU team).
	 */
	int	 paintColor2;

	/**
	 * If halloween is active, the cosmetic's halloween spell index.
	 */
	int	 halloweenSpellPaintId;
}

enum struct TFInventory_Cosmetics_Slot_Halloween
{
	/** Indicates if there is an active override for the cosmetics' halloween attributes. */
	bool isActiveOverride;

	/**
	 * The halloween footprint index selected by the client.
	 *
	 * -1 means no override is set.
	 */
	int	 halloweenFootstepsIndex;

	/**
	 * If set, the halloween footsteps value used for this cosmetic.
	 *
	 * -1 means no override is set.
	 */
	int	 halloweenFootsteps;

	/** Toggles the halloween voice modulation attribute (Voices from Below). */
	bool halloweenVoiceModulation;
}

enum struct TFInventory_Cosmetics_Slot
{
	/** The client index this slot override belongs to. */
	int client;

	/** The class this override is supposed to be for. */
	int class;

	/** The slot/cosmetic index this override is for. */
	int									 slotId;

	/** If true, marks this slot as actively overriden. */
	bool								 isActiveOverride;

	/** The item definition index for the cosmetic. */
	int									 itemDefIndex;

	/**
	 * If active, will override the cosmetic's unusual effect.
	 *
	 * -1 means no override is set.
	 */
	int									 unusualEffect;

	/** Options to alter cosmetic paint values. */
	TFInventory_Cosmetics_Slot_Paint	 paint;

	/** Options to alter cosmetic halloween attributes. */
	TFInventory_Cosmetics_Slot_Halloween halloween;

	/**
	 * Resets the inventory slot to default values.
	 *
	 * @param bool resetAll If true, will reset all values. If false, will only reset the item definition index.
	 *
	 * @return void
	 */
	void								 Reset(bool resetAll = false){
		// Disable the slot override setting.
		this.isActiveOverride = false;

		// If a resetAll is requested, reset all values.
		if (resetAll){
			this.itemDefIndex						= -1;
			this.unusualEffect						= -1;

			// Reset paint values.
			this.paint.isActiveOverride				= false;
			this.paint.paintIndex					= -1;
			this.paint.paintColor1					= -1;
			this.paint.paintColor2					= -1;
			this.paint.halloweenSpellPaintId		= -1;

			// Reset halloween values.
			this.halloween.isActiveOverride			= false;
			this.halloween.halloweenFootstepsIndex	= -1;
			this.halloween.halloweenFootsteps		= -1;
			this.halloween.halloweenVoiceModulation = false; }
}
}