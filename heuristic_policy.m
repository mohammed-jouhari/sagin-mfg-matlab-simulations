function U = heuristic_policy(P, type)
%HEURISTIC_POLICY Benchmark policies that do not solve any game.
%   type = 'PROP' : backlog-driven total rate lambda + gamma*q, split among
%                   the tiers in proportion to their current capacity
%   type = 'LOC'  : all work processed locally at the rate lambda + gamma*q
Nq = P.Nq; Nt = P.Nt; K = P.K;
gamma = 0.25;
U = zeros(Nt, Nq, K);
utot = P.lambda + gamma*P.q.';                 % 1 x Nq
for n = 1:Nt
    switch upper(type)
        case 'PROP'
            w = [P.umax(n,1), P.cap(n,2)*P.enable(2), P.cap(n,3)*P.enable(3)];
            w = w/sum(w);
            for k = 1:K
                U(n,:,k) = min(w(k)*utot, P.umax(n,k));
            end
        case 'LOC'
            U(n,:,1) = min(utot, P.umax(n,1));
        otherwise
            error('heuristic_policy: unknown type %s', type);
    end
end
end
