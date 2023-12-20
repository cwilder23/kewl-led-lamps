include <helix_extrude.scad>

eps = 0.001;

precision = 20;

axelRadius = 10;
height = 200;
angle = 360;
angleScalar = 5;

trapezoidHeight = 30;

outerHelixSquare = 8;
innerHelixSquare = 6;

numBases = 60;
basesRadius = 1;
dnaRadius = 24;

// Module used to create the polygon
// (to make it easier to re-use with rotate_extrude)
module helixPolygon() {
	// Move the trapezoid away from the center
	translate([axelRadius, 0, 0]) {
		// Simple trapezoid
		polygon([
			[0, 0],
			[20, 10],
			[20, trapezoidHeight-10],
			[0, trapezoidHeight]
		]);
	}
}

// DNA double-helix
translate([0, 150, 0]) {

difference(){       // Create helix ladder holes
	union() {
        
        //RHS helix
        difference() {  // Hollows out helix path
            helix_extrude(angle=angle * angleScalar, height=height, $fn=precision) {
                translate([dnaRadius, 0, 0]) {
                    square(outerHelixSquare, center= true);
                }
            }
             helix_extrude(angle=angle * angleScalar + eps, height=height, $fn=precision) {
                translate([dnaRadius, 0, 0]) {
                    square(innerHelixSquare, center= true);
                }
            }
        }
        
        //LHS helix
        difference() {  // Hollows out helix path
            helix_extrude(angle=angle * angleScalar, height=height, $fn=precision) {
                translate([-dnaRadius, 0, 0]) {
                    square(outerHelixSquare, center= true);
                }
            }
            
            helix_extrude(angle=360 * angleScalar + eps, height=height, $fn=precision) {
                translate([-dnaRadius, 0, 0]) {
                    square(innerHelixSquare, center= true);
                }
            }
        }

	}   /* Helix Union - end */
    
    // Holes for side-glow fiber; double helix bases
    for (i=[1:numBases])
    translate([0, 0, i*3.25])           //3.25
        rotate([0, 90, i*29.25])        //29.25
            cylinder(r=basesRadius, h=dnaRadius * 2, center=true, $fn=precision);
    
    }   /* Helix Difference - end */
}
