//stolen from ark120202
var contextPanel = $.GetContextPanel();

function GetKeyBind(name) {
	$.CreatePanelWithProperties('DOTAHotkey', contextPanel, "", {
		keybind: name,
	});

	var keyElement = contextPanel.GetChild(contextPanel.GetChildCount() - 1);
	keyElement.DeleteAsync(0);
	return keyElement.GetChild(0).text;
}

function RegisterKeyBindHandler(name, callback) {
  Game.AddCommand(
    'petro_' + name,
    function() {
		callback()
    }, '', 0,);
}

function RegisterKeyBind(name, callback) {
   RegisterKeyBindHandler(name, callback);
   var key = GetKeyBind(name);
   if (key !== '') Game.CreateCustomKeyBind(key, 'petro_' + name);
}

GameUI.CustomUIConfig().RegisterKeyBind = RegisterKeyBind;