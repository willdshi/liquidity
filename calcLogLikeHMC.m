function logLike = calcLogLikeHMC(Y,pY,sigma2Time)
    
    logLike = -0.5*sum(log(sigma2Time)) -0.5*sum((1./sigma2Time).*((Y-pY).^2));