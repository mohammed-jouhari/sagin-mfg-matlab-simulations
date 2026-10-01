function plot_all_figures(Res, outDir)
%PLOT_ALL_FIGURES Draw Figs. 2-5 of the paper from the saved results.
%   plot_all_figures(Res, outDir) writes PDF, EPS and PNG files.
if nargin < 2, outDir = 'figures'; end
outDir = prepare_output_dir(outDir);
P0 = Res.P0;
fs = 7;                                    % font size for IEEE figures
lw = 1.2;                                  % line width
ms = 4;                                    % marker size

% fixed colour per scheme (same colour in every figure)
cM.MFG  = hex('#2a78d6');  cM.MFC  = hex('#eb6834');  cM.GRD = hex('#1baf7a');
cM.PROP = hex('#eda100');  cM.LOC  = hex('#e87ba4');
mk.MFG = 'o'; mk.MFC = 's'; mk.GRD = '^'; mk.PROP = 'd'; mk.LOC = 'v';
ls.MFG = '-'; ls.MFC = '-'; ls.GRD = '--'; ls.PROP = '--'; ls.LOC = '-.';
lab.MFG = 'MFG-OR (proposed)'; lab.MFC = 'MFG-OR + Pigouvian price';
lab.GRD = 'Congestion-agnostic'; lab.PROP = 'Proportional split';
lab.LOC = 'Local only';
cT = {hex('#008300'), hex('#4a3aa7'), hex('#e34948')};   % tiers L, A, S

%% ---------------- Fig. 2: equilibrium structure ----------------------
f = newfig(7.16, 2.3);
% (a) convergence of the solvers
row_axes(1); hold on;
cc = {hex('#2a78d6'), hex('#5598e7'), hex('#0d366b'), hex('#eb6834'), hex('#e34948')};
st = {'-','--','-.','-',':'};
mm = {'o','s','^','d','v'};
res = Res.conv.res;
h = zeros(1, size(res,2));
for c = 1:size(res,2)
    y = res(:,c); x = (1:numel(y)).';
    ok = ~isnan(y);
    h(c) = pline(x(ok), y(ok), cc{c}, st{c}, mm{c}, 10, lw, ms);
end
set(gca, 'YScale', 'log'); grid on; box on;
ylim([1e-8 10]); xlim([0 size(res,1)]);
xlabel('Iteration'); ylabel('Fixed-point residual');
title('(a) Solver convergence');
% PC: price clearing (proposed), LD: classic load damping
legend(h, {'PC, \beta=1', 'PC, \beta=0.5', 'PC, FP', 'LD, \beta=0.1', 'LD, \beta=0.3'}, ...
       'Location', 'southwest', 'FontSize', fs-1);
style(gca, fs);

% (b) density of the backlog at several instants
row_axes(2); hold on;
tSnap = [0 10 50 150 290];
ramp = {hex('#9ec5f4'), hex('#5598e7'), hex('#2a78d6'), hex('#1c5cab'), hex('#0d366b')};
M = Res.base.MFG.S.M;
h = zeros(1, numel(tSnap)); L = cell(1, numel(tSnap));
for s = 1:numel(tSnap)
    n = round(tSnap(s)/P0.dt) + 1;
    h(s) = plot(P0.q, M(:,n)/P0.dq, '-', 'Color', ramp{s}, 'LineWidth', lw);
    L{s} = sprintf('t = %d s', tSnap(s));
end
xlim([0 5]); grid on; box on;
xlabel('Backlog q (Mbit)'); ylabel('Density m(t,q)');
title('(b) Equilibrium density');
legend(h, L, 'Location', 'northeast', 'FontSize', fs-1);
style(gca, fs);

% (c) equilibrium policies at high (solid) and low (dashed) visibility
row_axes(3); hold on;
U = Res.base.MFG.U;
nHi = round(150/P0.dt) + 1; nLo = round(10/P0.dt) + 1;
for k = 1:3
    plot(P0.q, U(nHi,:,k), '-',  'Color', cT{k}, 'LineWidth', lw);
    plot(P0.q, U(nLo,:,k), '--', 'Color', cT{k}, 'LineWidth', lw);
end
xlim([0 4]); grid on; box on;
xlabel('Backlog q (Mbit)'); ylabel('Offloading rate u_k (Mbit/s)');
title('(c) Policy (t = 150 s / 10 s)');
style(gca, fs);

% (d) tier loads (solid) against capacities (dashed) over the LEO pass
row_axes(4); hold on;
t = P0.t(1:P0.Nt);
Ub = Res.base.MFG.S.Ubar;
for k = 1:3
    plot(t, Ub(:,k), '-', 'Color', cT{k}, 'LineWidth', lw);
end
plot(t, P0.cap(:,2), '--', 'Color', cT{2}, 'LineWidth', lw);
plot(t, P0.cap(:,3), '--', 'Color', cT{3}, 'LineWidth', lw);
xlim([0 P0.T]); grid on; box on;
xlabel('Time t (s)'); ylabel('Rate (Mbit/s)');
title('(d) Loads and capacities');
style(gca, fs);
% shared legend for (c) and (d)
hL = zeros(1, 5);
for k = 1:3
    hL(k) = plot(NaN, NaN, '-', 'Color', cT{k}, 'LineWidth', lw);
end
hL(4) = plot(NaN, NaN, 'k-',  'LineWidth', lw);
hL(5) = plot(NaN, NaN, 'k--', 'LineWidth', lw);
shared_legend(hL, {'Local', 'Aerial', 'Satellite', ...
    'Solid: t = 150 s in (c), load in (d)', 'Dashed: t = 10 s in (c), capacity in (d)'}, fs);
write_fig(f, fullfile(outDir, 'fig_equilibrium'));

%% ---------------- Fig. 3: benchmarks versus arrival rate -------------
f = newfig(7.16, 2.3);
lamL = Res.lam.list; meth = Res.lam.meth;
panels = {Res.lam.J, Res.lam.delay, Res.lam.energy, Res.lam.peakRho};
ylab = {'Average cost per device', 'End-to-end delay (s)', ...
        'Energy cost per device', 'Peak utilization'};
ttl = {'(a) Total cost', '(b) Delay per Mbit', '(c) Energy', '(d) Peak congestion'};
for p = 1:4
    row_axes(p); hold on;
    Y = panels{p};
    use = 1:numel(meth);
    if p == 4, use = find(~strcmp(meth, 'LOC')); end
    h = zeros(1, numel(use)); L = cell(1, numel(use));
    for jj = 1:numel(use)
        j = use(jj); nm = meth{j};
        h(jj) = plot(lamL, Y(:,j), 'LineStyle', ls.(nm), 'Marker', mk.(nm), ...
            'Color', cM.(nm), 'MarkerFaceColor', cM.(nm), 'LineWidth', lw, 'MarkerSize', ms);
        L{jj} = lab.(nm);
    end
    if p == 1, hS = h; LS = L; end
    if p == 2, set(gca, 'YScale', 'log'); end
    if p == 4
        plot([lamL(1) lamL(end)], [1 1], 'k:', 'LineWidth', 1.0);
    end
    xlim([lamL(1) lamL(end)]); grid on; box on;
    xlabel('Arrival rate \lambda (Mbit/s)'); ylabel(ylab{p}); title(ttl{p});
    style(gca, fs);
end
shared_legend(hS, LS, fs);
write_fig(f, fullfile(outDir, 'fig_benchmarks'));

%% ---------------- Fig. 4: finite population and sensitivity ----------
f = newfig(7.16, 2.3);
methN = Res.fin.meth; NL = Res.fin.N;
row_axes(1); hold on;
h = zeros(1, numel(methN) + 1); L = cell(1, numel(methN) + 1);
for j = 1:numel(methN)
    nm = methN{j};
    h(j) = plot(NL, Res.fin.err(:,j), 'LineStyle', ls.(nm), 'Marker', mk.(nm), ...
        'Color', cM.(nm), 'MarkerFaceColor', cM.(nm), 'LineWidth', lw, 'MarkerSize', ms);
    L{j} = lab.(nm);
end
ref = Res.fin.err(1,1)*sqrt(NL(1)./NL);
h(end) = plot(NL, ref, 'k:', 'LineWidth', 1.0); L{end} = 'O(N^{-1/2})';
hS = h; LS = L;
set(gca, 'XScale', 'log', 'YScale', 'log'); grid on; box on;
xlim([NL(1) NL(end)]);
xlabel('Number of devices N'); ylabel('Load approximation error');
title('(a) Mean-field error');
style(gca, fs);

row_axes(2); hold on;
for j = 1:numel(methN)
    nm = methN{j};
    y = Res.fin.Jmean(:,j); e = Res.fin.Jstd(:,j);
    plot(NL, y, 'LineStyle', ls.(nm), 'Marker', mk.(nm), 'Color', cM.(nm), ...
        'MarkerFaceColor', cM.(nm), 'LineWidth', lw, 'MarkerSize', ms);
    for i = 1:numel(NL)                          % +/- one standard deviation
        plot([NL(i) NL(i)], [y(i)-e(i) y(i)+e(i)], '-', 'Color', cM.(nm), 'LineWidth', 0.8);
    end
    plot([NL(1) NL(end)], Res.fin.JMF(j)*[1 1], ':', 'Color', cM.(nm), 'LineWidth', 1.0);
end
set(gca, 'XScale', 'log'); grid on; box on;
xlim([NL(1)*0.8 NL(end)*1.25]);
xlabel('Number of devices N'); ylabel('Cost per device');
title('(b) N-device cost vs. mean field');
style(gca, fs);

sensX = {Res.sens.sig, Res.sens.cap};
sensY = {Res.sens.Jsig, Res.sens.Jcap};
sensXl = {'Burstiness \sigma (Mbit/s^{1/2})', 'Aerial capacity c_A (Mbit/s)'};
sensT = {'(c) Traffic burstiness', '(d) Aerial capacity'};
methS = Res.sens.meth;
for p = 1:2
    row_axes(2 + p); hold on;
    for j = 1:numel(methS)
        nm = methS{j};
        plot(sensX{p}, sensY{p}(:,j), 'LineStyle', ls.(nm), 'Marker', mk.(nm), ...
            'Color', cM.(nm), 'MarkerFaceColor', cM.(nm), 'LineWidth', lw, 'MarkerSize', ms);
    end
    grid on; box on;
    xlim([sensX{p}(1) sensX{p}(end)]);
    xlabel(sensXl{p}); ylabel('Average cost per device'); title(sensT{p});
    style(gca, fs);
end
shared_legend(hS, LS, fs);
write_fig(f, fullfile(outDir, 'fig_scalability'));

%% ---------------- Fig. 5: ablation study ------------------------------
f = newfig(7.16, 2.3);
abl = Res.abl;
% one colour / style per variant: Full, w/o SAT, w/o UAV, w/o VIS, w/o CA, PS
cA  = {cM.MFG, hex('#008300'), hex('#4a3aa7'), hex('#e34948'), cM.GRD, cM.PROP};
lsA = {'-', '--', '-.', ':', '--', '--'};
mkA = {'o', 's', 'x', 'v', '^', 'd'};

% (a) cost breakdown
row_axes(1, 0.085); hold on;
ord = [3 5 2 4 1 6];                 % longest bars on top, legend space at the bottom
parts = abl.parts(ord, :); names = abl.names(ord);
hb = barh(1:6, parts, 0.6, 'stacked');
cPart = {hex('#1c5cab'), hex('#86b6ef'), hex('#eda100')};
for i = 1:3
    set(hb(i), 'FaceColor', cPart{i}, 'EdgeColor', [1 1 1]);
end
set(gca, 'YTick', 1:6, 'YTickLabel', names, 'YDir', 'reverse');
tot = sum(parts, 2);
if any(tot > 3*median(tot))
    xmax = 1.3*max(tot(tot < 3*median(tot)));      % clip very long bars
else
    xmax = 1.9*max(tot);                           % room for the legend
end
for v = find(tot > xmax).'
    text(0.97*xmax, v, sprintf('%.1f >', tot(v)), 'HorizontalAlignment', 'right', ...
        'Color', [1 1 1], 'FontSize', fs-1, 'FontWeight', 'bold');
end
xlim([0 xmax]); ylim([0.4 6.6]); grid on; box on;
xlabel('Average cost per device');
title('(a) Cost breakdown');
legend(hb, {'Backlog', 'Energy', 'Latency'}, 'Location', 'southeast', 'FontSize', fs-1);
style(gca, fs);

% (b) instantaneous cost rate over the pass
row_axes(2); hold on;
t = P0.t(1:P0.Nt);
for v = 1:5
    pline(t(:), abl.Jt(:,v), cA{v}, lsA{v}, mkA{v}, 100, lw, ms);
end
set(gca, 'YScale', 'log'); xlim([0 P0.T]); grid on; box on;
xlabel('Time t (s)'); ylabel('Cost rate');
title('(b) Cost rate over the pass');
style(gca, fs);

% (c) ratio to the social optimum versus lambda
row_axes(3); hold on;
jM = find(strcmp(meth, 'MFC'));
cmp = {'MFG', 'GRD', 'PROP'}; idc = [1 5 6];
for i = 1:numel(cmp)
    j = find(strcmp(meth, cmp{i}));
    plot(lamL, Res.lam.J(:,j)./Res.lam.J(:,jM), 'LineStyle', lsA{idc(i)}, 'Marker', mkA{idc(i)}, ...
        'Color', cA{idc(i)}, 'MarkerFaceColor', cA{idc(i)}, 'LineWidth', lw, 'MarkerSize', ms);
end
plot([lamL(1) lamL(end)], [1 1], 'k:', 'LineWidth', 1.0);
set(gca, 'YScale', 'log'); xlim([lamL(1) lamL(end)]); grid on; box on;
xlabel('Arrival rate \lambda (Mbit/s)'); ylabel('J / J_{MFC}');
title('(c) Ratio to social optimum');
style(gca, fs);

% (d) cost versus satellite capacity
row_axes(4); hold on;
id3 = [1 4 2];
for i = 1:3
    v = id3(i);
    plot(abl.capS, abl.JcapS(:,i), 'LineStyle', lsA{v}, 'Marker', mkA{v}, 'Color', cA{v}, ...
        'MarkerFaceColor', cA{v}, 'LineWidth', lw, 'MarkerSize', ms);
end
xlim([abl.capS(1) abl.capS(end)]); grid on; box on;
xlabel('Satellite capacity c_S^0 (Mbit/s)'); ylabel('Average cost per device');
title('(d) Satellite capacity');
style(gca, fs);
hL = zeros(1, 6);
for v = 1:6
    hL(v) = plot(NaN, NaN, 'LineStyle', lsA{v}, 'Marker', mkA{v}, 'Color', cA{v}, ...
        'MarkerFaceColor', cA{v}, 'LineWidth', lw, 'MarkerSize', ms);
end
shared_legend(hL, {'Full (MFG-OR)', 'w/o SAT', 'w/o UAV', 'w/o VIS', 'w/o CA (= CA)', 'PS'}, fs);
write_fig(f, fullfile(outDir, 'fig_ablation'));
end

% ======================================================================
function c = hex(s)
%HEX Convert '#rrggbb' to an RGB triplet in [0,1].
s = strrep(s, '#', '');
c = [hex2dec(s(1:2)), hex2dec(s(3:4)), hex2dec(s(5:6))]/255;
end

function f = newfig(w, h)
%NEWFIG Figure of w x h inches (w = 7.16 in is the IEEE text width).
f = figure('Visible', 'off', 'Color', 'w');
set(f, 'Units', 'inches', 'Position', [0.5 0.5 w h]);
set(f, 'PaperUnits', 'inches', 'PaperSize', [w h], 'PaperPosition', [0 0 w h]);
end

function ax = row_axes(i, left)
%ROW_AXES i-th axes of a 1 x 4 row, leaving space for a shared legend.
if nargin < 2, left = 0.06; end
gap = 0.072; right = 0.012;
w = (1 - left - right - 3*gap)/4;
ax = axes('Position', [left + (i-1)*(w + gap), 0.20, w, 0.56]);
end

function shared_legend(h, L, fs)
%SHARED_LEGEND One horizontal legend on top of the figure.
lg = legend(h, L, 'Orientation', 'horizontal', 'FontSize', fs);
set(lg, 'Units', 'normalized', 'Position', [0.03 0.905 0.94 0.075]);
end

function h = pline(x, y, col, lstyle, marker, every, lw, ms)
%PLINE Line with markers on a subset of points; returns a legend handle.
plot(x, y, lstyle, 'Color', col, 'LineWidth', lw);
idx = 1:every:numel(x);
plot(x(idx), y(idx), 'LineStyle', 'none', 'Marker', marker, 'Color', col, ...
     'MarkerFaceColor', col, 'MarkerSize', ms);
h = plot(NaN, NaN, 'LineStyle', lstyle, 'Marker', marker, 'Color', col, ...
     'MarkerFaceColor', col, 'LineWidth', lw, 'MarkerSize', ms);
end

function style(ax, fs)
%STYLE Common axes style.
set(ax, 'FontSize', fs, 'LineWidth', 0.6, 'XMinorGrid', 'off', 'YMinorGrid', 'off');
end

function write_fig(f, base)
%WRITE_FIG Export to PDF, EPS and PNG without stopping the program.
%   If a file cannot be written (for example because it is open in a PDF
%   viewer on Windows, or the folder is read-only) the figure is written
%   under a new name with a time stamp and a warning is shown instead of
%   an error.
fmt = {'.pdf', '-dpdf', 'vector';
       '.eps', '-depsc', 'vector';
       '.png', '-dpng', 'image'};
c = clock;
stamp = sprintf('_%02d%02d%02d', c(4), c(5), round(c(6)));
for i = 1:size(fmt, 1)
    fname = [base fmt{i,1}];
    if ~try_export(f, fname, fmt{i,2}, fmt{i,3})
        alt = [base stamp fmt{i,1}];
        if try_export(f, alt, fmt{i,2}, fmt{i,3})
            warning('plot_all_figures:locked', ...
                'Could not overwrite %s (is it open in another program?). Saved as %s', fname, alt);
        else
            warning('plot_all_figures:export', 'Could not write %s', fname);
        end
    end
end
close(f);
end

function ok = try_export(f, fname, device, content)
%TRY_EXPORT Write one file with print, then exportgraphics as a fallback.
ok = false;
if exist(fname, 'file')
    ws = warning('off', 'all');               % silence 'file in use' messages
    try
        delete(fname);
    catch
    end
    warning(ws);
    if exist(fname, 'file'), return; end      % still there: file is locked
end
try
    if strcmp(device, '-dpng')
        print(f, fname, device, '-r300');
    else
        print(f, fname, device);
    end
    ok = exist(fname, 'file') == 2;
catch
    ok = false;
end
if ~ok && exist('OCTAVE_VERSION', 'builtin') == 0 && exist('exportgraphics') ~= 0 %#ok<EXIST>
    try
        exportgraphics(f, fname, 'ContentType', content);
        ok = exist(fname, 'file') == 2;
    catch
        ok = false;
    end
end
end
