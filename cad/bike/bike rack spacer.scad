$fn=50;

fudge = .3;

// Parameters
hatches = 4;              // Number of cylinders in each direction
N = hatches;
diameter = 1 + fudge;     // Cylinder diameter (mm)
gap = 10;                 // Center-to-center spacing (mm)
rack_diam = 10 + fudge;   // diameter of tubes on bike rack
rack_angle = 1.383;       // angle of bike rack taper
length = N * gap;         // size spacer

difference(){
    // support structure
    hull() {
        translate ([fudge,fudge,0]) cube([length-fudge*2,length-fudge*2,diameter*3]);
        h = diameter*3+2.5+ rack_diam*2/3;
            
        translate ([length/2-rack_diam/2,length/2-rack_diam/2,0]) cube([rack_diam,rack_diam,h]);
    }
    
    //contact spaces
    union(){
        // One layer of cylinders along X
        for (y = [gap/2 : gap : length]) {
            hull() {
                translate([0, y, -diameter])
                    rotate([0, 90, 0])
                        cylinder(d=diameter, h=length);
                translate([0, y, diameter*3/2])
                    rotate([0, 90, 0])
                        cylinder(d=diameter, h=length);
            }
        }
        
        // Crossing layer of cylinders along Y
        for (x = [gap/2 : gap : length]) {
            hull() {
                translate([x, 0, -diameter])
                    rotate([-90, 0, 0])
                        cylinder(d=diameter, h=length);
                translate([x, 0, diameter/2])
                    rotate([-90, 0, 0])
                        cylinder(d=diameter, h=length);
            }
        }
        translate([length/2, length/2, (rack_diam/2+diameter*2+3)])
            rotate([rack_angle, 90, 0])
                translate([0, 0, -length])
                cylinder(d=rack_diam, h=length*2);
    }
}