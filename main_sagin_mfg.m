%MAIN_SAGIN_MFG  Mean-field game orchestration of multi-tier offloading in SAGIN
%   Runs all the experiments of the paper and draws Figs. 2-5.
%   Tested with MATLAB (R2019b or newer) and GNU Octave 8.4.
%   Typical run time: a few minutes in MATLAB, about one hour in Octave.
%   The results are saved in results_sagin_mfg.mat and the figures in the
%   subfolder 'figures', both next to this script. To redraw the figures
%   without running the experiments again:
%       L = load('results_sagin_mfg.mat'); plot_all_figures(L.Res, 'figures');
%   Close any PDF viewer that has an old figure open before running.
clear; close all; clc;
isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
if isOctave
    % Octave: use Qt when a display exists (e.g. xvfb-run), else gnuplot
    if any(strcmp(available_graphics_toolkits(), 'qt')) && ~isempty(getenv('DISPLAY'))
        graphics_toolkit('qt');
    else
        graphics_toolkit('gnuplot');
    end
end
% all outputs go next to this script, whatever the current folder is
codeDir = fileparts(mfilename('fullpath'));
if isempty(codeDir), codeDir = pwd; end
outDir = prepare_output_dir(fullfile(codeDir, 'figures'));
P0 = sagin_params();
Res = struct();
Res.P0 = P0;
tStart = tic;

%% ===== Experiment 1: equilibrium structure and solver convergence ======
fprintf('Experiment 1: equilibrium at the nominal point (lambda = %.1f)\n', P0.lambda);
base = run_all_methods(P0, {'MFG','MFC','GRD','PROP','LOC'});
Res.base = base;
fprintf('  MFG converged in %d iterations (%.1f s)\n', base.MFG.S.iters, base.MFG.S.time);

cfg = {'clear', 1.0, false, 'Price clearing, \beta=1';
       'clear', 0.5, false, 'Price clearing, \beta=0.5';
       'clear', NaN, true,  'Price clearing, FP';
       'classic', 0.1, false, 'Load damping, \beta=0.1';
       'classic', 0.3, false, 'Load damping, \beta=0.3'};
nIt = 80;
Res.conv.res = nan(nIt, size(cfg,1));
Res.conv.labels = cfg(:,4);
for c = 1:size(cfg,1)
    P = P0; P.solver = cfg{c,1}; P.useFP = cfg{c,3}; P.adaptive = false;
    if ~P.useFP, P.beta = cfg{c,2}; end
    P.maxIter = nIt; P.tol = 1e-7;
    S = mfg_solve(P, 'MFG');
    Res.conv.res(1:numel(S.res), c) = S.res(:);
    fprintf('  %-28s final residual %.2e\n', cfg{c,4}, S.res(end));
end

%% ===== Experiment 2: benchmarks versus the arrival rate =================
lamList = 0.4:0.1:1.1;
meth = {'MFG','MFC','GRD','PROP','LOC'};
nL = numel(lamList); nM = numel(meth);
Res.lam.list = lamList; Res.lam.meth = meth;
Res.lam.J = zeros(nL,nM); Res.lam.delay = zeros(nL,nM);
Res.lam.energy = zeros(nL,nM); Res.lam.peakRho = zeros(nL,nM);
Res.lam.drop = zeros(nL,nM); Res.lam.Jd = zeros(nL,nM);
fprintf('Experiment 2: sweep of the arrival rate\n');
for i = 1:nL
    P = sagin_set(P0, 'lambda', lamList(i));
    o = run_all_methods(P, meth);
    for j = 1:nM
        R = o.(meth{j}).R;
        Res.lam.J(i,j) = R.J;       Res.lam.delay(i,j) = R.delayE2E;
        Res.lam.energy(i,j) = R.energy; Res.lam.peakRho(i,j) = R.peakRho;
        Res.lam.drop(i,j) = R.dropRatio; Res.lam.Jd(i,j) = R.Jd;
    end
    fprintf('  lambda = %.1f  J: MFG %.3f  MFC %.3f  GRD %.3f  PROP %.3f  LOC %.3f\n', ...
        lamList(i), Res.lam.J(i,:));
end

%% ===== Experiment 3: finite population and sensitivity ==================
fprintf('Experiment 3: finite-N validation and sensitivity\n');
NList = [20 50 100 200 500 1000 2000 5000];
nRuns = 6;
methN = {'MFG','MFC','GRD','PROP'};
Res.fin.N = NList; Res.fin.meth = methN;
Res.fin.Jmean = zeros(numel(NList), numel(methN));
Res.fin.Jstd  = zeros(numel(NList), numel(methN));
Res.fin.err   = zeros(numel(NList), numel(methN));
Res.fin.JMF   = zeros(1, numel(methN));
for j = 1:numel(methN)
    b = base.(methN{j});
    Res.fin.JMF(j) = b.R.J;
    for i = 1:numel(NList)
        o = finite_n_sim(b.U, P0, NList(i), nRuns, b.R.Ubar, 100 + i);
        Res.fin.Jmean(i,j) = mean(o.J);
        Res.fin.Jstd(i,j)  = std(o.J);
        Res.fin.err(i,j)   = mean(o.err);
    end
    fprintf('  %-4s  N=%d: J = %.4f (mean field %.4f), error = %.4f\n', methN{j}, ...
        NList(end), Res.fin.Jmean(end,j), Res.fin.JMF(j), Res.fin.err(end,j));
end

sigList = [0.2 0.4 0.6 0.8 1.0];
capList = [0.5 0.6 0.7 0.8 0.9];
methS = {'MFG','MFC','GRD','PROP'};
Res.sens.sig = sigList; Res.sens.cap = capList; Res.sens.meth = methS;
Res.sens.Jsig = zeros(numel(sigList), numel(methS));
Res.sens.Jcap = zeros(numel(capList), numel(methS));
for i = 1:numel(sigList)
    o = run_all_methods(sagin_set(P0, 'sigma', sigList(i)), methS);
    for j = 1:numel(methS), Res.sens.Jsig(i,j) = o.(methS{j}).R.J; end
end
for i = 1:numel(capList)
    o = run_all_methods(sagin_set(P0, 'capA', capList(i)), methS);
    for j = 1:numel(methS), Res.sens.Jcap(i,j) = o.(methS{j}).R.J; end
end
fprintf('  sensitivity sweeps done\n');

%% ===== Experiment 4: ablation study ======================================
fprintf('Experiment 4: ablation\n');
abl = struct();
abl.names = {'Full','w/o SAT','w/o UAV','w/o VIS','w/o CA','MFC'};
Rab = cell(1, 6);
Rab{1} = base.MFG.R;
Rab{2} = run_all_methods(sagin_set(P0, 'enable', [1 1 0]), {'MFG'}); Rab{2} = Rab{2}.MFG.R;
Rab{3} = run_all_methods(sagin_set(P0, 'enable', [1 0 1]), {'MFG'}); Rab{3} = Rab{3}.MFG.R;
Pc = sagin_set(P0, 'etaConst', []);                  % visibility-unaware model
Sc = mfg_solve(Pc, 'MFG');
Rab{4} = evaluate_policy(Sc.U, P0);                   % evaluated on the true pass
Rab{5} = base.GRD.R;                                  % congestion-agnostic
Rab{6} = base.MFC.R;
abl.parts = zeros(6, 3);                              % [backlog, energy, latency]
abl.Jt = zeros(P0.Nt, 6);
for v = 1:6
    abl.parts(v,:) = [Rab{v}.Jq, Rab{v}.Je, Rab{v}.Jd];
    abl.Jt(:,v) = Rab{v}.Jt;
    fprintf('  %-8s J = %.3f  (backlog %.3f, energy %.3f, latency %.3f)\n', ...
        abl.names{v}, Rab{v}.J, abl.parts(v,:));
end
capSList = [0.3 0.45 0.6 0.75 0.9];
abl.capS = capSList;
abl.JcapS = zeros(numel(capSList), 3);                % [Full, w/o VIS, w/o SAT]
Rnos = Rab{2}.J;
for i = 1:numel(capSList)
    Pi = sagin_set(P0, 'capS', capSList(i));
    o  = run_all_methods(Pi, {'MFG'});
    Si = mfg_solve(sagin_set(Pi, 'etaConst', []), 'MFG');
    Ri = evaluate_policy(Si.U, Pi);
    abl.JcapS(i,:) = [o.MFG.R.J, Ri.J, Rnos];
end
Res.abl = abl;
Res.runtime = toc(tStart);
fprintf('Total run time: %.1f s\n', Res.runtime);

resFile = fullfile(fileparts(outDir), 'results_sagin_mfg.mat');
try
    save(resFile, 'Res', '-v7');
catch err
    resFile = fullfile(outDir, 'results_sagin_mfg.mat');
    warning('main_sagin_mfg:save', 'Could not save next to the code (%s). Saving in %s', ...
        err.message, outDir);
    save(resFile, 'Res', '-v7');
end
fprintf('Results saved in %s\n', resFile);
plot_all_figures(Res, outDir);
fprintf('Figures written to %s\n', outDir);
