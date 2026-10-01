function a = clear_prices(V, M, P, mode)
%CLEAR_PRICES Market-clearing congestion prices of the orchestrator.
%   For every time slot n and tier k the price a solves the scalar
%   consistency equation
%       a = price_k( sum_i m_i * clip((p_i - a)/b_k, 0, umax_k) )
%   where p = V_q is the marginal value of backlog of the devices. The
%   left side increases and the right side decreases with a, so the root
%   is unique and bisection finds it.
%   V : Nq x (Nt+1) value function,  M : Nq x (Nt+1) density
%   a : Nt x K clearing prices
Nq = P.Nq; Nt = P.Nt; K = P.K; dq = P.dq;
% marginal value of backlog used by the controls on [t_n, t_{n+1}]
Vn1 = V(:, 2:Nt+1);
Pg = zeros(Nq, Nt);
Pg(2:end-1,:) = (Vn1(3:end,:) - Vn1(1:end-2,:))/(2*dq);
Pg(1,:)   = 0;                                % Neumann condition at q = 0
Pg(end,:) = (Vn1(end,:) - Vn1(end-1,:))/dq;
Mn = M(:, 1:Nt);

aLo = tier_prices(zeros(Nt, K), P, mode);         % price of empty servers
aHi = max(aLo, repmat(max(Pg, [], 1).', 1, K) + 1e-6);
for it = 1:50
    aMid = 0.5*(aLo + aHi);
    Ub = zeros(Nt, K);
    for k = 1:K
        uk = (Pg - repmat(aMid(:,k).', Nq, 1))/P.b(k);
        uk = min(max(uk, 0), repmat(P.umax(:,k).', Nq, 1));
        Ub(:,k) = sum(Mn.*uk, 1).';
    end
    G = aMid - tier_prices(Ub, P, mode);
    pos = G > 0;
    aHi(pos)  = aMid(pos);
    aLo(~pos) = aMid(~pos);
end
a = 0.5*(aLo + aHi);
end
