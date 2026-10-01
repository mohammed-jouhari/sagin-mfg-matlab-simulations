function P = sagin_set(P, name, value)
%SAGIN_SET Change one model parameter and rebuild the dependent quantities.
%   Supported names: 'lambda', 'sigma', 'capA', 'capS', 'enable', 'etaConst'
%   'etaConst' replaces the LEO visibility profile by its time average
%   (used by the visibility-unaware ablation).
switch name
    case 'lambda',   P.lambda = value;
    case 'sigma',    P.sigma = value;
    case 'capA',     P.cap0(2) = value;
    case 'capS',     P.cap0(3) = value;
    case 'enable',   P.enable = value;
    case 'etaConst', P.eta = mean(P.eta)*ones(size(P.eta));
    otherwise, error('sagin_set: unknown parameter %s', name);
end
P = sagin_update(P);
end
