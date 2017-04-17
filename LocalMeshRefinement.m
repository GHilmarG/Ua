function [MUAnew,RunInfo]=LocalMeshRefinement(CtrlVar,RunInfo,MUAold,ElementsToBeRefined,ElementsToBeCoarsened)

persistent wasRefine


% Local mesh refinement by subdividing selected triangular elements into four elements
% MUAnew=LocalMeshRefinement(CtrlVar,MUAold,ElementsToBeRefined)
%
% ElementsToBeRefined : either a logical vector with same number of elements as there are elements in the mesh,
%                       that is numel(ElementsToBeRefined)=MUA.Nele,
%                       or a list of numbers.
%
% Example:  To refine elements 200 and 500 in an existing mesh
%           MUAnew=LocalMeshRefinement(CtrlVar,MUAold,[200 500])
%
%
%          To refine all elements within a given radius R
%          xEle=Nodes2EleMean(MUA.connectivity,MUA.coordinates(:,1));
%          yEle=Nodes2EleMean(MUA.connectivity,MUA.coordinates(:,2));
%          r=sqrt(xEle.*xEle+yEle.*yEle);
%          I=r<R;
%          MUAnew=LocalMeshRefinement(CtrlVar,MUA,I)


% refine and smoothmesh only works for 3-nod elements
% so first change to 3-nod if needed
%%

% load TestSave
% CtrlVar.WhenPlottingMesh_PlotMeshBoundaryCoordinatesToo=0;  CtrlVar.PlotLabels=0;
% CtrlVar.LocalMeshRefinementMethod='red-green';
% CtrlVar.LocalMeshRefinementMethod='newest vertex bisection';

narginchk(5,5)


if ~islogical(ElementsToBeRefined)
    
    T= false(MUAold.Nele,1);
    T(ElementsToBeRefined)=true;
    
else
    
    T=ElementsToBeRefined;
    
end

nRefine=numel(find(ElementsToBeRefined));
nCoarsen=numel(find(ElementsToBeCoarsened));


if nRefine==0 && nCoarsen==0
    MUAnew=MUAold;
    return
end

if isempty(wasRefine)
    wasRefine=0;
end


[MUAold.coordinates,MUAold.connectivity]=ChangeElementType(MUAold.coordinates,MUAold.connectivity,3);

switch CtrlVar.MeshRefinementMethod
    
    case {'explicit:local:red-green','explicit:local'}
        
        
        RunInfo.MeshAdapt.Method='Red-Green Refinement';
        [MUAold.coordinates,MUAold.connectivity] = refine(MUAold.coordinates,MUAold.connectivity,T);
        [MUAold.coordinates] = GHGsmoothmesh(MUAold.coordinates,MUAold.connectivity,CtrlVar.LocalAdaptMeshSmoothingIterations,[]);
        MUAold.connectivity=FlipElements(MUAold.connectivity);
        
        % create MUA (this takes care of any eventual change in element type as well)
        MUAnew=CreateMUA(CtrlVar,MUAold.connectivity,MUAold.coordinates);
        
        
    case 'explicit:local:newest vertex bisection'
        
        %MUAold.connectivity=FlipElements(MUAold.connectivity);
        if  ~isfield(MUAold,'RefineMesh')  ||  isempty(MUAold.RefineMesh)
            mesh = genMesh(MUAold.connectivity, MUAold.coordinates);
            mesh.bd=[];
            mesh = genBisectionMesh(mesh);
            mesh = SelectRefinementEdge(mesh);
            MUAold.RefineMesh=mesh;
        else
            mesh=MUAold.RefineMesh;
        end
        
                
        if MUAold.nod~=3
            mesh.TR=triangulation(mesh.elements,mesh.coordinates);
        end
        
        
        Na=size(mesh.coordinates,1);  Ea=size(mesh.elements,1);
        
        % do refinement/coarsening alternativily, unless if there are
        % significant in number of elements to be refined/coarsened
        
        
        if wasRefine  &&  ( nRefine < 2*nCoarsen) || nRefine==0
                isRefine=0;
        else
                isRefine=1;
        end
              
        
        wasRefine=isRefine;
        
        if isRefine
            RunInfo.MeshAdapt.Method='Bisection Refinement';
            fprintf(' Refining %i elements \n',nRefine)
            if MUAold.nod~=3
                meshElementsToBeRefined=pointLocation(mesh.TR,[MUAold.xEle(ElementsToBeRefined) MUAold.yEle(ElementsToBeRefined)]);
            else
                meshElementsToBeRefined=ElementsToBeRefined;
            end
            mesh = bisectionRefine2D(mesh,meshElementsToBeRefined);
        else
            RunInfo.MeshAdapt.Method='Bisection Coarsening';
            fprintf(' Coarsening %i elements \n',nCoarsen)
            %mesh.elements=FlipElements(mesh.elements);
            if MUAold.nod~=3
                meshElementsToBeCoarsened=pointLocation(mesh.TR,[MUAold.xEle(ElementsToBeCoarsened) MUAold.yEle(ElementsToBeCoarsened)]);
            else
                meshElementsToBeCoarsened=ElementsToBeCoarsened;
            end
            mesh = bisectionCoarsen(mesh,meshElementsToBeCoarsened);
        end
        
        %elements=TestAndCorrectForInsideOutElements(CtrlVar,mesh.coordinates,mesh.elements);
        
        Nb=size(mesh.coordinates,1);  Eb=size(mesh.elements,1);
        
        isMeshChanged= ~(Na==Nb && Ea==Eb) ;
        
        if isMeshChanged
            fprintf('In local mesh-refinement step the change in the number of elements and nodes was %i and %i, respectivily  (#R/#C)=(%i/%i). \n',...
                Eb-Ea,Nb-Na,nRefine,nCoarsen)
            MUAnew=CreateMUA(CtrlVar,mesh.elements,mesh.coordinates);
            MUAnew.RefineMesh=mesh;
        else
            fprintf('Mesh unchanged in local mesh-refinement step (#R/#C)=(%i/%i). \n',nRefine,nCoarsen)
 
            MUAnew=CreateMUA(CtrlVar,MUAold.connectivity,MUAold.coordinates);
        end
        %%
        
        
    otherwise
        
   
        error('case not found.')
        
end


end