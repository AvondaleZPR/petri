'use strict';
// Current date
var date = new Date();
var curDate = date.getFullYear() * 10000 + (date.getMonth() + 1) * 100 + date.getDate();

var backgroundPath = "file://{resources}/layout/custom_game/loading_screen/backgrounds/";
var backgroundPanel = $( "#CustomBackground" );

var maxBGs = 18

//-----------------------------------------------------------------------------
//						Default backgrounds
//-----------------------------------------------------------------------------
var defaultBackgrounds = [
	"default"
];

var newYear = [
	"newyear"
];

//-----------------------------------------------------------------------------
//						Halloween backgrounds
//-----------------------------------------------------------------------------
var halloween = [
	"halloween"
];

function SetBackground()
{
	var backList = defaultBackgrounds;
	//var backList = newYear;
	var dayMonth = curDate % 10000;

	// if (dayMonth > 1024 && dayMonth < 1107)
	// 	backList = halloween;

	var backNum = Math.floor(Math.random() * backList.length);
	backgroundPanel.BLoadLayout( backgroundPath + backList[backNum] + ".xml", false, false );
	
	//
	var rnd = Math.floor(Math.random() * Math.floor(maxBGs));
	$.Msg("backgrond id " + rnd)
	backgroundPanel.FindChildTraverse("bg" + rnd).SetHasClass("hide", false)
	//
}

(function () {
	SetBackground();
})(); 