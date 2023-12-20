include <helix_extrude.scad>

precision = 20;

axelRadius = 10;
height = 200;
angle = 360 * 5;


ledPitch = 16.25;
dnaRadius = 20;

// DNA double-helix
/*
translate([0, 0, 0]) {
	dnaRadius = 20;

	union() {
		for (i=[1:60])
			translate([0, 0, i*3.25])
				rotate([0, 90, i*29.25])
					cylinder(r=1, h=dnaRadius * 2, center=true, $fn=precision);
	}
}
*/
function toRadians(degrees) = (PI / 180) * degrees;
function toDegrees(radians) = (180 / PI) * radians;
function circum(radius) = 2 * PI * radius;
echo("circum: ", circum(dnaRadius));
echo("numSteps", circum(dnaRadius) / ledPitch);

// Green circle
translate([0, 0, 6*3.25]) {
    color("LimeGreen", 1.0)
        circle(r = dnaRadius);
}

zFunk = 29.25;
yRot = 90;
echo("zFunk: ", zFunk);
translate([0, 0, 0]) {
    //dnaRadius = 20;
    for (i=[1:12])
        translate([0, 0, i*3.25])
            rotate([0, 90, i*29.25])
                cylinder(r=1, h=dnaRadius * 2, center=true, $fn=precision);
    /*
    translate([0, 0, 0*3.25])
        rotate([0, yRot, 0*zFunk])
            cylinder(r=1, h=dnaRadius * 2, center=true, $fn=precision);
       
    
    translate([0, 0, 1*3.25])
        rotate([0, yRot, 1*zFunk])
            cylinder(r=1, h=dnaRadius * 2, center=true, $fn=precision);
    
    
    translate([0, 0, 2*3.25])
        rotate([0, yRot, 2*zFunk])
            cylinder(r=1, h=dnaRadius * 2, center=true, $fn=precision);
    
    
    translate([0, 0, 3*3.25])
        rotate([0, yRot, 3*zFunk])
            cylinder(r=1, h=dnaRadius * 2, center=true, $fn=precision);

    translate([0, 0, 4*3.25])
        rotate([0, yRot, 4*zFunk])
            cylinder(r=1, h=dnaRadius * 2, center=true, $fn=precision);
    
    translate([0, 0, 5*3.25])
        rotate([0, yRot, 5*zFunk])
            cylinder(r=1, h=dnaRadius * 2, center=true, $fn=precision);
            */
}