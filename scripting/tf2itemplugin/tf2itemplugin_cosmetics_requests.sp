/**
 * Sends an HTTP request to the ConVar set URL to obtain the latest unusual effects information.
 *
 * This function is called on map start.
 *
 * @param url The URL to send the request to.
 *
 * @noreturn
 */
void TF2ItemPlugin_RequestUnusualEffectsData(const char[] url)
{
	// Create a new request handle.
	Handle req = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);

	// Configure the request.
	SteamWorks_SetHTTPRequestNetworkActivityTimeout(req, 15);
	SteamWorks_SetHTTPCallbacks(req, TF2ItemPlugin_RequestUnusualEffectsData_Callback);

	// Send the request.
	bool sent = SteamWorks_SendHTTPRequest(req);
	SteamWorks_PrioritizeHTTPRequest(req);

	// Print the request status.
	LogMessage("Unusual effects data request %s.", sent ? "sent" : "failed");
}

public void TF2ItemPlugin_RequestUnusualEffectsData_Callback(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, any data)
{
	if (bFailure || !bRequestSuccessful)
	{
		LogMessage("Unusual effects data request failed with status code %d", eStatusCode);
		return;
	}

	// Obtain the response body size.
	int bodySize = 0;
	SteamWorks_GetHTTPResponseBodySize(hRequest, bodySize);

	if (bodySize == 0)
	{
		LogMessage("Unusual effects data request returned an empty response body.");
		return;
	}

	// Read the response body.
	char[] responseBody = new char[bodySize];
	SteamWorks_GetHTTPResponseBodyData(hRequest, responseBody, bodySize);

	// Transform the response body into a JSON object.
	Handle json = json_load(responseBody);

	// Must be a valid JSON array, where each object has `id` and `name` keys, or else this will fail.
	int	   size = json_array_size(json);

	LogMessage("Received %d Unusual effect entries.", size);

	// Iterate over each Unusual effect entry.
	for (int i = 0; i < size; i++)
	{
		Handle entry = json_array_get(json, i);

		// Obtain the Unusual ID and name.
		int	   id	 = json_object_get_int(entry, "id");

		char   name[128];
		json_object_get_string(entry, "name", name, sizeof(name));

		// Store the unusual information on the global variable.
		g_unusualEffects[i] = new StringMap();

		g_unusualEffects[i].SetValue("id", id);
		g_unusualEffects[i].SetString("name", name);

		// Free the entry from memory.
		delete entry;
	}

	// Free the JSON object from memory.
	delete json;

	LogMessage("Unusual data has been successfully loaded.");
}