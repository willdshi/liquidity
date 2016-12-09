function P = updateTransitionMatrix(D,priorP,P)

K = size(P,1);
nStateTrans = zeros(K,K);

% Summarize number of transitions
DShift = D(2:end);
DnShift = D(1:end-1);

for i=1:K
    for j=1:K
        statenShift = (DnShift == i);
        stateShift = (DShift == j);
        nStateTrans(i,j) = sum(stateShift.*statenShift);
    end
end

% Estimate transition Probabilities  
for i=1:K
    for j=1:K
        P(i,j) = gamrnd((nStateTrans(i,j)+priorP(i,j)),1);
    end
    P(i,:) = P(i,:)/sum(P(i,:));
end