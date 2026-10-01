function [a, lat, rho] = tier_prices(Ubar, P, mode)
%TIER_PRICES Per-Mbit price signal of each tier for given aggregate loads.
%   Ubar : Nt x K mean offloaded rate per device (the mean field of controls)
%   mode : 'MFG' -> individual (selfish) price
%          'MFC' -> Pigouvian (marginal social) price used by the planner
%   a    : Nt x K price that enters the HJB equation
%   lat  : Nt x K latency part of the true price (used for cost reporting)
%   rho  : Nt x K utilization of the shared servers
%
%   Congestion law (M/M/1 type sojourn cost with a C1 linear extension
%   above rho0, so the price stays finite, continuous and increasing):
%       D(rho) = s/(1-rho)                              rho <= rho0
%       D(rho) = s/(1-rho0) + s/(1-rho0)^2 (rho-rho0)   rho >  rho0
if nargin < 3, mode = 'MFG'; end
Nt = P.Nt; K = P.K;
rho   = zeros(Nt, K);
lat   = zeros(Nt, K);
extra = zeros(Nt, K);
r0 = P.rho_max;
for k = 1:K
    if isinf(P.cap0(k))
        lat(:,k) = P.tau(:,k) + P.s(k);          % private CPU: no congestion
    else
        c = max(P.cap(:,k), 1e-9);
        r = Ubar(:,k)./c;
        rho(:,k) = r;
        D  = P.s(k)./(1 - min(r, r0));
        dD = P.s(k)./(1 - min(r, r0)).^2;        % dD/drho
        hi = r > r0;
        D(hi) = P.s(k)/(1 - r0) + P.s(k)/(1 - r0)^2*(r(hi) - r0);
        lat(:,k) = P.tau(:,k) + D;
        if strcmpi(mode, 'MFC')
            extra(:,k) = Ubar(:,k).*dD./c;       % congestion externality
        end
    end
end
a = P.eps + lat + extra;
end
