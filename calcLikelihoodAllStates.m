function likelihood = calcLikelihoodAllStates(Y,slope,sigma2,modelType)

    N = size(Y,1);
    
    if modelType == 1
        K = size(slope,1);
        logLike = -0.5*repmat(log(2*pi*sigma2'),N,1) -0.5*repmat((1./sigma2'),N,1).*(repmat(Y,1,K) - repmat(slope',N,1)).^2;
    end
    
    logOfLikeScalingFactor = max(max(logLike)); 
    logLike = max(logOfLikeScalingFactor - logLike,-200);
    likelihood = exp(-logLike)*exp(-logOfLikeScalingFactor);