class_name RulesText
extends RefCounted
## Short, original explanations of what each phase is for (FULL level only).
## Written for this game; not quoted from any rulebook.

const PHASE := {
	Phase.Kind.INITIATIVE: "Each side rolls two dice. The low roller must act first in every phase, so the winner gets to react to what the loser does.",
	Phase.Kind.MOVEMENT: "Sides take turns moving one 'Mech at a time. Moving farther makes you harder to hit, but walking or running also spoils your own aim and builds heat.",
	Phase.Kind.WEAPON_ATTACK: "Sides take turns choosing targets. Nothing resolves until everyone has chosen, so a 'Mech destroyed this phase still gets its shots.",
	Phase.Kind.PHYSICAL_ATTACK: "'Mechs next to an enemy may punch (each arm) or kick (once). Kicks are easier to land and hit twice as hard, but a miss can knock you over.",
	Phase.Kind.HEAT: "Heat from movement and weapons is added, then heat sinks remove one point each. High heat slows you, spoils your aim, and can shut you down or cook off ammo.",
	Phase.Kind.END: "Unconscious MechWarriors try to wake up, then a new turn starts.",
}


static func phase(p: int) -> String:
	return PHASE.get(p, "")


## One-line meaning of a to-hit chance.
static func odds_word(chance: float) -> String:
	if chance >= 0.83:
		return "very likely"
	if chance >= 0.58:
		return "likely"
	if chance >= 0.42:
		return "a coin flip"
	if chance >= 0.17:
		return "unlikely"
	return "a long shot"
