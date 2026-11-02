## How do I group spidertrons together?

Give them the same name. That is the whole mechanic.

A group (squad) is every spidertron on the same surface that shares the same label:
the custom name you typed in the spidertron's GUI, or the prototype name if it was never renamed.

1. Open a spidertron.
2. Click its name field and type a label, e.g. `Haulers`.
3. Repeat for every spidertron you want in that squad.

**Notes:**
- Different names = different squads. No tags, no extra setup.
- Grouping is per surface. `Haulers` on Nauvis and `Haulers` on Gleba are two independent squads and live in two separate tabs of the manager window.
- The row in the manager shows the squad color, its size and its name; the color is taken from the squad leader, so rename/recolor the leader to change the visual identity of the group.
- Commands issued from a row affect all spidertrons of that squad on that surface.

## How do I remove a single spidertron from a group?

Simply rename it. Open the spidertron's GUI and change its name to something unique.

Since the mod dynamically forms groups based entirely on matching names, giving it a different name instantly removes it from the current squad and creates a new one.

## How do I find the squad leader?

There is no such thing as a "real" leader — the concept is purely internal.

The mod picks the leader automatically as the first spidertron with a unique name it finds on the surface when building the squad list. There is no way to promote or demote a leader manually, and the choice is effectively arbitrary from the player's point of view.

So don't look for it. The Settings (gear) button on the group's row exists exactly for this reason: when you click it, the mod opens the settings GUI of the current leader for you. Any change you make there is then broadcast to the whole squad.

## How do I set a "home" location for a group?

1. Open the manager (`U` by default, or the toolbar icon).
2. Ctrl + click the Go to home button on the group's row.
3. Your cursor must be empty — the mod puts a hidden selection tool into it and closes the window.
4. On the map:
   - Click a tile → home is a single point.
   - Drag an area → home is an area; returning spidertrons are spread across it instead of stacking on one tile.

Done. From now on a plain click on Go to home recalls the whole squad there.

**Notes:**
- Homes are stored per group and per surface.
- To cancel, drop the selection tool from your cursor (`Q`); the manager window comes back.
- Repeat Ctrl + click at any time to overwrite the home point/area.

## How do I watch my spidertrons remotely?

Use the live camera view:

1. Open the manager.
2. Hold **Shift** and click the **View** button on the group's row.
3. A camera window opens and dynamically follows the selected group.

The camera tracks the whole squad in real time, so you can keep an eye on a distant hauler convoy, a patrol, or a marching column while you continue working elsewhere. Close the window with the close button when you no longer need it.

## How do I use pathfinding?

Hold Shift while clicking a movement button — Follow me, Go to location or Go to home.

Shift always requests the alternate movement method relative to your default:
- default = Pathfinding → Shift + click = Straight line
- default = Straight line → Shift + click = Pathfinding

Pathfinding asks the game's pathfinder for a route that avoids obstacles and can cross water and lava, exactly like a manually driven spidertron. The request is asynchronous, so the squad may start moving a moment later than with a direct order. Use it across rivers, lava lakes and dense construction; use the straight line for short, clean hops.

## How do I make pathfinding the default?

Settings → Mod settings → Per player → Spidertron Manager → default movement mode.

Allowed values: `pathfinder` (Pathfinding) and `direct` (Straight line).
Factory default: `pathfinder`.

It is a per-player runtime setting: every player picks their own, it can be changed mid-game and takes effect on the next click. No restart needed.

Shift + click keeps working as the one-off override in both directions.

## Why does a spidertron sometimes go straight even though I asked for pathfinding?

Because the pathfinder did not answer in time.

Path requests are handled by the game asynchronously. When the pathfinder is busy (CPU load, many concurrent requests, long distances), it returns a "try again later" response instead of a waypoint list. Automatic re-request is not implemented yet, so in that case the mod falls back to sending the spidertron directly to the destination.

Workarounds for now:
- Issue the order again a second later.
- Split a huge fleet into smaller squads so fewer requests are queued at once.

Retry logic is planned for a future version.

## Why is the equipment grid sometimes not copied?

Short answer: I don't know yet.

Long answer: the API has no simple "clone this equipment grid" call (or I have not found one). `LuaEquipmentGrid.put()` places equipment into a grid, but it does not consume items by itself — every approach I tried ended up being cheaty, because the equipment appeared out of nowhere.

A "fair" implementation is possible (take the actual items from the source grid / an inventory and move them), but it is not trivial: quality, item counts, unavailable space and partially filled grids all have to be handled.

If you know a clean way to do this, tell me — I will gladly say "thank you" :)

## How do I make the window smaller?

I agree, the window is currently quite large. I have ideas for a more compact layout and I am still evaluating them.

For now:
- Use short squad names. The name column defines most of the window width.
- Rich-text icons work well as names, e.g. `[entity=spidertron]` or `[item=spidertron-remote]` instead of a long label — I use pictograms myself for most squads.
- The window can be dragged by its title bar; the position is remembered between openings.
- Every window now has a dedicated close button in the corner, so you don't have to click the toolbar shortcut again.
