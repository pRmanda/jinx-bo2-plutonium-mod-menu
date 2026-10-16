# JINX MOD MENU — Plutonium T6 Multiplayer

**By Jinx | v0.6.20 | Private matches and local practice**

A customizable GSC mod menu for Call of Duty: Black Ops II Multiplayer on Plutonium T6. Features a black-and-red interface, smooth selection, remembered navigation, keyboard/controller action-based controls, and an automatic Crazy Vision effect while the menu is open.

## Requirements

- Black Ops II Multiplayer running through Plutonium T6 on Windows.
- A private/local match hosted by you for full access.
- Game assets needed by your selected map and equipment installed.

This release targets T6 Multiplayer, not Zombies, Steam-only BO2, IW5 or BO3. No DLL, injector or client patch is included or required.

## Installation

1. Close the game.
2. Download `JINX-T6-v0.6.20.zip` from this repository's Releases page and extract it.
3. Press **Win + R** and paste:
   ```text
   %localappdata%\Plutonium\storage\t6\scripts\mp
   ```
4. Create the `scripts` and `mp` folders if they do not exist.
5. Copy **jinx_menu.gsc** into that `mp` folder. Keep its filename unchanged; it must not end in `.txt`.
6. Move older JINX copies and other mod-menu scripts outside the game's script folders to avoid conflicts. Back up custom files; do not delete game assets.
7. Launch Plutonium T6 Multiplayer, host a private match, and spawn.
8. Hold **Aim Down Sights + Melee** to open JINX. Release both inputs before navigating.

Final file location:
```text
%localappdata%\Plutonium\storage\t6\scripts\mp\jinx_menu.gsc
```

Only the GSC file is installed. The supplied file is readable GSC source; use it as provided. No separate installer is needed.

## Controls

The menu reads game actions, not fixed physical keys. Your in-game bindings and controller layout determine the buttons.

| Action | Default menu control |
| --- | --- |
| Open | Hold Aim Down Sights + Melee |
| Move up | Aim Down Sights |
| Move down | Fire |
| Select / cycle a value | Use / Interact |
| Back | Melee |
| Close | Melee on the main screen |
| Previous page | Tactical grenade |
| Next page | Lethal grenade |

On the main screen, the page controls jump eight categories. Within submenus, they change pages when available. Menu Settings can switch the opening combination to ADS + Use and enable ADS + Melee as a direct close combination. If you change those settings, use the displayed control hints.

For a standard Xbox-style layout, ADS/Fire are usually LT/RT, Use is X, and Melee is the right-stick press. PlayStation-style equivalents are usually L2/R2, Square and R3. Alternate layouts and remapping change these assignments.

## Categories (display order)

1. Self Menu
2. Weapons Menu
3. Aimbot Menu
4. Trickshot Menu
5. Mini Map Menu
6. Teleport Menu
7. Fun Menu
8. Model Menu
9. Spawnables Menu
10. Game Mods Menu
11. Lobby Menu
12. Map Menu
13. Host Only Menu
14. All Players Menu
15. Players Menu
16. Messages Menu
17. Menu Settings

The right-side arrow or ON/OFF state is displayed beside the currently selected option. The menu uses 32 HUD elements to leave more room for the game HUD.

## Highlights

- Personal player settings, perks, weapons, attachments, kits and camos.
- Private trickshot practice tools and Ballista/DSR loadout groups.
- Radar options and torso ESP markers with visibility-based coloring.
- Teleport tools, spawned objects and practice platforms.
- In-match custom modes including Gun Game, One in the Chamber and weapon-only modes.
- Player administration, batch actions and revocable guest-menu access.
- Message presets, display styles and automatic messages.
- Themes, colors, panel dimensions, layout styles and navigation settings.

## Scope and limitations

- Host-level actions require the private-match host. Giving a human player menu access grants only the permitted Self, Weapons and Menu Settings actions; it does not grant host administration. Bots cannot operate a menu.
- Map Menu provides **Reload Current Map** and **Current Map Info**. Automatic switching to another map is not included.
- Prestige selection changes the match display; it is not a persistent profile unlock or XP service.
- ESP uses torso markers, not skeletons or full 2D/3D body boxes.
- The automatic menu vision effect is skipped in vehicles or remote-control states.
- Mode-specific actions require their relevant game mode and conditions. Native game rules and asset availability still apply.
- No Recoil, Force Host, XP Lobby, Clear Killfeed, Snaplines, Bones, full 2D/3D boxes, Size Editor, Rainbow Model, Light Sabers and Invert Controls are not exposed in this release.

## Troubleshooting

**Menu does not appear:** confirm you are hosting a private match, have spawned, and the file is in `scripts\mp`. Check for a hidden `.txt` extension. Restart the match after replacing scripts.

**Controls do something unexpected:** check your actual ADS, Fire, Use, Melee and grenade bindings. Release the opening combination before navigating. Check Menu Settings if you changed the open/close controls.

**Script error or overflow:** reproduce with only this menu installed. Older script overrides may also exist under `storage\t6\maps\mp`; move only known third-party mod files to a backup location. Report the full error text, map, mode, menu version and exact steps.

**An action is unavailable:** check host access, whether the player is alive/on foot, and any mode-specific instruction shown by the menu.

**Uninstall:** close the game, remove `jinx_menu.gsc` from the installation folder, then start a fresh match.

## Validation and bug reports

The source compiled successfully with gsc-tool targeting T6 PC. The author confirmed the final version working in their private-match setup. This does not guarantee every configuration or combination of mods.

When reporting an issue, include version, map, game mode, steps to reproduce, other installed scripts and the complete error text or screenshot.

## Author

- Jinx
- YouTube: https://www.youtube.com/@JinxPR
- Instagram: https://www.instagram.com/luistorrespr_/

An independent community project, not an official Plutonium or Call of Duty release.
