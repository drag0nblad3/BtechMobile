extends TestCase
## Verify the content uses existing rules and persists narrative text.

func test_new_maps_and_themes() -> void:
	for id in ["industrial", "fortified", "coastal", "alpine", "ash_fields", "agricultural"]:
		check(MapTheme.find(id) != null, id)
	for id in ["industrial_yard", "ridge_pass", "fortified_crossroads"]:
		var m := MapLoader.load_file("res://data/maps/%s.json" % id, terrain())
		check_eq(m.tiles.size(), m.width * m.height, id)


func test_advanced_course_has_five_missions() -> void:
	var c := TrainingCampaign.load_file()
	var count := 0
	for m in c.missions:
		if m.get("section", "") == "Advanced Tactical Academy":
			count += 1
	check_eq(count, 5)


func test_contract_story_is_stable_and_survives_save() -> void:
	var c := Campaign.new()
	c.name = "Test Company"
	var k := Contract.new()
	k.mission_id = "objective_raid"
	k.story = CampaignStory.offer(c, k, 0)
	check_eq(k.story, CampaignStory.offer(c, k, 0))
	var restored := Contract.from_dict(k.to_dict())
	check_eq(restored.story, k.story)
	check(CampaignStory.outcome(restored, true, 2).contains("2 contract objectives met"))
	c.battles = 1
	c.last_met = 0
	check(CampaignStory.offer(c, k, 0)["briefing"].contains("setback"))
