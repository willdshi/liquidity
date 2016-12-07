function [fStateGDataLag,fStateGData] = filterForwardHMMStationary(fDataGState,fStateGDataLag,fStateGData,P,nu)

N = size(fDataGState,1);

for i=1:N

    if i == 1
        fStateGDataLag(i,:) = nu';
    else
        fStateGDataLag(i,:) = (fStateGData(i-1,:)*P);
    end

    fDataGDataLag(i) = fDataGState(i,:)*fStateGDataLag(i,:)';
    fStateGData(i,:) = (fDataGState(i,:).*fStateGDataLag(i,:))/fDataGDataLag(i);

end