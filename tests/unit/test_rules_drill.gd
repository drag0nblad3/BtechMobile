extends TestCase
## Rules drills: well-formed questions whose answers match the rules code.


func test_every_kind_is_well_formed() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for kind in RulesDrill.KINDS:
		for i in 25:
			var q := RulesDrill.make(rng, designs(), terrain(), kind)
			check_eq(q["kind"], kind, "kind")
			var choices: Array = q["choices"]
			check(choices.size() >= 2, "%s has choices" % kind)
			check(int(q["answer"]) >= 0 and int(q["answer"]) < choices.size(), "%s answer listed: %s" % [kind, q])
			var unique := {}
			for c in choices:
				unique[c] = true
			check_eq(unique.size(), choices.size(), "%s choices distinct" % kind)
			check(String(q["explain"]) != "", "explained")


func test_to_hit_answer_is_the_summary_total() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 10:
		var q := RulesDrill.make(rng, designs(), terrain(), "to_hit")
		var right: String = q["choices"][int(q["answer"])]
		check(String(q["explain"]).contains("= %s." % right), "%s / %s" % [right, q["explain"]])


func test_location_matches_table() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var q := RulesDrill.make(rng, designs(), terrain(), "location")
	var right: String = q["choices"][int(q["answer"])]
	check(String(q["explain"]).contains(right.to_lower()), q["explain"])
