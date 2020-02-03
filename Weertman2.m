function [Tauu,Tauv,dTauudu,dTauvdv,dTauudv,dTauvdu,dTauudh,dTauvdh] = Weertman2(C,C0,He,delta,m,u,v,u0) 
%SLIDINGSYMBOLIC
%    [TAUU,TAUV,DTAUUDU,DTAUVDV,DTAUUDV,DTAUVDU,DTAUUDH,DTAUVDH] = SLIDINGSYMBOLIC(C,C0,H,HF,M,U,U0,V)

%    This function was generated by the Symbolic Math Toolbox version 8.4.
%    03-Feb-2020 19:08:20

t2 = u.^2;
t3 = u0.^2;
t4 = v.^2;
t5 = C+C0;
% t6 = -hf;
t7 = 1.0./m;
t8 = m.*t3;
% t9 = h+t6;
t10 = -t7;
t13 = t7./2.0;
t14 = t2+t3+t4;
t11=delta ; % t11 = dirac(t9);
t12=He ; % t12 = heaviside(t9);
t15 = t5.^t10;
t16 = t13-1.0./2.0;
t17 = t13-3.0./2.0;
t18 = t14.^t16;
Tauu = t12.*t15.*t18.*u;
if nargout > 1
    Tauv = t12.*t15.*t18.*v;
end
if nargout > 2
    t19 = t14.^t17;
    dTauudu = t7.*t12.*t15.*t19.*(t2+t8+m.*t4);
end
if nargout > 3
    dTauvdv = t7.*t12.*t15.*t19.*(t4+t8+m.*t2);
end
if nargout > 4
    t20 = t12.*t15.*t16.*t19.*u.*v.*2.0;
    dTauudv = t20;
end
if nargout > 5
    dTauvdu = t20;
end
if nargout > 6
    dTauudh = t11.*t15.*t18.*u;
end
if nargout > 7
    dTauvdh = t11.*t15.*t18.*v;
end
