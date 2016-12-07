%% Univariate Hidden Markov Chain inference tool.
%  John Liechty, May 21, 2013
%  Office of Financial Research, U.S. Department of Tresasury
%  all rights reserved.
%
% Model: for versions 1.0 to 1.2 the dynamical system is described by a
% simple observation equation and a traditional, discrite-time (hidden)
% Markov chain.
%
% Observation Equation: y_t = slope(D_t) + sqrt(sigma2) * e_t  and e_t ~ N(0,1)
%
% System Equation: D_t ~ MC(P,nu,D_{t-1})  - drawn from a Markov Chain
% distribution
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

close all;
clear all;
clc;

%% Data structures, parameters and control variables defined
N = 500;            % number of observations
K = 3;              % number of hidden states - synthetic data is hardwried
                    % to having just three states (can be generalized, of
                    % course)

burnin = 2000;
sample = 1000;
                    
NumStandardDevForStart = 2;                    
                    
printFigures = true;
debugMCMC = true;
genData = false;
randomStart = true;
syntheticData = false;
logInputData = true;
trunkOutliers = true;
smoothTrunk = true;     % Calculates a 'moving average' z-score
smoothStdInTime = 15;
numStd = 2;
missingData = false;
NumMissing = 15;         % Must be less than N. Only used if genData = true

projectName = 'testJustHMC';
reportFileName = [projectName 'ReportHMC.txt'];
summaryPlotFileName = [projectName 'SummaryPlotFilename.txt'];
logLikeFileName = [projectName 'LogLike.txt'];

predUnivariateDataFileName = [projectName 'predUnivariateData.mat'];
hiddenMCFileName = [projectName 'hiddenMC.mat'];
modelParametersFileName = [projectName 'modelParameters.mat'];

if syntheticData
    trueParamsFileName = [projectName 'TrueParams.mat'];    
end

dataInputFileName = '2004NEWCRSPKYLEOBIZ_AVG_SIC2.txt';
%dataInputFileName = 'VIXKYLEOBIZ_LOGAVG_MAT3.txt';
%dataInputFileName = 'Series2Test.txt';
%dataInputFileName = 'Series1Test.txt';
%dataInputFileName = 'univariateData.txt'; % Default name for synthetic data
%dataInputMatlabFileName = 'univariateData.mat'; % Default name for synthetic data

thinPrintScreen = 25;

if printFigures && (debugMCMC || genData)
    figDataHMC = figure;
end

if printFigures && debugMCMC
    figHMCFilterForward = figure;
    figHMCFilterBackward = figure;
    figDataHMCLevel = figure;
end

logLikeDraws = zeros(burnin+sample+1,1);

modelType = 1;      % 1 = Constant level, with normal errors
                    % 2 = Autoregressive/Mean Reversion around constant
                    % level, with normal errors (initially just 1
                    % implemented)

% Observation equation parameters
slope = zeros(K,1);     % Constant level
sigma2 = 0;             % Variance of deviationsn from constant level
Y = zeros(N,1);         % Observed data
pY = zeros(N,1);        % Predicted Observed Data - mean value

% System equation parameters
P = zeros(K,K);         % Transition matrix for HMC
D = zeros(N,1);         % Current realization of HMC
nu = zeros(K,1);        % Initial/starting probability vector of HMC do not update

% Summary statitics
nStateTrans = zeros(K,K);
meanY = zeros(K,1);
varY = zeros(K,1);

% Prior values
slopeVar = ones(K,1)*100;
slopeMean = zeros(K,1);
sigma2Shape = 1;
sigma2Scale = 1;
deltaPrior = 0.1;            % Keep between 0 and 1, % of observed data used to set shape and scale
deltaPriorP = 1;

%% Generate Synthetic Data or Load Real Data
if genData
 
    if missingData
       Ymiss = zeros(N,1);
       for i=1:NumMissing
          n = floor(N*rand) + 1;
          Ymiss(n) = 1;
       end
    end
   
    % Set System and Observation equation parameters
    slope(1) = 1;
    slope(2) = 3;
    slope(3) = 7;
    
    sigma2 = 0.5;
    
    nu(1) = 0.8;
    nu(2) = 0.15;
    nu(3) = 0.05;
    
    % Transition from state 1 to other states
    P(1,1) = 0.95;
    P(1,2) = 0.03;
    P(1,3) = 0.02;
    
    % Transition from state 2 to other states
    P(2,1) = 0.05;
    P(2,2) = 0.90;
    P(2,3) = 0.05;   
    
    % Transition from state 3 to other states
    P(3,1) = 0.05;
    P(3,2) = 0.15;
    P(3,3) = 0.80;
    
    % Generate Realization of HMC
    prob = zeros(N,K);
    
    for i=1:N
        
        if i == 1
            D(i) = loadedDie(nu);
        else
            D(i) = loadedDie(P(D(i-1),:)');
        end
        
        prob(i,D(i)) = 1;
        Y(i) = slope(D(i)) + sqrt(sigma2)*randn();
        pY(i) = slope(D(i));
    
    end
    
    if syntheticData
        slopeTrue = slope;
        sigma2True = sigma2;
        PTrue = P;
        DTrue = D;
        nuTrue = nu;
        probTrue = prob;
        pYTrue = pY;
    end    
    
    if printFigures
        figure(figDataHMC);
        subplot(2,1,1);
        plot(Y);
        hold;
        plot(pY,'r.');
        if missingData
           for i=1:N
               if(Ymiss(i) == 1)
                   plot(i,Y(i),'k*');
                   plot(i,Y(i),'y.');                 
               end
           end
        end       
        title('Data');
        if min(Y) > 0
            axis([0 N 0.9*min(Y) 1.1*max(Y)]);
        else
            axis([0 N 1.1*min(Y) 1.1*max(Y)]);
        end 
        hold;
        subplot(2,1,2);
        plot(D,'r.');
        title('Hidden Markov Chain');
        axis([0 N 0 K+1]);
    end
        
    fp = fopen(dataInputFileName,'w+t');
    for i=1:N
        if missingData
            fprintf(fp,'%d %f\n',Ymiss(i),Y(i));
        else       
            fprintf(fp,'%f\n',Y(i));
        end
    end
    fclose(fp);
 
    if missingData
        save(dataInputMatlabFileName,'Ymiss','Y');  % Can just use load to get Y - Y=load gives a structure of variables (just Y)
    else
        save(dataInputMatlabFileName,'Y');  % Can just use load to get Y - Y=load gives a structure of variables (just Y)
    end
    save(predUnivariateDataFileName,'pY');
    save(hiddenMCFileName,'D');
    save(modelParametersFileName,'slope','sigma2','P','nu');

    if syntheticData
        save(trueParamsFileName,'slopeTrue','sigma2True','PTrue','DTrue','nuTrue','probTrue','pYTrue');
    end
    
else
    
    Y = load(dataInputFileName);
    if missingData
        Ymiss = Y(:,1);
        Y = Y(:,2);
    end
    
    if logInputData
        Y = log(Y);
    end
    N = size(Y,1);
 
     if trunkOutliers
        
        if smoothTrunk          
            [ubTrunk,lbTrunk,YUbSub,YLbSub] = calcSmoothTrunk(smoothStdInTime,numStd,Y,printFigures);
        else
            [ubTrunk,lbTrunk,YUbSub,YLbSub] = calcStraightTrunk(numStd,Y);
        end
        
        YTrunk = zeros(N,1);
        noTrunk = ones(N,1) - (ubTrunk + lbTrunk);
        YTrunk = Y.*noTrunk + YUbSub.*ubTrunk + YLbSub.*lbTrunk;
        YOrigin = Y;
        Y = YTrunk;

        if printFigures
            figure
            plot(YOrigin);
            hold
            plot(Y,'r');
            title('Data and Truncated Data (red)');
        end

        [100*sum(ubTrunk)/N 100*sum(lbTrunk)/N]
        
    end    
    
    if syntheticData
        load(trueParamsFileName,'slopeTrue','sigma2True','PTrue','DTrue','nuTrue','probTrue','pYTrue');
    end
    
    % Conditional distributions for filter forward, sample backwards algorithm
    fStateGData = zeros(N,K);       % f(D_i|F_i)    F_i = {Y_1,...,Y_i}
    fStateGDataLag = zeros(N,K);    % f(D_i|F_{i-1})
    fDataGDataLag = zeros(N,1);     % f(Y_i|F_{i-1})

    fStateGDataAll = zeros(N,K);    % f(D_i|F_N)   
    
    % For Moment Summaries
    sfStateGDataAll1 = zeros(N,K);
    sfStateGDataAll2 = zeros(N,K);
    sD = zeros(N,2);
    
end

if missingData
    sYmiss = zeros(N,2);
end

maxY = max(max(Y),mean(Y)+NumStandardDevForStart*sqrt(var(Y)));
minY = min(min(Y),mean(Y)-NumStandardDevForStart*sqrt(var(Y)));

% Conditional distributions for filter forward, sample backwards algorithm
fStateGData = zeros(N,K);       % f(D_i|F_i)    F_i = {Y_1,...,Y_i}
fStateGDataLag = zeros(N,K);    % f(D_i|F_{i-1})
fDataGDataLag = zeros(N,1);     % f(Y_i|F_{i-1})

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
sSigma2 = zeros(1,2);


% Prior for transition matrix - forces longer waiting times
priorP = ones(K,K)*deltaPriorP + deltaPriorP*N*eye(K);
% Allow highest state to be short lived ...
% priorP(K,K) = priorP(K,K)*delta;

%% Create Initial Esimtates
if randomStart

    % System equation parameters
    D = zeros(N,1);         % Current realization of HMC
    pY = zeros(N,1);
    
    meanOfY = mean(Y);
    varOfY = var(Y);
    
     for i=1:K 
        slope(i) = meanOfY + sqrt(varOfY)*NumStandardDevForStart*((i-1)*2/(K-1) - 1);
    end
    
    sigma2 = varOfY;
    nu = ones(K,1)*(1/K); 
         
    %Set the Hidden Markov Chain based on max likelihood
    fDataGState = calcLikelihoodAllStates(Y,slope,sigma2*ones(K,1),modelType);
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
        [pY,slope] = genSlope(Y,D,sigma2*ones(K,1),slope,slopeMean,slopeVar,minY,maxY);

        % Set sigma2Shape and sigma2Scale
        sigma2Shape = deltaPrior*N;
        sigma2Scale = deltaPrior*sum((Y - pY).^2);
        
        % Update sigma2
        sigma2 = genSigma2Constant(Y,pY,sigma2Shape,sigma2Scale);
    
else
     load(hiddenMCFileName,'D');
     load(modelParametersFileName,'slope','sigma2','P','nu');        
     load(predUnivariateDataFileName,'pY');
     if printFigures
        figure;
        subplot(2,1,1);
        plot(Y);
        hold;
        plot(pY,'r.');
        hold;
        title('Data');
        if min(Y) > 0
            axis([0 N 0.9*min(Y) 1.1*max(Y)]);
        else
            axis([0 N 1.1*min(Y) 1.1*max(Y)]);
        end 
        subplot(2,1,2);
        plot(D,'r.');
        title('Starting Hidden Markov Chain');
        axis([0 N 0 K+1]);
     end
end

%% Markov chain Monte Carlo (MCMC) analysis

if syntheticData
    logLikeTrue = calcLogLikeHMC(Y,pYTrue,sigma2True*ones(N,1));
end 
logLikeDraws(1) = calcLogLikeHMC(Y,pY,sigma2*ones(N,1));

n = 0;
[n slope' sigma2 logLikeDraws(1)]

for n=1:burnin+sample
       
    % Update Hidden State: Filter Forward Backwards Sampling
        % Filter Forward
        fDataGState = calcLikelihoodAllStates(Y,slope,sigma2*ones(K,1),modelType);
        [fStateGDataLag,fStateGData] = filterForwardHMMStationary(fDataGState,fStateGDataLag,fStateGData,P,nu);
         
        % Backwards Sample
        [fStateGDataAll,D,pY] = backwardsSampleHMMStationary(fStateGDataAll,D,pY,fStateGData,fStateGDataLag,P,slope); 
        
    % Update Markov Chain Parameters
        P = updateTransitionMatrix(D,priorP,P);
    
    % Update Observation or Likelihood Parameters
        % Update slope
         [pY,slope] = genSlope(Y,D,sigma2*ones(K,1),slope,slopeMean,slopeVar,minY,maxY);
         
        % Update sigma2
        sigma2 = genSigma2Constant(Y,pY,sigma2Shape,sigma2Scale);
         
       if missingData
          % Update the missing Y values
          Y = updateYMissing(Y,Ymiss,pY,sigma2);
       end
       
    % Store parameter estimates
    if n > burnin
       % Store Moments for parameters
       sfStateGDataAll1 = sfStateGDataAll1 + fStateGDataAll;
       sfStateGDataAll2 = sfStateGDataAll2 + fStateGDataAll.*fStateGDataAll;
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
       if missingData
           sYmiss(:,1) = sYmiss(:,1) + Ymiss.*Y;
           sYmiss(:,2) = sYmiss(:,2) + Ymiss.*Y.*Y;
       end       
    end
    
    logLikeDraws(n+1) = calcLogLikeHMC(Y,pY,sigma2*ones(N,1));
    
    if mod(n,thinPrintScreen) == 0
        [n slope' sigma2 logLikeDraws(n+1)]
        P
        if debugMCMC && printFigures
            figure(figHMCFilterForward);
            for k=1:K
                subplot(K,1,k);
                if syntheticData
                    plot(probTrue(:,k),'r-');
                    hold;
                    plot(fStateGData(:,k));
                    hold;
                else
                    plot(fStateGData(:,k));
                end
                title(['Prob State: ' num2str(k) ' given data (filter forward) iteration: ' num2str(n)]);
                axis([0 N -0.1 1.1]);
            end
            figure(figHMCFilterBackward);
            for k=1:K
                subplot(K,1,k);
                if syntheticData
                    plot(probTrue(:,k),'r-');
                    hold;
                    plot(fStateGDataAll(:,k));
                    hold;
                else
                    plot(fStateGDataAll(:,k));
                end
                title(['Prob State: ' num2str(k) ' given All data (filter backwards) iteration: ' num2str(n)]);
                axis([0 N -0.1 1.1]);
            end
            figure(figDataHMC);
            subplot(2,1,1);
            plot(Y);
            hold;
            plot(pY,'r.');
            if missingData
               for i=1:N
                  if(Ymiss(i) == 1)
                      plot(i,Y(i),'k*');
                      plot(i,Y(i),'y.');                 
                  end
               end
            end
            hold;
            title('Data');
            if min(Y) > 0
                lbY = .9*min(Y);
            else
                lbY = 1.1*min(Y);
            end
            if max(Y) > 0
                ubY = 1.1*max(Y);
            else
                ubY = 0.9*max(Y);
            end
            axis([0 N lbY ubY]);
            subplot(2,1,2);
            plot(D,'r.');
            title(['Hidden Markov Chain iteration: ' num2str(n)]);
            axis([0 N 0 K+1]);
            
            figure(figDataHMCLevel);
            plot(Y);
            hold;
            plot(pY,'g.');
            if missingData
               for i=1:N
                  if(Ymiss(i) == 1)
                      plot(i,Y(i),'k*');
                      plot(i,Y(i),'y.');                 
                  end
               end
            end
            hold;
            title('Data');
            if min(Y) > 0
                lbY = .9*min(Y);
            else
                lbY = 1.1*min(Y);
            end
            if max(Y) > 0
                ubY = 1.1*max(Y);
            else
                ubY = 0.9*max(Y);
            end
            axis([0 N lbY ubY]);
        end
    end
   
end

%% Generate Reports

% Calculate moment summaries
sfStateGDataAll1 = sfStateGDataAll1/sample;
sfStateGDataAll2 = sqrt(sfStateGDataAll2/sample - sfStateGDataAll1.*sfStateGDataAll1);
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
if missingData
    sYmiss(:,1) = sYmiss(:,1)/sample;
    sYmiss(:,2) = sqrt(sYmiss(:,2)/sample - sYmiss(:,1).*sYmiss(:,1));
end

% LogLike Reports

save(logLikeFileName,'logLikeDraws');

if printFigures
    figure;
    plot(logLikeDraws);
    if syntheticData
        hold;
        plot(logLikeTrue*(ones(size(logLikeDraws))),'r-');
        title('Log Likelihood, true in Red');
    else
        title('Log Likelihood');
    end
end

% Plot Graphical Summaries
save(summaryPlotFileName,'Y','spY','sD','sfStateGDataAll1','sfStateGDataAll2');

if printFigures
    figure;
    subplot(2,1,1);
    plot(Y);
    hold;
    plot(spY(:,1),'r.');
    plot(spY(:,1)+2*spY(:,2),'rx');
    plot(spY(:,1)-2*spY(:,2),'rx');
    if missingData
       for i=1:N
          if(Ymiss(i) == 1)
              plot(i,sYmiss(i,1),'k*');
              plot(i,sYmiss(i,1),'y.');                 
              plot(i,sYmiss(i,1)+2*sYmiss(i,2),'k*');
              plot(i,sYmiss(i,1)+2*sYmiss(i,2),'y.'); 
              plot(i,sYmiss(i,1)-2*sYmiss(i,2),'k*');
              plot(i,sYmiss(i,1)-2*sYmiss(i,2),'y.'); 
          end
       end
    end     
    title('Data & Posterior Mean Liqidity Levels');
    axis([0 N min(0,min(Y)) 1.1*max(Y)]);
    hold;
    subplot(2,1,2);
    plot(sD(:,1),'r.');
    title('Posterior Mean, Hidden Markov Chain');
    axis([0 N 0 K+1]);

    figure;
    for k=1:K
        subplot(K,1,k);
        if syntheticData
            plot(probTrue(:,k),'r-');
            hold;
            plot(sfStateGDataAll1(:,k));
            plot(sfStateGDataAll1(:,k)+2*sfStateGDataAll2(:,k),'b--');
            plot(sfStateGDataAll1(:,k)-2*sfStateGDataAll2(:,k),'b--');
            hold;
        else
            plot(sfStateGDataAll1(:,k));
            hold;
            plot(sfStateGDataAll1(:,k)+2*sfStateGDataAll2(:,k),'b--');
            plot(sfStateGDataAll1(:,k)-2*sfStateGDataAll2(:,k),'b--');
            hold;
        end
        title(['Posterior Prob State: ' num2str(k) ' given All data']);
        axis([0 N -0.1 1.1]);
    end
    
    figure;
    plot(Y,'b*-');
    hold;
    plot(spY(:,1),'g.');  
    if missingData
       for i=1:N
          if(Ymiss(i) == 1)
              plot(i,sYmiss(i,1),'k*');
              plot(i,sYmiss(i,1),'y.');                 
              plot(i,sYmiss(i,1)+2*sYmiss(i,2),'k*');
              plot(i,sYmiss(i,1)+2*sYmiss(i,2),'y.'); 
              plot(i,sYmiss(i,1)-2*sYmiss(i,2),'k*');
              plot(i,sYmiss(i,1)-2*sYmiss(i,2),'y.'); 
          end
       end
    end      
    hold;
    if min(Y) > 0
        lbY = .9*min(Y);
    else
        lbY = 1.1*min(Y);
    end
    if max(Y) > 0
        ubY = 1.1*max(Y);
    else
        ubY = 0.9*max(Y);
    end
    axis([0 N lbY ubY]);
    
end

['Report Posterior Mean and (Stadard Deviation)']

for i=1:K
    ['Slope(' num2str(i) '): ' num2str(sSlope(i,1)) ' (' num2str(sSlope(i,2)) ')']
end

['Sigma2: ' num2str(sSigma2(1,1)) ' (' num2str(sSigma2(1,2)) ')']

['Transition Prob Mean:']
sP1

['Transition Prob Std:']
sP2

fp = fopen(reportFileName,'w+t');
fprintf(fp,'Report Posterior Mean and (Standard Deviation)\n\n');

for i=1:K
    fprintf(fp,'Slope(%d): %2.2f (%2.2f)\n',i,sSlope(i,1),sSlope(i,2));
end
fprintf(fp,'\n');
    
fprintf(fp,'Sigma2: %4.2f (%2.2f)\n\n',sSigma2(1,1),sSigma2(1,2));
fprintf(fp,'\n');

fprintf(fp,'Transition Prob Mean:\n');
for i=1:K
    for j=1:K
        fprintf(fp,'%2.2f ',sP1(i,j));
    end
    fprintf(fp,'\n');
end
fprintf(fp,'\n');
fprintf(fp,'Transition Prob Std:\n');
for i=1:K
    for j=1:K
        fprintf(fp,'%2.2f ',sP2(i,j));
    end
    fprintf(fp,'\n');
end

fclose(fp);

