# Mean-Field Game Orchestration of Multi-Tier Offloading in SAGIN (MATLAB code)

This repository contains the MATLAB code of the letter

> M. Jouhari and H. Benaddi, "Mean-Field Game Orchestration of Multi-Tier
> Computation Offloading in Space-Air-Ground Integrated Networks,"
> submitted to *IEEE Networking Letters*.

It reproduces all the numerical results of the letter (Fig. 1, Table II) and
draws three additional figures that do not appear in the letter.

## What the code does

Thousands of IoT devices share an aerial edge server (UAV or HAP) and a LEO
satellite server whose link changes during the pass. The code solves the
mean-field game of controls of the letter and computes:

- one congestion price per tier and per time slot, broadcast by the
  orchestrator (Nash price or Pigouvian price);
- the threshold offloading rule of every device (Proposition 1), which needs
  only the prices and the device's own backlog.

The price-clearing solver (Algorithm 1) does not depend on the number of
devices. The same prices serve a population of a hundred or a hundred
thousand devices.

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

## Where each result of the letter comes from

| Letter | Code |
|---|---|
| Table I (parameters) | `sagin_params.m` |
| Fig. 1 (cost, delay, energy, peak utilization vs. arrival rate) | Experiment 2 in `main_sagin_mfg.m`, file `figures/fig_benchmarks.*` |
| Table II, fixed-point residual | Experiment 1 (console output) |
| Table II, finite population and sensitivity | Experiment 3 (console output) |
| Table II, ablation | Experiment 4 (console output) |
| Algorithm 1 | `mfg_solve.m` with `clear_prices.m` |
| Price-clearing equation (11) | `clear_prices.m` |
| Proposition 1 (threshold policy) | `hjb_backward.m` |

The files `fig_equilibrium.*`, `fig_scalability.*` and `fig_ablation.*` give
more detail on the same experiments (equilibrium density and policy, finite-N
error, sensitivity, cost breakdown over the pass). They are not in the letter.

## Using the solver in your own work

The solver can be called on its own, for example to use MFG-OR as a baseline
or to test other parameters:

```matlab
P = sagin_params();                  % default parameters (Table I)
P = sagin_set(P, 'lambda', 0.8);     % change one parameter and rebuild the model
S = mfg_solve(P, 'MFG');             % 'MFG' (Nash), 'MFC' (Pigouvian), 'GRD' (congestion-agnostic)
a = S.a;                             % broadcast prices, Nt x K
U = S.U;                             % offloading policy of the devices
R = evaluate_policy(S.U, P);         % R.J, R.delayE2E, R.energy, R.peakRho, R.dropRatio
```

`sagin_set` accepts `'lambda'`, `'sigma'`, `'capA'`, `'capS'`, `'enable'` and
`'etaConst'`. For any other change, edit the fields of `P` and call
`P = sagin_update(P)`.

## Files

| File | Role |
|---|---|
| `main_sagin_mfg.m` | Runs the four experiments and draws the figures |
| `sagin_params.m` | All model and solver parameters (Table I of the letter) |
| `sagin_update.m` | Builds the time-varying tier quantities from the LEO visibility profile |
| `sagin_set.m` | Changes one parameter (arrival rate, capacity, ...) and rebuilds the model |
| `tier_prices.m` | Congestion law (M/M/1 type with C1 extension) and tier prices, selfish or Pigouvian |
| `hjb_backward.m` | Implicit upwind solver of the HJB equation and threshold policy (Proposition 1) |
| `fpk_forward.m` | Mass-conserving implicit solver of the FPK equation (adjoint of the HJB generator) |
| `build_generator.m` | Upwind generator of the reflected backlog diffusion |
| `clear_prices.m` | Orchestrator step: market-clearing prices by bisection, eq. (11) |
| `mfg_solve.m` | Algorithm 1 (price clearing) and the classic load-damping scheme; modes MFG, MFC, GRD |
| `heuristic_policy.m` | Proportional-split and local-only benchmarks |
| `evaluate_policy.m` | Population cost of any policy with the true congestion (breakdown, delay, drops) |
| `finite_n_sim.m` | Monte Carlo simulation with N devices and empirical congestion |
| `run_all_methods.m` | Solves and evaluates a list of schemes |
| `plot_all_figures.m` | Draws all the figures |
| `prepare_output_dir.m` | Makes the output folder absolute and checks that it can be written |

## Scheme names in the code

| Code | Letter |
|---|---|
| `MFG` | MFG-OR (proposed, Nash equilibrium) |
| `MFC` | MFG-OR with Pigouvian price (social optimum) |
| `GRD` | Congestion-agnostic (CA) |
| `PROP` | Proportional split (PS) |
| `LOC` | Local only (LO) |

## Troubleshooting

- If a figure file is open in a PDF viewer (Windows locks it), the figure is
  saved under a new name with a time stamp and MATLAB shows a warning; the
  run does not stop. Close the viewer and redraw with `plot_all_figures`.
- If the code folder is read-only (for example a protected or synced
  folder), the figures go to `tempdir/sagin_mfg_figures` and MATLAB prints
  the location.
- The parameter helper is called `sagin_set.m` (the old name `set_param`
  clashed with a Simulink function).

## How to cite

If you use this code or the model in your work, please cite the letter:

```bibtex
@misc{jouhari2026mfgsagin,
  author = {Jouhari, Mohammed and Benaddi, Hafsa},
  title  = {Mean-Field Game Orchestration of Multi-Tier Computation Offloading
            in Space-Air-Ground Integrated Networks},
  note   = {Submitted to IEEE Networking Letters},
  year   = {2026}
}
```

## License

MIT License. See `LICENSE`.

