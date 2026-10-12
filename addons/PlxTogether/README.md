# PlxTogether 0.4.0

Horde party quest planner prototype for WoW Forever beta. Requires a current
Forever-compatible Questie on every member's client. Not yet tested inside WoW.

## Why Questie?

Questie supplies quest locations, prerequisites, local eligibility checks, zone
mapping, and XP estimates. The quest log alone does not supply a complete world
quest database. PlxTogether reads the installed database without redistributing it.
The adapter is isolated in `Provider.lua`: the planner and party protocol are separate,
so an independent database provider can replace Questie later.

## Install and commands

On this PC, right-click `Install-PlxTogether.cmd` and choose **Run as administrator**.
The installer targets the Forever beta, backs up an existing PlxTogether folder, and
verifies every copied file. The agent's direct install attempt was denied access to
the Program Files destination.

For help in WoW, click **Guide** or type `/plx guide`. See `GUIDE.md` for a standalone
quick start.


Extract `PlxTogether-0.4.0.zip` into `_classic_beta_/Interface/AddOns/`, alongside
Questie. The result must be `AddOns/PlxTogether/PlxTogether.toc`. Reload the UI.
Install this version on every member's client. The manifest targets interface 16001.

- `/plx guide`: open the in-game usage guide.
- `/plx demo`: preview three simulated Horde players, no party or Questie needed.
- `/plx demo next`: complete the highlighted simulated stop and replan.
- `/plx demo reset`: restart the demo; the Refresh button also resets it.
- `/plx live`: exit demo and resume live scanning.
- `/plx`: toggle the draggable route window; Escape closes it.
- `/plx refresh`: refresh local data and print shared recommendations.
- `/plx list`: print recommendations and route stops.
- `/plx status`: show readiness, missing data, stale peers, and zone differences.
- `/plx map`: open the current map with numbered route markers.

Use a normal Horde party in the same zone. Missing or stale member data blocks shared
routes. Solo planning also works. Snapshots use the private party addon channel.
All party members must use PlxTogether 0.3. Remove the old HordeTogether addon folder
before installing, so both addons do not load together.

## Solo test mode

Run `/plx demo`, or open `/plx` and click **Try solo demo**. The gold card is your
next stop. **Next step** advances simulated pickups, objectives, and turn-ins. The
route overview uses the same numbers as the cards. **Reset demo** starts over;
**Exit demo** returns to your real character's data.

The sample party is level 12, 15, and 17. One member is already ahead on a quest;
an old quest gives reduced XP. All quest names, rewards, and locations in this mode
are demonstration data. Demo mode sends no party snapshots, places no fake markers
on the world map, and does not change your quests. It stays available without Questie,
including when live data fails to load. Demo state is not saved across reloads.

## Interface

The window has a scrollable task list, a gold next-stop card, a compact party summary,
and a schematic route overview. Tasks name who needs them. Nearby tasks share one
numbered stop. Extra notes explain missing or off-zone locations. A separate section
explains quest choices and per-member XP. The draggable header saves the window's
position, and the window scales down on smaller displays. Escape closes it.

## Routing

Each member reports their own eligibility, quest status, XP estimate, and objective
completion flags. Partial, malformed, duplicate, and expired snapshots are discarded.
Peers expire after 90 seconds. Frequent updates queue the latest snapshot without
interrupting one in flight.

Quest score is 75% weakest-member benefit and 25% average benefit. Benefit is quest
XP divided by that member's current level's XP requirement. Unknown/zero XP or a
quest unavailable to anyone excludes that quest. This favors shared progress; it
does not claim optimal XP per minute.

For the top eight quests, the next phase determines the route: pickup if anyone
needs it, unfinished objectives if anyone needs them, or turn-in when all are ready.
An objective disappears when all active members confirm it is finished. Unknown
progress keeps it. Routes choose nearby spawn alternatives and order up to 24 stops
in the current zone. Route order stays stable until quest state changes or you explicitly
refresh from your new position. Completion flags suppress stops only when objective
mappings match across clients; a mismatch conservatively keeps the objective.

## XP estimates

Questie's XP module supplies rewards and supported buff adjustments. Its level-only
estimate is full XP through five levels above the quest, then 80%, 60%, 40%, 20%, and
a 10% floor at ten or more levels above. Displayed retention excludes aura bonuses.
These are Questie estimates, not verified Forever server rules. Unknown beta rewards
stay unknown. Mob XP is separate and is not modeled.

## Limitations

- No terrain/road/flight travel model, route lines, cross-zone planning, future
  prerequisite-chain planning, XP lock detection, or AI companion yet.
- Uses the first 300 quest IDs assigned to the current zone by Questie. Unknown beta
  quests, quests without zone assignments, and off-zone locations may be absent.
- Objective markers use available Questie spawn data with NPC/object/item-drop
  fallbacks. Unsupported objectives may lack markers. At most 12 spawn alternatives
  and 32 completion flags per quest are considered. Detected sequenced beta quests are left to the quest log instead of guessing their
  next-stage locations. Different database versions especially need in-game validation.
- Only objective completion flags are transmitted, not individual kill/item counters.
  Unknown flags never count as complete, including unfinished Forever 1/1 objectives.
- Questie internal modules can change. Adapter errors appear in the route window.
  Planning scans defer during combat.

## Validation

Manifest checks, native Lua syntax checks, and seven fixture suites passed: planner
fairness/eligibility, objective routing, message protocol, Questie provider, core
party synchronization, solo demo lifecycle, and window/demo interactions. These fixtures do not simulate the full WoW runtime.

The environment blocks npm registry access. Tests ran using an existing local Lua
shared runtime. For development, `npm install` then `npm test` checks Lua 5.1 syntax
and runs fixtures through Fengari. Alternatively use
`python tests/native-runner.py <Lua-5.3-or-5.4-library-path>`. Development dependencies
are not included in the addon and are not required by players.

Before release, test two beta clients at different levels, prerequisites and racial
restrictions, completed quests, unknown quests, partial progress, party joins/leaves,
zone changes, disconnects, and map zoom. Compare estimates against actual quest XP
with controlled buffs around the falloff boundaries.

## References

- [Questie releases](https://github.com/Questie/Questie/releases)
- [Questie database](https://github.com/Questie/Questie/blob/master/Database/QuestieDB.lua)
- [Questie XP estimates](https://github.com/Questie/Questie/blob/master/Database/QuestXP/QuestieXP.lua)
- [Questie quest cache](https://github.com/Questie/Questie/blob/master/Modules/Quest/QuestLogCache.lua)

Next milestone: validate the beta adapter and visual layout inside WoW, including
map zoom and a real two-player party, then compare actual XP. Automated fixture
checks cannot guarantee that a beta client has no bugs.
An independent database and optional local-model/Gemini companion can follow.
