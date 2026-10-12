# Install PlxTogether for WoW Forever

You need **PlxTogether-0.5.0.zip**. Your friend should send you that ZIP along with this guide.

## 1. Find your Forever game folder

In Battle.net, select **WoW Forever beta**, open the gear menu beside Play, and choose
**Show in Explorer**. Find the `_classic_beta_` folder belonging to that installation.
The launcher's wording may differ; make sure you are opening the Forever client you
actually play, rather than Retail or another Classic installation.

The addon goes inside:

```text
World of Warcraft
└── _classic_beta_
    └── Interface
        └── AddOns
```

If `Interface` or `AddOns` is missing, create those folders. These instructions target
the Forever beta; the live release may use a different client folder.

## 2. Extract the addon

Close WoW. Extract **PlxTogether-0.5.0.zip**, then copy the extracted **PlxTogether**
folder into `Interface/AddOns`.

The final layout must look like this:

```text
AddOns
└── PlxTogether
    ├── PlxTogether.toc
    ├── Core.lua
    ├── Demo.lua
    └── ...
```

Open the PlxTogether folder to check that **PlxTogether.toc is directly inside it**.
Avoid an extra nested folder such as `AddOns/PlxTogether/PlxTogether/PlxTogether.toc`.
Copying the ZIP itself into AddOns will not install it.

If you previously installed the addon under its old name, **HordeTogether**, remove
that old addon folder or disable it in the AddOns menu. For an update, replace the
existing PlxTogether folder with the new extracted folder while WoW is closed.

## 3. Install Questie for live questing

Install a **Forever-compatible version of Questie** and its required dependencies,
following Questie's installation instructions. Place its addon folders alongside
PlxTogether inside the same client's `Interface/AddOns` folder.

[Questie downloads and release notes](https://github.com/Questie/Questie/releases)

Questie supplies the quest database for live routes. You can try PlxTogether's solo
demo without Questie. Everyone in the party needs both addons for live shared routes.

## 4. Enable and test

1. Start the Forever beta and open **AddOns** at character selection.
2. Confirm **PlxTogether** and **Questie** are enabled.
3. Log in and type **`/plx demo`**.
4. The PlxTogether window should open with a simulated three-person party.
5. Click **Next step** to preview the route. Click **Exit demo** or type **`/plx live`**
   when you are ready to use your real character.

PlxTogether 0.5.0 targets interface **16001**. A later beta build may mark it out of
date. Check for an updated addon first; enabling out-of-date addons does not guarantee
compatibility with a changed client.

## 5. Quest together

Everyone should install the same PlxTogether version. Form a normal **Horde party**,
meet in the **same zone**, and type **`/plx`**. Wait for everyone to show **Ready**.
Follow the gold next-stop card. The **For** line tells you who needs each task.

Useful commands:

- `/plx guide` — usage guide inside the game.
- `/plx status` — check party readiness.
- `/plx refresh` — refresh the route.
- `/plx map` — open the map with numbered live route stops.

## If it does not work

**PlxTogether is missing from AddOns:** check the client folder and the location of
`PlxTogether.toc`, then restart WoW completely.

**The demo works but live data does not:** check that a Forever-compatible Questie
and its dependencies are enabled and have finished loading.

**Waiting for a friend:** check their addon version, zone, and party connection.
Everyone needs both addons. Raid groups are not supported.

**No shared route:** some quests may be locked, already completed, missing XP data,
or outside the current zone. Read the route notes and check `/plx status`.

**An error after a beta patch:** update the addon and Questie. If it continues, send
the error text, PlxTogether version, and game build to the person testing the addon.

This is a beta addon. Quest XP estimates and live map behavior still need in-game
validation.

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
