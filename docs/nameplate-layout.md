# Combat nameplate layout

Nameplates are projected into a non-interactive 2D overlay below the HUD. Their anchors follow the actual animated unit positions and active camera every frame. A bounded, deterministic greedy layout chooses nearby non-overlapping rectangles about 13 times per second, with the selected unit first. Offset changes are exponentially eased; separated plates return to their natural anchors. Displaced labels receive thin team-colored leader lines. Viewport safe insets are respected; offscreen or behind-camera units do not generate labels. In extreme crowding where no tested placement is clear, the least-overlapping nearby position is used rather than hiding tactical data.

Visibility, name, team, health and to-hit forecasts still come from PlateInfo and the existing invalidation schedule. This is presentation only: no game state, targeting, LOS, or camera changes.
