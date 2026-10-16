// v0.6.20: 32-element menu HUD; one selected-row indicator replaces 17 indicators.
// v0.6.19: rebalance menu HUD pools to restore missing last row, scrollbar and footer.
// v0.6.18: Crazy Vision is automatic menu styling only; removed its selectable row.
// v0.6.17: temporary Crazy Vision while the menu is open; restores normal vision on close.
// v0.6.16: release cleanup; unavailable rows and manual map-change placeholders removed.
// Based on v0.6.12: private-host player administration, batch actions, revocable guest menus.
// Guest access: personal Self/Weapons/UI whitelist; no delegated host or lobby powers.
// Menu access lasts until disconnect/map end. Temporary grants reset on respawn.
// Ban is map-session only; prestige edits are display-only. No permanent profile changes.
// Stock source verification is recorded in the audit comment at the end of this file.
#include maps\mp\gametypes\_hud_util;

main()
{
    replaceFunc(maps\mp\bots\_bot::bot_comp_stomp_remove, ::jinx_bot_remove_guard);
    replaceFunc(maps\mp\bots\_bot::spawn_bot, ::jinx_stock_bot_spawn);
    replaceFunc(maps\mp\gametypes\_killcam::calckillcamtime, ::jinx_calc_killcam_time);
}

init()
{
    if (isDefined(level.jinx_phase1_started))
        return;
    level.jinx_phase1_started = true;
    level.jinx_phase1_ended = false;
    level.jinx_categories = [];
    level.jinx_categories[0] = "Self Menu";
    level.jinx_categories[1] = "Aimbot Menu";
    level.jinx_categories[2] = "Trickshot Menu";
    level.jinx_categories[3] = "Messages Menu";
    level.jinx_categories[4] = "Mini Map Menu";
    level.jinx_categories[5] = "Lobby Menu";
    level.jinx_categories[6] = "Menu Settings";
    level.jinx_categories[7] = "Weapons Menu";
    level.jinx_categories[8] = "Game Mods Menu";
    level.jinx_categories[9] = "Fun Menu";
    level.jinx_categories[10] = "Model Menu";
    level.jinx_categories[11] = "Spawnables Menu";
    level.jinx_categories[12] = "Teleport Menu";
    level.jinx_categories[13] = "Map Menu";
    level.jinx_categories[14] = "Host Only Menu";
    level.jinx_categories[15] = "All Players Menu";
    level.jinx_categories[16] = "Players Menu";
    level.jinx_main_order = [];
    level.jinx_main_order[0] = 0;
    level.jinx_main_order[1] = 7;
    level.jinx_main_order[2] = 1;
    level.jinx_main_order[3] = 2;
    level.jinx_main_order[4] = 4;
    level.jinx_main_order[5] = 12;
    level.jinx_main_order[6] = 9;
    level.jinx_main_order[7] = 10;
    level.jinx_main_order[8] = 11;
    level.jinx_main_order[9] = 8;
    level.jinx_main_order[10] = 5;
    level.jinx_main_order[11] = 13;
    level.jinx_main_order[12] = 14;
    level.jinx_main_order[13] = 15;
    level.jinx_main_order[14] = 16;
    level.jinx_main_order[15] = 3;
    level.jinx_main_order[16] = 6;

    precacheShader("hud_remote_missile_target");
    precacheItem("kard_wager_mp");
    precacheItem("satchel_charge_mp");
    precacheItem("bouncingbetty_mp");
    precacheItem("sticky_grenade_mp");
    precacheItem("proximity_grenade_mp");
    precacheModel("tag_origin");
    precacheModel("collision_clip_64x64x10");
    precacheModel("collision_clip_256x256x10");
    level.jinx_fun_fx = [];
    level.jinx_fun_fx[0] = loadFx("weapon/bouncing_betty/fx_betty_explosion");
    level.jinx_fun_fx[1] = loadFx("weapon/bouncing_betty/fx_betty_launch_dust");
    level.jinx_fun_fx[2] = loadFx("weapon/trophy_system/fx_trophy_radius_detonation");
    level.jinx_torch_effect = loadFx("vehicle/vfire/fx_vfire_med_12");
    level.jinx_spawn_items = [];
    level.jinx_trampolines = [];
    jinx_minimap_prepare();
    jinx_catalog();
    level.jinx_access_closed = false;
    level.jinx_join_locked = false;
    level.jinx_anti_quit = false;
    level.jinx_zombie_preparing = false;
    level.jinx_zombie_token = 0;
    level.jinx_match_bans = [];
    level.jinx_hazard_filter = false;
    level.jinx_trickcam_on = false;
    level thread jinx_admin_service();
    level thread jinx_connections();
    level thread jinx_message_service();
    jinx_lobby_init();
    level thread jinx_lobby_service();

    level thread jinx_match_end();
}

// Catalog labels. jinx_dispatch explicitly selects implemented Phase 3 actions.
// All Players has no supplied option list; its own screen remains navigable.
jinx_catalog()
{
    level.jinx_options = [];
    options = [];
    options[0] = "God Mode";
    options[1] = "Infinite Ammo";
    options[2] = "Unlimited Tactical";
    options[3] = "Unlimited Lethal";
    options[4] = "Red Boxes (ESP)";
    options[5] = "Third Person";
    options[6] = "Noclip";
    options[7] = "Constant Radar";
    options[8] = "No Recoil";
    options[9] = "Rapid Fire";
    options[10] = "Fast Reload";
    options[11] = "Super Speed";
    options[12] = "Low Gravity";
    options[13] = "High Jump";
    options[14] = "No Fall Damage";
    options[15] = "Freeze Position";
    options[16] = "Invisible";
    options[17] = "Change Class";
    options[18] = "Change Team";
    options[19] = "Respawn";
    options[20] = "Player FOV";
    options[21] = "Give Streaks";
    options[22] = "Multi Jump";
    options[23] = "Health Bar";
    options[options.size] = "Left Gun";
    options[options.size] = "Restore ADS Zoom";
    level.jinx_options[0] = options;
    options = [];
    options[0] = "Aimbot ON/OFF";
    options[1] = "Aimbot Type";
    options[2] = "Target Selection";
    options[3] = "Bone Selection";
    options[4] = "Auto Shoot";
    options[5] = "Silent Aim";
    options[6] = "Auto Wall";
    options[7] = "No Spread";
    options[8] = "No Recoil";
    options[9] = "Prediction";
    options[10] = "Aim Key";
    options[11] = "Aim FOV";
    options[12] = "Aim Smoothness";
    options[13] = "Visible Check";
    level.jinx_options[1] = options;
    options = [];
    options[0] = "Azza Aimbot";
    options[1] = "Trickshot Aimbot";
    options[2] = "Auto Trickshot";
    options[3] = "Trickshot Type";
    options[4] = "Trickshot Bone";
    options[5] = "Trickshot Prediction";
    options[6] = "Rapid Target Switch";
    options[7] = "No Flinch";
    options[8] = "No Spread (Trickshot)";
    options[9] = "Fast Swap";
    options[10] = "Crosshair";
    options[11] = "Bullet Teleport";
    options[12] = "Save / Load Position";
    options[13] = "Trickshot Bots";
    options[14] = "Trickshot Camera"; // Filtered below; no visible duplicate.
    options[15] = "Trickshot Hitmarker";
    options[16] = "Trickshot Killcam";
    options[17] = "Azza Aim Angle";
    options[18] = "Azza Max Range";
    options[options.size] = "Drop Canswap";
    options[options.size] = "Trickshot Class";
    options[options.size] = "Bind Insta Swap To";
    filtered = [];
    for (i = 0; i < options.size; i++)
        if (options[i] != "Trickshot Bots" && options[i] != "Trickshot Camera") filtered[filtered.size] = options[i];
    level.jinx_options[2] = filtered;
    options = [];
    options[0] = "Send Message";
    options[1] = "Center Message";
    options[2] = "Big Text Message";
    options[3] = "Scrolling Text";
    options[4] = "Typewriter Message";
    options[5] = "Killstreak Message";
    options[6] = "Welcome Message";
    options[7] = "Disconnect Message";
    options[8] = "Custom HUD Text";
    options[9] = "Chat Spam";
    options[10] = "Chat Rainbow";
    options[11] = "Advertise Menu";
    options[12] = "Instagram Text";
    options[13] = "YouTube Text";
    options[14] = "Custom Text Colors";
    options[15] = "Message Text";
    level.jinx_options[3] = options;
    options = [];
    options[0] = "Normal Map";
    options[1] = "Full Map";
    options[2] = "Radar Always On";
    options[3] = "UAV";
    options[4] = "Red Boxes (ESP)";
    options[5] = "Draw Friendly";
    options[6] = "Draw Enemy";
    options[7] = "Draw Names";
    options[8] = "Draw Distance";
    options[9] = "Draw Weapons";
    options[10] = "Draw Snaplines";
    options[11] = "Draw Bones";
    options[12] = "Draw Health";
    options[13] = "Draw 2D/3D Boxes";
    options[options.size] = "Show FPS";
    level.jinx_options[4] = options;
    options = [];
    options[0] = "End Game";
    options[1] = "Anti-Join";
    options[2] = "Anti-Quit";
    options[3] = "Fast Restart";
    options[4] = "Force Host";
    options[5] = "Set Game Speed";
    options[6] = "Unlimited Game Time";
    options[7] = "Disable Killcam";
    options[8] = "Disable Final Killcam";
    options[9] = "Freeze Lobby";
    options[10] = "Clear Killfeed";
    options[11] = "Ranked Match (Off)";
    options[12] = "Private Match Settings";
    options[13] = "Death Barriers ON/OFF";
    options[14] = "Tie Game";
    options[15] = "Long Melee";
    options[16] = "Long Killcams";
    options[17] = "Super Jump";
    options[18] = "Super Speed";
    options[19] = "Bot Menu";
    options[20] = "XP Lobby";
    options[options.size] = "Plant Bomb";
    options[options.size] = "Defuse Bomb";
    options[options.size] = "FFA Last";
    options[options.size] = "TDM Last";
    level.jinx_options[5] = options;
    options = [];
    options[0] = "Menu Theme";
    options[1] = "Menu Position";
    options[2] = "Menu Size";
    options[3] = "Menu Font";
    options[4] = "Menu Color 1";
    options[5] = "Menu Color 2";
    options[6] = "Background";
    options[7] = "Scrollbar";
    options[8] = "Menu Sound";
    options[9] = "Open Key";
    options[10] = "Close Key";
    options[11] = "Scroll Style";
    options[12] = "Reset Settings";
    options[13] = "Save Settings";
    options[14] = "Move With Menu";
    options[15] = "Move During Countdown";
    options[16] = "Panel Shape";
    options[17] = "Panel Width";
    options[18] = "Text Color";
    options[19] = "Selection Opacity";
    options[20] = "Logo Size";
    options[21] = "Row Text Size";
    options[22] = "Show Controls";
    options[23] = "Selection Speed";
    options[options.size] = "Menu Design";
    options[options.size] = "Replay Welcome";

    level.jinx_options[6] = options;
    options = [];
    options[0] = "Camos";
    options[1] = "Weapon Kits";
    options[2] = "Custom Weapons";
    options[3] = "Rapid Fire";
    options[4] = "No Recoil";
    options[5] = "No Spread";
    options[6] = "Laser Sight";
    options[7] = "Thermal Scope";
    options[8] = "Toggle ACOG";
    options[9] = "Default Weapon";
    options[10] = "Upgrade Weapon";
    options[11] = "Weapon Menu 2/2";
    options[options.size] = "Give Random Camo";
    level.jinx_options[7] = options;
    options = [];
    options[0] = "Scorestreaks Menu";
    options[1] = "Perks Menu";
    options[2] = "Timescale";
    options[3] = "Crazy Vision";
    options[4] = "Death Machine";
    options[5] = "Gun Game";
    options[6] = "Sticks and Stones";
    options[7] = "One in the Chamber";
    options[8] = "Sharpshooter";
    options[9] = "Sniper Only";
    options[10] = "Custom Game Modes";
    options[11] = "Stop Active Mode";
    level.jinx_options[8] = options;
    options = [];
    options[0] = "Trickshot Menu";
    options[1] = "Teleport Gun";
    options[2] = "Jetpack";
    options[3] = "Clone Me";
    options[4] = "Earthquake";
    options[5] = "Fake Lag (visual simulation)";
    options[6] = "Shake Screen";
    options[7] = "Third Person";
    options[8] = "Skybox";
    options[9] = "Zombie Mode (Fake)";
    options[10] = "Crosshair";
    options[11] = "Hitmarker";
    options[12] = "Random FX";
    options[13] = "Pick Up Player";
    options[14] = "Pro-Mod";
    filtered = [];
    for (f = 0; f < options.size; f++)
        if (options[f] != "Shake Screen" && options[f] != "Trickshot Menu") filtered[filtered.size] = options[f];
    filtered[filtered.size] = "Matrix Aiming";
    filtered[filtered.size] = "Rainbow Gun";
    level.jinx_options[9] = filtered;
    options = [];
    options[0] = "Change Model";
    options[1] = "Third Person Model";
    options[2] = "Force Player Model";
    options[3] = "Default Model";
    options[4] = "Human Torch";
    options[5] = "Size Editor";
    options[6] = "Rainbow Model";
    options[7] = "Invisible Model";
    options[8] = "Model Loop";
    options[9] = "Transform Into Object";
    options[options.size] = "Object Height";
    level.jinx_options[10] = options;
    options = [];
    options[0] = "Spawn Airdrop";
    options[1] = "Spawn Turret";
    options[2] = "Spawn Bouncing Betty";
    options[3] = "Spawn C4";
    options[4] = "Spawn Trampoline";
    options[5] = "Spawn Care Package";
    options[6] = "Spawn Bob/Sentry";
    options[7] = "Spawn Sentry";
    options[8] = "Spawn Vehicle";
    options[9] = "Spawn Fake Player";
    options[10] = "Spawn All";
    options[11] = "Sky Base";
    options[12] = "Trickshot Platform";
    options[13] = "Teleport To Last Platform";
    options[14] = "Return From Platform";
    options[15] = "Delete Last Spawn";
    options[16] = "Clear Spawned Objects";
    options[17] = "Detonate Spawned C4";
    level.jinx_options[11] = options;
    options = [];
    options[0] = "Save Position";
    options[1] = "Load Position";
    options[2] = "Teleport To Crosshair";
    options[3] = "Teleport To Player";
    options[4] = "Teleport To Sky";
    options[5] = "Teleport To Map";
    options[6] = "Teleport To All";
    options[7] = "Teleport To Spawn";
    options[8] = "Teleport To Trickshot";
    options[9] = "Return To Previous Position";
    level.jinx_options[12] = options;
    options = [];
    options[0] = "Nuketown 2025";
    options[1] = "Hijacked";
    options[2] = "Carrier";
    options[3] = "Standoff";
    options[4] = "Raid";
    options[5] = "Slums";
    options[6] = "Overflow";
    options[7] = "Express";
    options[8] = "Yemen";
    options[9] = "Downhill";
    options[10] = "Hydro";
    options[11] = "Mirage";
    options[12] = "Grind";
    options[13] = "Magma";
    options[14] = "Encore";
    options[15] = "Vertigo";
    options[16] = "Studio";
    options[17] = "Cove";
    options[18] = "Detour";
    options[19] = "Rush";
    options[20] = "Uplink";
    options[21] = "Frost";
    options[22] = "Pod";
    options[23] = "Dig";
    options[24] = "Takeoff";
    options[25] = "Map Loader";
    options[options.size] = "Aftermath";
    options[options.size] = "Cargo";
    options[options.size] = "Drone";
    options[options.size] = "Meltdown";
    options[options.size] = "Plaza";
    options[options.size] = "Turbine";
    level.jinx_options[13] = options;
    options = [];
    options[0] = "Host Controls";
    options[1] = "Game Rules";
    options[2] = "Player Permissions";
    options[3] = "Team Settings";
    options[4] = "Match Restart";
    options[5] = "Match Timer";
    options[6] = "Private Lobby Configuration";
    options[7] = "Show FPS";
    options[8] = "Gun on Left Side";
    level.jinx_options[14] = options;
    options = [];
    level.jinx_options[15] = options;
    options = [];
    options[0] = "Player List";
    options[1] = "Spectate Player";
    options[2] = "Kick Player";
    options[3] = "Ban Player";
    options[4] = "Freeze Player";
    options[5] = "Teleport To Player";
    options[6] = "Teleport Player To Me";
    options[7] = "Give God Mode";
    options[8] = "Take God Mode";
    options[9] = "Give Infinite Ammo";
    options[10] = "Set Prestige";
    options[11] = "More Options 2/2";
    level.jinx_options[16] = options;
    options = [];
    options[0] = "None";
    options[1] = "DEVGRU";
    options[2] = "A-TACS AU";
    options[3] = "ERDL";
    options[4] = "Siberia";
    options[5] = "Choco";
    options[6] = "Blue Tiger";
    options[7] = "Bloodshot";
    options[8] = "Ghostex: Delta 6";
    options[9] = "Kryptek: Typhon";
    options[10] = "Carbon Fiber";
    options[11] = "Cherry Blossom";
    options[12] = "Art of War";
    options[13] = "Ronin";
    options[14] = "Skulls";
    options[15] = "Gold";
    options[16] = "Diamond";
    options[17] = "Elite Member";
    options[18] = "CE Digital";
    options[19] = "Afterlife";
    options[20] = "Aqua";
    options[21] = "Bacon";
    options[22] = "Beast";
    options[23] = "Benjamins";
    options[24] = "Breach";
    options[25] = "Comics";
    options[26] = "Coyote";
    options[27] = "Cyborg";
    options[28] = "Dead Man's Hand";
    options[29] = "Dia de Muertos";
    options[30] = "Dragon";
    options[31] = "Glam";
    options[32] = "Graffiti";
    options[33] = "Jungle Warfare";
    options[34] = "Kawaii";
    options[35] = "Octane";
    options[36] = "Pack-A-Punch";
    options[37] = "Paladin";
    options[38] = "Party Rock";
    options[39] = "Rogue";
    options[40] = "UK Punk";
    options[41] = "Viper";
    options[42] = "Weaponized 115";
    options[43] = "Zombies";
    options[44] = "Ghosts";
    options[45] = "Advanced Warfare";
    level.jinx_options[17] = options;
    options = [];
    level.jinx_options[18] = strTok("Add Enemy Bot,Add Max Bots,Remove One Bot,Remove All Bots,Freeze Enemy Bots,Unfreeze Enemy Bots,Move Bots To Crosshair", ",");

    level.jinx_guns = [];
    level.jinx_weapon_groups = [];
    level.jinx_kit_guns = [];
    level.jinx_options[19] = strTok("Assault Rifles,SMGs,LMGs,Sniper Rifles,Shotguns,Pistols,Launchers,Special Weapons", ",");
    level.jinx_options[22] = strTok("MTAR,Type 25,SWAT-556,FAL OSW,M27,SCAR-H,SMR,M8A1,AN-94", ",");
    level.jinx_weapon_groups[22] = strTok("tar21_mp,type95_mp,sig556_mp,sa58_mp,hk416_mp,scar_mp,saritch_mp,xm8_mp,an94_mp", ",");
    level.jinx_guns[0] = "tar21_mp";
    level.jinx_guns[1] = "type95_mp";
    level.jinx_guns[2] = "sig556_mp";
    level.jinx_guns[3] = "sa58_mp";
    level.jinx_guns[4] = "hk416_mp";
    level.jinx_guns[5] = "scar_mp";
    level.jinx_guns[6] = "saritch_mp";
    level.jinx_guns[7] = "xm8_mp";
    level.jinx_guns[8] = "an94_mp";
    level.jinx_options[23] = strTok("MP7,PDW-57,Vector K10,MSMC,Chicom CQB,Scorpion EVO,Peacekeeper", ",");
    level.jinx_weapon_groups[23] = strTok("mp7_mp,pdw57_mp,vector_mp,insas_mp,qcw05_mp,evoskorpion_mp,peacekeeper_mp", ",");
    level.jinx_guns[9] = "mp7_mp";
    level.jinx_guns[10] = "pdw57_mp";
    level.jinx_guns[11] = "vector_mp";
    level.jinx_guns[12] = "insas_mp";
    level.jinx_guns[13] = "qcw05_mp";
    level.jinx_guns[14] = "evoskorpion_mp";
    level.jinx_guns[15] = "peacekeeper_mp";
    level.jinx_options[24] = strTok("Mk 48,QBB LSW,LSAT,HAMR", ",");
    level.jinx_weapon_groups[24] = strTok("mk48_mp,qbb95_mp,lsat_mp,hamr_mp", ",");
    level.jinx_guns[16] = "mk48_mp";
    level.jinx_guns[17] = "qbb95_mp";
    level.jinx_guns[18] = "lsat_mp";
    level.jinx_guns[19] = "hamr_mp";
    level.jinx_options[25] = strTok("SVU-AS,DSR 50,Ballista,XPR-50", ",");
    level.jinx_weapon_groups[25] = strTok("svu_mp,dsr50_mp,ballista_mp,as50_mp", ",");
    level.jinx_guns[20] = "svu_mp";
    level.jinx_guns[21] = "dsr50_mp";
    level.jinx_guns[22] = "ballista_mp";
    level.jinx_guns[23] = "as50_mp";
    level.jinx_options[26] = strTok("R870 MCS,S12,KSG,M1216", ",");
    level.jinx_weapon_groups[26] = strTok("870mcs_mp,saiga12_mp,ksg_mp,srm1216_mp", ",");
    level.jinx_guns[24] = "870mcs_mp";
    level.jinx_guns[25] = "saiga12_mp";
    level.jinx_guns[26] = "ksg_mp";
    level.jinx_guns[27] = "srm1216_mp";
    level.jinx_options[27] = strTok("Five-seven,Tac-45,B23R,Executioner,KAP-40,KAP-40 (Dual Wield)", ",");
    level.jinx_weapon_groups[27] = strTok("fiveseven_mp,fnp45_mp,beretta93r_mp,judge_mp,kard_mp,kard_dw_mp", ",");
    level.jinx_guns[28] = "fiveseven_mp";
    level.jinx_guns[29] = "fnp45_mp";
    level.jinx_guns[30] = "beretta93r_mp";
    level.jinx_guns[31] = "judge_mp";
    level.jinx_guns[32] = "kard_mp";
    level.jinx_guns[33] = "kard_dw_mp";
    level.jinx_options[28] = strTok("SMAW,FHJ-18 AA,RPG", ",");
    level.jinx_weapon_groups[28] = strTok("smaw_mp,fhj18_mp,usrpg_mp", ",");
    level.jinx_guns[34] = "smaw_mp";
    level.jinx_guns[35] = "fhj18_mp";
    level.jinx_guns[36] = "usrpg_mp";
    level.jinx_options[29] = strTok("Assault Shield,Combat Knife,Crossbow,Ballistic Knife,Default Weapon", ",");
    level.jinx_weapon_groups[29] = strTok("riotshield_mp,knife_held_mp,crossbow_mp,knife_ballistic_mp,defaultweapon_mp", ",");
    level.jinx_guns[37] = "riotshield_mp";
    level.jinx_guns[38] = "knife_held_mp";
    level.jinx_guns[39] = "crossbow_mp";
    level.jinx_guns[40] = "knife_ballistic_mp";
    level.jinx_guns[41] = "defaultweapon_mp";
    level.jinx_options[20] = strTok("DSR 50 + Five-seven,Ballista + Five-seven,AN-94 + Tac-45,MP7 + B23R,MTAR + KAP-40,SCAR-H + Executioner,M8A1 + B23R,MSMC + Five-seven,Peacekeeper + Tac-45,PDW-57 + KAP-40,LSAT + B23R,HAMR + Five-seven,R870 + Tac-45,KSG + Executioner,SVU-AS + KAP-40,XPR-50 + B23R,Crossbow + Ballistic Knife,Riot Shield + Five-seven", ",");
    level.jinx_kit_guns[0] = strTok("dsr50_mp,fiveseven_mp", ",");
    level.jinx_kit_guns[1] = strTok("ballista_mp,fiveseven_mp", ",");
    level.jinx_kit_guns[2] = strTok("an94_mp,fnp45_mp", ",");
    level.jinx_kit_guns[3] = strTok("mp7_mp,beretta93r_mp", ",");
    level.jinx_kit_guns[4] = strTok("tar21_mp,kard_mp", ",");
    level.jinx_kit_guns[5] = strTok("scar_mp,judge_mp", ",");
    level.jinx_kit_guns[6] = strTok("xm8_mp,beretta93r_mp", ",");
    level.jinx_kit_guns[7] = strTok("insas_mp,fiveseven_mp", ",");
    level.jinx_kit_guns[8] = strTok("peacekeeper_mp,fnp45_mp", ",");
    level.jinx_kit_guns[9] = strTok("pdw57_mp,kard_mp", ",");
    level.jinx_kit_guns[10] = strTok("lsat_mp,beretta93r_mp", ",");
    level.jinx_kit_guns[11] = strTok("hamr_mp,fiveseven_mp", ",");
    level.jinx_kit_guns[12] = strTok("870mcs_mp,fnp45_mp", ",");
    level.jinx_kit_guns[13] = strTok("ksg_mp,judge_mp", ",");
    level.jinx_kit_guns[14] = strTok("svu_mp,kard_mp", ",");
    level.jinx_kit_guns[15] = strTok("as50_mp,beretta93r_mp", ",");
    level.jinx_kit_guns[16] = strTok("crossbow_mp,knife_ballistic_mp", ",");
    level.jinx_kit_guns[17] = strTok("riotshield_mp,fiveseven_mp", ",");
    level.jinx_options[21] = strTok("UAV,RC-XD,Hunter Killer,Care Package,Counter UAV,Guardian,Hellstorm Missile,Lightning Strike,Sentry Gun,Death Machine,War Machine,Dragonfire,AGR,Stealth Chopper,Orbital VSAT,Escort Drone,EMP Systems,Warthog,Lodestar,VTOL Warship,K9 Unit,Swarm", ",");
    level.jinx_streaks = strTok("radar_mp,rcbomb_mp,inventory_missile_drone_mp,inventory_supplydrop_mp,counteruav_mp,microwaveturret_mp,remote_missile_mp,planemortar_mp,autoturret_mp,minigun_mp,m32_mp,killstreak_qrdrone_mp,inventory_ai_tank_drop_mp,helicopter_comlink_mp,radardirection_mp,helicopter_guard_mp,emp_mp,straferun_mp,remote_mortar_mp,helicopter_player_gunner_mp,dogs_mp,missile_swarm_mp", ",");
    level.jinx_options[30] = strTok("Attachments,Refill Current Ammo,Remove Attachments,Random Weapon,Remove Current Weapon", ",");
    level.jinx_options[31] = strTok("ACOG,Dual Band,Extended Clip,Fast Mag,FMJ,Fore Grip,Laser Sight,Quickdraw,Rapid Fire,Reflex,Stock,Suppressor", ",");
    level.jinx_attachment_ids = strTok("acog,ir,extclip,dualclip,fmj,grip,steadyaim,fastads,rf,reflex,stalker,silencer", ",");
    level.jinx_options[32] = strTok("Custom Class 1,Custom Class 2,Custom Class 3,Custom Class 4,Custom Class 5,Custom Class 6,Custom Class 7,Custom Class 8,Custom Class 9,Custom Class 10,Default SMG,Default CQB,Default Assault,Default LMG,Default Sniper", ",");
    level.jinx_classes = strTok("CLASS_CUSTOM1,CLASS_CUSTOM2,CLASS_CUSTOM3,CLASS_CUSTOM4,CLASS_CUSTOM5,CLASS_CUSTOM6,CLASS_CUSTOM7,CLASS_CUSTOM8,CLASS_CUSTOM9,CLASS_CUSTOM10,CLASS_SMG,CLASS_CQB,CLASS_ASSAULT,CLASS_LMG,CLASS_SNIPER", ",");
    level.jinx_camo_ids = [];
    level.jinx_camo_ids["None"] = 0;
    level.jinx_camo_ids["DEVGRU"] = 1;
    level.jinx_camo_ids["A-TACS AU"] = 2;
    level.jinx_camo_ids["ERDL"] = 3;
    level.jinx_camo_ids["Siberia"] = 4;
    level.jinx_camo_ids["Choco"] = 5;
    level.jinx_camo_ids["Blue Tiger"] = 6;
    level.jinx_camo_ids["Bloodshot"] = 7;
    level.jinx_camo_ids["Ghostex: Delta 6"] = 8;
    level.jinx_camo_ids["Kryptek: Typhon"] = 9;
    level.jinx_camo_ids["Carbon Fiber"] = 10;
    level.jinx_camo_ids["Cherry Blossom"] = 11;
    level.jinx_camo_ids["Art of War"] = 12;
    level.jinx_camo_ids["Ronin"] = 13;
    level.jinx_camo_ids["Skulls"] = 14;
    level.jinx_camo_ids["Gold"] = 15;
    level.jinx_camo_ids["Diamond"] = 16;
    level.jinx_camo_ids["CE Digital"] = 18;
    level.jinx_camo_ids["Jungle Warfare"] = 19;
    level.jinx_camo_ids["Ghosts"] = 29;
    level.jinx_camo_ids["Advanced Warfare"] = 45;
    level.jinx_camo_ids["Cyborg"] = 31;
    level.jinx_camo_ids["Weaponized 115"] = 43;
    level.jinx_camo_ids["Paladin"] = 30;
    level.jinx_camo_ids["Party Rock"] = 25;
    level.jinx_camo_ids["Afterlife"] = 44;
    level.jinx_camo_ids["Beast"] = 41;
    level.jinx_camo_ids["Dragon"] = 32;
    for (i = 0; i < level.jinx_guns.size; i++) precacheItem(level.jinx_guns[i]);
    level.jinx_camo_ids["Elite Member"] = 17;
    level.jinx_camo_ids["UK Punk"] = 20;
    level.jinx_camo_ids["Benjamins"] = 21;
    level.jinx_camo_ids["Dia de Muertos"] = 22;
    level.jinx_camo_ids["Graffiti"] = 23;
    level.jinx_camo_ids["Kawaii"] = 24;
    level.jinx_camo_ids["Zombies"] = 26;
    level.jinx_camo_ids["Viper"] = 27;
    level.jinx_camo_ids["Bacon"] = 28;
    level.jinx_camo_ids["Comics"] = 34;
    level.jinx_camo_ids["Aqua"] = 33;
    level.jinx_camo_ids["Breach"] = 35;
    level.jinx_camo_ids["Coyote"] = 36;
    level.jinx_camo_ids["Glam"] = 37;
    level.jinx_camo_ids["Rogue"] = 38;
    level.jinx_camo_ids["Pack-A-Punch"] = 39;
    level.jinx_camo_ids["Dead Man's Hand"] = 40;
    level.jinx_camo_ids["Octane"] = 42;

    // Nested screens do not add categories or HUD elements to the main menu.
    level.jinx_titles = [];
    for (i = 0; i < level.jinx_categories.size; i++)
        level.jinx_titles[i] = level.jinx_categories[i];
    level.jinx_titles[17] = "Camos";
    level.jinx_titles[18] = "Bot Menu";
    level.jinx_titles[19] = "Custom Weapons";
    level.jinx_titles[20] = "Weapon Kits";
    level.jinx_titles[21] = "Give Streaks";

    level.jinx_titles[22] = "Assault Rifles";
    level.jinx_titles[23] = "SMGs";
    level.jinx_titles[24] = "LMGs";
    level.jinx_titles[25] = "Sniper Rifles";
    level.jinx_titles[26] = "Shotguns";
    level.jinx_titles[27] = "Pistols";
    level.jinx_titles[28] = "Launchers";
    level.jinx_titles[29] = "Special Weapons";
    level.jinx_titles[30] = "Weapon Menu 2/2";
    level.jinx_titles[31] = "Attachments";
    level.jinx_titles[32] = "Change Class - Instant";

    level.jinx_options[33] = []; // Reserved index; duplicate bot menu removed.
    level.jinx_titles[33] = "Reserved";
    jinx_game_catalog();
    jinx_message_catalog();
    level.jinx_options[34] = level.jinx_message_groups;
    level.jinx_titles[34] = "Message Text";
    level.jinx_options[45] = strTok("Helicopter,Sentry Turret,Guardian,Supply Crate,AGR,Bouncing Betty,C4,Default Model", ",");
    level.jinx_titles[45] = "Object Models";
    level.jinx_options[46] = [];
    level.jinx_titles[46] = "Teleport To Player";
    jinx_extended_catalog();

    // Stable labels preserve action routing after reorganizing the visible rows.
    level.jinx_options[0] = strTok("God Mode,Health Bar,No Fall Damage,Infinite Ammo,Unlimited Tactical,Unlimited Lethal,Perks Menu,Give Streaks,No Recoil,Rapid Fire,Fast Reload,Noclip,Super Speed,High Jump,Multi Jump,Low Gravity,Freeze Position,Player FOV,Restore ADS Zoom,Third Person,Left Gun,Red Boxes (ESP),Invisible,Change Class,Change Team,Respawn", ",");
    filtered = [];
    foreach (entry in level.jinx_options[8]) if (entry != "Perks Menu") filtered[filtered.size] = entry;
    level.jinx_options[8] = filtered;
    level.jinx_options[3] = strTok("Message Text,Send Message,Preview Message,Display Style,Automatic Messages,Colors and Effects,Social Messages", ",");
    level.jinx_titles[54] = "Display Style";
    level.jinx_options[54] = strTok("Center Message,Big Text Message,Scrolling Text,Typewriter Message", ",");
    level.jinx_titles[55] = "Automatic Messages";
    level.jinx_options[55] = strTok("Welcome Message,Disconnect Message,Killstreak Message,Chat Spam", ",");
    level.jinx_titles[56] = "Colors and Effects";
    level.jinx_options[56] = strTok("Custom Text Colors,Chat Rainbow,Custom HUD Text", ",");
    level.jinx_titles[57] = "Social Messages";
    level.jinx_options[57] = strTok("Advertise Menu,YouTube Text,Instagram Text", ",");

    jinx_order_rows(1, "Aimbot ON/OFF,Aimbot Type,Aim Key,Aim FOV,Aim Smoothness,Target Selection,Bone Selection,Visible Check,Prediction,Silent Aim,Auto Wall,Auto Shoot,No Spread,No Recoil");
    jinx_order_rows(2, "Trickshot Class,Save / Load Position,Bind Insta Swap To,Drop Canswap,Azza Aimbot,Azza Aim Angle,Azza Max Range,Trickshot Aimbot,Trickshot Bone,Trickshot Prediction,Bullet Teleport,Fast Swap,No Flinch,No Spread (Trickshot),Crosshair,Trickshot Camera,Trickshot Hitmarker,Trickshot Killcam,Auto Trickshot,Trickshot Type,Rapid Target Switch");
    jinx_order_rows(5, "Bot Menu,Private Match Settings,Unlimited Game Time,Set Game Speed,Death Barriers ON/OFF,Super Jump,Super Speed,Long Melee,Disable Killcam,Disable Final Killcam,Long Killcams,Clear Killfeed,Plant Bomb,Defuse Bomb,FFA Last,TDM Last,Freeze Lobby,Anti-Join,Anti-Quit,Force Host,Ranked Match (Off),XP Lobby,Tie Game,Fast Restart,End Game");
    jinx_order_rows(6, "Menu Design,Menu Theme,Menu Position,Menu Size,Panel Shape,Panel Width,Background,Menu Color 1,Menu Color 2,Text Color,Menu Font,Logo Size,Row Text Size,Selection Opacity,Scrollbar,Scroll Style,Selection Speed,Show Controls,Open Key,Close Key,Move With Menu,Move During Countdown,Menu Sound,Replay Welcome,Save Settings,Reset Settings");
    jinx_order_rows(7, "Custom Weapons,Weapon Kits,Camos,Give Random Camo,Weapon Menu 2/2,Upgrade Weapon,Thermal Scope,Toggle ACOG,Laser Sight,Rapid Fire,No Spread,No Recoil,Default Weapon");
    jinx_order_rows(8, "Custom Game Modes,Gun Game,One in the Chamber,Sharpshooter,Sniper Only,Pistol Only,Shotgun Only,Sticks and Stones,Scorestreaks Menu,Death Machine,Timescale,Crazy Vision");
    jinx_order_rows(4, "Constant Radar,Radar Always On,UAV,Normal Map,Full Map,Red Boxes (ESP),Draw Enemy,Draw Friendly,Draw Names,Draw Distance,Draw Health,Draw Weapons,Draw 2D/3D Boxes,Draw Snaplines,Draw Bones,Show FPS");
    jinx_order_rows(9, "Teleport Gun,Pick Up Player,Jetpack,Clone Me,Rainbow Gun,Human Torch,Matrix Aiming,Earthquake,Fake Lag (visual simulation),Pro-Mod,Third Person,Crosshair,Hitmarker,Skybox,Random FX,Zombie Mode (Fake)");
    jinx_order_rows(10, "Change Model,Transform Into Object,Third Person Model,Object Height,Force Player Model,Human Torch,Invisible Model,Rainbow Model,Model Loop,Size Editor,Default Model");
    jinx_order_rows(11, "Trickshot Platform,Sky Base,Teleport To Last Platform,Return From Platform,Spawn Trampoline,Spawn Care Package,Spawn Airdrop,Spawn Turret,Spawn Sentry,Spawn Bob/Sentry,Spawn Vehicle,Spawn Fake Player,Spawn Bouncing Betty,Spawn C4,Detonate Spawned C4,Spawn All,Delete Last Spawn,Clear Spawned Objects");
    jinx_order_rows(12, "Save Position,Load Position,Return To Previous Position,Teleport To Crosshair,Teleport To Player,Teleport To Spawn,Teleport To Trickshot,Teleport To Sky,Teleport To Map,Teleport To All");
    jinx_order_rows(13, "Map Loader,Nuketown 2025,Hijacked,Raid,Standoff,Carrier,Slums,Express,Yemen,Overflow,Aftermath,Cargo,Drone,Meltdown,Plaza,Turbine,Downhill,Grind,Hydro,Mirage,Encore,Magma,Studio,Vertigo,Cove,Detour,Rush,Uplink,Dig,Frost,Pod,Takeoff");
    jinx_order_rows(14, "Host Controls,Private Lobby Configuration,Game Rules,Team Settings,Player Permissions,Match Timer,Show FPS,Gun on Left Side,Match Restart");
    jinx_order_rows(16, "Player List,Spectate Player,Teleport To Player,Teleport Player To Me,Give God Mode,Take God Mode,Give Infinite Ammo,Freeze Player,More Options 2/2,Set Prestige,Kick Player,Ban Player");
    jinx_admin_catalog();
    level.jinx_options[14][level.jinx_options[14].size] = "Clear Match Bans";
    level.jinx_titles[64] = "Prestige - Match Display";
    level.jinx_options[64] = strTok("Restore Prestige", ",");
    // Compact before building links: no blank rows, stale indices or N/A entries.
    for (category = 0; category < level.jinx_options.size; category++)
    {
        kept = [];
        foreach (entry in level.jinx_options[category])
        {
            if (jinx_unavailable_reason(entry) == "" && entry != "Ranked Match (Off)" && entry != "Crazy Vision")
                kept[kept.size] = entry;
        }
        level.jinx_options[category] = kept;
    }
    // Keep the main category; only expose actions that actually execute.
    level.jinx_options[13] = strTok("Reload Current Map,Current Map Info", ",");
    level.jinx_options[49] = [];
    level.jinx_options[50] = [];
    // Route by stable catalog labels, rather than shifting numeric row positions.
    level.jinx_links = [];
    for (i = 0; i < level.jinx_options.size; i++)
    {
        links = [];
        options = level.jinx_options[i];
        for (j = 0; j < options.size; j++)
        {
            links[j] = -1;
            if (i == 14 && options[j] == "Player Permissions") links[j] = 60;
            if (i == 14 && options[j] == "Game Rules") links[j] = 61;
            if (i == 14 && options[j] == "Team Settings") links[j] = 62;
            if (i == 14 && options[j] == "Match Timer") links[j] = 63;
            if (i == 3 && options[j] == "Message Text") links[j] = 34;
            if (i == 3 && options[j] == "Display Style") links[j] = 54;
            if (i == 3 && options[j] == "Automatic Messages") links[j] = 55;
            if (i == 3 && options[j] == "Colors and Effects") links[j] = 56;
            if (i == 3 && options[j] == "Social Messages") links[j] = 57;
            if (i == 34) links[j] = 35 + j;
            if (i == 19) links[j] = 22 + j;
            if (i == 2 && options[j] == "Trickshot Class") links[j] = 47;
            if (i == 47) links[j] = 51 + j;
            if (i == 2 && options[j] == "Bind Insta Swap To") links[j] = 48;
            if (i == 13 && options[j] == "Map Loader") links[j] = 49;
            if (i == 8 && (options[j] == "Killstreaks Menu" || options[j] == "Scorestreaks Menu")) links[j] = 21;
            if (i == 0 && options[j] == "Perks Menu") links[j] = 43;
            if (i == 8 && options[j] == "Custom Game Modes") links[j] = 44;
            if (i == 0 && options[j] == "Change Class") links[j] = 32;
            if (i == 7 && options[j] == "Weapon Menu 2/2") links[j] = 30;
            if (i == 30 && options[j] == "Attachments") links[j] = 31;
            if (i == 10 && options[j] == "Transform Into Object") links[j] = 45;
            if (i == 7 && options[j] == "Camos") links[j] = 17;
            if (i == 7 && options[j] == "Custom Weapons") links[j] = 19;
            if (i == 7 && options[j] == "Weapon Kits") links[j] = 20;
            if (i == 0 && options[j] == "Give Streaks") links[j] = 21;
            if (i == 5 && options[j] == "Bot Menu") links[j] = 18;
        }
        level.jinx_links[i] = links;
    }
}

jinx_connections()
{
    level endon("game_ended");
    for (;;)
    {
        level waittill("connected", player);
        player jinx_setup_player();
        player thread jinx_admission_check();
        player.jinx_access = false;
        player.jinx_admin_ammo = false;
        player.jinx_admin_frozen = false;
        player.jinx_admin_god = false;
        player.jinx_open = false;
        player.jinx_hud = [];
        player.jinx_cursor = 0;
        player.jinx_subcursor = [];
        for (i = 0; i < level.jinx_options.size; i++)
            player.jinx_subcursor[i] = 0;
        player.jinx_category = 0;
        player.jinx_return_stack = [];
        player.jinx_return_depth = 0;
        player.jinx_screen = "main";
        player.jinx_owns_freeze = false;
        player thread jinx_spawns();
        player thread jinx_practice_damage();

    }
}

jinx_spawns()
{
    self endon("disconnect");
    level endon("game_ended");
    for (;;)
    {
        self waittill("spawned_player");
        self jinx_admin_clear();
        self notify("jinx_life_stop");
        self jinx_stop_effects();
        self jinx_close();
        self.jinx_arsenal_saved = undefined;
        self.jinx_arsenal_applied = undefined;
        self.jinx_live_spawn_ready = getTime() + 350;
        self.jinx_spawn_origin = self.origin;
        self.jinx_spawn_angles = self getPlayerAngles();
        self.jinx_spawn_busy = false;
        self.jinx_live_life_gun = undefined;
        self.jinx_oic_scavenger = undefined;
        self.jinx_oic_budget = undefined;
        if (self isHost())
        {
            if (!isDefined(self.jinx_host_setup))
            {
                self.jinx_host_setup = true;
                self jinx_load_settings();
                self jinx_radar_normal_zoom();
                self thread jinx_host_disconnect();
            }
            if (isDefined(self.jinx_radar_requested) && self.jinx_radar_requested) self jinx_toggle_effect("radar");
                    self jinx_controls_notice();
            if (!isDefined(self.jinx_welcomed)) { self.jinx_welcomed = true; self jinx_intro_start(); }
            self thread jinx_input();
            self thread jinx_practice_shots();
            self thread jinx_life_event("death");
            self thread jinx_life_event("joined_spectators");
        }
        else if (self jinx_has_menu()) self jinx_guest_start();
    }
}

jinx_life_event(event_name)
{
    self endon("disconnect");
    self endon("jinx_life_stop");
    level endon("game_ended");
    self waittill(event_name);
    self jinx_stop_effects();
    self jinx_close();
    self notify("jinx_life_stop");
}

jinx_match_end()
{
    level waittill("game_ended");
    level.jinx_phase1_ended = true;
    jinx_admin_revoke_everyone();
    jinx_game_cleanup();
    jinx_spawn_clear();
    jinx_radar_global_restore();
    jinx_release_practice_bots();
    jinx_restore_gravity();
    jinx_restore_weapon_tuning();
    jinx_lobby_cleanup();
    if (!isDefined(level.players))
        return;
    for (i = 0; i < level.players.size; i++)
    {
        player = level.players[i];
        if (isDefined(player) && isDefined(player.jinx_open))
        {
            player notify("jinx_life_stop");
            player jinx_stop_effects();
            player jinx_close();
        }
    }
}

// One bounded input poll per living host. No threads per row / no HUD redraw loop.
// Read gameplay ACTIONS, not raw keyboard keys or client-side binds.
jinx_input()
{
    self endon("disconnect");
    self endon("jinx_life_stop");
    level endon("game_ended");
    previous = "";
    next_repeat = 0;
    armed = false;
    open_held = false;
    for (;;)
    {
        if (!isAlive(self) || !(self jinx_has_menu()))
        {
            self jinx_stop_effects();
            self jinx_close();
            return;
        }
        if (self isHost()) self jinx_effect_tick();
        else self jinx_guest_tick();

        ads = self adsButtonPressed();
        fire = self attackButtonPressed();
        use = self useButtonPressed();
        melee = self meleeButtonPressed();
        tactical = self secondaryOffhandButtonPressed();
        lethal = self fragButtonPressed();

        opening = ads && melee;
        if (self.jinx_settings["openkey"]) opening = ads && use;
        open_edge = opening && !open_held;
        open_held = opening;
        if (!self.jinx_open)
        {
            if (open_edge)
            {
                self jinx_open_menu();
                armed = false;
                previous = "";
            }
        }
        else if (!armed)
        {
            // Release the opening chord to avoid an accidental Back / scroll.
            if (!ads && !fire && !use && !melee && !tactical && !lethal)
                armed = true;
        }
        else
        {
            action = "";
            if (self.jinx_settings["closekey"] && ads && melee)
                action = "close";
            else if (melee)
                action = "back";
            else if (use)
                action = "select";
            else if (tactical && !lethal)
                action = "previous_page";
            else if (lethal && !tactical)
                action = "next_page";
            else if (ads && !fire)
                action = "up";
            else if (fire && !ads)
                action = "down";

            if (action == "")
                previous = "";
            else if (action != previous)
            {
                self jinx_action(action);
                previous = action;
                next_repeat = getTime() + 350;
            }
            else if ((action == "up" || action == "down") && getTime() >= next_repeat)
            {
                self jinx_action(action);
                next_repeat = getTime() + 140;
            }
        }
        wait 0.05;
    }
}

// Only explicitly supported Phase 3 actions are dispatched; other catalog entries stay pending.
jinx_action(action)
{
    if (action != "up" && action != "down") self jinx_ui_sound();
    if (action == "close")
    {
        self jinx_close();
        return;
    }
    if (action == "back")
    {
        if (self.jinx_screen == "main")
            self jinx_close();
        else
            self jinx_back();
        return;
    }
    if (action == "select")
    {
        if (self.jinx_screen == "main")
        {
            self.jinx_category = level.jinx_main_order[self.jinx_cursor];
            if (!(self isHost()) && self.jinx_category != 0 && self.jinx_category != 6 && self.jinx_category != 7)
            { self jinx_notice("Host-only category. Your access covers Self, Weapons and Menu Settings."); return; }
            self.jinx_return_depth = 0;
            self.jinx_screen = "category";
            self jinx_render(false);
        }
        else
        {
            cursor = self.jinx_subcursor[self.jinx_category];
            if (cursor == 0)
                self jinx_back();
            else
            {
                links = level.jinx_links[self.jinx_category];
                target = links[cursor - 1];
                if (target >= 0)
                {
                    if (!(self isHost()) && !(self jinx_guest_allowed(self.jinx_category, level.jinx_options[self.jinx_category][cursor - 1])))
                    { self jinx_notice("Host-only action."); return; }
                    self.jinx_return_stack[self.jinx_return_depth] = self.jinx_category;
                    self.jinx_return_depth++;
                    self.jinx_category = target;
                    self jinx_render(false);
                }
                else
                {
                    options = level.jinx_options[self.jinx_category];
                    self jinx_dispatch(self.jinx_category, options[cursor - 1], cursor - 1);
                }
            }
        }
        return;
    }
    if (self.jinx_screen == "main")
    {
        old_cursor = self.jinx_cursor;
        step = 0;
        if (action == "up") step = -1;
        else if (action == "down") step = 1;
        else if (action == "previous_page") step = -8;
        else if (action == "next_page") step = 8;
        self.jinx_cursor = jinx_wrap(old_cursor + step, level.jinx_categories.size);
        animate = (step == 1 || step == -1) && self.jinx_cursor == old_cursor + step;
        self jinx_render(animate);
        return;
    }
    options = level.jinx_options[self.jinx_category];
    old_cursor = self.jinx_subcursor[self.jinx_category];
    cursor = old_cursor;
    if (action == "up") cursor--;
    else if (action == "down") cursor++;
    else if (action == "previous_page" || action == "next_page")
    {
        pages = jinx_page(options.size) + 1;
        page = jinx_page(cursor);
        if (action == "previous_page") page--;
        else page++;
        page = jinx_wrap(page, pages);
        slot = 0;
        if (cursor > 0) slot = (cursor - 1) % 16;
        cursor = page * 16 + slot + 1;
        if (cursor > options.size) cursor = options.size;
    }
    cursor = jinx_wrap(cursor, options.size + 1);
    self.jinx_subcursor[self.jinx_category] = cursor;
    animate = (action == "up" || action == "down") && jinx_page(cursor) == jinx_page(old_cursor);
    if (cursor != old_cursor + 1 && cursor != old_cursor - 1) animate = false;
    self jinx_render(animate);
}

jinx_back()
{
    if (self.jinx_return_depth > 0)
    {
        self.jinx_return_depth--;
        self.jinx_category = self.jinx_return_stack[self.jinx_return_depth];
    }
    else
        self.jinx_screen = "main";
    self jinx_render(false);
}

jinx_wrap(value, count)
{
    while (value < 0) value += count;
    while (value >= count) value -= count;
    return value;
}

// Logical cursor 0 is Back. Cursors 1..16 are page 1, 17..32 page 2.
jinx_page(cursor)
{
    page = 0;
    while (cursor > 16)
    {
        cursor -= 16;
        page++;
    }
    return page;
}

jinx_open_menu()
{
    if (self.jinx_open || level.jinx_phase1_ended || !(self jinx_has_menu()))
        return;
    self jinx_intro_clear();
    self jinx_minimap_destroy();
    self jinx_message_clear();
    self jinx_health_destroy();
    self jinx_practice_hud_destroy();
    self jinx_esp_destroy();
    self.jinx_notice_until = undefined;
    self.jinx_screen = "main";
    self.jinx_return_depth = 0;
    self.jinx_hud = [];
    self.jinx_open = true;
    self.jinx_menu_vision = false;
    if (!self isRemoteControlling() && !self isInVehicle())
    {
        self.jinx_menu_vision = true;
        self useServerVisionSet(true);
        self setVisionSetForPlayer("mpIntro", 1);
    }
    self jinx_menu_movement();
    self jinx_ui_sound();
    self jinx_build_hud();
    self jinx_render(false);
    // Capture actual element handles so disconnect cleanup does not depend on self.
    self thread jinx_disconnect_hud(self.jinx_hud);
}

jinx_close()
{
    self notify("jinx_ui_closed");
    if (isDefined(self.jinx_hud))
    {
        for (i = 0; i < self.jinx_hud.size; i++)
        {
            if (isDefined(self.jinx_hud[i]))
                self.jinx_hud[i] destroy();
        }
    }
    self.jinx_hud = [];
    self.jinx_open = false;
    if (isDefined(self.jinx_menu_vision) && self.jinx_menu_vision)
    {
        self.jinx_menu_vision = false;
        keepVision = isDefined(self.jinx_crazy_vision) && self.jinx_crazy_vision;
        self useServerVisionSet(keepVision);
        if (keepVision) self setVisionSetForPlayer("mpIntro", 1);
    }
    if (isDefined(self.jinx_menu_blur) && self.jinx_menu_blur) { self setBlur(0, 0.15); self.jinx_menu_blur = false; }
    if (isDefined(self.jinx_owns_freeze) && self.jinx_owns_freeze)
    {
        self freezeControls(false);
        self.jinx_owns_freeze = false;
    }
}

jinx_disconnect_hud(elements)
{
    self endon("jinx_ui_closed");
    self waittill("disconnect");
    for (i = 0; i < elements.size; i++)
    {
        if (isDefined(elements[i]))
            elements[i] destroy();
    }
}

// All positions share CENTER as the virtual-screen reference.
// Raw reference geometry is transformed to the right by default in jinx_apply_layout().
// 160 x 358 units, with all 17 rows visible. No text scale below 1 is allowed.
jinx_build_hud()
{
    red = jinx_color(self.jinx_settings["color1"]);
    white = jinx_color(self.jinx_settings["textcolor"]);
    gray = (0.78, 0.78, 0.78);
    self.jinx_x = -305;
    self.jinx_width = self jinx_panel_width();
    self.jinx_first_row = -123;
    self.jinx_row_step = 14;
    if (self.jinx_settings["design"] == 2)
    { self.jinx_first_row = -166; self.jinx_row_step = 18; }
    x = self.jinx_x;
    w = self.jinx_width;

    // Two nested rectangles replace five panel pieces, saving three HUD slots.
    // The inset is opaque: the original 95%-opaque background is approximated
    // with an opaque selected color so the red backplate cannot bleed through.
    self jinx_box(x, -225, w, 358, red, 1, 10);
    bg = jinx_background(self.jinx_settings["background"]);
    self jinx_box(x + 1, -224, w - 2, 356, bg, 1, 11);
    self jinx_text("JINX", 3.8 - self.jinx_settings["logo"] * 0.5, "CENTER", x + w / 2, -202, red);
    self jinx_text("MOD MENU", 1.7, "CENTER", x + w / 2, -176, white);
    self jinx_text("PLUTONIUM BO2 | PRIVATE MATCH", 1, "CENTER", x + w / 2, -158, gray);
    self.jinx_heading = self jinx_text("by Jinx", 1, "CENTER", x + w / 2, -145, red);
    self jinx_box(x + 1, -136, w - 2, 1, red, 1, 12);

    // Three nested pieces replace five selector pieces, saving two HUD slots.
    // The black inset masks the solid red backplate. The burgundy overlay
    // remains translucent; all three pieces move together below the text.
    // Native white is tinted only, never replaced on disk.
    sx = x + 7;
    sy = self.jinx_first_row - 7;
    sw = w - 17;
    self.jinx_selection_parts = [];
    self.jinx_selection_offsets = [];
    self.jinx_selection_parts[0] = self jinx_box(sx, sy, sw, 14, jinx_color(self.jinx_settings["color2"]), 1, 13);
    self.jinx_selection_offsets[0] = 0;
    self.jinx_selection_parts[1] = self jinx_box(sx + 1, sy + 1, sw - 2, 12, (0.005, 0.005, 0.005), 1, 14);
    self.jinx_selection_offsets[1] = 1;
    self.jinx_selection_parts[2] = self jinx_box(sx + 1, sy + 1, sw - 2, 12, jinx_color(self.jinx_settings["color2"]), 0.10 + self.jinx_settings["fill"] * 0.15, 15);
    self.jinx_selection_offsets[2] = 1;
    self.jinx_rows = [];
    for (i = 0; i < level.jinx_categories.size; i++)
    {
        row_y = self.jinx_first_row + i * self.jinx_row_step;
        self.jinx_rows[i] = self jinx_text("", 1.15, "LEFT", x + 13, row_y, white);
    }
    self.jinx_indicator = self jinx_text(">", 1, "RIGHT", x + w - 17, self.jinx_first_row, white);
    self.jinx_track = self jinx_box(x + w - 5, self.jinx_first_row - 7, 1, (level.jinx_categories.size - 1) * self.jinx_row_step + 14, bg, 1, 12);
    self.jinx_thumb = self jinx_box(x + w - 5, self.jinx_first_row - 7, 1, 14, red, 1, 14);
    self.jinx_status = self jinx_text("", 1, "CENTER", x + w / 2, 119, gray);
    // Keep help outside the panel so it cannot cover the list or counter.
    self.jinx_help = self jinx_text("Scroll: [{+speed_throw}] / [{+attack}]\nSelect: [{+activate}]\nBack / Close: [{+melee}]", 1, "TOP_LEFT", x + 2, 144, white);
    self jinx_apply_layout();
}

jinx_render(animate)
{
    if (!self.jinx_open) return;
    self jinx_render_help();
    self.jinx_track.alpha = self.jinx_settings["scrollbar"];
    self.jinx_thumb.alpha = self.jinx_settings["scrollbar"];
    if (self.jinx_screen == "main")
    {
        self.jinx_heading jinx_set_text("by Jinx");
        self.jinx_status jinx_set_text("MAIN MENU  " + (self.jinx_cursor + 1) + "/17  |  1/1");
        for (i = 0; i < 17; i++)
        {
            self.jinx_rows[i] jinx_set_text(level.jinx_categories[level.jinx_main_order[i]]);
            self.jinx_rows[i].color = jinx_color(self.jinx_settings["textcolor"]);
            self.jinx_rows[i].fontScale = (1.0 + self.jinx_settings["rowtext"] * 0.1) * (self jinx_ui_scale());
            if (self.jinx_rows[i].fontScale < 1) self.jinx_rows[i].fontScale = 1;
            self.jinx_rows[i].alpha = 1;
        }
        self jinx_move_selection(self.jinx_first_row - 7 + self.jinx_cursor * self.jinx_row_step, animate);
        return;
    }
    options = level.jinx_options[self.jinx_category];
    cursor = self.jinx_subcursor[self.jinx_category];
    page = jinx_page(cursor);
    pages = jinx_page(options.size) + 1;
    self.jinx_heading jinx_set_text(level.jinx_titles[self.jinx_category]);
    self.jinx_status jinx_set_text("OPTION  " + cursor + "/" + options.size + "  |  " + (page + 1) + "/" + pages);
    // Compute the final label first. Never clear and refill unchanged rows.
    for (i = 0; i < 17; i++)
    {
        label = "";
        arrow = 0;
        color = jinx_color(self.jinx_settings["textcolor"]);
        if (i == 0)
            label = "< Back";
        else
        {
            index = page * 16 + i - 1;
            if (index < options.size)
            {
                label = options[index];
                arrow = 1;
            }
            else if (options.size == 0 && i == 3)
            {
                label = "Options pending definition.";
                color = (0.7, 0.7, 0.7);
            }
        }
        self.jinx_rows[i] jinx_set_text(label);
        self.jinx_rows[i].color = color;
        self.jinx_rows[i].fontScale = 1.0 + self.jinx_settings["rowtext"] * 0.1;
        self.jinx_rows[i].alpha = 1;
    }
    row = 0;
    if (cursor > 0) row = (cursor - 1) % 16 + 1;
    self jinx_move_selection(self.jinx_first_row - 7 + row * self.jinx_row_step, animate);
    // Thumb tracks the logical list, including options on subsequent pages.
    thumb_y = self.jinx_first_row - 7;
    if (options.size > 0) thumb_y += 224.0 * cursor / options.size;
    self.jinx_thumb.y = thumb_y * (self jinx_ui_scale());
}

jinx_move_selection(y, animate)
{
    duration = 0.001;
    if (animate && self.jinx_settings["smooth"])
        duration = self jinx_selection_seconds();
    // No waits between pieces: outline, inset, fill and thumb move in the same frame.
    for (i = 0; i < self.jinx_selection_parts.size; i++)
    {
        part = self.jinx_selection_parts[i];
        part moveOverTime(duration);
        part.y = (y + self.jinx_selection_offsets[i]) * (self jinx_ui_scale());
    }
    self.jinx_thumb moveOverTime(duration);
    self.jinx_thumb.y = y * (self jinx_ui_scale());
    // One shared right-aligned state follows the selected row.
    self.jinx_indicator.alpha = 1;
    self.jinx_indicator moveOverTime(duration);
    self.jinx_indicator.y = (y + 7) * (self jinx_ui_scale());
    indicatorText = ">";
    if (self.jinx_screen != "main")
    {
        selectedIndex = self.jinx_subcursor[self.jinx_category] - 1;
        if (selectedIndex < 0) indicatorText = "";
        else
        {
            selectedName = level.jinx_options[self.jinx_category][selectedIndex];
            indicatorText = self jinx_option_state(self.jinx_category, selectedName);
            if (level.jinx_links[self.jinx_category][selectedIndex] >= 0) indicatorText = ">";
        }
    }
    self.jinx_indicator jinx_set_text(indicatorText);
    if (self.jinx_settings["design"] == 2)
    {
        self.jinx_indicator.alpha = 0;
        self jinx_design_focus(y);
    }
}

jinx_track_hud(element)
{
    self.jinx_hud[self.jinx_hud.size] = element;
    // 32 menu elements total, split evenly to leave space for native HUD.
    element.archived = (self.jinx_hud.size > 16);
    element.hideWhenInMenu = true;
}

jinx_text(text, scale, align, x, y, color)
{
    // T6 can display huge text when fontScale is below 1.
    // Protect future labels, not just the currently affected subtitle/help.
    if (scale < 1)
        scale = 1;
    font = "objective";
    if (self.jinx_settings["font"]) font = "default";
    element = self createFontString(font, scale);
    element setPoint(align, "CENTER", x, y);
    element.color = color;
    element.alpha = 1;
    element.sort = 20;
    element jinx_set_text(text);
    self jinx_track_hud(element);
    return element;
}

jinx_box(x, y, width, height, color, alpha, sort)
{
    element = newClientHudElem(self);
    element.elemType = "icon";
    element.children = [];
    element setParent(level.uiParent);
    element setShader("white", width, height);
    element.width = width;
    element.height = height;
    element setPoint("TOP_LEFT", "CENTER", x, y);
    element.color = color;
    element.alpha = alpha;
    element.sort = sort;
    self jinx_track_hud(element);
    return element;
}

// Plutonium builtin, not a BO3/IW4x helper. Do not replace with setText:
// caching alone cannot prevent exhaustion from distinct catalog/counter strings.
// self is the HUD element. This cache dies with that element on close/death.
jinx_set_text(text)
{
    if (isDefined(self.jinx_cached_text) && self.jinx_cached_text == text)
        return;
    self setTextUnlimited(text);
    self.jinx_cached_text = text;
}

// ---- Phase 3: host-only effects and settings ---------------------------------
jinx_setup_player()
{
    self.jinx_fx = [];
    self.jinx_perks_owned = [];
    self.jinx_health_elements = [];
    self.jinx_ammo_time = 0;
    self.jinx_health_time = 0;
    self.jinx_esp_elements = [];
    self.jinx_esp_time = 0;
    self.jinx_noclip_key_down = true;
    self.jinx_jump_boost_left = 0;
    self.jinx_jump_launch_ready = false;
    self.jinx_jump_request_time = -10000;
    self.jinx_jump_previous = false;
    self.jinx_air_jumps = 0;
    self.jinx_was_grounded = false;
    self.jinx_fov = 0;
    self.jinx_camo = [];
    self.jinx_intro = [];
    self.jinx_object_height = 0;
    self.jinx_insta_bind = "OFF";
    self.jinx_insta_down = true;
    self.jinx_c4_use_down = true;
    self.jinx_c4_last_press = -10000;
    self jinx_practice_init();
    self jinx_message_init();
    self jinx_minimap_init();
    self.jinx_settings = [];
    self jinx_settings_defaults();
}

jinx_settings_defaults()
{
    self.jinx_settings["position"] = 2; // Right, as requested.
    self.jinx_settings["size"] = 0;
    self.jinx_settings["font"] = 0;
    self.jinx_settings["color1"] = 3;
    self.jinx_settings["color2"] = 3;
    self.jinx_settings["background"] = 0;
    self.jinx_settings["scrollbar"] = 1;
    self.jinx_settings["smooth"] = 1;
    self.jinx_settings["sound"] = 0;
    self.jinx_settings["openkey"] = 0;
    self.jinx_settings["closekey"] = 0;
    self.jinx_settings["move_menu"] = 0;
    self.jinx_settings["move_countdown"] = 1;
    self.jinx_settings["width"] = 0;
    self.jinx_settings["textcolor"] = 11;
    self.jinx_settings["fill"] = 2;
    self.jinx_settings["logo"] = 0;
    self.jinx_settings["rowtext"] = 0;
    self.jinx_settings["help"] = 1;
    self.jinx_settings["selspeed"] = 1;
    self.jinx_settings["design"] = 0;
}

jinx_enabled(name)
{
    return isDefined(self.jinx_fx[name]) && self.jinx_fx[name];
}

jinx_private_host()
{
    return self isHost() && isAlive(self) && !level.jinx_phase1_ended;
}

jinx_notice(message)
{
    if (self.jinx_open)
    {
        self.jinx_notice_text = message;
        self.jinx_help jinx_set_text(message);
        self.jinx_notice_until = getTime() + 3500;
    }
    else
        self iprintln("^1JINX: ^7" + message);
}

jinx_toggle_label(name)
{
    if (self jinx_enabled(name)) return "^2ON";
    return "^1OFF";
}

jinx_effect_key(name)
{
    switch(name)
    {
        case "God Mode": return "god";
        case "Infinite Ammo": return "ammo";
        case "Unlimited Tactical": return "tactical";
        case "Unlimited Lethal": return "lethal";
        case "Constant Radar": return "radar";
        case "Third Person": return "third";
        case "Noclip": return "noclip";
        case "Fast Reload": return "reload";
        case "Super Speed": return "speed";
        case "Low Gravity": return "gravity";
        case "High Jump": return "jump";
        case "Freeze Position": return "freeze";
        case "Invisible": return "invisible";
        case "Multi Jump": return "multi";
        case "Health Bar": return "health";
        case "No Spread": return "spread";
        case "Rapid Fire": return "rapid";
        case "No Fall Damage": return "nofall";
        case "Red Boxes (ESP)": return "esp";
    }
    return "";
}

jinx_option_state(category, name)
{
    if (jinx_unavailable_reason(name) != "") return "^8N/A";
    if (name == "Trickshot Killcam") { if (level.jinx_trickcam_on) return "^2NATIVE"; return "^1OFF"; }
    if (!(self isHost()) && !(self jinx_guest_allowed(category, name))) return "^8HOST";
    if (category == 14 || category == 15 || category == 16 || (category >= 58 && category <= 64))
        return self jinx_admin_state(category, name);
    if (name == "Left Gun" || name == "Gun on Left Side") return self jinx_toggle_label("leftgun");
    if (name == "Show FPS") return self jinx_toggle_label("showfps");
    if (name == "Restore ADS Zoom") return "RESET";
    if (name == "Perks Menu") return ">";
    if (category == 53) return "REMOVE";
    if (name == "Rainbow Gun") return self jinx_toggle_label("rainbowgun");
    if (name == "Matrix Aiming") return self jinx_toggle_label("matrix");
    if (name == "Give Random Camo" || name == "Drop Canswap") return "USE";
    if (name == "Trickshot Class" || name == "Bind Insta Swap To" || name == "Map Loader") return ">";
    if (name == "Object Height") return "" + self.jinx_object_height;
    if (category == 47) return ">";
    if (category == 51 || category == 52) return "EQUIP";
    if (category == 48) { if (self.jinx_insta_bind == name) return "^2SET"; return "USE"; }
    if (category == 50) { if (name == "Cancel") return "BACK"; return "INFO"; }
    if (category == 13 || category == 49) { if (name == "Reload Current Map") return "USE"; return "INFO"; }
    if (name == "Plant Bomb" || name == "Defuse Bomb" || name == "FFA Last" || name == "TDM Last") return "USE";
    if (category == 12 || category == 46) return "USE";
    if (category == 45) return "APPLY";
    if (category == 11) return jinx_spawn_state(name);
    if (category == 10) return self jinx_model_state(name);
    if (category == 9) return self jinx_fun_state(name);
    if (category == 8 || category == 43 || category == 44) return self jinx_game_state(category, name, 0);
    if (category == 5) return self jinx_lobby_state(name);
    if (category == 18) return "USE";
    if (category == 4) return self jinx_minimap_state(name);
    if (category == 3 || (category >= 34 && category <= 42) || (category >= 54 && category <= 57)) return self jinx_message_state(category, name);
    if (category == 1 || category == 2 || category == 33)
        return self jinx_practice_state(category, name);
    links = level.jinx_links[category];
    options = level.jinx_options[category];
    for (i = 0; i < options.size; i++)
        if (options[i] == name && links[i] >= 0) return ">";
    if (category == 0 || category == 7)
    {
        key = jinx_effect_key(name);
        if (key == "noclip" && self jinx_enabled(key))
        {
            if (isDefined(self.jinx_noclip_anchor)) return "FLY";
            return "READY";
        }
        if (key != "") return self jinx_toggle_label(key);
        if (name == "Player FOV")
        {
            if (self.jinx_fov == 0) return "DEF";
            return "" + self.jinx_fov;
        }
        if (name == "Change Class" || name == "Change Team" || name == "Default Weapon") return "USE";
    }
    if (category == 6)
    {
        switch(name)
        {
            case "Menu Design": return self jinx_design_name();
            case "Replay Welcome": return "PLAY";
            case "Menu Theme":
                if (self.jinx_settings["color1"] == 1 || self.jinx_settings["color1"] == 2) return "CUSTOM";
                return jinx_ui_color_name(self.jinx_settings["color1"]);
            case "Menu Position":
                if (self.jinx_settings["position"] == 0) return "LEFT";
                if (self.jinx_settings["position"] == 1) return "MID";
                return "RIGHT";
            case "Menu Size": return "" + (self jinx_ui_scale());
            case "Menu Font":
                if (self.jinx_settings["font"] == 0) return "OBJ";
                return "DEF";
            case "Menu Color 1": return jinx_ui_color_name(self.jinx_settings["color1"]);
            case "Menu Color 2": return jinx_ui_color_name(self.jinx_settings["color2"]);
            case "Background": return jinx_background_name(self.jinx_settings["background"]);
            case "Logo Size": return "" + (3.8 - self.jinx_settings["logo"] * 0.5);
            case "Row Text Size": return "" + (1.0 + self.jinx_settings["rowtext"] * 0.1);
            case "Show Controls":
                if (self.jinx_settings["help"]) return "^2ON";
                return "^1OFF";
            case "Selection Speed": return "" + (self jinx_selection_seconds()) + "s";
            case "Panel Shape": return self jinx_panel_shape();
            case "Panel Width": return "" + (self jinx_panel_width());
            case "Text Color": return jinx_ui_color_name(self.jinx_settings["textcolor"]);
            case "Selection Opacity": return "" + (10 + self.jinx_settings["fill"] * 15) + "%";
            case "Scrollbar":
                if (self.jinx_settings["scrollbar"]) return "^2ON";
                return "^1OFF";
            case "Scroll Style":
                if (self.jinx_settings["smooth"]) return "SMOOTH";
                return "SNAP";
            case "Menu Sound":
                if (self.jinx_settings["sound"]) return "^2ON";
                return "^1OFF";
            case "Move With Menu":
                if (self.jinx_settings["move_menu"]) return "^2ON";
                return "^1OFF";
            case "Move During Countdown":
                if (self.jinx_settings["move_countdown"]) return "^2ON";
                return "^1OFF";
            case "Open Key":
                if (self.jinx_settings["openkey"]) return "ADS+USE";
                return "ADS+MELEE";
            case "Close Key":
                if (self.jinx_settings["closekey"]) return "ADS+MELEE";
                return "MELEE";
            case "Reset Settings": return "USE";
            case "Save Settings": return "SESSION";
        }
    }
    if (category == 17)
    {
        if (isDefined(level.jinx_camo_ids[name])) return "APPLY";
    }
    if (category == 20 || category == 21 || (category >= 22 && category <= 29)) return "GIVE";
    if (category == 32) return "APPLY";
    if (category == 30 || category == 31) return "USE";
    if (category == 0 || category == 7)
    {
        if (name == "Respawn" || name == "Upgrade Weapon") return "USE";
        attachment = jinx_named_attachment(name);
        if (attachment != "")
        {
            parts = strTok(self getCurrentWeapon(), "+");
            if (jinx_in_list(parts, attachment)) return "^2ON";
            return "^1OFF";
        }
    }
    return "^8--";
}

jinx_dispatch(category, name, index)
{
    if (!(self isHost())) { self jinx_guest_action(category, name, index); return; }
    reason = jinx_unavailable_reason(name);
    if (reason != "") { self jinx_notice(reason); return; }
    if (category == 14 || category == 15 || category == 16 || (category >= 58 && category <= 64))
    { self jinx_admin_action(category, name, index); return; }
    if (self jinx_extended_dispatch(category, name, index)) return;
    if (category == 45) { if (self jinx_message_allowed()) self jinx_object_form(name); return; }
    if (category == 12 || category == 46)
    { if (self jinx_message_allowed()) self jinx_teleport_action(category, name, index); return; }
    if (category == 11)
    {
        if (self jinx_message_allowed()) self jinx_spawn_action(name);
        return;
    }
    if (category == 10)
    {
        if (self jinx_message_allowed()) self jinx_model_action(name);
        return;
    }
    if (category == 9)
    {
        if (self jinx_message_allowed()) self jinx_fun_action(name);
        return;
    }
    if (category == 8 || category == 43 || category == 44)
    {
        if (self jinx_message_allowed()) self jinx_game_action(category, name, index);
        return;
    }
    if (category == 5 || category == 18)
    {
        if (!(self jinx_message_allowed())) { self jinx_action_blocked(); return; }
        if (category == 18) self jinx_practice_bot_action(name);
        else self jinx_lobby_action(name);
        return;
    }
    if (category == 4)
    {
        self jinx_minimap_action(name);
        return;
    }
    if (category == 3 || (category >= 34 && category <= 42) || (category >= 54 && category <= 57))
    {
        self jinx_message_action(category, name, index);
        return;
    }
    if (!(self jinx_private_host())) return;
    if (category == 1 || category == 2 || category == 33)
    {
        self jinx_practice_action(category, name);
        return;
    }
    if (category == 0 || category == 7)
    {
        key = jinx_effect_key(name);
        if (key != "")
        {
            self jinx_toggle_effect(key);
            self jinx_render(false);
            if (key == "noclip" && self jinx_enabled(key))
                self jinx_notice("Noclip armed. Lethal: flight ON/OFF.\nIn flight: Fire forward / ADS reverse.");
            else if (key == "rapid" && self jinx_enabled(key))
                self jinx_notice("Rapid Fire: weapon-rate perk enabled.\nBolt / pump / semi-auto limits can remain.");
            else if (key == "spread" && self jinx_enabled(key))
                self jinx_notice("No Spread: tight hip-fire bullet grouping.\nThis does not remove weapon recoil.");
            else if (key == "jump" && self jinx_enabled(key))
                self jinx_notice("High Jump: stronger takeoff impulse.\nUse open sky; ceilings still block movement.");
            else if (key == "radar" && self jinx_enabled(key))
                self jinx_notice("Constant Radar persists through respawn.\nTeam modes share VSAT with your team; normal map zoom.");
            else if (key == "gravity")
                self jinx_notice("Low Gravity: affects the whole lobby.\nRestored when OFF or on death.");
            return;
        }
        if (name == "Player FOV")
        {
            if (self.jinx_fov == 0) self.jinx_fov = 80;
            else if (self.jinx_fov < 120) self.jinx_fov += 10;
            else self.jinx_fov = 0;
            if (self.jinx_fov == 0) self resetFov();
            else self setClientFov(self.jinx_fov);
            self jinx_render(false);
            return;
        }
        if (name == "Respawn")
        {
            self thread jinx_respawn_now();
            return;
        }
        attachment = jinx_named_attachment(name);
        if (attachment != "")
        {
            self jinx_attachment(attachment);
            self jinx_render(false);
            return;
        }
        if (name == "Upgrade Weapon")
        {
            self jinx_upgrade();
            return;
        }
        if (name == "Change Team")
        {
            target = "menu_changeclass";
            if (name == "Change Team") target = "menu_team";
            if (isDefined(game[target]))
            {
                self jinx_stop_effects();
                self jinx_close();
                self openMenu(game[target]);
            }
            else self jinx_notice("Game menu unavailable in this mode.");
            return;
        }
        if (name == "Default Weapon")
        {
            self jinx_give_gun("defaultweapon_mp");
            return;
        }
    }
    if (category == 6)
    {
        self jinx_setting_action(name);
        return;
    }
    if (category == 17)
    {
        self jinx_apply_camo(name);
        return;
    }
    if (category >= 22 && category <= 29)
    {
        self jinx_give_gun(level.jinx_weapon_groups[category][index]);
        return;
    }
    if (category == 20)
    {
        self jinx_give_kit(index);
        return;
    }
    if (category == 30) { self jinx_weapon_extra(name); return; }
    if (category == 31) { self jinx_attachment(level.jinx_attachment_ids[index]); return; }
    if (category == 32) { self jinx_change_class(index); return; }
    if (category == 21)
    {
        if (self isRemoteControlling() || self isInVehicle() || isDefined(self.jinx_noclip_anchor))
        {
            self jinx_notice("Exit Noclip / vehicle / remote control first.");
            return;
        }
        if (!isDefined(maps\mp\killstreaks\_killstreaks::getkillstreakfromweapon(level.jinx_streaks[index])))
        {
            self jinx_notice("This streak is not registered in this mode.");
            return;
        }
        self maps\mp\killstreaks\_killstreaks::givekillstreakweapon(level.jinx_streaks[index], 1);
        self jinx_notice("Streak granted: " + name);
        return;
    }
    if (name == "No Recoil") self jinx_notice("No verified T6 recoil-scale native.\nLinked-player workaround can immobilize you.");
    else self jinx_notice("No verified implementation for this option in this build.");
}

jinx_toggle_effect(key)
{
    if (key == "speed") self jinx_lobby_release_speed();
    active = !(self jinx_enabled(key));
    if (key == "tactical" && active)
    {
        if (!isDefined(self.grenadetypesecondary) || !(self hasWeapon(self.grenadetypesecondary)))
        {
            self jinx_notice("Equip tactical equipment in your class.");
            return;
        }
    }
    if (key == "lethal" && active)
    {
        if (!isDefined(self.grenadetypeprimary) || !(self hasWeapon(self.grenadetypeprimary)))
        {
            self jinx_notice("Equip lethal equipment in your class.");
            return;
        }
    }
    if (key == "noclip")
    {
        // Arming does not link, freeze, grant god mode, or disable weapons.
        self.jinx_noclip_key_down = true;
        if (!active) self jinx_end_noclip();
    }
    if (key == "freeze" && active)
    {
        if (self jinx_enabled("noclip")) self jinx_toggle_effect("noclip");
        self.jinx_freeze_origin = self.origin;
    }
    if (key == "speed")
    {
        if (active)
        {
            self.jinx_old_speed = self getMoveSpeedScale();
            self setMoveSpeedScale(self.jinx_old_speed * 2.25);
        }
        else if (isDefined(self.jinx_old_speed)) self setMoveSpeedScale(self.jinx_old_speed);
    }
    if (key == "gravity")
    {
        if (active)
        {
            if (isDefined(level.jinx_game_gravity) && level.jinx_game_gravity != 0) jinx_restore_gravity();
            level.jinx_old_gravity = maps\mp\_utility::getdvarfloatdefault("bg_gravity", 800);
            level.jinx_gravity_changed = true;
            level.jinx_old_jump_slowdown = maps\mp\_utility::getdvarfloatdefault("jump_slowdownEnable", 1);
            setDvar("bg_gravity", 400);
            setDvar("jump_slowdownEnable", 0);
        }
        else jinx_restore_gravity();
    }
    if (key == "reload")
    {
        if (active)
        {
            self.jinx_perks_owned["specialty_fastreload"] = !(self hasPerk("specialty_fastreload"));
            self setPerk("specialty_fastreload");
        }
        else if (isDefined(self.jinx_perks_owned["specialty_fastreload"]) && self.jinx_perks_owned["specialty_fastreload"])
            self unsetPerk("specialty_fastreload");
    }
    if (key == "nofall")
    {
        if (active)
        {
            self.jinx_perks_owned["specialty_fallheight"] = !(self hasPerk("specialty_fallheight"));
            self setPerk("specialty_fallheight");
        }
        else if (isDefined(self.jinx_perks_owned["specialty_fallheight"]) && self.jinx_perks_owned["specialty_fallheight"])
            self unsetPerk("specialty_fallheight");
    }
    if (key == "esp" && !active) self jinx_esp_destroy();
    if (key == "jump")
    {
        self.jinx_jump_boost_left = 0;
        self.jinx_jump_launch_ready = self isOnGround();
        self.jinx_was_grounded = self isOnGround();
    }
    if (key == "rapid")
    {
        if (active)
        {
            jinx_tune("perk_weapRateMultiplier", 0.25, 0.75);
            self jinx_owned_perk("specialty_rof", true);
        }
        else
        {
            self jinx_owned_perk("specialty_rof", false);
            jinx_restore_tune("perk_weapRateMultiplier");
        }
    }
    if (key == "spread")
    {
        if (active)
        {
            jinx_tune("perk_weapSpreadMultiplier", 0.001, 0.65);
            self jinx_owned_perk("specialty_bulletaccuracy", true);
            self setSpreadOverride(0);
        }
        else
        {
            self resetSpreadOverride();
            self jinx_owned_perk("specialty_bulletaccuracy", false);
            jinx_restore_tune("perk_weapSpreadMultiplier");
        }
    }
    if (key == "third") self setClientThirdPerson(active);
    if (key == "invisible")
    {
        if (active) self hide();
        else self show();
    }
    if (key == "radar")
    {
        self.jinx_radar_requested = active;
        if (active)
        {
            self.jinx_had_satellite = 0;
            if (isDefined(self.hasSatellite)) self.jinx_had_satellite = self.hasSatellite;
        }
        else self jinx_restore_radar();
    }
    self.jinx_fx[key] = active;
    if (key == "god")
    {
        if (self jinx_enabled("god") || isDefined(self.jinx_noclip_anchor) || (isDefined(self.jinx_admin_god) && self.jinx_admin_god)) self enableInvulnerability();
        else self disableInvulnerability();
    }
    if (key == "health" && !active) self jinx_health_destroy();
}

jinx_end_noclip()
{
    self notify("jinx_anchor_removed");
    if (isDefined(self.jinx_noclip_anchor))
    {
        if (!(self jinx_enabled("god"))) self disableInvulnerability();
        self unlink();
        self.jinx_noclip_anchor delete();
        self.jinx_noclip_anchor = undefined;
        self enableWeapons();
        self enableOffhandWeapons();
    }
}

jinx_anchor_disconnect(anchor)
{
    self endon("jinx_anchor_removed");
    self waittill("disconnect");
    if (isDefined(anchor)) anchor delete();
}

jinx_restore_gravity()
{
    if (isDefined(level.jinx_gravity_changed) && level.jinx_gravity_changed)
    {
        setDvar("bg_gravity", level.jinx_old_gravity);
        if (isDefined(level.jinx_old_jump_slowdown)) setDvar("jump_slowdownEnable", level.jinx_old_jump_slowdown);
        level.jinx_gravity_changed = false;
        level.jinx_game_gravity = 0;
    }
}

jinx_host_disconnect()
{
    self waittill("disconnect");
    level.jinx_access_closed = true;
    jinx_admin_revoke_everyone();
    jinx_extended_global_cleanup();
    jinx_fun_cleanup();
    jinx_release_practice_bots();
    jinx_restore_gravity();
    jinx_restore_weapon_tuning();
    jinx_lobby_cleanup();
    jinx_game_cleanup();
    jinx_spawn_clear();
    jinx_radar_global_restore();
}

jinx_restore_radar()
{
    self jinx_radar_release();
    if (isDefined(self.jinx_had_satellite)) self.hasSatellite = self.jinx_had_satellite;
    radar = 0;
    number = self getEntityNumber();
    if (isDefined(level.activeuavs) && isDefined(level.activeuavs[number])) radar += level.activeuavs[number];
    if (isDefined(level.activesatellites) && isDefined(level.activesatellites[number])) radar += level.activesatellites[number];
    self setClientUIVisibilityFlag("radar_client", radar > 0);
    forced = false;
    if (isDefined(level.forceradar)) forced = level.forceradar;
    self setClientUIVisibilityFlag("g_compassShowEnemies", forced);
}

jinx_stop_effects()
{
    if (!(self isHost())) { self jinx_guest_clear(); return; }
    if (!isDefined(self.jinx_fx)) return;
    self jinx_admin_clear();
    if (self isHost()) self jinx_extended_cleanup();
    if (self isHost()) self jinx_model_clear(false);
    if (self isHost()) jinx_fun_cleanup();
    self jinx_lobby_release_player();
    self jinx_game_perks_clear();
    if (isDefined(self.jinx_crazy_vision) && self.jinx_crazy_vision) self useServerVisionSet(0);
    self.jinx_crazy_vision = false;
    self jinx_minimap_destroy();
    self.jinx_map_on = false;
    self.jinx_map_info_on = false;
    self jinx_message_stop();
    self jinx_practice_stop();
    if (self jinx_enabled("noclip")) self jinx_end_noclip();
    if (self jinx_enabled("god")) self disableInvulnerability();
    if (self jinx_enabled("invisible")) self show();
    if (self jinx_enabled("third")) self setClientThirdPerson(0);
    if (self jinx_enabled("speed") && isDefined(self.jinx_old_speed)) self setMoveSpeedScale(self.jinx_old_speed);
    if (self jinx_enabled("spread"))
    {
        self resetSpreadOverride();
        self jinx_owned_perk("specialty_bulletaccuracy", false);
        jinx_restore_tune("perk_weapSpreadMultiplier");
    }
    if (self jinx_enabled("rapid"))
    {
        self jinx_owned_perk("specialty_rof", false);
        jinx_restore_tune("perk_weapRateMultiplier");
    }
    if (self jinx_enabled("radar")) self jinx_restore_radar();
    if (self jinx_enabled("reload") && isDefined(self.jinx_perks_owned["specialty_fastreload"]) && self.jinx_perks_owned["specialty_fastreload"])
        self unsetPerk("specialty_fastreload");
    if (self jinx_enabled("gravity")) jinx_restore_gravity();
    if (self jinx_enabled("nofall") && isDefined(self.jinx_perks_owned["specialty_fallheight"]) && self.jinx_perks_owned["specialty_fallheight"])
        self unsetPerk("specialty_fallheight");
    self jinx_esp_destroy();
    if (self.jinx_fov != 0) self resetFov();
    self.jinx_fov = 0;
    self.jinx_fx = [];
    self.jinx_perks_owned = [];
    self.jinx_noclip_key_down = true;
    self.jinx_jump_boost_left = 0;
    self.jinx_jump_launch_ready = false;
    self.jinx_jump_request_time = -10000;
    self.jinx_jump_previous = false;
    self.jinx_air_jumps = 0;
    self.jinx_was_grounded = false;
    self jinx_health_destroy();
}

// Called by the existing input poll; no new forever-thread for every toggle.
jinx_effect_tick()
{
    now = getTime();
    self jinx_extended_tick(now);
    self jinx_countdown_movement();
    if (self.jinx_open) self jinx_menu_movement();
    self jinx_fun_visual_tick(now);
    self jinx_model_tick(now);
    self jinx_spawn_tick(now);
    self jinx_message_tick(now);
    self jinx_minimap_tick(now);
    if (self.jinx_open && isDefined(self.jinx_notice_until) && now >= self.jinx_notice_until)
    {
        self.jinx_notice_until = undefined;
        self jinx_render(false);
    }
    if (now >= self.jinx_ammo_time)
    {
        self.jinx_ammo_time = now + 200;
        if (self jinx_enabled("spread")) self setSpreadOverride(0);
        if (self jinx_enabled("rapid") && !(self hasPerk("specialty_rof"))) self setPerk("specialty_rof");
        if (self jinx_enabled("ammo") && level.jinx_custom_mode == "")
        {
            weapons = self getWeaponsListPrimaries();
            for (i = 0; i < weapons.size; i++)
            {
                self giveMaxAmmo(weapons[i]);
                size = weaponClipSize(weapons[i]);
                if (size > 0) self setWeaponAmmoClip(weapons[i], size);
            }
        }
        if (self jinx_enabled("tactical") && level.jinx_custom_mode == "" && isDefined(self.grenadetypesecondary))
            self setWeaponAmmoClip(self.grenadetypesecondary, 2);
        if (self jinx_enabled("lethal") && level.jinx_custom_mode == "" && isDefined(self.grenadetypeprimary))
            self setWeaponAmmoClip(self.grenadetypeprimary, 2);
        if (self jinx_enabled("radar"))
        {
            self setClientUIVisibilityFlag("radar_client", 1);
            self setClientUIVisibilityFlag("g_compassShowEnemies", 1);
            self.hasSatellite = 1;
            self jinx_radar_attach();
        }
    }
    if (self jinx_enabled("health") && !self.jinx_open && now >= self.jinx_health_time)
    {
        self.jinx_health_time = now + 100;
        self jinx_health_update();
    }
    if (self.jinx_open)
    {
        self.jinx_noclip_key_down = true;
        self.jinx_carry_use_down = true;
        self.jinx_jump_boost_left = 0;
        self.jinx_position_down = true;
        self.jinx_position_up = true;
        return;
    }
    self jinx_position_keys_tick();
    self jinx_noclip_key_tick();
    if (self jinx_enabled("esp") && now >= self.jinx_esp_time)
    {
        self.jinx_esp_time = now + 100;
        self jinx_esp_update();
    }
    if (self jinx_enabled("noclip") && isDefined(self.jinx_noclip_anchor))
    {
        self jinx_practice_hud_destroy();
        dir = anglesToForward(self getPlayerAngles());
        step = 0;
        if (self attackButtonPressed()) step = 60;
        else if (self adsButtonPressed() && !(self meleeButtonPressed())) step = -60;
        if (self jumpButtonPressed()) step *= 2;
        if (step != 0) self.jinx_noclip_anchor.origin += (dir[0] * step, dir[1] * step, dir[2] * step);
        return;
    }
    if (self jinx_enabled("freeze"))
    {
        self jinx_practice_hud_destroy();
        self setOrigin(self.jinx_freeze_origin);
        self setVelocity((0, 0, 0));
        return;
    }
    self jinx_jump_tick(now);
    self jinx_fun_tick();
    self jinx_practice_tick(now);

}

jinx_health_update()
{
    if (self.jinx_health_elements.size == 0)
    {
        for (i = 0; i < 2; i++)
        {
            hud = newClientHudElem(self);
            hud.horzAlign = "center";
            hud.vertAlign = "middle";
            hud.alignX = "left";
            hud.alignY = "top";
            hud.x = -90;
            hud.y = 185;
            hud.archived = false;
            hud.hideWhenInMenu = true;
            hud.sort = 10 + i;
            hud.alpha = 0.9;
            hud.color = (0.75, 0.025, 0.025);
            if (i == 1) hud.color = (0, 0.9, 0.15);
            hud setShader("white", 180, 10);
            self.jinx_health_elements[i] = hud;
        }
        self thread jinx_health_disconnect(self.jinx_health_elements);
    }
    maxhp = self.maxhealth;
    if (!isDefined(maxhp) || maxhp <= 0) maxhp = 100;
    ratio = self.health / (maxhp * 1.0);
    if (ratio < 0) ratio = 0;
    if (ratio > 1) ratio = 1;
    width = int(180 * ratio);
    if (width < 1) width = 1;
    self.jinx_health_elements[1] setShader("white", width, 10);
    self.jinx_health_elements[1].color = (1 - ratio, 0.9 * ratio, 0.1 * ratio);
    if (ratio == 0) self.jinx_health_elements[1].alpha = 0;
    else self.jinx_health_elements[1].alpha = 0.95;
}

jinx_health_destroy()
{
    self notify("jinx_health_removed");
    if (!isDefined(self.jinx_health_elements)) return;
    for (i = 0; i < self.jinx_health_elements.size; i++)
        if (isDefined(self.jinx_health_elements[i])) self.jinx_health_elements[i] destroy();
    self.jinx_health_elements = [];
}

jinx_health_disconnect(elements)
{
    self endon("jinx_health_removed");
    self waittill("disconnect");
    for (i = 0; i < elements.size; i++)
        if (isDefined(elements[i])) elements[i] destroy();
}

jinx_give_gun(weapon)
{
    if (self isRemoteControlling() || self isInVehicle())
    {
        self jinx_notice("Exit vehicle / remote control first.");
        return;
    }
    if (isDefined(self.jinx_noclip_anchor))
    {
        self jinx_notice("Stop Noclip flight before changing weapons.");
        return;
    }
    current = self getCurrentWeapon();
    if (!(self hasWeapon(weapon)))
    {
        primary = self getWeaponsListPrimaries();
        if (primary.size >= 2)
        {
            if (!jinx_in_list(primary, current))
            {
                self jinx_notice("Hold a primary weapon to replace it.");
                return;
            }
            self takeWeapon(current);
        }
        self giveWeapon(weapon);
    }
    self giveStartAmmo(weapon);
    self switchToWeapon(weapon);
    self jinx_notice("Weapon equipped. Current slot replaced\nonly when already carrying two weapons.");
}

jinx_in_list(list, value)
{
    for (i = 0; i < list.size; i++) if (list[i] == value) return true;
    return false;
}

jinx_apply_camo(name)
{
    if (!isDefined(level.jinx_camo_ids[name]))
    {
        self jinx_notice("Pending: verify this camo ID on T6 MP.");
        return;
    }
    if (self isRemoteControlling() || self isInVehicle()) return;
    weapon = self getCurrentWeapon();
    parts = strTok(weapon, "+");
    if (parts.size == 0 || !jinx_in_list(level.jinx_guns, parts[0]))
    {
        self jinx_notice("Hold a supported MP firearm first.");
        return;
    }
    if (isDefined(self.jinx_noclip_anchor) || self isReloading() || self isSwitchingWeapons())
    {
        self jinx_notice("Exit Noclip and finish weapon animation.");
        return;
    }
    stock = self getWeaponAmmoStock(weapon);
    clip = self getWeaponAmmoClip(weapon);
    self takeWeapon(weapon);
    self giveWeapon(weapon, 0, level.jinx_camo_ids[name]);
    self setWeaponAmmoStock(weapon, stock);
    self setWeaponAmmoClip(weapon, clip);
    self switchToWeapon(weapon);
    self.jinx_camo[weapon] = level.jinx_camo_ids[name];
    self jinx_notice("Camo applied: " + name + "\nWeapon ammo and attachment string kept.");
}

jinx_ui_scale()
{
    if (self.jinx_settings["design"] > 0) return 1;
    if (self.jinx_settings["size"] == 1) return 0.95;
    if (self.jinx_settings["size"] == 2) return 1.05;
    return 1;
}

jinx_ui_offset()
{
    scale = self jinx_ui_scale();
    width = (self jinx_panel_width()) * scale;
    left = -305;
    if (self.jinx_settings["position"] == 1) left = 0 - width / 2;
    if (self.jinx_settings["position"] == 2) left = 305 - width;
    return left + 305 * scale;
}

jinx_color(index)
{
    colors = [];
    colors[0] = (1, 0, 0);
    colors[1] = (0.8, 0, 0.08);
    colors[2] = (1, 0.16, 0.08);
    colors[3] = (0.1, 0.4, 1);
    colors[4] = (0, 0.9, 1);
    colors[5] = (0.1, 1, 0.25);
    colors[6] = (0.6, 0.15, 1);
    colors[7] = (1, 0.2, 0.6);
    colors[8] = (1, 0.5, 0);
    colors[9] = (1, 0.8, 0.1);
    colors[10] = (0.1, 0.8, 0.65);
    colors[11] = (1, 1, 1);
    return colors[index];
}

jinx_apply_layout()
{
    if (self.jinx_settings["design"] > 0) { self jinx_alternate_layout(); return; }
    if (isDefined(self.jinx_menu_blur) && self.jinx_menu_blur)
    { self setBlur(0, 0.2); self.jinx_menu_blur = false; }
    scale = self jinx_ui_scale();
    offset = self jinx_ui_offset();
    for (i = 0; i < self.jinx_hud.size; i++)
    {
        elem = self.jinx_hud[i];
        elem.x = elem.x * scale + offset;
        elem.y = elem.y * scale;
        if (elem.elemType == "icon")
        {
            width = int(elem.width * scale);
            height = int(elem.height * scale);
            if (width < 1) width = 1;
            if (height < 1) height = 1;
            elem setShader("white", width, height);
        }
        else
        {
            elem.fontScale *= scale;
            if (elem.fontScale < 1) elem.fontScale = 1;
        }
    }
}

jinx_rebuild()
{
    self notify("jinx_ui_closed");
    for (i = 0; i < self.jinx_hud.size; i++)
        if (isDefined(self.jinx_hud[i])) self.jinx_hud[i] destroy();
    self.jinx_hud = [];
    self jinx_build_hud();
    self jinx_render(false);
    self thread jinx_disconnect_hud(self.jinx_hud);
}

jinx_setting_action(name)
{
    if (name == "Replay Welcome") { self jinx_close(); self jinx_intro_start(); return; }
    if (name == "Menu Design")
    {
        self.jinx_settings["design"] = (self.jinx_settings["design"] + 1) % 3;
        self jinx_rebuild(); self jinx_notice("Design: " + (self jinx_design_name())); return;
    }
    switch(name)
    {
        case "Menu Theme":
            self.jinx_settings["color1"] = (self.jinx_settings["color1"] + 1) % 12;
            if (self.jinx_settings["color1"] == 1 || self.jinx_settings["color1"] == 2) self.jinx_settings["color1"] = 3;
            self.jinx_settings["color2"] = self.jinx_settings["color1"];
            self.jinx_settings["background"] = (self.jinx_settings["color1"] + 1) % 8;
            break;
        case "Menu Position": self.jinx_settings["position"] = (self.jinx_settings["position"] + 1) % 3; break;
        case "Menu Size": self.jinx_settings["size"] = (self.jinx_settings["size"] + 1) % 3; break;
        case "Menu Font": self.jinx_settings["font"] = 1 - self.jinx_settings["font"]; break;
        case "Menu Color 1": self.jinx_settings["color1"] = (self.jinx_settings["color1"] + 1) % 12; break;
        case "Menu Color 2": self.jinx_settings["color2"] = (self.jinx_settings["color2"] + 1) % 12; break;
        case "Background": self.jinx_settings["background"] = (self.jinx_settings["background"] + 1) % 8; break;
        case "Logo Size": self.jinx_settings["logo"] = (self.jinx_settings["logo"] + 1) % 3; break;
        case "Row Text Size": self.jinx_settings["rowtext"] = (self.jinx_settings["rowtext"] + 1) % 3; break;
        case "Show Controls": self.jinx_settings["help"] = 1 - self.jinx_settings["help"]; break;
        case "Selection Speed": self.jinx_settings["selspeed"] = (self.jinx_settings["selspeed"] + 1) % 4; break;
        case "Panel Shape":
            if (self.jinx_settings["width"] == 0) self.jinx_settings["width"] = 2;
            else if (self.jinx_settings["width"] == 2) self.jinx_settings["width"] = 5;
            else self.jinx_settings["width"] = 0;
            break;
        case "Panel Width": self.jinx_settings["width"] = (self.jinx_settings["width"] + 1) % 6; break;
        case "Text Color": self.jinx_settings["textcolor"] = (self.jinx_settings["textcolor"] + 1) % 12; break;
        case "Selection Opacity": self.jinx_settings["fill"] = (self.jinx_settings["fill"] + 1) % 5; break;
        case "Scrollbar": self.jinx_settings["scrollbar"] = 1 - self.jinx_settings["scrollbar"]; break;
        case "Scroll Style": self.jinx_settings["smooth"] = 1 - self.jinx_settings["smooth"]; break;
        case "Reset Settings": self jinx_settings_defaults(); break;
        case "Save Settings":
            self jinx_save_settings();
            self jinx_notice("Settings saved for this game session.\nClosing Plutonium clears this save.");
            return;
        case "Open Key": self.jinx_settings["openkey"] = 1 - self.jinx_settings["openkey"]; break;
        case "Close Key": self.jinx_settings["closekey"] = 1 - self.jinx_settings["closekey"]; break;
        case "Menu Sound":
            self.jinx_settings["sound"] = 1 - self.jinx_settings["sound"];
            self jinx_ui_sound();
            break;
        case "Move With Menu": self.jinx_settings["move_menu"] = 1 - self.jinx_settings["move_menu"]; break;
        case "Move During Countdown": self.jinx_settings["move_countdown"] = 1 - self.jinx_settings["move_countdown"]; break;
        default: return;
    }
    self jinx_menu_movement();
    self jinx_countdown_movement();
    self jinx_rebuild();
    if (name == "Open Key" || name == "Close Key" || name == "Reset Settings") self jinx_controls_notice();
}

jinx_save_settings()
{
    keys = strTok("position,size,font,color1,color2,background,scrollbar,smooth,sound,openkey,closekey,move_menu,move_countdown,width,textcolor,fill,logo,rowtext,help,selspeed,design", ",");
    game["jinx_saved_ui"] = [];
    saved = [];
    for (i = 0; i < keys.size; i++) saved[keys[i]] = self.jinx_settings[keys[i]];
    game["jinx_saved_ui"] = saved;
}

jinx_load_settings()
{
    if (!isDefined(game["jinx_saved_ui"])) return;
    saved = game["jinx_saved_ui"];
    keys = strTok("position,size,font,color1,color2,background,scrollbar,smooth,sound,openkey,closekey,move_menu,move_countdown,width,textcolor,fill,logo,rowtext,help,selspeed,design", ",");
    for (i = 0; i < keys.size; i++)
    {
        if (!isDefined(saved[keys[i]])) continue;
        value = saved[keys[i]];
        limit = 1;
        if (keys[i] == "position" || keys[i] == "size" || keys[i] == "color1" || keys[i] == "color2") limit = 2;
        if (keys[i] == "color1" || keys[i] == "color2" || keys[i] == "textcolor") limit = 11;
        if (keys[i] == "background") limit = 7;
        if (keys[i] == "width") limit = 5;
        if (keys[i] == "fill") limit = 4;
        if (keys[i] == "logo" || keys[i] == "rowtext") limit = 2;
        if (keys[i] == "selspeed") limit = 3;
        if (keys[i] == "design") limit = 2;
        if (value >= 0 && value <= limit) self.jinx_settings[keys[i]] = value;
    }
}

jinx_render_help()
{
    self.jinx_help.alpha = self.jinx_settings["help"];
    if (isDefined(self.jinx_notice_until) && getTime() < self.jinx_notice_until) self.jinx_help.alpha = 1;
    if (isDefined(self.jinx_notice_until) && getTime() < self.jinx_notice_until)
        self.jinx_help jinx_set_text(self.jinx_notice_text);
    else
    {
        close = "Back/Close: [{+melee}]";
        if (self.jinx_settings["closekey"]) close = "Back: [{+melee}] | Close: [{+speed_throw}]+[{+melee}]";
        self.jinx_help jinx_set_text("Scroll: [{+speed_throw}] / [{+attack}] | Select: [{+activate}]\n" + close + "\nPage: [{+smoke}] / [{+frag}]");
    }
}

jinx_give_kit(index)
{
    if (self isRemoteControlling() || self isInVehicle())
    {
        self jinx_notice("Exit vehicle / remote control first.");
        return;
    }
    if (isDefined(self.jinx_noclip_anchor))
    {
        self jinx_notice("Stop Noclip flight before changing weapons.");
        return;
    }
    primary = jinx_kit_weapon(level.jinx_kit_guns[index][0]);
    sidearm = jinx_kit_weapon(level.jinx_kit_guns[index][1]);
    old = self getWeaponsListPrimaries();
    for (i = 0; i < old.size; i++) self takeWeapon(old[i]);
    self giveWeapon(primary);
    self giveWeapon(sidearm);
    self giveStartAmmo(primary);
    self giveStartAmmo(sidearm);
    self switchToWeapon(primary);
    self jinx_notice("Kit equipped with compatible attachments.\nEquipment and perks retained.");
}

// Bounded world-space target markers. No strings, no new HUD every poll.
jinx_esp_update()
{
    if (self.jinx_esp_elements.size == 0)
    {
        for (i = 0; i < 18; i++)
        {
            marker = newClientHudElem(self);
            marker.archived = false;
            marker.alpha = 0;
            marker.color = (1, 0.025, 0.025);
            marker.hideWhenInMenu = true;
            marker.alignX = "center";
            marker.alignY = "middle";
            marker setShader("hud_remote_missile_target", 18, 24);
            marker setWaypoint(0);
            self.jinx_esp_elements[i] = marker;
        }
        self thread jinx_esp_disconnect(self.jinx_esp_elements);
    }
    slot = 0;
    for (i = 0; i < level.players.size && slot < 18; i++)
    {
        target = level.players[i];
        if (!isDefined(target) || target == self || !isAlive(target)) continue;
        if (target.sessionstate != "playing") continue;
        if (level.teambased && target.team == self.team) continue;
        marker = self.jinx_esp_elements[slot];
        torso = target getTagOrigin("j_spine4");
        marker.color = (1, 0.025, 0.025);
        if (self jinx_practice_visible(target, torso)) marker.color = (0.1, 1, 0.15);
        marker.x = torso[0];
        marker.y = torso[1];
        marker.z = torso[2];
        marker.alpha = 0.85;
        slot++;
    }
    for (i = slot; i < self.jinx_esp_elements.size; i++)
        self.jinx_esp_elements[i].alpha = 0;
}

jinx_esp_destroy()
{
    self notify("jinx_esp_removed");
    if (!isDefined(self.jinx_esp_elements)) return;
    for (i = 0; i < self.jinx_esp_elements.size; i++)
        if (isDefined(self.jinx_esp_elements[i])) self.jinx_esp_elements[i] destroy();
    self.jinx_esp_elements = [];
}

jinx_esp_disconnect(elements)
{
    self endon("jinx_esp_removed");
    self waittill("disconnect");
    for (i = 0; i < elements.size; i++)
        if (isDefined(elements[i])) elements[i] destroy();
}

jinx_change_class(index)
{
    if (!(self jinx_private_host())) return;
    if (self isRemoteControlling() || self isInVehicle())
    {
        self jinx_notice("Exit vehicle / remote control first.");
        return;
    }
    if (!isDefined(self.pers["team"]) || self.sessionstate != "playing") return;
    chosen = level.jinx_classes[index];
    self jinx_stop_effects();
    self jinx_close();
    self.pers["class"] = chosen;
    self.class = chosen;
    self.pers["weapon"] = undefined;
    self.pers["changed_class"] = 0;
    self maps\mp\gametypes\_class::setclass(chosen);
    self.tag_stowed_back = undefined;
    self.tag_stowed_hip = undefined;
    self maps\mp\gametypes\_class::giveloadout(self.pers["team"], chosen);
    self maps\mp\killstreaks\_killstreaks::giveownedkillstreak();
    self jinx_notice("Class applied now. Effects reset; no death.");
}

// Called on a separate thread because the spawn notification ends the old input.
jinx_respawn_now()
{
    self endon("disconnect");
    level endon("game_ended");
    if (!(self jinx_private_host())) return;
    if (!isDefined(level.gametype) || (level.gametype != "tdm" && level.gametype != "dm"))
    {
        self jinx_notice("Practice Respawn: use TDM or Free-for-All.\nRound-based lives are not overridden.");
        return;
    }
    if (self isRemoteControlling() || self isInVehicle())
    {
        self jinx_notice("Exit vehicle / remote control first.");
        return;
    }
    if (!isDefined(level.spawnplayer)) return;
    self jinx_stop_effects();
    self jinx_close();
    self notify("jinx_life_stop");
    self [[level.spawnplayer]]();
}

jinx_named_attachment(name)
{
    if (name == "Laser Sight") return "steadyaim";
    if (name == "Thermal Scope") return "ir";
    if (name == "Toggle ACOG") return "acog";
    return "";
}

jinx_gun_group(base)
{
    for (i = 22; i <= 29; i++)
        if (jinx_in_list(level.jinx_weapon_groups[i], base)) return i;
    return -1;
}

// Uses the current game's actual MP stats table rather than guessed pairs.
// Verified in Resxt/Plutonium-T6-Scripts/chat_commands/chat_command_info.gsc.
jinx_attachment_allowed(base, attachment)
{
    if (!isDefined(level.tbl_weaponids)) return false;
    index = getBaseWeaponItemIndex(base);
    if (!isDefined(index) || !isDefined(level.tbl_weaponids[index])) return false;
    data = level.tbl_weaponids[index]["attachment"];
    if (!isDefined(data) || data == "") return false;
    variants = strTok(data, " ");
    for (i = 0; i < variants.size; i++)
    {
        // e.g. silencer_shotgun uses the weapon suffix +silencer.
        tokens = strTok(variants[i], "_");
        if (tokens.size > 0 && tokens[0] == attachment) return true;
    }
    return false;
}

jinx_weapon_ready()
{
    if (isDefined(self.jinx_noclip_anchor) || self isRemoteControlling() || self isInVehicle())
    {
        self jinx_notice("Exit Noclip / vehicle / remote control first.");
        return false;
    }
    if (self isReloading() || self isSwitchingWeapons())
    {
        self jinx_notice("Finish the current weapon animation first.");
        return false;
    }
    weapon = self getCurrentWeapon();
    parts = strTok(weapon, "+");
    if (parts.size == 0 || !jinx_in_list(level.jinx_guns, parts[0]))
    {
        self jinx_notice("Hold a weapon from Custom Weapons first.");
        return false;
    }
    return true;
}

jinx_attachments_compatible(existing, requested)
{
    // Real T6 MP attachment table, column 11: compatible attachment names.
    row = tableLookupRowNum("mp/attachmentTable.csv", 4, existing);
    if (row < 0) return false;
    allowed = strTok(tableLookupColumnForRow("mp/attachmentTable.csv", row, 11), " ");
    return jinx_in_list(allowed, requested);
}

jinx_attachment(attachment)
{
    if (!(self jinx_weapon_ready())) return;
    weapon = self getCurrentWeapon();
    parts = strTok(weapon, "+");
    base = parts[0];
    removing = jinx_in_list(parts, attachment);
    if (!removing && !jinx_attachment_allowed(base, attachment))
    {
        self jinx_notice("Attachment unavailable on this weapon.\nRapid Fire: compatible SMGs / LMGs only.");
        return;
    }
    optics = strTok("reflex,holo,rangefinder,mms,acog,dualoptic,ir,is,vzoom", ",");
    selected = [];
    for (i = 1; i < parts.size; i++)
    {
        old = parts[i];
        if (old == attachment) continue;
        if (!removing && jinx_in_list(optics, attachment) && jinx_in_list(optics, old)) continue;
        if (!removing && !jinx_attachments_compatible(old, attachment))
        {
            self jinx_notice("Attachment conflict. Remove Attachments\nin Weapon Menu 2/2, then try again.");
            return;
        }
        selected[selected.size] = old;
    }
    if (!removing) selected[selected.size] = attachment;
    if (selected.size > 3)
    {
        self jinx_notice("Maximum three attachments. Remove one first.");
        return;
    }
    // Engine attachment combinations use canonical alphabetical suffix order.
    order = strTok("acog,dualclip,dualoptic,dw,extbarrel,extclip,fastads,fmj,gl,grip,holo,ir,is,mms,rangefinder,reflex,rf,sf,silencer,stackfire,stalker,steadyaim,swayreduc,tacknife,vzoom", ",");
    replacement = base;
    count = 0;
    for (i = 0; i < order.size; i++)
        if (jinx_in_list(selected, order[i]))
        {
            replacement += "+" + order[i];
            count++;
        }
    if (count != selected.size)
    {
        self jinx_notice("Unrecognized existing attachment; weapon kept.");
        return;
    }
    self jinx_replace_gun(weapon, replacement);
    if (removing) self jinx_notice("Attachment removed: " + attachment);
    else self jinx_notice("Attachment equipped: " + attachment);
}

jinx_replace_gun(old, replacement)
{
    clip = self getWeaponAmmoClip(old);
    stock = self getWeaponAmmoStock(old);
    camo = 0;
    if (isDefined(self.jinx_camo[old])) camo = self.jinx_camo[old];
    self takeWeapon(old);
    self giveWeapon(replacement, 0, camo);
    capacity = weaponClipSize(replacement);
    if (capacity > 0 && clip > capacity) clip = capacity;
    self setWeaponAmmoClip(replacement, clip);
    self setWeaponAmmoStock(replacement, stock);
    self switchToWeapon(replacement);
    self.jinx_camo[replacement] = camo;
}

jinx_upgrade()
{
    if (!(self jinx_weapon_ready())) return;
    parts = strTok(self getCurrentWeapon(), "+");
    base = parts[0];
    if (!jinx_attachment_allowed(base, "fmj") || !jinx_attachment_allowed(base, "extclip"))
    {
        self jinx_notice("MP upgrade needs FMJ + Extended Clip support.");
        return;
    }
    self jinx_replace_gun(self getCurrentWeapon(), base + "+extclip+fmj");
    self jinx_notice("MP upgrade: Extended Clip + FMJ.\nReplaces attachments; no damage multiplier.");
}

jinx_weapon_extra(name)
{
    if (!(self jinx_weapon_ready())) return;
    weapon = self getCurrentWeapon();
    if (name == "Refill Current Ammo")
    {
        self giveMaxAmmo(weapon);
        size = weaponClipSize(weapon);
        if (size > 0) self setWeaponAmmoClip(weapon, size);
        self jinx_notice("Current weapon ammunition refilled.");
    }
    else if (name == "Remove Attachments")
    {
        parts = strTok(weapon, "+");
        self jinx_replace_gun(weapon, parts[0]);
        self jinx_notice("Attachments removed; ammo retained.");
    }
    else if (name == "Random Weapon")
        self jinx_give_gun(level.jinx_guns[randomInt(level.jinx_guns.size)]);
    else if (name == "Remove Current Weapon")
    {
        primaries = self getWeaponsListPrimaries();
        if (primaries.size < 2)
        {
            self jinx_notice("Keep at least one primary weapon.");
            return;
        }
        self takeWeapon(weapon);
        remaining = self getWeaponsListPrimaries();
        if (remaining.size > 0) self switchToWeapon(remaining[0]);
        self jinx_notice("Current weapon removed.");
    }
}

// One-edge input: holding the grenade key cannot repeatedly toggle flight.
jinx_noclip_key_tick()
{
    pressed = self fragButtonPressed();
    if (!(self jinx_enabled("noclip")))
    {
        self.jinx_noclip_key_down = pressed;
        return;
    }
    if (pressed && !self.jinx_noclip_key_down)
    {
        self forceOffhandEnd();
        if (isDefined(self.jinx_noclip_anchor))
        {
            self jinx_end_noclip();
            self jinx_notice("Flight OFF. Lethal starts flight again.");
        }
        else if (!self isRemoteControlling() && !self isInVehicle())
        {
            self.jinx_fx["freeze"] = false;
            self.jinx_jump_boost_left = 0;
            self.jinx_noclip_anchor = spawn("script_origin", self.origin);
            if (isDefined(self.jinx_noclip_anchor))
            {
                self playerLinkTo(self.jinx_noclip_anchor);
                self disableWeapons();
                self disableOffhandWeapons();
                self enableInvulnerability();
                self thread jinx_anchor_disconnect(self.jinx_noclip_anchor);
                self jinx_notice("Flight ON. Fire/ADS: forward/back. Jump: boost.");
            }
        }
    }
    self.jinx_noclip_key_down = pressed;
}

jinx_jump_tick(now)
{
    grounded = self isOnGround();
    pressed = self jumpButtonPressed();
    rising = pressed && !self.jinx_jump_previous;
    if (rising) self.jinx_jump_request_time = now;
    if (grounded)
    {
        self.jinx_jump_launch_ready = true;
        self.jinx_air_jumps = 0;
        self.jinx_jump_boost_left = 0;
    }
    velocity = self getVelocity();
    launched = false;
    if (self jinx_enabled("jump") && !grounded && self.jinx_jump_launch_ready)
    {
        // Apply AFTER normal takeoff, once per jump, not while standing on floor.
        if (velocity[2] > 80 && (self.jinx_was_grounded || now - self.jinx_jump_request_time <= 400))
        {
            self.jinx_jump_boost_left = 5;
            self.jinx_jump_launch_ready = false;
            launched = true;
        }
    }
    if (!grounded && now - self.jinx_jump_request_time > 400)
        self.jinx_jump_launch_ready = false;
    if (self jinx_enabled("jump") && self.jinx_jump_boost_left > 0)
    {
        self.jinx_jump_boost_left--;
        // Five bounded airborne ticks counter a takeoff/prediction overwrite without
        // an unbounded hover loop. Horizontal velocity remains untouched.
        self setVelocity((velocity[0], velocity[1], 2200));
    }
    else if (self jinx_enabled("multi") && rising && !grounded && !self.jinx_was_grounded && !launched && self.jinx_air_jumps < 3)
    {
        self.jinx_air_jumps++;
        self setVelocity((velocity[0], velocity[1], 350));
    }
    self.jinx_jump_previous = pressed;
    self.jinx_was_grounded = grounded;
}

jinx_owned_perk(perk, active)
{
    if (active)
    {
        self.jinx_perks_owned[perk] = !(self hasPerk(perk));
        self setPerk(perk);
    }
    else if (isDefined(self.jinx_perks_owned[perk]) && self.jinx_perks_owned[perk])
    {
        self unsetPerk(perk);
        self.jinx_perks_owned[perk] = false;
    }
}

jinx_tune(name, value, fallback)
{
    if (!isDefined(level.jinx_original_tuning)) level.jinx_original_tuning = [];
    if (!isDefined(level.jinx_original_tuning[name]))
        level.jinx_original_tuning[name] = maps\mp\_utility::getdvarfloatdefault(name, fallback);
    setDvar(name, value);
}

jinx_restore_tune(name)
{
    if (!isDefined(level.jinx_original_tuning)) return;
    if (!isDefined(level.jinx_original_tuning[name])) return;
    setDvar(name, level.jinx_original_tuning[name]);
    level.jinx_original_tuning[name] = undefined;
}

jinx_restore_weapon_tuning()
{
    jinx_restore_tune("perk_weapRateMultiplier");
    jinx_restore_tune("perk_weapSpreadMultiplier");
}

jinx_kit_weapon(base)
{
    group = jinx_gun_group(base);
    choices = [];
    if (group == 22) choices = strTok("fastads,stalker,extclip,grip,silencer", ",");
    if (group == 23) choices = strTok("extclip,fastads,extbarrel,grip,silencer", ",");
    if (group == 24) choices = strTok("fastads,stalker,extclip,grip", ",");
    if (group == 25) choices = strTok("dualclip,fmj,swayreduc,steadyaim,extclip", ",");
    if (group == 26) choices = strTok("extbarrel,steadyaim,fastads,dualclip,reflex", ",");
    if (group == 27) choices = strTok("extclip,steadyaim,dualclip,fmj", ",");
    if (base == "crossbow_mp") choices = strTok("stackfire,reflex", ",");
    selected = [];
    for (i = 0; i < choices.size && selected.size < 3; i++)
    {
        candidate = choices[i];
        if (!jinx_attachment_allowed(base, candidate)) continue;
        compatible = true;
        for (j = 0; j < selected.size; j++)
            if (!jinx_attachments_compatible(selected[j], candidate) || !jinx_attachments_compatible(candidate, selected[j]))
                compatible = false;
        if (compatible) selected[selected.size] = candidate;
    }
    order = strTok("dualclip,extbarrel,extclip,fastads,fmj,grip,reflex,silencer,stackfire,stalker,steadyaim,swayreduc", ",");
    weapon = base;
    for (i = 0; i < order.size; i++)
        if (jinx_in_list(selected, order[i])) weapon += "+" + order[i];
    return weapon;
}

// ---- Phase 4: private bot practice -----------------------------------------
jinx_practice_init()
{
    self.jinx_practice = [];
    self.jinx_practice["Aimbot Type"] = 0;
    self.jinx_practice["Target Selection"] = 0;
    self.jinx_practice["Bone Selection"] = 0;
    self.jinx_practice["Prediction"] = 0;
    self.jinx_practice["Aim Key"] = 0;
    self.jinx_practice["Aim FOV"] = 4;
    self.jinx_practice["Azza Aim Angle"] = 1;
    self.jinx_practice["Azza Max Range"] = 2;
    self.jinx_practice["Aim Smoothness"] = 2;
    self.jinx_practice["Visible Check"] = 1;
    self.jinx_practice["Trickshot Type"] = 0;
    self.jinx_practice["Trickshot Bone"] = 0;
    self.jinx_practice["Trickshot Prediction"] = 0;
    self.jinx_practice_hud = [];
    self.jinx_practice_next_shot = 0;
    self.jinx_practice_hit_until = 0;
    self.jinx_practice_last_switch = 0;
    self.jinx_position_down = true;
    self.jinx_position_up = true;
    self.jinx_practice_shot_time = -10000;
    self.jinx_practice_last_target = undefined;
}

jinx_practice_allowed()
{
    if (!(self jinx_private_host())) return false;
    // rankedmatch is derived from XP mode, not proof of a public session.
    return sessionModeIsPrivate() || sessionModeIsSystemLink() || !sessionModeIsOnlineGame();
}

jinx_practice_ready()
{
    if (!(self jinx_practice_allowed()) || self.jinx_open) return false;
    if (self.sessionstate != "playing") return false;
    if (self isRemoteControlling() || self isInVehicle()) return false;
    if (isDefined(self.jinx_noclip_anchor)) return false;
    return true;
}

jinx_practice_key(name)
{
    switch(name)
    {
        case "Aimbot ON/OFF": return "aim";
        case "Auto Shoot": return "autoshoot";
        case "Silent Aim": return "silent";
        case "Auto Wall": return "autowall";
        case "Save / Load Position": return "positionkeys";
        case "Azza Aimbot": return "azza";
        case "Trickshot Aimbot": return "trickaim";
        case "Auto Trickshot": return "autospin";
        case "Rapid Target Switch": return "targetswitch";
        case "No Flinch": return "noflinch";
        case "Fast Swap": return "fastswap";
        case "Crosshair": return "crosshair";
        case "Bullet Teleport": return "bulletteleport";
        case "Trickshot Hitmarker": return "practicehit";
        case "Trickshot Camera": return "third";
        case "No Spread":
        case "No Spread (Trickshot)": return "spread";
    }
    return "";
}

jinx_practice_values(name)
{
    switch(name)
    {
        case "Aimbot Type": return strTok("SNAP,SMOOTH", ",");
        case "Target Selection": return strTok("CROSSHAIR,NEAREST,LOW HP", ",");
        case "Bone Selection":
        case "Trickshot Bone": return strTok("HEAD,NECK,CHEST,PELVIS", ",");
        case "Prediction":
        case "Trickshot Prediction": return strTok("OFF,50 MS,100 MS,150 MS", ",");
        case "Aim Key": return strTok("ADS,FIRE,ADS+FIRE,ALWAYS", ",");
        case "Aim FOV": return strTok("5,15,30,60,90,180", ",");
        case "Azza Aim Angle": return strTok("3,5,8,12,20", ",");
        case "Azza Max Range": return strTok("1000,2000,3000,5000", ",");
        case "Aim Smoothness": return strTok("2,4,6,8,12", ",");
        case "Visible Check": return strTok("OFF,ON", ",");
        case "Trickshot Type": return strTok("NEAREST,RANDOM,FARTHEST", ",");
    }
    return [];
}

jinx_practice_state(category, name)
{
    key = jinx_practice_key(name);
    if (key != "")
    {
        if (self jinx_enabled(key))
        {
            if (key == "autoshoot" || key == "azza" || key == "trickaim" || key == "bulletteleport" || key == "silent" || key == "autowall") return "^3GSC";
            if (key == "autospin") return "^2SPIN";
        }
        return self jinx_toggle_label(key);
    }
    values = jinx_practice_values(name);
    if (values.size > 0) return values[self.jinx_practice[name]];
    if (category == 33) return "USE";
    return "^8--";
}

jinx_practice_action(category, name)
{
    if (name == "Trickshot Killcam")
    {
        if (!(self jinx_practice_allowed())) return;
        if (!level.jinx_trickcam_on && !jinx_damage_filter_install()) { self jinx_notice("Damage callback is not ready."); return; }
        level.jinx_trickcam_on = !level.jinx_trickcam_on;
        jinx_damage_filter_release(); self jinx_render(false);
        self jinx_notice("Native replay: up to 8s for the host's airborne sniper kills. Respects killcam limits and Disable Killcam. No custom camera or fabricated replay."); return;
    }
    if (!(self jinx_practice_allowed()))
    {
        self jinx_notice("Private/local unranked host session required.\nAim helpers target enemy bots only.");
        return;
    }
    values = jinx_practice_values(name);
    if (values.size > 0)
    {
        self.jinx_practice[name]++;
        if (self.jinx_practice[name] >= values.size) self.jinx_practice[name] = 0;
        self jinx_render(false);
        return;
    }
    if (category == 33)
    {
        self jinx_practice_bot_action(name);
        return;
    }
    key = jinx_practice_key(name);
    if (key != "")
    {
        if (key == "third" || key == "spread") self jinx_toggle_effect(key);
        else
        {
            self.jinx_fx[key] = !(self jinx_enabled(key));
            if (key == "noflinch") self jinx_owned_perk("specialty_bulletflinch", self.jinx_fx[key]);
            if (key == "fastswap") self jinx_owned_perk("specialty_fastweaponswitch", self.jinx_fx[key]);
        }
        if (key == "trickaim" && self jinx_enabled(key)) self.jinx_fx["azza"] = false;
        if (key == "azza" && self jinx_enabled(key)) self.jinx_fx["trickaim"] = false;
        if (key == "positionkeys")
        {
            self.jinx_position_down = true;
            self.jinx_position_up = true;
        }
        self jinx_render(false);
        if (self jinx_enabled(key))
        {
            if (key == "positionkeys") self jinx_notice("Close menu. D-pad DOWN: save / UP: load.\nNative scorestreak cycling remains bound.");
            else if (key == "trickaim") self jinx_notice("Airborne shot: lethal hit to a bot in 360.\nNo camera lock. Azza disabled.");
            else if (key == "azza") self jinx_notice("SNIPERS / airborne / enemy bots. Through-wall GSC hit.\nUses Azza Aim Angle + Max Range. Trickshot OFF.");
            else if (key == "bulletteleport") self jinx_notice("Shot: scripted hit at target, ground or air.\nUses crosshair + Aim FOV; bypasses walls.");
            else if (key == "silent") self jinx_notice("Aim Key + shot: scripted hit, camera stays.\nWorks alone; uses Aim FOV. Original shot stays.");
            else if (key == "autowall") self jinx_notice("Aim/Silent/Azza: scripted hits through walls.\nOriginal weapon penetration is unchanged.");
            else if (key == "autoshoot") self jinx_notice("Aimbot + Aim Key: scripted hit every 250ms.\nConsumes ammo; no native fire animation.");
            else if (key == "autospin") self jinx_notice("Airborne 360 deg/s spin helper. Fire manually.\nADS pauses spin; landing stops it.");
            else if (key == "aim") self jinx_notice("Enemy BOTS only. Uses Aim Key.\nSilent Aim suppresses camera snapping.");
        }
        return;
    }
    if (name == "No Recoil") self jinx_notice("No verified T6 recoil-scale native.\nLinked-player workaround can immobilize you.");
}

jinx_practice_enemy(target)
{
    if (!isDefined(target) || target == self || !isAlive(target)) return false;
    if (target.sessionstate != "playing") return false;
    if (!isDefined(target.pers["isBot"]) || !target.pers["isBot"]) return false;
    if (level.teambased && target.team == self.team) return false;
    return true;
}

jinx_practice_point(target, trick)
{
    bone = "Bone Selection";
    prediction = "Prediction";
    if (trick)
    {
        bone = "Trickshot Bone";
        prediction = "Trickshot Prediction";
    }
    tags = strTok("j_head,j_neck,j_spine4,pelvis", ",");
    point = target getTagOrigin(tags[self.jinx_practice[bone]]);
    lead = self.jinx_practice[prediction] * 0.05;
    if (lead > 0) point += target getVelocity() * lead;
    return point;
}

jinx_practice_visible(target, point)
{
    trace = bulletTrace(self getEye(), point, true, self);
    return trace["fraction"] >= 0.99 || (isDefined(trace["entity"]) && trace["entity"] == target);
}

jinx_practice_target(mode, bypass)
{
    // Only the dedicated 360 mode ignores the view and Aim FOV.
    // Azza / teleport always sort by angular distance, never by world distance.
    best = undefined;
    best_score = 99999999;
    candidates = [];
    trick = mode == "trick" || mode == "azza";
    forward = anglesToForward(self getPlayerAngles());
    fovs = strTok("5,15,30,60,90,180", ",");
    fov = int(fovs[self.jinx_practice["Aim FOV"]]);
    azza_range = 3000;
    if (mode == "azza")
    {
        azza_angles = jinx_practice_values("Azza Aim Angle");
        azza_ranges = jinx_practice_values("Azza Max Range");
        fov = int(azza_angles[self.jinx_practice["Azza Aim Angle"]]);
        azza_range = int(azza_ranges[self.jinx_practice["Azza Max Range"]]);
    }
    for (i = 0; i < level.players.size; i++)
    {
        target = level.players[i];
        if (!(self jinx_practice_enemy(target))) continue;
        point = self jinx_practice_point(target, trick);
        if (mode == "azza" && distance(self getEye(), point) > azza_range) continue;
        delta = point - self getEye();
        dot = vectorDot(forward, vectorNormalize(delta));
        if (dot > 1) dot = 1;
        if (dot < -1) dot = -1;
        angle = acos(dot);
        if (mode != "trick" && angle > fov) continue;
        if (!bypass && self.jinx_practice["Visible Check"] && !(self jinx_practice_visible(target, point))) continue;
        score = angle;
        if (mode == "aim")
        {
            if (self.jinx_practice["Target Selection"] == 1) score = distance(self.origin, target.origin);
            if (self.jinx_practice["Target Selection"] == 2) score = target.health;
        }
        if (mode == "trick")
        {
            score = distance(self.origin, target.origin);
            if (self.jinx_practice["Trickshot Type"] == 2) score = -score;
        }
        // Azza always means nearest crosshair. Cycling applies only to 360 mode.
        if (mode == "trick" && self jinx_enabled("targetswitch") && isDefined(self.jinx_practice_last_target) && target == self.jinx_practice_last_target)
            score += 10000000;
        candidates[candidates.size] = target;
        if (score < best_score)
        {
            best = target;
            best_score = score;
        }
    }
    if (mode == "trick" && self.jinx_practice["Trickshot Type"] == 1 && candidates.size > 0)
    {
        // Skip previous target when cycling, unless it is the only living bot.
        pool = [];
        for (i = 0; i < candidates.size; i++)
            if (!(self jinx_enabled("targetswitch")) || !isDefined(self.jinx_practice_last_target) || candidates[i] != self.jinx_practice_last_target || candidates.size == 1)
                pool[pool.size] = candidates[i];
        best = pool[randomInt(pool.size)];
    }
    return best;
}

jinx_practice_aim_key()
{
    key = self.jinx_practice["Aim Key"];
    if (key == 0) return self adsButtonPressed();
    if (key == 1) return self attackButtonPressed();
    if (key == 2) return self adsButtonPressed() && self attackButtonPressed();
    return true;
}

jinx_angle_delta(angle)
{
    while (angle > 180) angle -= 360;
    while (angle < -180) angle += 360;
    return angle;
}

jinx_practice_turn(point)
{
    desired = vectorToAngles(point - self getEye());
    if (self.jinx_practice["Aimbot Type"] == 0)
    {
        self setPlayerAngles((jinx_angle_delta(desired[0]), desired[1], 0));
        return;
    }
    current = self getPlayerAngles();
    factors = strTok("2,4,6,8,12", ",");
    factor = int(factors[self.jinx_practice["Aim Smoothness"]]);
    pitch = current[0] + jinx_angle_delta(desired[0] - current[0]) / factor;
    yaw = current[1] + jinx_angle_delta(desired[1] - current[1]) / factor;
    self setPlayerAngles((pitch, yaw, 0));
}

jinx_practice_tick(now)
{
    if (!(self jinx_practice_ready()))
    {
        self jinx_practice_hud_destroy();
        return;
    }
    self jinx_practice_hud_update(now);
    // Trickshot/Azza/Bullet Teleport never continuously move the camera.
    airborne_mode = !(self isOnGround()) && (self jinx_enabled("trickaim") || (self jinx_enabled("azza") && jinx_practice_sniper(self getCurrentWeapon())));
    aim = self jinx_enabled("aim") && self jinx_practice_aim_key() && !airborne_mode;
    if (aim)
    {
        bypass = self jinx_enabled("autowall");
        target = self jinx_practice_target("aim", bypass);
        if (isDefined(target))
        {
            if (!(self jinx_enabled("silent")))
                self jinx_practice_turn(self jinx_practice_point(target, false));
            if (self jinx_enabled("autoshoot"))
                self jinx_practice_auto_hit(target, bypass, now);
        }
    }
    else if (self jinx_enabled("autospin") && !(self isOnGround()) && !(self adsButtonPressed()))
    {
        angles = self getPlayerAngles();
        self setPlayerAngles((angles[0], jinx_angle_delta(angles[1] + 18), 0));
    }
}

jinx_practice_shots()
{
    self endon("disconnect");
    self endon("jinx_life_stop");
    self endon("death");
    level endon("game_ended");
    for (;;)
    {
        self waittill("weapon_fired", fired_weapon);
        if (self jinx_practice_ready()) self jinx_fun_shot();
        if (!(self jinx_practice_ready())) continue;
        if (!isDefined(fired_weapon)) fired_weapon = self getCurrentWeapon();
        if (!jinx_practice_firearm(fired_weapon)) continue;
        now = getTime();
        if (now == self.jinx_practice_shot_time) continue;
        self.jinx_practice_shot_time = now;
        airborne = !(self isOnGround());
        mode = "";
        bypass = self jinx_enabled("autowall");
        if (airborne && self jinx_enabled("trickaim"))
        {
            mode = "trick";
            bypass = true;
        }
        else if (airborne && self jinx_enabled("azza") && jinx_practice_sniper(fired_weapon))
        {
            mode = "azza";
            bypass = true;
        }
        else if (self jinx_enabled("bulletteleport"))
        {
            mode = "teleport";
            bypass = true;
        }
        else if ((self jinx_enabled("silent") || (self jinx_enabled("aim") && bypass)) && self jinx_practice_aim_key()) mode = "aim";
        if (mode == "") continue;
        if (mode == "azza" && self jinx_enabled("bulletteleport")) bypass = true;
        target = self jinx_practice_target(mode, bypass);
        if (!isDefined(target)) continue;
        trick = mode == "trick" || mode == "azza";
        // A normal aim shot without Silent only gets wall assistance when blocked.
        if (mode == "aim" && !(self jinx_enabled("silent")) && self jinx_practice_visible(target, self jinx_practice_point(target, false))) continue;
        // One selected target / one stock damage call. No shared 250ms gate:
        // firing just after Auto Shoot no longer suppresses a trickshot.
        self.jinx_practice_next_shot = now + 250;
        self jinx_practice_hit(target, fired_weapon, trick, bypass);
    }
}

jinx_practice_damage()
{
    self endon("disconnect");
    level endon("game_ended");
    for (;;)
    {
        self waittill("damage", amount, attacker);
        if (!isDefined(attacker) || !isPlayer(attacker) || amount <= 0) continue;
        if (!isDefined(attacker.jinx_fx)) continue;
        if (!(attacker jinx_enabled("practicehit"))) continue;
        if (!(attacker jinx_practice_ready())) continue;
        if (!isDefined(self.pers["isBot"]) || !self.pers["isBot"]) continue;
        if (level.teambased && self.team == attacker.team) continue;
        attacker.jinx_practice_hit_until = getTime() + 180;
    }
}

jinx_practice_hud_update(now)
{
    crosshair = self jinx_enabled("crosshair");
    hit = self jinx_enabled("practicehit") && now < self.jinx_practice_hit_until;
    if (!crosshair && !hit)
    {
        self jinx_practice_hud_destroy();
        return;
    }
    if (self.jinx_practice_hud.size == 0)
    {
        hud = newClientHudElem(self);
        hud.horzAlign = "center";
        hud.vertAlign = "middle";
        hud.alignX = "center";
        hud.alignY = "middle";
        hud.x = 0;
        hud.y = 0;
        hud.font = "default";
        hud.fontScale = 1.4;
        hud.color = (1, 1, 1);
        hud.archived = false;
        hud.hideWhenInMenu = true;
        self.jinx_practice_hud[0] = hud;
        self thread jinx_practice_hud_disconnect(self.jinx_practice_hud);
    }
    label = "+";
    if (hit) label = "X";
    self.jinx_practice_hud[0] jinx_set_text(label);
}

jinx_practice_hud_destroy()
{
    self notify("jinx_practice_hud_removed");
    if (!isDefined(self.jinx_practice_hud)) return;
    for (i = 0; i < self.jinx_practice_hud.size; i++)
        if (isDefined(self.jinx_practice_hud[i])) self.jinx_practice_hud[i] destroy();
    self.jinx_practice_hud = [];
}

jinx_practice_hud_disconnect(elements)
{
    self endon("jinx_practice_hud_removed");
    self waittill("disconnect");
    for (i = 0; i < elements.size; i++)
        if (isDefined(elements[i])) elements[i] destroy();
}

jinx_practice_bot_action(name)
{
    if (!(self jinx_practice_allowed())) { self jinx_action_blocked(); return; }
    if (name == "Add Enemy Bot" || name == "Add Max Bots")
    { self thread jinx_add_bot_batch(name == "Add Max Bots"); return; }
    if (name == "Remove One Bot") { self jinx_bot_picker(); return; }
    if (name == "Remove All Bots") { self thread jinx_remove_all_bots(); return; }
    destination = undefined;
    if (name == "Move Bots To Crosshair")
    {
        forward = anglesToForward(self getPlayerAngles());
        trace = bulletTrace(self getEye(), self getEye() + forward * 4096, false, self);
        if (trace["fraction"] >= 1)
        {
            self jinx_notice("Aim at a clear floor, then retry.");
            return;
        }
        if (trace["normal"][2] < 0.7)
        {
            self jinx_notice("Aim at a flat floor, not a wall.");
            return;
        }
        destination = trace["position"] + (0, 0, 12);
    }
    count = 0;
    for (i = 0; i < level.players.size; i++)
    {
        bot = level.players[i];
        if (!(self jinx_practice_enemy(bot))) continue;
        if (name == "Freeze Enemy Bots")
        {
            if (!isDefined(bot.jinx_practice_frozen))
            {
                bot freezeControls(true);
                bot.jinx_practice_frozen = true;
            }
        }
        if (name == "Unfreeze Enemy Bots" && isDefined(bot.jinx_practice_frozen))
        {
            bot freezeControls(false);
            bot.jinx_practice_frozen = undefined;
        }
        // Same destination by design: no unchecked offsets through map geometry.
        if (isDefined(destination)) bot setOrigin(destination);
        count++;
    }
    self jinx_notice("Applied to " + count + " living enemy bots.");
}

jinx_release_practice_bots()
{
    if (!isDefined(level.players)) return;
    for (i = 0; i < level.players.size; i++)
    {
        bot = level.players[i];
        if (!isDefined(bot) || !isDefined(bot.jinx_practice_frozen)) continue;
        bot freezeControls(false);
        bot.jinx_practice_frozen = undefined;
    }
}

jinx_practice_stop()
{
    self jinx_practice_hud_destroy();
    if (self jinx_enabled("noflinch")) self jinx_owned_perk("specialty_bulletflinch", false);
    if (self jinx_enabled("fastswap")) self jinx_owned_perk("specialty_fastweaponswitch", false);
    if (isDefined(self.jinx_practice_frozen))
    {
        self freezeControls(false);
        self.jinx_practice_frozen = undefined;
    }
    if (self isHost()) { if (!level.jinx_phase1_ended) level.jinx_trickcam_on = false; jinx_damage_filter_release(); jinx_release_practice_bots(); }
    self.jinx_position_down = true;
    self.jinx_position_up = true;
    self.jinx_practice_shot_time = -10000;
    self.jinx_practice_last_target = undefined;
    self.jinx_practice_hit_until = 0;
}

jinx_position_load()
{
    if (!isDefined(self.jinx_practice_position))
    {
        self jinx_notice("No saved position. D-pad DOWN to save first.");
        return;
    }
    self setOrigin(self.jinx_practice_position);
    self setPlayerAngles(self.jinx_practice_angles);
    self setVelocity((0, 0, 0));
    if (self jinx_enabled("freeze")) self.jinx_freeze_origin = self.jinx_practice_position;
    self.jinx_jump_boost_left = 0;
    self.jinx_jump_launch_ready = false;
    self.jinx_jump_request_time = -10000;
    self.jinx_jump_previous = self jumpButtonPressed();
    self.jinx_was_grounded = false;
    self.jinx_air_jumps = 0;
    self jinx_notice("Saved position restored.");
}


jinx_position_save()
{
    if (!(self isOnGround()))
    {
        self jinx_notice("Save requires a grounded position.");
        return;
    }
    self.jinx_practice_position = self.origin;
    self.jinx_practice_angles = self getPlayerAngles();
    self jinx_notice("Position saved. D-pad UP to load.");
}


jinx_position_keys_tick()
{
    down = self actionSlotTwoButtonPressed();
    up = self actionSlotOneButtonPressed();
    down_edge = down && !self.jinx_position_down;
    up_edge = up && !self.jinx_position_up;
    self.jinx_position_down = down;
    self.jinx_position_up = up;
    if (!(self jinx_enabled("positionkeys")) || !(self jinx_practice_ready())) return;
    // Reject simultaneous inputs; hold cannot repeatedly save or teleport.
    if (down && up) return;
    if (down_edge) self jinx_position_save();
    else if (up_edge) self jinx_position_load();
}


jinx_practice_auto_hit(target, bypass, now)
{
    if (now < self.jinx_practice_next_shot) return;
    if (self isReloading() || self isSwitchingWeapons()) return;
    weapon = self getCurrentWeapon();
    if (!jinx_practice_firearm(weapon)) return;
    if (!bypass && !(self jinx_practice_visible(target, self jinx_practice_point(target, false)))) return;
    clip = self getWeaponAmmoClip(weapon);
    if (clip <= 0) return;
    self.jinx_practice_next_shot = now + 250;
    self setWeaponAmmoClip(weapon, clip - 1);
    self jinx_practice_hit(target, weapon, false, bypass);
}


jinx_practice_hit(target, weapon, trick, bypass)
{
    if (!(self jinx_practice_ready()) || !(self jinx_practice_enemy(target))) return;
    if (!jinx_practice_firearm(weapon)) return;
    if (!isDefined(level.callbackPlayerDamage)) return;
    point = self jinx_practice_point(target, trick);
    if (!bypass && !(self jinx_practice_visible(target, point))) return;
    // Stock callback retains combat state / gametype damage rules and kill credit.
    // This is scripted lethal practice damage, not a re-aimed native projectile.
    before_health = target.health;
    damage = before_health + 100;
    location = "Bone Selection";
    if (trick) location = "Trickshot Bone";
    hitlocs = strTok("head,neck,torso_upper,torso_lower", ",");
    hitloc = hitlocs[self.jinx_practice[location]];
    direction = vectorNormalize(point - self getEye());
    self.jinx_practice_last_target = target;
    target [[level.callbackPlayerDamage]](self, self, damage, 0, "MOD_RIFLE_BULLET", weapon, point, direction, hitloc, 0, 0);
    // Direct callback hits may not emit the engine's initial damage notification.
    // Show feedback only after an observed health decrease/death, never on fire alone.
    if (self jinx_enabled("practicehit") && isDefined(target))
        if (!isAlive(target) || target.health < before_health)
            self.jinx_practice_hit_until = getTime() + 180;
}


jinx_practice_firearm(weapon)
{
    // Verify base against this MP menu's loaded firearms, excluding explosives,
    // scorestreaks, launchers, shields, crossbow and ballistic knife.
    parts = strTok(weapon, "+");
    if (parts.size == 0 || !jinx_in_list(level.jinx_guns, parts[0])) return false;
    group = jinx_gun_group(parts[0]);
    return group >= 22 && group <= 27;
}


// ---- Phase 5A: Messages ----------------------------------------------------
jinx_message_catalog()
{
    level.jinx_message_instagram = "instagram.com/luistorrespr_/";
    level.jinx_message_youtube = "youtube.com/@JinxPR";
    level.jinx_message_groups = strTok("Troll,Funny,Welcome,Trickshot,GG & Hype,Lobby Rules,Boricua,JINX & Social", ",");
    level.jinx_message_texts = [];
    level.jinx_message_queue = [];
    level.jinx_message_queue_head = 0;
    level.jinx_message_queue_count = 0;
    level.jinx_message_send_at = 0;
    level.jinx_message_roster = [];
    level.jinx_message_serial = 0;
    options = [];
    texts = [];
    options[0] = "Aim delivery";
    texts[0] = "Your aim is arriving by mail tomorrow.";
    options[1] = "Lobby GPS";
    texts[1] = "Lobby GPS: the enemy is right in front of you.";
    options[2] = "Air shipment";
    texts[2] = "Another shot delivered straight to the stratosphere.";
    options[3] = "Reload excuse";
    texts[3] = "Still reloading since the last match?";
    options[4] = "Respawn club";
    texts[4] = "Respawn VIP club. Welcome back.";
    options[5] = "Wall inspector";
    texts[5] = "Thanks for checking every wall with your bullets.";
    options[6] = "Hit the sky";
    texts[6] = "That cloud just reported your sniper.";
    options[7] = "Controller nap";
    texts[7] = "Your controller is taking a nap.";
    options[8] = "Free taxi";
    texts[8] = "Free ride to respawn. Courtesy of JINX.";
    options[9] = "Lag excuse";
    texts[9] = "Lag asked you to stop blaming it.";
    level.jinx_options[35] = options;
    level.jinx_titles[35] = "Troll";
    level.jinx_message_texts[35] = texts;
    options = [];
    texts = [];
    options[0] = "WiFi aim";
    texts[0] = "My aim runs on the neighbor's WiFi.";
    options[1] = "Warmup forever";
    texts[1] = "47 warmup matches later... almost ready.";
    options[2] = "Gravity wins";
    texts[2] = "Nice spin. Gravity won the round.";
    options[3] = "Floor fan";
    texts[3] = "My character is a huge fan of the floor.";
    options[4] = "Clip or trip";
    texts[4] = "Not a trickshot. A stylish accident.";
    options[5] = "Snack break";
    texts[5] = "Brain break: thinking about snacks.";
    options[6] = "Respawn speedrun";
    texts[6] = "New respawn speedrun record.";
    options[7] = "One more";
    texts[7] = "One more and I am out. Make that twenty.";
    options[8] = "Loading aim";
    texts[8] = "Loading aim... 2%.";
    options[9] = "Budget pro";
    texts[9] = "Professional player. Beginner budget.";
    level.jinx_options[36] = options;
    level.jinx_titles[36] = "Funny";
    level.jinx_message_texts[36] = texts;
    options = [];
    texts = [];
    options[0] = "Good vibes";
    texts[0] = "Welcome to JINX. Good games, good vibes.";
    options[1] = "Private practice";
    texts[1] = "Private match: practice, experiment, enjoy.";
    options[2] = "Squad arrived";
    texts[2] = "The squad is here. Now we can start.";
    options[3] = "Get comfy";
    texts[3] = "Get comfortable, pick a class, and jump in.";
    options[4] = "First try";
    texts[4] = "Welcome! Your first miss is on the house.";
    options[5] = "Respect";
    texts[5] = "Good vibes and respect for the whole lobby.";
    options[6] = "New challenger";
    texts[6] = "A new challenger joined the private match.";
    options[7] = "Ready up";
    texts[7] = "The lobby is ready. Are you?";
    options[8] = "JINX house";
    texts[8] = "Welcome to the house of JINX.";
    options[9] = "Welcome back";
    texts[9] = "You are back! Your respawn spot was reserved.";
    level.jinx_options[37] = options;
    level.jinx_titles[37] = "Welcome";
    level.jinx_message_texts[37] = texts;
    options = [];
    texts = [];
    options[0] = "One bullet";
    texts[0] = "One jump. One spin. One bullet. Make it count.";
    options[1] = "Clip time";
    texts[1] = "Time to hit that clip.";
    options[2] = "Send it";
    texts[2] = "Do not fear the miss. Send it!";
    options[3] = "Practice pays";
    texts[3] = "Great shots take practice. Keep going.";
    options[4] = "Spin receipt";
    texts[4] = "That spin needs a receipt and a warranty.";
    options[5] = "Behind you";
    texts[5] = "The target was behind you. The style was ahead.";
    options[6] = "Air control";
    texts[6] = "Less thinking, more attempts.";
    options[7] = "Save first";
    texts[7] = "Save your position before the next jump.";
    options[8] = "Almost";
    texts[8] = "Does almost count as a clip? Asking for a friend.";
    options[9] = "Clean landing";
    texts[9] = "Now try it without kissing the floor.";
    level.jinx_options[38] = options;
    level.jinx_titles[38] = "Trickshot";
    level.jinx_message_texts[38] = texts;
    options = [];
    texts = [];
    options[0] = "GG";
    texts[0] = "GG, squad! Great match.";
    options[1] = "Nice shot";
    texts[1] = "That shot was ridiculously clean.";
    options[2] = "Clip saved";
    texts[2] = "Save that clip. This does not happen every day.";
    options[3] = "Lets go";
    texts[3] = "LET'S GO! That is the energy.";
    options[4] = "Respect shot";
    texts[4] = "Respect. That shot earned a replay.";
    options[5] = "On fire";
    texts[5] = "You are on fire. Keep that sniper ready.";
    options[6] = "Comeback";
    texts[6] = "The comeback starts with this kill.";
    options[7] = "Team effort";
    texts[7] = "Great work, team. That is how we do it.";
    options[8] = "Big moment";
    texts[8] = "That was THE moment of the match.";
    options[9] = "One more clip";
    texts[9] = "Still time for one more clip.";
    level.jinx_options[39] = options;
    level.jinx_titles[39] = "GG & Hype";
    level.jinx_message_texts[39] = texts;
    options = [];
    texts = [];
    options[0] = "Private only";
    texts[0] = "JINX: tools for this private practice match.";
    options[1] = "Take turns";
    texts[1] = "Take turns and give the next player some space.";
    options[2] = "No spawn camp";
    texts[2] = "Let players leave spawn before the next attempt.";
    options[3] = "Respect players";
    texts[3] = "Jokes are welcome. Disrespect is not.";
    options[4] = "Host ready";
    texts[4] = "Wait for the host signal before starting.";
    options[5] = "Pick class";
    texts[5] = "Choose your class before the next attempt.";
    options[6] = "Bots ready";
    texts[6] = "Set up your bots and save your position.";
    options[7] = "Reset round";
    texts[7] = "Reset and give it another try.";
    options[8] = "Menu closed";
    texts[8] = "Close the menu to return to gameplay controls.";
    options[9] = "Have fun";
    texts[9] = "Main rule: have fun with the squad.";
    level.jinx_options[40] = options;
    level.jinx_titles[40] = "Lobby Rules";
    level.jinx_message_texts[40] = texts;
    options = [];
    texts = [];
    options[0] = "Wepa";
    texts[0] = "WEPA! El corillo esta activo.";
    options[1] = "Tu pai";
    texts[1] = "Tu pai llego al lobby.";
    options[2] = "Duro";
    texts[2] = "Eso quedo duro, mano.";
    options[3] = "Pabellon";
    texts[3] = "Pabellon, suelta ese tiro!";
    options[4] = "Bendito";
    texts[4] = "Bendito, la bala se fue de vacaciones.";
    options[5] = "Dale";
    texts[5] = "Dale sin miedo, que esto es practica.";
    options[6] = "Activo";
    texts[6] = "Puerto Rico en la casa. Estamos activos.";
    options[7] = "Chacho";
    texts[7] = "Chacho, ese giro me mareo hasta a mi.";
    options[8] = "Corillo";
    texts[8] = "Corillo, una mas y nos vamos. Seguro.";
    options[9] = "Flow";
    texts[9] = "No pegue el tiro, pero el flow estaba.";
    level.jinx_options[41] = options;
    level.jinx_titles[41] = "Boricua";
    level.jinx_message_texts[41] = texts;
    options = [];
    texts = [];
    options[0] = "JINX Menu";
    texts[0] = "JINX MOD MENU | By Jinx";
    options[1] = "YouTube";
    texts[1] = "YouTube: youtube.com/@JinxPR";
    options[2] = "Instagram";
    texts[2] = "Instagram: instagram.com/luistorrespr_/";
    options[3] = "Subscribe";
    texts[3] = "More clips on YouTube: @JinxPR";
    options[4] = "Follow";
    texts[4] = "Follow the squad on Instagram: @luistorrespr_";
    options[5] = "Private session";
    texts[5] = "JINX PRIVATE SESSION | Practice. Laugh. Repeat.";
    options[6] = "Red and black";
    texts[6] = "Black and red. The JINX signature.";
    options[7] = "Share the clip";
    texts[7] = "Record your best shot and share it with the squad.";
    options[8] = "Thanks";
    texts[8] = "Thanks for playing with JINX!";
    options[9] = "Custom";
    texts[9] = "Your custom message here.";
    level.jinx_options[42] = options;
    level.jinx_titles[42] = "JINX & Social";
    level.jinx_message_texts[42] = texts;
}

jinx_message_init()
{
    level.jinx_message_serial++;
    self.jinx_message_id = "p" + level.jinx_message_serial;
    self.jinx_message_hud = [];
    self.jinx_message_choice = 0;
    self.jinx_message_display = "Typewriter Message";
    self.jinx_message_color = 2; // GREEN default.
    self.jinx_message_flags = [];
    self.jinx_message_category = 42; // JINX & Social, first preset.
    self.jinx_message_life_kills = 0;
    self.jinx_message_kills_seen = undefined;
    self.jinx_message_next_tick = 0;
    self.jinx_message_next_send = 0;
    self.jinx_message_repeat_left = 0;
    self.jinx_message_last_streak = 0;
    self.jinx_message_until = 0;
}

jinx_message_key(name)
{
    switch(name)
    {
        case "Killstreak Message": return "msg_streak";
        case "Welcome Message": return "msg_welcome";
        case "Disconnect Message": return "msg_disconnect";
        case "Custom HUD Text": return "msg_custom";
        case "Chat Spam": return "msg_repeat";
        case "Chat Rainbow": return "msg_rainbow";
    }
    return "";
}

jinx_message_state(category, name)
{
    if (category == 34) return ">";
    if (category == 54) { if (self.jinx_message_display == name) return "^2SET"; return "USE"; }
    if (category >= 35 && category <= 42)
    {
        if (self.jinx_message_category == category && level.jinx_options[category][self.jinx_message_choice] == name) return "^2SET";
        return "USE";
    }
    if (name == "Message Text" || name == "Display Style" || name == "Automatic Messages" || name == "Colors and Effects" || name == "Social Messages") return ">";
    key = jinx_message_key(name);
    if (key != "")
    {
        if (self jinx_message_on(key)) return "^2ON";
        return "^1OFF";
    }
    if (name == "Custom Text Colors")
    {
        colors = strTok("WHITE,RED,GREEN,YELLOW,CYAN,PINK", ",");
        return colors[self.jinx_message_color];
    }
    if (name == "Instagram Text" && level.jinx_message_instagram == "") return "SETUP";
    if (name == "YouTube Text" && level.jinx_message_youtube == "") return "SETUP";
    return "SHOW";
}

jinx_message_text()
{
    return jinx_message_limit(level.jinx_message_texts[self.jinx_message_category][self.jinx_message_choice], 72);
}

jinx_message_paint(message, rainbow)
{
    colors = strTok("^7,^1,^2,^3,^5,^6", ",");
    if (!rainbow) return colors[self.jinx_message_color] + message;
    output = "";
    for (i = 0; i < message.size && i < 72; i++)
        output += colors[i % colors.size] + getSubStr(message, i, i + 1);
    return output;
}

jinx_message_action(category, name, index)
{
    if (!(self jinx_message_allowed()))
    {
        self jinx_notice("Messages require a private/local host match.");
        return;
    }
    if (category == 54)
    {
        self.jinx_message_display = name;
        self jinx_back();
        self jinx_notice("Style selected. Preview Message shows it on your HUD.");
        return;
    }
    if (category >= 35 && category <= 42)
    {
        self.jinx_message_category = category;
        self.jinx_message_choice = index;
        self.jinx_category = 3;
        self.jinx_return_depth = 0;
        self.jinx_subcursor[3] = 1;
        self jinx_render(false);
        self jinx_notice("Selected: " + self jinx_message_text());
        return;
    }
    if (name == "Custom Text Colors")
    {
        self.jinx_message_color++;
        if (self.jinx_message_color >= 6) self.jinx_message_color = 0;
        self jinx_render(false);
        return;
    }
    key = jinx_message_key(name);
    if (key != "")
    {
        active = !(self jinx_message_on(key));
        self.jinx_message_flags[key] = active;
        level.jinx_message_host = self;
        self jinx_render(false);
        if (!active)
        {
            if (key == "msg_repeat") self.jinx_message_repeat_left = 0;
            self jinx_notice(name + ": OFF");
            return;
        }
        if (key == "msg_repeat")
        {
            self.jinx_message_repeat_left = 5;
            self.jinx_message_repeat_at = getTime();
            self jinx_notice("Repeat ON: first send now, then every 5s.\nFive sends total; works with menu open.");
        }
        else if (key == "msg_rainbow")
        {
            self jinx_message_broadcast(self jinx_message_text());
            self jinx_notice("Rainbow ON: sample sent to the lobby feed.");
        }
        else if (key == "msg_welcome")
        {
            self jinx_message_broadcast("Welcome to JINX! Private match, good vibes.");
            self jinx_notice("Welcome sent. New arrivals greeted automatically.");
        }
        else if (key == "msg_disconnect") self jinx_notice("Departure alerts ON. A player must leave.\nRespawning does not count as leaving.");
        else if (key == "msg_streak") self jinx_notice("Killstreak alerts ON: each new kill.\nCounter resets on death; setting stays ON.");
        else if (key == "msg_custom") self jinx_notice("Selected text appears when you close the menu.");
        return;
    }
    message = self jinx_message_text();
    if (name == "Send Message")
    {
        self jinx_message_broadcast(message);
        return;
    }
    if (name == "Advertise Menu")
    {
        self jinx_message_broadcast("JINX MOD MENU | By Jinx | Private Practice");
        return;
    }
    if (name == "Instagram Text" || name == "YouTube Text")
    {
        handle = level.jinx_message_instagram;
        prefix = "Instagram: ";
        if (name == "YouTube Text")
        {
            handle = level.jinx_message_youtube;
            prefix = "YouTube: ";
        }
        if (handle == "")
        {
            self jinx_notice("Set your handle in jinx_message_catalog().\nNo account is assumed or advertised.");
            return;
        }
        message = prefix + jinx_message_limit(handle, 48);
    }
    // Close the menu first: 48 menu elements + the normal game's HUD must not
    // coexist with animated text. Reopening cancels the temporary animation.
    self jinx_close();
    if (name == "Preview Message") name = self.jinx_message_display;
    self jinx_message_show(name, message);
}

jinx_message_broadcast(message)
{
    if (!(self jinx_message_allowed())) return false;
    if (level.jinx_message_queue_count >= 16) return false;
    tail = (level.jinx_message_queue_head + level.jinx_message_queue_count) % 16;
    text = self jinx_message_paint(jinx_message_limit(message, 72), self jinx_message_on("msg_rainbow"));
    level.jinx_message_queue[tail] = text;
    level.jinx_message_queue_count++;
    return true;
}

jinx_message_element(slot)
{
    if (isDefined(self.jinx_message_hud[slot])) return self.jinx_message_hud[slot];
    hud = newClientHudElem(self);
    hud.horzAlign = "center";
    hud.vertAlign = "middle";
    hud.alignX = "center";
    hud.alignY = "middle";
    hud.x = 0;
    hud.y = -110;
    hud.font = "objective";
    hud.fontScale = 1.4;
    hud.sort = 12;
    hud.archived = false;
    hud.hideWhenInMenu = true;
    self.jinx_message_hud[slot] = hud;
    // Separate finite cleanup watcher for each allocated element.
    self thread jinx_message_element_disconnect(hud, slot);
    return hud;
}

jinx_message_element_disconnect(hud, slot)
{
    self endon("jinx_message_removed_" + slot);
    self waittill("disconnect");
    if (isDefined(hud)) hud destroy();
}

jinx_message_remove(slot)
{
    if (!isDefined(self.jinx_message_hud[slot])) return;
    self notify("jinx_message_removed_" + slot);
    self.jinx_message_hud[slot] destroy();
    self.jinx_message_hud[slot] = undefined;
}

jinx_message_clear()
{
    self jinx_message_remove(0);
    self jinx_message_remove(1);
    self.jinx_message_until = 0;
}

jinx_message_show(style, message)
{
    if (self.jinx_open || !isAlive(self) || !(self jinx_message_allowed())) return;
    self jinx_message_remove(0);
    hud = self jinx_message_element(0);
    self.jinx_message_body = jinx_message_limit(message, 72);
    self.jinx_message_style = style;
    self.jinx_message_start = getTime();
    self.jinx_message_fading = false;
    self.jinx_message_until = getTime() + 6000;
    if (style == "Big Text Message") hud.fontScale = 2.0;
    if (style == "Scrolling Text")
    {
        hud.y = 95;
        hud.x = 0;
        hud.fontScale = 1.2;
        self.jinx_message_body = jinx_message_limit(message, 42);
        self.jinx_message_until = getTime() + 7000;
    }
    if (style == "Typewriter Message")
    {
        hud jinx_set_text("");
        self.jinx_message_until = getTime() + self.jinx_message_body.size * 70 + 2500;
    }
    else hud jinx_set_text(self jinx_message_paint(self.jinx_message_body, false));
    target_y = hud.y;
    hud.y = target_y + 12;
    hud.alpha = 0;
    hud moveOverTime(0.3);
    hud.y = target_y;
    hud fadeOverTime(0.3);
    hud.alpha = 1;
}

jinx_message_streak()
{
    return self.jinx_message_life_kills;
}

jinx_message_tick(now)
{
    if (now < self.jinx_message_next_tick) return;
    self.jinx_message_next_tick = now + 100;
    if (self.jinx_open || !isAlive(self) || !(self jinx_message_allowed())) return;
    if (self.jinx_message_until > 0)
    {
        if (now >= self.jinx_message_until)
        {
            self jinx_message_remove(0);
            self.jinx_message_until = 0;
        }
        else if (self.jinx_message_style == "Scrolling Text" && isDefined(self.jinx_message_hud[0]))
        {
            self.jinx_message_hud[0] moveOverTime(0.1);
            self.jinx_message_hud[0].x = sin((now - self.jinx_message_start) * 0.025) * 24;
        }
        else if (self.jinx_message_style == "Typewriter Message" && isDefined(self.jinx_message_hud[0]))
        {
            count = int((now - self.jinx_message_start) / 70);
            if (count > self.jinx_message_body.size) count = self.jinx_message_body.size;
            text = getSubStr(self.jinx_message_body, 0, count);
            self.jinx_message_hud[0] jinx_set_text(self jinx_message_paint(text, false));
        }
    }
    if (isDefined(self.jinx_message_hud[0]) && !self.jinx_message_fading && now >= self.jinx_message_until - 600)
    {
        self.jinx_message_fading = true;
        self.jinx_message_hud[0] fadeOverTime(0.6);
        self.jinx_message_hud[0].alpha = 0;
    }
    if (self jinx_message_on("msg_custom"))
    {
        hud = self jinx_message_element(1);
        hud.y = -165;
        hud.fontScale = 1.2;
        hud jinx_set_text(self jinx_message_paint(self jinx_message_text(), false));
    }
    else self jinx_message_remove(1);

}

jinx_message_on(key)
{
    return isDefined(self.jinx_message_flags[key]) && self.jinx_message_flags[key];
}

jinx_message_stop()
{
    self jinx_message_clear();
    // HUD is per life, preferences are not. Never clear the message host on death.
    self.jinx_message_life_kills = 0;
    self.jinx_message_kills_seen = undefined;
}

jinx_practice_sniper(weapon)
{
    parts = strTok(weapon, "+");
    return parts.size > 0 && jinx_gun_group(parts[0]) == 25;
}

jinx_message_limit(text, limit)
{
    if (text.size <= limit) return text;
    return getSubStr(text, 0, limit);
}

jinx_message_allowed()
{
    if (!(self isHost()) || level.jinx_phase1_ended) return false;
    // rankedmatch is derived from XP mode, not proof of a public session.
    return sessionModeIsPrivate() || sessionModeIsSystemLink() || !sessionModeIsOnlineGame();
}

// One independent level service: automatic prints survive host death and menus.
// Only the two optional visual HUD elements depend on the living-host HUD poll.
jinx_message_service()
{
    level endon("game_ended");
    for (;;)
    {
        wait 0.1;
        if (!isDefined(level.players)) continue;
        host = undefined;
        current = [];
        for (i = 0; i < level.players.size; i++)
        {
            player = level.players[i];
            if (!isDefined(player) || !isDefined(player.jinx_message_id)) continue;
            name = "Player";
            if (isDefined(player.name)) name = jinx_message_limit(player.name, 24);
            current[player.jinx_message_id] = name;
            if (player isHost()) host = player;
        }
        if (isDefined(host) && host jinx_message_allowed())
        {
            level.jinx_message_host = host;
            now = getTime();
            // Compare serials, not reusable entity numbers or deleted entities.
            keys = getArrayKeys(current);
            for (i = 0; i < keys.size; i++)
                if (!isDefined(level.jinx_message_roster[keys[i]]) && keys[i] != host.jinx_message_id && host jinx_message_on("msg_welcome"))
                    host jinx_message_broadcast("Welcome, " + current[keys[i]] + "! JINX is ready.");
            keys = getArrayKeys(level.jinx_message_roster);
            for (i = 0; i < keys.size; i++)
                if (!isDefined(current[keys[i]]) && host jinx_message_on("msg_disconnect"))
                    host jinx_message_broadcast(level.jinx_message_roster[keys[i]] + " left the lobby. See you next time!");
            if (host jinx_message_on("msg_repeat") && now >= host.jinx_message_repeat_at)
            {
                if (host jinx_message_broadcast(host jinx_message_text())) host.jinx_message_repeat_left--;
                host.jinx_message_repeat_at = now + 5000;
                if (host.jinx_message_repeat_left <= 0)
                {
                    host.jinx_message_flags["msg_repeat"] = false;
                    if (host.jinx_open && (host.jinx_category == 3 || host.jinx_category == 55)) host jinx_render(false);
                }
            }
            if (isDefined(host.kills))
            {
                if (!isDefined(host.jinx_message_kills_seen)) host.jinx_message_kills_seen = host.kills;
                gained = host.kills - host.jinx_message_kills_seen;
                host.jinx_message_kills_seen = host.kills;
                if (gained > 0 && isAlive(host))
                {
                    host.jinx_message_life_kills += gained;
                    if (host jinx_message_on("msg_streak"))
                        host jinx_message_broadcast("Killstreak: " + host.jinx_message_life_kills + " kills without dying!");
                }
            }
            if (level.jinx_message_queue_count > 0 && now >= level.jinx_message_send_at)
            {
                text = level.jinx_message_queue[level.jinx_message_queue_head];
                level.jinx_message_queue[level.jinx_message_queue_head] = undefined;
                level.jinx_message_queue_head = (level.jinx_message_queue_head + 1) % 16;
                level.jinx_message_queue_count--;
                level.jinx_message_send_at = now + 500;
                for (i = 0; i < level.players.size; i++)
                    if (isDefined(level.players[i])) level.players[i] iprintln("^1JINX: ^7" + text);
            }
        }
        else
        {
            // Never carry pending broadcasts across host departure/session change.
            level.jinx_message_queue = [];
            level.jinx_message_queue_head = 0;
            level.jinx_message_queue_count = 0;
        }
        level.jinx_message_roster = current;
    }
}


jinx_minimap_prepare()
{
    level.jinx_map_material = undefined;
    materials = [];
    materials["mp_bridge"] = "compass_map_mp_bridge";
    materials["mp_carrier"] = "compass_map_mp_carrier";
    materials["mp_castaway"] = "compass_map_mp_castaway";
    materials["mp_concert"] = "compass_map_mp_concert";
    materials["mp_dig"] = "compass_map_mp_dig";
    materials["mp_dockside"] = "compass_map_mp_dockside";
    materials["mp_downhill"] = "compass_map_mp_downhill";
    materials["mp_drone"] = "compass_map_mp_drone";
    materials["mp_express"] = "compass_map_mp_express";
    materials["mp_frostbite"] = "compass_map_mp_frostbite";
    materials["mp_hijacked"] = "compass_map_mp_hijacked";
    materials["mp_hydro"] = "compass_map_mp_hydro";
    materials["mp_la"] = "compass_map_mp_la";
    materials["mp_magma"] = "compass_map_mp_magma";
    materials["mp_meltdown"] = "compass_map_mp_meltdown";
    materials["mp_mirage"] = "compass_map_mp_mirage";
    materials["mp_nightclub"] = "compass_map_mp_nightclub";
    materials["mp_nuketown_2020"] = "compass_map_mp_nuketown_2020";
    materials["mp_overflow"] = "compass_map_mp_overflow";
    materials["mp_paintball"] = "compass_map_mp_paintball";
    materials["mp_pod"] = "compass_map_mp_pod";
    materials["mp_raid"] = "compass_map_mp_raid";
    materials["mp_skate"] = "compass_map_mp_skate";
    materials["mp_slums"] = "compass_map_mp_slums";
    materials["mp_socotra"] = "compass_map_mp_socotra";
    materials["mp_studio"] = "compass_map_mp_studio";
    materials["mp_takeoff"] = "compass_map_mp_takeoff";
    materials["mp_turbine"] = "compass_map_mp_turbine";
    materials["mp_uplink"] = "compass_map_mp_uplink";
    materials["mp_vertigo"] = "compass_map_mp_vertigo";
    materials["mp_village"] = "compass_map_mp_village";
    if (!isDefined(level.script) || !isDefined(materials[level.script])) return;
    level.jinx_map_material = materials[level.script];
    precacheShader(level.jinx_map_material);
}

jinx_minimap_init()
{
    self.jinx_map_on = false;
    self.jinx_map_info_on = false;
    self.jinx_map_hud = [];
    self.jinx_map_next = 0;
    self.jinx_map_flags = [];
    self.jinx_map_flags["Draw Friendly"] = false;
    self.jinx_map_flags["Draw Enemy"] = true;
    self.jinx_map_flags["Draw Names"] = false;
    self.jinx_map_flags["Draw Distance"] = false;
    self.jinx_map_flags["Draw Weapons"] = false;
    self.jinx_map_flags["Draw Health"] = false;
}

jinx_minimap_state(name)
{
    if (name == "Normal Map") return "RESTORE";
    if (name == "Full Map")
    {
        if (self.jinx_map_on) return "^2ON";
        return "SHOW";
    }
    if (name == "Radar Always On") return self jinx_toggle_label("radar");
    if (name == "Red Boxes (ESP)") return self jinx_toggle_label("esp");
    if (name == "UAV") return "GIVE";
    if (isDefined(self.jinx_map_flags[name]))
    {
        if (self.jinx_map_flags[name]) return "^2ON";
        return "^1OFF";
    }
    return "^8--";
}

jinx_minimap_action(name)
{
    if (!(self jinx_practice_allowed()))
    {
        self jinx_notice("Mini Map tools require a private/local host match.");
        return;
    }
    if (name == "Normal Map")
    {
        self.jinx_map_on = false;
        self jinx_minimap_destroy();
        self jinx_render(false);
        self jinx_notice("Extra tactical map hidden. Native minimap kept.");
        return;
    }
    if (name == "Radar Always On" || name == "Red Boxes (ESP)")
    {
        key = "radar";
        if (name == "Red Boxes (ESP)") key = "esp";
        self jinx_toggle_effect(key);
        self jinx_render(false);
        return;
    }
    if (name == "UAV")
    {
        if (!isDefined(level.killstreaks) || !isDefined(level.killstreaks["radar_mp"]))
        {
            self jinx_notice("UAV is disabled by this match's game rules.");
            return;
        }
        if (self isRemoteControlling() || self isInVehicle())
        {
            self jinx_notice("Exit remote control / vehicle first.");
            return;
        }
        self maps\mp\killstreaks\_killstreaks::givekillstreakweapon("radar_mp", 1);
        self jinx_notice("UAV added. Activate it with your scorestreak control.");
        return;
    }
    if (name == "Full Map")
    {
        if (!self.jinx_map_on && !jinx_minimap_bounds())
        {
            self jinx_notice("No verified compass material/corners for this map.");
            return;
        }
        self.jinx_map_on = !self.jinx_map_on;
        self jinx_minimap_destroy();
        self jinx_render(false);
        self jinx_close();
        return;
    }
    if (isDefined(self.jinx_map_flags[name]))
    {
        self.jinx_map_flags[name] = !self.jinx_map_flags[name];
        self.jinx_map_info_on = self.jinx_map_flags["Draw Names"] || self.jinx_map_flags["Draw Distance"] || self.jinx_map_flags["Draw Weapons"] || self.jinx_map_flags["Draw Health"];
        self jinx_minimap_destroy();
        self jinx_render(false);
        self jinx_notice("Draw info: upper-right corner, up to 4 players.\nFull Map is controlled separately.");
        return;
    }
    if (name == "Draw Snaplines") self jinx_notice("Not implemented: no verified production HUD line\nrenderer in this build. Native radar is available.");
    else if (name == "Draw Bones") self jinx_notice("Not implemented: skeleton projection is unverified.\nNo fake bones toggle is enabled.");
    else if (name == "Draw 2D/3D Boxes") self jinx_notice("Body boxes are not implemented. Use Red Boxes\nfor verified torso waypoint markers.");
}

// Same north/west axes and minimap_corner entities used by stock _compass.gsc.
jinx_minimap_bounds()
{
    if (!isDefined(level.jinx_map_material)) return false;
    if (isDefined(level.jinx_map_bounds_ready)) return true;
    corners = getEntArray("minimap_corner", "targetname");
    if (corners.size != 2) return false;
    north = (cos(getNorthYaw()), sin(getNorthYaw()), 0);
    west = (0 - north[1], north[0], 0);
    n0 = vectorDot(corners[0].origin, north);
    n1 = vectorDot(corners[1].origin, north);
    w0 = vectorDot(corners[0].origin, west);
    w1 = vectorDot(corners[1].origin, west);
    nspan = n1 - n0;
    wspan = w1 - w0;
    if (nspan < 0) nspan = 0 - nspan;
    if (wspan < 0) wspan = 0 - wspan;
    if (nspan < 1 || wspan < 1) return false;
    aspect = maps\mp\_utility::getdvarfloatdefault("scr_RequiredMapAspectratio", 0);
    if (aspect > 0)
    {
        if (wspan / nspan < aspect) wspan = nspan * aspect;
        else nspan = wspan / aspect;
    }
    level.jinx_map_north = north;
    level.jinx_map_west = west;
    level.jinx_map_nmax = (n0 + n1) / 2 + nspan / 2;
    level.jinx_map_wmax = (w0 + w1) / 2 + wspan / 2;
    level.jinx_map_nspan = nspan;
    level.jinx_map_wspan = wspan;
    level.jinx_map_width = 200;
    level.jinx_map_height = 200;
    if (wspan > nspan) level.jinx_map_height = int(200 * nspan / wspan);
    else level.jinx_map_width = int(200 * wspan / nspan);
    level.jinx_map_bounds_ready = true;
    return true;
}

jinx_minimap_xy(origin)
{
    x = (level.jinx_map_wmax - vectorDot(origin, level.jinx_map_west)) / level.jinx_map_wspan;
    y = (level.jinx_map_nmax - vectorDot(origin, level.jinx_map_north)) / level.jinx_map_nspan;
    return (x, y, 0);
}

// 12 fixed HUD slots: optional map/title/self, four markers/labels, info header.
// Labels are separate from the map. No large background obscures gameplay.
jinx_minimap_build()
{
    for (i = 0; i < 12; i++)
    {
        hud = newClientHudElem(self);
        hud.horzAlign = "center";
        hud.vertAlign = "middle";
        hud.alignX = "center";
        hud.alignY = "middle";
        hud.archived = false;
        hud.hideWhenInMenu = true;
        hud.font = "objective";
        hud.fontScale = 1.0;
        hud.color = (1, 1, 1);
        hud.alpha = 0;
        hud.sort = 10;
        self.jinx_map_hud[i] = hud;
    }
    if (self.jinx_map_on)
    {
        map = self.jinx_map_hud[0];
        map.x = -180;
        map.y = 10;
        map.sort = 7;
        map.alpha = 0.85;
        map setShader(level.jinx_map_material, level.jinx_map_width, level.jinx_map_height);
        title = self.jinx_map_hud[1];
        title.x = -180;
        title.y = -105;
        title.alpha = 1;
        self.jinx_map_hud[2] setShader("white", 5, 5);
    }
    for (slot = 0; slot < 4; slot++)
    {
        label = self.jinx_map_hud[4 + slot * 2];
        label.horzAlign = "right";
        label.vertAlign = "top";
        label.alignX = "right";
        label.alignY = "top";
        label.x = -14;
        label.y = 36 + slot * 30;
    }
    header = self.jinx_map_hud[11];
    header.horzAlign = "right";
    header.vertAlign = "top";
    header.alignX = "right";
    header.alignY = "top";
    header.x = -14;
    header.y = 19;
    self thread jinx_minimap_disconnect(self.jinx_map_hud);
}

jinx_minimap_tick(now)
{
    if (self.jinx_open || !(self jinx_practice_allowed())) return;
    if (!self.jinx_map_on && !self.jinx_map_info_on) return;
    if (now < self.jinx_map_next) return;
    self.jinx_map_next = now + 200;
    if (self.jinx_map_on && !jinx_minimap_bounds()) return;
    if (self.jinx_map_hud.size == 0) self jinx_minimap_build();
    if (self.jinx_map_on)
    {
        xy = jinx_minimap_xy(self.origin);
        self.jinx_map_hud[2].x = -180 + (xy[0] - 0.5) * level.jinx_map_width;
        self.jinx_map_hud[2].y = 10 + (xy[1] - 0.5) * level.jinx_map_height;
        self.jinx_map_hud[2].alpha = 0;
        if (xy[0] >= 0 && xy[0] <= 1 && xy[1] >= 0 && xy[1] <= 1) self.jinx_map_hud[2].alpha = 1;
    }
    selected = [];
    eligible = 0;
    for (i = 0; i < level.players.size; i++)
        if (self jinx_minimap_target(level.players[i])) eligible++;
    for (slot = 0; slot < 4; slot++)
    {
        best = undefined;
        nearest = 99999999;
        for (i = 0; i < level.players.size; i++)
        {
            target = level.players[i];
            if (!(self jinx_minimap_target(target)) || jinx_in_list(selected, target)) continue;
            d = distance(self.origin, target.origin);
            if (d < nearest)
            {
                best = target;
                nearest = d;
            }
        }
        marker = self.jinx_map_hud[3 + slot * 2];
        label = self.jinx_map_hud[4 + slot * 2];
        marker.alpha = 0;
        label.alpha = 0;
        if (!isDefined(best)) continue;
        selected[selected.size] = best;
        friendly = level.teambased && best.team == self.team;
        color = (1, 0.1, 0.1);
        if (friendly || self jinx_practice_visible(best, best getTagOrigin("j_spine4"))) color = (0.1, 1, 0.2);
        if (self.jinx_map_on)
        {
            xy = jinx_minimap_xy(best.origin);
            marker.x = -180 + (xy[0] - 0.5) * level.jinx_map_width;
            marker.y = 10 + (xy[1] - 0.5) * level.jinx_map_height;
            marker.color = color;
            if (xy[0] >= 0 && xy[0] <= 1 && xy[1] >= 0 && xy[1] <= 1) marker.alpha = 1;
            marker jinx_set_text("" + (slot + 1));
        }
        if (!self.jinx_map_info_on) continue;
        label.alpha = 0.95;
        label.color = color;
        text = "" + (slot + 1);
        if (self.jinx_map_flags["Draw Names"]) text += " " + jinx_message_limit(best.name, 14);
        if (self.jinx_map_flags["Draw Distance"]) text += " " + int(nearest * 0.0254) + "m";
        extra = "";
        if (self.jinx_map_flags["Draw Weapons"])
        {
            parts = strTok(best getCurrentWeapon(), "+");
            if (parts.size > 0) extra = jinx_message_limit(parts[0], 18);
        }
        if (self.jinx_map_flags["Draw Health"]) extra += " HP:" + best.health;
        if (extra != "") text += "\n" + extra;
        label jinx_set_text(text);
    }
    if (self.jinx_map_on) self.jinx_map_hud[1] jinx_set_text("^1JINX ^7MAP " + selected.size + "/" + eligible);
    if (self.jinx_map_info_on)
    {
        self.jinx_map_hud[11].alpha = 0.9;
        self.jinx_map_hud[11] jinx_set_text("^1JINX ^7INFO " + selected.size + "/" + eligible);
    }
}

jinx_minimap_target(target)
{
    if (!isDefined(target) || target == self || !isAlive(target)) return false;
    if (target.sessionstate != "playing") return false;
    friendly = level.teambased && target.team == self.team;
    if (friendly) return self.jinx_map_flags["Draw Friendly"];
    return self.jinx_map_flags["Draw Enemy"];
}

jinx_minimap_destroy()
{
    self notify("jinx_minimap_removed");
    if (!isDefined(self.jinx_map_hud)) return;
    for (i = 0; i < self.jinx_map_hud.size; i++)
        if (isDefined(self.jinx_map_hud[i])) self.jinx_map_hud[i] destroy();
    self.jinx_map_hud = [];
}

jinx_minimap_disconnect(elements)
{
    self endon("jinx_minimap_removed");
    self waittill("disconnect");
    for (i = 0; i < elements.size; i++)
        if (isDefined(elements[i])) elements[i] destroy();
}

// ---- Private-host lobby tools --------------------------------------------
jinx_lobby_init()
{
    level.jinx_lobby = [];
    level.jinx_lobby["Freeze Lobby"] = false;
    level.jinx_lobby["Super Jump"] = false;
    level.jinx_lobby["Super Speed"] = false;
    level.jinx_lobby["Unlimited Game Time"] = false;
    level.jinx_lobby["Disable Killcam"] = false;
    level.jinx_lobby["Disable Final Killcam"] = false;
    level.jinx_lobby["Long Killcams"] = false;
    level.jinx_lobby_speed = 1;
    level.jinx_lobby_active = false;
}

jinx_lobby_state(name)
{
    if (name == "Anti-Quit") { if (level.jinx_anti_quit) return "^2PAUSE LOCK"; return "^1OFF"; }
    if (name == "Anti-Join") { if (level.jinx_join_locked) return "^2LOCKED"; return "^1OPEN"; }
    if (name == "Death Barriers ON/OFF") { if (level.jinx_hazard_filter) return "^3FILTER"; return "^2NORMAL"; }
    if (name == "Long Melee") { if (isDefined(level.jinx_melee_old)) return "^2ON"; return "^1OFF"; }
    if (name == "Bot Menu") return ">";
    if (name == "Set Game Speed") return "" + level.jinx_lobby_speed + "x";
    if (name == "End Game" || name == "Fast Restart" || name == "Tie Game") return "USE";
    if (name == "Private Match Settings") return "INFO";
    if (name == "Ranked Match (Off)") return "^2OFF";
    if (isDefined(level.jinx_lobby[name]))
    {
        if (level.jinx_lobby[name]) return "^2ON";
        return "^1OFF";
    }
    return "^8--";
}

jinx_lobby_action(name)
{
    if (!(self jinx_message_allowed())) return;
    if (name == "Anti-Join")
    {
        level.jinx_join_locked = !level.jinx_join_locked;
        foreach (p in level.players) if (isDefined(p)) p.jinx_join_allowed = true;
        if (level.jinx_join_locked) jinx_bot_cancel_add();
        self jinx_render(false);
        self jinx_notice("Anti-Join blocks NEW humans AND bots. Current players stay. Turn OFF before adding bots."); return;
    }
    if (name == "Anti-Quit")
    {
        if (isDefined(level.gameended) && level.gameended) return;
        level.jinx_anti_quit = !level.jinx_anti_quit;
        setMatchFlag("disableIngameMenu", level.jinx_anti_quit);
        self jinx_render(false);
        self jinx_notice("Anti-Quit locks the native pause menu for this match. JINX remains usable. OFF unlocks pause; closing the app/disconnecting is still possible."); return;
    }
    if (name == "Long Melee") { self jinx_long_melee(); return; }
    if (name == "Death Barriers ON/OFF")
    {
        if (!level.jinx_hazard_filter && !jinx_damage_filter_install()) { self jinx_notice("Damage callback is not ready."); return; }
        level.jinx_hazard_filter = !level.jinx_hazard_filter;
        jinx_damage_filter_release(); self jinx_render(false);
        self jinx_notice("FILTER blocks MOD_TRIGGER_HURT damage only. Map-script suicides, drowning scripts and world limits may still kill. Not universal God Mode."); return;
    }
    if (name == "End Game" || name == "Fast Restart" || name == "Tie Game")
    {
        // Prevent an accidental match exit while navigating: select twice.
        if (!isDefined(self.jinx_lobby_confirm) || self.jinx_lobby_confirm != name || getTime() > self.jinx_lobby_confirm_until)
        {
            self.jinx_lobby_confirm = name;
            self.jinx_lobby_confirm_until = getTime() + 4000;
            self jinx_notice("Select " + name + " again within 4 seconds to confirm.");
            return;
        }
        self.jinx_lobby_confirm = undefined;
        if (name == "Fast Restart")
        {
            jinx_game_cleanup();
            jinx_radar_global_restore();
            jinx_lobby_cleanup();
            // Stock _pregame uses 0 to start a fresh match; 1 retains round state.
            maps\mp\gametypes\_globallogic_score::resetallscores();
            map_restart(0);
            return;
        }
        if (name == "Tie Game")
        {
            // Round-based modes can have their own win bookkeeping.
            if (level.gametype != "tdm")
            {
                self jinx_notice("Tie Game currently supports Team Deathmatch only.");
                return;
            }
            level.forcedend = 1;
            level thread maps\mp\gametypes\_globallogic::endgame("tie", &"MP_HOST_ENDED_GAME");
        }
        else level thread maps\mp\gametypes\_globallogic::forceend(false);
        return;
    }
    if (name == "Private Match Settings")
    {
        self jinx_notice("Private/local host | " + level.gametype + "\nPlayers: " + level.players.size + " | Time limit: " + level.timelimit + " min");
        return;
    }
    if (name == "Ranked Match (Off)")
    {
        self jinx_notice("This menu stays in private/local unranked matches.");
        return;
    }
    if (name == "Set Game Speed")
    {
        speed = level.jinx_lobby_speed;
        if (speed == 1) speed = 1.25;
        else if (speed == 1.25) speed = 1.5;
        else if (speed == 1.5) speed = 0.5;
        else if (speed == 0.5) speed = 0.75;
        else speed = 1;
        setSlowMotion(level.jinx_lobby_speed, speed, 0.25);
        level.jinx_lobby_speed = speed;
        level.jinx_lobby_active = true;
        self jinx_render(false);
        self jinx_notice("Whole-match game speed: " + speed + "x");
        return;
    }
    if (!isDefined(level.jinx_lobby[name]))
    {
        if (name == "Anti-Quit") self jinx_notice("Unavailable: GSC cannot prevent a player from leaving.");
        else if (name == "Force Host") self jinx_notice("You must already host this private match.\nHost selection is not changed by this menu.");
        else if (name == "XP Lobby") self jinx_notice("Not implemented: no persistent XP/rank changes.");
        else if (name == "Clear Killfeed") self jinx_notice("Not implemented: no verified native killfeed clear.\nMessages expire using the game's normal timing.");
        return;
    }
    on = !level.jinx_lobby[name];
    if (name == "Disable Killcam")
    {
        if (on) level.jinx_lobby_old_killcam = level.killcam;
        if (on) level.killcam = 0;
        else level.killcam = level.jinx_lobby_old_killcam;
    }
    if (name == "Disable Final Killcam")
    {
        if (on) level.jinx_lobby_old_final = level.finalkillcam;
        if (on) level.finalkillcam = 0;
        else level.finalkillcam = level.jinx_lobby_old_final;
        if (on) maps\mp\gametypes\_killcam::erasefinalkillcam();
        for (i = 0; i < level.players.size; i++)
            if (isDefined(level.players[i])) level.players[i] jinx_lobby_final_player(on);
    }
    if (name == "Long Killcams")
    {
        if (on)
        {
            // Stock _killcam::calckillcamtime reads this dvar (seconds).
            // Save the string, including empty = engine/script default behavior.
            level.jinx_lobby_old_camtime = getDvar(#"scr_killcam_time");
            setDvar("scr_killcam_time", 8);
        }
        else setDvar("scr_killcam_time", level.jinx_lobby_old_camtime);
    }
    if (name == "Unlimited Game Time")
    {
        if (on)
        {
            level.jinx_lobby_old_timelimit = level.timelimit;
            level.jinx_lobby_old_gettimelimit = level.gettimelimit;
            level.gettimelimit = ::jinx_lobby_no_time_limit;
            level.timelimit = 0;
            setDvar("ui_timelimit", 0);
            setGameEndTime(0);
        }
        else jinx_lobby_restore_time();
        level notify("update_timelimit");
    }
    level.jinx_lobby[name] = on;
    level.jinx_lobby_active = true;
    self jinx_render(false);
    status = "OFF";
    if (on) status = "ON";
    if (name == "Freeze Lobby") self jinx_notice("Freeze Lobby " + status + " | Host excluded.");
    else if (name == "Long Killcams") self jinx_notice("Regular killcams " + status + " | 8s request,\nlimited by replay history and respawn timing.");
    else self jinx_notice(name + " " + status);
}

jinx_lobby_no_time_limit()
{
    return 0;
}

jinx_lobby_restore_time()
{
    if (!isDefined(level.jinx_lobby_old_gettimelimit)) return;
    level.gettimelimit = level.jinx_lobby_old_gettimelimit;
    level.timelimit = level.jinx_lobby_old_timelimit;
    setDvar("ui_timelimit", level.timelimit);
    level.jinx_lobby_old_gettimelimit = undefined;
    level notify("update_timelimit");
}

jinx_lobby_release_speed()
{
    if (!isDefined(self.jinx_lobby_old_speed)) return;
    self setMoveSpeedScale(self.jinx_lobby_old_speed);
    self.jinx_lobby_old_speed = undefined;
}

jinx_lobby_release_player()
{
    self jinx_lobby_release_speed();
    if (isDefined(self.jinx_lobby_frozen) && self.jinx_lobby_frozen)
    {
        if (!isDefined(self.jinx_practice_frozen)) self freezeControls(false);
        self.jinx_lobby_frozen = false;
    }
    self.jinx_lobby_grounded = false;
}

// One level service for all players; lobby state survives host respawn.
jinx_lobby_service()
{
    level endon("game_ended");
    for (;;)
    {
        wait 0.1;
        if (!level.jinx_lobby_active || !isDefined(level.players)) continue;
        host = undefined;
        for (i = 0; i < level.players.size; i++)
            if (isDefined(level.players[i]) && level.players[i] isHost()) host = level.players[i];
        if (!isDefined(host) || !(host jinx_message_allowed()))
        {
            jinx_lobby_cleanup();
            continue;
        }
        for (i = 0; i < level.players.size; i++)
        {
            player = level.players[i];
            if (!isDefined(player)) continue;
            player jinx_lobby_final_player(level.jinx_lobby["Disable Final Killcam"]);
            if (!isAlive(player) || player.sessionstate != "playing")
            {
                player jinx_lobby_release_player();
                continue;
            }
            freeze = level.jinx_lobby["Freeze Lobby"] && player != host;
            if (freeze)
            {
                player freezeControls(true);
                player.jinx_lobby_frozen = true;
            }
            else if (isDefined(player.jinx_lobby_frozen) && player.jinx_lobby_frozen)
            {
                if (!isDefined(player.jinx_practice_frozen)) player freezeControls(false);
                player.jinx_lobby_frozen = false;
            }
            ownspeed = isDefined(player.jinx_fx) && player jinx_enabled("speed");
            if (level.jinx_lobby["Super Speed"] && !ownspeed)
            {
                if (!isDefined(player.jinx_lobby_old_speed)) player.jinx_lobby_old_speed = player getMoveSpeedScale();
                player setMoveSpeedScale(player.jinx_lobby_old_speed * 2.25);
            }
            else player jinx_lobby_release_speed();
            grounded = player isOnGround();
            ownjump = isDefined(player.jinx_fx) && (player jinx_enabled("jump") || player jinx_enabled("noclip") || player jinx_enabled("freeze"));
            if (level.jinx_lobby["Super Jump"] && !freeze && !ownjump && !grounded && isDefined(player.jinx_lobby_grounded) && player.jinx_lobby_grounded)
            {
                velocity = player getVelocity();
                if (velocity[2] > 80 && !(player isInVehicle()) && !(player isRemoteControlling()))
                    player setVelocity((velocity[0], velocity[1], 1600));
            }
            player.jinx_lobby_grounded = grounded;
        }
    }
}

jinx_lobby_cleanup()
{
    level.jinx_join_locked = false;
    level.jinx_hazard_filter = false;
    if (isDefined(level.jinx_anti_quit) && level.jinx_anti_quit)
    {
        // End-game code owns this flag once the match has ended.
        if (!isDefined(level.gameended) || !level.gameended) setMatchFlag("disableIngameMenu", false);
        level.jinx_anti_quit = false;
    }
    jinx_long_melee_restore();
    jinx_damage_filter_release();
    if (!isDefined(level.jinx_lobby)) return;
    if (level.jinx_lobby["Disable Final Killcam"]) maps\mp\gametypes\_killcam::erasefinalkillcam();
    if (level.jinx_lobby_speed != 1) setSlowMotion(1, 1, 0);
    level.jinx_lobby_speed = 1;
    jinx_lobby_restore_time();
    if (level.jinx_lobby["Long Killcams"])
        setDvar("scr_killcam_time", level.jinx_lobby_old_camtime);
    // Do not re-enable the final replay when game_ended fires before playback.
    // These two fields are level-local and will be initialized by the next map.
    if (!isDefined(level.gameended) || !level.gameended)
    {
        if (level.jinx_lobby["Disable Killcam"]) level.killcam = level.jinx_lobby_old_killcam;
        if (level.jinx_lobby["Disable Final Killcam"]) level.finalkillcam = level.jinx_lobby_old_final;
    }
    keys = getArrayKeys(level.jinx_lobby);
    for (i = 0; i < keys.size; i++) level.jinx_lobby[keys[i]] = false;
    if (isDefined(level.players))
        for (i = 0; i < level.players.size; i++)
            if (isDefined(level.players[i]))
            {
                level.players[i] jinx_lobby_release_player();
                level.players[i] jinx_lobby_final_player(false);
            }
    level.jinx_lobby_active = false;
}

// Stock player-killed callback suppresses final replay recording if the
// attacker has disablefinalkillcam defined. Preserve any previous owner.
jinx_lobby_final_player(on)
{
    if (on)
    {
        if (!isDefined(self.jinx_lobby_final_owned))
        {
            self.jinx_lobby_final_owned = true;
            self.jinx_lobby_final_previous = self.disablefinalkillcam;
        }
        self.disablefinalkillcam = true;
    }
    else if (isDefined(self.jinx_lobby_final_owned))
    {
        self.disablefinalkillcam = self.jinx_lobby_final_previous;
        self.jinx_lobby_final_owned = undefined;
        self.jinx_lobby_final_previous = undefined;
    }
}


jinx_ui_color_name(index)
{
    names = strTok("RED,CRIMSON,SCARLET,BLUE,CYAN,GREEN,PURPLE,PINK,ORANGE,GOLD,TEAL,WHITE", ",");
    return names[index];
}

jinx_panel_width()
{
    if (self.jinx_settings["design"] == 1) return 230;
    if (self.jinx_settings["design"] == 2) return 300;
    sizes = strTok("160,200,240,280,320,358", ",");
    return int(sizes[self.jinx_settings["width"]]);
}

jinx_panel_shape()
{
    if (self.jinx_settings["width"] == 0) return "TALL";
    if (self.jinx_settings["width"] == 5) return "SQUARE";
    return "WIDE";
}

jinx_background_name(index)
{
    names = strTok("BLACK,WINE,NAVY,FOREST,PURPLE,TEAL,CHARCOAL,BROWN", ",");
    return names[index];
}

jinx_background(index)
{
    colors = [];
    colors[0] = (0.005, 0.005, 0.005);
    colors[1] = (0.32, 0.015, 0.07);
    colors[2] = (0.02, 0.08, 0.34);
    colors[3] = (0.015, 0.27, 0.07);
    colors[4] = (0.25, 0.025, 0.34);
    colors[5] = (0.01, 0.26, 0.30);
    colors[6] = (0.19, 0.19, 0.21);
    colors[7] = (0.32, 0.14, 0.02);
    return colors[index];
}

jinx_ui_sound()
{
    if (!self.jinx_settings["sound"]) return;
    // Stock T6 MP _weapons.gsc equipment pickup cue. Scroll remains silent.
    if (isDefined(self.jinx_sound_at) && getTime() < self.jinx_sound_at) return;
    self.jinx_sound_at = getTime() + 300;
    self playLocalSound("fly_equipment_pickup_plr");
}

jinx_controls_notice()
{
    opening = "[{+speed_throw}] + [{+melee}]";
    closing = "[{+melee}] Back / Close";
    if (self.jinx_settings["openkey"]) opening = "[{+speed_throw}] + [{+activate}]";
    if (self.jinx_settings["closekey"]) closing = "[{+speed_throw}]+[{+melee}] Close | [{+melee}] Back";
    self iprintln("^1JINX: ^7Open: " + opening + " | " + closing);
}

jinx_menu_movement()
{
    if (!self.jinx_open) return;
    if (self.jinx_settings["move_menu"])
    {
        self freezeControls(false);
        self.jinx_owns_freeze = false;
    }
    else
    {
        self freezeControls(true);
        self.jinx_owns_freeze = true;
    }
}

jinx_countdown_movement()
{
    if (!(self jinx_message_allowed()) || !isAlive(self) || self.sessionstate != "playing") return;
    if (!isDefined(level.inprematchperiod) || !level.inprematchperiod) return;
    if (isDefined(level.hostmigrationtimer)) return;
    // Only lift the prematch freeze for the private host. Menu OFF preference
    // still wins while open. No countdown cancellation or combat-rule changes.
    canmove = self.jinx_settings["move_countdown"];
    if (self.jinx_open) canmove = self.jinx_settings["move_menu"];
    self maps\mp\_utility::freeze_player_controls(!canmove);
}

// Native radar contribution: counted alongside real satellite streaks.
jinx_radar_attach()
{
    if (!(self jinx_message_allowed())) return;
    if (!isDefined(level.activesatellites)) return;
    key = self getEntityNumber();
    if (level.teambased) key = self.team;
    if (isDefined(level.jinx_radar_key) && level.jinx_radar_key != key) jinx_radar_global_restore();
    if (!isDefined(level.jinx_radar_key))
    {
        if (!isDefined(level.activesatellites[key])) return;
        level.activesatellites[key]++;
        level.jinx_radar_key = key;
        level.jinx_radar_team = level.teambased;
        level.jinx_radar_range = maps\mp\_utility::getdvarfloatdefault("compassmaxrange", 2500);
        // Preserve the map zoom; the native satellite supplies detections.
    }
    if (level.teambased)
        maps\mp\killstreaks\_radar::setteamsatellitewrapper(self.team, 1);
    else self.hasSatellite = 1;
}

jinx_radar_release()
{
    if (isDefined(level.jinx_radar_range)) self setClientDvar("compassmaxrange", level.jinx_radar_range);
    jinx_radar_global_restore();
}

jinx_radar_global_restore()
{
    if (!isDefined(level.jinx_radar_key)) return;
    key = level.jinx_radar_key;
    if (isDefined(level.activesatellites[key]) && level.activesatellites[key] > 0) level.activesatellites[key]--;
    if (level.jinx_radar_team) maps\mp\killstreaks\_spyplane::updateteamuavstatus(key);
    else maps\mp\killstreaks\_spyplane::updateplayersuavstatus();
    setDvar("compassmaxrange", level.jinx_radar_range);
    if (isDefined(level.players))
        for (i = 0; i < level.players.size; i++)
            if (isDefined(level.players[i]) && level.players[i] isHost()) level.players[i] setClientDvar("compassmaxrange", level.jinx_radar_range);
    level.jinx_radar_key = undefined;
    level.jinx_radar_range = undefined;
}

// ---- Game Mods -----------------------------------------------------------
jinx_game_catalog()
{
    level.jinx_options[43] = strTok("Lightweight,Hardline,Blind Eye,Flak Jacket,Ghost,Toughness,Cold Blooded,Fast Hands,Hard Wired,Scavenger,Dexterity,Extreme Conditioning,Engineer,Tactical Mask,Dead Silence,Awareness,Give All Perks,Remove Added Perks", ",");
    level.jinx_game_perks = strTok("specialty_movefaster,specialty_killstreak,specialty_nottargetedbyairsupport,specialty_flakjacket,specialty_gpsjammer,specialty_bulletflinch,specialty_noname,specialty_fastequipmentuse,specialty_immunecounteruav,specialty_scavenger,specialty_fastads,specialty_longersprint,specialty_showenemyequipment,specialty_stunprotection,specialty_quieter,specialty_loudenemies", ",");
    level.jinx_titles[43] = "Perks Menu";
    level.jinx_options[44] = strTok("Sniper Only,Pistols Only,Shotguns Only,Knife Only,Headshots Only,Sniper Roulette,Gun Roulette,Stop Active Mode", ",");
    level.jinx_titles[44] = "Custom Game Modes";
    level.jinx_custom_mode = "";
    level.jinx_custom_weapon = "";
    level.jinx_game_gravity = 0;
}

jinx_game_state(category, name, unused)
{
    if (category == 43)
    {
        for (i = 0; i < level.jinx_game_perks.size; i++)
            if (name == level.jinx_options[43][i])
            {
                if (self hasPerk(level.jinx_game_perks[i])) return "^2ON";
                return "^1OFF";
            }
        return "USE";
    }
    if (name == "Killstreaks Menu" || name == "Scorestreaks Menu" || name == "Perks Menu" || name == "Custom Game Modes") return ">";
    if (name == "Super Jump") return self jinx_lobby_state(name);
    if (name == "Timescale") return self jinx_lobby_state("Set Game Speed");
    if (name == "Low Gravity" || name == "High Gravity")
    {
        if ((name == "Low Gravity" && level.jinx_game_gravity == 400) || (name == "High Gravity" && level.jinx_game_gravity == 1200)) return "^2ON";
        return "^1OFF";
    }
    if (name == "Crazy Vision")
    {
        if (isDefined(self.jinx_crazy_vision) && self.jinx_crazy_vision) return "^2ON";
        return "^1OFF";
    }
    if (name == level.jinx_custom_mode) return "^2ON";
    return "USE";
}

jinx_game_action(category, name, index)
{
    if (category == 43)
    {
        if (!isDefined(self.jinx_game_added_perks)) self.jinx_game_added_perks = [];
        if (index == 17) self jinx_game_perks_clear();
        else if (index == 16)
        {
            for (i = 0; i < level.jinx_game_perks.size; i++) self jinx_game_perk(i, true);
        }
        else self jinx_game_perk(index, !(self hasPerk(level.jinx_game_perks[index])));
        self jinx_render(false);
        return;
    }
    if (name == "Super Jump") { self jinx_lobby_action(name); return; }
    if (name == "Timescale") { self jinx_lobby_action("Set Game Speed"); return; }
    if (name == "Low Gravity" || name == "High Gravity")
    {
        value = 400;
        if (name == "High Gravity") value = 1200;
        if (self jinx_enabled("gravity")) self jinx_toggle_effect("gravity");
        if (level.jinx_game_gravity == value)
        {
            jinx_restore_gravity();
            level.jinx_game_gravity = 0;
        }
        else
        {
            if (!isDefined(level.jinx_gravity_changed) || !level.jinx_gravity_changed)
            {
                level.jinx_old_gravity = maps\mp\_utility::getdvarfloatdefault("bg_gravity", 800);
                level.jinx_old_jump_slowdown = maps\mp\_utility::getdvarfloatdefault("jump_slowdownEnable", 1);
            }
            level.jinx_gravity_changed = true;
            level.jinx_game_gravity = value;
            setDvar("bg_gravity", value);
            setDvar("jump_slowdownEnable", 0);
        }
        self jinx_render(false);
        self jinx_notice("Gravity changes affect the entire private match.");
        return;
    }
    if (name == "Crazy Vision")
    {
        if (self isRemoteControlling() || self isInVehicle()) { self jinx_notice("Exit remote control / vehicle first."); return; }
        on = !isDefined(self.jinx_crazy_vision) || !self.jinx_crazy_vision;
        self.jinx_crazy_vision = on;
        visible = on || (isDefined(self.jinx_menu_vision) && self.jinx_menu_vision);
        self useServerVisionSet(visible);
        if (visible) self setVisionSetForPlayer("mpIntro", 1);
        self jinx_render(false);
        return;
    }
    if (name == "Death Machine")
    {
        if (!isDefined(level.killstreaks) || !isDefined(level.killstreaks["minigun_mp"])) { self jinx_notice("Death Machine is disabled in this mode."); return; }
        self maps\mp\killstreaks\_killstreaks::givekillstreakweapon("minigun_mp", 1);
        self jinx_notice("Death Machine added. Use your scorestreak control.");
        return;
    }
    if (name == "Stop Active Mode" || name == level.jinx_custom_mode)
    {
        jinx_custom_stop();
        self jinx_render(false);
        self jinx_notice("Live mode stopped; original loadouts restored.");
        return;
    }
    self jinx_live_start(name);

}

jinx_game_perk(index, on)
{
    perk = level.jinx_game_perks[index];
    if (perk == "specialty_scavenger" && level.jinx_custom_mode == "One in the Chamber")
    {
        self jinx_notice("Scavenger is suspended during One in the Chamber.");
        return;
    }
    extra = "";
    if (index == 0) extra = "specialty_fallheight";
    if (index == 1) extra = "specialty_earnmoremomentum";
    if (index == 6) extra = "specialty_immunemms,specialty_immunenvthermal,specialty_immunerangefinder,specialty_nokillstreakreticle,specialty_nottargettedbysentry";
    if (index == 7) extra = "specialty_fasttoss,specialty_fastweaponswitch";
    if (index == 8) extra = "specialty_immuneemp";
    if (index == 10) extra = "specialty_fastladderclimb,specialty_fastmantle";
    if (index == 11) extra = "specialty_sprintrecovery";
    if (index == 12) extra = "specialty_detectexplosive,specialty_delayexplosive,specialty_disarmexplosive";
    if (index == 13) extra = "specialty_flashprotection,specialty_proximityprotection";
    all = strTok(perk + "," + extra, ",");
    for (i = 0; i < all.size; i++)
    {
        if (all[i] == "") continue;
        if (on && !(self hasPerk(all[i])))
        {
            self setPerk(all[i]);
            self.jinx_game_added_perks[all[i]] = true;
        }
        else if (!on && isDefined(self.jinx_game_added_perks[all[i]]))
        {
            self unsetPerk(all[i]);
            self.jinx_game_added_perks[all[i]] = undefined;
        }
    }
    if (!on && self hasPerk(perk)) self jinx_notice("Class-owned perk kept. Change class to remove it.");
}

jinx_game_perks_clear()
{
    if (!isDefined(self.jinx_game_added_perks)) return;
    keys = getArrayKeys(self.jinx_game_added_perks);
    for (i = 0; i < keys.size; i++)
        if (isDefined(self.jinx_game_added_perks[keys[i]])) self unsetPerk(keys[i]);
    self.jinx_game_added_perks = [];
}

// Live private loadout challenges, no custom damage or pretend game-mode label.
// Originals are kept per life; scorestreak activations are suspended by this mode.
jinx_custom_stop()
{
    if (isDefined(level.jinx_zombie_token)) level.jinx_zombie_token++;
    level.jinx_zombie_preparing = false;
    level notify("jinx_live_stop");
    if (isDefined(level.jinx_live_original_damage))
    {
        if (level.onplayerdamage == ::jinx_live_damage) level.onplayerdamage = level.jinx_live_original_damage;
        level.jinx_live_original_damage = undefined;
    }
    if (isDefined(level.onplayerkilledextraunthreadedcbs))
    {
        kept = [];
        for (c = 0; c < level.onplayerkilledextraunthreadedcbs.size; c++)
            if (level.onplayerkilledextraunthreadedcbs[c] != ::jinx_live_killed) kept[kept.size] = level.onplayerkilledextraunthreadedcbs[c];
        level.onplayerkilledextraunthreadedcbs = kept;
    }
    level.jinx_custom_mode = "";
    level.jinx_custom_weapon = "";
    if (!isDefined(level.players)) return;
    for (i = 0; i < level.players.size; i++)
    {
        p = level.players[i];
        if (!isDefined(p)) continue;
        p jinx_live_hud_clear();
        p notify("jinx_oic_listener_stop");
        if (isDefined(p.jinx_oic_scavenger) && p.jinx_oic_scavenger && isAlive(p)) p setPerk("specialty_scavenger");
        p.jinx_oic_scavenger = undefined;
        p.jinx_oic_budget = undefined;
        p.jinx_live_life_gun = undefined;
        if (!isDefined(p.jinx_arsenal_saved)) continue;
        if (isAlive(p) && p.sessionstate == "playing" && !(p isRemoteControlling()) && !(p isInVehicle()))
        {
            p takeAllWeapons();
            for (j = 0; j < p.jinx_arsenal_saved.size; j++)
            {
                w = p.jinx_arsenal_saved[j];
                p giveWeapon(w);
                p setWeaponAmmoClip(w, p.jinx_arsenal_clip[w]);
                p setWeaponAmmoStock(w, p.jinx_arsenal_stock[w]);
            }
            if (isDefined(p.jinx_live_offhand))
            {
                p.grenadetypeprimary = p.jinx_live_offhand;
                p setOffhandPrimaryClass(p.jinx_live_offhand);
            }
            if (p hasWeapon(p.jinx_arsenal_current)) p switchToWeapon(p.jinx_arsenal_current);
        }
        p.jinx_arsenal_saved = undefined;
        p.jinx_arsenal_applied = undefined;
    }
    jinx_zombie_restore_teams();
}

jinx_game_cleanup()
{
    jinx_custom_stop();
    jinx_restore_gravity();
    level.jinx_game_gravity = 0;
}

jinx_selection_seconds()
{
    values = [];
    values[0] = 0.05;
    values[1] = 0.10;
    values[2] = 0.18;
    values[3] = 0.25;
    return values[self.jinx_settings["selspeed"]];
}

// Live variants keep the base match's teams, score limit and respawn rules.
jinx_live_start(name, prepared)
{
    modes = strTok("Gun Game,Sticks and Stones,One in the Chamber,Sharpshooter,Sniper Only,Pistols Only,Shotguns Only,Knife Only,Headshots Only,Sniper Roulette,Gun Roulette,Zombie Mode (Fake)", ",");
    if (!jinx_in_list(modes, name)) return;
    if (name == "Zombie Mode (Fake)" && (!isDefined(prepared) || !prepared))
    { self thread jinx_prepare_zombies(); return; }
    if (!isDefined(level.onplayerdamage) || !isDefined(level.onplayerkilledextraunthreadedcbs))
    {
        self jinx_notice("Wait until the match has finished initializing.");
        return;
    }
    if (!isDefined(prepared) || !prepared) jinx_custom_stop();
    level.jinx_custom_mode = name;
    level.jinx_live_id = getTime();
    level.jinx_live_rotate = getTime() + 30000;
    level.jinx_live_cycle = 0;
    level.jinx_live_random = 0;
    level.jinx_live_sniper = randomInt(4);
    level.jinx_live_winner = false;
    level.jinx_live_guns = [];
    for (group = 22; group <= 27; group++)
        for (g = 0; g < level.jinx_weapon_groups[group].size; g++)
            level.jinx_live_guns[level.jinx_live_guns.size] = level.jinx_weapon_groups[group][g];
    level.jinx_live_guns[level.jinx_live_guns.size] = "crossbow_mp";
    level.jinx_live_guns[level.jinx_live_guns.size] = "knife_ballistic_mp";
    // Fisher-Yates: one shared randomized progression, all entries exactly once.
    for (g = level.jinx_live_guns.size - 1; g > 0; g--)
    {
        other = randomInt(g + 1);
        temp = level.jinx_live_guns[g];
        level.jinx_live_guns[g] = level.jinx_live_guns[other];
        level.jinx_live_guns[other] = temp;
    }
    level.jinx_live_random = randomInt(level.jinx_live_guns.size);
    level.jinx_live_original_damage = level.onplayerdamage;
    level.onplayerdamage = ::jinx_live_damage;
    level.onplayerkilledextraunthreadedcbs[level.onplayerkilledextraunthreadedcbs.size] = ::jinx_live_killed;
    // Start from the action itself, apply immediately, then maintain respawns.
    count = jinx_live_tick();
    level thread jinx_live_service();
    self jinx_render(false);
    self jinx_notice(name + " LIVE: equipped " + count + " players.\nBase teams/respawn stay. Stop Active Mode restores gear.");
}

jinx_live_service()
{
    level endon("jinx_live_stop");
    level endon("game_ended");
    for (;;)
    {
        wait 0.2;
        if (level.jinx_custom_mode == "") return;
        host = undefined;
        for (i = 0; i < level.players.size; i++)
            if (isDefined(level.players[i]) && level.players[i] isHost()) host = level.players[i];
        if (!isDefined(host) || !(host jinx_message_allowed())) { jinx_custom_stop(); return; }
        jinx_live_tick();
    }
}

jinx_live_tick()
{
    mode = level.jinx_custom_mode;
    if (mode == "") return 0;
    if (mode == "Zombie Mode (Fake)" && !jinx_zombie_teams_valid())
    {
        jinx_custom_stop();
        foreach (p in level.players) if (isDefined(p) && p isHost()) p jinx_notice("Zombie practice stopped: keep humans on one team and bots on the other.");
        return 0;
    }
    if ((mode == "Sharpshooter" || mode == "Gun Roulette" || mode == "Sniper Roulette") && getTime() >= level.jinx_live_rotate)
    {
        level.jinx_live_cycle++;
        level.jinx_live_random = randomInt(level.jinx_live_guns.size);
        level.jinx_live_sniper = randomInt(4);
        interval = 30000;
        if (mode == "Gun Roulette") interval = 15000;
        level.jinx_live_rotate = getTime() + interval;
    }
    count = 0;
    for (i = 0; i < level.players.size; i++)
    {
        p = level.players[i];
        if (!isDefined(p)) continue;
        if (!isDefined(p.jinx_live_id) || p.jinx_live_id != level.jinx_live_id)
        {
            p.jinx_live_id = level.jinx_live_id;
            p.jinx_live_rank = 0;
            p.jinx_live_points = 0;
            p.jinx_live_life_gun = undefined;
        }
        if (!isAlive(p) || p.sessionstate != "playing") { p jinx_live_hud_clear(); continue; }
        if (p isRemoteControlling() || p isInVehicle()) continue;
        if (isDefined(p.jinx_live_spawn_ready) && getTime() < p.jinx_live_spawn_ready) continue;
        if (mode == "One in the Chamber")
        {
            if (!isDefined(p.jinx_oic_scavenger)) p.jinx_oic_scavenger = p hasPerk("specialty_scavenger");
            if (p hasPerk("specialty_scavenger")) p unsetPerk("specialty_scavenger");
        }
        desired = p jinx_live_weapon();
        if (!isDefined(p.jinx_arsenal_saved))
        {
            p.jinx_arsenal_saved = p getWeaponsList();
            p.jinx_arsenal_current = p getCurrentWeapon();
            p.jinx_arsenal_clip = [];
            p.jinx_arsenal_stock = [];
            for (j = 0; j < p.jinx_arsenal_saved.size; j++)
            {
                w = p.jinx_arsenal_saved[j];
                p.jinx_arsenal_clip[w] = p getWeaponAmmoClip(w);
                p.jinx_arsenal_stock[w] = p getWeaponAmmoStock(w);
            }
            p.jinx_live_offhand = p.grenadetypeprimary;
        }
        signature = desired;
        if (mode == "Sharpshooter" || mode == "Gun Roulette" || mode == "Sniper Roulette") signature += level.jinx_live_cycle;
        if (!isDefined(p.jinx_arsenal_applied) || p.jinx_arsenal_applied != signature || !(p hasWeapon(desired)))
        {
            p takeAllWeapons();
            p giveWeapon("knife_mp");
            if (mode == "Sniper Only") p giveWeapon(desired, 0, level.jinx_camo_ids["Diamond"]);
            else p giveWeapon(desired);
            p giveMaxAmmo(desired);
            if (mode == "Sticks and Stones")
            {
                p giveWeapon("knife_ballistic_mp");
                p giveMaxAmmo("knife_ballistic_mp");
                p setOffhandPrimaryClass("hatchet_mp");
                p.grenadetypeprimary = "hatchet_mp";
                p giveWeapon("hatchet_mp");
                p setWeaponAmmoClip("hatchet_mp", 1);
                p setWeaponAmmoStock("hatchet_mp", 0);
            }
            if (mode == "One in the Chamber")
            {
                p notify("jinx_oic_listener_stop");
                p.jinx_oic_budget = 1;
                p thread jinx_oic_shots();
                p setWeaponAmmoClip(desired, 1);
                p setWeaponAmmoStock(desired, 0);
            }
            p switchToWeapon(desired);
            p.jinx_arsenal_applied = signature;
        }
        weapons = p getWeaponsList();
        for (j = 0; j < weapons.size; j++)
            if (!jinx_live_allowed(weapons[j], desired)) p takeWeapon(weapons[j]);
        if (mode == "One in the Chamber") p jinx_oic_cap();
        p jinx_live_hud();
        if (p hasWeapon(desired)) count++;
    }
    return count;
}

jinx_live_weapon()
{
    mode = level.jinx_custom_mode;
    if (mode == "Gun Game") return level.jinx_live_guns[self.jinx_live_rank];
    if (mode == "Sharpshooter" || mode == "Gun Roulette") return level.jinx_live_guns[level.jinx_live_random];
    if (mode == "Sniper Roulette")
    {
        guns = strTok("ballista_mp,dsr50_mp,svu_mp,as50_mp", ",");
        return guns[level.jinx_live_sniper];
    }
    if (mode == "One in the Chamber") return "kard_wager_mp";
    if (mode == "Sniper Only" || mode == "Pistols Only" || mode == "Shotguns Only")
    {
        if (!isDefined(self.jinx_live_life_gun))
        {
            guns = strTok("ballista_mp,dsr50_mp", ",");
            if (mode == "Pistols Only") guns = level.jinx_weapon_groups[27];
            if (mode == "Shotguns Only") guns = level.jinx_weapon_groups[26];
            self.jinx_live_life_gun = guns[randomInt(guns.size)];
        }
        return self.jinx_live_life_gun;
    }
    if (mode == "Zombie Mode (Fake)") { if (self is_bot()) return "knife_held_mp"; return "870mcs_mp"; }
    if (mode == "Knife Only") return "knife_held_mp";
    if (mode == "Sticks and Stones") return "crossbow_mp";
    if (mode == "Headshots Only") return "an94_mp";
    return "ballista_mp";
}

jinx_live_allowed(weapon, desired)
{
    if (weapon == "crossbow_explosive_mp" || weapon == "explosive_bolt_mp") weapon = "crossbow_mp";
    if (weapon == desired || weapon == "knife_mp") return true;
    if (level.jinx_custom_mode == "Sticks and Stones" && (weapon == "knife_ballistic_mp" || weapon == "hatchet_mp")) return true;
    return false;
}

jinx_live_damage(inflictor, attacker, damage, flags, mod, weapon, point, dir, hitloc, offset)
{
    previous = self [[level.jinx_live_original_damage]](inflictor, attacker, damage, flags, mod, weapon, point, dir, hitloc, offset);
    if (isDefined(previous)) damage = previous;
    if (damage <= 0 || !isDefined(attacker) || !isPlayer(attacker) || attacker == self) return damage;
    if (!isDefined(attacker.jinx_live_id) || attacker.jinx_live_id != level.jinx_live_id) return damage;
    desired = attacker jinx_live_weapon();
    parts = strTok(weapon, "+");
    if (parts.size == 0) return 0;
    base = parts[0];
    if (base == "crossbow_explosive_mp" || base == "explosive_bolt_mp") base = "crossbow_mp";
    allowed = jinx_live_allowed(base, desired);
    // Delayed bolts must still damage after the shooter advances a rank.
    if (level.jinx_custom_mode == "Gun Game" && jinx_in_list(level.jinx_live_guns, base)) allowed = true;
    if (!allowed) return 0;
    if (level.jinx_custom_mode == "Headshots Only" && hitloc != "head" && hitloc != "helmet") return 0;
    if (level.jinx_custom_mode == "One in the Chamber") return self.maxhealth + 100;
    return damage;
}

jinx_live_killed(inflictor, attacker, damage, mod, weapon, dir, hitloc, offset, duration)
{
    if (level.jinx_custom_mode == "" || level.jinx_live_winner) return;
    if (!isDefined(attacker) || !isPlayer(attacker) || attacker == self) return;
    if (level.teambased && attacker.team == self.team) return;
    if (!isDefined(attacker.jinx_live_id) || attacker.jinx_live_id != level.jinx_live_id) return;
    attacker.jinx_live_points++;
    mode = level.jinx_custom_mode;
    if (mode == "Gun Game")
    {
        if (mod == "MOD_MELEE")
        {
            if (isDefined(self.jinx_live_rank) && self.jinx_live_rank > 0) self.jinx_live_rank--;
        }
        else
        {
            if (attacker.jinx_live_rank >= level.jinx_live_guns.size - 1)
            {
                level.jinx_live_winner = true;
                level thread jinx_live_finish(attacker.name);
                return;
            }
            attacker.jinx_live_rank++;
        }
    }
    if (mode == "One in the Chamber")
    {
        if (isDefined(attacker.jinx_oic_budget)) attacker.jinx_oic_budget++;
        gun = attacker jinx_live_weapon();
        if ((attacker getWeaponAmmoClip(gun)) == 0) attacker setWeaponAmmoClip(gun, 1);
        else attacker setWeaponAmmoStock(gun, (attacker getWeaponAmmoStock(gun)) + 1);
    }
    if (mode == "Sticks and Stones")
    {
        attacker.jinx_live_points--; // use points rather than kill count in this mode
        if (weapon == "hatchet_mp") self.jinx_live_points = 0;
        else if (mod == "MOD_MELEE") attacker.jinx_live_points += 25;
        else attacker.jinx_live_points += 100;
    }
}

jinx_live_finish(winner)
{
    wait 0.05;
    iprintlnbold("^1JINX ^2Gun Game winner: ^7" + winner);
    jinx_custom_stop();
}

jinx_live_hud()
{
    if (!isDefined(self.jinx_live_hud_elem))
    {
        h = newClientHudElem(self);
        h.horzAlign = "center";
        h.vertAlign = "top";
        h.alignX = "right";
        h.alignY = "top";
        h.x = 300;
        h.y = 35;
        h.font = "objective";
        h.fontScale = 1;
        h.color = (1, 1, 1);
        h.archived = true;
        h.hideWhenInMenu = true;
        self.jinx_live_hud_elem = h;
        self thread jinx_live_hud_disconnect(h);
    }
    text = "^1JINX ^7" + level.jinx_custom_mode + " | Kills: " + self.jinx_live_points;
    if (level.jinx_custom_mode == "Sticks and Stones") text = "^1JINX ^7Sticks and Stones | Score: " + self.jinx_live_points;
    if (level.jinx_custom_mode == "Gun Game") text += " | Weapon " + (self.jinx_live_rank + 1) + "/" + level.jinx_live_guns.size;
    if (level.jinx_custom_mode == "Sharpshooter" || level.jinx_custom_mode == "Sniper Roulette" || level.jinx_custom_mode == "Gun Roulette") text += " | Next: " + int((level.jinx_live_rotate - getTime()) / 1000) + "s";
    if (level.jinx_custom_mode == "One in the Chamber") text += " | Ammo: " + self.jinx_oic_budget;
    if (level.jinx_custom_mode == "Zombie Mode (Fake)") text += " | Humans: shotgun / Bots: melee";
    self.jinx_live_hud_elem jinx_set_text(text);
    self.jinx_live_hud_elem.alpha = 1;
    if (isDefined(self.jinx_open) && self.jinx_open) self.jinx_live_hud_elem.alpha = 0;
}

jinx_live_hud_clear()
{
    self notify("jinx_live_hud_clear");
    if (isDefined(self.jinx_live_hud_elem)) self.jinx_live_hud_elem destroy();
    self.jinx_live_hud_elem = undefined;
}

jinx_live_hud_disconnect(h)
{
    self endon("jinx_live_hud_clear");
    self waittill("disconnect");
    if (isDefined(h)) h destroy();
}


jinx_radar_normal_zoom()
{
    range = maps\mp\_utility::getdvarfloatdefault("compassmaxrange", 2500);
    if (range < 12000) return;
    defaults = [];
    defaults["mp_paintball"] = 2100;
    defaults["mp_bridge"] = 2100;
    defaults["mp_castaway"] = 2100;
    defaults["mp_takeoff"] = 2100;
    defaults["mp_vertigo"] = 2100;
    defaults["mp_studio"] = 2100;
    defaults["mp_skate"] = 2100;
    defaults["mp_downhill"] = 2100;
    defaults["mp_pod"] = 2100;
    defaults["mp_concert"] = 2100;
    defaults["mp_nuketown_2020"] = 2100;
    defaults["mp_mirage"] = 2400;
    defaults["mp_hydro"] = 2300;
    defaults["mp_magma"] = 2100;
    defaults["mp_dig"] = 2100;
    defaults["mp_uplink"] = 2100;
    defaults["mp_frostbite"] = 2100;
    range = 2500;
    if (isDefined(level.script) && isDefined(defaults[level.script])) range = defaults[level.script];
    setDvar("compassmaxrange", range);
    self setClientDvar("compassmaxrange", range);
}

// One budget per life: pickups/refill actions cannot increase OIC ammunition.
jinx_oic_shots()
{
    self endon("disconnect");
    self endon("death");
    self endon("jinx_life_stop");
    self endon("jinx_oic_listener_stop");
    level endon("jinx_live_stop");
    level endon("game_ended");
    for (;;)
    {
        self waittill("weapon_fired", weapon);
        if (!isDefined(weapon)) weapon = self getCurrentWeapon();
        if (weapon != "kard_wager_mp" || !isDefined(self.jinx_oic_budget)) continue;
        if (self.jinx_oic_budget > 0) self.jinx_oic_budget--;
    }
}

jinx_oic_cap()
{
    if (!isDefined(self.jinx_oic_budget)) return;
    gun = "kard_wager_mp";
    clip = self getWeaponAmmoClip(gun);
    stock = self getWeaponAmmoStock(gun);
    if (clip < 0 || stock < 0) return;
    budget = self.jinx_oic_budget;
    if (clip > budget) { clip = budget; self setWeaponAmmoClip(gun, clip); }
    if (clip + stock > budget) self setWeaponAmmoStock(gun, budget - clip);
}

// Fun uses the host's existing input poll; no extra permanent effect loop.
jinx_fun_key(name)
{
    switch (name)
    {
        case "Earthquake": return "earthquake";
        case "Fake Lag (visual simulation)": return "fakelag";
        case "Random FX": return "randomfx";
        case "Teleport Gun": return "teleportgun";
        case "Jetpack": return "jetpack";
        case "Third Person": return "third";
        case "Crosshair": return "crosshair";
        case "Hitmarker": return "practicehit";
        case "Pro-Mod": return "promod";
    }
    return "";
}

jinx_fun_state(name)
{
    if (name == "Skybox") { if (isDefined(level.jinx_sky_step)) return "LEVEL " + level.jinx_sky_step; return "DEFAULT"; }
    if (name == "Zombie Mode (Fake)") { if (level.jinx_zombie_preparing) return "SETUP"; if (level.jinx_custom_mode == name) return "^2LIVE"; return "^1OFF"; }
    if (name == "Trickshot Menu") return ">";
    key = jinx_fun_key(name);
    if (key != "") return self jinx_toggle_label(key);
    if (name == "Clone Me")
    {
        if (isDefined(level.jinx_fun_clone)) return "^2ON";
        return "^1OFF";
    }
    if (name == "Pick Up Player")
    {
        if (isDefined(level.jinx_carried_bot)) return "HOLD";
        return self jinx_toggle_label("pickup");
    }
    return "--";
}

jinx_fun_action(name)
{
    if (name == "Skybox") { self jinx_sky_cycle(); return; }
    if (name == "Zombie Mode (Fake)")
    {
        if (level.jinx_custom_mode == name) jinx_custom_stop();
        else self jinx_live_start(name);
        self jinx_render(false); return;
    }
    key = jinx_fun_key(name);
    if (key != "")
    {
        if (key == "third") self jinx_toggle_effect(key);
        else
        {
            self.jinx_fx[key] = !(self jinx_enabled(key));
            if (key == "promod")
            {
                if (self jinx_enabled(key))
                {
                    self.jinx_fun_old_fov = self.jinx_fov;
                    self.jinx_fov = 110;
                    self setClientFov(110);
                }
                else
                {
                    self.jinx_fov = self.jinx_fun_old_fov;
                    if (self.jinx_fov == 0) self resetFov();
                    else self setClientFov(self.jinx_fov);
                }
            }
        }
        self jinx_render(false);
        if (key == "teleportgun") self jinx_notice("Shoot floor or wall. Teleport stops outside the surface.");
        if (key == "earthquake") self jinx_notice("Continuous strong earthquake nearby until OFF.");
        if (key == "fakelag") self jinx_notice("Camera stutter simulation ON/OFF; network ping is unchanged.");
        if (key == "randomfx") self jinx_notice("Stock visual FX every 1.5s ahead of you; no damage.");
        if (key == "jetpack") self jinx_notice("Hold Jump outside menu to fly; release to fall.");
        if (key == "promod") self jinx_notice("Pro-Mod view preset: 110 FOV only. OFF restores FOV.");
        if (key == "practicehit") self jinx_notice("Hitmarker uses the existing enemy-bot damage listener.");
        return;
    }
    if (name == "Pick Up Player")
    {
        self.jinx_fx["pickup"] = !(self jinx_enabled("pickup"));
        self.jinx_carry_use_down = true;
        if (!(self jinx_enabled("pickup"))) jinx_fun_drop();
        self jinx_render(false);
        self jinx_notice("ON arms pickup only. Close menu, aim DIRECTLY at player,\npress Use to pick up. Press Use again to drop. OFF disarms.");
        return;
    }
    if (name == "Clone Me")
    {
        if (isDefined(level.jinx_fun_clone))
        {
            level.jinx_fun_clone delete();
            level.jinx_fun_clone = undefined;
        }
        else self jinx_clone_statue();
        self jinx_render(false);
        self jinx_notice("Static upright model. Toggle OFF removes it; no corpse timer.");
        return;
    }
}

jinx_fun_shot()
{
    if (!(self jinx_enabled("teleportgun"))) return;
    if (isDefined(self.jinx_fun_teleport_time) && getTime() < self.jinx_fun_teleport_time) return;
    self.jinx_fun_teleport_time = getTime() + 350;
    eye = self getEye();
    trace = bulletTrace(eye, eye + anglesToForward(self getPlayerAngles()) * 4096, false, self);
    if (trace["fraction"] >= 1) return;
    destination = trace["position"] + trace["normal"] * 48 - (0, 0, 30);
    if (trace["normal"][2] > 0.7) destination = trace["position"] + (0, 0, 12);
    if (!jinx_body_space(destination, self)) return;
    self setOrigin(destination);
    self setVelocity((0, 0, 0));
}

jinx_fun_tick()
{
    if (self jinx_enabled("jetpack") && self jumpButtonPressed())
    {
        velocity = self getVelocity();
        self setVelocity((velocity[0], velocity[1], 450));
    }
    if (!(self jinx_enabled("pickup"))) return;
    pressed = self useButtonPressed();
    edge = pressed && !self.jinx_carry_use_down;
    self.jinx_carry_use_down = pressed;
    if (!isDefined(level.jinx_carried_bot))
    {
        if (isDefined(level.jinx_carry_anchor)) { level.jinx_carry_anchor delete(); level.jinx_carry_anchor = undefined; }
        if (!edge) return;
        eye = self getEye();
        trace = bulletTrace(eye, eye + anglesToForward(self getPlayerAngles()) * 768, true, self);
        if (!isDefined(trace["entity"]) || !isPlayer(trace["entity"])) { self iprintln("^1JINX ^7Aim directly at a nearby player, then press Use."); return; }
        target = trace["entity"];
        if (target == self || !isAlive(target) || target.sessionstate != "playing") return;
        if (target isInVehicle() || target isRemoteControlling() || isDefined(target.jinx_noclip_anchor)) return;
        if (target areControlsFrozen()) { self iprintln("^1JINX ^7That player is already frozen/busy."); return; }
        level.jinx_carried_origin = target.origin;
        level.jinx_carried_frozen = false;
        level.jinx_carry_anchor = spawn("script_origin", target.origin);
        level.jinx_carried_bot = target;
        target playerLinkTo(level.jinx_carry_anchor);
        target freezeControls(true);
        self iprintln("^1JINX ^7Holding " + target.name + ". Use again to drop.");
        return;
    }
    target = level.jinx_carried_bot;
    if (edge || !isAlive(target) || target.sessionstate != "playing") { jinx_fun_drop(); return; }
    eye = self getEye();
    point = eye + anglesToForward(self getPlayerAngles()) * 120;
    trace = bulletTrace(eye, point, false, self);
    if (trace["fraction"] < 1 || !jinx_body_space(point - (0, 0, 35), self)) return;
    if (isDefined(level.jinx_carry_anchor)) level.jinx_carry_anchor.origin = point - (0, 0, 35);
}

jinx_fun_drop()
{
    if (!isDefined(level.jinx_carried_bot))
    {
        if (isDefined(level.jinx_carry_anchor)) level.jinx_carry_anchor delete();
        level.jinx_carry_anchor = undefined;
        return;
    }
    bot = level.jinx_carried_bot;
    bot unlink();
    if (isDefined(level.jinx_carry_anchor)) level.jinx_carry_anchor delete();
    level.jinx_carry_anchor = undefined;
    // Prefer clear ground below the carried player; fall back to pickup position.
    if (isAlive(bot))
    {
        floor = bulletTrace(bot.origin + (0, 0, 8), bot.origin - (0, 0, 1024), false, bot);
        safe = floor["position"] + (0, 0, 12);
        if (floor["fraction"] < 1 && floor["normal"][2] > 0.7 && jinx_body_space(safe, bot)) bot setOrigin(safe);
        else bot setOrigin(level.jinx_carried_origin);
    }
    if (!level.jinx_carried_frozen) bot freezeControls(false);
    level.jinx_carried_bot = undefined;
}

jinx_fun_cleanup()
{
    jinx_sky_restore();
    if (isDefined(level.jinx_torch_fx)) level.jinx_torch_fx delete();
    level.jinx_torch_fx = undefined;
    jinx_fun_drop();
    if (isDefined(level.jinx_fun_clone)) level.jinx_fun_clone delete();
    level.jinx_fun_clone = undefined;
}

jinx_clone_statue()
{
    if (!isDefined(self.model) || self.model == "") { self jinx_notice("Current player model unavailable."); return; }
    body = spawn("script_model", self.origin);
    body setModel(self.model);
    angles = self getPlayerAngles();
    body.angles = (0, angles[1], 0);
    body notSolid();
    for (i = 0; i < self getAttachSize(); i++)
        body attach(self getAttachModelName(i), self getAttachTagName(i), self getAttachIgnoreCollision(i));
    level.jinx_fun_clone = body;
}

jinx_fun_visual_tick(now)
{
    if (self jinx_enabled("earthquake") && (!isDefined(self.jinx_quake_next) || now >= self.jinx_quake_next))
    {
        earthquake(0.65, 2.8, self.origin, 3000);
        self.jinx_quake_next = now + 2500;
    }
    if (self jinx_enabled("fakelag") && (!isDefined(self.jinx_jitter_next) || now >= self.jinx_jitter_next))
    {
        earthquake(0.5, 0.18, self.origin, 512, self);
        self.jinx_jitter_next = now + 450;
    }
    if (self jinx_enabled("randomfx") && (!isDefined(self.jinx_randomfx_next) || now >= self.jinx_randomfx_next))
    {
        eye = self getEye();
        forward = anglesToForward(self getPlayerAngles());
        trace = bulletTrace(eye, eye + forward * 180, false, self);
        position = trace["position"];
        if (trace["fraction"] < 1) position += trace["normal"] * 12;
        playFx(level.jinx_fun_fx[randomInt(level.jinx_fun_fx.size)], position);
        self.jinx_randomfx_next = now + 1500;
    }
}

// Six-ray clearance approximation, not a full player hull trace.
jinx_body_space(origin, ignore)
{
    center = origin + (0, 0, 34);
    offsets = [];
    offsets[0] = (22, 0, 0); offsets[1] = (-22, 0, 0);
    offsets[2] = (0, 22, 0); offsets[3] = (0, -22, 0);
    offsets[4] = (0, 0, 36); offsets[5] = (0, 0, -32);
    for (i = 0; i < offsets.size; i++)
    {
        t = bulletTrace(center, center + offsets[i], false, ignore);
        if (t["fraction"] < 1) return false;
    }
    return true;
}

jinx_model_snapshot()
{
    data = spawnStruct();
    data.model = self.model;
    data.models = []; data.tags = []; data.ignore = [];
    for (i = 0; i < self getAttachSize(); i++)
    {
        data.models[i] = self getAttachModelName(i);
        data.tags[i] = self getAttachTagName(i);
        data.ignore[i] = self getAttachIgnoreCollision(i);
    }
    return data;
}

jinx_model_restore(data)
{
    if (!isDefined(data) || !isDefined(data.model) || data.model == "") return;
    self detachAll();
    self setModel(data.model);
    for (i = 0; i < data.models.size; i++) self attach(data.models[i], data.tags[i], data.ignore[i]);
}

jinx_model_state(name)
{
    if (name == "Transform Into Object") return ">";
    if (name == "Change Model")
    {
        if (!isDefined(self.jinx_model_choice)) return "NEXT";
        names = strTok("ASSAULT,SNIPER,SHOTGUN,LMG,SMG", ",");
        return names[self.jinx_model_choice];
    }
    if (name == "Default Model") return "RESET";
    if (name == "Third Person Model") return self jinx_toggle_label("third");
    if (name == "Invisible Model") return self jinx_toggle_label("invisible");
    if (name == "Force Player Model") return self jinx_toggle_label("modelforce");
    if (name == "Model Loop") return self jinx_toggle_label("modelloop");
    if (name == "Human Torch") return self jinx_toggle_label("torch");
    if (name == "Size Editor") return "--";
    return "--";
}

jinx_model_apply_next()
{
    self jinx_object_remove();
    if (!isDefined(game["set_player_model"])) return false;
    team = self.team;
    if (!isDefined(team) || !isDefined(game["set_player_model"][team])) team = "allies";
    if (!isDefined(game["set_player_model"][team])) return false;
    types = strTok("default,rifle,spread,mg,smg", ",");
    start = 0;
    if (isDefined(self.jinx_model_choice)) start = (self.jinx_model_choice + 1) % types.size;
    for (i = 0; i < types.size; i++)
    {
        index = (start + i) % types.size;
        if (!isDefined(game["set_player_model"][team][types[index]])) continue;
        if (!isDefined(self.jinx_model_original)) self.jinx_model_original = self jinx_model_snapshot();
        self detachAll();
        // Loaded stock character callback, not an invented model name.
        self [[game["set_player_model"][team][types[index]]]]();
        self.jinx_model_choice = index;
        self.jinx_model_forced = self jinx_model_snapshot();
        return true;
    }
    return false;
}

jinx_model_action(name)
{
    if (name == "Change Model")
    {
        if (!(self jinx_model_apply_next())) self jinx_notice("No loaded stock character variants available for this team.");
        else
        {
            self jinx_render(false);
            self jinx_notice("Stock team character changed. Enable Third Person Model to see it.");
        }
        return;
    }
    if (name == "Default Model")
    {
        self jinx_model_clear(true);
        self jinx_render(false);
        self jinx_notice("Original appearance restored; model effects OFF.");
        return;
    }
    if (name == "Third Person Model" || name == "Invisible Model")
    {
        key = "third";
        if (name == "Invisible Model") key = "invisible";
        self jinx_toggle_effect(key);
        self jinx_render(false);
        return;
    }
    if (name == "Force Player Model" || name == "Model Loop" || name == "Human Torch")
    {
        key = "modelforce";
        if (name == "Model Loop") key = "modelloop";
        if (name == "Human Torch") key = "torch";
        self.jinx_fx[key] = !(self jinx_enabled(key));
        if (key == "modelforce" && self jinx_enabled(key))
        {
            self.jinx_fx["modelloop"] = false;
            self.jinx_model_forced = self jinx_model_snapshot();
        }
        if (key == "modelloop" && self jinx_enabled(key)) self.jinx_fx["modelforce"] = false;
        if (key == "torch" && !(self jinx_enabled(key)) && isDefined(level.jinx_torch_fx))
        {
            level.jinx_torch_fx delete();
            level.jinx_torch_fx = undefined;
        }
        self jinx_render(false);
        if (key == "torch") self jinx_notice("Persistent cosmetic fire, no damage. Use Third Person Model to inspect.");
        return;
    }
    if (name == "Size Editor")
    {
        self jinx_notice("Pending: model scaling native is unavailable in T6 Multiplayer.");
        return;
    }
    if (name == "Rainbow Model") self jinx_notice("Unavailable: no verified stock GSC player-material tint API. No fake toggle.");
}

jinx_model_tick(now)
{
    self jinx_object_tick();
    if (self jinx_enabled("modelloop") && (!isDefined(self.jinx_model_next) || now >= self.jinx_model_next))
    {
        if (!(self jinx_model_apply_next())) self.jinx_fx["modelloop"] = false;
        self.jinx_model_next = now + 3000;
    }
    if (self jinx_enabled("modelforce") && isDefined(self.jinx_model_forced))
    {
        if (self.model != self.jinx_model_forced.model) self jinx_model_restore(self.jinx_model_forced);
    }
    if (self jinx_enabled("torch"))
    {
        point = self getTagOrigin("j_spine4");
        if (!isDefined(level.jinx_torch_fx))
        {
            level.jinx_torch_fx = spawnFx(level.jinx_torch_effect, point);
            triggerFx(level.jinx_torch_fx);
        }
        // Keep the emitter alive; deleting it every 0.5s cut off its startup.
        level.jinx_torch_fx.origin = point;
    }
}

jinx_model_clear(restore)
{
    self jinx_object_remove();
    if (restore)
    {
        self jinx_model_restore(self.jinx_model_original);
        self show();
        if (self jinx_enabled("invisible")) self jinx_toggle_effect("invisible");
    }
    if (isDefined(level.jinx_torch_fx)) level.jinx_torch_fx delete();
    level.jinx_torch_fx = undefined;
    self.jinx_fx["torch"] = false;
    self.jinx_fx["modelforce"] = false;
    self.jinx_fx["modelloop"] = false;
    self.jinx_model_original = undefined;
    self.jinx_model_forced = undefined;
    self.jinx_model_choice = undefined;
}


// Owned spawn groups keep visuals, collision and behavior together.
jinx_spawn_state(name)
{
    if (name == "Spawn Fake Player") return "STATIC";
    if (name == "Detonate Spawned C4") return "BOOM";
    return "USE";
}

jinx_spawn_group(kind)
{
    group = spawnStruct();
    group.kind = kind;
    group.parts = [];
    group.clips = [];
    group.owner = self;
    group.created = getTime();
    level.jinx_spawn_items[level.jinx_spawn_items.size] = group;
    return group;
}

jinx_spawn_count()
{
    count = 0;
    for (i = 0; i < level.jinx_spawn_items.size; i++)
    {
        g = level.jinx_spawn_items[i];
        if (!isDefined(g)) continue;
        count += g.parts.size + g.clips.size;
    }
    return count;
}

jinx_spawn_clip(group, model, point)
{
    before = getEntArray("collider", "classname");
    clip = spawnCollision(model, "collider", point, (0, 0, 0));
    if (isDefined(clip)) { group.clips[group.clips.size] = clip; return true; }
    // Some builds expose the spawned entity only through the entity list.
    after = getEntArray("collider", "classname");
    for (i = 0; i < after.size; i++)
        if (!jinx_in_list(before, after[i]))
        { group.clips[group.clips.size] = after[i]; return true; }
    return false;
}

jinx_spawn_remove(group)
{
    if (!isDefined(group) || isDefined(group.removing)) return;
    group.removing = true;
    for (i = 0; i < group.parts.size; i++)
    {
        obj = group.parts[i];
        if (!isDefined(obj)) continue;
        if (group.kind == "turret") obj notify("destroy_turret", 0);
        else if (group.kind == "package") obj maps\mp\killstreaks\_supplydrop::cratedelete(0);
        else obj delete();
    }
    for (i = 0; i < group.clips.size; i++) if (isDefined(group.clips[i])) group.clips[i] delete();
    group.parts = []; group.clips = [];
}

jinx_spawn_compact()
{
    keep = [];
    for (i = 0; i < level.jinx_spawn_items.size; i++)
    {
        g = level.jinx_spawn_items[i];
        if (!isDefined(g) || isDefined(g.removing)) continue;
        alive = false;
        for (j = 0; j < g.parts.size; j++) if (isDefined(g.parts[j])) alive = true;
        if (alive) keep[keep.size] = g;
        else jinx_spawn_remove(g);
    }
    level.jinx_spawn_items = keep;
}

jinx_spawn_clear()
{
    if (isDefined(level.jinx_spawn_items))
        for (i = 0; i < level.jinx_spawn_items.size; i++) jinx_spawn_remove(level.jinx_spawn_items[i]);
    level.jinx_spawn_items = [];
    level.jinx_trampolines = [];
    level.jinx_last_platform = undefined;
    level.jinx_last_platform_piece = undefined;
    level.jinx_trickshot_platform = undefined;
}

jinx_spawn_floor()
{
    angles = self getPlayerAngles();
    point = self.origin + anglesToForward((0, angles[1], 0)) * 110;
    trace = bulletTrace(point + (0, 0, 80), point - (0, 0, 256), false, self);
    if (trace["fraction"] >= 1 || trace["normal"][2] < 0.7) return undefined;
    return trace["position"] + (0, 0, 4);
}

jinx_platform_create(kind)
{
    if (!isDefined(level.cratemodelfriendly)) { self jinx_notice("Wait for map assets to initialize."); return; }
    cols = 3; rows = 2; tilesx = 2; tilesy = 2; tilewidth = 64;
    // 48 visuals + 2 clips, half the old 100-entity Sky Base.
    if (kind == "Sky Base") { cols = 12; rows = 4; tilesy = 1; tilewidth = 256; }
    if (kind == "Spawn Trampoline") { cols = 1; rows = 1; tilesx = 1; tilesy = 1; }
    if (jinx_spawn_count() + cols * rows + tilesx * tilesy > 128)
    { self jinx_notice("Not enough room: " + jinx_spawn_count() + "/128 entities used. Sky Base needs 50. Delete an old structure."); return; }
    // Horizontal platform at the player's feet, never at a random trace location.
    surface = self.origin - (0, 0, 4);
    group = self jinx_spawn_group("platform");
    group.label = kind;
    group.surface = surface;
    group.width = tilesx * tilewidth;
    group.depth = tilesy * tilewidth;
    for (x = 0; x < tilesx; x++)
        for (y = 0; y < tilesy; y++)
        {
            offset = ((x - (tilesx - 1) * 0.5) * tilewidth, (y - (tilesy - 1) * 0.5) * tilewidth, -5);
            model = "collision_clip_64x64x10";
            if (tilewidth == 256) model = "collision_clip_256x256x10";
            if (!jinx_spawn_clip(group, model, surface + offset))
            { jinx_spawn_remove(group); self jinx_notice("Collision entity was not returned; structure cancelled."); return; }
        }
    for (x = 0; x < cols; x++)
        for (y = 0; y < rows; y++)
        {
            offset = ((x - (cols - 1) * 0.5) * 42, (y - (rows - 1) * 0.5) * 64, -30);
            obj = spawn("script_model", surface + offset);
            obj setModel(level.cratemodelfriendly);
            obj.angles = (0, 0, 0);
            obj notSolid(); // The separate clip brushes provide player collision.
            group.parts[group.parts.size] = obj;
        }
    if (kind == "Spawn Trampoline") group.kind = "trampoline";
    else
    {
        level.jinx_last_platform = surface + (0, 0, 16);
        level.jinx_last_platform_piece = group.parts[0];
        if (kind == "Trickshot Platform") level.jinx_trickshot_platform = group;
    }
    if (!isDefined(self.jinx_noclip_anchor))
    { self setOrigin(surface + (0, 0, 16)); self setVelocity((0, 0, 0)); }
    self jinx_notice(kind + " created directly under you. Width: " + group.width + " units.");
}

jinx_spawn_action(name)
{
    if (!isAlive(self) || self isInVehicle() || self isRemoteControlling()) return;
    if (isDefined(self.jinx_spawn_busy) && self.jinx_spawn_busy) { self jinx_notice("Wait for the current spawn."); return; }
    jinx_spawn_compact();
    if (name == "Clear Spawned Objects") { jinx_spawn_clear(); self jinx_notice("Owned spawn groups removed."); return; }
    if (name == "Delete Last Spawn")
    {
        if (level.jinx_spawn_items.size > 0) jinx_spawn_remove(level.jinx_spawn_items[level.jinx_spawn_items.size - 1]);
        jinx_spawn_compact(); return;
    }
    if (name == "Teleport To Last Platform") { self jinx_teleport_platform(false); return; }
    if (name == "Return From Platform") { self jinx_teleport_action(12, "Return To Previous Position", 0); return; }
    if (name == "Detonate Spawned C4")
    {
        self jinx_c4_detonate();
        return;
    }
    if (name == "Sky Base" || name == "Trickshot Platform" || name == "Spawn Trampoline")
    { self jinx_platform_create(name); return; }
    if (isDefined(self.jinx_noclip_anchor)) { self jinx_notice("Stop Noclip flight for ground objects."); return; }
    if (name == "Spawn All")
    {
        self jinx_notice("Spawn All runs a bounded batch in front of you. Structures stay underfoot.");
        self thread jinx_spawn_batch(); return;
    }
    if (jinx_spawn_count() >= 128) { self jinx_notice("World-object limit reached."); return; }
    point = self jinx_spawn_floor();
    if (!isDefined(point)) { self jinx_notice("Stand near clear flat ground."); return; }
    if (name == "Spawn C4" || name == "Spawn Bouncing Betty")
    {
        if (level.jinx_custom_mode != "") { self jinx_notice("Stop Active Mode before spawning explosives."); return; }
        weapon = "bouncingbetty_mp"; kind = "betty";
        if (name == "Spawn C4") { weapon = "satchel_charge_mp"; kind = "c4"; }
        model = getWeaponModel(weapon);
        if (!isDefined(model) || model == "") { self jinx_notice("Equipment world model unavailable."); return; }
        g = self jinx_spawn_group(kind);
        obj = spawn("script_model", point);
        obj setModel(model); obj.angles = (0, 0, 0);
        g.parts[0] = obj;
        g.weapon = weapon;
        g.armed_at = getTime() + 1500;
        if (kind == "c4") self jinx_notice("C4 armed in 1.5s. Double-tap Use outside menu, or Detonate Spawned C4.");
        else self jinx_notice("Betty spawned. Arms in 1.5s; enemy proximity triggers it.");
        return;
    }
    if (name == "Spawn Fake Player")
    {
        g = self jinx_spawn_group("static");
        obj = spawn("script_model", point); obj setModel(self.model);
        a = self getPlayerAngles(); obj.angles = (0, a[1] + 180, 0); obj notSolid();
        for (i = 0; i < self getAttachSize(); i++) obj attach(self getAttachModelName(i), self getAttachTagName(i), self getAttachIgnoreCollision(i));
        g.parts[0] = obj; return;
    }
    if (name == "Spawn Care Package" || name == "Spawn Airdrop")
    { self thread jinx_spawn_package(point, name == "Spawn Airdrop"); return; }
    if (name == "Spawn Sentry" || name == "Spawn Bob/Sentry" || name == "Spawn Turret")
    { self thread jinx_spawn_turret(point, name == "Spawn Turret"); return; }
    if (name == "Spawn Vehicle") { self thread jinx_spawn_vehicle(point); return; }
}

jinx_spawn_package(point, falling)
{
    self endon("disconnect"); level endon("game_ended");
    if (!isDefined(level.cratetypes) || !isDefined(level.cratetypes["supplydrop_mp"]))
    { self jinx_notice("Native care-package registry is not ready."); return; }
    start = point;
    if (falling)
    {
        roof = bulletTrace(point, point + (0, 0, 250), false, self);
        if (roof["fraction"] < 1) { self jinx_notice("Airdrop needs open space above the drop point."); return; }
        start += (0, 0, 250);
    }
    crate = maps\mp\killstreaks\_supplydrop::cratespawn("supplydrop_mp", self, self.team, start, (0, 0, 0));
    crate.killstreak_id = -1; crate.package_contents_id = -1;
    g = self jinx_spawn_group("package"); g.parts[0] = crate;
    crate endon("death");
    if (falling) crate maps\mp\killstreaks\_supplydrop::cratephysics();
    crate maps\mp\killstreaks\_supplydrop::crateactivate();
    crate thread maps\mp\killstreaks\_supplydrop::crateusethink();
    crate thread maps\mp\killstreaks\_supplydrop::crateusethinkowner();
    crate thread maps\mp\killstreaks\_supplydrop::cratetimeout(90);
    if (isDefined(crate.cratetype.hint_gambler))
        crate thread maps\mp\killstreaks\_supplydrop::crategamblerthink();
    self jinx_notice("Real care package spawned. Hold Use beside it to collect.");
    maps\mp\killstreaks\_supplydrop::default_land_function(crate, "supplydrop_mp", self, self.team);
}

jinx_spawn_turret(point, guardian)
{
    self endon("disconnect"); self endon("death"); level endon("game_ended");
    if (!isDefined(level.auto_turret_settings)) return;
    weapon = "autoturret_mp";
    if (guardian) weapon = "microwaveturret_mp";
    id = self maps\mp\killstreaks\_killstreakrules::killstreakstart(weapon, self.team);
    if (id == -1) { self jinx_notice("Native turret limit/rules currently block this spawn."); return; }
    self.jinx_spawn_busy = true;
    self jinx_close();
    previous = self.usingkillstreakfrominventory;
    self.usingkillstreakfrominventory = false;
    if (guardian) turret = self maps\mp\killstreaks\_turret_killstreak::usemicrowaveturret(weapon);
    else turret = self maps\mp\killstreaks\_turret_killstreak::usesentryturret(weapon);
    self.usingkillstreakfrominventory = previous;
    turret.killstreak_id = id;
    g = self jinx_spawn_group("turret"); g.parts[0] = turret;
    wait 0.1;
    if (isDefined(turret))
    {
        a = self getPlayerAngles();
        turret.origin = point; turret.angles = (0, a[1], 0);
        turret.canbeplaced = true;
        self maps\mp\killstreaks\_turret_killstreak::placeturret(turret);
    }
    self.jinx_spawn_busy = false;
}

jinx_spawn_vehicle(point)
{
    // Use the real AGR creation path at a nearby navigation node, no inventory grant.
    self endon("disconnect"); level endon("game_ended");
    node = getNearestNode(point);
    if (!isDefined(node) || distance(node.origin, point) > 256)
    { self jinx_notice("AGR needs ground near a navigation node."); return; }
    weapon = "inventory_ai_tank_drop_mp";
    id = self maps\mp\killstreaks\_killstreakrules::killstreakstart(weapon, self.team, 0, 0);
    if (id == -1) { self jinx_notice("Native AGR limit/rules currently block this spawn."); return; }
    level thread maps\mp\killstreaks\_ai_tank::ai_tank_killstreak_start(self, point, id, weapon);
    self jinx_notice("AGR creation started here; native AI/lifetime controls it.");
}

jinx_spawn_explode(group)
{
    if (!isDefined(group) || isDefined(group.removing) || group.parts.size == 0 || !isDefined(group.parts[0])) return;
    obj = group.parts[0];
    point = obj.origin + (0, 0, 12);
    if (group.kind == "betty") point += (0, 0, 45);
    playFx(level.jinx_fun_fx[0], point);
    if (isDefined(group.owner)) obj radiusDamage(point, 192, 180, 25, group.owner, "MOD_EXPLOSIVE", group.weapon);
    jinx_spawn_remove(group);
}

jinx_spawn_tick(now)
{
    if (isDefined(level.jinx_spawn_next) && now < level.jinx_spawn_next) return;
    level.jinx_spawn_next = now + 100;
    for (i = 0; i < level.jinx_spawn_items.size; i++)
    {
        g = level.jinx_spawn_items[i];
        if (!isDefined(g) || isDefined(g.removing) || g.parts.size == 0 || !isDefined(g.parts[0])) continue;
        if (g.kind != "trampoline" && g.kind != "betty") continue;
        if (g.kind == "betty" && now < g.armed_at) continue;
        for (j = 0; j < level.players.size; j++)
        {
            p = level.players[j];
            if (!isDefined(p) || !isAlive(p) || p.sessionstate != "playing") continue;
            if (g.kind == "betty")
            {
                if (!isDefined(g.owner) || p == g.owner || (level.teambased && p.team == g.owner.team)) continue;
                if (distance(p.origin, g.parts[0].origin) < 110)
                {
                    sight = bulletTrace(g.parts[0].origin + (0, 0, 24), p.origin + (0, 0, 32), false, g.parts[0]);
                    if (sight["fraction"] >= 0.99) { jinx_spawn_explode(g); break; }
                }
                continue;
            }
            if (p isInVehicle() || p isRemoteControlling() || isDefined(p.jinx_noclip_anchor)) continue;
            if (isDefined(level.jinx_carried_bot) && level.jinx_carried_bot == p) continue;
            if (isDefined(p.jinx_trampoline_next) && now < p.jinx_trampoline_next) continue;
            d = p.origin - g.surface;
            velocity = p getVelocity();
            if (abs(d[0]) <= 32 && abs(d[1]) <= 32 && d[2] >= -4 && d[2] < 32 && velocity[2] <= 50)
            { p setVelocity((velocity[0], velocity[1], 1000)); p.jinx_trampoline_next = now + 1200; }
        }
    }
}

jinx_spawn_batch()
{
    self endon("disconnect"); self endon("death"); level endon("game_ended");
    names = strTok("Sky Base,Trickshot Platform,Spawn Trampoline,Spawn Fake Player,Spawn C4,Spawn Bouncing Betty,Spawn Care Package,Spawn Airdrop,Spawn Sentry,Spawn Turret,Spawn Vehicle", ",");
    for (i = 0; i < names.size; i++) { self jinx_spawn_action(names[i]); wait 0.3; }
}

jinx_object_form(name)
{
    if (name == "Default Model") { self jinx_model_action(name); return; }
    model = "";
    if (name == "Helicopter" && isDefined(level.supplydrophelicopterfriendly)) model = level.supplydrophelicopterfriendly;
    if (name == "Supply Crate" && isDefined(level.cratemodelfriendly)) model = level.cratemodelfriendly;
    if (name == "Sentry Turret" && isDefined(level.auto_turret_settings["sentry"])) model = level.auto_turret_settings["sentry"].modelbase;
    if (name == "Guardian" && isDefined(level.auto_turret_settings["microwave"])) model = level.auto_turret_settings["microwave"].modelbase;
    // This stock model is precached by the native AGR script on MP maps.
    if (name == "AGR" && isDefined(level.ai_tank_explode_fx)) model = "veh_t6_drone_tank";
    if (name == "Bouncing Betty") model = getWeaponModel("bouncingbetty_mp");
    if (name == "C4") model = getWeaponModel("satchel_charge_mp");
    if (!isDefined(model) || model == "") { self jinx_notice("Requested model is not loaded on this map."); return; }
    if (!isDefined(self.jinx_model_original)) self.jinx_model_original = self jinx_model_snapshot();
    self.jinx_fx["modelloop"] = false; self.jinx_fx["modelforce"] = false;
    self jinx_object_remove();
    self jinx_model_restore(self.jinx_model_original);
    proxy = spawn("script_model", self.origin);
    proxy setModel(model);
    proxy notSolid();
    a = self getPlayerAngles(); proxy.angles = (0, a[1], 0);
    bottom = proxy getPointInBounds(0, 0, -1);
    self.jinx_object_offset = self.origin[2] - bottom[2] + 6;
    if (name == "Helicopter") self.jinx_object_offset += 70;
    self.jinx_object_height = 0;
    self.jinx_object_proxy = proxy;
    level.jinx_object_proxy = proxy;
    self hide();
    self jinx_object_tick();
    // Independent unanimated visual proxy; normal player physics underneath.
    if (!(self jinx_enabled("third"))) self jinx_toggle_effect("third");
    self jinx_notice(name + " appearance applied. Default Model restores your soldier.");
}

jinx_teleport_ready()
{
    if (!isAlive(self) || self.sessionstate != "playing") return false;
    if (isDefined(self.jinx_noclip_anchor) || self isInVehicle() || self isRemoteControlling())
    { self jinx_notice("Exit Noclip/vehicle/remote control before teleporting."); return false; }
    return true;
}

jinx_teleport_move(point, angles)
{
    if (!(self jinx_teleport_ready())) return false;
    if (!isDefined(point) || !jinx_body_space(point, self))
    { self jinx_notice("Destination is obstructed; teleport cancelled."); return false; }
    self.jinx_teleport_previous = self.origin;
    self.jinx_teleport_previous_angles = self getPlayerAngles();
    if (isDefined(level.jinx_carried_bot)) jinx_fun_drop();
    self setOrigin(point); self setVelocity((0, 0, 0));
    if (isDefined(angles)) self setPlayerAngles(angles);
    if (self jinx_enabled("freeze")) self.jinx_freeze_origin = point;
    self.jinx_jump_boost_left = 0;
    self jinx_close();
    return true;
}

jinx_teleport_near(point)
{
    // Floor/clearance checks; never put two players at exactly the same origin.
    for (i = 0; i < 8; i++)
    {
        angle = i * 45;
        spot = point + (cos(angle) * 100, sin(angle) * 100, 40);
        trace = bulletTrace(spot, spot - (0, 0, 256), false, self);
        if (trace["fraction"] >= 1 || trace["normal"][2] < 0.7) continue;
        dest = trace["position"] + (0, 0, 12);
        if (!jinx_body_space(dest, self)) continue;
        occupied = false;
        for (j = 0; j < level.players.size; j++)
            if (isDefined(level.players[j]) && level.players[j] != self && isAlive(level.players[j]) && distance(level.players[j].origin, dest) < 40) occupied = true;
        if (!occupied) return dest;
    }
    return undefined;
}

jinx_teleport_platform(trick)
{
    if (!(self jinx_teleport_ready())) return;
    point = level.jinx_last_platform;
    if (trick)
    {
        if (!isDefined(level.jinx_trickshot_platform) || isDefined(level.jinx_trickshot_platform.removing))
        { self jinx_notice("Create a Trickshot Platform first."); return; }
        point = level.jinx_trickshot_platform.surface + (0, 0, 16);
    }
    else if (!isDefined(level.jinx_last_platform_piece))
    { self jinx_notice("Create a platform first."); return; }
    self jinx_teleport_move(point, undefined);
}

jinx_teleport_player_list()
{
    self.jinx_teleport_targets = [];
    options = []; links = [];
    for (i = 0; i < level.players.size; i++)
    {
        p = level.players[i];
        if (!isDefined(p) || p == self || !isAlive(p) || p.sessionstate != "playing") continue;
        self.jinx_teleport_targets[self.jinx_teleport_targets.size] = p;
        options[options.size] = p.name;
        links[links.size] = -1;
    }
    if (options.size == 0) { self jinx_notice("No other living players available."); return; }
    level.jinx_options[46] = options; level.jinx_links[46] = links;
    self.jinx_return_stack[self.jinx_return_depth] = self.jinx_category;
    self.jinx_return_depth++;
    self.jinx_category = 46; self.jinx_subcursor[46] = 0;
    self jinx_render(false);
}

jinx_teleport_action(category, name, index)
{
    if (!(self jinx_teleport_ready())) return;
    if (category == 46)
    {
        if (!isDefined(self.jinx_teleport_targets[index])) { self jinx_notice("Player left; reopen player list."); return; }
        target = self.jinx_teleport_targets[index];
        if (!isAlive(target)) { self jinx_notice("Player is dead; select another target."); return; }
        point = self jinx_teleport_near(target.origin);
        self jinx_teleport_move(point, undefined); return;
    }
    if (name == "Save Position")
    {
        self.jinx_practice_position = self.origin;
        self.jinx_practice_angles = self getPlayerAngles();
        self jinx_notice("Position and view saved; shared with Trickshot Save/Load."); return;
    }
    if (name == "Load Position")
    {
        if (!isDefined(self.jinx_practice_position)) { self jinx_notice("Save Position first."); return; }
        self jinx_teleport_move(self.jinx_practice_position, self.jinx_practice_angles); return;
    }
    if (name == "Return To Previous Position")
    {
        if (!isDefined(self.jinx_teleport_previous)) { self jinx_notice("No previous teleport position."); return; }
        self jinx_teleport_move(self.jinx_teleport_previous, self.jinx_teleport_previous_angles); return;
    }
    if (name == "Teleport To Player") { self jinx_teleport_player_list(); return; }
    if (name == "Teleport To Trickshot") { self jinx_teleport_platform(true); return; }
    if (name == "Teleport To Spawn")
    {
        if (isDefined(self.jinx_spawn_origin)) self jinx_teleport_move(self.jinx_spawn_origin, self.jinx_spawn_angles);
        return;
    }
    if (name == "Teleport To Sky")
    {
        point = self.origin + (0, 0, 500);
        trace = bulletTrace(self getEye(), point + (0, 0, 60), false, self);
        if (trace["fraction"] < 1) { self jinx_notice("Ceiling blocks Teleport To Sky."); return; }
        self jinx_teleport_move(point, undefined); return;
    }
    if (name == "Teleport To Crosshair")
    {
        eye = self getEye();
        trace = bulletTrace(eye, eye + anglesToForward(self getPlayerAngles()) * 8192, false, self);
        if (trace["fraction"] >= 1) { self jinx_notice("Aim at a floor or wall."); return; }
        point = trace["position"] + trace["normal"] * 48 - (0, 0, 30);
        if (trace["normal"][2] > 0.7) point = trace["position"] + (0, 0, 12);
        self jinx_teleport_move(point, undefined); return;
    }
    if (name == "Teleport To Map")
    {
        if (!isDefined(level.unified_spawn_points)) { self jinx_notice("Map spawn locations unavailable."); return; }
        points = []; keys = getArrayKeys(level.unified_spawn_points);
        for (i = 0; i < keys.size; i++)
        {
            entry = level.unified_spawn_points[keys[i]];
            if (!isDefined(entry.a)) continue;
            for (j = 0; j < entry.a.size; j++)
                if (isDefined(entry.a[j].origin)) points[points.size] = entry.a[j].origin;
        }
        if (points.size == 0) { self jinx_notice("No map spawn locations found."); return; }
        if (!isDefined(self.jinx_map_destination)) self.jinx_map_destination = 0;
        for (i = 0; i < points.size; i++)
        {
            self.jinx_map_destination = (self.jinx_map_destination + 1) % points.size;
            point = points[self.jinx_map_destination] + (0, 0, 12);
            if (jinx_body_space(point, self)) { self jinx_teleport_move(point, undefined); return; }
        }
        self jinx_notice("All inspected spawn locations were obstructed."); return;
    }
    if (name == "Teleport To All")
    {
        count = 0;
        for (i = 0; i < level.players.size; i++)
        {
            p = level.players[i];
            if (!isDefined(p) || p == self || !isAlive(p) || p.sessionstate != "playing") continue;
            if (p isInVehicle() || p isRemoteControlling() || isDefined(p.jinx_noclip_anchor)) continue;
            if (isDefined(level.jinx_carried_bot) && p == level.jinx_carried_bot) continue;
            point = p jinx_teleport_near(self.origin);
            if (!isDefined(point)) continue;
            p.jinx_teleport_previous = p.origin;
            p.jinx_teleport_previous_angles = p getPlayerAngles();
            p setOrigin(point); p setVelocity((0, 0, 0)); count++;
        }
        self jinx_notice("Brought " + count + " players to clear ground around the host."); return;
    }
}

// ---- v0.6.5 extensions: private host only ----------------------------------
jinx_extended_catalog()
{
    level.jinx_maps = [];
    names = strTok("Nuketown 2025,Hijacked,Carrier,Standoff,Raid,Slums,Overflow,Express,Yemen,Downhill,Hydro,Mirage,Grind,Magma,Encore,Vertigo,Studio,Cove,Detour,Rush,Uplink,Frost,Pod,Dig,Takeoff,Aftermath,Cargo,Drone,Meltdown,Plaza,Turbine", ",");
    ids = strTok("mp_nuketown_2020,mp_hijacked,mp_carrier,mp_village,mp_raid,mp_slums,mp_overflow,mp_express,mp_socotra,mp_downhill,mp_hydro,mp_mirage,mp_skate,mp_magma,mp_concert,mp_vertigo,mp_studio,mp_castaway,mp_bridge,mp_paintball,mp_uplink,mp_frostbite,mp_pod,mp_dig,mp_takeoff,mp_la,mp_dockside,mp_drone,mp_meltdown,mp_nightclub,mp_turbine", ",");
    for (i = 0; i < names.size; i++) level.jinx_maps[names[i]] = ids[i];
    level.jinx_map_names = names;
    level.jinx_titles[53] = "Remove One Bot";
    level.jinx_options[53] = [];
    level.jinx_titles[50] = "Map Change";
    level.jinx_options[50] = strTok("Show Map Command,Cancel", ",");
    level.jinx_titles[49] = "Map Loader";
    level.jinx_options[49] = strTok("Random Map,Reload Current Map,Current Map Info", ",");
    level.jinx_titles[47] = "Trickshot Class";
    level.jinx_titles[48] = "Bind Insta Swap To";
    level.jinx_options[48] = strTok("OFF,Right D-Pad,Left D-Pad", ",");
    level.jinx_options[47] = strTok("Ballista Loadouts,DSR 50 Loadouts", ",");
    level.jinx_titles[51] = "Ballista Loadouts";
    level.jinx_titles[52] = "DSR 50 Loadouts";
    level.jinx_options[51] = []; level.jinx_options[52] = [];
    level.jinx_trick_kits = [];
    sidearms = strTok("fiveseven_mp,beretta93r_mp,kard_dw_mp,870mcs_mp,ksg_mp,knife_ballistic_mp,crossbow_mp,usrpg_mp,mp7_mp,pdw57_mp,vector_mp,insas_mp,qcw05_mp,evoskorpion_mp,peacekeeper_mp,tar21_mp,type95_mp,sig556_mp,sa58_mp,hk416_mp,scar_mp,saritch_mp,xm8_mp,an94_mp", ",");
    labels = strTok("Five-seven,B23R,Dual KAP-40,R870,KSG,Ballistic Knife,Crossbow,RPG,MP7,PDW-57,Vector,MSMC,Chicom,Skorpion EVO,Peacekeeper,MTAR,Type 25,SWAT-556,FAL,M27,SCAR-H,SMR,M8A1,AN-94", ",");
    for (group = 0; group < 2; group++)
    {
        category = 51 + group;
        level.jinx_trick_kits[category] = [];
        sniper = "ballista_mp";
        if (group == 1) sniper = "dsr50_mp";
        for (i = 0; i < sidearms.size; i++)
        {
            level.jinx_options[category][i] = labels[i];
            level.jinx_trick_kits[category][i] = [];
            level.jinx_trick_kits[category][i][0] = sniper;
            level.jinx_trick_kits[category][i][1] = sidearms[i];
        }
    }
    // Keep existing groups and add five entries to each (120 total presets).
    for (group = 35; group <= 42; group++)
    {
        labels = []; texts = [];
        if (group == 35)
        {
            labels = strTok("Crosshair vacation,Respawn miles,Wall collector,Scope warranty,Aim update", ",");
            texts = strTok("Your crosshair is on vacation.|You just earned more respawn miles.|Another wall added to your collection.|Your scope warranty does not cover that aim.|Aim update available. Download after this round.", "|");
        }
        if (group == 36)
        {
            labels = strTok("Gravity wins,Skill loading,Chair blame,One more try,Accidental pro", ",");
            texts = strTok("Gravity: 1. Trickshot: 0.|Skill is still loading. Please wait.|The chair was clearly holding me back.|One more try has become our full-time job.|That was completely planned. Probably.", "|");
        }
        if (group == 37)
        {
            labels = strTok("Squad arrival,Fresh lobby,Grab sniper,Settle in,First attempt", ",");
            texts = strTok("Welcome aboard. The squad is ready.|Fresh lobby. Fresh clips. Welcome!|Grab a sniper and join the practice.|Settle in and enjoy the private lobby.|New arrival gets the next attempt.", "|");
        }
        if (group == 38)
        {
            labels = strTok("Last setup,Camera ready,Air time,Swap clean,Diamond shot", ",");
            texts = strTok("Last is ready. Set up your best shot.|Camera rolling. Make this one count.|More air time. Less panic.|Clean swap. Clean spin. Clean finish.|Diamond camo deserves a diamond clip.", "|");
        }
        if (group == 39)
        {
            labels = strTok("Replay now,Personal best,Squad clip,Unbelievable,Perfect finish", ",");
            texts = strTok("Replay that right now!|New personal best. Keep going.|That clip belongs in the squad montage.|We all saw that. Unbelievable shot.|Perfect finish. GG everyone.", "|");
        }
        if (group == 40)
        {
            labels = strTok("Clear landing,No explosives,Save spot,Wait turn,Private practice", ",");
            texts = strTok("Keep the landing zone clear.|Please stop explosives while we set up.|Save your position before jumping.|Wait your turn. Everyone gets an attempt.|Private practice session. Enjoy the tools.", "|");
        }
        if (group == 41)
        {
            labels = strTok("Que clase tiro,Corillo listo,Dale pabellon,Otra vuelta,Desde PR", ",");
            texts = strTok("Que clase de tiro, mano!|El corillo esta listo. Arranca!|Dale pabellon, que ese clip es tuyo.|Una vuelta mas y lo pegamos.|Desde PR con flow. Wepa!", "|");
        }
        if (group == 42)
        {
            labels = strTok("YouTube clips,Instagram squad,JINX session,Montage time,Thanks squad", ",");
            texts = strTok("Clips and more: youtube.com/@JinxPR|Join the squad: instagram.com/luistorrespr_|JINX private session. Built for practice and fun.|Montage time. Hit your best shot.|Thanks for being part of the JINX squad.", "|");
        }
        for (j = 0; j < labels.size; j++)
        {
            n = level.jinx_options[group].size;
            level.jinx_options[group][n] = labels[j];
            level.jinx_message_texts[group][n] = texts[j];
        }
    }
}

jinx_extended_dispatch(category, name, index)
{
    handled = category == 13 || category == 47 || category == 48 || category == 49 || category == 50 || category == 51 || category == 52 || category == 53;
    actions = strTok("Restore ADS Zoom,Left Gun,Gun on Left Side,Show FPS,Matrix Aiming,Rainbow Gun,Give Random Camo,Drop Canswap,Object Height,Plant Bomb,Defuse Bomb,FFA Last,TDM Last", ",");
    if (jinx_in_list(actions, name)) handled = true;
    if (!handled) return false;
    if (!(self jinx_private_host()) || !(self jinx_message_allowed()))
    { self jinx_action_blocked(); return true; }
    if (name == "Restore ADS Zoom") { self jinx_restore_ads_zoom(); return true; }
    if (category == 53) { self jinx_remove_selected_bot(index); return true; }
    if (category == 13 || category == 49) { self jinx_map_action(name); return true; }
    if (category == 51 || category == 52) { self jinx_trick_class(category, index); return true; }
    if (category == 48)
    {
        self.jinx_insta_bind = name; self.jinx_insta_down = true;
        self jinx_render(false);
        self jinx_notice("Insta Swap: " + name + ". Closed menu only; native action-slot function remains assigned.");
        return true;
    }
    if (name == "Give Random Camo")
    {
        names = getArrayKeys(level.jinx_camo_ids);
        pool = [];
        for (i = 0; i < names.size; i++) if (level.jinx_camo_ids[names[i]] > 0) pool[pool.size] = names[i];
        self jinx_apply_camo(pool[randomInt(pool.size)]);
        return true;
    }
    if (name == "Drop Canswap") { self jinx_drop_canswap(); return true; }
    if (name == "Plant Bomb" || name == "Defuse Bomb") { self jinx_sd_action(name); return true; }
    if (name == "FFA Last" || name == "TDM Last") { self thread jinx_last_action(name); return true; }
    if (name == "Object Height")
    {
        if (!isDefined(self.jinx_object_proxy)) { self jinx_notice("Transform Into Object first."); return true; }
        self.jinx_object_height += 20;
        if (self.jinx_object_height > 200) self.jinx_object_height = -40;
        self jinx_object_tick(); self jinx_render(false); return true;
    }
    key = "leftgun";
    if (name == "Show FPS") key = "showfps";
    if (name == "Matrix Aiming") key = "matrix";
    if (name == "Rainbow Gun") key = "rainbowgun";
    active = !(self jinx_enabled(key));
    self.jinx_fx[key] = active;
    if (key == "leftgun")
    {
        if (active) jinx_tune("cg_gun_y", 7, 0);
        else jinx_restore_tune("cg_gun_y");
    }
    if (key == "showfps")
    {
        if (active) jinx_tune("cg_drawFPS", 1, 0);
        else jinx_restore_tune("cg_drawFPS");
    }
    if (key == "matrix" && !active) jinx_matrix_restore();
    self jinx_render(false);
    if (key == "matrix") self jinx_notice("Matrix Aiming: slow motion while holding ADS. Affects the whole private match.");
    if (key == "rainbowgun") self jinx_notice("Random camo every 0.4s while idle. Pauses while firing, aiming, reloading or using the menu.");
    if (key == "leftgun") self jinx_notice("Viewmodel shifted left. This does not mirror the weapon or hands.");
    return true;
}

jinx_extended_tick(now)
{
    // No extra polling threads: share the existing 20 Hz service.
    self jinx_intro_tick(now);
    self jinx_rainbow_tick(now);
    self jinx_matrix_tick();
    if (self.jinx_open)
    {
        self.jinx_insta_down = true;
        self.jinx_c4_use_down = true;
        self.jinx_c4_last_press = -10000;
            return;
    }
    // Shared input processing.
    pressed = false;
    if (self.jinx_insta_bind == "Right D-Pad") pressed = self actionSlotFourButtonPressed();
    if (self.jinx_insta_bind == "Left D-Pad") pressed = self actionSlotThreeButtonPressed();
    if (pressed && !self.jinx_insta_down && !isDefined(self.jinx_noclip_anchor) && !(self isInVehicle()) && !(self isRemoteControlling()))
        self jinx_insta_swap();
    self.jinx_insta_down = pressed;
    use = self useButtonPressed();
    if (use && !self.jinx_c4_use_down)
    {
        if (now - self.jinx_c4_last_press <= 350)
        { self jinx_c4_detonate(); self.jinx_c4_last_press = -10000; }
        else self.jinx_c4_last_press = now;
    }
    self.jinx_c4_use_down = use;
}

jinx_c4_detonate()
{
    count = 0;
    for (i = 0; i < level.jinx_spawn_items.size; i++)
    {
        g = level.jinx_spawn_items[i];
        if (!isDefined(g) || g.kind != "c4" || isDefined(g.removing) || !isDefined(g.owner) || g.owner != self) continue;
        if (getTime() < g.armed_at) continue;
        if (g.parts.size == 0 || !isDefined(g.parts[0])) continue;
        jinx_spawn_explode(g); count++;
    }
    jinx_spawn_compact();
    if (count > 0) self jinx_notice("Detonated " + count + " spawned C4 charge(s).");
    else if (self.jinx_open) self jinx_notice("No armed spawned C4. Wait 1.5 seconds after spawning.");
}

jinx_object_tick()
{
    if (!isDefined(self.jinx_object_proxy)) return;
    a = self getPlayerAngles();
    self.jinx_object_proxy.origin = self.origin + (0, 0, self.jinx_object_offset + self.jinx_object_height);
    self.jinx_object_proxy.angles = (0, a[1], 0);
    self hide();
    if (self jinx_enabled("invisible")) self.jinx_object_proxy hide();
    else self.jinx_object_proxy show();
}

jinx_object_remove()
{
    if (isDefined(self.jinx_object_proxy))
    {
        self.jinx_object_proxy delete(); self.jinx_object_proxy = undefined;
        level.jinx_object_proxy = undefined;
        if (!(self jinx_enabled("invisible"))) self show();
    }
}


jinx_matrix_tick()
{
    aiming = (self jinx_enabled("matrix")) && !self.jinx_open && self adsButtonPressed() && !isDefined(self.jinx_noclip_anchor);
    if (aiming && (!isDefined(level.jinx_matrix_active) || !level.jinx_matrix_active))
    {
        level.jinx_matrix_active = true;
        setSlowMotion(level.jinx_lobby_speed, 0.25, 0.15);
    }
    else if (!aiming) jinx_matrix_restore();
}

jinx_matrix_restore()
{
    if (!isDefined(level.jinx_matrix_active) || !level.jinx_matrix_active) return;
    level.jinx_matrix_active = false;
    setSlowMotion(0.25, level.jinx_lobby_speed, 0.15);
}

jinx_extended_cleanup()
{
    self jinx_intro_clear();
    self jinx_object_remove();
    self.jinx_insta_bind = "OFF";
    self.jinx_insta_down = true;
    self.jinx_c4_last_press = -10000;
    jinx_extended_global_cleanup();
}

jinx_extended_global_cleanup()
{
    jinx_matrix_restore();
    jinx_restore_tune("cg_gun_y");
    jinx_restore_tune("cg_drawFPS");
    if (isDefined(level.jinx_object_proxy)) level.jinx_object_proxy delete();
    level.jinx_object_proxy = undefined;
}

jinx_insta_swap()
{
    current = self getCurrentWeapon();
    weapons = self getWeaponsListPrimaries();
    for (i = 0; i < weapons.size; i++)
    {
        if (weapons[i] == current) continue;
        parts = strTok(weapons[i], "+");
        if (parts.size == 0 || !jinx_in_list(level.jinx_guns, parts[0])) continue;
        self switchToWeaponImmediate(weapons[i]);
        return;
    }
    self jinx_notice("Equip two primary/secondary weapons first.");
}

jinx_drop_canswap()
{
    if (!(self jinx_weapon_ready())) return;
    if (level.jinx_custom_mode != "") { self jinx_notice("Stop Active Mode before dropping a canswap."); return; }
    if (jinx_spawn_count() >= 128) { self jinx_notice("Delete some spawned objects first."); return; }
    pool = [];
    for (i = 0; i < level.jinx_guns.size; i++)
    {
        w = level.jinx_guns[i];
        if (jinx_gun_group(w) < 22 || jinx_gun_group(w) > 27 || self hasWeapon(w)) continue;
        pool[pool.size] = w;
    }
    if (pool.size == 0) return;
    current = self getCurrentWeapon();
    w = pool[randomInt(pool.size)];
    self giveWeapon(w, 0, 16); self giveStartAmmo(w);
    item = self dropItem(w);
    if (self hasWeapon(w)) self takeWeapon(w);
    self switchToWeapon(current);
    if (!isDefined(item)) { self jinx_notice("The engine could not drop this weapon."); return; }
    g = self jinx_spawn_group("canswap"); g.parts[0] = item;
    self jinx_notice("Canswap dropped beside you. Use the normal weapon-pickup control.");
}

jinx_trick_class(category, index)
{
    if (!(self jinx_weapon_ready())) return;
    if (level.jinx_custom_mode != "") { self jinx_notice("Stop Active Mode before changing trickshot loadout."); return; }
    pair = level.jinx_trick_kits[category][index];
    primary = jinx_kit_weapon(pair[0]); secondary = jinx_kit_weapon(pair[1]);
    old = self getWeaponsListPrimaries();
    for (i = 0; i < old.size; i++) self takeWeapon(old[i]);
    self giveWeapon(primary, 0, 16); self giveWeapon(secondary, 0, 16);
    self.jinx_camo[primary] = 16; self.jinx_camo[secondary] = 16;
    self giveStartAmmo(primary); self giveStartAmmo(secondary);
    // Equipment setup follows the stock MP _class path.
    if (isDefined(self.grenadetypeprimary) && self.grenadetypeprimary != "" && self hasWeapon(self.grenadetypeprimary))
        self takeWeapon(self.grenadetypeprimary);
    if (isDefined(self.grenadetypesecondary) && self.grenadetypesecondary != "" && self hasWeapon(self.grenadetypesecondary))
        self takeWeapon(self.grenadetypesecondary);
    self giveWeapon("sticky_grenade_mp");
    self setWeaponAmmoClip("sticky_grenade_mp", 1);
    self switchToOffhand("sticky_grenade_mp");
    self.grenadetypeprimary = "sticky_grenade_mp";
    self.grenadetypeprimarycount = 1;
    self setOffhandSecondaryClass("proximity_grenade_mp");
    self giveWeapon("proximity_grenade_mp");
    self setWeaponAmmoClip("proximity_grenade_mp", 2);
    self.grenadetypesecondary = "proximity_grenade_mp";
    self.grenadetypesecondarycount = 2;
    self switchToWeapon(primary);
    if (!(self jinx_enabled("fastswap")))
    {
        self.jinx_fx["fastswap"] = true;
        self jinx_owned_perk("specialty_fastweaponswitch", true);
    }
    self jinx_notice("Trickshot loadout: " + level.jinx_options[category][index] + ". Diamond, attachments, Semtex and 2 Shock Charges.");
}

jinx_last_action(name)
{
    self endon("disconnect"); level endon("game_ended");
    if (isDefined(self.jinx_last_busy) && self.jinx_last_busy) return;
    mode = toLower(getDvar(#"g_gametype"));
    if (mode == "") mode = level.gametype;
    if ((name == "FFA Last" && mode != "dm") || (name == "TDM Last" && mode != "tdm"))
    { self jinx_notice(name + " requires its native gametype. Current: " + mode); return; }
    if (mode == "tdm" && self.team != "axis" && self.team != "allies")
    { self jinx_notice("Join Allies or Axis first."); return; }
    self.jinx_last_busy = true;
    limit = level.scorelimit;
    unlimited = !isDefined(limit) || limit <= 1;
    if (unlimited) { limit = 30; if (mode == "tdm") limit = 75; }
    step = level.teamscoreperkill;
    if (!isDefined(step) || step < 1) step = 1;
    target = int(limit - step); if (target < 0) target = 0;
    if (mode == "dm")
    {
        self.pointstowin = target; self.pers["pointstowin"] = target;
        self.kills = int(target / step); self.pers["kills"] = self.kills;
        self.score = self.kills * 100; self.pers["score"] = self.score;
        self thread maps\mp\gametypes\_globallogic::checkscorelimit();
    }
    else
    {
        game["teamScores"][self.team] = target;
        setTeamScore(self.team, target);
        maps\mp\gametypes\_globallogic_score::updateteamscores(self.team);
        level thread maps\mp\gametypes\_globallogic::checkscorelimit();
    }
    wait 0.25;
    actual = self.pointstowin;
    if (mode == "tdm") actual = getTeamScore(self.team);
    message = name + ": requested " + target + ", current " + actual;
    if (actual != target) message += " - score was overwritten by another script/rule.";
    else if (unlimited) message += " (unlimited match: no winning limit).";
    else message += "/" + limit + ".";
    self jinx_notice(message); self iprintln("^1JINX ^7" + message);
    self.jinx_last_busy = false;
}

jinx_sd_action(name)
{
    if (level.gametype != "sd" || !isAlive(self) || level.gameended)
    { self jinx_notice("Requires a living host in an active Search and Destroy round."); return; }
    if (name == "Defuse Bomb")
    {
        if (!level.bombplanted || level.bombdefused || level.bombexploded || !isDefined(level.tickingobject))
        { self jinx_notice("There is no active planted bomb."); return; }
        if (self.team != game["defenders"])
        { self jinx_notice("Join the defending team to defuse."); return; }
        self jinx_close();
        level thread maps\mp\gametypes\sd::bombdefused();
        self jinx_notice("Bomb defused through the native round logic.");
        return;
    }
    if (self.team != game["attackers"] || level.bombplanted || !isDefined(level.bombzones))
    { self jinx_notice("Plant requires the attacking team and an unplanted bomb."); return; }
    best = undefined; bestdist = 999999;
    for (i = 0; i < level.bombzones.size; i++)
    {
        zone = level.bombzones[i]; d = distance(self.origin, zone.curorigin);
        if (d < bestdist) { best = zone; bestdist = d; }
    }
    if (!isDefined(best) || bestdist > 180)
    { self jinx_notice("Move within 180 units of a bomb site to quick-plant."); return; }
    if (!level.multibomb && (!isDefined(level.sdbomb.carrier) || level.sdbomb.carrier != self))
    { self jinx_notice("Pick up the bomb first, then select Plant Bomb near a site."); return; }
    self jinx_close();
    best maps\mp\gametypes\sd::onuseplantobject(self);
}

jinx_map_action(name)
{
    if (name == "Current Map Info")
    { self jinx_notice("Map: " + getDvar("mapname") + " | Mode: " + level.gametype + ". DLC maps require their installed files."); return; }
    if (name == "Reload Current Map")
    {
        self jinx_save_settings();
        maps\mp\gametypes\_globallogic_score::resetallscores();
        map_restart(0);
        return;
    }
}

// v0.6.6 visual and lifecycle services, sharing the existing input poll.
jinx_action_blocked()
{
    if (!(self isHost())) { self jinx_notice("Host access required."); return; }
    if (!isAlive(self)) { self jinx_notice("Wait until you have spawned."); return; }
    self jinx_notice("Action blocked: session is not private/local. Start Custom Games or LAN. Private=" + sessionModeIsPrivate() + " Online=" + sessionModeIsOnlineGame());
}

jinx_plain_name(name)
{
    text = "";
    for (i = 0; i < name.size && text.size < 20; i++)
    {
        c = getSubStr(name, i, i + 1);
        if (c == "^" && i + 1 < name.size) { i++; continue; }
        text += c;
    }
    return text;
}

jinx_intro_start()
{
    self jinx_intro_clear();
    self.jinx_intro_started = getTime();
    self.jinx_intro_until = getTime() + 9000;
    self.jinx_intro_text = "Hello " + jinx_plain_name(self.name) + ", welcome to Jinx ModMenu";
    self.jinx_intro_next = 0;
}

jinx_intro_tick(now)
{
    if (!isDefined(self.jinx_intro_until)) return;
    if (self.jinx_open || now >= self.jinx_intro_until || !isAlive(self))
    { self jinx_intro_clear(); return; }
    if (self.jinx_intro.size == 0)
    {
        for (i = 0; i < 3; i++)
        {
            h = newClientHudElem(self);
            h.archived = true; h.hideWhenInMenu = true;
            h.horzAlign = "center"; h.vertAlign = "middle";
            h.alignX = "center"; h.alignY = "middle";
            h.font = "objective"; h.fontScale = 1.6;
            h.color = (1, 1, 1); h.glowColor = (0.1, 0.35, 1); h.glowAlpha = 0.85;
            h.sort = 30; h.x = 0; h.y = -190;
            if (i > 0) { h.y = -165; h.fontScale = 1.3; }
            if (i == 1) { h.alignX = "right"; h.x = 20; h jinx_set_text("Access Level: "); }
            if (i == 2) { h.alignX = "left"; h.x = 22; h.color = (0.1, 0.4, 1); h jinx_set_text("Host"); }
            self.jinx_intro[i] = h;
        }
        self thread jinx_intro_disconnect(self.jinx_intro);
    }
    if (now >= self.jinx_intro_next)
    {
        self.jinx_intro_next = now + 50;
        length = int((now - self.jinx_intro_started) / 45);
        if (length > self.jinx_intro_text.size) length = self.jinx_intro_text.size;
        self.jinx_intro[0] jinx_set_text(getSubStr(self.jinx_intro_text, 0, length));
        self.jinx_intro[2].alpha = 0.45 + 0.55 * abs(sin((now - self.jinx_intro_started) * 0.4));
        remaining = self.jinx_intro_until - now;
        if (remaining < 1000)
        {
            self.jinx_intro[0].alpha = remaining / 1000.0;
            self.jinx_intro[1].alpha = remaining / 1000.0;
            self.jinx_intro[2].alpha *= remaining / 1000.0;
        }
    }
}

jinx_intro_clear()
{
    self notify("jinx_intro_removed");
    if (isDefined(self.jinx_intro))
        for (i = 0; i < self.jinx_intro.size; i++) if (isDefined(self.jinx_intro[i])) self.jinx_intro[i] destroy();
    self.jinx_intro = []; self.jinx_intro_until = undefined;
}

jinx_intro_disconnect(elements)
{
    self endon("jinx_intro_removed");
    self waittill("disconnect");
    for (i = 0; i < elements.size; i++) if (isDefined(elements[i])) elements[i] destroy();
}

jinx_rainbow_tick(now)
{
    if (!(self jinx_enabled("rainbowgun")) || self.jinx_open) return;
    if (isDefined(self.jinx_rainbow_next) && now < self.jinx_rainbow_next) return;
    if (self attackButtonPressed() || self adsButtonPressed() || self isReloading() || self isSwitchingWeapons()) return;
    if (isDefined(self.jinx_noclip_anchor) || self isInVehicle() || self isRemoteControlling()) return;
    w = self getCurrentWeapon();
    if (!jinx_practice_firearm(w)) return;
    self.jinx_rainbow_next = now + 400;
    clip = self getWeaponAmmoClip(w); stock = self getWeaponAmmoStock(w);
    camo = randomIntRange(1, 46);
    if (isDefined(self.jinx_camo[w]) && self.jinx_camo[w] == camo) camo = (camo % 45) + 1;
    self takeWeapon(w); self giveWeapon(w, 0, camo);
    self setWeaponAmmoClip(w, clip); self setWeaponAmmoStock(w, stock);
    self switchToWeaponImmediate(w);
    self.jinx_camo[w] = camo;
}

jinx_design_name()
{
    if (self.jinx_settings["design"] == 1) return "LARGE SIDE";
    if (self.jinx_settings["design"] == 2) return "FULL SCREEN";
    return "CLASSIC";
}

jinx_alternate_layout()
{
    side = self.jinx_settings["design"] == 1;
    width = self jinx_panel_width();
    for (i = 0; i < self.jinx_hud.size; i++)
    {
        e = self.jinx_hud[i];
        if (side) { e.horzAlign = "right"; e.x = e.x + 305 - width; }
        else { e.horzAlign = "center"; e.x = e.x + 305 - width / 2; }
    }
    // Reuse the two existing background elements: no added menu HUD slots.
    back = self.jinx_hud[0]; panel = self.jinx_hud[1];
    back.alpha = 0;
    panel.y = -240;
    panel.color = jinx_background(self.jinx_settings["background"]);
    panel.alpha = 0.82;
    if (side)
    {
        panel.x = 0 - width; panel setShader("white", width, 480);
        for (i = 0; i < self.jinx_selection_parts.size; i++)
        {
            e = self.jinx_selection_parts[i]; e.x = 0 - width;
            if (i == 0) { e setShader("white", width, 14); e.alpha = 0.75; }
            else e.alpha = 0;
        }
    }
    else
    {
        panel.x = -500; panel setShader("white", 1000, 480);
        panel.color = (0, 0, 0); panel.alpha = 0.18;
        self.jinx_hud[6].alpha = 0;
        self.jinx_heading.x = 0; self.jinx_heading.y = -205;
        self.jinx_heading.font = "default"; self.jinx_heading.fontScale = 1.6;
        self.jinx_status.x = 0; self.jinx_status.y = 160;
        self.jinx_help.alignX = "center"; self.jinx_help.x = 0; self.jinx_help.y = 184;
        for (i = 0; i < self.jinx_selection_parts.size; i++) self.jinx_selection_parts[i].alpha = 0;
        self setBlur(2, 0.2); self.jinx_menu_blur = true;
    }
    if (side && isDefined(self.jinx_menu_blur) && self.jinx_menu_blur)
    { self setBlur(0, 0.15); self.jinx_menu_blur = false; }
}

jinx_design_focus(y)
{
    selected = int((y - self.jinx_first_row + 7) / self.jinx_row_step);
    self.jinx_track.alpha = 0; self.jinx_thumb.alpha = 0;
    focus = self.jinx_category;
    if (self.jinx_screen == "main") focus = self.jinx_cursor;
    if (focus > 16)
    {
        focus = 2;
        if (self.jinx_return_depth > 0) focus = self.jinx_return_stack[0];
        if (focus > 16) focus = 2;
    }
    if (self.jinx_screen != "main")
        for (n = 0; n < 17; n++) if (level.jinx_main_order[n] == focus) { focus = n; break; }
    left = jinx_wrap(focus - 1, 17); right = jinx_wrap(focus + 1, 17);
    self.jinx_hud[2] jinx_set_text(level.jinx_categories[level.jinx_main_order[left]]);
    self.jinx_hud[3] jinx_set_text(level.jinx_categories[level.jinx_main_order[right]]);
    for (i = 2; i <= 3; i++)
    {
        h = self.jinx_hud[i]; h.alignX = "center"; h.x = -220;
        if (i == 3) h.x = 220;
        h.y = -205; h.font = "default"; h.fontScale = 1.1;
        h.color = jinx_color(self.jinx_settings["color1"]); h.alpha = 0.8;
    }
    self.jinx_hud[4] jinx_set_text("JINX MOD MENU");
    self.jinx_hud[4].x = 0; self.jinx_hud[4].y = -232;
    self.jinx_hud[4].fontScale = 1; self.jinx_hud[4].alpha = 0.7;
    if (self.jinx_screen == "main") self.jinx_heading jinx_set_text("Main Menu");
    state = "";
    if (self.jinx_screen != "main" && self.jinx_subcursor[self.jinx_category] > 0)
    {
        name = level.jinx_options[self.jinx_category][self.jinx_subcursor[self.jinx_category] - 1];
        state = "  |  " + (self jinx_option_state(self.jinx_category, name));
    }
    for (i = 0; i < self.jinx_rows.size; i++)
    {
        h = self.jinx_rows[i]; h.alignX = "center"; h.x = 0;
        h.y = self.jinx_first_row + i * self.jinx_row_step;
        h.font = "default"; h.fontScale = 1.15;
        h.color = (1, 1, 1); h.alpha = 0.92; h.glowAlpha = 0;
        if (i == selected)
        {
            h.color = jinx_color(self.jinx_settings["color2"]);
            h.fontScale = 1.35; h.alpha = 1;
            h.glowColor = h.color; h.glowAlpha = 0.4;
        }
    }
    if (self.jinx_screen == "main") self.jinx_status jinx_set_text("MAIN MENU  " + (self.jinx_cursor + 1) + "/17");
    else
    {
        cursor = self.jinx_subcursor[self.jinx_category]; count = level.jinx_options[self.jinx_category].size;
        self.jinx_status jinx_set_text("OPTION " + cursor + "/" + count + " | PAGE " + (jinx_page(cursor) + 1) + "/" + (jinx_page(count) + 1) + state);
    }
}

jinx_add_practice_bot(balanced)
{
    if (level.jinx_join_locked) { self jinx_notice("Anti-Join is ON. Turn it OFF before adding bots."); return false; }
    self endon("disconnect"); level endon("game_ended");
    if (isDefined(level.jinx_bot_adding) && level.jinx_bot_adding)
    { self jinx_notice("A bot is already joining. Wait for the result."); return; }
    allowed = maps\mp\bots\_bot::bot_gametype_allowed();
    if (!allowed && level.gametype != "sd")
    { self jinx_notice("Native practice bots are unsupported in this mode."); return; }
    client_limit = jinx_bot_client_limit();
    if (getEntArray("player", "classname").size >= client_limit)
    { self jinx_notice("No client slots available. Increase lobby slots or remove a bot."); return; }
    level.jinx_bot_adding = true;
    bot = addTestClient();
    if (!isDefined(bot))
    { level.jinx_bot_adding = false; self jinx_notice("Engine refused addTestClient: no available bot/client slot."); return; }
    bot.pers["isBot"] = 1;
    bot.jinx_keep_practice_bot = true;
    team = "autoassign";
    if (level.teambased)
    {
        team = "axis"; if (self.team == "axis") team = "allies";
        if (isDefined(balanced) && balanced)
        {
            axis_count = 0; allies_count = 0;
            foreach (p in level.players)
            {
                if (p == bot || !isDefined(p.team)) continue;
                if (p.team == "axis") axis_count++;
                if (p.team == "allies") allies_count++;
            }
            if (axis_count < allies_count) team = "axis";
            if (allies_count < axis_count) team = "allies";
        }
        bot.pers["team"] = team;
    }
    self jinx_notice("Bot connected. Assigning team and loadout...");
    // Allow stock connection initialization to finish before retrying its loader.
    wait 1;
    if (!isDefined(bot)) { level.jinx_bot_adding = false; return; }
    if (!isDefined(bot.pers["bot_loadout"])) bot thread maps\mp\bots\_bot_loadout::on_bot_connect();
    bot thread maps\mp\bots\_bot::bot_spawn_think(team);
    for (attempt = 0; attempt < 20; attempt++)
    {
        wait 0.4;
        if (!isDefined(bot)) { level.jinx_bot_adding = false; self jinx_notice("Bot disconnected before spawning."); return; }
        if (isAlive(bot) && isDefined(bot.sessionstate) && bot.sessionstate == "playing")
        {
            level.jinx_bot_adding = false;
            self jinx_notice("Bot spawned: " + bot.name);
            return true;
        }
    }
    level.jinx_bot_adding = false;
    if (level.gametype == "sd") self jinx_notice("Bot connected; S&D may defer spawning until next round. No plant/defuse objective AI.");
    else self jinx_notice("Bot connected but has not spawned. State: " + bot.sessionstate + ". Check team slots.");
    return isDefined(bot);
}

// Based on stock _bot::bot_comp_stomp_remove. Only JINX-created practice bots
// are exempt from automatic quota removal; manual engine kicks remain available.
jinx_bot_remove_guard(team)
{
    if (isDefined(level.jinx_manual_bots) && level.jinx_manual_bots) return;
    bots = [];
    foreach (player in level.players)
    {
        if (!isDefined(player.team)) continue;
        if (isDefined(player.jinx_keep_practice_bot) && player.jinx_keep_practice_bot) continue;
        if (!(player maps\mp\_utility::is_bot())) continue;
        if (level.teambased && player.team != team) continue;
        bots[bots.size] = player;
    }
    if (bots.size == 0) return;
    remove = bots[randomInt(bots.size)];
    foreach (bot in bots)
    {
        if (!(bot maps\mp\bots\_bot_combat::bot_has_enemy())) { remove = bot; break; }
    }
    remove botLeaveGame();
}

// Native renderer experiment. These are documented BO2 dvars, not screen-space HUDs.
// Visibility/range rules still belong to the client; all-hidden-enemy names are not guaranteed.


// Preserve stock spawn behavior until the host explicitly takes manual control.
jinx_stock_bot_spawn(team)
{
    if (isDefined(level.jinx_join_locked) && level.jinx_join_locked) return false;
    if (isDefined(level.jinx_manual_bots) && level.jinx_manual_bots) return false;
    bot = addTestClient();
    if (!isDefined(bot)) return false;
    bot.pers["isBot"] = 1;
    if (team != "autoassign") bot.pers["team"] = team;
    bot thread maps\mp\bots\_bot::bot_spawn_think(team);
    return true;
}

jinx_bot_client_limit()
{
    count = int(getDvar(#"sv_maxclients"));
    if (count < 1 || count > 18) count = 18;
    if (isLocalGame() && count > 10) count = 10;
    return count;
}

jinx_bot_entities()
{
    result = [];
    foreach (p in level.players)
        if (isDefined(p) && p maps\mp\_utility::is_bot()) result[result.size] = p;
    return result;
}

jinx_add_bot_batch(fill)
{
    if (level.jinx_join_locked) { self jinx_notice("Anti-Join is ON. Turn it OFF before adding bots."); return; }
    self endon("disconnect"); level endon("game_ended");
    level endon("jinx_bot_batch_cancel");
    if (isDefined(level.jinx_bot_batch) && level.jinx_bot_batch)
    { self jinx_notice("Bots are being added. Remove All Bots cancels the operation."); return; }
    level.jinx_manual_bots = true;
    level.jinx_bot_batch = true;
    wait 0.5;
    added = 0;
    attempts = 1; if (fill) attempts = 18;
    for (i = 0; i < attempts; i++)
    {
        if (level.jinx_join_locked || level.players.size >= jinx_bot_client_limit()) break;
        ok = self jinx_add_practice_bot(fill);
        if (!isDefined(ok) || !ok) break;
        added++;
        wait 0.3;
    }
    level.jinx_bot_batch = false;
    current = jinx_bot_entities();
    self jinx_notice("Added " + added + ". Bots connected: " + current.size + ". Client capacity: " + jinx_bot_client_limit());
}

jinx_bot_cancel_add()
{
    level notify("jinx_bot_batch_cancel");
    level.jinx_bot_batch = false; level.jinx_bot_adding = false;
    level.jinx_manual_bots = true;
}

jinx_bot_picker()
{
    bots = jinx_bot_entities();
    if (bots.size == 0) { self jinx_notice("No bots to remove."); return; }
    self.jinx_bot_targets = bots;
    level.jinx_options[53] = []; level.jinx_links[53] = [];
    for (i = 0; i < bots.size; i++)
    {
        level.jinx_options[53][i] = jinx_plain_name(bots[i].name);
        level.jinx_links[53][i] = -1;
    }
    self.jinx_return_stack[self.jinx_return_depth] = self.jinx_category;
    self.jinx_return_depth++;
    self.jinx_category = 53; self.jinx_subcursor[53] = 0;
    self jinx_render(false);
}

jinx_remove_selected_bot(index)
{
    if (!isDefined(self.jinx_bot_targets) || index >= self.jinx_bot_targets.size)
    { self jinx_notice("Bot list changed. Reopen Remove One Bot."); return; }
    bot = self.jinx_bot_targets[index];
    if (!isDefined(bot) || !(bot maps\mp\_utility::is_bot()))
    { self jinx_notice("That bot already left. Reopen Remove One Bot."); return; }
    jinx_bot_cancel_add();
    name = bot.name;
    bot botLeaveGame();
    self jinx_back();
    self jinx_notice("Removal requested: " + name + ". Native autofill disabled for this match.");
}

jinx_remove_all_bots()
{
    self endon("disconnect"); level endon("game_ended");
    jinx_bot_cancel_add();
    bots = jinx_bot_entities();
    foreach (bot in bots) if (isDefined(bot)) bot botLeaveGame();
    wait 0.5;
    remaining = jinx_bot_entities();
    self jinx_notice("Bots remaining: " + remaining.size + ". Native autofill disabled for this match.");
}

// Legacy BO2 map context setup, exposed as TEST rather than claimed as a fixed
// Plutonium private-map switch. No injected console executor or client modification.

// Explicit recovery action; never applied automatically to a user's camera settings.
jinx_restore_ads_zoom()
{
    self.jinx_fx["promod"] = false;
    self.jinx_fun_old_fov = 0;
    self.jinx_fov = 0;
    self resetFov();
    setDvar("cg_fovMin", 1);
    setDvar("cg_fovScale", 1);
    self setClientDvar("cg_fovMin", 1);
    self setClientDvar("cg_fovScale", 1);
    self jinx_render(false);
    self jinx_notice("ADS camera reset: FOV minimum 1, scale 1.\nPro-Mod OFF. Release ADS, then scope in again.");
}

// Reorder existing labels only; never drop an unlisted option or fabricate a function.
jinx_order_rows(category, preferred)
{
    ordered = []; used = [];
    original = level.jinx_options[category];
    foreach (label in strTok(preferred, ","))
        for (i = 0; i < original.size; i++)
            if (original[i] == label && !isDefined(used[i]))
            { ordered[ordered.size] = original[i]; used[i] = true; }
    for (i = 0; i < original.size; i++)
        if (!isDefined(used[i])) ordered[ordered.size] = original[i];
    level.jinx_options[category] = ordered;
}

// Host administration: entity references are revalidated before every operation.
jinx_admin_catalog()
{
    level.jinx_options[14] = strTok("Host Controls,Player Permissions,Game Rules,Team Settings,Match Timer,Private Lobby Configuration,Show FPS,Gun on Left Side,Reset Match Scores,Clear Spawned Objects,Stop Active Mode,Clear Player Effects,Revoke All Menus,Match Restart,End Game", ",");
    level.jinx_options[15] = strTok("Include Host,Heal All,Refill Ammo All,Give God Mode All,Take God Mode All,Give Infinite Ammo All,Take Infinite Ammo All,Freeze All,Unfreeze All,Bring All To Me,Give Menu All,Remove Menu All,Clear Effects All", ",");
    level.jinx_options[16] = strTok("Player List,Selected Player Info,Spectate Player,Teleport To Player,Teleport Player To Me,Heal Player,Refill Ammo,Give God Mode,Take God Mode,Give Infinite Ammo,Take Infinite Ammo,Freeze Player,Unfreeze Player,Give Menu,Remove Menu,More Options 2/2,Kick Player,Ban Player,Set Prestige", ",");
    level.jinx_titles[58] = "Select Player"; level.jinx_options[58] = [];
    level.jinx_titles[59] = "More Player Options";
    level.jinx_options[59] = strTok("Give All Perks,Remove Granted Perks,Give My Weapon,Respawn Player,Clear Player Effects", ",");
    level.jinx_titles[60] = "Player Permissions";
    level.jinx_options[60] = strTok("Player List,Selected Player Info,Give Menu,Remove Menu,Give Menu All,Remove Menu All", ",");
    level.jinx_titles[61] = "Game Rules";
    level.jinx_options[61] = strTok("Disable Killcam,Disable Final Killcam,Long Killcams,Set Game Speed,Freeze Lobby,Super Jump,Super Speed", ",");
    level.jinx_titles[62] = "Team Settings";
    level.jinx_options[62] = strTok("Player List,Selected Player Info,Move To Allies,Move To Axis", ",");
    level.jinx_titles[63] = "Match Timer";
    level.jinx_options[63] = strTok("Unlimited Game Time,Private Match Settings", ",");
}

jinx_has_menu()
{
    if (level.jinx_phase1_ended || level.jinx_access_closed) return false;
    if (!(sessionModeIsPrivate() || sessionModeIsSystemLink() || !sessionModeIsOnlineGame())) return false;
    return self isHost() || (isDefined(self.jinx_access) && self.jinx_access);
}

jinx_admin_valid(p)
{
    if (!isDefined(p)) return false;
    foreach (client in level.players) if (isDefined(client) && client == p) return true;
    return false;
}

jinx_admin_push(category)
{
    self.jinx_return_stack[self.jinx_return_depth] = self.jinx_category;
    self.jinx_return_depth++;
    self.jinx_category = category;
    self.jinx_subcursor[category] = 0;
    self jinx_render(false);
}

jinx_admin_list()
{
    labels = []; refs = []; links = [];
    foreach (p in level.players)
    {
        if (!isDefined(p) || !isDefined(p.jinx_fx)) continue;
        label = jinx_plain_name(p.name);
        if (p isHost()) label += " [HOST]";
        else if (p is_bot()) label += " [BOT]";
        else if (isDefined(p.jinx_access) && p.jinx_access) label += " [MENU]";
        labels[labels.size] = label; refs[refs.size] = p; links[links.size] = -1;
    }
    self.jinx_admin_refs = refs;
    level.jinx_options[58] = labels; level.jinx_links[58] = links;
    self jinx_admin_push(58);
}

jinx_admin_state(category, name)
{
    if (name == "Ban Player") return "MATCH";
    if (name == "Set Prestige") return "DISPLAY";
    if (category == 64) return "DISPLAY";
    if (category == 61 || category == 63) return jinx_lobby_state(name);
    if (name == "Include Host") { if (isDefined(self.jinx_admin_include) && self.jinx_admin_include) return "^2ON"; return "^1OFF"; }
    if (name == "Player List" || name == "More Options 2/2" || name == "Player Permissions" || name == "Game Rules" || name == "Team Settings" || name == "Match Timer") return ">";
    if (name == "Show FPS") return self jinx_toggle_label("showfps");
    if (name == "Gun on Left Side") return self jinx_toggle_label("leftgun");
    if (name == "Give Menu" || name == "Remove Menu")
    {
        if (!jinx_admin_valid(self.jinx_admin_target)) return "SELECT";
        if (self.jinx_admin_target isHost()) return "HOST";
        if (self.jinx_admin_target is_bot()) return "BOT";
        if (self.jinx_admin_target.jinx_access) return "^2GRANTED";
        return "^1NONE";
    }
    return "USE";
}

jinx_admin_action(category, name, index)
{
    if (!(self jinx_message_allowed())) { self jinx_action_blocked(); return; }
    if (name == "Clear Match Bans") { level.jinx_match_bans = []; self jinx_notice("Match ban list cleared. Anti-Join is independent."); return; }
    if (name == "Set Prestige")
    {
        if (!jinx_admin_valid(self.jinx_admin_target)) { self jinx_notice("Select a player first."); return; }
        jinx_prestige_catalog();
        self.jinx_subcursor[64] = 0;
        self jinx_admin_push(64); self jinx_notice("Scoreboard prestige display only. No XP, unlocks or saved profile changes."); return;
    }
    if (category == 64) { self jinx_prestige_display(name, index); return; }
    if (category == 58)
    {
        if (!isDefined(self.jinx_admin_refs) || index >= self.jinx_admin_refs.size || !jinx_admin_valid(self.jinx_admin_refs[index]))
        { self jinx_notice("Player left. Go back and refresh Player List."); return; }
        self.jinx_admin_target = self.jinx_admin_refs[index];
        self jinx_back(); self jinx_notice("Selected: " + jinx_plain_name(self.jinx_admin_target.name)); return;
    }
    if (name == "Player List") { self jinx_admin_list(); return; }
    if (name == "More Options 2/2") { self jinx_admin_push(59); return; }
    if (name == "Include Host")
    { self.jinx_admin_include = !(isDefined(self.jinx_admin_include) && self.jinx_admin_include); self jinx_render(false); return; }
    if (category == 61 || category == 63) { self jinx_lobby_action(name); return; }
    if (category == 14)
    {
        if (name == "Host Controls" || name == "Private Lobby Configuration") { self jinx_lobby_action("Private Match Settings"); return; }
        if (name == "Match Restart") { self jinx_lobby_action("Fast Restart"); return; }
        if (name == "End Game") { self jinx_lobby_action(name); return; }
        if (name == "Show FPS" || name == "Gun on Left Side") { self jinx_extended_dispatch(category, name, index); return; }
        if (name == "Reset Match Scores") { maps\mp\gametypes\_globallogic_score::resetallscores(); self jinx_notice("Match scores reset; no persistent stats changed."); return; }
        if (name == "Clear Spawned Objects") { jinx_spawn_clear(); self jinx_notice("JINX spawned objects cleared."); return; }
        if (name == "Stop Active Mode") { jinx_custom_stop(); self jinx_notice("Custom mode stopped."); return; }
        if (name == "Revoke All Menus") name = "Remove Menu All";
        if (name == "Clear Player Effects") name = "Clear Effects All";
    }
    if (category == 15 || name == "Give Menu All" || name == "Remove Menu All" || name == "Clear Effects All")
    {
        count = 0;
        foreach (p in level.players)
        {
            if (!jinx_admin_valid(p) || !isDefined(p.jinx_fx)) continue;
            if (p isHost() && !(isDefined(self.jinx_admin_include) && self.jinx_admin_include)) continue;
            if (self jinx_admin_apply(p, name)) count++;
        }
        self jinx_render(false); self jinx_notice("Applied to " + count + " eligible players. Temporary effects reset on respawn."); return;
    }
    p = self.jinx_admin_target;
    if (!jinx_admin_valid(p)) { self jinx_notice("Choose a connected player in Player List first."); return; }
    if (name == "Selected Player Info")
    { self jinx_notice(jinx_plain_name(p.name) + " | Team: " + p.pers["team"] + " | State: " + p.sessionstate); return; }
    if (name == "Give Menu" || name == "Remove Menu")
    {
        if (p is_bot()) { self jinx_notice("Selected player is a BOT, not a missing player. Bots have no human menu controls. Use God/Ammo/Freeze/Teleport on this bot instead."); return; }
        if (p isHost()) { self jinx_notice("The host already has full access; it cannot be revoked."); return; }
        wanted = name == "Give Menu";
        if (wanted == p.jinx_access) { self jinx_notice("Menu access is already in that state."); return; }
    }
    if (name == "Spectate Player") { self thread jinx_admin_spectate(p); return; }
    if (name == "Kick Player" || name == "Ban Player")
    {
        if (p isHost()) { self jinx_notice("The host cannot be kicked."); return; }
        if (!isDefined(self.jinx_kick_confirm) || self.jinx_kick_confirm != p || self.jinx_kick_action != name || getTime() > self.jinx_kick_until)
        { self.jinx_kick_confirm = p; self.jinx_kick_action = name; self.jinx_kick_until = getTime() + 4000; self jinx_notice("Select " + name + " again within 4 seconds. Ban lasts for this map only."); return; }
        if (name == "Ban Player")
        {
            if (p is_bot()) { self jinx_notice("Bots have no human account to ban. Use Remove One Bot or Kick Player."); return; }
            guid = p getGuid();
            if (!isDefined(guid) || guid == "" || guid == "0") { self jinx_notice("Cannot ban: no stable player GUID."); return; }
            level.jinx_match_bans[guid] = true;
        }
        self.jinx_kick_confirm = undefined; self.jinx_admin_target = undefined;
        kick(p getEntityNumber()); return;
    }
    if (self jinx_admin_apply(p, name)) { self jinx_render(false); self jinx_notice(name + ": applied to " + jinx_plain_name(p.name)); }
    else self jinx_notice("Not applied: player must be alive, on foot and eligible. Respawn/team changes require TDM or FFA; teams require a team mode.");
}

jinx_admin_apply(p, name)
{
    if (!(self jinx_message_allowed()) || !jinx_admin_valid(p)) return false;
    if (name == "Give Menu" || name == "Give Menu All") return self jinx_grant_menu(p, true);
    if (name == "Remove Menu" || name == "Remove Menu All") return self jinx_grant_menu(p, false);
    if (name == "Clear Player Effects" || name == "Clear Effects All")
    { p jinx_admin_clear(); p jinx_stop_effects(); return true; }
    if (!isAlive(p) || p.sessionstate != "playing" || p isInVehicle() || p isRemoteControlling()) return false;
    if (name == "Heal Player" || name == "Heal All") { p.health = p.maxhealth; return true; }
    if (name == "Refill Ammo" || name == "Refill Ammo All")
    { if (level.jinx_custom_mode != "") return false; p jinx_admin_refill(); return true; }
    if (name == "Give God Mode" || name == "Give God Mode All") { p.jinx_admin_god = true; p enableInvulnerability(); return true; }
    if (name == "Take God Mode" || name == "Take God Mode All")
    { p.jinx_admin_god = false; p.jinx_fx["god"] = false; if (!isDefined(p.jinx_noclip_anchor)) p disableInvulnerability(); return true; }
    if (name == "Give Infinite Ammo" || name == "Give Infinite Ammo All")
    { if (level.jinx_custom_mode != "") return false; p.jinx_admin_ammo = true; return true; }
    if (name == "Take Infinite Ammo" || name == "Take Infinite Ammo All") { p.jinx_admin_ammo = false; p.jinx_fx["ammo"] = false; return true; }
    if (name == "Freeze Player" || name == "Freeze All")
    { if (isDefined(p.jinx_noclip_anchor)) return false; p.jinx_admin_frozen = true; p.jinx_admin_origin = p.origin; return true; }
    if (name == "Unfreeze Player" || name == "Unfreeze All") { p.jinx_admin_frozen = false; return true; }
    if (name == "Teleport To Player")
    {
        if (p == self || !isAlive(self) || isDefined(self.jinx_noclip_anchor)) return false;
        point = self jinx_teleport_near(p.origin); if (!isDefined(point)) return false;
        self jinx_teleport_move(point, undefined); return true;
    }
    if (name == "Teleport Player To Me" || name == "Bring All To Me")
    {
        if (p == self || !isAlive(self) || isDefined(p.jinx_noclip_anchor)) return false;
        point = p jinx_teleport_near(self.origin); if (!isDefined(point)) return false;
        p setOrigin(point); p setVelocity((0,0,0)); p.jinx_admin_origin = point; return true;
    }
    if (name == "Give All Perks") { for (i=0; i<level.jinx_game_perks.size; i++) p jinx_game_perk(i, true); return true; }
    if (name == "Remove Granted Perks") { p jinx_game_perks_clear(); return true; }
    if (name == "Give My Weapon")
    { if (level.jinx_custom_mode != "") return false; w = self getCurrentWeapon(); if (jinx_gun_group(strTok(w,"+")[0]) < 0) return false; p jinx_give_gun(w); return true; }
    if (name == "Respawn Player" || name == "Move To Allies" || name == "Move To Axis")
    {
        if (level.gametype != "tdm" && level.gametype != "dm") return false;
        if (name != "Respawn Player")
        {
            if (!level.teambased) return false;
            team = "allies"; if (name == "Move To Axis") team = "axis";
            p.pers["team"] = team; p.team = team; p.sessionteam = team;
        }
        p thread jinx_admin_respawn(); return true;
    }
    return false;
}

jinx_admin_respawn()
{
    self endon("disconnect"); level endon("game_ended");
    self jinx_admin_clear(); self jinx_stop_effects(); self jinx_close();
    self notify("jinx_life_stop"); self [[level.spawnplayer]]();
}

jinx_admin_clear()
{
    if (isDefined(self.jinx_admin_god) && self.jinx_admin_god && !(self jinx_enabled("god")) && !isDefined(self.jinx_noclip_anchor)) self disableInvulnerability();
    self.jinx_admin_god = false; self.jinx_admin_ammo = false; self.jinx_admin_frozen = false;
}

jinx_admin_refill()
{
    foreach (w in self getWeaponsListPrimaries())
    { self giveMaxAmmo(w); size = weaponClipSize(w); if (size > 0) self setWeaponAmmoClip(w, size); }
}

jinx_admin_service()
{
    level endon("game_ended"); next_ammo = 0;
    for (;;)
    {
        wait 0.05;
        if (!isDefined(level.players)) continue;
        ammo_due = getTime() >= next_ammo; if (ammo_due) next_ammo = getTime() + 250;
        foreach (p in level.players)
        {
            if (!isDefined(p) || !isDefined(p.jinx_admin_ammo)) continue;
            if (!isAlive(p) || p.sessionstate != "playing") { p jinx_admin_clear(); continue; }
            if (p.jinx_admin_frozen && !p isInVehicle() && !p isRemoteControlling() && !isDefined(p.jinx_noclip_anchor))
            { p setOrigin(p.jinx_admin_origin); p setVelocity((0,0,0)); }
            if (ammo_due && p.jinx_admin_ammo && level.jinx_custom_mode == "") p jinx_admin_refill();
        }
    }
}

jinx_grant_menu(p, on)
{
    if (p isHost() || p is_bot()) return false;
    if (on == p.jinx_access) return false;
    p.jinx_access = on;
    if (on)
    {
        if (isAlive(p)) p jinx_guest_start();
        p iprintln("^1JINX ^2Menu access granted by host. ^7ADS + Melee to open.");
    }
    else
    {
        p jinx_close(); p jinx_admin_clear(); p jinx_guest_clear();
        p notify("jinx_life_stop");
        p iprintln("^1JINX ^7Menu access removed by host.");
    }
    return true;
}

jinx_admin_revoke_everyone()
{
    if (!isDefined(level.players)) return;
    foreach (p in level.players)
    {
        if (!isDefined(p) || !isDefined(p.jinx_access)) continue;
        p jinx_admin_clear();
        if (p isHost()) continue;
        p.jinx_access = false; p jinx_close(); p jinx_guest_clear(); p notify("jinx_life_stop");
    }
}

jinx_guest_start()
{
    self notify("jinx_life_stop");
    self thread jinx_input();
    self thread jinx_life_event("death");
    self thread jinx_life_event("joined_spectators");
}

jinx_guest_allowed(category, name)
{
    if (category == 6) return name != "Move During Countdown" && name != "Replay Welcome" && name != "Save Settings";
    if (category == 17 || (category >= 22 && category <= 29)) return true;
    if (category == 7) return name == "Custom Weapons" || name == "Camos";
    if (category == 19) return true;
    if (category == 0) return jinx_in_list(strTok("God Mode,Infinite Ammo,Unlimited Tactical,Unlimited Lethal,Third Person,Health Bar,Fast Reload,No Fall Damage,Player FOV", ","), name);
    return false;
}

jinx_guest_action(category, name, index)
{
    if (!(self jinx_has_menu()) || !isAlive(self)) return;
    if (!(self jinx_guest_allowed(category, name))) { self jinx_notice("Host-only action. Personal options are marked ON/OFF or USE."); return; }
    if (category == 6) { self jinx_setting_action(name); return; }
    if (level.jinx_custom_mode != "" && category != 0) { self jinx_notice("Loadout locked while a custom mode is active."); return; }
    if (category == 17) { self jinx_apply_camo(name); return; }
    if (category >= 22 && category <= 29) { self jinx_give_gun(level.jinx_weapon_groups[category][index]); return; }
    if (name == "Player FOV")
    { self.jinx_fov += 10; if (self.jinx_fov < 80) self.jinx_fov = 80; if (self.jinx_fov > 120) { self.jinx_fov = 0; self resetFov(); } else self setClientFov(self.jinx_fov); }
    else self jinx_toggle_effect(jinx_effect_key(name));
    self jinx_render(false);
}

jinx_guest_tick()
{
    if (self.jinx_open) self jinx_menu_movement();
    if (self.jinx_open && isDefined(self.jinx_notice_until) && getTime() >= self.jinx_notice_until)
    { self.jinx_notice_until = undefined; self jinx_render(false); }
    if (self jinx_enabled("health") && !self.jinx_open && getTime() >= self.jinx_health_time)
    { self.jinx_health_time = getTime() + 100; self jinx_health_update(); }
    if (getTime() < self.jinx_ammo_time) return;
    self.jinx_ammo_time = getTime() + 250;
    if (level.jinx_custom_mode != "") return;
    if (self jinx_enabled("ammo")) self jinx_admin_refill();
    if (self jinx_enabled("tactical") && isDefined(self.grenadetypesecondary)) self setWeaponAmmoClip(self.grenadetypesecondary, 2);
    if (self jinx_enabled("lethal") && isDefined(self.grenadetypeprimary)) self setWeaponAmmoClip(self.grenadetypeprimary, 2);
}

jinx_guest_clear()
{
    if (!isDefined(self.jinx_fx)) return;
    if (self jinx_enabled("god") && !(isDefined(self.jinx_admin_god) && self.jinx_admin_god)) self disableInvulnerability();
    if (self jinx_enabled("third")) self setClientThirdPerson(0);
    foreach (perk in strTok("specialty_fastreload,specialty_fallheight", ","))
        if (isDefined(self.jinx_perks_owned[perk]) && self.jinx_perks_owned[perk]) self unsetPerk(perk);
    self jinx_game_perks_clear();
    if (self.jinx_fov != 0) self resetFov(); self.jinx_fov = 0;
    self.jinx_fx = []; self.jinx_perks_owned = []; self jinx_health_destroy();
}

jinx_admin_spectate(p)
{
    self endon("disconnect"); level endon("game_ended");
    if (!jinx_admin_valid(p) || p == self || !isAlive(p) || (level.gametype != "tdm" && level.gametype != "dm"))
    { self jinx_notice("Spectate requires another living player in TDM or FFA."); return; }
    if (self isInVehicle() || self isRemoteControlling()) return;
    self jinx_close(); self jinx_stop_effects(); self notify("jinx_life_stop");
    self maps\mp\gametypes\_globallogic_spawn::spawnspectator(self.origin, self getPlayerAngles());
    self allowSpectateTeam("allies", true); self allowSpectateTeam("axis", true); self allowSpectateTeam("freelook", true);
    self.spectatorclient = p getEntityNumber();
    self iprintln("^1JINX ^7Spectating. Press melee to return to play.");
    wait 0.5;
    while (self meleeButtonPressed()) wait 0.05;
    while (jinx_admin_valid(p) && isAlive(p) && !self meleeButtonPressed() && self.sessionstate == "spectator") wait 0.05;
    if (self.sessionstate == "spectator") self [[level.spawnplayer]]();
}

// Explicit limits found during the v0.6.12 audit. No fake ON state.
jinx_unavailable_reason(name)
{
    switch (name)
    {
        case "No Recoil": return "Unavailable in this build: no verified T6 MP recoil-scale API. Grip and No Spread do not remove recoil; no aim-lock workaround is used.";
        case "Force Host": return "Not a host-transfer tool. Start and host Custom Games before loading JINX; GSC does not force ownership of another lobby.";
        case "XP Lobby": return "Unavailable: no verified persistent private-match XP implementation. This option does not change profile stats.";
        case "Clear Killfeed": return "Unavailable: no verified native API to clear existing obituary entries. Hiding the feed is not the same as clearing it.";
        case "Draw Snaplines": return "Unavailable: no validated client-side line projection for this HUD. No inaccurate screen-space substitute is enabled.";
        case "Draw Bones": return "Unavailable: skeleton drawing needs reliable bone projection and line rendering. Native torso ESP remains available.";
        case "Draw 2D/3D Boxes": return "Unavailable: full body geometry is not implemented with a verified T6 renderer. Red Boxes are torso markers, not 3D boxes.";
        case "Size Editor": return "Unavailable: setScale failed in your T6 MP build. Model hitboxes and visual scale are not changed.";
        case "Rainbow Model": return "Unavailable: no verified per-player material tint API. Rainbow Gun changes camos and remains separate.";
    }
    return "";
}

jinx_admission_check()
{
    self endon("disconnect"); level endon("game_ended");
    wait 0.5;
    if (level.jinx_access_closed || self isHost()) return;
    if (!(sessionModeIsPrivate() || sessionModeIsSystemLink() || !sessionModeIsOnlineGame())) return;
    denied = level.jinx_join_locked && !isDefined(self.jinx_join_allowed);
    if (self is_bot())
    {
        if (denied) { self botLeaveGame(); return; }
        if (isDefined(level.jinx_melee_old)) self setClientDvar("player_meleeRange", 768);
        return;
    }
    guid = self getGuid();
    banned = isDefined(guid) && guid != "" && isDefined(level.jinx_match_bans[guid]);
    if (banned || denied) { kick(self getEntityNumber()); return; }
    if (isDefined(level.jinx_melee_old)) self setClientDvar("player_meleeRange", 768);
}

jinx_long_melee()
{
    if (isDefined(level.jinx_melee_old)) { jinx_long_melee_restore(); self jinx_render(false); return; }
    original = getDvar("player_meleeRange");
    if (original == "") { self jinx_notice("player_meleeRange is not registered in this build; nothing changed."); return; }
    level.jinx_melee_old = original;
    setDvar("player_meleeRange", 768);
    foreach (p in level.players) if (isDefined(p)) p setClientDvar("player_meleeRange", 768);
    self jinx_render(false);
    self jinx_notice("Melee range: 768 units (4x previous JINX range), whole private match. Native collision/target rules remain. OFF restores the previous range.");
}

jinx_long_melee_restore()
{
    if (!isDefined(level.jinx_melee_old)) return;
    setDvar("player_meleeRange", level.jinx_melee_old);
    if (isDefined(level.players)) foreach (p in level.players)
        if (isDefined(p)) p setClientDvar("player_meleeRange", level.jinx_melee_old);
    level.jinx_melee_old = undefined;
}

jinx_damage_filter_install()
{
    if (!isDefined(level.callbackPlayerDamage)) return false;
    if (level.callbackPlayerDamage == ::jinx_filtered_damage) return true;
    // Do not form a cycle if another script replaced a callback already wrapped by us.
    if (isDefined(level.jinx_original_damage_callback)) return false;
    level.jinx_original_damage_callback = level.callbackPlayerDamage;
    level.callbackPlayerDamage = ::jinx_filtered_damage;
    return true;
}

jinx_damage_filter_release()
{
    if (level.jinx_hazard_filter || level.jinx_trickcam_on) return;
    if (!isDefined(level.jinx_original_damage_callback)) return;
    if (level.callbackPlayerDamage == ::jinx_filtered_damage)
    {
        level.callbackPlayerDamage = level.jinx_original_damage_callback;
        level.jinx_original_damage_callback = undefined;
    }
}

jinx_filtered_damage(inflictor, attacker, damage, flags, mod, weapon, point, dir, hitloc, offset, bone)
{
    if (level.jinx_hazard_filter && mod == "MOD_TRIGGER_HURT") return;
    self.jinx_trickcam_stamp = undefined;
    eligible = false;
    if (level.jinx_trickcam_on && isDefined(attacker) && isPlayer(attacker) && attacker isHost() && attacker != self)
    {
        if (isDefined(weapon) && jinx_practice_sniper(weapon) && !(attacker isOnGround())) eligible = true;
    }
    if (eligible) self.jinx_trickcam_stamp = getTime();
    self [[level.jinx_original_damage_callback]](inflictor, attacker, damage, flags, mod, weapon, point, dir, hitloc, offset, bone);
    if (!isAlive(self))
    {
        level.jinx_final_trick_stamp = undefined;
        if (eligible) level.jinx_final_trick_stamp = getTime();
    }
}

// Stock _killcam::calcKillCamTime, with an optional bounded native replay length.
// Preserve weapon-specific timing and the native respawn maximum.
jinx_calc_killcam_time(weapon, entitystarttime, predelay, respawn, maxtime)
{
    if (getDvar("scr_killcam_time") == "")
    {
        if (maps\mp\gametypes\_killcam::iskillcamentityweapon(weapon)) camtime = (getTime() - entitystarttime) / 1000 - predelay - 0.1;
        else if (!respawn) camtime = 5.0;
        else if (maps\mp\gametypes\_killcam::iskillcamgrenadeweapon(weapon)) camtime = 4.25;
        else camtime = 2.5;
    }
    else camtime = maps\mp\_utility::getdvarfloatdefault("scr_killcam_time", 2.5);
    if (isDefined(level.jinx_trickcam_on) && level.jinx_trickcam_on && isDefined(weapon) && jinx_practice_sniper(weapon))
    {
        recent = isDefined(self.jinx_trickcam_stamp) && getTime() - self.jinx_trickcam_stamp < 10000;
        if (!respawn && isDefined(level.jinx_final_trick_stamp) && getTime() - level.jinx_final_trick_stamp < 15000) recent = true;
        if (recent && camtime < 8) camtime = 8;
    }
    if (isDefined(maxtime)) { if (camtime > maxtime) camtime = maxtime; if (camtime < 0.05) camtime = 0.05; }
    return camtime;
}

jinx_prestige_display(name, index)
{
    p = self.jinx_admin_target;
    if (!jinx_admin_valid(p) || !isDefined(p.pers["rank"]) || !isDefined(p.pers["prestige"]))
    { self jinx_notice("Select a player with initialized rank data."); return; }
    if (name == "Restore Prestige")
    { p setRank(p.pers["rank"], p.pers["prestige"]); p.jinx_display_prestige = undefined; self jinx_notice("Original prestige display restored."); return; }
    if (!isDefined(level.maxprestige) || index < 0 || index > level.maxprestige)
    { self jinx_notice("Prestige index unavailable in the loaded rank table."); return; }
    p setRank(p.pers["rank"], index); p.jinx_display_prestige = index;
    self jinx_notice("Selected prestige: " + index + ". Match display only; saved profile unchanged.");
}

jinx_prestige_catalog()
{
    options = []; links = [];
    if (isDefined(level.maxprestige) && level.maxprestige >= 0)
        for (i = 0; i <= level.maxprestige; i++)
        { options[options.size] = "Prestige " + i; links[links.size] = -1; }
    options[options.size] = "Restore Prestige"; links[links.size] = -1;
    level.jinx_options[64] = options; level.jinx_links[64] = links;
}

jinx_sky_cycle()
{
    if (!isDefined(level.jinx_sky_old))
    {
        original = getDvar("r_sky_intensity_factor0");
        if (original == "") { self jinx_notice("Sky intensity dvar unavailable; no sky material was invented."); return; }
        level.jinx_sky_old = original; level.jinx_sky_base = maps\mp\_utility::getdvarfloatdefault("r_sky_intensity_factor0", 1);
        level.jinx_sky_step = 0; level.jinx_sky_owner = self;
    }
    level.jinx_sky_step++;
    if (level.jinx_sky_step > 3) { jinx_sky_restore(); self jinx_render(false); return; }
    multiplier = 0.2; if (level.jinx_sky_step == 2) multiplier = 0.6; if (level.jinx_sky_step == 3) multiplier = 1.5;
    setDvar("r_sky_intensity_factor0", level.jinx_sky_base * multiplier);
    self setClientDvar("r_sky_intensity_factor0", level.jinx_sky_base * multiplier);
    self jinx_render(false);
    self jinx_notice("Stock sky brightness x" + multiplier + ". Host view only; map sky material stays. Next after level 3 restores default.");
}

jinx_sky_restore()
{
    if (!isDefined(level.jinx_sky_old)) return;
    setDvar("r_sky_intensity_factor0", level.jinx_sky_old);
    if (isDefined(level.jinx_sky_owner)) level.jinx_sky_owner setClientDvar("r_sky_intensity_factor0", level.jinx_sky_old);
    level.jinx_sky_old = undefined; level.jinx_sky_step = undefined; level.jinx_sky_owner = undefined;
}






jinx_zombie_teams_valid()
{
    if (!isDefined(level.jinx_zombie_team) || level.gametype != "tdm") return false;
    bots = 0;
    foreach (p in level.players)
    {
        if (!isDefined(p) || !isDefined(p.pers["team"])) continue;
        if (p.pers["team"] == "spectator") continue;
        if (p is_bot()) { if (p.pers["team"] == level.jinx_zombie_team) return false; bots++; }
        else if (p.pers["team"] != level.jinx_zombie_team) return false;
    }
    return bots > 0;
}


// TDM-only live practice: prepare native teams instead of requiring manual setup.
jinx_prepare_zombies()
{
    self endon("disconnect"); level endon("game_ended");
    if (level.jinx_zombie_preparing) { self jinx_notice("Zombie teams are being prepared. Please wait."); return; }
    if (level.gametype != "tdm")
    { self jinx_notice("Zombie practice requires Team Deathmatch. Start a private TDM match first; this does not launch BO2 Zombies."); return; }
    if (!isDefined(self.team) || (self.team != "allies" && self.team != "axis"))
    { self jinx_notice("Join a playing team before starting Zombie practice."); return; }
    if (!isDefined(level.onplayerdamage) || !isDefined(level.onplayerkilledextraunthreadedcbs))
    { self jinx_notice("Wait for match initialization, then try again."); return; }
    if ((isDefined(level.jinx_bot_batch) && level.jinx_bot_batch) || (isDefined(level.jinx_bot_adding) && level.jinx_bot_adding))
    { self jinx_notice("Wait until the current bot operation finishes."); return; }
    bots = jinx_bot_entities();
    if (bots.size == 0 && level.jinx_join_locked)
    { self jinx_notice("No bots: turn Anti-Join OFF so Zombie practice can add one."); return; }
    jinx_custom_stop();
    level.jinx_zombie_preparing = true;
    token = level.jinx_zombie_token;
    level.jinx_zombie_team = self.team;
    if (bots.size == 0)
    {
        level.jinx_manual_bots = true;
        self jinx_add_practice_bot(false);
        if (token != level.jinx_zombie_token) return;
    }
    bots = jinx_bot_entities();
    if (bots.size == 0)
    { level.jinx_zombie_preparing = false; self jinx_notice("No bot could join. Check lobby slots and Anti-Join, then retry."); return; }
    enemy = "axis"; if (level.jinx_zombie_team == "axis") enemy = "allies";
    foreach (p in level.players)
    {
        if (token != level.jinx_zombie_token) return;
        if (!isDefined(p) || !isDefined(p.pers["team"]) || p.pers["team"] == "spectator") continue;
        team = level.jinx_zombie_team; if (p is_bot()) team = enemy;
        if (p.pers["team"] == team) continue;
        p.jinx_zombie_old_team = p.pers["team"];
        p.pers["team"] = team; p.team = team; p.sessionteam = team;
        p [[level.spawnplayer]]();
    }
    wait 0.5;
    if (token != level.jinx_zombie_token) return;
    level.jinx_zombie_preparing = false;
    if (!jinx_zombie_teams_valid())
    { jinx_zombie_restore_teams(); self jinx_notice("Team setup incomplete. Wait for bots to spawn, then retry."); return; }
    self jinx_live_start("Zombie Mode (Fake)", true);
}

jinx_zombie_restore_teams()
{
    if (!isDefined(level.players)) return;
    foreach (p in level.players)
    {
        if (!isDefined(p) || !isDefined(p.jinx_zombie_old_team)) continue;
        team = p.jinx_zombie_old_team; p.jinx_zombie_old_team = undefined;
        if (isDefined(level.gameended) && level.gameended) continue;
        if (!isDefined(p.pers["team"]) || p.pers["team"] == "spectator" || level.gametype != "tdm") continue;
        p.pers["team"] = team; p.team = team; p.sessionteam = team;
        p [[level.spawnplayer]]();
    }
}










/* v0.6.16 RELEASE CLEANUP
Unavailable entries are removed before navigation links are generated.
All 17 main categories, existing HUD/input and gameplay implementations retained.
Map Menu now offers only Reload Current Map and Current Map Info.
Light Sabers and Invert Controls remain removed.
No new gameplay functionality claimed. Compilation is not an in-game test.
*/
