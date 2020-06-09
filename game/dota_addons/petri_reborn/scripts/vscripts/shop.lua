if not _G.Shop then
  Shop = class({})
end

function Shop:Init()
  CUSTOM_SHOP_STOCK = {}

  chicks = {}

  for k,v in pairs(GameMode.ItemKVs) do
    local itemName = k

    if itemName == "item_courier" then
      v.ItemStockInitial = 5
      v.ItemStockTime = 60 * 99
    end

    if v.ItemStockTime and v.ItemStockTime > 0 then
      CUSTOM_SHOP_STOCK[itemName] = {
        stockTime = v.ItemStockTime,
        stockInitial = v.ItemStockInitial
      }

      CustomNetTables:SetTableValue("shop", itemName, {count = CUSTOM_SHOP_STOCK[itemName].stockInitial, time = CUSTOM_SHOP_STOCK[itemName].stockTime})

      Timers:CreateTimer(0.0, function (  )
        local oldValue = CustomNetTables:GetTableValue("shop", itemName)["time"] - 1
        local oldStock = CustomNetTables:GetTableValue("shop", itemName)["count"] 
        if oldValue <= 0 then
          CustomNetTables:SetTableValue("shop", itemName, {count = oldStock + 500, time = CUSTOM_SHOP_STOCK[itemName].stockTime})
        else
          CustomNetTables:SetTableValue("shop", itemName, {count = oldStock, time = oldValue})
        end
        return 1.0
      end)
    else
      CUSTOM_SHOP_STOCK[itemName] = -1
    end
  end

end

function SpendStock(item)
  if CUSTOM_SHOP_STOCK[item] == -1 then return 1 end

  local oldValue = CustomNetTables:GetTableValue("shop", item)["time"]
  local oldStock = CustomNetTables:GetTableValue("shop", item)["count"] 
  CustomNetTables:SetTableValue("shop", item, {count = oldStock - 1, time = oldValue})
end

function CheckStock( item, hero )
  if CUSTOM_SHOP_STOCK[item] == -1 then return 1 end

  local stock = CustomNetTables:GetTableValue("shop", item)["count"]

  if hero and stock == 0 then
    Notifications:Bottom(hero:GetPlayerOwner(), {text="#DOTA_Shop_Item_Error_Out_of_Stock", duration=1, style={color="red", ["font-size"]="50px", border="0px solid blue"}})
  end

  return stock > 0
end

function FindItemSlot( unit, item )
  for i=0,11 do
    local it = unit:GetItemInSlot(i)
    
    if it then
      if it == item then
        return i 
      end
    end
  end
end

function MoveToStash( hero, slot )
  local target = hero:GetItemInSlot(slot)
  if target then
    for i=6+3,11+3 do
      local it = hero:GetItemInSlot(i)

      if not it then
        hero:SwapItems(slot,i)
        return i
      end
    end

    hero:DropItemAtPositionImmediate(target,hero.spawnPosition)
  end
end

function LockInventory(hero)
  for i=0,11 do
    local it = hero:GetItemInSlot(i)
    if it then
      ExecuteOrderFromTable({ UnitIndex = hero:entindex(), 
          OrderType = DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK,
          AbilityIndex = it:entindex(), 
          TargetIndex = 1,
          Queue = 0})
    end
  end
end

function UnlockInventory(hero)
  for i=0,11 do
    local it = hero:GetItemInSlot(i)
    if it then
      ExecuteOrderFromTable({ UnitIndex = hero:entindex(), 
          OrderType = DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK,
          AbilityIndex = it:entindex(), 
          TargetIndex = 0,
          Queue = 0})
    end
  end
end

function AddItem( owner, unit, item_name )
  local item_entity = CreateItem(item_name,owner,owner)
  local item = unit:AddItemByName(item_name)
  if item then
    item:SetPurchaser(owner)
    item.purchaseTime = GameMode.PETRI_TRUE_TIME

    return item
  end

end

function GameMode:BuyItem(keys)
  local pID = keys.PlayerID
  local item = keys.itemname
  local hero = EntIndexToHScript(tonumber(keys.hero))
  local buyer = EntIndexToHScript(tonumber(keys.buyer))

  hero.tempShopInstance = {}

  local tmp = {}

  local toBuy, toDelete = GetItemList( hero, item, tmp )

  local cost = 0

  for k,v in pairs(toBuy) do
    if v and v ~= "" then
      cost = cost + GameMode.ItemKVs[v].ItemCost
    end
  end

  chicks = Entities:FindAllByName("npc_dota_courier") or {}

  -- PrintTable(toBuy)
  -- PrintTable(toDelete)

  -- for i=0,5 do
  --   local it = hero:GetItemInSlot(i)
  --   if it and it:GetName() == "item_petri_locker" then
  --     hero:RemoveItem(it)
  --   end
  -- end
  
  local function confirm(target, deleteItems)
    if CheckStock( item, hero ) and hero.itemsPurchased < GameRules.MaxItemsToBuy then
      if cost <= GetCustomGold( hero:GetPlayerID() ) then
        SpendCustomGold( pID, cost )
        if target == "stash" then
          LockInventory(hero)
          local item_entity = AddItem( hero, hero, item )
          if item_entity then
            if GameMode.ItemKVs[item] and tonumber(GameMode.ItemKVs[item].ItemInitialCharges) then
            else
              local slot = FindItemSlot( hero, item_entity )
              local target_slot = MoveToStash( hero, slot )
            end
          end
          UnlockInventory(hero)
        elseif IsValidEntity(target) then
          AddItem( hero, target, item )
        end

        hero:EmitSound("General.Buy")
        SpendStock(item)
		
		hero.itemsPurchased = hero.itemsPurchased + 1
		print("itemcount "..hero.itemsPurchased)
		
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
            GameMode:BusPayOut(1)
		elseif hero:GetTeam() == DOTA_TEAM_BADGUYS and cost >= 5 then
		    GameMode:BusPayOut(4)
		end
		
		if item == "item_petri_cola" then
		    print("COLA BUS")
		    GameMode:BusPayOut(2)
		end
		
        return true
      else
        Notifications:Bottom(hero:GetPlayerOwner(), {text="#dota_hud_error_not_enough_gold", duration=1, style={color="red", ["font-size"]="50px", border="0px solid blue"}})
        return false
      end
    end
  end

  local function confirmParts(target)
    local newCost = 0
    for k,v in pairs(toBuy) do
      if v ~= "" and GameMode.ItemKVs[v] and CheckStock( v, hero ) then
        newCost = newCost + GameMode.ItemKVs[v].ItemCost
      end
    end

    if newCost <= GetCustomGold( hero:GetPlayerID() ) then
      for k,v in pairs(toBuy) do
        if v ~= "" and CheckStock( v, hero ) then
          local partCost = GameMode.ItemKVs[v].ItemCost
          SpendCustomGold( pID, partCost )

          if target == "stash" then
            LockInventory(hero)
            local item_entity = AddItem( hero, hero, v )
            local slot = FindItemSlot( hero, item_entity )
            if slot then
              MoveToStash( hero, slot )
            end
            UnlockInventory(hero)
          elseif IsValidEntity(target) and target.SwapItems then
            AddItem( hero, target, v )
          elseif target == "inventory" then
            AddItem( hero, hero, v )
          end
        end
      end
    else
      Notifications:Bottom(hero:GetPlayerOwner(), {text="#dota_hud_error_not_enough_gold", duration=1, style={color="red", ["font-size"]="50px", border="0px solid blue"}})
      return false
    end
  end

  if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS and GameMode.ItemKVs[item].SideShop then
    local allents = Entities:FindAllByClassname("trigger_shop")
    local touch = false
    for k,v in pairs(allents) do
      if v:GetName() == "team_2_idol" then
        if (v:GetAbsOrigin() - hero:GetAbsOrigin()):Length2D() < 390 then
          touch = true
          break
        end
      end
    end
    if not touch then
      return touch
    else
      local allItems = false
      for k,v in pairs(toDelete) do
        if CheckRange(hero, v, 0, 11) == false then
          allItems = false
          break
        else
          allItems = true
        end
      end

      local reallyAll = true
      for k,v in pairs(toBuy) do
        if v ~= "" then
          reallyAll = false
          break
        end
      end

      if reallyAll then
        cost = GameMode.ItemKVs[item].ItemCost
        confirm(hero)
      elseif allItems or #toDelete == 0 then
        if confirm(hero) then
          RemoveItems( hero, hero, toDelete )
        end
      else
        confirmParts(hero)
      end
    end
  else
    if CheckShopRange( buyer ) then
      if IsValidEntity(buyer) and buyer:GetUnitName() == "npc_dota_courier" then
        local allItems = false
        for k,v in pairs(toDelete) do
          if CheckStash(hero, v) == false then
            allItems = false
            break
          else
            allItems = true
          end
        end

        local reallyAll = true
        for k,v in pairs(toBuy) do
          if v ~= "" then
            reallyAll = false
            break
          end
        end

        if reallyAll then
          cost = GameMode.ItemKVs[item].ItemCost
          confirm(buyer)
        elseif allItems or #toDelete == 0 then
          if confirm(buyer) then
            RemoveItems( hero, buyer, toDelete )
          end
        else
          confirmParts(buyer)
        end
      else
        local allItems = false
        for k,v in pairs(toDelete) do
          if CheckRange(hero, v, 0, 11) == false then
            allItems = false
            break
          else
            allItems = true
          end
        end

        local reallyAll = true
        for k,v in pairs(toBuy) do
          if v ~= "" then
            reallyAll = false
            break
          end
        end

        if reallyAll then
          cost = GameMode.ItemKVs[item].ItemCost
          confirm(hero)
        elseif allItems or #toDelete == 0 then
          if confirm(hero) then
            RemoveItems( hero, hero, toDelete )
          end
        else
          confirmParts(hero)
        end
      end
    else
      local allItems = false
      for k,v in pairs(toDelete) do
        if CheckStash(hero, v) == false then
          allItems = false
          break
        else
          allItems = true
        end
      end

      local reallyAll = true
      for k,v in pairs(toBuy) do
        if v ~= "" then
          reallyAll = false
          break
        end
      end

      if reallyAll then
        cost = GameMode.ItemKVs[item].ItemCost
        confirm("stash")
      elseif allItems or #toDelete == 0 then
        if confirm("stash") then
          RemoveItems( hero, "stash", toDelete )
        end
      else
        confirmParts("stash")
      end
    end
  end

  hero.tempShopInstance = nil

  if hero:GetTeamNumber() == DOTA_TEAM_BADGUYS then
    --fixcourier(hero, item)
  end
end

function fixcourier(hero, itemname)
local courier = Entities:FindByName(nil,"npc_dota_courier")
   if courier ~= nil then
    Timers:CreateTimer(0.1, function()
        courier:CastAbilityNoTarget(courier:FindAbilityByName("courier_take_stash_items"), hero:GetPlayerID())
        return nil
    end)
   else
        print(itemname)
        local item = hero:GetItemInSlot(9)
        hero:EjectItemFromStash(item)
   end
end

function RemoveItems( hero, c, t )
  local function r( unit, t, minSlot, maxSlot )
    for k,v in pairs(t) do
      for i=minSlot,maxSlot do
        local it = unit:GetItemInSlot(i)
        if it and it:GetName() == v then
          unit:RemoveItem(it)
          break
        end
      end
    end
  end

  if c == "stash" then
    local stashMin = 6+3
    local stashMax = 11+3

    r( hero, t, stashMin, stashMax )
    return
  elseif IsValidEntity(c) and c.SwapItems then
    if c:IsRealHero() then
      r( c, t, 0, 11 )
    else
      for k,v in pairs(chicks) do
        if IsValidEntity(v) and v:GetTeamNumber() == hero:GetTeamNumber() then
          r( v, t, 0, 5 )
          return
        end
      end
    end
  elseif c == "inventory" then
    r( hero, t, 0, 5 )
    return
  end
end

function GetItemList( hero, item, t, t2 )
  if CheckForItem(hero, item) and not t then
    hero.tempShopInstance[item] = hero.tempShopInstance[item] + 1
    return {}, { [1] = item }
  end
  if string.match(item, "recipe_") then return { [1] = item }, {} end
  if not GameMode.ItemKVs[string.gsub(item, "item_", "item_recipe_")] then return { [1] = item }, {} end
  local recipe = Split(GameMode.ItemKVs[string.gsub(item, "item_", "item_recipe_")].ItemRequirements["01"], ";")

  local recipeName = string.gsub(item, "item_", "item_recipe_")

  t = t or {}
  t2 = t2 or {}

  
  table.insert(recipe, recipeName)

  for k,v in pairs(recipe) do
    local check, delete = GetItemList( hero, v )
    for k2,v2 in pairs(check) do
      table.insert(t, v2)
    end
    for k2,v2 in pairs(delete) do
      table.insert(t2, v2)
    end
  end

  return t, t2
end

function CheckRange(hero, item, min, max)
  for i=min,max do
    local it = hero:GetItemInSlot(i)
    if it and it:GetName() == item then
      return i
    end
  end

  return false
end

function CheckStash(hero, item)
  local stashMin = 6+3
  local stashMax = 11+3

  for i=stashMin,stashMax do
    local it = hero:GetItemInSlot(i)
    if it and it:GetName() == item then
      return i
    end
  end

  return false
end

function CheckShopRange( hero )
  local trigger = Entities:FindByName(nil,"PetrosyanShopTrigger")

  if trigger:IsTouching(hero) then
    return true
  end

  return false
end

function CheckShopRangeAll( hero )
  local trigger = Entities:FindByName(nil,"PetrosyanShopTrigger")

  if trigger:IsTouching(hero) then
    return true
  end

  for k,v in pairs(chicks) do
    if trigger:IsTouching(v) then
      return true
    end
  end

  return false
end

function CheckForItem(hero, item)
  hero.tempShopInstance[item] = hero.tempShopInstance[item] or 0 
  
  local current = 0

  for i=0,11 do
    local it = hero:GetItemInSlot(i)
    if it and it:GetName() == item then
      current = current + 1
      if current > hero.tempShopInstance[item] then
        return hero
      end
    end
  end

  for k,v in pairs(chicks) do
    if IsValidEntity(v) and v:GetTeamNumber() == hero:GetTeamNumber() then
      for i=0,5 do
        local it = v:GetItemInSlot(i)
        if it and it:GetName() == item then
          current = current + 1
          if current > hero.tempShopInstance[item] then
            return v
          end
        end
      end
    end
  end

  return false
end