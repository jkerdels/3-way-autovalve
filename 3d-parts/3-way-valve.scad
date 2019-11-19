
// for the gears we use the Getriebe.scad library
// https://www.thingiverse.com/thing:1604369
use <Getriebe.scad>;

// to export/print any part, make the just_<part> variable true
// and re-render the model
just_case         = false;
just_case_lid     = false;
just_lever_gear   = false;
just_drive_gear   = false;
just_motor        = false;
just_piping       = false;
just_etronics     = false;
just_holder_base  = false;
just_holder_stand = false;
just_case_seal    = false;

// Distance between the axis of the two opposing valves.
// This value depends on the valves and the T-pipe between
// them that you choose for your version of the 3-way-valve
valve_axis_distance = 92;

// nr of teeth you want on the main gears
nr_of_gearteeth     = 34;
// nr of teeth you want on the gear attached to the motor
drive_gear_teeth    = 13;

// diameter of the "round parts" of the top case that houses
// the motor and the electronics
case_outer_diam     = 50;

// height of the top case
case_outer_height   = 35;

// height of the gears. You can increase this height to
// reduce the load on each gear tooth, e.g., when your
// valves are very hard to move
gear_height         = 10;

// the gap between gears and top case
gear_case_spacing = 4;

// depending on your 3d-printer, holes may be printed too
// small (or too big). With this parameter you can tweak
// the size of all holes to meet the characteristics of
// your printer. 
hole_extra  = 0.5;

// this function just checks if any of the above "just_*" variables is true
function show_all() = !just_case && !just_case_lid && !just_lever_gear && !just_drive_gear && !just_motor && !just_piping && !just_etronics && !just_holder_base && !just_holder_stand && !just_case_seal;

// from here on it is just a series of modules that
// describe the geometry
module piping() {

sp = 24+hole_extra;
lp = 28+hole_extra;

translate([valve_axis_distance/2,0,lp/2])
cylinder(d=8,h=50-lp/2);

translate([-valve_axis_distance/2,0,lp/2])
cylinder(d=8,h=50-lp/2);

translate([-45/2,0,sp/2+2])
rotate([0,90,0])
cylinder(d=sp,h=45);

translate([0,24,sp/2+2])
rotate([90,0,0])
cylinder(d=sp,h=24);

translate([45/2,0,lp/2])
rotate([0,90,0])
cylinder(d=lp,h=50);

translate([-45/2-50,0,lp/2])
rotate([0,90,0])
cylinder(d=lp,h=50);

translate([0,8+24,lp/2])
rotate([90,0,0])
cylinder(d=lp,h=10);

translate([0,30+24+8,sp/2+2])
rotate([90,0,0])
rotate([0,0,30])
cylinder(d=sp,h=30,$fn=6);

translate([valve_axis_distance/2-10,-9,40])
cube([95,18,20]);

translate([-valve_axis_distance/2+9,0,40])
rotate([0,0,90])
translate([-10,0,0])
cube([95,18,20]);

translate([-13,32,20])
cube([3,30,10]);

}

module end_stop() {
    difference(){
        union(){
            cube([15,13,15]);
            translate([0,0,15])
            cube([6,13,8]);
        }

        translate([15,-1,15])
        rotate([-90,0,0])
        cylinder(d=18,h=15,$fn=36);

        translate([-1,13/2,18])
        rotate([0,90,0])
        cylinder(d=5+hole_extra,h=8,$fn=18);
    }
}

module lever_gear(){
    difference(){
        stirnrad(m,nr_of_gearteeth,gear_height,14.5+hole_extra,optimiert=false);
        cylinder(d=17+hole_extra,h=6,$fn=72);
    }
    translate([25,-10,0])
    difference(){
        cube([60,20,10]);
        translate([52,-1,9])
        cube([4,22,3]);
        translate([44,-1,9])
        cube([4,22,3]);
        translate([36,-1,9])
        cube([4,22,3]);
        translate([28,-1,9])
        cube([4,22,3]);
    }
    translate([case_outer_diam/2+8.5,-13/2,gear_height-0.1])
    end_stop();
}

module motor(diff_helper = false) {
    gearbox_width  = 32;
    gearbox_length = 46.1;
    gearbox_height = 21.1;
    
    translate([-14,-gearbox_width/2,-(gearbox_height+2)])
    union(){
        cube([gearbox_length,gearbox_width,gearbox_height]);
        translate([14,gearbox_width/2,gearbox_height-1])
        cylinder(h=3,d=14.5,$fn=36);
        translate([14,gearbox_width/2,gearbox_height-1])
        cylinder(h=14+3,d=6+hole_extra,$fn=36);
        translate([5.5,7,gearbox_height-1]) {
            cylinder(h=3,d=8,$fn=18);
            if (diff_helper) {
                cylinder(h=20,d=3+hole_extra,$fn=18);
            }
        }
        translate([5.5,gearbox_width-7,gearbox_height-1]) {
            cylinder(h=3,d=8,$fn=18);
            if (diff_helper) {
                cylinder(h=20,d=3+hole_extra,$fn=18);
            }
        }
        translate([38.5,7,gearbox_height-1]) {
            cylinder(h=3,d=8,$fn=18);
            if (diff_helper) {
                cylinder(h=20,d=3+hole_extra,$fn=18);
            }
        }
        translate([38.5,gearbox_width-7,gearbox_height-1]) {
            cylinder(h=3,d=8,$fn=18);
            if (diff_helper) {
                cylinder(h=20,d=3+hole_extra,$fn=18);
            }
        }
        translate([gearbox_length,6+24.5/2,24.5/2-4])
        rotate([0,90,0])
        cylinder(d=24.5,h=35);
    }
}

if (show_all()) {
    color("Silver")
    translate([valve_axis_distance/2,valve_axis_distance/2+drive_gear_diam/2,60+gear_height+gear_case_spacing+2.1])
    rotate([180,0,-110])
    motor();
} else if (just_motor) {
    motor();
}

if (show_all()) {
    color("Silver")
    piping();
} else if (just_piping) {
    piping();
}

m = valve_axis_distance/nr_of_gearteeth;

if (show_all()) {
    color("Green")
    render()
    translate([valve_axis_distance/2,0,60]) 
    lever_gear();

    color("Green")
    render()
    translate([-valve_axis_distance/2,0,60])
    rotate([0,0,90])
    lever_gear();
} else if (just_lever_gear) {
    lever_gear();
}

drive_gear_diam = m * drive_gear_teeth;

module drive_gear() {
    gd = 5.95;
    cap = 5.3;
    
    teeth_angle = 360/drive_gear_teeth;
    render()
    difference(){
        union(){
            stirnrad(m,drive_gear_teeth,gear_height,gd+hole_extra,optimiert=false);
            rotate([0,0,-teeth_angle/2])
            translate([gd/2-(gd-cap),-3,0])
            cube([3,6,gear_height]);
        }
        rotate([0,0,-teeth_angle/2])
        translate([0,0,gear_height/2])
        rotate([0,90,0])
        cylinder(d=3+hole_extra,h=30,$fn=18);
    }
}

color("Red")
if (show_all()) {
    translate([valve_axis_distance/2,0,0])
    rotate([0,0,0])
    translate([0,valve_axis_distance/2+drive_gear_diam/2,60])
    rotate([0,0,20])
    drive_gear();
} else if (just_drive_gear) {
    drive_gear();
}

module case_shape(case_diam) {

difference(){
union() {
    translate([valve_axis_distance/2,0])
    circle(d=case_diam,$fn=72);

    translate([valve_axis_distance/2,valve_axis_distance/2+drive_gear_diam/2])
    circle(d=case_diam,$fn=72);

    translate([-(valve_axis_distance-2*case_diam)/2,valve_axis_distance/2+drive_gear_diam/2])
    circle(d=case_diam,$fn=72);

    translate([0,-case_diam])
    scale([1,0.5])
    circle(d=valve_axis_distance-case_diam,$fn=72);

    translate([-valve_axis_distance/2,0])
    circle(d=case_diam,$fn=72);

    translate([-valve_axis_distance/2,-case_diam])
    square([valve_axis_distance,2*case_diam]);

    translate([valve_axis_distance/2-1,0])
    square([case_diam/2+1,valve_axis_distance/2+drive_gear_diam/2]);

    translate([-(valve_axis_distance-2*case_diam)/2,valve_axis_distance/2+drive_gear_diam/2-1])
    square([valve_axis_distance-case_diam,case_diam/2+1]);

    translate([-(valve_axis_distance-2*case_diam)/2-case_diam/2,valve_axis_distance/2+drive_gear_diam/2-1-case_diam/2])
    square([valve_axis_distance-case_diam+case_diam/2,case_diam/2+1]);

}

translate([-valve_axis_distance/2,-case_diam])
circle(d=case_diam,$fn=72);

translate([valve_axis_distance/2,-case_diam])
circle(d=case_diam,$fn=72);

translate([-valve_axis_distance/2,case_diam])
circle(d=case_diam,$fn=72);
}

}



module case(case_diam,case_height,floor_thickness,wall_thickness) {

difference(){    
    union(){
        linear_extrude(height=floor_thickness)
        case_shape(case_diam);

        color("Peru")
        translate([-(valve_axis_distance/2),0,0])
        cylinder(d=20,h=5,$fn=72);

        color("Peru")
        translate([(valve_axis_distance/2),0,0])
        cylinder(d=20,h=5,$fn=72);
        
        color("Peru")
        translate([-(valve_axis_distance/2)-15,-5,0])
        cube([valve_axis_distance+30,10,5]);

        color("Peru")
        translate([-5,-50,0])
        cube([10,125,3]);

        color("Peru")
        translate([6,64.5,floor_thickness])
        rotate([0,0,35])
        power_reg(true);
        
        color("Peru")
        translate([3,-17,floor_thickness])
        rotate([0,0,-20])
        motor_driver(true);

        color("Peru")
        translate([-15,22,floor_thickness])
        rotate([0,0,35])
        arduino_nano(true);    

    }
        translate([-(valve_axis_distance/2),0,-1])
        cylinder(d=6,h=15,$fn=36);

        translate([(valve_axis_distance/2),0,-1])
        cylinder(d=6,h=15,$fn=36);  
  
        translate([valve_axis_distance/2,valve_axis_distance/2+drive_gear_diam/2,2.1])
        rotate([180,0,-115])
        motor(true);    
       
}

color("SkyBlue",1)
linear_extrude(height=case_height)
difference(){
    case_shape(case_diam);
    offset(r=-wall_thickness)
    case_shape(case_diam);
}


}

if (show_all()) {    
    translate([0,0,60+gear_height+gear_case_spacing])
    case(case_outer_diam,case_outer_height,2,2);
} else if (just_case) {
    case(case_outer_diam,case_outer_height,2,2);
}


module case_deckel(case_diam,lip_height,ceil_thickness,wall_thickness) {

translate([0,0,lip_height-ceil_thickness])
linear_extrude(height=ceil_thickness)
offset(r=wall_thickness/2+hole_extra*2)
case_shape(case_diam);

linear_extrude(height=lip_height)
difference(){
    offset(r=wall_thickness+hole_extra*2)
    case_shape(case_diam);
    offset(r=hole_extra*2)
    case_shape(case_diam);
}

}

if (show_all()) {
    
    color("SkyBlue",0.2)
    translate([0,0,60+gear_height+gear_case_spacing+case_outer_height-6+2])
    case_deckel(case_outer_diam,6,1.5,1.6);
    
    
} else if (just_case_lid) {
    case_deckel(case_outer_diam,6,1.5,1.6);
}

module case_seal(case_diam,lip_height,wall_thickness,seal_thickness) {

    difference(){
        linear_extrude(height=lip_height/2)
        difference(){
            offset(r=wall_thickness+hole_extra*2+seal_thickness)
            case_shape(case_diam);
            offset(r=hole_extra*2-seal_thickness)
            case_shape(case_diam);
        }

        translate([0,0,seal_thickness])
        linear_extrude(height=lip_height)
        difference(){
            offset(r=wall_thickness+hole_extra*2)
            case_shape(case_diam);
            offset(r=hole_extra*2)
            case_shape(case_diam);
        }
    }
}

if (show_all()) {
    
    color("White")
    translate([0,0,60+gear_height+gear_case_spacing+case_outer_height-6+2])
    case_seal(case_outer_diam,6,1.6,0.8);
    
    
} else if (just_case_seal) {
    case_seal(case_outer_diam,6,1.6,0.8);
}



module power_reg(just_feet = false) {
    pr_width = 21.5;
    pr_length = 43.5; 
    pr_height = 15;
    
    translate([-pr_length/2,-pr_width/2,4])
    {
        if (!just_feet) {
            cube([pr_length,pr_width,pr_height]);    
        } 
        translate([6.75,pr_width-2.75,-4])
        difference(){
            cylinder(d=5,h=4,$fn=18);
            translate([0,0,-1])
            cylinder(d=2.5+hole_extra,h=6,$fn=18);
        }
        translate([pr_length-6.75,2.75,-4])
        difference(){
            cylinder(d=5,h=4,$fn=18);
            translate([0,0,-1])
            cylinder(d=2.5+hole_extra,h=6,$fn=18);
        }        
    }   
}


module motor_driver(just_feet = false) {
    md_width = 43.5;
    md_length = 43.5; 
    md_height = 26.5;
    
    translate([-md_length/2,-md_width/2,4])
    {
        if (!just_feet) {
            cube([md_length,md_width,md_height]);    
        } 
        translate([3.5,3.5,-4])
        difference(){
            cylinder(d=5,h=4,$fn=18);
            translate([0,0,-1])
            cylinder(d=2.5+hole_extra,h=6,$fn=18);
        }
        translate([3.5,md_width-3.5,-4])
        difference(){
            cylinder(d=5,h=4,$fn=18);
            translate([0,0,-1])
            cylinder(d=2.5+hole_extra,h=6,$fn=18);
        }        
        translate([md_length-3.5,md_width-3.5,-4])
        difference(){
            cylinder(d=5,h=4,$fn=18);
            translate([0,0,-1])
            cylinder(d=2.5+hole_extra,h=6,$fn=18);
        }
        translate([md_length-3.5,3.5,-4])
        difference(){
            cylinder(d=5,h=4,$fn=18);
            translate([0,0,-1])
            cylinder(d=2.5+hole_extra,h=6,$fn=18);
        }        
    }   
}

module arduino_nano(just_feet = false) {
    md_width = 19;
    md_length = 44.5; 
    md_height = 5;
    
    translate([-md_length/2,-md_width/2,4])
    {
        if (!just_feet) {
            cube([md_length,md_width,md_height]);    
        } 
        translate([2,2,-3])
        cylinder(d=2.5,h=3,$fn=18);

        translate([2,md_width-2,-3])
        cylinder(d=2.5,h=3,$fn=18);

        translate([md_length-2,md_width-2,-3])
        cylinder(d=2.5,h=3,$fn=18);

        translate([md_length-2,2,-3])
        cylinder(d=2.5,h=3,$fn=18);
    }   
}


if (show_all()) {
    color("RoyalBlue",0.2)
    translate([6,64.5,60+gear_height+gear_case_spacing+2])
    rotate([0,0,35])
    power_reg();
    
    color("RoyalBlue",0.2)
    translate([3,-17,60+gear_height+gear_case_spacing+2])
    rotate([0,0,-20])
    motor_driver();

    color("RoyalBlue",0.2)
    translate([-15,22,60+gear_height+gear_case_spacing+2])
    rotate([0,0,35])
    arduino_nano();    
} else if (just_etronics) {
    translate([50,0,0])
    power_reg();
    motor_driver();
    translate([-50,0,0])
    arduino_nano();
}



module holder_base() {
    base_floor = 2;
    difference(){
        union(){
            translate([-20,-40,-base_floor])
            cube([40,95,14+base_floor]);    
            translate([-70,-20,-base_floor])
            cube([140,40,14+base_floor]);
            translate([-30,10,-base_floor])
            cube([60,45,14+base_floor]);
        }
        piping();
        translate([10,-30,-base_floor-1]) union() {
            cylinder(d=10+hole_extra,h=6.5+1,$fn=27);
            cylinder(d=6+hole_extra,h=36,$fn=27);
        }
        translate([-10,-30,-base_floor-1]) union() {
            cylinder(d=10+hole_extra,h=6.5+1,$fn=27);
            cylinder(d=6+hole_extra,h=36,$fn=27);
        }
        translate([20,45,-base_floor-1]) union() {
            cylinder(d=10+hole_extra,h=6.5+1,$fn=27);
            cylinder(d=6+hole_extra,h=36,$fn=27);
        }
        translate([-20,45,-base_floor-1]) union() {
            cylinder(d=10+hole_extra,h=6.5+1,$fn=27);
            cylinder(d=6+hole_extra,h=36,$fn=27);
        }
    }
    
}

if (show_all()) {
    color("Orange")
    holder_base();
} else if (just_holder_base) {
    render()
    holder_base();
}

module holder_stand() {
    render()
    difference() {
        union() {
            difference(){
                union(){
                    difference(){
                        translate([0,0,34])
                        linear_extrude(height=40)
                        case_shape(case_outer_diam);

                        translate([21.25,-50,0])
                        cube([50,150,100]);

                        translate([-30-50,-50,0])
                        cube([50,150,100]);

                        translate([valve_axis_distance/2,0,10])
                        cylinder(d=valve_axis_distance+15,h=70,$fn=72);

                        translate([-valve_axis_distance/2,0,10])
                        cylinder(d=valve_axis_distance+15,h=70,$fn=72);    
                    }

                    translate([-20,-47.5,14])
                    cube([40,50,40]);

                    translate([-20,0,14+20])
                    cube([40,65,20]);
                }

                translate([-50,94,35])
                rotate([0,90,0])
                cylinder(d=78,h=100,$fn=72);

                translate([-50,-67.1,14])
                scale([1,0.7,1.54])
                rotate([0,90,0])
                cylinder(d=78,h=100,$fn=144);
            }
            union() {
                translate([-30,-40,14])
                cube([17,95,27]);

                translate([30-17,-40,14])
                cube([17,95,27]);

                translate([-20,-40,14])
                cube([40,65,27]);
            }
        }

        translate([20,-55,13])
        cube([17,35,70]);

        translate([-20-17,-55,13])
        cube([17,35,70]);

        translate([10,-30,-2-1]) union() {
            cylinder(d=10+hole_extra,h=6.5+1,$fn=27);
            cylinder(d=6+hole_extra,h=40,$fn=27);
        }

        translate([-10,-30,-2-1]) union() {
            cylinder(d=10+hole_extra,h=6.5+1,$fn=27);
            cylinder(d=6+hole_extra,h=40,$fn=27);
        }

        translate([20,45,-3]) union() {
            cylinder(d=10+hole_extra,h=6.5+1,$fn=27);
            cylinder(d=6+hole_extra,h=40,$fn=27);
        }

        translate([-20,45,-3]) union() {
            cylinder(d=10+hole_extra,h=6.5+1,$fn=27);
            cylinder(d=6+hole_extra,h=40,$fn=27);
        }


        translate([10,-30-12,14+2])
        union() {
            translate([-(10+hole_extra)/2,0,0])
            cube([10+hole_extra,20,5+hole_extra]);

            translate([0,20,5+hole_extra])
            difference(){
            rotate([90,0,0])
            cylinder(d=10+hole_extra,h=20,$fn=36);
            translate([-10,-30,-10])
            cube([20,35,10]);
            }
        }

        translate([-10,-30-12,14+2])
        union() {
            translate([-(10+hole_extra)/2,0,0])
            cube([10+hole_extra,20,5+hole_extra]);

            translate([0,20,5+hole_extra])
            difference(){
            rotate([90,0,0])
            cylinder(d=10+hole_extra,h=20,$fn=36);
            translate([-10,-30,-10])
            cube([20,35,10]);
            }
        }
        
        translate([-11,45,14+2])
        rotate([0,0,90])
        union() {
            translate([-(10+hole_extra)/2,0,0])
            cube([10+hole_extra,20,5+hole_extra]);

            translate([0,20,5+hole_extra])
            difference(){
            rotate([90,0,0])
            cylinder(d=10+hole_extra,h=20,$fn=36);
            translate([-10,-30,-10])
            cube([20,35,10]);
            }
        }

        translate([31,45,14+2])
        rotate([0,0,90])
        union() {
            translate([-(10+hole_extra)/2,0,0])
            cube([10+hole_extra,20,5+hole_extra]);

            translate([0,20,5+hole_extra])
            difference(){
            rotate([90,0,0])
            cylinder(d=10+hole_extra,h=20,$fn=36);
            translate([-10,-30,-10])
            cube([20,35,10]);
            }
        }

        translate([-33,100,42])
        rotate([90,0,0])
        cylinder(d=20,h=150,$fn=36);

        translate([33,100,42])
        rotate([90,0,0])
        cylinder(d=20,h=150,$fn=36);

        piping();

        translate([0,-45,62]) union() {
            translate([0,0,-40])
            cylinder(d=10+hole_extra,h=6.5+1+40,$fn=50);
            cylinder(d=6+hole_extra,h=35,$fn=50);
        }

        translate([0,70,62]) union() {
            translate([0,0,-35])
            cylinder(d=10+hole_extra,h=6.5+1+35,$fn=27);
            cylinder(d=6+hole_extra,h=35,$fn=27);
        }

    }
}

        


if (show_all()) {
    color("Moccasin")
    holder_stand();
} else if (just_holder_stand) {
    holder_stand();
}







