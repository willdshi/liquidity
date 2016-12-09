function [pY,slope] = genSlope(Y,D,sigma2,slope,slopeMean,slopeVar,maxLb,maxUb)

N = size(D,1);
K = size(slope,1);

pY = zeros(N,1);

for i=1:K
    state = (D == i);
    varY(i) = 1/(sum(state)/sigma2(i) + 1/(slopeVar(i)*sigma2(i)));
    meanY(i) = (sum(state.*Y)/sigma2(i) + slopeMean(i)/(slopeVar(i)*sigma2(i)))*varY(i);
    % slope(i) = meanY(i) + sqrt(varY(i))*randn();
    if (i == 1) || (i == K)
        if i == 1
            slope(i) = sliceNormalLbAndUb(slope(i),meanY(i),varY(i),maxLb,slope(i+1));
        else
            slope(i) = sliceNormalLbAndUb(slope(i),meanY(i),varY(i),slope(i-1),maxUb);
        end
    else
            slope(i) = sliceNormalLbAndUb(slope(i),meanY(i),varY(i),slope(i-1),slope(i+1));
    end
    
    pY = pY + state*slope(i);
end