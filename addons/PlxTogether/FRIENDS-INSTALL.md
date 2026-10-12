# One download: PlxTogether + Questie

1. Close WoW and extract the entire PlxTogether-Friends.zip.
2. On Windows, run Install-Friends.cmd. Enter the Forever client folder containing the WoW executable (WowB.exe on the current beta), or press Enter for the standard _classic_beta_ location. If Windows denies access, right-click the CMD file and Run as administrator.
3. Launch Forever. Enable PlxTogether, Questie and QuestieDB in the character-selection AddOns list, along with any bundled dependency folders.
4. Type `/plx demo` to try a simulated Horde party solo. Close Details to see the small on-screen tracker. Next step advances the preview; `/plx live` returns to your character.
5. For live play, all Horde party members install this package, form a normal party, and meet in the same zone.

Manual installation (Windows or macOS): copy every folder inside this package's AddOns directory into your Forever client's Interface/AddOns directory. The PlxTogether, Questie and QuestieDB folders must sit beside each other. Do not put the entire package inside AddOns. Existing folders are backed up by the Windows installer before it copies updates; the installer does not modify your saved quest settings.

`/plx` opens Details. `/plx hud show` restores the tracker. Drag the tracker to move it. `/plx guide` opens the guide. `/plx status` explains missing party data.

The preview works without Questie. Live routing uses Questie's quest database. Locations are approximate; routes do not account for terrain. Forever beta XP rules and UI behavior still need in-game verification. AI integration is not included.

Questie is an independent upstream project. ThirdParty contains notices, its license, and matching source archives.
