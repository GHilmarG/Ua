
function [LSF,UserVar,RunInfo]=ReinitializeLevelSet(UserVar,RunInfo,CtrlVar,MUA,LSF,Threshold)
    
    
    %%
    %   [LSF,UserVar,RunInfo]=ReinitializeLevelSet(UserVar,RunInfo,CtrlVar,MUA,F,LSF)
    %
    %
    % Reinitilizes the Level Set;
    %
    %%

    
    %% 1)
    
    if nargin < 6  || isempty(Threshold)
        Threshold=0 ;
    end

    CtrlVar.LineUpGLs=false ; 
    [xc,yc]=CalcMuaFieldsContourLine(CtrlVar,MUA,LSF,Threshold);
    
    
    % 2) Distance 
    if numel(xc)>0
        
        %Dist=pdist2(MUA.coordinates(Mask.NodesOn,:),MUA.coordinates,'euclidean','Smallest',1) ;
        Dist=pdist2([xc(:) yc(:)],MUA.coordinates,'euclidean','Smallest',1) ;
        Dist=Dist(:) ;
    
        PM=sign(LSF) ; 
        
     % 3) Replace LSF with signed distance 
        TH = TopHatApprox(1/10e3,LSF,50e3) ;
     
        LSF=PM.*Dist.*TH+(1-TH).*LSF; 
        
        
    else
        
        fprintf('ReinitializeLevelSet:No calving-front nodes found within the domain.\n')
        
    end
    
    
    
end