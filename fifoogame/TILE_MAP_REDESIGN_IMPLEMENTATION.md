# FifooGame Tile Day Map — Implementation History (Passes 3–4)

This pass is the first device-driven refinement of the square-card day map. It is based on the real iPhone screenshot captured after Pass 2, rather than only the source architecture.

## What the screenshot confirmed

The core migration is working:

- the time/progress Cartesian map remains intact;
- pan/zoom still expose the day as a 2D board;
- GameNodes render inside square cards;
- Completed, Chosen and Alternate path membership is readable without visible roads;
- the current-path boundary is visible;
- remote Post artwork renders inside a card;
- path-only cells correctly bridge between GameNode cards.

The screenshot also showed four issues that should be corrected before adding backend persistence:

1. Path-only cards were visually louder than real GameNode cards because they used large `Done`, `Next`, and `Option` labels.
2. Completed/chosen borders and glows were too thick at real device scale.
3. Hidden cards contained more branding text than necessary and the whole board felt slightly cramped.
4. Pass 2 still seeded all existing GameNodes as revealed, so the actual hidden -> flip -> reveal mechanic was not yet the default gameplay behavior.

## Pass 3 changes

### 1. Discovery-first reveal policy is now the default

Added `DayMapTileRevealPolicy`:

- `.discoveryFirst` — new default;
- `.revealAllNodes` — compatibility/debug option.

With `.discoveryFirst`:

- ordinary GameNodes begin hidden;
- a hidden GameNode card is visually indistinguishable from an unused hidden card;
- first tap on a hidden stop card flips/reveals it;
- second tap invokes the existing GameNode sheet/full-screen action;
- Completed, Chosen, Alternate, and path-preview cells remain automatically exposed because they communicate the user's path;
- a GameNode created by the user is revealed immediately;
- editing a stop keeps/reveals its card;
- backend stop snapshots no longer automatically reveal every unrelated stop.

Reveal persistence is still memory-only. No new Socket.IO event/schema has been invented yet.

### 2. Path-only cards are now intentionally quiet

Path-only cards no longer show large centered:

- `Done`
- `Next`
- `Option`

The colored card perimeter remains the primary path language, matching the original product concept that the path is a sequence of revealed squares with boundaries.

A small centered diamond (`◆`) is used as a restrained path motif, with a small footer label (`DONE`, `CHOSEN`, `ALT`, or preview state) for secondary clarity.

Real GameNode cards therefore regain visual priority.

### 3. Path styling was reduced for real-device scale

Completed/chosen/alternate/preview boundaries now use:

- thinner strokes;
- much smaller glows;
- lighter interior tints.

The state is still obvious, but the perimeter should no longer visually consume the card.

### 4. Card spacing now reads more like islands

The semantic grid pitch is unchanged, but `tileGapWorld` increased from the Pass 2 value to a larger visual gap.

This is presentation-only:

- no time coordinate changes;
- no progress coordinate changes;
- no path/pathfinding changes;
- no camera changes.

### 5. Revealed stop hierarchy was retuned

At real device scale:

- artwork is larger relative to the card;
- the artwork sits slightly higher;
- title/footer positions were adjusted;
- type/time/footer typography is slightly quieter.

This gives stop imagery and the stop title more weight without increasing the physical grid pitch.

### 6. Hidden card backs were simplified

Hidden cards retain the Fifoo `F` mark, but:

- the mark is smaller and lower contrast;
- the redundant `FIFOO` caption is removed;
- hidden borders are quieter.

The goal is for unrevealed space to recede instead of competing with revealed gameplay content.

### 7. Selection and current-boundary chrome was reduced

The white selection ring is thinner and uses less glow.

The current-path boundary dot is slightly smaller so it remains a state marker rather than becoming the strongest visual object on the card.

## Architecture intentionally unchanged

Pass 3 does **not** replace or delete:

- `RoadGraph`;
- path pathfinding;
- alternative path generation;
- future path planning/commit;
- completed-path progression;
- path switching;
- path inspectors;
- GameNode sheets/editors;
- SocketManager path/stop payloads;
- time/progress coordinate conversion;
- pan/zoom/momentum/clamping.

The road system remains a hidden semantic engine. Cards remain the only visible navigation surface.

## Files materially changed in Pass 3

- `Game/Domain/Tiles/DayMapTile.swift`
- `Game/Domain/Grid/GridMapGeometry.swift`
- `Game/Rendering/MapGridRenderer.swift`
- `Game/Rendering/MapVisualTheme.swift`
- `Game/Store/GameStore.swift`

## Validation performed

All 154 Swift files were run through Swift frontend parsing after Pass 3 changes.

Result:

- 154 parsed;
- 0 parser failures.

As before, the supplied source archive does not include an `.xcodeproj`, `.xcworkspace`, or `project.pbxproj`, so an actual iOS SDK build/type-check cannot be run in this environment.

## What to test in Xcode next

1. Launch the same full-day DEBUG fixture used for the Pass 2 screenshot.
2. Confirm off-path GameNode cards now begin hidden.
3. Tap a hidden card known to contain a stop:
   - first tap should flip it;
   - second tap should open the existing stop UI.
4. Confirm Completed/Chosen/Alternate path cards remain exposed without needing manual reveal.
5. Confirm path-only cards now show a quiet diamond rather than large `Done`/`Next`/`Option` text.
6. Check the path colors at normal zoom and when zoomed out.
7. Confirm artwork remains correctly cropped after the card-size/spacing adjustments.
8. Capture one normal-zoom screenshot and one zoomed-out screenshot for Pass 4.

## Recommended Pass 4

After visual confirmation, the next implementation step should be path-card topology and gameplay polish:

- make adjacent path cards read as one coherent path without reintroducing roads;
- distinguish path stop cards from path transit cards more deliberately;
- add optional reveal haptic/sound feedback;
- define whether reveal state persists per day, per user, or server-authored;
- then design and add the backend reveal-state contract.

Only after those behaviors are stable should the remaining legacy visible-road renderer/hit-test code be removed from the source tree.

---

# FifooGame Tile Day Map — Implementation Pass 4

Pass 4 is driven by the two real-device screenshots captured after Pass 3: one at the normal gameplay scale and one zoomed farther out. Those screenshots confirm the card design is stable, while also showing that path membership still reads as a set of separately highlighted cards rather than one continuous journey through the day.

## What the Pass 3 screenshots confirmed

At both zoom levels:

- hidden cards now recede appropriately;
- GameNode cards remain legible;
- completed, chosen and alternate path colors are distinguishable;
- path-only diamond cards no longer overpower actual GameNodes;
- the larger card spacing reads much more like islands;
- pan/zoom and the time/progress coordinate system remain intact.

The remaining visual problem is path continuity. The eye can infer the green and blue sequences, but the gutters interrupt them strongly enough that the path still feels like a collection of selected cells.

## Pass 4 changes

### 1. Path projection now preserves card order

`DayMapTileResolver` no longer uses only unordered `Set<GridCellID>` projections for path presentation.

It now also creates an ordered card chain from each existing `RoadRouteSegment` sequence:

1. sample the hidden road-path geometry in traversal order;
2. project each sample to the nearest tile/card;
3. collapse consecutive duplicate cells;
4. preserve path traversal order;
5. create a connection only between consecutive neighboring cards.

The old `RoadGraph` remains the semantic/pathfinding engine. This ordered card chain is presentation data only.

### 2. Added explicit path-connection presentation state

`DayMapTileRenderState` now contains `routeConnections` in addition to per-card snapshots.

Each `DayMapTileRouteConnection` records:

- first card;
- second card;
- visual path style.

Supported connection styles are:

- completed;
- chosen;
- alternative;
- selected preview;
- alternate preview.

Connections are canonicalized and de-duplicated.

When multiple path layers use the same card-to-card edge, visual priority is:

1. selected preview;
2. preview alternative;
3. completed;
4. chosen;
5. alternative.

This prevents overlapping green/blue/gray bridge strokes on shared path sections.

### 3. Added card-to-card path stitching

`MapGridRenderer` now owns a dedicated `routeConnectorContainerNode`.

For each sequential path connection, it draws a center-to-center SpriteKit stroke **under** the cards. Because the card faces render above it, nearly the entire stroke is masked. The only visible portion is the short segment crossing the gutter between the two cards.

Visually this should read approximately as:

```text
+---------+     +---------+
|         |=====|         |
|  CARD   |=====|  CARD   |
|         |=====|         |
+---------+     +---------+
```

rather than as a traditional road or path line.

This keeps the product metaphor intact:

> the path is still a sequence of square islands; the small bridge merely stitches their boundaries into one readable chain.

### 4. Path bridges are state-aware

Bridge color follows the same path hierarchy as card borders:

- green = completed;
- blue = chosen;
- muted light = alternate;
- orange = selected path-builder preview;
- subdued white = preview alternative.

Completed and chosen bridges are thicker than alternate bridges, matching their visual importance.

A very low-alpha halo sits behind the bridge so continuity remains visible when zoomed out without restoring the heavy glow from Pass 2.

### 5. Connections are culled with the visible card region

The connector layer is rebuilt only when:

- tile render state changes; or
- the camera crosses into a new visible grid region.

Only connections touching the visible buffered region are drawn.

This preserves the existing cell recycling / camera culling architecture and avoids creating SpriteKit stops for the entire horizontally unbounded map.

### 6. Invalid long jumps are never visualized

Path sampling should normally advance one grid card at a time. Pass 4 explicitly refuses to draw a connector when two consecutive projected samples jump more than one row or column.

This is a presentation safety rule only. It does not alter path semantics or pathfinding if malformed or unusual path data is ever received.

## Architecture intentionally unchanged

Pass 4 still does not delete or rewrite:

- `RoadGraph`;
- path pathfinding;
- completed-path progression;
- future path planning;
- alternative path generation;
- path switching;
- GameNode sheets/editors;
- SocketManager path/stop contracts;
- time/progress conversion;
- camera pan/zoom/momentum;
- reveal persistence behavior.

The hidden road system continues to answer *where the user can travel*. The tile system now owns *what that travel looks like*.

## Files materially changed in Pass 4

- `Game/Domain/Tiles/DayMapTile.swift`
- `Game/Rendering/MapGridRenderer.swift`
- `TILE_MAP_REDESIGN_IMPLEMENTATION.md`

## Validation performed

All 154 Swift source files were parsed after the Pass 4 changes.

Result:

- 154 parsed;
- 0 parser failures.

The supplied source archive still does not contain an `.xcodeproj`, `.xcworkspace`, or `project.pbxproj`, so iOS SDK type-check/build validation must still happen in the real Xcode project.

## What to test in Xcode next

1. Launch the same full-day DEBUG path fixture used for the Pass 3 screenshots.
2. Inspect the completed green path around 6 AM through midday.
3. Confirm sequential green cards now have a short green bridge across their gutter.
4. Inspect the chosen blue path after midday and confirm the same behavior in blue.
5. Confirm alternate branches use a thinner subdued bridge.
6. Confirm two adjacent path-colored cards are **not** connected merely because they touch; they should be connected only when the path traversal says they are sequential.
7. Zoom out to roughly the scale of `Screenshot4` and confirm the green/blue path now reads as one continuous chain.
8. Pan horizontally so connectors enter and leave the buffered visible region; there should be no visible pop-in inside the viewport.
9. Confirm all card taps still work and the gutter bridges themselves do not intercept touches.
10. Confirm path-builder previews stitch in orange / subdued white without exposing the old road renderer.

## Earlier recommendation after Pass 4

After path stitching is visually confirmed, the next implementation pass should move from map presentation into gameplay/state polish:

- define the persistence scope for revealed cards (per user + day is the strongest current candidate);
- add explicit Socket.IO/backend reveal-state payloads only after that scope is agreed;
- add reveal feedback (haptic and optional sound) at the scene/application boundary;
- decide whether hidden empty cards and hidden stop cards remain intentionally indistinguishable;
- then begin deleting truly obsolete visible-road rendering/hit-test code once no current UI path depends on it.


# Pass 5 — Full-Bleed Card Faces + Path Pattern Styling

Pass 5 is a focused visual rewrite requested after the Pass 4 device screenshots. It does not change path semantics, pathfinding, reveal behavior, coordinate conversion, or map interaction.

## 1. Revealed GameNode cards are now full bleed

The revealed face no longer contains an inset artwork tile. The GameNode artwork now aspect-fills the entire card/island and is clipped only by the card's outer rounded shape.

The previous inner card border and artwork border have been removed from the visible composition. One subtle outer face border remains above the image.

Text remains readable through two dark translucent overlays:

- a compact top overlay for the GameNode kind;
- a stronger bottom overlay for title, time, and path-state label.

The overlay shapes are inside the same crop as the artwork so they follow the card corners exactly.

## 2. Card corner radius reduced by half

The card radius changed from approximately `min(17, tileSize * 0.165)` to `min(8.5, tileSize * 0.0825)`. The same reduced-radius geometry is reused by the image mask and path perimeter so the whole island remains visually coherent.

## 3. Path highlight language changed

The path-state hierarchy is now:

- **completed:** solid green perimeter;
- **chosen:** diagonal green/white striped perimeter;
- **alternate:** diagonal orange/white striped perimeter.

The striped perimeters are generated once as cached `SKTexture`s and displayed through a dedicated `routePatternNode`, avoiding a large number of individual SpriteKit stripe stops per visible card.

Pass 4 path bridges remain, but their dominant colors now follow the new hierarchy:

- completed bridge = green;
- chosen bridge = green;
- alternate bridge = orange.

The striped card boundary distinguishes chosen from completed while the common green bridge keeps the main path visually continuous.

Path-builder alternative previews also use the orange/white striped language.

## 4. Multi-stop points now look like physical card stacks

The `+N` badge has been retired.

When more than one GameNode occupies the same `GridCellID`, the renderer exposes offset back-card edges beneath the front card:

- two stops -> one back-card edge;
- three or more -> two back-card edges.

The stack is visible for both hidden and revealed cells. Hidden stacks use hidden-card colors, so multiplicity is communicated without revealing the hidden GameNode content.

## Files materially changed in Pass 5

- `Game/Rendering/MapGridRenderer.swift`
- `Game/Rendering/RouteVisualTheme.swift`
- `TILE_MAP_REDESIGN_IMPLEMENTATION.md`

## Pass 5 visual checks

1. Reveal an Activity/Post/Play card and confirm its image reaches every edge of the card face.
2. Confirm there is no inset inner frame around the image.
3. Confirm kind/title/time/status remain legible on dark overlays.
4. Compare the new corners to Pass 4; they should be roughly half as rounded.
5. Confirm completed path cards retain a solid green perimeter.
6. Confirm chosen path cards have a clearly alternating green/white striped perimeter.
7. Confirm alternate path cards have a clearly alternating orange/white striped perimeter.
8. Zoom out and confirm the stripe patterns remain recognizable rather than collapsing into blue/gray borders.
9. Locate the existing multi-stop point (for example the former `+1` card) and confirm the badge is gone and offset card edges are visible instead.
10. Confirm hidden multi-stop points show stacked hidden cards without leaking their contents.

## Recommended Pass 6

After confirming this styling on device, the next useful pass is interaction/gameplay polish rather than another architecture change: reveal haptic/sound feedback, persistence scope for discovered cards, and cleanup of legacy visible-road renderer code that is now provably unused.

# Pass 5.1 — Minimal Card Text

Pass 5.1 is a focused readability cleanup based on the Pass 5 device screenshots.

## Card-face text is now limited to title + time

Revealed GameNode cards no longer render the stop-kind header (`ACTIVITY`, `USER`, `POST`, `PLAY`, etc.). The top dark overlay used only for that label has also been removed, allowing more of the full-bleed image to remain unobscured.

Path-state text labels are also removed from card faces. `DONE`, `CHOSEN`, `ALT`, `PREVIEW`, and `OPTION` are no longer rendered. Path state is communicated entirely by the existing visual language:

- completed = solid green perimeter/bridge;
- chosen = green/white striped perimeter with green bridge;
- alternate = orange/white striped perimeter with orange bridge;
- preview states = their existing preview border/connector treatment.

The path-only diamond motif remains because it is a non-verbal visual marker rather than a text status label.

For GameNode cards, the only text now rendered on the face is:

- title;
- time.

The bottom dark readability overlay remains for those two values.

## DEBUG fixture title cleanup

The full-day DEBUG path fixture previously baked path roles directly into example titles (`Chosen: ...`, `Alt 1: ...`, etc.). Those prefixes have been removed so device screenshots exercise the same presentation rule: path role comes from the perimeter/connector styling, not from duplicated title text.

## Files materially changed in Pass 5.1

- `Game/Rendering/MapGridRenderer.swift`
- `Game/DEBUG/DebugRouteRenderDemo.swift`
- `TILE_MAP_REDESIGN_IMPLEMENTATION.md`

# Pass 5.2 — Alternate Path Focus Interaction

Pass 5.2 changes how alternate paths are presented and tapped while leaving the hidden `RoadGraph`, pathfinding, path generation, and normal GameNode sheets intact.

## 1. Alternate paths no longer draw join/bridge paths

Live alternate paths no longer contribute `DayMapTileRouteConnection` gutter bridges. Their orange/white striped card perimeter is the only persistent alternate-path cue.

Unselected alternate path previews also avoid gutter bridges. Completed and chosen path connections remain unchanged.

## 2. First tap on an alternate GameNode isolates one path

`GameStore` now owns `focusedAlternativeRouteID`.

When a revealed tile contains a GameNode and its current tile path target is `.alternative(routeID:)`:

- if that path is not already focused, the tap sets `focusedAlternativeRouteID` and does **not** open the stop sheet;
- the rendered path state is filtered to completed history plus exactly that one alternate path;
- the chosen path and every unrelated alternate path are temporarily omitted from the path presentation.

If more than one alternate path passes through the tapped card, the tile resolver's existing deterministic path ordering supplies one path ID. No attempt is made to show all paths through that point.

Ordinary non-path stop cards remain visible; what is isolated is the path-state presentation.

## 3. Second tap opens stop details

Once the alternate path represented by the card is already focused, tapping a GameNode on that focused alternate path follows the existing `requestGameNodeAction` path and opens the normal details sheet/full-screen presentation.

This keeps stop presentation unchanged while giving the first tap a path-exploration role.

## 4. Exiting alternate focus

Background taps, non-alternate stop taps, and path-only card interactions clear alternate-path focus and restore the normal completed/chosen/all-alternates path render state.

## Files materially changed in Pass 5.2

- `Game/Store/GameStore.swift`
- `Game/Domain/Tiles/DayMapTile.swift`
- `App/SocketManager.swift`
- `App/DayMapView.swift`
- `TILE_MAP_REDESIGN_IMPLEMENTATION.md`

## Pass 5.2 visual/interaction checks

1. At normal map state, confirm orange/white alternate card borders remain visible but no orange connector/join paths are drawn between them.
2. Tap an alternate GameNode once.
3. Confirm completed path highlighting remains.
4. Confirm exactly one alternate path through that card remains highlighted.
5. Confirm the chosen path and other alternate-path highlights disappear while focused.
6. Confirm the focused alternate itself still has no orange join paths; only its striped card borders identify its path.
7. Tap a GameNode on that focused alternate path again and confirm its normal stop details presentation opens.
8. Tap empty map background and confirm the normal chosen + alternate path presentation returns.


## Pass 5.3 — Focused Alternate Connectors + Neutral Empty Alternates

> Pass 5.3 supersedes the Pass 5.2 visual rule that focused alternates had no join paths.

- Unfocused alternate paths no longer style empty transit cells. Only alternate cells that actually contain a GameNode retain the orange/white striped perimeter.
- First tap on an alternate GameNode still isolates exactly one alternate path plus completed history.
- While that alternate is focused, all cells belonging to the selected alternate path are revealed/styled and orange join bridges are restored between sequential path cells.
- Second tap on a stop belonging to that focused alternate still opens the normal GameNode details presentation.
- Clearing alternate focus restores the neutral empty cells and removes alternate join bridges again.

## Pass 5.4 — Alternate-path preview overlay and interaction lock

Clarifies the focused-alternate interaction as an explicit preview mode.

- The first tap on an alternate GameNode still selects one deterministic alternate path through that stop and renders completed history plus that alternate path.
- While an alternate is focused, `VirtualMapScene` suppresses semantic taps only. Pan, momentum, and pinch-to-zoom remain available because the camera gesture system is not disabled.
- `DayMapView` presents a compact glass-style preview control bar above the existing bottom navigation. It exposes:
  - **View Path** — opens the existing alternate `RouteInspectorView` sheet for the focused path.
  - **Preview progress** — shows the focused path's projected ending progress percentage, using the final resolvable path stop's X/progress coordinate.
  - **Close** — clears alternate preview focus/selection and restores the normal chosen-path presentation.
- Choosing the alternate from `RouteInspectorView` also exits preview mode because that path has become the real chosen path.
- The overlay does not use a full-screen SwiftUI hit-testing surface; only its compact control bar accepts SwiftUI touches. This prevents accidental loss of SpriteKit map pan/zoom gestures.

## Pass 5.5 — Thinner Path-Type Borders

- Reduced the visible completed tile perimeter from `3.75` to `1.5` world points (60% thinner).
- Reduced the completed perimeter glow from `0.75` to `0.30` to preserve the thinner appearance.
- Reduced chosen and alternate striped perimeter thickness from `5.0` to `2.0` world points (60% thinner).
- Kept path join/bridge widths unchanged.
- Kept path-builder preview border widths unchanged; this pass only targets completed/chosen/alternate path-state borders.
- Included border width in the striped-border texture cache key so old-width textures cannot be reused accidentally.


## Pass 5.6 — Pied Piper Card Back

Face-down / hidden day-map cards now use the supplied Pied Piper silhouette instead of the previous `F` glyph.

Implementation details:

- Added `Resources/Assets.xcassets/pied_piper_card_back.imageset`.
- The supplied raster was cleaned into a transparent 512×512 silhouette asset so the white source background does not appear on the card.
- `MapGridRenderer.RenderedCell` now owns a `hiddenArtworkSpriteNode` rather than hidden-card text labels.
- `MapGridRenderer` keeps one shared `SKTexture` for the Pied Piper card-back asset and reuses it across recycled cells.
- The emblem is centered at 72% of the card size and tinted white at 32% opacity so it remains visible but subordinate to revealed content and path states.
- Existing hidden/revealed flip logic is unchanged: the emblem lives exclusively inside `hiddenLayer`, so it automatically disappears at the midpoint of the card flip when a tile is revealed.

## Pass 5.7 — Colored Pied Piper Path Assets

Added colored Pied Piper assets and started using them on empty path-only cards.

Implementation details:

- Added these asset-catalog image sets under `Resources/Assets.xcassets`:
  - `green_pied_piper.imageset`
  - `orange_pied_piper.imageset`
  - `purple_pied_piper.imageset`
- All three assets reuse the transparent Pied Piper silhouette and recolor it directly in the image file so the renderer can reference them by asset name.
- `MapGridRenderer` now keeps shared `SKTexture`s for:
  - `green_pied_piper`
  - `orange_pied_piper`
  - `purple_pied_piper`
- Added `routeArtworkSpriteNode` to `RenderedCell` so path-only empty cards can show image-based path motifs instead of the text diamond alone.
- Empty path-only cards now behave as follows:
  - **Completed** empty path cards use `green_pied_piper`.
  - **Chosen** empty path cards use `green_pied_piper`.
  - **Focused selected alternate** empty path cards use `orange_pied_piper`.
  - Preview-only cards continue to use the small diamond motif.
- Hidden/down-facing cards still use the existing neutral `pied_piper_card_back` asset; the new colored variants do not replace the ordinary hidden-card back.
- The purple asset is added to the asset catalog and texture pool now, but is intentionally not yet assigned to any card state.

## Pass 5.8 — Purple Undiscovered Stops + Path/Stop Terminology

Two presentation-language changes were applied without renaming the legacy internal route/node engine types.

### Purple undiscovered content stops

- A face-down card that already contains GameMapNode content, but is not currently part of completed/chosen/alternate path presentation, now uses `purple_pied_piper` on its hidden face.
- Empty face-down map cards continue to use the neutral `pied_piper_card_back` artwork.
- The purple asset keeps its authored RGB color (`colorBlendFactor = 0`) and renders at higher opacity than the neutral hidden-card mark so users can distinguish an undiscovered content stop from an empty map card without revealing the content itself.
- The existing flip/reveal interaction is unchanged.

### User-facing terminology

From this pass forward the product language is:

- **Path** instead of **Route**
- **Stop** instead of **Node**
- A path is an ordered sequence of stops, visually represented by the map cards/islands.

User-facing labels, buttons, sheets, validation messages, search/help copy, preview copy, and debug-visible text were migrated to Path/Stop terminology.

The existing internal Swift/domain/network names such as `GameMapNode`, `RouteID`, `DayRouteState`, Socket.IO event names, serialized keys (`nodeId`, `routeId`), and route/pathfinding engine filenames remain unchanged for compatibility. Renaming those identifiers would be a separate schema/API refactor and is intentionally not part of this visual/terminology pass.

## Pass 5.9 — Empty Path Stop Content Chooser

Empty cards that already belong to a visible path now represent an explicit stop-content opportunity.

Behavior:

- Tapping an empty completed/chosen/visible alternate path card no longer opens path details directly.
- The tap emits `EmptyPathStopRequest`, preserving the exact grid cell, semantic time/progress coordinate, and internal path target.
- `DayMapView` presents a two-choice sheet:
  - **Suggested Stop** — opens suggested content for that point in the day.
  - **Add New Stop** — dismisses the chooser and opens the existing `AddGameNodeView` at the exact same path-stop coordinate.
- Non-path empty cards keep their existing direct Add Stop behavior.
- Existing cards with stop content keep their existing reveal/details behavior.
- Focused alternate-path preview mode still suppresses semantic map taps as designed in Pass 5.4, so this chooser does not bypass the preview interaction lock.

Suggested-content seam:

- Added a lightweight local `SuggestedPathStopContent` model in `DayMapView.swift` with meal/activity/post/hyperlink/media categories.
- A deterministic time-of-day fallback provides demo suggestion content until the backend supplies real suggestions.
- The UI flow is backend-ready: the local provider can later be replaced without changing the empty-stop interaction or Add Stop flow.

Application-layer tracing:

- Added `pathStopOptionsOpened` and `suggestedStopViewed` application actions to `SocketManager` so the new interaction still passes through the centralized action gateway.

## Pass 5.10 — Direct Suggested-Stop Review (No Chooser Sheet)

Pass 5.10 supersedes the Pass 5.9 two-option chooser.

Behavior now:

- Tapping an empty card that belongs to a path checks whether the application has supplied real stop content for that exact `GridCellID`.
- If suggestion content exists, the map opens that actual stop content directly in `SuggestedPathStopReviewView`.
- The review exposes exactly three user actions:
  - **Accept** — validates/normalizes the suggested `GameMapNode`, adds it through `SocketManager.addGameNode`, removes the pending suggestion for the card, and closes the sheet.
  - **Reject** — removes the suggestion and closes the sheet. A later tap on that now-unsuggested empty card goes through the normal Add Stop flow.
  - **Edit** — switches the sheet into the existing `GameNodeEditorForm` using the real suggested node as the editable draft. Saving returns to review; the user can then Accept the edited stop.
- If the app has not supplied a suggestion for the tapped empty path card, there is no intermediate sheet at all. The existing `AddGameNodeView` opens immediately, exactly like other empty cards.
- Removed the time-of-day `localFallback` suggestion generator; the UI never invents suggestion content merely because the card is on a path.
- Added `SuggestedPathStop`, which stores real `GameNodeContent` and can materialize a normal `GameMapNode` at the tapped path coordinate.
- Added app/backend hooks on `SocketManager`:
  - `provideSuggestedPathStop(_:for:)`
  - `clearSuggestedPathStop(for:)`
- Added application-action tracing for suggested-stop view, edit, accept, and reject actions.
- Focused alternate-path preview interaction locking remains unchanged: semantic stop taps are suppressed while preview mode is active, but pan and zoom continue to work.

Example app-side provisioning:

```swift
SocketManager.shared.provideSuggestedPathStop(
    .activity(
        ActivityNodeContent(
            activityID: UUID().uuidString,
            title: "Lunch Walk",
            startTime: "12:30 PM",
            description: "Take a short walk after lunch.",
            activityType: ActivityNodeContent.ActivityType.task.rawValue,
            status: "Suggested",
            task: nil,
            image: nil
        )
    ),
    for: targetCellID
)
```

The exact backend/socket payload for delivering suggestions is still intentionally deferred; the presentation and domain hooks are now ready for it.


## Pass 5.11 — User Stop Reveal Policy + Larger Progress Badge

- Off-path stops whose content kind is `.user` are now always rendered revealed.
- Completed, chosen, alternate, and preview path cards continue to reveal automatically as before.
- Every other off-path stop kind remains hidden until the current user explicitly reveals its card.
- A mixed/stacked card containing at least one User stop is revealed because the card stack represents that shared time/progress point.
- Increased `UserCircularProgressBar` percentage text from 14 pt to 28 pt.
- Increased the progress ring line width from 6 to 7 points and expanded the control to 82×82 points with internal ring padding so the larger percentage remains legible without crowding the segments.
- Separated the date control and progress control into independent material surfaces in `AppOverLayTopRow`; the progress badge now has its own circular material background instead of sharing one large rounded rectangle with the date title.

## Pass 5.12 — Progress Header Rollback + Contrast Refinement

- Restored `UserCircularProgressBar` to its pre-Pass-5.11 sizing:
  - percentage font: `14pt`
  - segmented ring width: `6pt`
  - overall control: `50×50`
- Restored `AppOverLayTopRow` to the previous shared rounded material background containing both the date control and progress control.
- Removed the separate circular material background introduced in Pass 5.11.
- To keep the smaller progress percentage from being visually overwhelmed by the shared translucent background, added a compact dark center disc inside the segmented ring and kept the percentage text bright green with a stronger shadow.
- No changes were made to the Pass 5.11 off-path stop reveal policy.

## Pass 5.13 — Active Path Dominance + Direction Arrows

This pass makes the user's active path read more clearly than unrelated stops/cards.

- Added `DayMapTileSnapshot.isEmphasizedPathCard` as presentation-only state.
- Normal map mode emphasizes **Completed + Chosen** path cards.
- Alternate preview mode emphasizes **Completed + the single focused Alternate** path cards. Unfocused alternate stops remain normal-sized.
- Active path cards render at **1.12×** the ordinary card scale (12% larger). This applies to both content stops and empty transit/stop cards on the active path so the entire chain has a consistent visual hierarchy.
- The emphasis scale is integrated with the existing card-flip animation so reveal flips still collapse/expand correctly at the larger size.
- `DayMapTileRouteConnection` now preserves route traversal direction (`fromCellID` → `toCellID`) in addition to its canonical edge pair used for de-duplication.
- Added a small triangular direction arrow in each visible Completed/Chosen/focused-Alternate connector gutter. The arrow tip points toward the next card in traversal order.
- Direction arrows are intentionally not added to route-builder preview/alternative-preview connectors, so planning UI does not compete with the committed/selected path.
- Existing connector colors are reused for the arrows; a subtle white edge keeps the arrowhead readable on dark backgrounds.
- Legacy hidden road geometry/pathfinding remains unchanged.

## Pass 5.14 — Broad Active-Path Background Band

Replaces the Pass 5.13 card-size and arrow emphasis with one continuous path treatment.

- Removed the 12% active-path card enlargement. All stop cards are once again rendered at the same physical size.
- Removed the directional arrowheads that were added to sequential path connectors in Pass 5.13.
- Added a broad, low-opacity green background band underneath the active user path.
- The band uses the same width as a stop card (`tileSize`) and a 12% alpha version of the completed-path green, with rounded caps/joins so turns read as one continuous corridor.
- In normal mode, the band follows Completed + Chosen path connections.
- In focused alternate preview mode, the band follows Completed + the selected Alternate path connections; unrelated/unfocused alternates do not receive the band because their connector chains are not emitted until focused.
- Existing path-state card borders and thin connector bridges remain intact above the background band.
- Preview-builder-only connection styles do not receive this user-path background treatment.

## Pass 5.15 — Remove Committed-Path Join Lines + Stronger Green Band

Refines the broad active-path treatment introduced in Pass 5.14.

- Removed the old narrow join/bridge line from committed user-path states:
  - Completed
  - Chosen
  - focused/selected Alternative
- The broad green background band is now the only connector treatment for those active path states.
- Increased the active-path green band opacity from `0.12` to `0.36` (3× stronger), while keeping its width equal to `tileSize` and preserving rounded caps/joins.
- Route-builder preview connectors are intentionally preserved so planning interactions still have a visible connection affordance; this change targets the committed/selected user-path join line only.
- Stop-card sizes, path-state borders, reveal behavior, alternate preview behavior, and backend/pathfinding logic are unchanged.

## Pass 5.16 — Remove Broad Path Band, Add Direction Arrow Asset

Replaced the committed-path green background band with a directional arrow image placed in the gutter between sequential path stops.

Implementation details:

- Added `path_direction_arrow.imageset` to `Resources/Assets.xcassets`.
- The arrow asset is derived from the user-provided green arrow image with the black background made transparent.
- `DayMapTileRouteConnection` now preserves traversal order with `fromCellID` and `toCellID` in addition to the canonicalized cell pair used for de-duplication.
- `MapGridRenderer.renderRouteConnectors()` no longer draws the broad translucent green path band for committed path states.
- Instead, it renders a `SKSpriteNode` arrow at the midpoint between sequential path stops for these styles:
  - `.completed`
  - `.chosen`
  - `.alternative` (focused selected alternate path)
- The arrow is rotated so its tip points toward the next stop in actual path traversal order.
- Thin preview connectors are still retained for route/path-builder preview states only.

## Pass 5.17 — Borderless Active Path Cards

Visual experiment requested for Completed / Chosen / selected Alternate path stops.

Changes:

- Removed the normal outer face border from committed path cards in `.completed`, `.chosen`, and `.alternative` state.
- Removed the route-specific solid/striped perimeter from those same committed path states.
- Removed stack-back edge strokes for stacked committed-path cards so a stacked path stop does not reintroduce a visible perimeter behind the front card.
- Suppressed the ordinary selection border on those committed-path cards as part of the borderless visual test.
- Kept temporary route/path-builder preview borders unchanged.
- Kept the Pass 5.16 directional arrow asset and arrow rendering unchanged.
- Existing low-opacity state tints, route-only Pied Piper artwork, stop content, reveal policy, and interactions remain unchanged.

Validation: all 154 Swift files parse successfully with `swiftc -frontend -parse`.

## Pass 5.18 — Universal Card Reveal + Empty Stop Face

Updated card interaction so every concealed card uses the same first-tap discovery behavior.

### Interaction

- First tap on any hidden card only reveals/flips the card.
- Hidden cards with GameNode/stop content reveal their existing content face.
- Hidden empty cards reveal a new empty-stop face instead of opening Add Stop immediately.
- On a revealed empty card, only the `Add Stop` label at the bottom is an active semantic tap target.
- Tapping `Add Stop` opens the existing `AddGameNodeView` at the exact semantic center of that card.
- Existing active-path direction arrows from Pass 5.17 remain unchanged.

### Empty stop face hierarchy

Top to bottom:

1. Time of day.
2. Neutral/original Pied Piper silhouette.
3. Potential progress gain/loss.
4. `Add Stop` label.

The potential progress change is computed as:

`card horizontal progress percentage - current user progress percentage`

and is shown as a signed value such as `+12.5%`, `−6%`, or `0%`.

### Rendering/state changes

- `DayMapTileSnapshot` now carries `potentialProgressDeltaPercent`.
- Explicitly revealed empty cells are included in `DayMapTileResolver` output so a truly empty card can persist in its revealed state.
- `VirtualMapScene` tracks the current progress percentage and refreshes tile presentation when it changes.
- `MapGridRenderer` has a dedicated revealed empty-card face and an Add Stop hit region.
- `SocketManager.handleDayTileReveal` now accepts an optional GameNode ID so empty-card reveals are logged through the same application-action gateway.

## Pass 5.19 — Playable Meal Fulfillment Paths

The Activity → Meal type sheet now opens with a situation-aware playable meal path before the ordinary Suggested Meal editor fields.

### User flow

Every path begins with the scheduled meal and ends with `Eat <Meal>`.

The user first chooses the sourcing situation:

- Home-made
- Restaurant
- Store-bought
- Friend's place

The path rebuilds immediately when a relevant situation changes. The player completes only the current stop; completed stops turn green and the next stop becomes active.

### Example: Home-made cheeseburger

`View Cheeseburger → Make it at home → Check ingredients → Grocery Store → Buy ingredients → Return home → Choose recipe → Prep ingredients → Cook step-by-step → Plate the meal → Eat Cheeseburger`

If ingredients are already available, the grocery-store branch is removed. If a recipe is already selected, the recipe-selection stop is removed.

### Example: Restaurant cheeseburger

Takeout:

`View Cheeseburger → Get it from a restaurant → Burger King → Place takeout order → Go to Burger King → Pick up the meal → Take it home → Eat Cheeseburger`

Dine-in and delivery create different paths. If the selected restaurant is unavailable, the path inserts a restaurant-recovery branch before ordering.

### Store-bought

Supports in-store shopping, pickup, and delivery. Out-of-stock adds an alternate-store branch. Heating/preparation adds a preparation stop before the final meal.

### Friend's place

Supports confirmed/unconfirmed plans, optionally bringing something, and whether the meal is already ready. If the meal is not ready, the path adds help-preparation and serving stops.

### Implementation

Added:

- `Game/Domain/Nodes/MealPlayablePathView.swift`
  - `MealPathSource`
  - `MealRestaurantMode`
  - `MealStoreMode`
  - `MealPathSituation`
  - `MealPathStop`
  - `MealPathBuilder`
  - `MealPlayablePathView`
  - `MealPathMapView`
  - `MealPathStopCard`

Updated:

- `Game/Domain/Nodes/ActivityTypeEditorView.swift`
  - Meal type now presents the playable path at the top of the sheet.
  - The scheduled Activity start time is passed into the path planner.

The mini-map is self-contained UI state for this pass. It does not yet mutate the authoritative day-map `GameRoute` / `DayRouteState`; that integration can be added later after the meal-flow UX is settled.

## Pass 5.20 — MapGridRenderer private nested-type access-control fix

Fixed Swift compiler access-control errors caused by helper methods exposing the private nested `RenderedCell` type through method signatures.

The following `MapGridRenderer` helpers are now explicitly `private`:

- `makeRenderedCell()`
- `configure(_:for:)`
- `apply(_:previousSnapshot:to:animated:)`
- `applyVisuals(_:previousSnapshot:to:)`
- `applyRouteStyle(_:to:)`
- `applyStripedRouteBorder(to:primary:secondary:cacheKey:alpha:borderWidth:)`
- `applyArtwork(_:previousNode:to:)`
- `cancelArtworkTask(for:)`

No rendering behavior or UI semantics were changed in this pass.
