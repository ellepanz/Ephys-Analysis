function Data = MINIS_calculateImean(Data, S)
% MINIS_calculateImean
%
% Glykys/Mody-style analysis using 1-s epochs.
%
% For every 1-s epoch of each stable Control and Washout trial:
%   1) Make all-points histogram and fit Gaussian using MINIS_fitBaseline
%   2) Gaussian mean (mu) = holding current for that epoch
%   3) Subtract mu from all points in the epoch
%   4) Average the baseline-subtracted points = phasic Imean
%
% IMPORTANT:
% The Gaussian mean is a HOLDING CURRENT measurement.
% It is not, by itself, the tonic GABA current. Tonic GABA current requires
% a GABAA-receptor blocker condition and is calculated from the shift in
% holding current.
%
% Output fields include:
%
%   epochHoldingCurrent
%   epochHoldingCurrentDetrended
%   epochPhasicImean
%   epochSigma
%   epochFitR2
%   epochTimeMin
%   epochFits
%
% and trial-averaged versions of holding current and phasic Imean.


%% =========================================================
% SETTINGS
% ==========================================================

analysisConditions = { ...
    S.controlCondition, ...
    S.washCondition};

epochSec = 1;
epochSamples = round(epochSec * S.Fs);


%% =========================================================
% CALCULATE 1-S EPOCH VALUES
% ==========================================================
for c = 1:numel(analysisConditions)
    cond = analysisConditions{c};

    miniData = Data.(cond).stableMiniData;
    nSamples = size(miniData,1);
    nTrials = size(miniData,2);
    %% Number of complete 1-s epochs
    n1sEpochs = floor(nSamples / epochSamples);
    nTracePts = n1sEpochs * epochSamples;

    %% Preallocate
    epochHoldingCurrent = nan(n1sEpochs,nTrials);
    epochPhasicImean = nan(n1sEpochs,nTrials);
    epochSigma = nan(n1sEpochs,nTrials);
    epochFitR2 = nan(n1sEpochs,nTrials);
    epochTimeMin = nan(n1sEpochs,nTrials);
    epochFits = cell(n1sEpochs,nTrials);

    %% =====================================================
    % LOOP THROUGH STABLE TRIALS
    % ======================================================
    for k = 1:nTrials

        trial = miniData(:,k);
        trialStartMin = Data.(cond).stableTrialTimeMin(k);

        %% Loop through 1-s epochs
        for e = 1:n1sEpochs

            startIdx = (e-1)*epochSamples + 1;
            endIdx = e*epochSamples;
            epoch = trial(startIdx:endIdx);
                
            %% -----------------------------------------
            % Gaussian fit
            % ------------------------------------------
            fit = MINIS_fitBaseline(epoch,S);
            epochFits{e,k} = fit;
            epochHoldingCurrent(e,k) = fit.mu;
            epochSigma(e,k) = fit.sigma;
            epochFitR2(e,k) = fit.R2;

            %% -----------------------------------------
            % Phasic Imean
            % ------------------------------------------
            % Subtract gaussian mean from each trial pt to get synaptic event
            baselineSubtractedEpoch = epoch - fit.mu;       

            epochPhasicImean(e,k) = mean(baselineSubtractedEpoch); % Phasic Imean = average synaptic current during the epoch (pA)
            epochPhasicCharge(e,k) = sum(baselineSubtractedEpoch) / S.Fs; % Phasic charge = total synaptic charge transferred during the epoch (pC)
    
            %% -----------------------------------------
            % Experimental time
            % ------------------------------------------
            % Put each 1-s measurement at the CENTER of its epoch.
            %
            % Epoch 1 = trial start + 0.5 s
            % Epoch 2 = trial start + 1.5 s
            % etc.

            epochTimeMin(e,k) = trialStartMin +  ((e-0.5)*epochSec)/60;
        end
    end

    %% =====================================================
    % STORE RAW EPOCH RESULTS
    % ======================================================
    Data.(cond).oneSecEpoch.epochHoldingCurrent = epochHoldingCurrent;
    Data.(cond).oneSecEpoch.epochPhasicImean = epochPhasicImean;
    Data.(cond).oneSecEpoch.epochSigma = epochSigma;     
    Data.(cond).oneSecEpoch.epochFitR2 = epochFitR2;        
    Data.(cond).oneSecEpoch.epochTimeMin = epochTimeMin;
    Data.(cond).oneSecEpoch.epochFits = epochFits;
    Data.(cond).oneSecEpoch.ImeanEpochSec = epochSec;
    Data.(cond).oneSecEpoch.ImeanEpochSamples = epochSamples;
    Data.(cond).oneSecEpoch.ImeanEpochsPerTrial = n1sEpochs;
    Data.(cond).oneSecEpoch.ImeanAnalyzedSamplesPerTrial = nTracePts;

    %% =====================================================
    % ONE VALUE PER STABLE TRIAL
    % ======================================================
    Data.(cond).trialHoldingCurrent = mean(epochHoldingCurrent,1); % find mean of all 1s segments
    Data.(cond).trialPhasicImean = mean(epochPhasicImean,1); 
end
fprintf('Imeans calculated and stored.\n')