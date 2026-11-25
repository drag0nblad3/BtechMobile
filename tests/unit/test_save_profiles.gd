extends TestCase


func test_legacy_paths_and_isolation() -> void:
	check_eq(SaveProfiles.path_for(BattleSave.SAVE_PATH, 0), BattleSave.SAVE_PATH)
	var seen := {}
	for slot in SaveProfiles.COUNT:
		for file: String in SaveProfiles.FILES:
			var path := SaveProfiles.path_for("user://" + file, slot)
			check(not seen.has(path), "each slot and save type has a unique path")
			seen[path] = true
	check_eq(SaveProfiles.path_for("user://test_campaign.json", 2), "user://test_campaign.json")


func test_campaign_pending_data_isolated() -> void:
	var old := SaveProfiles.active()
	var c := Campaign.create(CampaignRules.load_file(), ChaosRules.load_file())
	if not SaveProfiles.select(4):
		check(false, "select save workspace")
		return
	CampaignStore.delete()
	check(CampaignStore.save(c, {1: c.mechs[0].id}))
	check_eq(CampaignStore.pending_roster().get(1), c.mechs[0].id)
	check_eq(CampaignStore.load_company().name, c.name)
	CampaignStore.delete()
	SaveProfiles.select(old)
