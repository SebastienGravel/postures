// Filename: app.js
define([
    'underscore',
    'jquery',
    'mobile'

], function(_, $, mobile) {
    var initialize = function() {
        "use strict";

        var socket = io.connect()
        ,   slideActif = true
        ,   widthW = document.width
        ,   heightW = document.height
        ,   nbPage = $(".page").length
        ,   currentPage = 1;



        document.ontouchmove = function(event) {
            event.preventDefault();
        }


        // Get orientation delta from server
        var orientationDelta = 0.0;

        socket.on("orientationDelta", function(data) {
            orientationDelta = parseFloat(data);
        });

        socket.emit("getOrientationDelta", 0);

        //*** ORIENTATION ***//
        window.addEventListener('deviceorientation', function(eventData) {
            var yaw, pitch, roll;
            var yaw = 0.0;
            yaw = ((eventData.webkitCompassHeading + orientationDelta) % 360.0) * 0.0174532925199;
            pitch = eventData.beta * 0.0174532925199;
            roll = eventData.gamma * 0.0174532925199;

            var x, y, z;
            x = Math.sin(-pitch + 1.570796326795) * Math.cos(-yaw);
            y = Math.sin(-pitch + 1.570796326795) * Math.sin(-yaw);
            z = Math.cos(-pitch + 1.570796326795);

            yaw *= -57.2957795;
            pitch *= 57.2957795;
            roll *= 57.2957795;

            var send = {
                yaw : yaw,
                pitch : pitch,
                roll : roll,
            };
            socket.emit("orientation", send);

            send = {
                x : x,
                y : y,
                z : z
            };
            socket.emit("velocity", send);
        });

        //*** Position finger arrows ***//
        $("#arrows").on('touchmove', function(e) {
            var value = e.originalEvent.touches[0].pageY;
            value = Math.max(heightW - value, 0);
            value = (value - heightW / 2) / 40;
            if (Math.abs(value) < 0.5)
                value = 0.0;
            // alert(value);
            socket.emit("speed", value);

            //$(this).html(value);
        })

        $("#arrows").on('touchend', function(e) {
            socket.emit("speed", 0.0);
        })

        $("#cube").on('touchstart', function(e) {
            socket.emit("pressBrush", 1);
        })

        $("#pen").on('touchstart', function(e) {
            socket.emit("pressBrush", 2);
        })

        $("#grid").on('touchstart', function(e) {
            socket.emit("switchProjection", 1);
        })

        //*** Send message OSC click btn1 ***//
        $("#btn1").on({
            'mouseleave' : pressOut,
            'touchstart' : pressIn,
            'touchend'   : pressOut
        });

        function pressIn() {
            var btnSelected = $(".press .icon").attr("id")
            ,   send = null;
            if(btnSelected == "cube" )
                send = 1;
            else if(btnSelected == "pen" )
                send = 2;
            else
                send = 0;

            $("#btn1 .icon").addClass("pressed");

            if (send != 0)
                socket.emit("pressBtn", send);
        }

        function pressOut() {
            var btnSelected = $(".press .icon").attr("id")
            ,   send = null;
            if(btnSelected == "cube" )
                send = -1;
            else if(btnSelected == "pen" )
                send = -2;
            else
                send = 0;

            $("#btn1 .icon").removeClass("pressed");

            if (send != 0)
                socket.emit("pressBtn", send);
        }



        //*** SWITCH TYPE DRAWING ***//

        $('.btnMenu').on('touchstart touchend', function(e) {
            e.preventDefault();
            $(this).toggleClass('pressed');
            if($(this).hasClass("btnAction"))
            {
                var btnSelected = $(this).attr("id");
                $("#btn1 .icon").attr("id", btnSelected);
            }
        });



        $('#trash').on('touchstart touchend', function(e) {
            e.preventDefault();
            $(this).toggleClass('pressed');
            if(e.type == "touchstart") socket.emit("pressBtn", 0);
        });



        $("#global").width(widthW).height(heightW);
        $("#content").width(widthW*nbPage).height(heightW);
        $(".page").height(heightW).width(widthW);
        $("#arrows").height(heightW);


        //*** Swipe page ***///

        $(function()
        {

            //*** Define size page ***//

            $(".page").on("swipeleft", function()
            {
                if(currentPage < nbPage && slideActif)
                {
                    $("#content").animate({left : '-=320'}, 400, function(){ currentPage +=1; });
                }
            });

            $(".page").on("swiperight", function() {
                if(currentPage > 1 && slideActif)
                {
                    $("#content").animate({left : '+=320'}, 400, function(){ currentPage -=1; });
                }
            });

        });


        var stateMirror = 0.0;
        $("#btn2").on("touchstart", function(){
            $("#btn2 .icon").toggleClass("pressed");
            $("#content-slider").toggleClass("hidden");

            if($("#btn2 .icon").hasClass("pressed"))
                stateMirror = 1.0;
            else
                stateMirror = 0.0;

            socket.emit("calibrate", stateMirror, $("#slider-calibrage").val()); //0 1

        });


        //*** Jquery UI Slider ***///

        $("#slider-calibrage" ).slider();
        $( "#slider-calibrage" ).bind( "change", function(event, ui){ socket.emit("calibrate", stateMirror, $(this).val()); });
        $( "#slider-calibrage" ).on( 'slidestart', function( event ) { slideActif = false });
        $( "#slider-calibrage" ).on( 'slidestop', function( event ) { slideActif = true });
    }

  return {
    initialize: initialize
  };

});
