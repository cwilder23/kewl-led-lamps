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
height = 360;                   // PARAM
numTurns = 2;                   // PARAM
pitch = height / numTurns;
stepsPerTurn = pitch / ledPitch;
//dnaRadius = round_to_decimal((stepsPerTurn * ledPitch) / (2 * PI), 2);
dnaRadius = 28.65;              // PARAM


/** Helix bars shape */
outerHelixSquare = 8;           // PARAM
innerHelixSquare = 6;           // PARAM

/** Helix rungs */
rungDiameter = 3;                // PARAM
zStepSize = ledPitch;
numRungs = floor(height / ledPitch);
arcTheta=toDegrees((2*PI) / stepsPerTurn);

echo("numRungs: ", numRungs);
echo("dnaRadius: ", dnaRadius);
echo("stepsPerTurn: ", stepsPerTurn);

/** Helix paths - defined so we have points */
rhsHelixOuter = helix(l=height, turns=numTurns, r=dnaRadius);
rhsHelixInner = helix(l=height+eps, turns=numTurns, r=dnaRadius);
lhsHelixOuter = helix(l=height, turns=numTurns, r=-dnaRadius);
lhsHelixInner = helix(l=height+eps, turns=numTurns, r=-dnaRadius);


// DNA double-helix
// Generate the helix path. Necessary if we want to be able 
// to get positional information. Also will add support for 
// anchoring objects to the paht.
// TODO: Use the helix() method to draw
module dnaLampHelix(){ //(l,t,r){ //(height, angle, turns, r) {
    
    translate([0, 0, 0]) {
        let (
//            rhsHelixOuter = helix(l=l, turns=t, r=r),
//            rhsHelixInner = helix(l=l+eps, turns=t, r=r),
//            lhsHelixOuter = helix(l=l, turns=t, r=-r),
//            lhsHelixInner = helix(l=l+eps, turns=t, r=-r)
        ) {
           union() {
               union() {
                   difference() {
                        path_sweep(square(outerHelixSquare, true), rhsHelixOuter);
                        path_sweep(square(innerHelixSquare, true), rhsHelixInner);
                        //echo("helix path 1 (RHS): ", rhsHelixOuter);
                    } 
                    
                    
                    difference() {
                        path_sweep(square(outerHelixSquare, true), lhsHelixOuter);
                        path_sweep(square(innerHelixSquare, true), lhsHelixInner);
                        //echo("helix path 2 (LHS): ", lhsHelix);
                    }
                }
                // Holes for side-glow fiber; double helix rungs
                for (i=[1:numRungs])
                translate([0, 0, i * zStepSize])           //15
                    rotate([0, 90, i * arcTheta])          //30
                        cylinder(r=rungDiameter / 2, h=dnaRadius * 2, center=true);
                
              }
        } 
    }
}

/*
    TODO: Attemptng to figure out how to draw a shape along, the path of the helix that, that will be the base for the join
https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Tips_and_Tricks#Minimum_rotation_problem
*/

//echo("helix path 1 (RHS): ", rhsHelixOuter);
echo("helix path 1 (RHS) len: ", len(rhsHelixOuter));
echo("helix path 1 (RHS) mid: ", rhsHelixOuter[len(rhsHelixOuter) / 2]);
echo("helix path 1 (RHS) mid: ", rhsHelixOuter[(len(rhsHelixOuter) / 2) - 1]);


//a=rhsJointUpper;
//b=rhsJointLower;
function angleBetween2Points(a,b)=atan2(norm(cross(a,b)),a*b);

// Find the unitary vector with direction v. Fails if v=[0,0,0].
function unit(v) = norm(v)>0 ? v/norm(v) : undef; 
// Find the transpose of a rectangular matrix
function transpose(m) = // m is any rectangular matrix of objects
  [ for(j=[0:len(m[0])-1]) [ for(i=[0:len(m)-1]) m[i][j] ] ];
// The identity matrix with dimension n
function identity(n) = [for(i=[0:n-1]) [for(j=[0:n-1]) i==j ? 1 : 0] ];

// computes the rotation with minimum angle that brings a to b
// the code fails if a and b are opposed to each other
function rotate_from_to(a,b) = 
    let( axis = unit(cross(a,b)) )
    axis*axis >= 0.99 ? 
        transpose([unit(b), axis, cross(axis, unit(b))]) * 
            [unit(a), axis, cross(axis, unit(a))] : 
        identity(3);


rhsJointUpper = rhsHelixOuter[len(rhsHelixOuter) / 2];
rhsJointLower = rhsHelixOuter[(len(rhsHelixOuter) / 2) - 1];
translate(rhsJointUpper)
    rotate( [toDegrees(angleBetween2Points(rhsJointUpper,rhsJointLower)), toDegrees(angleBetween2Points(rhsJointUpper,rhsJointLower))/2, 0])
    square(50, true);



echo("arcTheta: ", arcTheta);
echo("computed: ", toDegrees(angleBetween2Points(rhsJointUpper,rhsJointLower)));
//echo("computed_2: ", rotate_from_to(rhsJointUpper,rhsJointLower));
echo("unitVector: ", unit(rhsJointUpper));


// Render it
dnaLampHelix();
//dnaLampHelix(l=height, t=numTurns, r=dnaRadius);

// TODO: Define render for exporting model. Set convexity to 10
//render(convexity=10){
//  dnaLampHelix(l=height, t=numTurns, r=dnaRadius);
//}