function [TRI,DT,LightHandle]=Plot_sbB(CtrlVar,MUA,s,b,B,TRI,DT,AspectRatio,ViewAndLight,LightHandle)

%  Creates a perspective plot of s,b and B
%  TRI and DT are optional, can be empty.
%
%
%  Note: AspectRatio is not the actual aspect ratio between xy and z,  
%        just a number that affects the aspect ratio.
%        To see what the aspect ratio is use the matlab commant `daspect'
%
% ViewAndLight(1)=AZ
% ViewAndLight(2)=EL
%
%
% CtrlVar.ThicknessCutOffForPlotting  :  Ice only plotted as ice if thickness greater than this. 
%
%



x=MUA.coordinates(:,1) ; y=MUA.coordinates(:,2) ;

if nargin<10
    LightHandle=[];
end

if nargin<6 || isempty(TRI)
    [TRI,DT]=CreateTRI(MUA);
end

if nargin<8  || isempty(AspectRatio)
    AspectRatio=1;
end

if nargin<9 || isempty(ViewAndLight)
    ViewAndLight(1)=-70 ;  ViewAndLight(2)=20 ;
    ViewAndLight(3)=-45 ;  ViewAndLight(4)=50;
end

hold off



sCol=copper(numel(s));
bCol=copper(numel(s));
BCol=copper(numel(s));

ColorIndex=Variable2ColorIndex(s); sCol(:,:)=sCol(ColorIndex,:);
ColorIndex=Variable2ColorIndex(b); bCol(:,:)=bCol(ColorIndex,:);
ColorIndex=Variable2ColorIndex(B); BCol(:,:)=BCol(ColorIndex,:);

h=s-b; 


if isfield(CtrlVar,'ThicknessCutOffForPlotting')
    I=h>CtrlVar.ThicknessCutOffForPlotting;
else
    I=h>2*CtrlVar.ThickMin;
end


sCol(I,:)=zeros(numel(find(I)),3)+1;
bCol(I,:)=zeros(numel(find(I)),3)+1;
%BCol(I,:)=zeros(numel(find(I)),3)+1;

if ~isempty(s)
    trisurf(TRI,x/CtrlVar.PlotXYscale,y/CtrlVar.PlotXYscale,s,'FaceVertexCData',sCol,'EdgeColor','none') ;
end

hold on
if ~isempty(b)
    trisurf(TRI,x/CtrlVar.PlotXYscale,y/CtrlVar.PlotXYscale,b,'FaceVertexCData',bCol,'EdgeColor','none') ;
end

if ~isempty(B)
    trisurf(TRI,x/CtrlVar.PlotXYscale,y/CtrlVar.PlotXYscale,B,'FaceVertexCData',BCol,'EdgeColor','none') ;
end



if ishandle(LightHandle)
    LightHandle=lightangle(LightHandle,ViewAndLight(3),ViewAndLight(4)) ;
else
    LightHandle=lightangle(ViewAndLight(3),ViewAndLight(4)) ;
end

lighting phong ;

xlabel(CtrlVar.PlotsXaxisLabel) ;
ylabel(CtrlVar.PlotsYaxisLabel) ;
zlabel('z (m a.s.l.)')
%colorbar ; title(colorbar,'(m)')
hold on

title(sprintf('t=%f (yr)',CtrlVar.time))
axis equal ; tt=daspect ; 
daspect([mean(tt(1)+tt(2)) mean(tt(1)+tt(2)) tt(3)*CtrlVar.PlotXYscale/10/AspectRatio]); 
axis tight
hold off

view(ViewAndLight(1),ViewAndLight(2));

end