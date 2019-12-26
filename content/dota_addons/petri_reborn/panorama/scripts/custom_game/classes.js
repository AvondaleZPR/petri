var classes = []
var selectedClass = null;

var CLASS_ID = 0
var CLASS_ICON = 1
var CLASS_ABILITY = 2
var CLASS_NAME = 3
var CLASS_BANNED = 4
var CLASS_PANEL = 5
var CLASS_IMAGE = 6


function ToggleClassPanel() {
	$("#ClassesPanel").ToggleClass("Hide");
}

function OnClass(data) {
	classes[data["id"]][CLASS_ID] = data["id"]
	classes[data["id"]][CLASS_ICON] = data["icon"]
	classes[data["id"]][CLASS_ABILITY] = data["ability"]
	classes[data["id"]][CLASS_NAME] = "#" + data["name"]
	classes[data["id"]][CLASS_BANNED] = false
	classes[data["id"]][CLASS_PANEL] = null
	classes[data["id"]][CLASS_IMAGE] = null
}

function SetClasses() {
	for(var i = 0; i < classes.length; i++){
		if (classes[i][CLASS_ICON] != ""){
            CreateClassBtn(classes[i]);			
		}
	}
	SelectClass(1)
}

function CreateClassBtn(clasie){
	var classpanel = $.CreatePanel("Button", $("#ClassListPanel"), clasie[CLASS_ID]);
	classpanel.SetHasClass("inList", true)
	
	var icon = $.CreatePanel("Image", classpanel, "Image");
	icon.SetImage("file://{images}/custom_game/classes/small/" + clasie[CLASS_ICON]);
	
	var id = clasie[CLASS_ID]
	classpanel.SetPanelEvent('onactivate', function(){SelectClass(id)});
	
	classes[id][CLASS_IMAGE] = icon
	classes[id][CLASS_PANEL] = classpanel
}

function SelectClass(id) {
	$("#DescName").text = $.Localize(classes[id][CLASS_NAME]);
	$("#DescText").text = $.Localize(classes[id][CLASS_NAME] + "_desc");
	
	var path = "file://{images}/custom_game/classes/big/" + classes[id][CLASS_ICON]
    if (classes[id][CLASS_BANNED] == true){
	    path = "file://{images}/custom_game/classes/big/" + "ban_" + classes[id][CLASS_ICON]
	}		

	$("#DescImage").SetImage(path);
	
	selectedClass = id;
}

function PickClass() {
    $.Msg(selectedClass);	
	if (classes[selectedClass][CLASS_BANNED] == false){
	    ToggleClassPanel()
	    GameEvents.SendCustomGameEventToServer( "petri_player_pick_class", { "ability" : classes[selectedClass][CLASS_ABILITY], "classname" : classes[selectedClass][CLASS_NAME] } );
	}
}

function BanClass() {
    $.Msg(selectedClass);	
	if (classes[selectedClass][CLASS_BANNED] == false){
	    ToggleClassPanel()
	    GameEvents.SendCustomGameEventToServer( "petri_player_ban_class", { "classname" : classes[selectedClass][CLASS_NAME] } );
	}
}

function OnBlock(data) {
    for (var i = 0; i < classes.length; i++){
	    if (classes[i][CLASS_NAME] == data["classname"]){
		    classes[i][CLASS_BANNED] = true
			BlockClass(i)   
		}
	}
}

function BlockClass(id) {
	//classes[id][CLASS_PANEL].SetHasClass("banned", true);
	classes[id][CLASS_IMAGE].SetImage("file://{images}/custom_game/classes/small/" + "ban_" + classes[id][CLASS_ICON]);
}

(function () {
	GameEvents.Subscribe("petri_send_class", OnClass);
	GameEvents.Subscribe("petri_set_classes", SetClasses);
	GameEvents.Subscribe("petri_block_class", OnBlock);
	classes = [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []]
	for(var i = 0; i < classes.length; i++ ){
		classes[i] = ["", "", "", "", "", "", "", "", "", ""]
	}
})();