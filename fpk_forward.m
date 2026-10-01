function [M, Ubar, drop] = fpk_forward(U, P)
%FPK_FORWARD Solve the Fokker-Planck-Kolmogorov equation forward in time.
%   U    : Nt x Nq x K feedback policy
%   M    : Nq x (Nt+1) probability mass of the backlog on the grid
%   Ubar : Nt x K mean offloaded rate per device (mean field of controls)
%   drop : Nt x 1 mean rate of dropped work per device (Mbit/s) at q = Qmax
%   Implicit scheme with the adjoint of the HJB generator, so the discrete
%   HJB-FPK pair is consistent and total mass is preserved.
Nq = P.Nq; Nt = P.Nt; K = P.K;
M = zeros(Nq, Nt+1);
M(:,1) = P.m0;
Ubar = zeros(Nt, K);
drop = zeros(Nt, 1);
I = speye(Nq);
Dq = 0.5*P.sigma^2/P.dq;
for n = 1:Nt
    u = reshape(U(n,:,:), [Nq, K]);
    m = M(:,n);
    Ubar(n,:) = m.'*u;
    drift = P.lambda - sum(u, 2);
    % blocked probability flux at the full buffer times dq = lost work rate
    drop(n) = m(end)*(max(drift(end),0) + Dq);
    A = build_generator(drift, P);
    mn = (I - P.dt*A.') \ m;
    mn = max(mn, 0);
    M(:,n+1) = mn/sum(mn);
end
end
