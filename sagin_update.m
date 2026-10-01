function P = sagin_update(P)
%SAGIN_UPDATE Build the time-varying tier quantities from the base parameters.
%   Must be called again after any change of lambda, eta, enable, umax0,
%   cap0 or the grids.
Nt = P.Nt;
eta = P.eta(:).';                     % 1 x Nt
P.umax = zeros(Nt, P.K);              % max rate per tier over time
P.cap  = zeros(Nt, P.K);              % server capacity per tier over time
P.eps  = zeros(Nt, P.K);              % energy price per tier over time
P.tau  = zeros(Nt, P.K);              % propagation delay cost per tier
for k = 1:P.K
    P.umax(:,k) = P.umax0(k);
    P.cap(:,k)  = P.cap0(k);
    P.eps(:,k)  = P.eps0(k);
    P.tau(:,k)  = P.tau0(k);
end
% satellite tier depends on the elevation-driven link quality eta(t)
P.umax(:,3) = P.umax0(3)*eta.';
P.cap(:,3)  = P.cap0(3)*eta.';
P.eps(:,3)  = P.eps0(3)./eta.';               % lower spectral efficiency -> more energy per bit
P.tau(:,3)  = P.tau0(3)*(2 - eta.');          % longer slant range at low elevation
% switch off disabled tiers
for k = 1:P.K
    if ~P.enable(k)
        P.umax(:,k) = 0;
    end
end
end
