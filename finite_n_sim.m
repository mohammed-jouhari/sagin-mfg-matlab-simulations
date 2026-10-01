function out = finite_n_sim(U, P, N, nRuns, UbarMF, seed)
%FINITE_N_SIM Monte Carlo simulation of N devices that apply policy U.
%   Every device follows the same feedback policy u_k(t,q); the congestion
%   latency of each shared tier is computed from the EMPIRICAL load of the
%   N devices, so this checks the mean-field approximation.
%   U      : Nt x Nq x K policy,  N : number of devices,  nRuns : runs
%   UbarMF : Nt x K mean-field loads (reference) or [] to skip the error
%   out.J    : mean cost per device for each run (nRuns x 1)
%   out.err  : time-averaged sum_k |Ubar^N - Ubar^MF| for each run
%   out.Ubar : empirical loads of the last run (Nt x K)
if nargin < 6, seed = 1; end
rng(seed);                      % reproducible runs (MATLAB and Octave >= 7)
Nq = P.Nq; Nt = P.Nt; K = P.K; dq = P.dq;
nSub = 4;                       % Euler-Maruyama sub-steps per time slot
h = P.dt/nSub;
cdf = cumsum(P.m0(:));
out.J = zeros(nRuns, 1);
out.err = zeros(nRuns, 1);
out.drop = zeros(nRuns, 1);
for r = 1:nRuns
    % sample initial backlogs from m0 (inverse CDF on the grid + jitter)
    xi = rand(N, 1);
    [~, idx0] = max(repmat(cdf.', N, 1) >= repmat(xi, 1, Nq), [], 2);
    q = P.q(idx0) + (rand(N,1) - 0.5)*dq;
    q = min(max(q, 0), P.Qmax);
    cost = zeros(N, 1);
    dropped = 0;
    UbarN = zeros(Nt, K);
    for n = 1:Nt
        Un = reshape(U(n,:,:), [Nq, K]);
        for s = 1:nSub
            % linear interpolation of the policy at the device backlogs
            pos = q/dq;
            j = min(floor(pos) + 1, Nq - 1);
            w = pos - (j - 1);
            u = (1 - w).*Un(j,:) + w.*Un(j+1,:);           % N x K
            u = min(max(u, 0), repmat(P.umax(n,:), N, 1));
            ub = mean(u, 1);                               % empirical loads
            UbarN(n,:) = UbarN(n,:) + ub/nSub;
            % true prices from the empirical loads
            Ub = zeros(Nt, K); Ub(n,:) = ub;
            [~, lat] = tier_prices(Ub, P, 'MFG');
            price = P.eps(n,:) + lat(n,:);
            cost = cost + h*(P.wq*q + u*price.' + 0.5*(u.^2)*P.b(:));
            % backlog dynamics
            q = q + (P.lambda - sum(u, 2))*h + P.sigma*sqrt(h)*randn(N, 1);
            over = q > P.Qmax;
            dropped = dropped + sum(q(over) - P.Qmax);
            q = min(abs(q), P.Qmax);               % reflection at 0, overflow at Qmax
        end
    end
    cost = cost + P.wT*q;
    out.J(r) = mean(cost)/P.T;
    out.drop(r) = dropped/(N*P.T*P.lambda);
    if ~isempty(UbarMF)
        out.err(r) = mean(sum(abs(UbarN - UbarMF), 2));
    end
end
out.Ubar = UbarN;
end
