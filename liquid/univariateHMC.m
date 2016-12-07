function results = univariateHMC(params, Y)
%% Univariate Hidden Markov Chain inference tool.
%  John Liechty, May 21, 2013
%  Office of Financial Research, U.S. Department of Treasury
%  all rights reserved.
%
% Model: for versions 1.0 to 1.2 the dynamical system is described by a
% simple observation equation and a traditional, discrite-time (hidden)
% Markov chain.
%
% System Equation: y_t = slope(D_t) + sqrt(sigma2) * e_t  and e_t ~ N(0,1)
%
%
% Version 1.1 - V1p1
%
%  Converted FB filtering to routines (note that these are only time
%  homogenious versions of the routines - the common factor approach would
%  need to be time-inhomogenioius, need to include a more complicated
%  transition matrix).
%
%  Added a finite mixture model to the random starting procedure.
%
%  Added likelihood calculation (for model choice)
%
%  Added forward prediction of HMM and Level - including asymptotic level
%
%  Version 1.0 - V1p0
%  
%  Makes inference about the different levels of liquidity (or other
%  time-series of ineterest), with the assumption that the dynamics of the
%  time-series are driven by a hidden (unobserved Markov chain).  Each time
%  the Markov chain changes state, the dynamics of the observed time-series
%  changes (e.g. the level of liquidty in a market changes).  This type of
%  model could be viewed as a discrete time, discretes state space
%  version of a Kalman Filter - or a version of the Baum-Welch algorithm.  
%  Also see West and Harrison (1997) - Bayesian Forecasting and Dynamic 
%  Models - along with Cappe, Moulines and Ryden (2005)-Inference in Hidden 
%  Markov Models - for related discussions.
%
%  Inference is done using Markov Chain Monte Carlo (MCMC) methods, see
%  Brooks, Gelman, Jones and Meng (2011) - Handbook of Markov Chain Monte
%  Carlo - and Gelman, Carlin, Stern and Rubin (2000) - bayesian Data
%  Analysis, for discussions of MCMC methods.

% close all;
% clear all;
% clc;

    %% Data structures, parameters and control variables defined

    % Parameters
    logInputData = params.logInputData; 
    N = size(Y, 1);
    % Number of hidden states (e.g., 3)
    K = params.K;	    
    sample = params.sample; 
    burnin = params.burnin; 
    % Typically, this is: round(0.5*burnin)
    priorChange = params.priorChange;
    numStandardDevForStart = params.numStandardDevForStart; 
    % 1 = Constant level with normal errors; 
    % 2 = Autoreg./Mean Reversion around constant level w/ normal errors
    modelType = params.modelType;
	
    % Prior values
    slopeVar = ones(K,1)*params.priorSlopeVarRescale;
    slopeMean = zeros(K,1);
    sigma2Shape = params.priorSigma2Shape;
    sigma2Scale = params.priorSigma2Scale;
    % of observed data used to set shape and scale; keep between 0 and 1,
    delta = params.priorDelta; 

    logLikeDraws = zeros(burnin+sample+1,1);

    % Observation equation parameters
    
    % Constant level
    slope = zeros(K,1); 
    % Variance of deviations from constant level
    sigma2 = zeros(K,1);
    % Predicted Observed Data - mean value
    pY = zeros(N,1); 
    % Time varying variance
    sigma2Time = zeros(N,1);        

    % System equation parameters
    
    % Transition matrix for HMC
    P = zeros(K,K);         
    % Current realization of HMC
    D = zeros(N,1);         
    % Starting probability vector; do not update
    nu = zeros(K,1);        

    %% Working with the data

    if logInputData
        Y = log(Y);
    end

    maxY = max(max(Y),mean(Y)+numStandardDevForStart*sqrt(var(Y)));
    minY = min(min(Y),mean(Y)-numStandardDevForStart*sqrt(var(Y)));

    % Conditional distrib's for filter forward, sample backwards algorithm
    fStateGData = zeros(N,K);       % f(D_i|F_i)    F_i = {Y_1,...,Y_i}
    fStateGDataLag = zeros(N,K);    % f(D_i|F_{i-1})
    fStateGDataAll = zeros(N,K);    % f(D_i|F_N)

    % For Moment Summaries
    sfStateGDataAll1 = zeros(N,K);
    sfStateGDataAll2 = zeros(N,K);
    sD = zeros(N,2);
    spY = zeros(N,2);

    sSlope = zeros(K,2);
    sP1 = zeros(K,K);
    sP2 = zeros(K,K);
    snu = zeros(K,2);
    sSigma2 = zeros(K,2);

    % Prior for transition matrix - forces longer waiting times
    priorP = ones(K,K)*delta + delta*N*eye(K);
    % Allow highest state to be short lived ...
    priorP(K,K) = priorP(K,K)*delta;

    %% Create Initial Estimates

    % System equation parameters
    D = zeros(N,1);         % Current realization of HMC
    pY = zeros(N,1);

    meanOfY = mean(Y);
    varOfY = var(Y);

    for i=1:K 
        slope(i) = meanOfY + ...
            sqrt(varOfY)*numStandardDevForStart*((i-1)*2/(K-1)-1);
    end

    sigma2 = varOfY*ones(K,1);
    nu = ones(K,1)*(1/K); 

    %Set the Hidden Markov Chain based on max likelihood
    fDataGState = calcLikelihoodAllStates(Y,slope,sigma2,modelType);
    [m,I] = sort(fDataGState,2);
    D = I(:,end);

    for i=1:K
        state = (D == i);
        pY = pY + state*slope(i); 
    end     

    % Update Markov Chain Parameters
    % Summarize number of transitions
    P = updateTransitionMatrix(D,priorP,P); 

    % Update Observation or Likelihood Parameters
    % Update slope
    [pY,slope] = genSlope(Y,D,sigma2,slope,slopeMean,slopeVar,minY,maxY);

    % Set sigma2Shape and sigma2Scale
    sigma2Shape = delta*N;
    sigma2Scale = delta*sum((Y - pY).^2);

    % Update sigma2
    [sigma2,sigma2Time] = genSigma2(Y,D,pY,sigma2,sigma2Shape,sigma2Scale);


    %% Markov chain Monte Carlo (MCMC) analysis

    logLikeDraws(1) = calcLogLikeHMC(Y,pY,sigma2Time);

    for n = 1:burnin+sample

        if (n==priorChange)
            sigma2Scale = delta*sigma2Scale;
            sigma2Shape = delta*sigma2Shape;
        end   

        % Update Hidden State: Filter Forward Backwards Sampling
        % Filter Forward
        fDataGState = calcLikelihoodAllStates(Y,slope,sigma2,modelType);
        [fStateGDataLag,fStateGData] = filterForwardHMMStationary(...
            fDataGState,fStateGDataLag,fStateGData,P,nu);

        % Backwards Sample
        [fStateGDataAll,D,pY] = backwardsSampleHMMStationary(...
            fStateGDataAll,D,pY,fStateGData,fStateGDataLag,P,slope); 

        % Update Markov Chain Parameters
        P = updateTransitionMatrix(D,priorP,P);

        % Update Observation or Likelihood Parameters
        
        % Update slope
        [pY,slope] = ...
            genSlope(Y,D,sigma2,slope,slopeMean,slopeVar,minY,maxY);

        % Update sigma2
        [sigma2,sigma2Time] = ...
            genSigma2(Y,D,pY,sigma2,sigma2Shape,sigma2Scale);

        % Store parameter estimates
        if (n > burnin)
           % Store Moments for parameters
           sfStateGDataAll1 = sfStateGDataAll1 + fStateGDataAll;
           sfStateGDataAll2 = ...
               sfStateGDataAll2 + fStateGDataAll.*fStateGDataAll;
           sD(:,1) = sD(:,1) + D;
           sD(:,2) = sD(:,2) + D.*D;
           spY(:,1) = spY(:,1) + pY;
           spY(:,2) = spY(:,2) + pY.*pY;       

           sSlope(:,1) = sSlope(:,1) + slope;
           sSlope(:,2) = sSlope(:,2) + slope.*slope;
           sP1 = sP1 + P;
           sP2 = sP2 + P.*P;
           snu(:,1) = snu(:,1) + nu;
           sny(:,2) = snu(:,2) + nu;
           sSigma2(:,1) = sSigma2(:,1) + sigma2;
           sSigma2(:,2) = sSigma2(:,2) + sigma2.*sigma2;       
        end

        logLikeDraws(n+1) = calcLogLikeHMC(Y,pY,sigma2Time);

    end

    %% Generate Reports

    % Calculate moment summaries
    sfStateGDataAll1 = sfStateGDataAll1/sample;
    sfStateGDataAll2 = ...
        sqrt(sfStateGDataAll2/sample - sfStateGDataAll1.*sfStateGDataAll1);
    sD(:,1) = sD(:,1)/sample;
    sD(:,2) = sqrt(sD(:,2)/sample - sD(:,1).*sD(:,1));
    spY(:,1) = spY(:,1)/sample;
    spY(:,2) = sqrt(spY(:,2)/sample - spY(:,1).* spY(:,1));       

    sSlope(:,1) = sSlope(:,1)/sample;
    sSlope(:,2) = sqrt(sSlope(:,2)/sample - sSlope(:,1).*sSlope(:,1));
    sP1 = sP1/sample;
    sP2 = sqrt(sP2/sample - sP1.*sP1);
    snu(:,1) = snu(:,1)/sample;
    sny(:,2) = sqrt(snu(:,2)/sample - snu(:,1).*snu(:,1));
    sSigma2(:,1) = sSigma2(:,1)/sample;
    sSigma2(:,2) = sqrt(sSigma2(:,2)/sample - sSigma2(:,1).*sSigma2(:,1)); 

    % LogLike Reports
    results.logLikeDraws = logLikeDraws;
    results.Y = Y;
    results.sny = sny;
    results.spY = spY;
    results.sD = sD;
    results.sfStateGDataAll1 = sfStateGDataAll1;
    results.sfStateGDataAll2 = sfStateGDataAll2;
    results.sSlope = sSlope;
    results.sSigma2 = sSigma2;
    results.sP1 = sP1;
    results.sP2 = sP2;
    
end

