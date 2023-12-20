module helix_extrude(angle=360, height=100) {
	precision = $fn ? $fn : 24;

	// Thickness of polygon used to create an helix segment
	epsilon = 0.001;

	// Number of segments to create.
	//   I reversed ingenering rotate_extrude
	//   to provide a very similar behaviour.
	nbSegments = floor(abs(angle * precision / 360));

	module helix_segment() {
		// The segment is "render" (cached) to save (a lot of) CPU cycles.
		render() {
			// NOTE: hull() doesn't work on 2D polygon in a 3D space.
			//   The polygon needs to be extrude into a 3D shape
			//   before performing the hull() operation.
			//   To work around that problem, we create extremely
			//   thin shape (using linear_extrude) which represent
			//   our 2D polygon.
			hull() {
				rotate([90, 0, 0])
					linear_extrude(height=epsilon) children();

				translate([0, 0, height / nbSegments])
					rotate([90, 0, angle / nbSegments])
						linear_extrude(height=epsilon) children();
			}
		}
	}

	union() {
		for (a = [0:nbSegments-1])
			translate([0, 0, height / nbSegments * a])
				rotate([0, 0, angle / nbSegments * a])
					helix_segment() children();
	}
}


/*
LEDs specs:
    - 60 LEDs/m
    - inside LED N to inside LED N+1: 12 mm
    - LED component size (w): ~4.867
    - Estimated dist between LEDs (TODO: verify): 12mm + 4.9mm ~= 16.9mm
        - LED N center to LED N+1 center 
        - trying: 16.25 mm

numBases per segment
    - Need to figure out the bases z-axis rotation coef

bases Z position coef (basesZPosCoef):
    - basesZPosCoeff -> The space between each base.
        - Multiply to increase space between
        - function of height or i-th pos
    - constants or input values
        - height
        - helixSegments
    - Needs to be computed;
        - helixLength
        - pitch (p) => 
            - equation: p = Height / helixSegments
                - p = 200 / 3
        - numBases
            - equation: helixLength / ledDistance
        
bases Z rotational coef (basesZRotCoef):
    - basesZRotCoef -> The Z-axis rotational change for each base; how the bases rotate with the helixes
        - function of height or i-th pos
        
Value set 1:
    - height = 200
    - angle = 360
    - helixSegments = 1
    - basesZPosCoef: 3.25 * 5 => 16.25
    - basesZRotCoef: 29.25
    - numBases = 60;
    - Delta
    - Status:
        - basesZRotCoef aligns perfectly

*/
/*
********************************************************************
* Helix equations                                                  *
*   from: https://www.redcrab-software.com/en/Calculator/Helix)    *
********************************************************************
 -----------------------
| Variables             |
 -----------------------
r	Radius
h	Height of a turn
t	Number of turns
k	Slope
κ	Curvature (kappa)
w	Torsion
s	Arc length       
*/
/* 
  SLOPE:  k = h / (2πr) 
*/
function helixSlope(turnHeight, radius) = turnHeight / (2 * PI * radius);

/*
  CURVATURE:  κ = 1 / r(1 + k²)
*/
function helixCurvature(slope, radius) = 1 / (radius * (1 + pow(slope, 2)));

/*
  TORSION:    w = k / r(1 + k²)

  The torsion kappa is the measure how much a wire is twisted when 
  it is formed into a helix.
*/
function helixTorsion(slope, radius) = slope / (radius * (1 + pow(slope, 2)));

/*
    ARC LENGTH: s = (2πr) * sqrt(1 + k²) * t
*/
function helixArcLength(radius, numTurns, slope) = (2 * PI * radius) * sqrt(1 + pow(slope, 2)) * numTurns;

/*
**************************************************************************
* Formula for calculating an arc of a circle                             *
*   from: https://www.redcrab-software.com/en/Calculator/Circular-Arc    *
**************************************************************************

An arc is part of the outline of a circle. It is determined by two straight 
lines starting from the center point that intersect the circular line 
at a certain angle α.

Since a circle has a circumference of 360 degrees, the arc length l can be 
calculated using the following formula:

 -----------------------
| Variables             |
 -----------------------
r	Radius
l	Arc length  
α   angle of intersection
*/

/*
    α = (360 * l) / (2πr)
 */
function archAngleOfIntersect(archLen, radius) = (360 * archLen) / (2 * PI * radius);

/*
    l = (2πrα) / 360
    
    angle - arch angle of intersection in degrees
*/
function archLength(angle, radius) = (2 * PI * radius * angle) / 360;

ledPitch = 16.25;           // LED spec

eps = 0.001;

precision = 20;
height = 400;
angle = 360;
helixSegments = 5;    // aka turns

outerHelixSquare = 8;
innerHelixSquare = 6;

//numBases = 60;      //60
basesRadius = 1;
helixRadius = 14;

pitch = (height / helixSegments);
helixCircum = (2 * PI * helixRadius);
helixLength = (helixSegments * sqrt(pow(helixCircum, 2) + pow(pitch, 2)));
numBases = round((pitch * helixSegments) / ledPitch);


basesZPosCoef = 16.25;          //3.25      --> angle=(360 *5), numBases=60, height=200
basesZRotCoef = 90/4;//29.25 * helixSegments;      //29.25     --> angle=(360 *5), numBases=60, height=200
// ----------------------------------------
// DEBUGGING - BEGIN

echo("\n");
echo("----------------------------------");
echo(" Helix Module vars ");
echo("----------------------------------");
helixAngle = (angle * helixSegments);
helixExtrudePrecision = $fn ? $fn : 24;
nbSegments = floor(abs(helixAngle * helixExtrudePrecision / 360));
heightPerNBSeg = height / nbSegments;
anglePerNBSeg = angle / nbSegments;

echo("nbSegments: ", nbSegments);
echo("helixExtrudePrecision: ", helixExtrudePrecision);
echo("helixAngle: ", helixAngle);
echo("heightPerNBSeg: ", heightPerNBSeg);
echo("anglePerNBSeg: ", anglePerNBSeg);
//for (a = [0:nbSegments-1]) {
//    echo(a, ": trans([0, 0, ", height / nbSegments * a, "])");
//    echo(a, ": rot([0, 0, ", angle / nbSegments * a, "])");
//}
echo("Delta trans heightPerNBSeg: ", (heightPerNBSeg * 6) - (heightPerNBSeg * 5));
echo("Delta rot anglePerNBSeg: ", (anglePerNBSeg * 6) - (anglePerNBSeg * 5));


echo("\n");
echo("----------------------------------");
echo(" Bases computations ");
echo("----------------------------------");

echo("basesZPosCoef: ", basesZPosCoef);
echo("basesZRotCoef: ", basesZRotCoef);

echo("\n");
echo("----------------------------------");
echo(" Double Helix vars ");
echo("----------------------------------");
echo("angle: ", angle);
echo("helixSegments: ", helixSegments);
echo("pitch: ", pitch);
echo("helixRadius: ", helixRadius);
echo("diameter: ", 2 * helixRadius);
echo("helixCircum: ", helixCircum);
echo("helixLength: ", helixLength);
echo("numBases: ", numBases);

echo("\n");


echo("\n");
echo("----------------------------------");
echo(" Helix equations ");
echo("----------------------------------");
slope = helixSlope(pitch, helixRadius);
echo("helixSlope", slope);
echo("helixCurvature", helixCurvature(slope, helixRadius) );
echo("helixTorsion", helixTorsion(slope, helixRadius) );
helixArchLen = helixArcLength(helixRadius, helixSegments, slope);
echo("helixArcLength", helixArchLen);

echo("\n");
echo("----------------------------------");
echo(" arch equations ");
echo("----------------------------------");
archAoI = archAngleOfIntersect(archLength, helixRadius);
echo("archAngleOfIntersect: ", archAoI);
echo("archLength: ", archLength(archAoI, helixRadius));

echo("\n");

// DEBUGGING - END
// ----------------------------------------
// ----------------------------------------

translate([0, 0, 0]) {
    union() {
        helix_extrude(angle=angle * helixSegments, height=height, $fn=precision) {
            translate([helixRadius, 0, 0]) {
                square(outerHelixSquare, center= true);
            }
        }
        helix_extrude(angle=angle * helixSegments, height=height, $fn=precision) {
            translate([-helixRadius, 0, 0]) {
                square(outerHelixSquare, center= true);
            }
        }
    }
    // Holes for side-glow fiber; double helix bases
    for (i=[1:numBases])
    translate([0, 0, i*ledPitch])           //3.25
        rotate([0, 90, i*basesZRotCoef])        //0, 90, i*29.25]
            cylinder(r=basesRadius, h=helixRadius * 2, center=true, $fn=precision);



}

