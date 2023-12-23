//include <lib/HelixLib/helix_extrude.scad>
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

/** Lamp base */
lampBaseHeight = 28;                // PARAM
lampBaseRadius = 2 * dnaRadius;
lambBaseWallThickness = 3;          // PARAM


echo("numRungs: ", numRungs);
echo("dnaRadius: ", dnaRadius);
echo("stepsPerTurn: ", stepsPerTurn);

/** Helix paths - defined so we have points */
rhsHelixOuter = helix(l=height, turns=numTurns, r=dnaRadius);
rhsHelixInner = helix(l=height+eps, turns=numTurns, r=dnaRadius);
lhsHelixOuter = helix(l=height, turns=numTurns, r=-dnaRadius);
lhsHelixInner = helix(l=height+eps, turns=numTurns, r=-dnaRadius);


// An application of the minimum rotation
// Given two points p0 and p1, draw a thin cylinder with its
// bases at p0 and p1
// from: https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Tips_and_Tricks#Drawing_%22lines%22_in_OpenSCAD
module line(p0, p1, diameter=1) {
    v = p1-p0;
    translate(p0)
        // rotate the cylinder so its z axis is brought to direction v
        multmatrix(vector_angle([0,0,1],v))
            cylinder(d=diameter, h=norm(v), $fn=4);
}

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
           //difference() {
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
                        cylinder(h=dnaRadius * 2, r=rungDiameter / 2, center=true);
                
              }
        } 
    }
}

// DNA Lamp base
// TODO: Add holes for buttons and wires. Use a cylinder
// TODO: Add mounts for joining the base with the double helix structure
module lampBase(height, radius, wallThickness) {
    let (
        //wallThickness = outerRadius - innerRadius,
        outerRadius = radius,
        innerRadius = outerRadius - wallThickness,
        zPos = -(height / 2)
    ) {
        difference() {
            // Base outer shell
            translate([0, 0, zPos])
                cylinder(r=outerRadius, h=height, center=true);
            
            translate([0, 0, zPos - wallThickness])
                cylinder(r=innerRadius, h=height, center=true);
        }
    }
}

// Figuring out the joint
echo("rhsOuterStart: ", rhsHelixOuter[0]);
echo("rhsOuterEnd: ", rhsHelixOuter[len(rhsHelixOuter)-1]);

color ("red") line(rhsHelixOuter[0], [rhsHelixOuter[0][0], 0, height+20], 2);


pointsPerTurn = len(rhsHelixOuter)/numTurns;
echo("pointsPerTurn: ", pointsPerTurn);

function getSectionIndexVector(section, pointsPerTurn) =
    [(pointsPerTurn - 3) * section, (pointsPerTurn - 2) * section, (pointsPerTurn - 1) * section];

secIdxVec = getSectionIndexVector(1, pointsPerTurn);
lowSecIdx = secIdxVec[0];
midSecIdx = secIdxVec[1];
highSecIdx = secIdxVec[2];
//lowSecIdx = pointsPerTurn - 3;
//midSecIdx = pointsPerTurn - 2;
//highSecIdx = pointsPerTurn - 1;

echo("lowSecIdx: ", lowSecIdx);
echo("midSecIdx: ", midSecIdx);
echo("highSecIdx: ", highSecIdx);

secAngle = vector_angle(rhsHelixOuter[lowSecIdx], rhsHelixOuter[midSecIdx], rhsHelixOuter[highSecIdx]);
secAxis = vector_axis(rhsHelixOuter[lowSecIdx], rhsHelixOuter[midSecIdx], rhsHelixOuter[highSecIdx]);
echo("secAngle: ", secAngle);
echo("secAxis: ", secAxis);


echo("sectionIdxes: ", getSectionIndexVector(1, pointsPerTurn));


module helixSectionJoint(rhsHelix){ //(l,t,r){ //(height, angle, turns, r) {
    
    translate([0, 0, 0]) {
        let (
//            rhsHelixOuter = helix(l=l, turns=t, r=r),
//            rhsHelixInner = helix(l=l+eps, turns=t, r=r),
//            lhsHelixOuter = helix(l=l, turns=t, r=-r),
//            lhsHelixInner = helix(l=l+eps, turns=t, r=-r)
        ) {
           union() {
           //difference() {
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
              }
        } 
    }
}

// Figuring out the joing
//translate([0,0, (height / 2) - 4]) {
//translate(rhsHelixOuter[lowSecIdx]) {
translate([0,0,0) {
//translate(secAxis) {
    color("blue")
        rotate([0 ,0 , 0])
            path_sweep(square(outerHelixSquare, false), slice(rhsHelixOuter, lowSecIdx, highSecIdx));
            //path_sweep(square(outerHelixSquare, true), slice(rhsHelixOuter, 0, 3));
            //path_sweep(square(outerHelixSquare, true), slice(rhsHelixOuter, lowSecIdx+1, highSecIdx+2));
    
}

// Mid point reference square
translate([0,0,height/2]) {
    square(dnaRadius*4, true);
}
// Render it
union() {
    dnaLampHelix();
    lampBase(lampBaseHeight, lampBaseRadius, lambBaseWallThickness);
}
//dnaLampHelix(l=height, t=numTurns, r=dnaRadius);

// TODO: Define render for exporting model. Set convexity to 10
//render(convexity=10){
//  dnaLampHelix(l=height, t=numTurns, r=dnaRadius);
//}