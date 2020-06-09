var classes = []
var selectedClass = null;

var CLASS_ID = 0
var CLASS_ICON = 1
var CLASS_ABILITY = 2
var CLASS_NAME = 3
var CLASS_BANNED = 4
var CLASS_PANEL = 5
var CLASS_IMAGE = 6

var GUIDE_BASIC_PAGE_COUNT = 3
var GUIDE_KVN_PAGE_COUNT = 3
var GUIDE_PETRI_PAGE_COUNT = 1

var selectedPage = null
var selectedPageId = 1
var selectedGuide = ""

var rewards = [10, 25, 50, 75, 100, 125, 150, 1000, 10000]
var rewardsOnePage = 6
var rewardsCurrentPage = 0

function LoadRewards() {
	var j = 0
	for(var i = rewardsCurrentPage; i < rewardsCurrentPage + rewardsOnePage; i++){
		j++
		if(rewards[i] != null){
		    CreateRewardPanel(j, rewards[i])
		}
	}
}

function MoveRewards(value) {
    for(var i = 0; i <= rewardsOnePage; i++){
		if($("#rew" + i) != null){
			$.Msg(i)
		    $("#rew" + i).RemoveAndDeleteChildren()
			$("#rew" + i).DeleteAsync(0.0)
		}
	}
	
	if(value == "left" && rewardsCurrentPage > 0){
        rewardsCurrentPage = rewardsCurrentPage - rewardsOnePage
	}
	else if(value == "right"){
		rewardsCurrentPage = rewardsCurrentPage + rewardsOnePage
	}
	
	LoadRewards()
}

function CreateRewardPanel(i, lvl) {
	var rewardpanel = $.CreatePanel("Panel", $("#BPRewards"), "rew" + i);
	rewardpanel.SetHasClass("reward", true)
	
	var rewardlabel = $.CreatePanel("Label", rewardpanel, "rew" + i + "_l");
	rewardlabel.text = lvl
	
	$.Msg(lvl)
	
	var icon = $.CreatePanel("Image", rewardpanel, "Image");
	icon.SetImage("file://{images}/custom_game/comp/rewards/" + lvl + ".png");
	
	rewardpanel.SetPanelEvent(
	"onmouseover",
		function(){
			$.DispatchEvent("DOTAShowTextTooltip", rewardpanel, 
			$.Localize("#rew_desc" + lvl));
		}
	)
	
	rewardpanel.SetPanelEvent(
	"onmouseout",
		function(){
			$.DispatchEvent("DOTAHideTextTooltip", rewardpanel)
		}
	)
}

function ToggleClassPanel() {
	$("#BPPanel").SetHasClass("Hide", true);
	$("#ClassesPanel").ToggleClass("Hide");
	$("#HTPPanel").SetHasClass("Hide", true)
}

function ToggleHTPPanel() {
	$("#BPPanel").SetHasClass("Hide", true);
	$("#HTPPanel").ToggleClass("Hide");
	$("#ClassesPanel").SetHasClass("Hide", true)
}

function ToggleBPPanel() {
	$("#BPPanel").ToggleClass("Hide");
	$("#HTPPanel").SetHasClass("Hide", true);
	$("#ClassesPanel").SetHasClass("Hide", true);
}

function ChDesc(event_data)
{
	$.Msg(event_data);
	$("#CH"+event_data.chid).text = $.Localize(event_data.text);
}

function ChPr(event_data)
{
	$.Msg(event_data);
	$("#CH"+event_data.chid+"Pr").text = event_data.cur + "/" + event_data.tar;
	
	if(event_data.cur >= event_data.tar){
		$("#CH"+event_data.chid).SetHasClass("BPDefault", false)		
		$("#CH"+event_data.chid+"Pr").SetHasClass("BPDefault", false)		
		
		$("#CH"+event_data.chid).SetHasClass("BPCompleted", true)
	    $("#CH"+event_data.chid+"Pr").SetHasClass("BPCompleted", true)
		
		$("#CH"+event_data.chid+"Pr").text = "+" + event_data.chid + "00"
	}
}

function ChLvl(event_data)
{
	var lvl = event_data.lvl / 1000;
	$("#CHlvl").text = parseInt(lvl);
	
	var exp = event_data.lvl % 1000;
	$("#CHexp").text = exp + "/1000"
}

function BasicGuide() {	
    $("#basicguidebtn").SetHasClass("guideSelected", true)
	$("#kvnguidebtn").SetHasClass("guideSelected", false)
	$("#petriguidebtn").SetHasClass("guideSelected", false)
	
	selectedGuide = "basic"
	selectedPageId = 1
	GuideOpenPage($("#basic1"), selectedPage)
	UpdatePageNumbDisplayer()
}

function KvnGuide() {
    $("#basicguidebtn").SetHasClass("guideSelected", false)
	$("#kvnguidebtn").SetHasClass("guideSelected", true)
	$("#petriguidebtn").SetHasClass("guideSelected", false)
	
	selectedGuide = "kvn"
	selectedPageId = 1
	GuideOpenPage($("#kvn1"), selectedPage)
	UpdatePageNumbDisplayer()
}

function PetriGuide() {
    $("#basicguidebtn").SetHasClass("guideSelected", false)
	$("#kvnguidebtn").SetHasClass("guideSelected", false)
	$("#petriguidebtn").SetHasClass("guideSelected", true)
	
	selectedGuide = "petri"
	selectedPageId = 1
	GuideOpenPage($("#petri1"), selectedPage)
	UpdatePageNumbDisplayer()
}

function GetSelectedGuideMaxPagesCount(){
	if (selectedGuide == "basic") return GUIDE_BASIC_PAGE_COUNT 
	if (selectedGuide == "kvn") return GUIDE_KVN_PAGE_COUNT
    if (selectedGuide == "petri") return GUIDE_PETRI_PAGE_COUNT 	
}

function GuideOpenPage(page, previous) {
    if (previous != null) {
	    previous.SetHasClass("Hide", true)
	}
	
	page.SetHasClass("Hide", false)
	selectedPage = page
}

function GuideNextPage() {
    if (selectedPageId < GetSelectedGuideMaxPagesCount()) {
        selectedPageId = selectedPageId + 1
		GuideOpenPage($("#" + selectedGuide + selectedPageId), selectedPage)
		
		UpdatePageNumbDisplayer()
	}
	
}

function GuidePreviousPage() {
    if (selectedPageId > 1) {
	    selectedPageId = selectedPageId - 1
		GuideOpenPage($("#" + selectedGuide + selectedPageId), selectedPage)
		
		UpdatePageNumbDisplayer()
	}
}

function UpdatePageNumbDisplayer() {
    $("#PageNumb").text = selectedPageId + "/" + GetSelectedGuideMaxPagesCount()
}

function OnClass(data) {
	if (classes[data["id"]][CLASS_ID] == "") {
	
	classes[data["id"]][CLASS_ID] = data["id"]
	classes[data["id"]][CLASS_ICON] = data["icon"]
	classes[data["id"]][CLASS_ABILITY] = data["ability"]
	classes[data["id"]][CLASS_NAME] = "#" + data["name"]
	classes[data["id"]][CLASS_BANNED] = false
	classes[data["id"]][CLASS_PANEL] = null
	classes[data["id"]][CLASS_IMAGE] = null
	
	if(data["banned"] == 1){
	    OnBlock(data)
	}
	
	}
}

function SetClasses() {
	for(var i = 0; i < classes.length; i++){
		//$("#class_" + classes[i][CLASS_ID]).SetHasClass("Hide", true)
		if ($("#class_" + classes[i][CLASS_ID]) == null) {
			if (classes[i][CLASS_ICON] != ""){
				CreateClassBtn(classes[i]);			
			}
		}
	}
	SelectClass(1)
}

function CreateClassBtn(clasie){
	var classpanel = $.CreatePanel("Button", $("#ClassListPanel"), "class_" + clasie[CLASS_ID]);
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
	    GameEvents.SendCustomGameEventToServer( "petri_player_ban_class", { "ability" : classes[selectedClass][CLASS_ABILITY], "classname" : classes[selectedClass][CLASS_NAME] } );
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

function OnBanPlayer() {
    $.Msg("banned")
	
	$("#RootRootRoot").hittest = true
	$("#RootRootRoot").hittestchildren = false
}

function SendFeedBack() {
	var msg = $("#FeedText").text
	$.Msg(msg)
	GameEvents.SendCustomGameEventToServer( "petri_send_feedback", { "feedback" : msg } );
}

function OnEndGameCam()
{        
    GameUI.SetCameraYaw(60);
    GameUI.SetCameraPitchMin(5);
    GameUI.SetCameraPitchMax(5);
    GameUI.SetCameraDistance(100);
    GameUI.SetCameraLookAtPositionHeightOffset(0);
}

(function () {
	GameEvents.Subscribe("petri_send_class", OnClass);
	GameEvents.Subscribe("petri_set_classes", SetClasses);
	GameEvents.Subscribe("petri_block_class", OnBlock);
	GameEvents.Subscribe("petri_ban_player", OnBanPlayer);
	
	GameEvents.Subscribe( "send_ch_desc", ChDesc);
    GameEvents.Subscribe( "send_ch_pr", ChPr);
	GameEvents.Subscribe( "send_ch_lvl", ChLvl);
	
	GameEvents.Subscribe( "petri_end_game_cam", OnEndGameCam);
	
	classes = [[], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], [], []]
	for(var i = 0; i < classes.length; i++ ){
		classes[i] = ["", "", "", "", "", "", "", "", "", ""]
	}
	
	//BasicGuide()
	LoadRewards()
})();