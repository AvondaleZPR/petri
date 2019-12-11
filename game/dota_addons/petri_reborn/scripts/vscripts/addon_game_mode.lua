require('internal/util')
require('libraries/timers')

require('gamemode')
-- require("statcollection/init")

function Precache( context )
  -- SendToServerConsole( "dota_combine_models 0" )
  -- SendToConsole( "dota_combine_models 0" )
  
  -- ITEMS
  --PrecacheResource("model", "models/props_gameplay/red_box.vmdl", context)
  
  --PrecacheUnitByNameSync("npc_dota_hero_storm_spirit", context)
  --PrecacheUnitByNameSync("npc_petri_mini_actor", context)

  -- UNITS
 -- PrecacheResource("model", "models/creeps/neutral_creeps/n_creep_ghost_a/n_creep_ghost_a.vmdl", context)

  -- Custom skins
  -- local AttachmentDatabase = LoadKeyValues("scripts/attachments.txt")
  -- for k,model in pairs(AttachmentDatabase) do
  --   PrecacheResource("model", k, context)
  --   for pointName,pointTable in pairs(model) do
  --     for modelName,modelTable in pairs(pointTable) do
  --       if string.match(modelName, "vmdl") then
  --         PrecacheResource("model", modelName, context)
  --       end
  --     end
  --   end
  -- end

  -- local Particles = AttachmentDatabase['Particles']
  -- for k,model in pairs(Particles) do
  --   for effectName,values in pairs(model) do
  --     if string.match(effectName, "vpcf") then
  --       PrecacheResource("particle", effectName, context)
  --       print(effectName)
  --     end
  --   end
  -- end

 -- PrecacheUnitByNameSync("npc_petri_creep_bad_actor", context)
  --PrecacheUnitByNameSync("npc_petri_creep_dead_actor", context)
  --PrecacheUnitByNameSync("npc_petri_creep_draconoid", context)
  --PrecacheUnitByNameSync("npc_petri_creep_good_actor", context)
  --PrecacheUnitByNameSync("npc_petri_creep_humorist", context)
  --PrecacheUnitByNameSync("npc_petri_creep_kvn_actor", context)
  --PrecacheUnitByNameSync("npc_petri_creep_kivin", context)

  PrecacheUnitByNameSync("npc_petri_cop_trap", context)

  PrecacheUnitByNameSync("npc_petri_cop", context)
  --PrecacheUnitByNameSync("npc_petri_janitor", context)

  --PrecacheUnitByNameSync("npc_petri_svetlakov", context)
  --PrecacheUnitByNameSync("npc_petri_maslyakov", context)
  --PrecacheUnitByNameSync("npc_petri_gusman", context)

  PrecacheUnitByNameSync("npc_dota_hero_rattletrap", context)
  PrecacheUnitByNameSync("npc_dota_hero_brewmaster", context)
  PrecacheUnitByNameSync("npc_dota_hero_death_prophet", context)

  -- BUILDINGS
  -- idol
  --PrecacheUnitByNameSync("npc_petri_idol", context)

  -- exit
  --PrecacheUnitByNameSync("npc_petri_exit", context)

  -- towers
  --PrecacheResource("model", "models/props_structures/tower_good.vmdl", context)
  --PrecacheResource("model", "models/items/invoker/forge_spirit/arsenal_magus_forged_spirit/arsenal_magus_forged_spirit.vmdl", context)
  --PrecacheResource("model", "models/heroes/ancient_apparition/ancient_apparition.vmdl", context)
  --PrecacheResource("model", "models/heroes/undying/undying_tower.vmdl", context)

  --PrecacheResource("model", "models/items/undying/idol_of_ruination/idol_tower.vmdl", context)
  --PrecacheResource("model", "models/items/undying/idol_of_ruination/idol_tower_gold.vmdl", context)

  PrecacheUnitByNameSync("npc_petri_tower_of_evil", context)
  --PrecacheUnitByNameSync("npc_petri_exploration_tree", context)
  
  -- wall
  --PrecacheResource("model", "models/items/rattletrap/warmachine_cog_dc/warmachine_cog_dc.vmdl", context)
  --PrecacheResource("model", "models/props_debris/merchant_debris_chest002.vmdl", context)
  --PrecacheResource("model", "models/props_rock/riveredge_rock008a.vmdl", context)
  --PrecacheResource("model", "models/heroes/oracle/crystal_ball.vmdl", context)
  --PrecacheResource("model", "models/props_items/bloodstone.vmdl", context)
  --PrecacheResource("model", "models/props_magic/bad_crystals002.vmdl", context)
  PrecacheResource("model", "models/heroes/undying/undying_flesh_golem.vmdl", context)
  PrecacheResource("model", "models/creeps/neutral_creeps/n_creep_golem_a/neutral_creep_golem_a.vmdl", context)
  PrecacheResource("model", "models/items/terrorblade/dotapit_s3_fallen_light_metamorphosis/dotapit_s3_fallen_light_metamorphosis.vmdl", context)
  PrecacheResource("model", "models/items/warlock/golem/obsidian_golem/obsidian_golem.vmdl", context)
  PrecacheResource("model", "models/items/rattletrap/forge_warrior_rocket_cannon/forge_warrior_rocket_cannon.vmdl", context)
  PrecacheResource("model", "models/creeps/roshan/aegis.vmdl", context)
  PrecacheResource("model", "models/creeps/roshan/roshan.vmdl", context)
  PrecacheResource("model", "models/earthwall/earthwall.vmdl", context)
  PrecacheResource("model", "models/heroes/brewmaster/brewmaster_earthspirit.vmdl", context)

  PrecacheResource("model", "models/items/brewmaster/reddragon_arms/reddragon_arms.vmdl", context)
  PrecacheResource("model", "models/items/brewmaster/reddragon_back/reddragon_back.vmdl", context)
  PrecacheResource("model", "models/items/brewmaster/reddragon_offhand/reddragon_offhand.vmdl", context)
  PrecacheResource("model", "models/items/brewmaster/reddragon_shoulder/reddragon_shoulder.vmdl", context)
  PrecacheResource("model", "models/items/brewmaster/reddragon_weapon/reddragon_weapon.vmdl", context)
  PrecacheResource("model", "models/items/death_prophet/fatal_blossom_nails/fatal_blossom_nails.vmdl", context)
  PrecacheResource("model", "models/items/death_prophet/burial_robes_armor/burial_robes_armor.vmdl", context)
  PrecacheResource("model", "models/items/death_prophet/burial_robes_belt/burial_robes_belt.vmdl", context)
  PrecacheResource("model", "models/items/death_prophet/burial_robes_legs/burial_robes_legs.vmdl", context)
  PrecacheResource("model", "models/items/death_prophet/burial_robes_head/burial_robes_head.vmdl", context)
  PrecacheResource("model", "models/items/death_prophet/burial_robes_vortex/burial_robes_vortex.vmdl", context)


  PrecacheResource("model", "models/items/rattletrap/forge_warrior_helm/forge_warrior_helm.vmdl", context)
  PrecacheResource("model", "models/items/rattletrap/forge_warrior_claw/forge_warrior_claw.vmdl", context)
  PrecacheResource("model", "models/items/rattletrap/forge_warrior_rocket_cannon/forge_warrior_rocket_cannon.vmdl", context)
  PrecacheResource("model", "models/items/rattletrap/forge_warrior_steam_exoskeleton/forge_warrior_steam_exoskeleton.vmdl", context)
  PrecacheResource("model", "models/items/storm_spirit/raikage_ares_armor/raikage_ares_armor.vmdl", context)
  PrecacheResource("model", "models/items/storm_spirit/raikage_ares_arms/raikage_ares_arms.vmdl", context)
  PrecacheResource("model", "models/items/storm_spirit/raikage_ares_head/raikage_ares_head.vmdl", context)
  
  -- for k,v in pairs(LoadKeyValues("scripts/kv/custom_skins.kv")) do
  --   for _,m in pairs(v) do
  --     for __,g in pairs(m) do
  --       if string.match(__, "vmdl") then
  --         print(__)
  --         PrecacheResource("model", __, context)
  --       end
  --     end
  --   end
  -- end

  -- for k,v in pairs(LoadKeyValues("scripts/kv/custom_buildings.kv")) do
  --   for _,m in pairs(v) do
  --     if type(m) == "table" then
  --       for __,g in pairs(m) do
  --         if g == "model" then
  --           print(__)
  --           PrecacheResource("model", __, context)
  --         end
  --       end
  --     else
  --       PrecacheResource("model", m, context)
  --     end
  --   end
  -- end
  
  -- sawmill
  --PrecacheResource("model", "models/props_structures/bad_barracks001_ranged.vmdl", context)
  --PrecacheResource("model", "models/props_structures/good_barracks_ranged002_lvl2.vmdl", context)
  --PrecacheResource("model", "models/props_structures/good_ancient001.vmdl", context)

  --PrecacheResource("model", "models/props_structures/radiant_tower001.vmdl", context)

  --PrecacheResource("model", "models/props_structures/tent_dk_small.vmdl", context)
  --PrecacheResource("model", "models/props_structures/tent_dk_med.vmdl", context)
  --PrecacheResource("model", "models/props_structures/tent_dk_large.vmdl", context)

  PrecacheUnitByNameSync("npc_petri_sawmill", context)
  PrecacheUnitByNameSync("npc_petri_tower_basic", context)
  PrecacheUnitByNameSync("npc_petri_exploration_tower", context)
  PrecacheUnitByNameSync("npc_petri_gold_bag", context)
  PrecacheUnitByNameSync("npc_petri_gold_bag2", context)
  PrecacheUnitByNameSync("npc_petri_gold_bag3", context)
  
  -- PARTICLES
  PrecacheResource("particle", "particles/econ/items/wisp/wisp_ambient_ti7.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_tinker/tinker_laser.vpcf", context)
  
  PrecacheResource("particle", "particles/buildinghelper/ghost_model.vpcf", context)
  PrecacheResource("particle", "particles/buildinghelper/square_sprite.vpcf", context)
  
  PrecacheResource("particle", "particles/econ/events/nexon_hero_compendium_2014/teleport_end_ground_flash_nexon_hero_cp_2014.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_mirana/mirana_base_attack.vpcf", context)

  PrecacheResource("particle", "particles/items_fx/dust_of_appearance.vpcf", context)

  PrecacheResource("particle", "particles/units/heroes/hero_jakiro/jakiro_base_attack_fire.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_jakiro/jakiro_liquid_fire_ready.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_jakiro/jakiro_liquid_fire_explosion.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_jakiro/jakiro_liquid_fire_debuff.vpcf", context)

  PrecacheResource("particle", "particles/units/heroes/hero_rattletrap/rattletrap_rocket_flare_explosion_flash_c.vpcf", context)

  PrecacheResource("particle", "particles/generic_gameplay/dropped_item.vpcf", context)

  PrecacheResource("particle", "particles/units/heroes/hero_invoker/invoker_tornado.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_invoker/invoker_tornado_child.vpcf", context)
  PrecacheResource("particle", "particles/items_fx/cyclone.vpcf", context)

  PrecacheResource("particle", "particles/items_fx/blademail.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_viper/viper_viper_strike_debuff.vpcf", context)

  PrecacheResource("particle", "particles/units/heroes/hero_meepo/meepo_earthbind.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_meepo/meepo_earthbind_projectile_fx.vpcf", context)

  PrecacheResource("particle", "particles/items2_fx/shadow_amulet_activate_runes.vpcf", context)

  PrecacheResource("particle", "particles/units/heroes/hero_invoker/invoker_base_attack.vpcf", context)

  PrecacheResource("particle", "particles/econ/courier/courier_flopjaw_gold/flopjaw_death_coins_gold.vpcf", context)

  PrecacheResource("particle", "particles/portal_level_msg.vpcf", context)

  PrecacheResource("particle", "particles/units/heroes/hero_necrolyte/necrolyte_pulse_enemy.vpcf", context)
  
  -- SOUNDS
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_naga_siren.vsndevts", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_earth_spirit.vsndevts", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_earthshaker.vsndevts", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_custom.vsndevts", context)


  PrecacheUnitByNameSync("npc_petri_peasant", context)
  PrecacheUnitByNameSync("npc_petri_super_peasant", context)
  PrecacheUnitByNameSync("npc_petri_mega_peasant", context)

  PrecacheUnitByNameSync("npc_petri_trap", context)

  PrecacheUnitByNameSync("npc_petri_earth_wall", context)

  GameRules.pc = context
  GameMode().pc = context
end

function Activate()
  GameRules.GameMode = GameMode()
  GameRules.GameMode:InitGameMode()
end