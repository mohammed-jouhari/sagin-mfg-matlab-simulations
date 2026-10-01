function S = mfg_solve(P, mode)
%MFG_SOLVE Price-clearing fixed-point solver of the SAGIN mean-field game.
%   mode = 'MFG' : Nash equilibrium of the selfish devices (proposed)
%   mode = 'MFC' : mean-field control (social optimum, Pigouvian price)
%   mode = 'GRD' : congestion-agnostic best response (one HJB pass, the
%                  devices assume empty servers)
%   P.solver = 'clear'   (default, proposed) each outer iteration j:
%     (1) orchestrator computes clearing prices from (V^j, M^j)
%     (2) prices are relaxed:  a <- (1-beta) a + beta a_new
%     (3) devices solve the HJB equation (backward)
%     (4) the population density is updated by the FPK equation (forward)
%   P.solver = 'classic' : damped fixed point on the mean field of
%     controls, Ubar <- (1-beta) Ubar + beta Ubar_new (reference scheme)
%   P.useFP = true replaces beta by the fictitious play step 1/(j+1).
%   P.adaptive = true halves beta when the residual jumps up and lets it
%   grow back (x1.1, up to P.beta) while the residual decreases.
%   Output S: U (policy), V, M (density), Ubar (loads), a (prices),
%   res (fixed-point residual per iteration, relative load change divided
%   by the step beta), iters, time.
if nargin < 2, mode = 'MFG'; end
if ~isfield(P, 'solver'), P.solver = 'clear'; end
tic;
a = tier_prices(zeros(P.Nt, P.K), P, 'MFG');
[U, V] = hjb_backward(a, P);
[M, Ubar] = fpk_forward(U, P);
if strcmpi(mode, 'GRD')
    S = struct('U', U, 'V', V, 'M', M, 'Ubar', Ubar, 'a', a, 'res', 0, ...
               'iters', 1, 'time', toc);
    return;
end
if ~isfield(P, 'adaptive'), P.adaptive = true; end
res = zeros(P.maxIter, 1);
UbarMix = Ubar;                         % used by the classic scheme only
betaCur = P.beta;
it = 0;
for it = 1:P.maxIter
    % adaptive relaxation: halve beta when the residual jumps up
    % (oscillation), let it grow back slowly while the residual decreases
    if P.adaptive && it > 2
        if res(it-1) > 1.2*res(it-2)
            betaCur = max(0.5*betaCur, 0.05);
        elseif res(it-1) < res(it-2)
            betaCur = min(1.1*betaCur, P.beta);
        end
    end
    if P.useFP
        beta = 1/(it + 1);
    else
        beta = betaCur;
    end
    if strcmpi(P.solver, 'classic')
        UbarMix = (1 - beta)*UbarMix + beta*Ubar;
        a = tier_prices(UbarMix, P, mode);
    else
        aNew = clear_prices(V, M, P, mode);
        a = (1 - beta)*a + beta*aNew;
    end
    [U, V] = hjb_backward(a, P);
    UbarOld = Ubar;
    [M, Ubar] = fpk_forward(U, P);
    scale = max(max(abs(Ubar(:))), 1e-9);
    if strcmpi(P.solver, 'classic')
        % gap between the response and the mixed mean field used for prices
        res(it) = max(abs(Ubar(:) - UbarMix(:)))/scale;
    else
        % change of the loads normalized by the step, so a small beta
        % cannot stop the iteration early
        res(it) = max(abs(Ubar(:) - UbarOld(:)))/(scale*beta);
    end
    if res(it) < P.tol
        break;
    end
end
S = struct('U', U, 'V', V, 'M', M, 'Ubar', Ubar, 'a', a, 'res', res(1:it), ...
           'iters', it, 'time', toc);
end
