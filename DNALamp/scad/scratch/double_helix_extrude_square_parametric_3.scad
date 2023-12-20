include <helix_extrude.scad>

// TODO: include LEDPithch = 16.25

eps = 0.001;

precision = 50;

axelRadius = 10;
pitch = 180;
angle = 360;
numTurns = 2;
height = pitch * numTurns;

trapezoidHeight = 30;

outerHelixSquare = 8;
innerHelixSquare = 6;

numSteps = 15;
numBases = numSteps * numTurns;
basesRadius = 1;
dnaRadius = 30.5;

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
translate([0, 0, 0]) {

    difference(){       // Create helix ladder holes
        union() {
            
        //RHS helix
        difference() {  // Hollows out helix path
            helix_extrude(angle=angle * numTurns, height=height, $fn=precision) {
                translate([dnaRadius, 0, 0]) {
                    square(outerHelixSquare, center= true);
                }
            }
             helix_extrude(angle=angle * numTurns + eps, height=height, $fn=precision) {
                translate([dnaRadius, 0, 0]) {
                    square(innerHelixSquare, center= true);
                }
            }
        }
        
        //LHS helix
        difference() {  // Hollows out helix path
            helix_extrude(angle=angle * numTurns, height=height, $fn=precision) {
                translate([-dnaRadius, 0, 0]) {
                    square(outerHelixSquare, center= true);
                }
            }
            
            helix_extrude(angle=360 * numTurns + eps, height=height, $fn=precision) {
                translate([-dnaRadius, 0, 0]) {
                    square(innerHelixSquare, center= true);
                }
            }
        }

	}   /* Helix Union - end */
    
    // Holes for side-glow fiber; double helix bases
    for (i=[1:numBases])
    translate([0, 0, i*15])           //3.25        // TODO: add equation
        rotate([0, 90, i*30])        //29.25        // TODO: use equation: (180/PI()) * ((2*PI()) / A15)
            cylinder(r=basesRadius, h=dnaRadius * 2, center=true, $fn=precision);
    
    }   /* Helix Difference - end */
}
