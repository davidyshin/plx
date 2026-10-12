# PlxTogether quick start

Open the addon with `/plx`. Click **Guide** for these instructions inside WoW,
or type `/plx guide`.

## Try it alone

1. Type `/plx demo`.
2. Follow the gold **NEXT** card. Its number matches the route overview.
3. Click **Next step** to simulate a pickup, objective, or turn-in.
4. Watch the party route change. **For** tells you who needs each task.
5. **Reset demo** starts over. **Exit demo** returns to live play.

The demo works without Questie or a party. It uses fictional quests and rewards,
does not alter your character, and sends no party messages.

## Use it with friends

Every member needs PlxTogether and a Forever-compatible Questie. Play Horde,
form a normal party, and meet in the same zone. Open `/plx` and wait for everyone
to show **Ready**. Follow the gold stop and complete quests normally. Open
**World map** for numbered markers. Nearby tasks share one number.

The route updates with party progress. **Refresh route** reorders it from your
current position. The schematic overview shows stop order rather than roads.
**Why these quests?** explains per-member XP estimates and level penalties.
Estimates still need verification against Forever's actual beta quest rewards.

## Troubleshooting

- No live data: confirm Questie is installed and has finished loading.
- Waiting for a friend: confirm their addon version, zone, and party connection.
- No shared quests: some may be locked, already completed, or missing XP data.
- No marker: a quest may lack coordinates or require another zone.
- After updating: restart WoW if the addon is newly installed; otherwise `/reload`.
- `/plx status` prints party readiness. `/plx list` prints recommendations.

Use `/plx live` to exit the demo. Escape closes the window.

## On-screen route tracker (0.5.0)

The small PlxTogether tracker stays visible while the large Details window is closed. Drag it to move it. It shows your current stop, map coordinates, who needs the tasks, and the next two stops. Details opens the full route; Map opens the live zone map.

Use `/plx hud` to toggle the tracker, `/plx hud show` to restore it, and `/plx hud hide` to hide it. Its position and visibility are saved. Escape closes Details without closing the tracker.

To preview solo, run `/plx demo`, close Details, and use **Next step** on the tracker. The preview uses fictional quests and sends no party messages. Use `/plx live` to return to your character. Live progress comes from quest updates; Refresh does not mark a quest complete.

The route uses approximate map locations, not terrain-aware navigation. Forever beta XP rules and the new tracker still need verification in the game client.

## Version 0.5.0

- The direction arrow points to the next stop, updates as you turn, and shows approximate yards. It is direct compass guidance, not terrain-aware navigation. At the stop does not complete a quest.
- Route stops contain separate action-labelled substeps (1.1, 1.2), dividers, and Needed by lists. Click a live map pin to open that stop's instructions.
- SOLO MODE is your real character. PARTY MODE is your real party. DEMO · SIMULATED is the fictional test, with an Exit demo button on the tracker. /plx live leaves the demo.
- The complete friends ZIP includes PlxTogether-Setup.exe, a Windows installer with the Paddington logo and game-folder selection. Extract the entire ZIP before launching it; keep the executable beside Install-Friends.ps1 and AddOns. The source checkout is not an installable friends package.
- Website previews are interactive illustrations using sample data, not screenshots of a running game.
