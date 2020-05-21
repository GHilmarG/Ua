function [UserVar,r,rRes,rWork,rDisp,D2] = CalcCostFunctionNR(UserVar,CtrlVar,MUA,gamma,F,fext0,L,l,cuv,dub,dvb,dl,K)
    
    nargoutchk(2,6)
    narginchk(12,13)
    
    if isnan(gamma) ; error(' gamma is nan ') ; end
    if ~isreal(gamma) ; error(' gamma is not real ') ; end
    
    F.ub=F.ub+gamma*dub;
    F.vb=F.vb+gamma*dvb;
    l.ubvb=l.ubvb+gamma*dl;
    
    Ruv=KRTFgeneralBCs(CtrlVar,MUA,F);
    
    if ~isempty(L)
        frhs=-Ruv-L'*l.ubvb;
        grhs=cuv-L*[F.ub;F.vb];
        
    else
        frhs=-Ruv;
        grhs=[];
        dl=[];
    end
    
    rRes=ResidualCostFunction(CtrlVar,MUA,L,frhs,grhs,fext0,"-uv-");
    
    % Newton Decrement 

    D2=[frhs;grhs]'*[dub;dvb;dl]  ;
    rWork=D2^2 ;
    
   
    
    % Energy cost function: -Ruv'*[dub;dvb]
    
    
    Inodes=F.h <=CtrlVar.ThickMin ;
    rDisp=CalcIncrementsNorm(CtrlVar,MUA,L,Inodes,F.ub,dub,F.vb,dvb);
    
        
    switch CtrlVar.uvCostFunction
        case "Force Residuals"
            r=rRes;
        case "Work Residuals"
            r=rWork;
        case "Increments"
            r=rDisp ;
    end
    
    % fprintf('gamma=%f rRes=%g \t rWork=%g \t D2=%g \n',gamma,rRes,rWork,D2) 
    
end

