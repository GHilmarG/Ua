
function Ua


%% �a
% A finite-element ice-flow model.
% 
% Flow approximations: Shallow Ice Sheet Flow Approximation (SSHEET or SIA)
%                      Shallow Ice Stream Flow Approximation (SSTREAM or SSA)
%                      Hybrid combinations of SIA and SSA (already implemented,
%                      but still being developed further...)
%
% The code is developed by Hilmar Gudmundsson (ghg@bas.ac.uk).
%
%% Running �a:
%
% 1) Add the folder with the �a m-files, and its subfolders, to your matlab
% path.
%    This can be done using the 'Home/Set' Path menu item, or from the command
%    prompt doing something like: addpath('MyUaSourceFileFolder')
%
% 2) Define the Matlab environmental variable 'UaHomeDirectory'.
%    This can for example be done as follows:
%                 setenv('UaHomeDirectory','MyUaSourceFileFolder')
%
% 3) If using the mesh generator `gmsh' (almost always the case) then also
%    define the Matlab environmental variable 'GmeshHomeDirectory'. 
%    The gmsh program for windows is in a subfolder of Ua/Source
%    So if you are running windows
%                 setenv('GmeshHomeDirectory','MyDrive/Ua/Source/gmsh-2.12.0-Windows')
%   will do. Alternativily you might want to install your own copy of gmsh. If
%   running on a Unix system, then most likely gmsh can be called without the
%   need to set the Matlab environmental variable 'GmeshHomeDirectory'.
%
% Now you can run �a from within Matlab by writing Ua [Ret]
%
%  Summary: Before running Ua do
%   setenv('UaHomeDirectory','C:\cygwin64\home\Hilmar\ghg\Ua\Source')
%   setenv('GmeshHomeDirectory','C:\cygwin64\home\Hilmar\ghg\Ua\Source\gmsh-2.12.0-Windows')
%   UaHomeDirectory=getenv('UaHomeDirectory'); addpath(genpath(UaHomeDirectory))
%
%  Then run Ua from the Source directory to see if everyting is OK.
%% Getting help
% You can get help on the use of �a in the same way as you would get help on
% various in-build matlab commands by writing `help Ua'  in the matlab command
% line,  or `doc Ua'. Most m-files that are part of the Ua program have some
% inbuild help text, for example try `doc Ua2D_DefaultParameters'.
%
% To get a HTML formatted documentation try:
%
%    publish('Ua.m','evalCode',false) ; web('html\Ua.html')
%
%% Defining model run
%
% Whenever setting up your own model, create your own working directory for your
% model runs. Most of the parameters of a given model run are defined by the
% user through ` *user m-files'* that are called by �a during the run.
%
%% User m-files :
% 
% * Ua2D_InitialUserInput
% * DefineAGlenDistribution.m
% * DefineSlipperyDistribution.m
% * DefineBoundaryConditions.m  (also possible to use the more limited but
% easier to use `DefineBCs.m' instead)
% * DefineGeometry.m
% * DefineDensities.m
% * DefineMassBalance.m
% * DefineDesiredEleSize.m
% * DefineStartVelValues.m
% * DefineInputsForInverseRun.m
% * DefineInverseModellingVariables.m (older approach, use
% DefineInputsForInversion.m instead)
% * UaOutputs.m
%
% To get further information on how to use individual user m-files use help. For
% example: help DefineGeometry 
% Make sure to do this from the �a home directory, or at least not from another
% directory that has a m-file with the same name.
%
%
% When defining a new model-run, just copy these user m-files from the �a home
% directory into your own model-run directory and modify as needed.
%
% Not all of these user m-files are always needed. For example
% `DefineInverseModellingVariables.m' is only needed for inverse runs. Also
% 'DefineStartVelValues.m' is not often required as setting start velocities to
% zero (the default opton) is usually a good approach. And DefineDesiredEleSizes
% is only needed if one finds that the standard remeshing options within �a are
% too limited.
%
% UaOutputs is only needed for producing output files or for some plotting, etc.
%
% If any of the above listed m-Files are not found in the run directory, the
% corresponding m-Files in the �a home directory are used instead.
%
%
%% Name of variables
% 
% Throughout the following variables stand for:
%
%  s          : upper glacier surface elevation 
%  b          : lower glacier surface elevation 
%  S          : ocean surface elevation 
%  B          : bedrock elevation 
%  (ub,vb,wb) : sliding velocity components 
%  (ud,vd,wd) : deformational  velocity components 
%  rho        : ice density (defined at nodes and does not have to be spatially uniform) 
%  rhow       : ocean density (a scalar) 
%  AGlen      : rate factor of Glen's flow law  (either a nodal or an element variable)
%  n          : stress exponent of the Glen's flow law  
%  C          : basal slipperiness ((either a nodal or an element variable) 
%  m          : stress exponent of the basal sliding law (a scalar)
%  as, ab     : mass balance distribution over the upper (as) and lower (ab) glacier surfaces. 
%               The mass balance is given in units distance/time, and should be
%               in same units as the velocity.
% alpha       : Slope of the coordinate system with respect to gravity.
% g           : The gravitational acceleration.
% GF          : a floating/grounded mask. This is a structure with the two
%                fields: node and ele. This are 1 if a node/element is grounded, 0 if
%                node/element is afloat.
%    
%
%
%
%% Calls to user m-files:
% The calls to these functions are:
%
%    [rho,rhow,g]=DefineDensities(Experiment,CtrlVar,MUA,time,s,b,h,S,B);
% 
%    [C,m]=DefineSlipperyDistribution(Experiment,CtrlVar,MUA,time,s,b,h,S,B,rho,rhow,GF);
% 
%    [AGlen,n]=DefineAGlenDistribution(Experiment,CtrlVar,MUA,time,s,b,h,S,B,rho,rhow,GF);
% 
%    [as,ab]=DefineMassBalance(Experiment,CtrlVar,MUA,time,s,b,h,S,B,rho,rhow,GF);
%
% If mass-balance geometry feedback is included, define mass balance as:
% 
%    [as,ab,dasdh,dabdh]=DefineMassBalance(Experiment,CtrlVar,MUA,time,s,b,h,S,B,rho,rhow,GF);
% 
%    BCs=DefineBoundaryConditions(Experiment,CtrlVar,MUA,BCs,time,s,b,h,S,B,ub,vb,ud,vd,GF)
%
% BCs is an instant of the class `BoundaryConditions'. To see the fields of BCs
% have a look at BoundaryConditions.m in the editor or do help
% BoundaryConditions.m .
% The fancy way of doing this is to do:
% publish('BoundaryConditions.m') ; web('html\BoundaryConditions.html') from the
% �a home directory.
%
% 
%   [s,b,S,B,alpha]=DefineGeometry(Experiment,CtrlVar,MUA,time,FieldsToBeDefined);
% 
%   [ub,vb,ud,vd]=DefineStartVelValues(Experiment,CtrlVar,MUA,ub,vb,ud,vd,time,s,b,h,S,B,rho,rhow,GF,AGlen,n,C,m);
%  
%
%% Getting information about the FE mesh from within user m-files:
%
% In all user m-files the variable MUA is given as an input.
%  MUA is a structured variable with the following fields
%      coordinates:  Nnodes x 2 array with the x and y coordinates of all nodal
%                    points
%     connectivity:  mesh connectivity
%           Nnodes:  number of nodes in mesh
%             Nele:  number of elements in mesh
%              nod:  number of nodes per element nip:  number of integration
%                    points
%           points:  local element coordinates of integration points
%          weights:  weights of integration points
%         Boundary:  a structure containing info about mesh boundary
%                    This structure is calculated as:
%                    MUA.Boundary=FindBoundary(connectivity,coordinates); and
%                    info about the fields can be found in `FindBoundary.m'
%            Deriv:  element derivatives
%             DetJ:  element determinants
%
%               The values of MUA should never be changed directly by the user.
%
%
%% Meshing
% There are various ways of meshing the computational domain.
%
% In almost all cases the simplest option tends to be to define the outlines of
% the computational domain in Ua2D_InitialUserInput. In that case �a will call
% an external mesh generator. The external mesh generator used by �a is "gmsh"
% which is a well known and well supported open source mesh generator
% (http://geuz.org/gmsh/) The outlines of the mesh are defined by the variable
% 'MeshBoundaryCoordinates' set in Ua2D_InitialUserInput.m. This approach is
% quite flexible and allows for complicated computational domains containing
% holes and/or separated domains. 
%
% For examples of how to generate different
% type of meshes run *ExamplesOfMeshGeneration*
%
% The ExamplesOfMeshGeneration.m containes information and examples on how
% to define inputs for various types of meshes. 
%
% There are also various ways of refining the mesh. Boht global and local
% (explicit) adaptive meshing is supported. See further explanations in
% 'Ua2D_DefaultParamters.m'
%%
% Control parameters The type of runs (static, transient, forward, inverse) and
% various paramters affecting the run are specified using the variable
% `CtlrVar'.  This variable is defined by the user in `Ua2D_InitialUserInput.m'.
% This variable has a large number of fields. List of all fields with
% descriptions can be found in  `Ua2D_DefaultParameters.m'
%
%
%


if nargin==0
    UserRunParameters=[];
end

Ua2D(UserRunParameters)


end


