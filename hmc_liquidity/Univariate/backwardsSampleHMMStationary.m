function [fStateGDataAll,D,pY] = backwardsSampleHMMStationary(fStateGDataAll,D,pY,fStateGData,fStateGDataLag,P,slope)

[N,K] = size(fStateGData);

for ti=1:N

    i = N + 1 - ti;

    if i == N
        fStateGDataAll(N,:) = fStateGData(N,:);
    else
        fStateGDataAll(i,:) = (repmat(fStateGData(i,:)',1,K ).*P)*(fStateGDataAll(i+1,:)./fStateGDataLag(i+1,:))';
    end

    D(i) = loadedDie(fStateGDataAll(i,:)');
    pY(i) = slope(D(i));

end