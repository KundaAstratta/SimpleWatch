using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.ActivityMonitor as Act;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Application as App;


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
      
        // percent
        // avant      
        var percent_big_circ = 0.80;
        var percent_lit_circ = 0.70;
        var percent_pos_dat = 0.90;
        var percent_pos_oth = 0.77;
        var pos_dec = 6;
      
      
      
       if (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND) {
	         if (System.getDeviceSettings().screenWidth < 220) {  //SmallRound
	 
	            percent_big_circ = 0.90;
                percent_lit_circ = 0.70;
                percent_pos_dat = 0.20;
                percent_pos_oth = 0.20;   	
	 	
     	       } else {	                   //largeRound
	
	             percent_big_circ = 0.95;
                 percent_lit_circ = 0.75;
                 percent_pos_dat = 0.20;
                 percent_pos_oth = 0.20;
	       	
	          } 
	  } else {					//semiRound
	    	   
	     percent_big_circ = 0.80;
         percent_lit_circ = 0.70;
         percent_pos_dat = 0.25;
         percent_pos_oth = 0.15;
         pos_dec = 6;
      }
      
      
        // the second hand (length)
        var seconde_length = percent_big_circ * radius;
        // the minute hand (length)
        var minute_length = percent_big_circ * radius;
        // the hour hand (length)
        var hour_length = percent_lit_circ * minute_length;
       
        // for the arc
        var arc_width = center_x ;
        var arc_height = center_y ;
        var arc_radius = radius * percent_big_circ;
        var pos_min;
    
    
        dc.clear(); 
        
        
        // Set background color
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.fillCircle(center_x, center_y, diameter);
        
        
        // Color background circles 
        var color_circle = Gfx.COLOR_YELLOW ;
        color_circle = Gfx.COLOR_GREEN;
        color_circle = Gfx.COLOR_DK_GRAY;
        
       
        
        dc.setPenWidth(7);
        dc.setColor(color_circle, Gfx.COLOR_TRANSPARENT);    
        dc.drawCircle(center_x , center_y, arc_radius);
        
        dc.setPenWidth(7);
        dc.setColor(color_circle, Gfx.COLOR_TRANSPARENT) ;    
        dc.drawCircle(center_x , center_y, arc_radius * percent_lit_circ);
      
      

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
         // stepsNow = 1;
         //TEST
         
         stepsPercent = stepsNow * 1.0 / stepsMax ;
    
      
       
        //color for step by step arcs
        var color_sec= Gfx.COLOR_BLUE;
    
 
        // TEST
       //var stepsPercent = 0.21;
        // TEST
        
        if (stepsPercent >= 1.0) {
		        color_sec = Gfx.COLOR_GREEN;
	       } else {
                color_sec = Gfx.COLOR_BLUE;
                }
             
	 
	    //date
        var date = Time.now();
		var info = Calendar.info(date, Time.FORMAT_LONG);        
        var dayDate = info.day;
        
        //battery
        var battery = Sys.getSystemStats().battery / 100 ;
        var battery_color ;
       
        battery_color = Gfx.COLOR_WHITE ; 
        
        //TEST
        //battery = 0.40;
        //TEST
        if (battery < 0.50) {
		        battery_color = Gfx.COLOR_WHITE;
		        if (battery < 0.20) {
		             battery_color = Gfx.COLOR_RED;
		    
		        } 
	        }  else {      
		             battery_color = Gfx.COLOR_WHITE ;
		             }
	  
	  // arcs' color
	  var color_arc_out = Gfx.COLOR_YELLOW;
	  var colorPropertiesOut = App.getApp().getProperty("ArcColorOut") ;
      color_arc_out = returnColor(colorPropertiesOut); 
      
	  var color_arc_in = Gfx.COLOR_YELLOW;
	  var colorPropertiesIn = App.getApp().getProperty("ArcColorIn") ;
      color_arc_in = returnColor(colorPropertiesIn); 
	
	  
	  
	   dc.setColor(color_arc_in, Gfx.COLOR_TRANSPARENT);    
       dc.fillEllipse(center_x, 
              center_y - arc_radius * percent_lit_circ + 1, 
                         radius * 0.1, radius* 0.04);                     
   
	  
       dc.setPenWidth(9);
	   dc.setColor(color_arc_in, Gfx.COLOR_TRANSPARENT);  
	   dc.drawArc(arc_width , arc_height , arc_radius * percent_lit_circ, Gfx.ARC_CLOCKWISE, 90, 90-360*xyz_hour) ;
	 
	
	    dc.setColor(color_arc_out, Gfx.COLOR_TRANSPARENT);    
        dc.fillEllipse(center_x, 
              center_y - arc_radius + 0.9 , 
                         radius * 0.1, radius* 0.04);
	
       dc.setPenWidth(9);
	   dc.setColor(color_arc_out, Gfx.COLOR_TRANSPARENT);  
	   dc.drawArc(arc_width , arc_height , arc_radius , Gfx.ARC_CLOCKWISE, 90, 90-360*xyz_min/60) ;
	
	  	
		
		//PHONE CONNECTED
	    if (System.getDeviceSettings().phoneConnected == true) {
		  
		   if (System.getDeviceSettings().notificationCount != 0) {
		    //NOTIFICATIONS
		    var DrawIconNotification = Ui.loadResource(Rez.Drawables.Notification) ;
            dc.drawBitmap(center_x + radius * percent_pos_oth, center_y, DrawIconNotification) ;
		     } else { 
		     // DATE SHOWED
		      dc.setColor(battery_color, Gfx.COLOR_TRANSPARENT);
              dc.drawText(center_x + radius * percent_pos_dat, center_y , Gfx.FONT_SMALL, dayDate, Gfx.TEXT_JUSTIFY_CENTER);
             }
		  
		   } else {
	       var DrawIconConnected = Ui.loadResource(Rez.Drawables.Notconnected) ;
           dc.drawBitmap(center_x + radius * percent_pos_oth, center_y, DrawIconConnected);
           
		   }
		//PHONE CONNECTED
		
     	var width = dc.getWidth();
        var height = dc.getHeight();  
        
        // TEST TEST TEST 
       // isAwake = true;
       // TEST TEST
       
        	
		// bottom arc battery
		// V++
		var PropertiesShowBattery = App.getApp().getProperty("ShowBatteryArc") ;
		if ((PropertiesShowBattery == 0) or 
		   ((PropertiesShowBattery == 2) and (isAwake == true))) 
		{
		     dc.setPenWidth(3); 
		     dc.setColor(battery_color, Gfx.COLOR_TRANSPARENT); 
		     dc.drawArc(width/2, height/2, arc_radius - pos_dec , Gfx.ARC_CLOCKWISE, 0 , -180 * battery); 
		 }
		//V++
		
		
		// top arc steps
		//V++
	   dc.setPenWidth(3); 
       dc.setColor(color_sec , Gfx.COLOR_TRANSPARENT); 
       
       var PropertiesShowSteps = App.getApp().getProperty("ShowStepsArc") ;
	   if ((PropertiesShowSteps == 0) or 
		   ((PropertiesShowSteps == 2) and (isAwake == true))) 
		{  
		 if (stepsPercent >= 1.0) {
		        dc.drawArc(width/2, height/2, arc_radius - pos_dec, Gfx.ARC_COUNTER_CLOCKWISE, 0 , 180); 
           } else {
             if (stepsPercent <= 0.1) {
                dc.drawArc(width/2, height/2, arc_radius - pos_dec, Gfx.ARC_COUNTER_CLOCKWISE, 0 , 1); 
                 } else {
                 dc.drawArc(width/2, height/2, arc_radius - pos_dec, Gfx.ARC_COUNTER_CLOCKWISE, 0 , stepsPercent * 180); 
                }       
           }
    
        }
      //V++
     
       
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
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        dc.setPenWidth(6);
        dc.drawLine(center_x, center_y,
            (center_x + minute_length * Math.cos(minute_angle)),
            (center_y + minute_length * Math.sin(minute_angle)));
           
       dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);    
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
             
   
       dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);    
       dc.fillCircle((center_x + radius * 0.10 * Math.cos(minute_angle)), 
                     (center_y + radius * 0.10 * Math.sin(minute_angle)), 
                     radius * 0.035);
                     
      
      
    
       
       // Awake ?
       if (isAwake) {
            // draw the second hand
            dc.setColor(color_sec, Gfx.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
           
            dc.drawLine(center_x, center_y,
              (center_x + seconde_length * Math.cos(seconde_angle)),
              (center_y + seconde_length * Math.sin(seconde_angle)));
              
     
   
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
    
    // the user can choose the arc color in settings
     function returnColor(colorNum) {
    	switch(colorNum) {
    		case 0:
    			return Gfx.COLOR_WHITE;
    			break;
    		case 1:
    			return Gfx.COLOR_LT_GRAY;
    			break;
    		case 2:
    			return Gfx.COLOR_RED;
    			break;
    		case 3:
    			return Gfx.COLOR_DK_RED;
    			break;
    		case 4:
    			return Gfx.COLOR_ORANGE;
    			break;
    		case 5:
    			return Gfx.COLOR_YELLOW;
    			break;
    		case 6:
    			return Gfx.COLOR_GREEN;
    			break;
    		case 7:
    			return Gfx.COLOR_DK_GREEN;
    			break;
    		case 8:
    			return Gfx.COLOR_BLUE;
    			break;
    		case 9:
    			return Gfx.COLOR_DK_BLUE;
    			break;
    		case 10:
    			return Gfx.COLOR_PURPLE;
    			break;
    		case 11:
    			return Gfx.COLOR_PINK;
    			break;
    		case 12:
    			return Gfx.COLOR_BLACK;
    			break;	
    		default:
    			return Gfx.COLOR_WHITE;
    			break;
		}
	}
    
    

}
