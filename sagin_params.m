function P = sagin_params()
%SAGIN_PARAMS Default parameters of the MFG-based SAGIN orchestration model.
%   All rates are in Mbit/s, backlogs in Mbit and time in seconds.
%   Tier index: 1 = local (ground device), 2 = aerial (UAV/HAP edge),
%               3 = LEO satellite edge.

% ---------------- time and state grids ----------------
P.T     = 300;              % LEO visibility window (s)
P.dt    = 0.5;              % time step (s)
P.Nt    = round(P.T/P.dt);  % number of time intervals
P.t     = (0:P.Nt)*P.dt;    % time nodes (1 x Nt+1)
P.Qmax  = 10;               % buffer size (Mbit)
P.Nq    = 201;              % number of backlog grid points
P.q     = linspace(0, P.Qmax, P.Nq).';   % backlog grid (Nq x 1)
P.dq    = P.q(2) - P.q(1);

% ---------------- traffic ----------------
P.lambda = 1.0;             % mean task arrival rate per device (Mbit/s)
P.sigma  = 0.6;             % traffic burstiness (Mbit/sqrt(s))

% ---------------- LEO visibility profile ----------------
P.eta_min = 0.20;           % normalized link quality at the horizon
P.eta     = P.eta_min + (1 - P.eta_min)*sin(pi*P.t(1:P.Nt)/P.T).^2;  % 1 x Nt

% ---------------- tier parameters (index 1:3 = L, A, S) ----------------
P.K      = 3;
P.names  = {'Local', 'Aerial', 'Satellite'};
P.eps0   = [0.05, 0.08, 0.10];  % energy price per Mbit (at full visibility for S)
P.tau0   = [0.00, 0.01, 0.04];  % propagation delay cost (S grows at low elevation)
P.s      = [0.00, 0.20, 0.25];  % nominal service time cost per Mbit
P.b      = [1.60, 0.60, 0.60];  % convexity of the energy cost (energy per rate^2)
P.umax0  = [0.50, 1.20, 1.40];  % max processing / uplink rate per device
P.cap0   = [Inf,  0.60, 0.60];  % per-device capacity of shared servers
P.enable = [1, 1, 1];           % tier on/off switch (used by ablation)

% ---------------- cost weights ----------------
P.wq   = 0.25;               % backlog holding cost weight
P.wT   = 2.0;                % terminal cost weight on remaining backlog
P.rho_max = 0.90;            % knee of the congestion law (C1 extension above)

% ---------------- initial distribution of backlogs ----------------
m0 = exp(-(P.q - 2).^2/(2*1.0^2));
P.m0 = m0/sum(m0);           % probability mass on the grid (sums to 1)

% ---------------- solver ----------------
P.beta    = 1.0;             % relaxation factor of the price update
P.solver  = 'clear';         % 'clear' (proposed) or 'classic'
P.maxIter = 400;
P.tol     = 2e-4;             % stop when the relative change of loads is below tol
P.useFP   = false;           % true: fictitious play step 1/(j+1)
P.adaptive = true;           % adapt beta when the residual oscillates

P = sagin_update(P);
end
