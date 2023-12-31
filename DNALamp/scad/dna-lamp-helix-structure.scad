include <lib/HelixLib/helix_extrude.scad>
include <BOSL2/fnliterals.scad>
include <BOSL2/std.scad>
include <BOSL2/strings.scad>
include <BOSL2/drawing.scad>
/*
    TODO: Document hardware used: LED Strip models, MCU, powersupply, side-glow optics, etc.
    TODO: Set helix bar size using the LED strip width. Inner size will be: ledStripWidth + tolerance
    TODO: Use these vars to compute bar size: wallThickness, hollowSize
    TODO: Determine rungDiameter
 */

/* 
    Custom function 
    
    TODO: Move to their own file
*/
// Round a number to the specific decimal precision.
// Required Lib(s):
//  BOSL2
function round_to_decimal(number, precision) = 
    parse_float(format_fixed(number, precision));
    
function archLength(angle, radius) = (2 * PI * radius * angle) / 360;
function toRadians(degrees) = (PI / 180) * degrees;
function toDegrees(radians) = (180 / PI) * radians;

/* Global Variables */

/** Tolerances */
eps = 0.001;            // Epsilon - delta used for open spaces in shapes

/** Rendering */
precision = $preview ? 24 : 72;             // Keep to multiples of 4
$fn = precision;

/**  LED strip specs */
ledPitch = 16;                  // PARAM distance between LED components on the LED strip 

/**  Helix structure */
stepsPerTurn = 12;              // PARAM. Selected from "double-helix-analysis-for-parametric-design!finding Coeffs"
height = 360;                   // PARAM
numTurns = 2;                   // PARAM
pitch = height / numTurns;
dnaRadius=round_to_decimal((stepsPerTurn * ledPitch) / (2 * PI), 2);

/** Helix bars shape */
outerHelixSquare = 8;           // PARAM
innerHelixSquare = 6;           // PARAM

/** Helix rungs */
rungDiameter = 1;                // PARAM. 
zStepSize = pitch / stepsPerTurn;
numRungs = zStepSize * numTurns;
arcTheta=toDegrees((2*PI) / stepsPerTurn);



// Generate the helix path. Necessary if we want to be able 
// to get positional information. Also will add support for 
// anchoring objects to the paht.
// TODO: Use the helix() method to draw
module helixPath(l,t,r){ //(height, angle, turns, r) {
    // path = helix(l|h, [turns=], [angle=], r=|r1=|r2=, d=|d1=|d2=);
    translate([25, 0, 0]) {
        let (
            path1 = helix(l=l, turns=t, r=r),
            path2 = helix(l=l, turns=t, r=-r)
        ) {
        //let (path = helix(l=height, turns=numTurns, r=dnaRadius)) {      
            stroke(path1, dots=true, dots_color="blue");
            //echo("helix path 1: ", path1);
            stroke(path2, dots=true, dots_color="blue");
            path_sweep(square(25, true), path2);
            //echo("helix path 2: ", path2);
        }
    }
}

// DNA double-helix
module dnaLampHelix() {      

    translate([0, 0, 0]) {

        difference(){       // Creates helix ladder holes
            union() {       // Combines helixes
                
            //RHS helix
            difference() {  // Hollows out RHS helix path
                helix_extrude(angle=360 * numTurns, height=height) {
                    translate([dnaRadius, 0, 0]) {
                        square(outerHelixSquare, center= true);
                    }
                }
                 helix_extrude(angle=360 * numTurns + eps, height=height) {
                    translate([dnaRadius, 0, 0]) {
                        square(innerHelixSquare, center= true);
                    }
                }
            }
            
            //LHS helix
            difference() {  // Hollows out LHS helix path
                helix_extrude(angle=360 * numTurns, height=height) {
                    translate([-dnaRadius, 0, 0]) {
                        square(outerHelixSquare, center= true);
                    }
                }
                
                helix_extrude(angle=360 * numTurns + eps, height=height) {
                    translate([-dnaRadius, 0, 0]) {
                        square(innerHelixSquare, center= true);
                    }
                }
            }

        }   /* Helix Union - end */
        
        // Holes for side-glow fiber; double helix rungs
        for (i=[1:numRungs])
        translate([0, 0, i * zStepSize])           //15
            rotate([0, 90, i * arcTheta])          //30
                cylinder(r=rungDiameter / 2, h=dnaRadius * 2, center=true);
        
        }   /* Helix Difference - end */
    }
}

// Render it
dnaLampHelix();
//translate([25, 0, 0]) {
    helixPath(l=height, t=numTurns, r=dnaRadius);
//}

// TODO: Define render for exporting model. Set convexity to 10
//render(convexity=10){
//  dnaLampHelix();
//}