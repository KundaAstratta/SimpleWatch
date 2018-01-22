using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.ActivityMonitor as Act;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;


class SimpleWatchView extends Ui.WatchFace {
   // awake
    var isAwake;
    // 2 pi
    var TWO_PI = Math.PI * 2;
   //angle adjust for time hands
    var ANGLE_ADJUST = Math.PI / 2.0;
    // steps Goal
    var stepsMax ;
    // steps now
    var stepsNow ;
    // steps percent
    var stepsPercent;
 
 
   
        
    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {      
    
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
      
        // center, diameter, radius   
        var center_x = dc.getWidth() / 2;
        var center_y = dc.getHeight() / 2;
        var diameter = dc.getWidth() ;
        var radius = diameter / 2 ;
      
      
        // the second hand (length)
        var seconde_length = 0.80 * radius;
        // the minute hand (length)
        var minute_length = 0.80 * radius;
        // the hour hand (length)
        var hour_length = 0.70 * minute_length;
       
        // for the arc
        var arc_width = center_x ;
        var arc_height = center_y ;
        var arc_radius = radius * 0.80;
        var pos_min;
    
    
        dc.clear(); 
        
        
        // Set background color
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(center_x, center_y, diameter);
        
        dc.setPenWidth(7);
        dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);    
        dc.drawCircle(center_x , center_y, arc_radius);
        
        dc.setPenWidth(7);
        dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT) ;    
        dc.drawCircle(center_x , center_y, arc_radius * 0.70);
      
      

        // Get the current time
        var now = Sys.getClockTime();
        var hour = now.hour;
        var min = now.min;
        var sec = now.sec;
   
        // to draw the line time
        var hour_fraction = min / 60.0;
        var minute_angle = hour_fraction * TWO_PI;
        var hour_angle = ((hour % 12 + hour_fraction) / 12.0) * TWO_PI;
        var seconde_angle = sec / 60.0 * TWO_PI;
        
        // compensate the starting position
        minute_angle -= ANGLE_ADJUST;
        hour_angle -= ANGLE_ADJUST;
        seconde_angle -= ANGLE_ADJUST;
      
        // TEST
        // min=10 ; 
        // TEST
        
        // to color the arcs
        var xyz_min = min  ;
        var xyz_hour = (hour % 12 + hour_fraction) / 12.0;
    
        
        //calcul steps percent
         stepsMax = Act.getInfo().stepGoal;
         
         stepsNow = Act.getInfo().steps;
         
         // TEST 
         // stepsMax = 100;
         //  stepsNow = 1;
         //TEST
         
         stepsPercent = stepsNow * 1.0 / stepsMax ;
    
      
       
        //color for step by step
        var color = Gfx.COLOR_RED;
    
 
        // TEST
        // steps = 1.21;
        // TEST
        
        if (stepsPercent >= 1.0) {
		        color = Gfx.COLOR_YELLOW;
	       } else {
                color = Gfx.COLOR_RED;
                }
             
	 
	    //date
        var date = Time.now();
		var info = Calendar.info(date, Time.FORMAT_LONG);        
        var dayDate = info.day;
        
        //battery
        var battery = Sys.getSystemStats().battery / 100 ;
        var battery_color ;
       
        battery_color = Gfx.COLOR_WHITE ; 
       
        if (battery < 0.50) {
		        battery_color = Gfx.COLOR_YELLOW;
		        if (battery < 0.20) {
		             battery_color = Gfx.COLOR_RED ;
		        } 
	        }  else {      
		             battery_color = Gfx.COLOR_WHITE ;
		             }
	
	  // arc blue 
       dc.setPenWidth(7);
	   dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);  
	   dc.drawArc(arc_width , arc_height , arc_radius * 0.70, Gfx.ARC_CLOCKWISE, 90, 90-360*xyz_hour) ;
	 
	
       dc.setPenWidth(7);
	   dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);  
	   dc.drawArc(arc_width , arc_height , arc_radius , Gfx.ARC_CLOCKWISE, 90, 90-360*xyz_min/60) ;
	
	  	
		
         //TEST PHONE CONNECTED
	 if (System.getDeviceSettings().phoneConnected == true) {
		  
		   if (System.getDeviceSettings().notificationCount != 0) {
		    //TEST NOTIFICATIONS
		    var DrawIconNotification = Ui.loadResource(Rez.Drawables.Notification) ;
                    dc.drawBitmap(center_x + radius * 0.77, center_y, DrawIconNotification) ;
		   
		     } else { 
		     // DATE SHOWED
		      dc.setColor(battery_color, Gfx.COLOR_TRANSPARENT);
                      dc.drawText(center_x + radius * 0.90, center_y , Gfx.FONT_SMALL, dayDate, Gfx.TEXT_JUSTIFY_CENTER);
                     }
		  
           } else {
	      var DrawIconConnected = Ui.loadResource(Rez.Drawables.Notconnected) ;
              dc.drawBitmap(center_x + radius * 0.77, center_y, DrawIconConnected);
	  }
          //TEST PHONE CONNECTED
		
     
      
     
       
       //draw the hour hand
       dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
       dc.setPenWidth(6);
       dc.drawLine(center_x, center_y,
            (center_x + hour_length * Math.cos(hour_angle)),
            (center_y + hour_length * Math.sin(hour_angle)));
            
            
       dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);    
       dc.fillCircle((center_x + hour_length * Math.cos(hour_angle)), 
                     (center_y + hour_length * Math.sin(hour_angle)), 
                     radius * 0.035);
      
     
         // draw the minute hand
        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(6);
        dc.drawLine(center_x, center_y,
            (center_x + minute_length * Math.cos(minute_angle)),
            (center_y + minute_length * Math.sin(minute_angle)));
           
       dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);    
       dc.fillCircle((center_x + minute_length * Math.cos(minute_angle)), 
                     (center_y + minute_length * Math.sin(minute_angle)), 
                     radius * 0.035);
      
     
      
      
       // the watch center
       dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);    
       dc.fillCircle(center_x, center_y, radius * 0.10);
   
       dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);    
       dc.fillCircle((center_x + radius * 0.10 * Math.cos(hour_angle)), 
                     (center_y + radius * 0.10 * Math.sin(hour_angle)), 
                     radius * 0.035);
             
   
       dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);    
       dc.fillCircle((center_x + radius * 0.10 * Math.cos(minute_angle)), 
                     (center_y + radius * 0.10 * Math.sin(minute_angle)), 
                     radius * 0.035);
                     
      
      
    
       // TEST TEST TEST 
       //isAwake = true;
       // TEST TEST
       
       // Awake ?
       if (isAwake) {
            // draw the second hand
            dc.setColor(color, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawLine(center_x, center_y,
               (center_x + seconde_length * Math.cos(seconde_angle)),
               (center_y + seconde_length * Math.sin(seconde_angle)));
               
           dc.setColor(color, Gfx.COLOR_TRANSPARENT);    
           dc.fillCircle((center_x + seconde_length * Math.cos(seconde_angle)), 
                         (center_y + seconde_length * Math.sin(seconde_angle)), 
                         radius * 0.05);
   
          dc.setColor(color, Gfx.COLOR_TRANSPARENT);    
          dc.fillCircle(center_x, center_y, radius * 0.04);
       
   
        }
   
        
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
       isAwake = true;
        Ui.requestUpdate();
        
      
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
        isAwake = false;
        Ui.requestUpdate();
    }

}
