//Licensed under GNU LGPL script for OpenSCAD, fsf.org.
//Written by Gerald Lafreniere, aka spingoogL, thingiverse.com, and printables.com

//Sample polygon
PTL2D=[     [16,-1] , [13,-3] , [13,3]  ,[16,1]   ];

////Sample helix
//union(){
////    cylinder(r=13.5,h=50);
//    helix_extrude( points=PTL2D, pitch=8.5, loops=1, fn=4);
//}

////////////////////////////////////////////
////////////    MODULES         ////////////
////////////////////////////////////////////


//Module to create a helix of given profile points
    //points is a 2D point array, the kind you would use with polygon().
    //pitch is a float type that is the distance from a corresponding pt in the helix the next.
	//+ pitch produces RH twist, - pitch produces LH twist.
    //loops integer that is the number of loops.  Non-integer=undefined results
module helix_extrude( points, pitch, loops, fn){
   //Sort out resolution
    __FN= fn==undef ? $fn : fn;
    _FN= __FN==0 ? 3 : __FN;
   //Change plane from XY to XZ using 3D point system
    P3D=rotate90X3D(points);//Conversion of 2D polygon in to 3D polygon
   //Generate a list of 3D points in a helix
    HelixPointList=_genHelix(ORIGIN=P3D,PITCH=pitch,FN=_FN,N=loops);
//    echo("HelixPointList: ", HelixPointList,"\n\n");
   //Start Cap
    SC=_genCapStart(P3D);
    StartCap=reverse(SC);
   //End Cap
    EndCap=reverse(_genCapEnd(P3D,HelixPointList));
   //Generate a list faces to accompany the HelixPointList
    Middle=flatten(_genFaceMatrix(P3D,HelixPointList));
   //Combine Faces
    FaceMatrix=flatten([StartCap, Middle, EndCap]);
//    echo("FaceMatrix: ", FaceMatrix,"\n\n");
   //Generate the 3D helical object
    if ( pitch > 0 ) polyhedron(HelixPointList, FaceMatrix);
	if ( pitch < 0 ) rotate([180,0,0]) polyhedron(HelixPointList, FaceMatrix);
}

////////////////////////////////////////////
////////////    FUNCTIONS       ////////////
////////////////////////////////////////////
//In alphabetical order


//Removes unwanted nesting of arrays
    //l is input : nested list
    //output : list with the outer level nesting removed
    //this one is cut and pasted from the openscad website
function flatten(l) = [ for (a = l) for (b = a) b ] ;

//returns array of N position Face for the Base segment, given an ORIGIN 3D point list
    //ORIGIN is the 3D polygon point list
    //N is the Nth Face of the segment 
function _genBaseFaceN(ORIGIN, N)=[
    let(
        ABmin=0,
        CDmin=len(ORIGIN),
        ABmax=CDmin-1,
        CDmax=CDmin+ABmax,
        i=N%CDmin,
        A=i,
        B=(A+1)%CDmin,
        C=B+CDmin,
        D=CDmin+A
    )
    [ A , B , C , D ]
];

//Generates a list of faces of the base segment
function _genBaseSegmentFaceMatrix(ORIGIN)=[
    for ( i=[0:1:len(ORIGIN)-1] )
    let(
        Base=_genBaseFaceN(ORIGIN, i)
    )
    flatten(Base)
];

//Face array to close off the end
function _genCapEnd(ORIGIN, PTLIST)=[
    let(
        SCap=flatten(_genCapStart(ORIGIN)),
        Offset=len(PTLIST)-len(ORIGIN),
        AddMatrix=flatten(_genPervasiveMatrix( len(ORIGIN), 1, Offset)),
        ECap=reverse(SCap+AddMatrix)
    )
    ECap
];

//Face array to close off the start
function _genCapStart(ORIGIN)=[[
    for ( i=[len(ORIGIN)-1:-1:0] )
    let(
    )
    i
]];
    


//ORIGIN is a 3D profile
//PTLIST is a patterned point list typically generated with ORIGIN that will be stiched together
function _genFaceMatrix(ORIGIN, PTLIST)=[
    for (  i=[0:1: ( ( len(PTLIST)-len(ORIGIN) ) / len(ORIGIN) ) - 1 ] )//i=[0:len(ORIGIN):len(PTLIST)-len(ORIGIN)]
    let(
    SegmentMatrix= _genSegmentMatrixN(ORIGIN,i)
    )
    flatten(SegmentMatrix)
];

//Creates an array of a patterned list of point in a helix
    //ORIGIN, [x,y,z] start point of the helix.
    //PITCH, length or distance from corresponding points on the helix.
    //FN, integer that serves same purpose as $fn.  Defines number of segments per 1 full turn.
    //N, Number of times to generate the helix, LENGTH=N*PITCH.
    //S will be FN*N. S being the total number of segments
function _genHelix(ORIGIN, PITCH, FN, N)=[
    for ( i=[0:1:(FN*N)] )  // Segment counter
        for ( j=[0:1:len(ORIGIN)-1] )
        let(    // Point counter for point list
            SegmentAngle=360/FN,
            Angle=SegmentAngle * i,
            PPT=getPolarFromCoordinate( [ ORIGIN[j][0] , ORIGIN[j][1] ] ),
            PT=getCoordinateFromPolar( [ PPT[0], PPT[1]+Angle ] ),
            X=PT[0],
            Y=PT[1],
            Z=PITCH * (Angle/360) + ORIGIN[j][2]
        )
    [ X, Y, Z ]
];

//Creates an 2D array with the same value in each cell
    //X is the length of one line in array
    //Y is the number of lines in the array
    //V is the value to be entered in to each cell of the array
function _genPervasiveMatrix(X, Y, V)=[
    for ( i=[0:1:Y-1] )    // Segment counter
    let(    // Point counter for point list
        line=_genPervasiveLine(X,V) 
    )
    line        
];

//Creates a uni-dimensional array with the same value in each cell
    //X is length of line
    //V is the value to be entered in each cell
function _genPervasiveLine(X,V)=[
    for ( i=[0:1:X-1] )
    let(
    )
    V
];

//returns 1 segment (array of faces) at position N
    //ORIGIN is a XZ plane polygon
    //N is the iteration location/position
function _genSegmentMatrixN(ORIGIN, N)=[
    let(
        BaseSegmentMatrix=_genBaseSegmentFaceMatrix(ORIGIN),
        AdditionMatrix=_genPervasiveMatrix(4, (len(ORIGIN)) , (len(ORIGIN)*N) ),
        SegmentMatrixN=BaseSegmentMatrix+AdditionMatrix
    )
    SegmentMatrixN
];

//Low budget function. Returns [X,Y] position of polar points.
    //PPT is a Polar PoinT in the form of [ Radius , Angle ] from [0,0] on XY plane.  
function getCoordinateFromPolar(PPT)=
    let(
        X=cos(PPT[1])*PPT[0],
        Y=sin(PPT[1])*PPT[0]
    )
    [X,Y]
;

//Low budget function. Returns a XY point from polar coordinates.
    //PT is an [X,Y] point on the XY axis.
function getPolarFromCoordinate(PT)=
    let(
        X=PT[0],
        Y=PT[1],
        R=sqrt(pow(X,2)+pow(Y,2)),
        A=atan(Y/X)
    )
    [R,A]
;

function reverse(MATRIX)=[
    for ( i=[len(MATRIX)-1:-1:0] )
    let(
    )
    MATRIX[i]
];

//Low budget function. Rotates a 2D polygon on X giving it 3D coordinates.
//Going from the XY axis to the XZ axis.
    //PTL is point list on the XY axis. Same that is used with polygon(points).
function rotate90X3D(PTL)=[
    for ( i=[0:1:len(PTL)-1] )
    let(
        X=PTL[i][0],
        Z=PTL[i][1]
    )
    [ X, 0, Z ]
];
















