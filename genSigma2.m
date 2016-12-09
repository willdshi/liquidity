function [sigma2,sigma2Time] = genSigma2(Y,D,pY,sigma2,sigma2Shape,sigma2Scale)

K = size(sigma2,1);
N = size(Y,1);
sigma2Time = zeros(N,1);

SSTime = (Y-pY).^2;

for i=1:K

    stateIndicator = (D == i);
        
    N = sum(stateIndicator);
    SS = sum(SSTime.*stateIndicator);

    sigma2(i) = 1/gamrnd(0.5*N + sigma2Shape,1/(0.5*SS + sigma2Scale));

end

for i=1:size(D,1)
    sigma2Time(i) = sigma2(D(i));
end