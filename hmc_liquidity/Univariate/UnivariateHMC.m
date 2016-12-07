%% Univariate Hidden Markov Chain inference tool.
%  John Liechty, May 21, 2013
%  Office of Financial Research, U.S. Department of Tresasury
%  all rights reserved.
%
%  Makes inference about the different levels of liquidity (or other
%  time-series of ineterest), with the assumption that the dynamics of the
%  time-series are driven by a hidden (unobserved Markov chain).  Each time
%  the Markov chain changes state, the dynamics of the observed time-series
%  changes (e.g. the level of liquidty in a market changes).  This type of
%  model could be viewed as a discrete time, discretes state space
%  version of a Kalman Filter.  See West and Harrison (1997) - Bayesian
%  Forecasting and Dynamic Models - along with Cappe, Moulines and Ryden
%  (2005)-Inference in Hidden Markov Models - for related discussions.
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

printFigures = false;
debugMCMC = true;
genData = false;
randomStart = true;
syntheticData = true;

thinPrintScreen = 10;

if printFigures
    figDataHMC = figure;
    figHMCFilterForward = figure;
    figHMCFilterBackward = figure;
end

burnin = 100;
sample = 100;

logLikeDraws = zeros(burnin+sample,1);

modelType = 1;      % 1 = Constant level, with normal errors
                    % 2 = Autoregressive/Mean Reversion around constant
                    % level, with normal errors (initially just 1
                    % implemented)

% Observation equation parameters
slope = zeros(K,1);     % Constant level
sigma2 = zeros(1);      % Variance of deviationsn from constant level
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
priorP = 1;
slopeVar = ones(K,1)*100;
slopeMean = zeros(K,1);
sigma2Shape = 1;
sigma2Scale = 1;

% Conditional distributions for filter forward, sample backwards algorithm
fStateGData = zeros(N,K);       % f(D_i|F_i)    F_i = {Y_1,...,Y_i}
fStateGDataLag = zeros(N,K);    % f(D_i|F_{i-1})
fDataGDataLag = zeros(N,1);     % f(Y_i|F_{i-1})

fStateGAllData = zeros(N,K);    % f(D_i|F_N)

% For Moment Summaries
sfStateGDataAll1 = zeros(N,K);
sfStateGDataAll2 = zeros(N,K);
sD = zeros(N,2);
spY = zeros(N,2);

sSlope = zeros(K,2);
sP1 = zeros(K,K);
sP2 = zeros(K,K);
snu = zeros(K,2);
sSigma2 = zeros(2,1);


%% Generate Synthetic Data or Load Real Data

if genData
   
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
    end    
    
    if printFigures
        figure(figDataHMC);
        subplot(2,1,1);
        plot(Y);
        hold;
        plot(pY,'r.');
        title('Data');
        axis([0 N min(0,min(Y)) 1.1*max(Y)]);
        hold;
        subplot(2,1,2);
        plot(D,'r.');
        title('Hidden Markov Chain');
        axis([0 N 0 K+1]);
    end
        
    save('univariateData.mat','Y');
    save('predUnivariateData.mat','pY');
    save('hiddenMC.mat','D');
    save('modelParameters.mat','slope','sigma2','P','nu');

    if syntheticData
        save('trueParams.mat','slopeTrue','sigma2True','PTrue','DTrue','nuTrue','probTrue');
    end
    
else
    load('univariateData.mat','Y');
    N = size(Y,1);
    
    if syntheticData
        load('trueParams.mat','slopeTrue','sigma2True','PTrue','DTrue','nuTrue','probTrue');
    end
    
    % Conditional distributions for filter forward, sample backwards algorithm
    fStateGData = zeros(N,K);       % f(D_i|F_i)    F_i = {Y_1,...,Y_i}
    fStateGDataLag = zeros(N,K);    % f(D_i|F_{i-1})
    fDataGDataLag = zeros(N,1);     % f(Y_i|F_{i-1})

    fStateGAllData = zeros(N,K);    % f(D_i|F_N)   
    
    % For Moment Summaries
    sfStateGDataAll1 = zeros(N,K);
    sfStateGDataAll2 = zeros(N,K);
    sD = zeros(N,2);
    
end

%% Create Initial Esimtates

if randomStart
% System equation parameters
    D = zeros(N,1);         % Current realization of HMC
    
    meanOfY = mean(Y);
    varOfY = var(Y);
    
    slope(1) = meanOfY - sqrt(varOfY);
    slope(2) = meanOfY;
    slope(3) = meanOfY + sqrt(varOfY);

    sigma2 = varOfY;
    nu = ones(K,1)*(1/K);
        
    fDataGState = calcLikelihoodAllStates(Y,slope,sigma2,modelType);
    [m,I] = sort(fDataGState,2);
    D = I(:,end);
    
     for i=1:K
        state = (D == i);
        pY = pY + state*slope(i);
     end
        
    if printFigures
        figure(figDataHMC);
        subplot(2,1,1);
        plot(Y);
        hold;
        plot(pY,'r.');
        title('Data');
        axis([0 N min(0,min(Y)) 1.1*max(Y)]);
        hold;
        subplot(2,1,2);
        plot(D,'r.');
        title('Hidden Markov Chain');
        axis([0 N 0 K+1]);
    end
    
%     
%     for i=1:N
% 
%         if i == 1
%             fStateGDataLag(i,:) = nu';
%         else
%             fStateGDataLag(i,:) = (fStateGData(i-1,:)*P);
%         end
% 
%         fDataGDataLag(i) = fDataGState(i,:)*fStateGDataLag(i,:)';
%         fStateGData(i,:) = (fDataGState(i,:).*fStateGDataLag(i,:))/fDataGDataLag(i);
% 
%     end
% 
%     for ti=1:N
% 
%         i = N + 1 - ti;
% 
%         if i == N
%             fStateGDataAll(N,:) = fStateGData(N,:);
%         else
%             fStateGDataAll(i,:) = (repmat(fStateGData(i,:)' ,1,K ) .* P)*(fStateGDataAll(i+1,:)./fStateGDataLag(i+1,:))';
%         end
% 
%         D(i) = loadedDie(fStateGDataAll(i,:)');
%         pY(i) = slope(D(i));
% 
%     end
    
    % Update Markov Chain Parameters
    
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
                P(i,j) = gamrnd((nStateTrans(i,j)+priorP),1);
            end
            P(i,:) = P(i,:)/sum(P(i,:));
        end
    
    % Update Observation or Likelihood Parameters

        % Update slope
        
        pY = zeros(N,1);
        
        for i=1:K
            state = (D == i);
            varY(i) = 1/(sum(state)/sigma2 + 1/slopeVar(i));
            meanY(i) = (sum(state.*Y)/sigma2 + slopeMean(i)/slopeVar(i))*varY(i);
            slope(i) = meanY(i) + sqrt(varY(i))*randn();
            pY = pY + state*slope(i);
        end
        
        % Update sigma2
        sigma2 = 1/gamrnd(0.5*N + sigma2Shape,1/(0.5*sum((Y-pY).^2) + sigma2Scale));
    
else
     load('hiddenMC.mat','D');
     load('modelParameters.mat','slope','sigma2','P','nu');        
     load('predUnivariateData.mat','pY');
     if printFigures
        figure;
        subplot(2,1,1);
        plot(Y);
        hold;
        plot(pY,'r.');
        hold;
        title('Data');
        axis([0 N min(0,min(Y)) 1.1*max(Y)]);
        subplot(2,1,2);
        plot(D,'r.');
        title('Starting Hidden Markov Chain');
        axis([0 N 0 K+1]);
     end
end


%% Markov chain Monte Carlo (MCMC) analysis
n = 0;
[n slope' sigma2]
        
for n=1:burnin+sample
    
    if mod(n,thinPrintScreen) == 0
        [n slope' sigma2]
    end
    
    % Update Hidden State: Filter Forward Backwards Sampling
        % Filter Forward
    
        fDataGState = calcLikelihoodAllStates(Y,slope,sigma2,modelType);
  
        for i=1:N
        
            if i == 1
                fStateGDataLag(i,:) = nu';
            else
                fStateGDataLag(i,:) = (fStateGData(i-1,:)*P);
            end
                
            fDataGDataLag(i) = fDataGState(i,:)*fStateGDataLag(i,:)';
            fStateGData(i,:) = (fDataGState(i,:).*fStateGDataLag(i,:))/fDataGDataLag(i);
            
        end
    
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
        end
        
        % Backwards Sample
        for ti=1:N
            
            i = N + 1 - ti;
            
            if i == N
                fStateGDataAll(N,:) = fStateGData(N,:);
            else
                fStateGDataAll(i,:) = (repmat(fStateGData(i,:)' ,1,K ) .* P)*(fStateGDataAll(i+1,:)./fStateGDataLag(i+1,:))';
            end

            D(i) = loadedDie(fStateGDataAll(i,:)');
            pY(i) = slope(D(i));
            
        end
        
        
        if debugMCMC && printFigures
            figure(figHMCFilterBackward);
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
                title(['Prob State: ' num2str(k) ' given All data (filter backwards) iteration: ' num2str(n)]);
                axis([0 N -0.1 1.1]);
            end
            figure(figDataHMC);
            subplot(2,1,1);
            plot(Y);
            hold;
            plot(pY,'r.');
            hold;
            title('Data');
            axis([0 N min(0,min(Y)) 1.1*max(Y)]);
            subplot(2,1,2);
            plot(D,'r.');
            title(['Hidden Markov Chain iteration: ' num2str(n)]);
            axis([0 N 0 K+1]);
        end
        
    % Update Markov Chain Parameters
    
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
                P(i,j) = gamrnd((nStateTrans(i,j)+priorP),1);
            end
            P(i,:) = P(i,:)/sum(P(i,:));
        end
    
    % Update Observation or Likelihood Parameters

        % Update slope
        
        pY = zeros(N,1);
        
        for i=1:K
            state = (D == i);
            varY(i) = 1/(sum(state)/sigma2 + 1/slopeVar(i));
            meanY(i) = (sum(state.*Y)/sigma2 + slopeMean(i)/slopeVar(i))*varY(i);
            slope(i) = meanY(i) + sqrt(varY(i))*randn();
            pY = pY + state*slope(i);
        end
        
        % Update sigma2
        sigma2 = 1/gamrnd(0.5*N + sigma2Shape,1/(0.5*sum((Y-pY).^2) + sigma2Scale));
    
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
       sSigma2(1) = sSigma2(1) + sigma2;
       sSigma2(2) = sSigma2(2) + sigma2.*sigma2;       
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
sSigma2(1) = sSigma2(1)/sample;
sSigma2(2) = sqrt(sSigma2(2)/sample - sSigma2(1).*sSigma2(1)); 

% Plot Graphical Summaries
figure;
subplot(2,1,1);
plot(Y);
hold;
plot(spY(:,1),'r.');
plot(spY(:,1)+2*spY(:,2),'rx');
plot(spY(:,1)-2*spY(:,2),'rx');
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
        plot(sfStateGDataAll1(:,k)+2*sfStateGDataAll2(:,2),'b--');
        plot(sfStateGDataAll1(:,k)-2*sfStateGDataAll2(:,2),'b--');
        hold;
    else
        plot(sfStateGDataAll1(:,k));
        hold;
        plot(sfStateGDataAll1(:,k)+2*sfStateGDataAll2(:,2),'b--');
        plot(sfStateGDataAll1(:,k)-2*sfStateGDataAll2(:,2),'b--');
        hold;
    end
    title(['Posterior Prob State: ' num2str(k) ' given All data']);
    axis([0 N -0.1 1.1]);
end


