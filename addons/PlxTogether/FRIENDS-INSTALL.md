# One download: PlxTogether + Questie

Download the **PlxTogether-Friends.zip** release asset. GitHub's **Source code (zip)** is a developer checkout and does not contain Questie or a ready-to-run complete installer. If you downloaded source, run Build-Friends-Bundle.ps1 from addons/PlxTogether using a network-enabled terminal, then extract the generated dist/PlxTogether-Friends.zip.

1. Close WoW and extract the entire PlxTogether-Friends.zip.
2. On Windows, run **PlxTogether-Setup.exe** and approve the administrator prompt. Choose the Forever client folder containing the WoW executable (WowB.exe on the current beta), then click Install addons. The default is the standard _classic_beta_ location. The executable must remain beside the Support and AddOns folders. Only PlxTogether-Setup.exe needs to be opened.
3. Launch Forever. Enable PlxTogether, Questie and QuestieDB in the character-selection AddOns list, along with any bundled dependency folders.
4. Type `/plx demo` to try a simulated Horde party solo. Close Details to see the small on-screen tracker. Next step advances the preview; `/plx live` returns to your character.
5. For live play, all Horde party members install this package, form a normal party, and meet in the same zone.

Manual installation (Windows or macOS): copy every folder inside this package's AddOns directory into your Forever client's Interface/AddOns directory. The PlxTogether, Questie and QuestieDB folders must sit beside each other. Do not put the entire package inside AddOns. Existing folders are backed up by the Windows installer before it copies updates; the installer does not modify your saved quest settings.

`/plx` opens Details. `/plx hud show` restores the tracker. Drag the tracker to move it. `/plx guide` opens the guide. `/plx status` explains missing party data.

The preview works without Questie. Live routing uses Questie's quest database. Locations are approximate; routes do not account for terrain. Forever beta XP rules and UI behavior still need in-game verification. AI integration is not included.

Questie is an independent upstream project. ThirdParty contains notices, its license, and matching source archives.
