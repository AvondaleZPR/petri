var selectedItem;
var selectedItemName = "";

var shopItems = {};

var rewards = {};

function ToggleShop() {
	$("#ShopWindow").ToggleClass("Hide");
	$("#ShopGuide").ToggleClass("Hide");
}

function OpenTab(arg) {
	$("#BasicShopTab").RemoveClass("ShopTabHighlight");
	$("#AdvancedShopTab").RemoveClass("ShopTabHighlight");
	$("#SecretShopTab").RemoveClass("ShopTabHighlight");

	$("#" + arg + "Tab").AddClass("ShopTabHighlight");

	$("#BasicShopContents").visible = false;
	$("#AdvancedShopContents").visible = false;
	$("#SideShopContents").visible = false;
	$("#SecretShopContents").visible = false;

	$("#" + arg + "Contents").visible = true;
}

function Clean(panel) {
	var children = panel.Children();
	for (var key in children) {
		children[key].RemoveAndDeleteChildren();
		children[key].DeleteAsync(0.0);
	}
}

function SetupItems(team, hero) {
	if (!GameUI.CustomUIConfig().shopsKVs || !GameUI.CustomUIConfig().itemBuilds) {
		$.Schedule(0.1, SetupItems)
		return;
	}

	Clean($("#ShopGuide"));
	Clean($("#ShopQuickbuy"));

	$("#Petri").visible = false;
	$("#KVN").visible = false;

	var team = team || Entities.GetTeamNumber(Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() ));
	var heroName = hero || Entities.GetUnitName(Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() ));

	if (team != DOTATeam_t.DOTA_TEAM_BADGUYS){
		$("#CourierPanel").SetHasClass("Hide", true);
	}	
	
	for (var key in GameUI.CustomUIConfig().shopsKVs) {
		var r = $("#ShopWindow").FindChildTraverse(key);
		if (r) {
			Clean(r);
			for (var key2 in GameUI.CustomUIConfig().shopsKVs[key]) {
				(function () {
					var itemname = GameUI.CustomUIConfig().shopsKVs[key][key2];

					shopItems[itemname] = CreateItem(r, itemname);
				})();
			}
			if (r.Children().length == 0) {
				r.visible = false;
			}
		}
	}

	if (team == 2) {
		$("#KVN").visible = true;
		OpenTab("SideShop");
		$("#SideShopTab").style.width = "100%;";
	} else {
		$("#Petri").visible = true;
		OpenTab("BasicShop");
	}

	if (GameUI.CustomUIConfig().itemBuilds[heroName]) {
		for (var t in GameUI.CustomUIConfig().itemBuilds[heroName].Items) {
			var items = GameUI.CustomUIConfig().itemBuilds[heroName].Items[t];

			var guideBlock = $.CreatePanel("Panel", $("#ShopGuide"), t.replace("#", ""));
			guideBlock.BLoadLayoutSnippet("GuideBlock");

			guideBlock.FindChildTraverse("ShopGuideBlockLabel").text = $.Localize(t);

			var x = 0;
			var y = 0;
			var i = 1;
			for (var item in items) {
				var itemPanel = CreateItem(guideBlock.FindChildTraverse("ShopGuideBlockItems"), items[i]);
				itemPanel.style.position = (x * 60) + "px " + (y * 44) + "px " + "0px;";
				x++;
				if ((x ) % 3 == 0) {
					x = 0;
					y++;
				}

				i++;
			}
		}
		$("#ShopGuide").visible = true;
	} else {
		$("#ShopGuide").visible = false;
	}
}

function OpenQuickbuy(itemname) {
	for (var key in $("#ShopQuickbuy").Children()) {
		var child = $("#ShopQuickbuy").Children()[key];
		if (child == selectedItem) {
			selectedItem = undefined;
		}
		child.RemoveAndDeleteChildren();
		child.DeleteAsync(0.0);
	}

	var recipeName = itemname.replace("item_", "item_recipe_");
	var recipe = GameUI.CustomUIConfig().itemsKVs[recipeName];
	if (recipe) {
		recipe = recipe.ItemRequirements["01"];
		recipe = recipe.split(";");

		for (var key in recipe) {
			var recipePart = recipe[key];
			CreateItem($("#ShopQuickbuy"), recipePart)
		}

		CreateItem($("#ShopQuickbuy"), recipeName)
	} else {
		CreateItem($("#ShopQuickbuy"), itemname)
	}
}

function OpenRecipe(itemname) {
	selectedItemName = itemname
	
	for (var key in $("#ShopRecipeContainer").Children()) {
		var child = $("#ShopRecipeContainer").Children()[key];
		if (child == selectedItem) {
			selectedItem = undefined;
		}
		child.RemoveAndDeleteChildren();
		child.DeleteAsync(0.0);
	}

	var recipeName = itemname.replace("item_", "item_recipe_");
	var recipe = GameUI.CustomUIConfig().itemsKVs[recipeName];
	if (recipe) {
		recipe = recipe.ItemRequirements["01"];
		recipe = recipe.split(";");

		$("#ShopRecipeLabel").visible = false;

		for (var key in recipe) {
			var recipePart = recipe[key];
			CreateItem($("#ShopRecipeContainer"), recipePart)
		}

		CreateItem($("#ShopRecipeContainer"), recipeName)
	}
	else {
		$("#ShopRecipeLabel").visible = false;
		CreateItem($("#ShopRecipeContainer"), itemname)
		// $("#ShopRecipeLabel").visible = true;
	}
}

function CreateItem(r, itemname) {
	if (itemname == "") {
		return;
	}
	var item = $.CreatePanel("Panel", r, itemname);
	item.BLoadLayoutSnippet("Item");

	item.FindChildTraverse("ItemImage").itemname = itemname;
	item.itemname = itemname;

	item.SetPanelEvent('oncontextmenu', (function () {
		GameEvents.SendCustomGameEventToServer("petri_buy_item", { itemname : itemname, hero : Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() ), buyer : Players.GetLocalPlayerPortraitUnit() });
	}));
	item.SetPanelEvent('onactivate', (function () {
		if (selectedItem) {
			selectedItem.RemoveClass("Selected");
		}
		selectedItem = item;
		item.AddClass("Selected");
		OpenRecipe(itemname)
		OpenQuickbuy(itemname)
	}));

	return item;
}

var convertTime = (function (d) {
	d = Number(d);
	var h = Math.floor(d / 3600);
	var m = Math.floor(d % 3600 / 60);
	var s = Math.floor(d % 3600 % 60);
	return ((h > 0 ? h + ":" + (m < 10 ? "0" : "") : "") + m + ":" + (s < 10 ? "0" : "") + s); 
});

function ShopStock(table_name, key, data) {
	if (shopItems[key]) {
		if (CustomNetTables.GetTableValue(table_name, key).count == 0) {
			shopItems[key].AddClass("OutOfStock");
			shopItems[key].FindChildTraverse("StockLabel").visible = true;
		} else {
			shopItems[key].RemoveClass("OutOfStock");
			shopItems[key].FindChildTraverse("StockLabel").visible = false;
		}
		shopItems[key].FindChildTraverse("StockLabel").text = convertTime(CustomNetTables.GetTableValue(table_name, key).time);
	}
}

function ChangeTeam(args) {		
	for (var key in $("#ShopRecipeContainer").Children()) {
		var child = $("#ShopRecipeContainer").Children()[key];
		if (child == selectedItem) {
			selectedItem = undefined;
		}
		child.RemoveAndDeleteChildren();
		child.DeleteAsync(0.0);
	}
	
	for (var key in $("#ShopQuickbuy").Children()) {
		var child = $("#ShopQuickbuy").Children()[key];
		if (child == selectedItem) {
			selectedItem = undefined;
		}
		child.RemoveAndDeleteChildren();
		child.DeleteAsync(0.0);
	}
	SetupItems(args.team, args.hero);
}

function ReApplySkin() {
	GameEvents.SendCustomGameEventToServer("petri_reapplyskin", {})
}

//function OnInventoryChanged(){
//	$.Msg('invchng')
//}

function Spectate()
{
	GameEvents.SendCustomGameEventToServer("petri_host_spectate", {"pid" : Players.GetLocalPlayer()});
	$("#SpectateBtn").SetHasClass("Hide", true);
}

//function HideSpectateBtn()
//{
	//$("#SpectateBtn").SetHasClass("Hide", true);
//}

function HideChBtn()
{
	$.Msg("HideChBtn")
	$("#ChBtn").SetHasClass("Hide", true);
}

function ShowChPanel()
{
	$("#ChPanel").ToggleClass("Hide");
}

function ChDesc(event_data)
{
	$.Msg(event_data);
	$("#CH"+event_data.chid).text = $.Localize(event_data.text);
	$("#CHlvl").text = event_data.lvl;
	setupRewards(0);
}

function ChPr(event_data)
{
	$.Msg(event_data);
	$("#CH"+event_data.chid+"Pr").text = event_data.cur + "/" + event_data.tar;
}

function print(event_data)
{
	$.Msg("DEBUG: " + event_data.text + event_data.numb)
}

function setupRewards(start)
{
	for(; start < start+6; start++)
	{
		$("#rew"+(start+1)).SetHasClass("REWLVL"+rewards[start], true)
		if($("#CHlvl").text < rewards[start]){
		    $("#rl"+(start+1)).text = rewards[start];
		    $("#rew"+(start+1)).SetHasClass("locked", true)
		}
	}
}

function OnSetCameraYaw( event_data )
{
	$.Msg("setcamerayaw", event_data.yaw);
	GameUI.SetCameraYaw(event_data.yaw)
	
	$.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("minimap").SetHasClass("rotate" + event_data.yaw, true)
}

function CourierSelect()
{
	GameEvents.SendCustomGameEventToServer( "courier_select", { "id" : Players.GetLocalPlayer()} );
}

function CourierDeliver()
{
	GameEvents.SendCustomGameEventToServer( "courier_deliver", { "id" : Players.GetLocalPlayer()} );
}

function SelectUnit(event_data)
{
	GameUI.SelectUnit(event_data.unit, false)
}

(function () {
	GameEvents.Subscribe("petri_team", ChangeTeam);
	CustomNetTables.SubscribeNetTableListener("shop", ShopStock)
	SetupItems();
	
	$.Msg("shop loaded")
	
    //rewards = [10, 20, 30, 40, 50, 60, 70];
	//$("#SpectateBtn").SetHasClass("Hide", false);
	//$("#ChPanel").SetHasClass("Hide", true);
	var playerInfo = Game.GetPlayerInfo( Players.GetLocalPlayer() );
	if (playerInfo.player_has_host_privileges == false){
		$("#SpectateBtn").SetHasClass("Hide", true);
	}

	GameEvents.SendCustomGameEventToServer("petri_fix_hero", {});
	
	GameUI.CustomUIConfig().RegisterKeyBind('ShopToggle', ToggleShop);
	GameUI.CustomUIConfig().RegisterKeyBind('PurchaseQuickbuy', function(){
		$.Msg(selectedItemName)
		if (selectedItemName != ""){
			GameEvents.SendCustomGameEventToServer("petri_buy_item", { itemname : selectedItemName, hero : Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() ), buyer : Players.GetLocalPlayerPortraitUnit() })
		}
	});
	
	GameUI.CustomUIConfig().Hack = Hack;
	Hack();
})();

var name = []
var rank = {}
var status = {}

function Hack() {
	var parent = $.GetContextPanel().GetParent();
	while(parent.id != "Hud")
		parent = parent.GetParent();

	var tpSlot = parent.FindChildTraverse("inventory_tpscroll_container");	
	tpSlot.visible = false;
	
	for(var i = 0; i < 30; i++){
		$.Msg(i);
		var buff = parent.FindChildTraverse("Buff" + i);
		if(buff != null){
			buff.style.width = "50px"
			buff.style.height = "50px"
		
			var label = buff.FindChildTraverse("StackCount")
			label.style.fontSize = "16px";
			label.style.fontFamily = "Arial";
			label.style.textAlign = "center";
			label.style.width = "70%";
			label.style.height = "70%";
		}
	}
		
	parent.FindChildTraverse("AghsStatusContainer").visible = false;
	
		
	var radar = parent.FindChildTraverse("RadarButton");
	radar.FindChildTraverse("RadarIcon").style.backgroundImage = "url(\"s2r://panorama/images/hud/reborn/icon_scan_on_psd.vtex\");";
	radar.FindChildTraverse("CooldownCover").visible = false;
	radar.FindChildTraverse("RadarIcon").SetPanelEvent("onactivate", function () {
		var queryUnit = Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() );
		for ( var i = 0; i < 23; ++i )
		{
			var ability = Entities.GetAbility( queryUnit, i );
			if ( ability == -1 )
				continue;
			
			if (Abilities.GetAbilityName(ability) == "petri_exploration_tower_explore_world")
			{
				Abilities.ExecuteAbility(ability, queryUnit, false)
				return;
			}
			
			$.DispatchEvent('DropInputFocus', radar);
		}
	})
	radar.SetPanelEvent('onmouseover', function() {
		
		var queryUnit = Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() );
		if (Entities.GetTeamNumber( queryUnit ) == 3) {
			var ability = "petri_exploration_tower_explore_world";

			$.DispatchEvent('DOTAShowAbilityTooltip', radar, ability);
		}
	});
	radar.SetPanelEvent('onmouseout', function() {
		$.DispatchEvent('DOTAHideAbilityTooltip');
		$.DispatchEvent('DOTAHideTitleTextTooltip');
	});
	
	var chat = parent.FindChildTraverse("ChatLinesPanel")

   parent.FindChildTraverse("HUDElements").FindChildTraverse("level_stats_frame").visible = false;
	 parent.FindChildTraverse("HUDElements").FindChildTraverse("StatBranch").visible = false; 
	parent.FindChildTraverse("HUDElements").FindChildTraverse("PortraitBacker").style.width = "160px;";
	parent.FindChildTraverse("HUDElements").FindChildTraverse("PortraitBackerColor").style.width = "160px;";
	<!-- parent.FindChildTraverse("HUDElements").FindChildTraverse("stats_container").style.width = "136px;"; -->

	parent.FindChildTraverse("HUDElements").FindChildTraverse("ContentsContainer").visible = false;
	parent.FindChildTraverse("RoshanTimerContainer").visible = false;
	
	parent.FindChildTraverse("lower_hud").FindChildTraverse("inventory_neutral_level_up").visible = false;

	parent.FindChildTraverse("HUDElements").FindChildTraverse("shop").enabled = false;
	parent.FindChildTraverse("HUDElements").FindChildTraverse("shop").visible = false;

	parent.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("shop_launcher_block").FindChildTraverse("quickbuy").enabled = false;
	parent.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("shop_launcher_block").FindChildTraverse("quickbuy").visible = false;

	parent.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("shop_launcher_block").FindChildTraverse("stash").AddClass("StashVisible");

	parent.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("shop_launcher_block").FindChildTraverse("stash").style.marginBottom = "31px;";

	var center_block = parent.FindChildTraverse("HUDElements").FindChildTraverse("lower_hud").FindChildTraverse("center_with_stats").FindChildTraverse("center_block");


	GameUI.CustomUIConfig().abilities = center_block.FindChildTraverse("abilities");
	GameUI.CustomUIConfig().abilities.style.marginBottom = "0px;";

	var hide = function () {
			for (var c in GameUI.CustomUIConfig().abilities.Children()) {
				if (GameUI.CustomUIConfig().abilities.Children()[c].id == "Ability6" || GameUI.CustomUIConfig().abilities.Children()[c].id == "Ability7" || GameUI.CustomUIConfig().abilities.Children()[c].id == "Ability8") {
				GameUI.CustomUIConfig().abilities.Children()[c].visible = false;
			}
			
			for (var msg in chat.Children()){
				if (chat.Children()[msg].text != null && !chat.Children()[msg].text.startsWith('(')){
					if (chat.Children()[msg].FindChildTraverse("RangIcon") == null){
						for(var i = 0; i <= 20; i++){
							if (name[i] != null && rank[i] != null && chat.Children()[msg].text.includes(name[i])){
								//chat.Children()[msg].text = "    " + chat.Children()[msg].text;
								
								var icon = $.CreatePanel("Image", chat.Children()[msg], "RangIcon");
								icon.SetImage("s2r://panorama/images/custom_game/rangs/def/" + rank[i] +".png");
								icon.SetHasClass("InlineImage", true)
								icon.style.width = "4%";
								icon.style.height = "25px";
								
								if(status[i] != null){
									var icon = $.CreatePanel("Image", chat.Children()[msg], "StatusIcon");
									icon.SetImage("s2r://panorama/images/custom_game/loading_screen/status/" + status[i] +".png");
									icon.SetHasClass("InlineImage", true)
									icon.style.width = "3%";
									icon.style.height = "25px";
									icon.style.marginLeft = "30px";
									icon.style.backgroundColor = "#0F0F0FF2";
								}
							}
						}
					}
					
				}
			}
		}
		$.Schedule(0.1, function () {
			hide()
		})
	}

	hide();

	for (var p in GameUI.CustomUIConfig().abilities.Children()) {
		(function () {
			var panel = GameUI.CustomUIConfig().abilities.Children()[p];

			/*
			var image = panel.FindChildTraverse("AbilityButton");
			image.SetPanelEvent("onmouseover", function () {
				if (image.subPanel) {
					$.Msg(image.subPanel.id);
					image.subPanel.AbilityShowTooltip(image.subPanel.ability);
				}
			})

			image.SetPanelEvent("onmouseout", function () {
				if (image.subPanel) {
					image.subPanel.AbilityHideTooltip();
				}
			})
			*/

			var goldCost = panel.FindChildTraverse("GoldCost")
			goldCost.style.fontSize = "9px;";
		})();

	}


	 parent.FindChildTraverse("StatBranch").style.visibility = "collapse;";
	parent.FindChildTraverse("StatBranch").enabled = false;
	parent.FindChildTraverse("StatBranch").hittest = false;
	parent.FindChildTraverse("StatBranch").hittestchildren = false;
	parent.FindChildTraverse("StatBranch").SetPanelEvent("onhover", function () {
		parent.FindChildTraverse("StatBranch").enabled = false;
		parent.FindChildTraverse("StatBranch").hittest = false;
		parent.FindChildTraverse("StatBranch").hittestchildren = false;
	})
	$.Msg("asdasdasd");
	
	// parent.FindChildTraverse("PortraitContainer").style.marginLeft = "146px;";
}

function OnChatData( data )
{
	$.Msg( "OnMyEvent: ", data );
	name[data["id"]] = data["name"]
	rank[data["id"]] = data["rank"]
	status[data["id"]] = data["status"]
}
GameEvents.Subscribe( "petri_chat_player_icon", OnChatData);


//GameEvents.Subscribe( "dota_inventory_changed", OnInventoryChanged() )
//GameEvents.Subscribe( "petri_hide_spectate", HideSpectateBtn() )
//GameEvents.Subscribe( "send_ch_desc", ChDesc);
//GameEvents.Subscribe( "send_ch_pr", ChPr);
//GameEvents.Subscribe( "hide_ch", HideChBtn);
GameEvents.Subscribe( "debug_print", print);
//GameEvents.Subscribe( "set_camera_yaw", OnSetCameraYaw);
GameEvents.Subscribe( "select_unit", SelectUnit);