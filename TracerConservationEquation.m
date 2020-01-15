function [UserVar,c1,lambda]=TracerConservationEquation(UserVar,CtrlVar,MUA,dt,c0,u0,v0,a0,u1,v1,a1,kappa,BCsTracer)

%%
% Solves the tracer conservation equation for the tracer c on the form:
% 
% $$\partial c/\partial t + d (u c)/dx + d (v c)/dy - \nabla \cdot (\kappa \nabla c) = a$$
% 
% The natural boundary condition is 
%
% $$\nabla c \cdot \hat{n} = 0 $$
%
% ie,  the free outflow condition 
%
% It gives c1 at the end of the time step, i.e. time=time+dt
%
% c is solved implicitly using the theta method ie:
%  \Delta c / Delta t = \Theta d c_1/dt + (1-\Theta) d c_0/dt 
%
% with 
%   theta=CtrlVar.theta;
% and SUPG with 
% tauSUPG=CalcSUPGtau(CtrlVar,MUA,u0,v0,dt);
%
% Boundary conditions: The BCs are identical to define thickness boundary
% conditions. So define the relevant BCs as you were defining BCs for h and
% these will be used for c.
%

MLC=BCs2MLC(CtrlVar,MUA,BCsTracer);
L=MLC.hL ; Lrhs=MLC.hRhs ; lambda=Lrhs*0;

[UserVar,kv,rh]=TracerConservationEquationAssembly(UserVar,CtrlVar,MUA,dt,c0,u0,v0,a0,u1,v1,a1,kappa);

[c1,lambda]=solveKApe(kv,L,rh,Lrhs,c0,lambda,CtrlVar);
c1=full(c1);


end




