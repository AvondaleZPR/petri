"use strict";

var isdev = []
var icon = []

var stats = []

//---------------------------//
const STAT_RATING = 0       //|
const STAT_GOLD = 1         //|
const STAT_GAMES = 2        //|
const STAT_PETRI_WIN = 3    //|
const STAT_PETRI_GAMES = 4  //|
const STAT_KVN_WIN = 5      //|
const STAT_KVN_GAMES = 6    //|
const STAT_KILLS = 7        //|
const STAT_KVN_WINRATE = 8  //|
const STAT_PETRI_WINRATE = 9//|
//---------------------------//

//--------------------------------------------------------------------------------------------------
// Handeler for when the unssigned players panel is clicked that causes the player to be reassigned
// to the unssigned players team
//--------------------------------------------------------------------------------------------------
function OnLeaveTeamPressed()
{
	Game.PlayerJoinTeam( 5 ); // 5 == unassigned ( DOTA_TEAM_NOTEAM )
}


//--------------------------------------------------------------------------------------------------
// Update the contents of the player panel when the player information has been modified.
//--------------------------------------------------------------------------------------------------
function OnPlayerDetailsChanged()
{
    var playerId = $.GetContextPanel().GetAttributeInt("player_id", -1);
	var playerInfo = Game.GetPlayerInfo( playerId );
	if ( !playerInfo )
		return;
	$( "#PlayerName" ).text = playerInfo.player_name;
	$( "#PlayerAvatar" ).steamid = playerInfo.player_steamid;

	$.GetContextPanel().SetHasClass( "player_is_local", playerInfo.player_is_local );
	$.GetContextPanel().SetHasClass( "player_has_host_privileges", playerInfo.player_has_host_privileges );
	
	if (isdev[playerId] == true){
	    $.GetContextPanel("#PlayerStatusPanel").SetHasClass( "player_has_developer_privileges", true );
		$.GetContextPanel("#PlayerStatusPanel").SetHasClass( icon[playerId], true );
    }
	
	$( "#PlayerRating").text = stats[playerId][STAT_RATING];
	$( "#PlayerLvl").text = stats[playerId][STAT_PETRI_WINRATE] + "%"
	if (stats[playerId][STAT_PETRI_GAMES] >= 10){
	    $( "#PlayerLvl").SetHasClass("ply_green", true)
	} else if (stats[playerId][STAT_PETRI_GAMES] >= 5){
	    $( "#PlayerLvl").SetHasClass("ply_yellow", true)
	}
	
	
	$("#PlayerRating").SetPanelEvent(
	    "onmouseover",
		function(){
			$.DispatchEvent("DOTAShowTextTooltip", $("#PlayerRating"), 
			$.Localize("#stats_rating") + stats[playerId][STAT_RATING] + ", "
			+ $.Localize("#stats_games") + stats[playerId][STAT_GAMES] + ", "
			+ $.Localize("#stats_gold") + stats[playerId][STAT_GOLD] + ", "
		    + $.Localize("#stats_kills") + stats[playerId][STAT_KILLS] + ", "
			+ $.Localize("#stats_games_petri") + stats[playerId][STAT_PETRI_GAMES] + ", "
			+ $.Localize("#stats_games_petri_win") + stats[playerId][STAT_PETRI_WIN] + ", "
			+ $.Localize("#stats_games_kvn") + stats[playerId][STAT_KVN_GAMES] + ", "
			+ $.Localize("#stats_games_kvn_win") + stats[playerId][STAT_KVN_WIN] + ", "
			+ $.Localize("#stats_games_petri_wr") + stats[playerId][STAT_PETRI_WINRATE] + ", "
			+ $.Localize("#stats_games_kvn_wr") + stats[playerId][STAT_KVN_WINRATE] + ", "
			);
		}
	)
}

function OnDev(event_data)
{
	isdev[event_data.pid] = true;
	icon[event_data.pid] = event_data.icon;
	OnPlayerDetailsChanged();
}

/*
function OnRating(event_data)
{
	$.Msg("client got rating");
	rating[event_data.pid] = event_data.rating;
	lvl[event_data.pid] = event_data.lvl;
    OnPlayerDetailsChanged();
}
*/

function OnRating(event_data)
{
	if(event_data["1"] != null){
	    stats[parseInt(event_data["pid"])][STAT_RATING] = parseInt(event_data["1"]["rating"])
        stats[parseInt(event_data["pid"])][STAT_GOLD] = parseInt(event_data["1"]["totalgold"])
	    stats[parseInt(event_data["pid"])][STAT_GAMES] = parseInt(event_data["1"]["gamesplayed"])
	    stats[parseInt(event_data["pid"])][STAT_KVN_GAMES] = parseInt(event_data["1"]["kvngames"])
	    stats[parseInt(event_data["pid"])][STAT_PETRI_GAMES] = parseInt(event_data["1"]["petrigames"])
	    stats[parseInt(event_data["pid"])][STAT_KVN_WIN] = parseInt(event_data["1"]["kvnvictories"])
	    stats[parseInt(event_data["pid"])][STAT_PETRI_WIN] = parseInt(event_data["1"]["petrivictories"])
	    stats[parseInt(event_data["pid"])][STAT_KILLS] = parseInt(event_data["1"]["kills"])
	    stats[parseInt(event_data["pid"])][STAT_PETRI_WINRATE] = parseInt( (parseInt(event_data["1"]["petrivictories"])) / (parseInt(event_data["1"]["petrigames"])) * 100 )
	    stats[parseInt(event_data["pid"])][STAT_KVN_WINRATE] = parseInt( (parseInt(event_data["1"]["kvnvictories"])) / (parseInt(event_data["1"]["kvngames"])) * 100	)
	}
	OnPlayerDetailsChanged();
}

//--------------------------------------------------------------------------------------------------
// Entry point, update a player panel on creation and register for callbacks when the player details
// are changed.
//--------------------------------------------------------------------------------------------------
(function()
{
	$.Msg("game_setup_player ready");
	$.RegisterForUnhandledEvent( "DOTAGame_PlayerDetailsChanged", OnPlayerDetailsChanged );
	isdev = [false, false, false, false, false, false, false, false, false, false, false, false, false, false];
	
	stats = [[], [], [], [], [], [], [], [], [], [], [], [], [], []]
	for(var i = 0; i < 13; i++ ){
		stats[i] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	}
	//rating = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
	//lvl = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
	GameEvents.Subscribe( "is_dev", OnDev);
	GameEvents.SendCustomGameEventToServer( "check4dev", null );
	//GameEvents.Subscribe( "send_rating", OnRating);
	GameEvents.Subscribe("new_send_rating", OnRating)
	OnPlayerDetailsChanged();
})();
