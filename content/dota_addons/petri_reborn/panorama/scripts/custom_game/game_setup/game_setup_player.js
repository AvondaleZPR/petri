"use strict";

var isdev = []
var icon = []
var rating = []
var lvl = []

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
	
	//$( "#PlayerRating").text = rating[playerId];
	//$("#PlayerLvl").text = lvl[playerId];
}

function OnDev(event_data)
{
	isdev[event_data.pid] = true;
	icon[event_data.pid] = event_data.icon;
	OnPlayerDetailsChanged();
}

function OnRating(event_data)
{
	$.Msg("client got rating");
	rating[event_data.pid] = event_data.rating;
	lvl[event_data.pid] = event_data.lvl;
    OnPlayerDetailsChanged();
}

//--------------------------------------------------------------------------------------------------
// Entry point, update a player panel on creation and register for callbacks when the player details
// are changed.
//--------------------------------------------------------------------------------------------------
(function()
{
	$.Msg("game_setup_player ready");
	OnPlayerDetailsChanged();
	$.RegisterForUnhandledEvent( "DOTAGame_PlayerDetailsChanged", OnPlayerDetailsChanged );
	isdev = [false, false, false, false, false, false, false, false, false, false, false, false, false, false];
	rating = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
	lvl = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
	GameEvents.Subscribe( "is_dev", OnDev);
	GameEvents.SendCustomGameEventToServer( "check4dev", null );
	//GameEvents.Subscribe( "send_rating", OnRating);
})();
