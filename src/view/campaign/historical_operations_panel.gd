class_name HistoricalOperationsPanel
extends RefCounted
## Explicitly label the source limitations before starting a campaign.

static func build(parent: VBoxContainer, launch: Callable) -> void:
	UiKit.label(parent, "HISTORICAL OPERATIONS", 25)
	UiKit.label(parent, "Documented starting forces, reconstructed regions and open-ended outcomes. These are company-scale adaptations, not exact tabletop tracks.", UiKit.SMALL)
	for op: Dictionary in HistoricalOperations.all():
		var entry := op
		var card := UiKit.panel(parent)
		UiKit.label(card, "%s · %s" % [entry["title"], entry["date"]], 22)
		UiKit.label(card, String(entry["summary"]), UiKit.SMALL)
		UiKit.label(card, String(entry["fidelity"]), UiKit.SMALL)
		var substitutions := HistoricalOperations.substitutions(entry)
		if not substitutions.is_empty():
			UiKit.label(card, "\n".join(substitutions), 16)
		UiKit.button(card, "START OPERATION", launch.bind(String(entry["id"])), Vector2(0, 52), "secondary")
