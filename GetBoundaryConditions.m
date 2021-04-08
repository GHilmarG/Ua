
function [UserVar,BCs]=GetBoundaryConditions(UserVar,CtrlVar,MUA,BCs,F)


narginchk(5,5)
nargoutchk(2,2)


% does DefineBoundaryConditions.m exist in the run directory?
% if so then use that instead of DefineBCs.m


if exist(fullfile(cd,'DefineBoundaryConditions.m'),'file')
    
    if CtrlVar.InfoLevel>=10
        fprintf(' Using DefineBoundaryConditions.m to define boundary conditions \n')
    end
    
    N=nargout('DefineBoundaryConditions');
    
    switch N
        
        case 1
            
            BCs=DefineBoundaryConditions(UserVar,CtrlVar,MUA,BCs,CtrlVar.time,F.s,F.b,F.h,F.S,F.B,F.ub,F.vb,F.ud,F.vd,F.GF);
            
        case 2
            
            [UserVar,BCs]=DefineBoundaryConditions(UserVar,CtrlVar,MUA,BCs,CtrlVar.time,F.s,F.b,F.h,F.S,F.B,F.ub,F.vb,F.ud,F.vd,F.GF);
            
    end
    
    
else
    
    fprintf(' Using DefineBCs.m to define boundary conditions \n')
    [ubFixedNode,ubFixedValue,vbFixedNode,vbFixedValue,...
        ubTiedNodeA,ubTiedNodeB,vbTiedNodeA,vbTiedNodeB,...
        hFixedNode,hFixedValue,hTiedNodeA,hTiedNodeB]=...
        DefineBCs(CtrlVar.Experiment,CtrlVar,MUA,CtrlVar.time,F.s,F.b,F.h,F.S,F.B,F.ub,F.vb,F.ud,F.vd,F.GF);
    
    BCs.ubFixedNode=ubFixedNode;
    BCs.ubFixedValue=ubFixedValue;
    BCs.vbFixedNode=vbFixedNode;
    BCs.vbFixedValue=vbFixedValue;
    
    BCs.ubTiedNodeA=ubTiedNodeA;
    BCs.ubTiedNodeB=ubTiedNodeB;
    BCs.vbTiedNodeA=vbTiedNodeA;
    BCs.vbTiedNodeB=vbTiedNodeB;
    
    BCs.hFixedNode=hFixedNode;
    BCs.hFixedValue=hFixedValue;
    BCs.hTiedNodeA=hTiedNodeA;
    BCs.hTiedNodeB=hTiedNodeB;
    
end

switch lower(CtrlVar.FlowApproximation)
    
    case 'sstream'
        
        BCs.udFixedNode=[];
        BCs.udFixedValue=[];
        BCs.vdFixedNode=[];
        BCs.vdFixedValue=[];
        BCs.udTiedNodeA=[];
        BCs.udTiedNodeB=[];
        BCs.vdTiedNodeA=[];
        BCs.vdTiedNodeB=[];
        BCs.udvdFixedNormalNode=[];
        BCs.udvdFixedNormalValue=[];
        
    case 'ssheet'
        
        BCs.ubFixedNode=[];
        BCs.ubFixedValue=[];
        BCs.vbFixedNode=[];
        BCs.vbFixedValue=[];
        BCs.ubTiedNodeA=[];
        BCs.ubTiedNodeB=[];
        BCs.vbTiedNodeA=[];
        BCs.vbTiedNodeB=[];
        BCs.ubvbFixedNormalNode=[];
        BCs.ubvbFixedNormalValue=[];
        
end


% do some basic checks

if numel(BCs.ubFixedNode) ~=  numel(BCs.ubFixedValue)
    error('GetBoundaryConditions:ub','Number of fixed ub nodes not equal to number of ub fixed values! \n')
end


if numel(BCs.vbFixedNode) ~=  numel(BCs.vbFixedValue)
    error('GetBoundaryConditions:vb','Number of fixed vb nodes not equal to number of vb fixed values! \n')
end

if numel(BCs.hFixedValue) ~=  numel(BCs.hFixedNode)
    error('GetBoundaryConditions:h','Number of fixed h nodes not equal to number of h fixed values! \n')
end

if numel(BCs.LSFFixedNode) ~=  numel(BCs.LSFFixedValue)
    error('GetBoundaryConditions:LSF','Number of fixed LSF nodes not equal to number of LSF fixed values! \n')
end

if CtrlVar.doplots && CtrlVar.PlotBCs
    fig=FindOrCreateFigure("Boundary Conditions");
    clf(fig) 
    hold off
    PlotBoundaryConditions(CtrlVar,MUA,BCs,'k');
end




end





