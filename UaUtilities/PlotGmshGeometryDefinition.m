function GmshPointsInLoop=PlotGmshGeometryDefinition(CtrlVar)

% Plots the geometry (topology) of the mesh as given as input to gmsh
% when using input format 2 (CtrlVar.GmshInputFormat=2)
%
% GmshPointsInLoop=PlotGmshGeometryDefinition(CtrlVar)
%
%
%

switch CtrlVar.GmshInputFormat
    
    
    case 1
        %fprintf('PlotGmshGeometryDefinition: gmsh input format 1 \n')
        
        I=isnan(CtrlVar.MeshBoundaryCoordinates(:,2));
        CtrlVar.MeshBoundaryCoordinates(I,1)=NaN;
        
        plot(CtrlVar.MeshBoundaryCoordinates(:,1)/CtrlVar.PlotXYscale,CtrlVar.MeshBoundaryCoordinates(:,2)/CtrlVar.PlotXYscale,'bx-','LineWidth',2)
        GmshPointsInLoop=[];
        
        
    case 2
        
        
        %fprintf('PlotGmshGeometryDefinition: gmsh input format 2 \n')
        GmshPointsInLoop=FindGmshPointsInLoop(CtrlVar);

        
        for I=1:numel(GmshPointsInLoop)
            plot(GmshPointsInLoop{I}(:,1)/CtrlVar.PlotXYscale,GmshPointsInLoop{I}(:,2)/CtrlVar.PlotXYscale,'LineWidth',2)
        end
            
            
end


end
