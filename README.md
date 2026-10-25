# Who's the Killer?

An original Roblox social mystery game. The digging game is preserved on `game/dig-to-the-center`; this game lives on `game/midnight-mystery`.

## Play and sync on Windows

Switch GitHub Desktop to `game/midnight-mystery` and pull. Start `rojo serve` from this checkout, open a **new place** in Studio, connect the Rojo plugin, and accept sync. Use a separate published Roblox experience for this game to keep your digging place intact.

Use Studio's **Test → Server & Clients** with **at least 3 players** to test a full round. Solo Play supports the lobby and shop, but waits for more players before starting rounds.

## Rules

- A 20-second vote selects one of three original blockout maps: Moonlit Manor, Research Lab, Cargo Depot. Highest votes wins; ties choose randomly.
- One random murderer gets a knife, one random sheriff gets a gun, and everyone else is innocent. Rounds last five minutes.
- Equip your weapon using the Roblox backpack, then click/tap to attack. The on-screen ATTACK / SHOOT button equips the weapon and aims at the center crosshair.
- Murderer wins by eliminating everyone; innocents win when the murderer dies or time expires. A sheriff who shoots an innocent is eliminated; the innocent survives.
- The sheriff's gun drops on death. Only a nearby, living innocent can claim it using the prompt. The murderer cannot pick it up.
- Lobby players and eliminated players can use SPECTATE to cycle through surviving players. Roles are sent only to the player who owns them.
- Surviving players receive 100 coins at round end. Starting balance is 500 coins. Collect gold coins around the map perimeter for 10 coins each, with a 30-coin bag per round (300 currency). Coins respawn after 12 seconds and collected currency is retained after elimination. Collection is server-validated for active players, distance, and bag capacity.

## Shop and inventory

Six knife boxes and four gun boxes each have five cosmetic tiers. Cases cost 250 coins or 25 gems. Actual odds: gray common 65%, blue uncommon 23%, green rare 10%, red legendary 1.9%, pink unique 0.1%. The shop has category tabs, case cards, 3D reward previews, explicit coin/gem buttons, and a result reveal. Odds are displayed before opening; duplicates are retained. Weapons are original recolored prototype models and do not grant combat advantages. Skins apply the next time a weapon is issued.

Emotes, cosmetic backpack radios, and geometric companion pets are purchasable with earned coins. Emotes use avatar-supported animation names. Radios are visual accessories; music playback and custom audio are not included. Pets are welded cosmetic companions, not pathfinding NPCs. Maps and items use generated Roblox parts, with no third-party game assets.

## Persistence and paid gems

Publish a separate Roblox experience. For Studio persistence tests, enable **Game Settings → Security → Enable Studio Access to API Services** using a test experience (not production data). If saving cannot be loaded or a profile is locked in another server, the player gets explicitly labeled session-only progress and cannot buy gems. Profiles autosave every 60 seconds and at departure/shutdown. A session lock prevents simultaneous servers from overwriting a player's profile.

To enable gem sales, create developer products in Creator Dashboard for **this experience** and configure `Products` in `src/shared/MysteryConfig.luau`, for example `[YOUR_REAL_PRODUCT_ID] = 100`. Use actual IDs, not the placeholder. Roblox checkout displays prices. The server validates configured products and records each receipt atomically before acknowledging it; receipt retries do not award twice. Do not replace `ProcessReceipt` with a separate handler.

Gem-case eligibility is checked using Roblox PolicyService. Paid random items are denied if the policy call fails or the account is restricted. Coin cases use only earned currency; coins cannot be purchased. No trading or item cash-out exists. Verify developer products and policy behavior in a published test experience before enabling real sales.

## Validation

- `rojo build -o /tmp/whos-the-killer.rbxlx` (choose a suitable output path on Windows).
- `luau tests/rules.luau`: round outcomes, map majority/ties, disconnected voters, and gun pickup authorization.
- Compile the Luau scripts with `luau-compile` for syntax validation.

Required Studio multiplayer checks before release:

1. Join three clients, vote different maps, and confirm the selected map and one murderer/one sheriff.
2. Check attacks cannot damage lobby players or hit through walls; check knife reach and gun cooldown.
3. Kill the sheriff, pick up the gun as an innocent, and attempt pickup as the murderer.
4. Verify murderer death, innocent survival at timeout, murderer eliminating everyone, disconnects, reset, and a second complete round.
5. Spectate after death and verify the camera returns to your character on respawn.
6. Open boxes with both currencies where permitted, equip owned items, and confirm inventory survives rejoining with data services enabled.
7. Test configured gem receipts and retries in Roblox's test purchase flow; check restricted-account behavior.

Cloud checks cannot establish multiplayer behavior, animation compatibility, live purchases, or live DataStore persistence. This is a playable prototype, not a production release.
