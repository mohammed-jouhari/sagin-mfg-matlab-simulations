function R = evaluate_policy(U, P)
%EVALUATE_POLICY Population-level performance of any feedback policy U.
%   The policy is applied by every device, the density is propagated with
%   the FPK equation and all costs are charged with the TRUE congestion
%   latency (selfish price, without any Pigouvian transfer).
%   Rates of a tier are clipped to the feasible range of the true system.
Nq = P.Nq; Nt = P.Nt; K = P.K;
for k = 1:K
    Uk = U(:,:,k);
    Uk = min(max(Uk, 0), repmat(P.umax(:,k), 1, Nq));
    U(:,:,k) = Uk;
end
[M, Ubar, drop] = fpk_forward(U, P);
[~, lat, rho] = tier_prices(Ubar, P, 'MFG');
Jq = 0; Je = 0; Jd = 0;
Jt = zeros(Nt, 1);
for n = 1:Nt
    u = reshape(U(n,:,:), [Nq, K]);
    m = M(:,n);
    cq = P.wq*(m.'*P.q);
    ce = (m.'*u)*P.eps(n,:).' + 0.5*(m.'*(u.^2))*P.b(:);
    cd = (m.'*u)*lat(n,:).';
    Jq = Jq + P.dt*cq; Je = Je + P.dt*ce; Jd = Jd + P.dt*cd;
    Jt(n) = cq + ce + cd;
end
JT = P.wT*(M(:,end).'*P.q);
R.J      = (Jq + Je + Jd + JT)/P.T;      % time-averaged cost per device
R.Jq     = (Jq + JT)/P.T;                % backlog (delay) part incl. terminal
R.Je     = Je/P.T;                       % energy part
R.Jd     = Jd/P.T;                       % offloading latency part
R.Jt     = Jt;                           % instantaneous cost rate
R.meanQ  = mean(P.q.'*M(:,1:Nt));        % mean backlog (Mbit)
R.delay  = R.meanQ/P.lambda;             % mean waiting time in the device buffer (Little's law)
R.delayE2E = (R.meanQ + R.Jd)/P.lambda;  % waiting + transfer/processing latency per Mbit (s)
R.energy = Je/P.T;
R.dropRatio = mean(drop)/P.lambda;       % fraction of arriving work dropped
R.Ubar   = Ubar;
R.rho    = rho;
R.peakRho = max(max(rho(:,2:3)));
R.M      = M;
end
