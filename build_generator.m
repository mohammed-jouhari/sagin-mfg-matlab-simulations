function A = build_generator(drift, P)
%BUILD_GENERATOR Upwind finite-difference generator of dq = drift dt + sigma dW
%   on the backlog grid with reflecting boundaries at q = 0 and q = Qmax.
%   Rows of A sum to zero, so A' preserves probability mass in the FPK step.
Nq = P.Nq; dq = P.dq;
D  = 0.5*P.sigma^2/dq^2;
up = max(drift, 0)/dq + D;     % rate of moving to q + dq
dn = max(-drift, 0)/dq + D;    % rate of moving to q - dq
up(end) = 0;                   % reflecting (full buffer: work is dropped)
dn(1)   = 0;                   % reflecting (empty buffer)
main = -(up + dn);
% spdiags convention: sub-diagonal uses entries 1..N-1, super uses 2..N
A = spdiags([[dn(2:end); 0], main, [0; up(1:end-1)]], [-1 0 1], Nq, Nq);
end
