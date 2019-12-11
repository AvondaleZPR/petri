"use strict";
var playerID = -1;


function DismissMenu()
{
	$.DispatchEvent( "DismissAllContextMenus" )
}

function VoteKick()
{
	GameEvents.SendCustomGameEventToServer( "petri_start_vote_kick", { "KickPlayerID" : playerID, "VoteInitiator": Players.GetLocalPlayer() } );
	DismissMenu();	
}

function Close()
{
    $.GetContextPanel("#ContextMenuScript").DeleteAsync(0.0);
}

(function()
{
	playerID = $.GetContextPanel().GetAttributeInt("PlayerID", -1);
	$( "#PlayerName" ).text = Players.GetPlayerName( playerID );
	$( "#VoteKick" ).visible = GameUI.CustomUIConfig().IsAllowedToKick(playerID);
})();
