function out = run_all_methods(P, methods)
%RUN_ALL_METHODS Solve / build and evaluate the requested schemes.
%   methods : cell array with any of 'MFG','MFC','GRD','PROP','LOC'
%   out.(name).R : evaluation struct (see evaluate_policy)
%   out.(name).U : policy,  out.(name).S : solver output (game schemes)
if nargin < 2, methods = {'MFG','MFC','GRD','PROP','LOC'}; end
out = struct();
for i = 1:numel(methods)
    name = upper(methods{i});
    switch name
        case {'MFG','MFC','GRD'}
            S = mfg_solve(P, name);
            U = S.U;
        case {'PROP','LOC'}
            S = struct('iters', 0, 'time', 0, 'res', 0);
            U = heuristic_policy(P, name);
        otherwise
            error('run_all_methods: unknown method %s', name);
    end
    out.(name).U = U;
    out.(name).S = S;
    out.(name).R = evaluate_policy(U, P);
end
end
