
function [UserVar,RunInfo,MUAnew,BCsNew,Fnew,lnew,GFnew]=AdaptMesh(UserVar,RunInfo,CtrlVar,MUAold,BCsOld,Fold,lold,GFold,Ruv,Lubvb)


% [UserVar,CtrlVar,MUAnew,BCsNew,GF,GLdescriptors,...
%     s,b,h,S,B,ub,vb,ud,vd,l,rho,rhow,g,AGlen,n,C,m,ab,as,dhdt,dhdtm1,dubdt,dvbdt,dubdtm1,dvbdtm1,duddt,dvddt,duddtm1,dvddtm1]=...
%     AdaptMesh(UserVar,CtrlVar,MUAold,BCsOld,...
%     GF,GLdescriptors,alpha,...
%     s,b,h,S,B,ub,vb,ud,vd,uo,vo,Ruv,Lubvb,l,rho,rhow,g,AGlen,n,C,m,ab,as,dhdt,dhdtm1,dubdt,dvbdt,dubdtm1,dvbdtm1,duddt,dvddt,duddtm1,dvddtm1)



narginchk(10,10)
nargoutchk(7,7)

persistent MUA_Background

MUAnew=MUAold;
Fnew=Fold;
BCsNew=BCsOld;
lnew=lold;
GFnew=GFold;


if CtrlVar.InfoLevelAdaptiveMeshing>=1
    fprintf(CtrlVar.fidlog,'Before remeshing: '); PrintInfoAboutElementsSizes(CtrlVar,MUAold)
end


% I want to control directly when FE-mesh is plotted, and avoid the potential FE-mesh plotting in genmesh2d
PlotMeshOnInput=CtrlVar.PlotMesh; CtrlVar.PlotMesh=0;


if CtrlVar.doplots && CtrlVar.doAdaptMeshPlots && CtrlVar.InfoLevelAdaptiveMeshing>=2
    figure
    PlotFEmesh(MUAold.coordinates,MUAold.connectivity,CtrlVar);
    title(sprintf('Initial mesh on input to AdaptMesh : #Ele=%-i, #Nodes=%-i, #nod=%-i',MUAold.Nele,MUAold.Nnodes,MUAold.nod))
end


% Either there is mesh advance nad/or retreat, or mesh adaptation
% If MeshAdvanceRetreat, do not do MeshAdapt

isMeshAdvanceRetreat = CtrlVar.FEmeshAdvanceRetreat && ( ReminderFraction(CtrlVar.time,CtrlVar.FEmeshAdvanceRetreatDT)<1e-5 || CtrlVar.FEmeshAdvanceRetreatDT==0);

isMeshAdapt=CtrlVar.AdaptMesh  ...
    && (CtrlVar.AdaptMeshInitial || (mod(CtrlVar.CurrentRunStepNumber,CtrlVar.AdaptMeshInterval)==0 ...
    && CtrlVar.AdaptMeshInterval>0 && CtrlVar.CurrentRunStepNumber>1)) ...
    && ~isMeshAdvanceRetreat;



if isMeshAdvanceRetreat
    
    
    %%  FE mesh advance or retreat
    if CtrlVar.InfoLevelAdaptiveMeshing>=1
        fprintf(CtrlVar.fidlog,' FE mesh advance or retreat, element activated/deactivated at time %-g \n ',CtrlVar.time);
    end
    
    if isempty(MUA_Background)
        
        if    exist(fullfile(cd,CtrlVar.FEmeshAdvanceRetreatBackgroundMeshFileName), 'file')  == 2 ...
                || exist(fullfile(cd,[CtrlVar.FEmeshAdvanceRetreatBackgroundMeshFileName,'.mat']), 'file')  == 2
            try
                
                if CtrlVar.InfoLevelAdaptiveMeshing>=1
                    fprintf('Reading ''MUA_Background'' from: %s ',CtrlVar.FEmeshAdvanceRetreatBackgroundMeshFileName)
                end
                
                %load(CtrlVar.FEmeshAdvanceRetreatBackgroundMeshFileName,'coordinates','connectivity')
                load(CtrlVar.FEmeshAdvanceRetreatBackgroundMeshFileName,'MUA_Background')
                
                if exist('MUA_Background','var')==0
                    fprintf(' The variable MUA_Background not found in %s.! \n',CtrlVar.FEmeshAdvanceRetreatBackgroundMeshFileName)
                    error('AdaptMesh:MUA_BackgroundNotFound','Where is MUA_Background?')
                end
                
                MUA_Background=UpdateMUA(CtrlVar,MUA_Background);
                if CtrlVar.InfoLevelAdaptiveMeshing>=1
                    fprintf('done \n ')
                end
                
            catch
                fprintf('File %s not containing ''MUA_Background'' \n',CtrlVar.FEmeshAdvanceRetreatBackgroundMeshFileName)
                error(' exiting ' )
            end
        else
            fprintf('File with background meshfile %s could not be found \n',CtrlVar.FEmeshAdvanceRetreatBackgroundMeshFileName)
            fprintf('Note: When using the''FEmeshAdvanceRetreat'' option, a background mesh must be defined.\n')
            fprintf('The background mesh is usually same as the intial mesh used in the run, but must be defined by the user.\n')
            fprintf('Possible solution: \n')
            fprintf('Load a MUA structure previously created in an initial meshing step and save in a seperate file. \n')
            fprintf('For example: load NewMeshFile.mat ; MUA_Background=MUA ; save(''Backgroundmesh'',''MUA_Background'') \n')
            fprintf('And in Ua2D_InitialUserInput: CtrlVar.FEmeshAdvanceRetreatBackgroundMeshFileName=''Backgroundmesh'' ; \n')
            fprintf('                              CtrlVar.FEmeshAdvanceRetreat=1 ; \n')
            
            error('Ua:AdaptMesh:NoBackgroundMeshfile',' exiting ' )
        end
        
    end
    
    
    hBackground=MapNodalVariablesFromMesh1ToMesh2(CtrlVar,MUAold,MUA_Background.coordinates(:,1),MUA_Background.coordinates(:,2),CtrlVar.ThickMin,Fold.h);
    [UserVar,iDeactivatedElements]=FindElementsToDeactivate(UserVar,CtrlVar,MUA_Background,hBackground);
    
    fprintf(CtrlVar.fidlog,'%i elements of background mesh deactivated. ',numel(find(iDeactivatedElements)));
    
    
    if CtrlVar.doplots && CtrlVar.doAdaptMeshPlots && CtrlVar.InfoLevelAdaptiveMeshing>=10
        
        figure(10000)
        subplot(2,1,1,'replace')
        hold off
        PlotNodalBasedQuantities(MUA_Background.connectivity,MUA_Background.coordinates,hBackground,CtrlVar);
        xlabel('x (km)') ; ylabel('y (km)') ;
        colorbar ; title(colorbar,'(m)') ; % caxis([0 100])
        hold on
        
        title(sprintf('hBackground at t=%#5.1f ',CtrlVar.time))
        %tt=daspect ; daspect([mean(tt(1)+tt(2)) mean(tt(1)+tt(2)) tt(3)]);
        axis equal tight
        
        ind=hBackground<=CtrlVar.ThickMinDeactivateElements;
        plot(MUA_Background.coordinates(ind,1)/CtrlVar.PlotXYscale,MUA_Background.coordinates(ind,2)/CtrlVar.PlotXYscale,'.r')
        hold off
        
        
        subplot(2,1,2,'replace')
        hold off
        PlotFEmesh(MUA_Background.coordinates,MUA_Background.connectivity,CtrlVar)
        hold on
        ind=hBackground<=CtrlVar.ThickMinDeactivateElements;
        plot(MUA_Background.coordinates(ind,1)/CtrlVar.PlotXYscale,MUA_Background.coordinates(ind,2)/CtrlVar.PlotXYscale,'.r')
        
        xEleBackground=Nodes2EleMean(MUA_Background.connectivity,MUA_Background.coordinates(:,1));
        yEleBackground=Nodes2EleMean(MUA_Background.connectivity,MUA_Background.coordinates(:,2));
        
        plot(xEleBackground(iDeactivatedElements)/CtrlVar.PlotXYscale,yEleBackground(iDeactivatedElements)/CtrlVar.PlotXYscale,'og')
        title(sprintf('time=%-g \t #Ele=%-i, #Nodes=%-i, #nod=%-i, \n # EleBG=%-i, #NodesBG=%-i, #nodBG=%-i \n Green=Elements to deactivate',...
            CtrlVar.time,MUAold.Nele,MUAold.Nnodes,MUAold.nod,MUA_Background.Nele,MUA_Background.nod,MUA_Background.Nnodes))
        axis equal tight
    end
    
    % eliminate elements
    if numel(find(iDeactivatedElements))>0
        [coordinates,connectivity]=DeactivateElements(CtrlVar,iDeactivatedElements,MUA_Background.coordinates,MUA_Background.connectivity);
        clear MUA
        MUAnew=CreateMUA(CtrlVar,connectivity,coordinates);
        clear connectivity coordinates
        MUAnew=UpdateMUA(CtrlVar,MUAnew);
        
        
        fprintf(CtrlVar.fidlog,'Change in the number of elements : %+i \n ',MUAnew.Nele-MUAold.Nele);
    end
    
    
    isMeshChanged=HasMeshChanged(MUAnew,MUAold);
    if ~isMeshChanged
        CtrlVar.PlotMesh=PlotMeshOnInput;
        return
    end
    
    
elseif isMeshAdapt
    
    for JJ=1:CtrlVar.AdaptMeshIterations
        
        
        
        if CtrlVar.InfoLevelAdaptiveMeshing>=1
            fprintf(CtrlVar.fidlog,' =====  Remeshing at start of run step %-i. Iteration #%-i out of %-i \n ',CtrlVar.CurrentRunStepNumber,JJ,CtrlVar.AdaptMeshIterations);
        end
        
        switch lower(CtrlVar.MeshRefinementMethod)
            
            case 'implicit'
                
                error(' implicit error estimate not fully implemented \n')
                %                 [coordinates,connectivity]=DesiredEleSizesBasedOnImplicitErrorEstimate(UserVar,MeshBoundaryCoordinates,Boundary,...
                %                     s,b,S,B,h,ub,vb,coordinates,connectivity,nip,AGlen,C,Luv,Luvrhs,l.ubvb,n,m,alpha,rho,rhow,g,CtrlVar.CurrentRunStepNumber,CtrlVar);
                
            case {'explicit:global','explicit:local'}
                
                % do I need to calculate velocities for error estimates?
                CalcVel=any(arrayfun(@(x) strcmpi(x,'effective strain rates'),CtrlVar.RefineCriteria) | arrayfun(@(x) strcmpi(x,'residuals'),CtrlVar.RefineCriteria));
                
                if CalcVel
                    [UserVar,RunInfo,Fold,lold,~,Ruv,Lubvb]= uv(UserVar,RunInfo,CtrlVar,MUAold,BCsOld,Fold,lold,GFold);
                end
                
                [UserVar,CtrlVar,MUAnew,xGLmesh,yGLmesh]=...
                    RemeshingBasedOnExplicitErrorEstimate(UserVar,CtrlVar,MUAold,Fold,lold,GFold,CtrlVar.MeshBoundaryCoordinates,Ruv,Lubvb);

            otherwise
                error(' unknown case  ')
        end

        
        if MUAnew.Nele==0
            fprintf('No elements left in mesh! \n ')
            CtrlVar.PlotMesh=PlotMeshOnInput;
            return
        end
        
        % At the end of an iteration, the new becomes old
        MUAnew=UpdateMUA(CtrlVar,MUAnew);
        lnew=UaLagrangeVariables;
        [UserVar,Fnew,BCsNew,GFnew]=MapFbetweenMeshes(UserVar,CtrlVar,MUAold,MUAnew,Fold,BCsOld,GFold);
        
        
        MUAold=MUAnew;
        Fold=Fnew;
        BCsOld=BCsNew;
        
        if CtrlVar.doplots && CtrlVar.doAdaptMeshPlots && CtrlVar.InfoLevelAdaptiveMeshing>=1
            if CtrlVar.PlotBCs
                figure ; PlotBoundaryConditions(CtrlVar,MUAnew,BCsNew);
            else
                figure
                PlotFEmesh(MUAnew.coordinates,MUAnew.connectivity,CtrlVar); hold on
                title(sprintf('AdaptMesh Iteration %i: #Ele=%-i, #Nodes=%-i, #nod=%-i',JJ,MUAnew.Nele,MUAnew.Nnodes,MUAnew.nod))
            end
            
            if CtrlVar.GLmeshing
                hold on ; plot(xGLmesh,yGLmesh,'-rx','LineWidth',2);
            end
        end
    end
    
end

if MUAnew.Nele==0
    fprintf('No elements left in mesh! \n ')
    CtrlVar.PlotMesh=PlotMeshOnInput;
    return
end

MUAnew=UpdateMUA(CtrlVar,MUAnew);
lnew=UaLagrangeVariables;

[UserVar,Fnew,BCsNew,GFnew]=MapFbetweenMeshes(UserVar,CtrlVar,MUAold,MUAnew,Fold,BCsOld,GFold);
[UserVar,RunInfo,Fnew,lnew]= uv(UserVar,RunInfo,CtrlVar,MUAnew,BCsNew,Fnew,lnew,GFnew);  % should really not be needed

if CtrlVar.InfoLevelAdaptiveMeshing>=1
    fprintf(CtrlVar.fidlog,'After remeshing: ') ; PrintInfoAboutElementsSizes(CtrlVar,MUAnew)
end

if CtrlVar.InitialDiagnosticStepAfterRemeshing
    CtrlVar.InitialDiagnosticStep=1;  % make sure that in next uvh step I start with an initial uv step
end

if ~isempty(CtrlVar.SaveAdaptMeshFileName)
    MUA=MUAnew;
    save(CtrlVar.SaveAdaptMeshFileName,'MUA')
    fprintf(CtrlVar.fidlog,' Adapted FE mesh was saved in %s .\n',CtrlVar.SaveAdaptMeshFileName);
end

end

