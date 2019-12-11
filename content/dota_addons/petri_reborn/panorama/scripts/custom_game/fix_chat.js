function OnFixChat( )
{
	$.Msg( "fix chat" );
	Game.EnterAbilityLearnMode()
	Game.EndAbilityLearnMode()
}

GameEvents.Subscribe( "chat_fix", OnFixChat);