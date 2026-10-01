# MFG orchestration of multi-tier offloading in SAGIN: MATLAB code

This folder reproduces all numerical results and Figs. 2 to 5 of the paper
"Mean-Field Game Orchestration of Multi-Tier Computation Offloading in
Space-Air-Ground Integrated Networks".

## How to run

1. Open MATLAB (R2019b or newer; no toolbox is needed) in this folder.
2. Run `main_sagin_mfg`.
3. The figures are written to the `figures` subfolder next to the code (PDF,
   EPS and PNG), whatever the current folder is, and all the results are
   saved in `results_sagin_mfg.mat` in the same folder as the code.

To redraw the figures without running the experiments again:

```matlab
L = load('results_sagin_mfg.mat');
plot_all_figures(L.Res, 'figures');
```

The code also runs in GNU Octave 8 (`octave main_sagin_mfg.m`). On a machine
without a display, use `xvfb-run -a octave main_sagin_mfg.m` to get the Qt
renderer; otherwise the script falls back to gnuplot.

Run time: a few minutes in MATLAB, about one hour in Octave.

## Files

| File | Role |
|---|---|
| `main_sagin_mfg.m` | Runs the four experiments and draws the figures |
| `sagin_params.m` | All model and solver parameters (Table I of the paper) |
| `sagin_update.m` | Builds the time-varying tier quantities from the LEO visibility profile |
| `sagin_set.m` | Changes one parameter (arrival rate, capacity, ...) and rebuilds the model |
| `tier_prices.m` | Congestion law (M/M/1 type with C1 extension) and tier prices, selfish or Pigouvian |
| `hjb_backward.m` | Implicit upwind solver of the HJB equation and threshold policy (Proposition 1) |
| `fpk_forward.m` | Mass-conserving implicit solver of the FPK equation (adjoint of the HJB generator) |
| `build_generator.m` | Upwind generator of the reflected backlog diffusion |
| `clear_prices.m` | Orchestrator step: market-clearing prices by bisection, eq. (15) |
| `mfg_solve.m` | Algorithm 1 (price clearing) and the classic load-damping scheme; modes MFG, MFC, GRD |
| `heuristic_policy.m` | Proportional-split and local-only benchmarks |
| `evaluate_policy.m` | Population cost of any policy with the true congestion (breakdown, delay, drops) |
| `finite_n_sim.m` | Monte Carlo simulation with N devices and empirical congestion |
| `run_all_methods.m` | Solves and evaluates a list of schemes |
| `plot_all_figures.m` | Draws Figs. 2 to 5 |
| `prepare_output_dir.m` | Makes the output folder absolute and checks that it can be written |

## Scheme names in the code

| Code | Paper |
|---|---|
| `MFG` | MFG-OR (proposed, Nash equilibrium) |
| `MFC` | MFG-OR with Pigouvian price (social optimum) |
| `GRD` | Congestion-agnostic best response |
| `PROP` | Proportional split |
| `LOC` | Local only |

## Troubleshooting

- If a figure file is open in a PDF viewer (Windows locks it), the figure is
  saved under a new name with a time stamp and MATLAB shows a warning; the
  run does not stop. Close the viewer and redraw with `plot_all_figures`.
- If the code folder is read-only (for example a protected or synced
  folder), the figures go to `tempdir/sagin_mfg_figures` and MATLAB prints
  the location.
- The parameter helper is called `sagin_set.m` (the old name `set_param`
  clashed with a Simulink function).

