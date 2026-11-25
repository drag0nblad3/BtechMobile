extends TestCase
## Campaign screens' plumbing: saving the company, launching its battle,
## and writing the result back after a save and resume.

const PATH := "user://test_campaign.json"


func test_launch_save_and_finish() -> void:
	CampaignStore.delete(PATH)
	var c := Campaign.create(CampaignRules.load_file())
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var s := CampaignLaunch.build(c, designs(), rng)
	check(s != null, "battle built")
	check_eq(s.units_of_side(0).size(), 4, "the lance deploys")
	check_eq(s.units_of_side(1).size(), 4, "against a lance")
	# CampaignLaunch saved to the default path; copy that roster to the test file.
	var roster := CampaignStore.pending_roster()
	check_eq(roster.size(), 4, "deployment remembered")
	CampaignStore.save(c, roster, PATH)
	CampaignStore.drop_pending()
	check(CampaignStore.pending_roster().is_empty(), "dropping forgets the battle")
	var u := s.unit_by_id(roster.keys()[0])
	u.armor[Location.RA] = 0
	var report := CampaignStore.finish(s, 0, 0, [], PATH)
	check(report.contains("victory"), "report says who won")
	check(CampaignStore.pending_roster(PATH).is_empty(), "battle closed")
	var back := CampaignStore.load_company(PATH)
	check_eq(back.battles, 1)
	check_eq(int(back.mech(roster[u.id]).condition["armor"][Location.RA]), 0, "damage saved")
	check(ConditionText.summary(back.mech(roster[u.id]), designs()).begins_with("Armor"), "condition in words")
	check(ConditionText.weakest(back.mech(roster[u.id]), designs()).contains("Right Arm"), "weakest spot named")
	check_eq(CampaignStore.finish(s, 0, 0, [], PATH), "", "a battle is only written back once")
	CampaignStore.delete(PATH)
	CampaignStore.delete()
