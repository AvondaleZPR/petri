		var dayLength = 480;

		function SetPositionRotation( element, position, rotation ) {
		  var oldPosition = element.oldPosition || [0, 0];
		  var oldRotation = element.oldRotation || 0;

		  //Revert previous transformation
		  element.style.transform = "translate3d(" +
		          -oldPosition[0] + "px, " + -oldPosition[1] + "px, 0px) rotateZ("+(-oldRotation)+"deg)";

		  //Apply new transformation
		  element.style.transform = "rotateZ("+rotation+"deg) translate3d(" +
		          position[0] + "px, " + position[1] + "px, 0px)";

		  element.oldPosition = position;
		  element.oldRotation = rotation;
		}

		function UpdateTime()
		{
			var time = Math.floor( Game.GetDOTATime( false, false) );
			$( "#Time" ).text = new Date(0, 0, 0, 0, 0, time ).toTimeString().replace(/.*(\d{2}:\d{2}).*/, "$1");

			var daySec = time % 480;
			if ( daySec > 240 )
				$( "#PetroTime" ).style.visibility = "visible;";
			else
				$( "#PetroTime" ).style.visibility = "collapse;";				

			SetPositionRotation($( "#TimeOfDayImage" ), [0, 0], -180 + daySec / 480 * 360);
			//$( "#TimeOfDayImage" ).style["transform"] = "rotateZ(" + String( -180 + daySec / 480 * 360 ) + "deg );";

			$.Schedule( 1, UpdateTime );
		}

		(function() {
			SetPositionRotation($( "#TimeOfDayImage" ), [0, 0], -180);
		    $.Schedule( 0.1, UpdateTime );
		})();