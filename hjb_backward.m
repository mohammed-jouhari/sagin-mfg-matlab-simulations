function [U, V] = hjb_backward(a, P)
%HJB_BACKWARD Solve the HJB equation backward in time for a given price path.
%   a : Nt x K price per Mbit of each tier (broadcast orchestration signal)
%   U : Nt x Nq x K optimal feedback offloading rates u_k(t,q)
%   V : Nq x (Nt+1) value function
%
%   dV/dt + (sigma^2/2) V_qq + min_u { (lambda - sum_k u_k) V_q + L(q,u) } = 0
%   L(q,u) = wq*q + sum_k ( a_k u_k + b_k/2 u_k^2 ),   V(T,q) = wT*q
%   The minimizer is u_k = clip( (V_q - a_k)/b_k , 0 , umax_k ).
%   Semi-implicit upwind scheme: the control is taken from V^{n+1}, the
%   linear part is implicit, which is monotone and stable for any dt.
Nq = P.Nq; Nt = P.Nt; K = P.K; dq = P.dq; q = P.q;
U = zeros(Nt, Nq, K);
V = zeros(Nq, Nt+1);
V(:,Nt+1) = P.wT*q;
I = speye(Nq);
for n = Nt:-1:1
    Vn1 = V(:,n+1);
    p = zeros(Nq,1);                         % V_q by central differences
    p(2:end-1) = (Vn1(3:end) - Vn1(1:end-2))/(2*dq);
    p(1)   = 0;                              % Neumann condition at q = 0
    p(end) = (Vn1(end) - Vn1(end-1))/dq;
    u = zeros(Nq, K);
    for k = 1:K
        u(:,k) = min(max((p - a(n,k))/P.b(k), 0), P.umax(n,k));
    end
    drift = P.lambda - sum(u, 2);
    A = build_generator(drift, P);
    L = P.wq*q + u*a(n,:).' + 0.5*(u.^2)*P.b(:);
    V(:,n) = (I/P.dt - A) \ (Vn1/P.dt + L);
    U(n,:,:) = reshape(u, [1, Nq, K]);
end
end
