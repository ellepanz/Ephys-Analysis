function Data = MINIS_calculateHistogramMetrics(Data,S,conditions)
% Calculate final local Gaussian histogram metrics for stable trials.
%
% Each trial is analyzed as complete 1-s epochs.
% For each epoch:
%   1) Fit the right side of the all-points histogram with a Gaussian.
%   2) Gaussian mu estimates the local holding current.
%   3) Baseline-center the histogram so mu = 0 pA.
%   4) Subtract the mirrored Gaussian prediction from the negative side.
%   5) Clip negative residuals to zero.
%   6) Amplitude-weight the excess to calculate synaptic charge.
%
% Trial holding current = mean of epoch mu values.
% Trial synaptic charge = sum of epoch charges.
% Trial synaptic current = trial charge / analyzed trial duration.
%
% Synaptic charge and current are reported as positive magnitudes.

analysisConditions = getAnalysisConditions(conditions,S);

if isempty(analysisConditions)
    error('No conditions remain for final histogram analysis.');
end

epochSec = 1;
epochSamples = round(epochSec*S.Fs);

for c = 1:numel(analysisConditions)

    cond = analysisConditions{c};

    if ~isfield(Data.(cond),'stableMiniData')
        error('Data.%s.stableMiniData does not exist. Select stable trials first.',cond);
    end

    miniData = Data.(cond).stableMiniData;

    nSamples = size(miniData,1);
    nTrials = size(miniData,2);

    nEpochs = floor(nSamples/epochSamples);
    nAnalyzedSamples = nEpochs*epochSamples;
    analyzedDurationSec = nEpochs*epochSec;

    if nEpochs < 1
        error('Data.%s does not contain one complete 1-s epoch.',cond);
    end

    %% PREALLOCATE

    epochHoldingCurrent = nan(nEpochs,nTrials);
    epochSynapticCharge_pC = nan(nEpochs,nTrials);
    epochSynapticCurrent_pA = nan(nEpochs,nTrials);
    epochSynapticExcessCount = nan(nEpochs,nTrials);
    epochSigma = nan(nEpochs,nTrials);
    epochFitR2 = nan(nEpochs,nTrials);
    epochTimeMin = nan(nEpochs,nTrials);
    epochFits = cell(nEpochs,nTrials);

    %% ANALYZE EVERY 1-S EPOCH

    for k = 1:nTrials

        trial = miniData(:,k);
        trialStartMin = Data.(cond).stableTrialTimeMin(k);

        for e = 1:nEpochs

            startIdx = (e-1)*epochSamples + 1;
            endIdx = e*epochSamples;

            epoch = trial(startIdx:endIdx);

            fit = MINIS_fitBaseline(epoch,S);

            epochFits{e,k} = fit;

            epochHoldingCurrent(e,k) = fit.mu;
            epochSynapticCharge_pC(e,k) = fit.synapticCharge_pC;
            epochSynapticCurrent_pA(e,k) = fit.synapticCurrent_pA;
            epochSynapticExcessCount(e,k) = fit.synapticExcessCount;

            epochSigma(e,k) = fit.sigma;
            epochFitR2(e,k) = fit.R2;

            epochTimeMin(e,k) = ...
                trialStartMin + ((e-0.5)*epochSec)/60;

        end
    end

    %% REMOVE RETIRED METRIC FIELDS

    if isfield(Data.(cond),'oneSecEpoch')

        oldEpochFields = { ...
            'epochPhasicImean', ...
            'epochPhasicCharge', ...
            'epochSynapticExcessFraction', ...
            'ImeanEpochSec', ...
            'ImeanEpochSamples', ...
            'ImeanEpochsPerTrial', ...
            'ImeanAnalyzedSamplesPerTrial'};

        present = oldEpochFields( ...
            isfield(Data.(cond).oneSecEpoch,oldEpochFields));

        if ~isempty(present)
            Data.(cond).oneSecEpoch = ...
                rmfield(Data.(cond).oneSecEpoch,present);
        end
    end

    oldConditionFields = { ...
        'trialPhasicImean', ...
        'trialPhasicCharge', ...
        'avgPhasicImean', ...
        'avgPhasicCharge', ...
        'trialSynapticExcessFraction', ...
        'avgSynapticExcessFraction'};

    present = oldConditionFields( ...
        isfield(Data.(cond),oldConditionFields));

    if ~isempty(present)
        Data.(cond) = rmfield(Data.(cond),present);
    end

    %% STORE 1-S RESULTS

    Data.(cond).oneSecEpoch.epochHoldingCurrent = ...
        epochHoldingCurrent;

    Data.(cond).oneSecEpoch.epochSynapticCharge_pC = ...
        epochSynapticCharge_pC;

    Data.(cond).oneSecEpoch.epochSynapticCurrent_pA = ...
        epochSynapticCurrent_pA;

    Data.(cond).oneSecEpoch.epochSynapticExcessCount = ...
        epochSynapticExcessCount;

    Data.(cond).oneSecEpoch.epochSigma = epochSigma;
    Data.(cond).oneSecEpoch.epochFitR2 = epochFitR2;
    Data.(cond).oneSecEpoch.epochTimeMin = epochTimeMin;
    Data.(cond).oneSecEpoch.epochFits = epochFits;

    Data.(cond).oneSecEpoch.epochDurationSec = epochSec;
    Data.(cond).oneSecEpoch.epochSamples = epochSamples;
    Data.(cond).oneSecEpoch.epochsPerTrial = nEpochs;
    Data.(cond).oneSecEpoch.analyzedSamplesPerTrial = ...
        nAnalyzedSamples;

    %% COLLAPSE TO ONE VALUE PER TRIAL

    Data.(cond).trialHoldingCurrent = ...
        mean(epochHoldingCurrent,1,'omitnan');

    Data.(cond).trialSynapticCharge_pC = ...
        sum(epochSynapticCharge_pC,1,'omitnan');

    Data.(cond).trialSynapticCurrent_pA = ...
        Data.(cond).trialSynapticCharge_pC/analyzedDurationSec;

    %% CONDITION MEANS

    Data.(cond).avgHoldingCurrent = ...
        mean(Data.(cond).trialHoldingCurrent,'omitnan');

    Data.(cond).avgSynapticCurrent_pA = ...
        mean(Data.(cond).trialSynapticCurrent_pA,'omitnan');

    Data.(cond).avgSynapticCharge_pC = ...
        mean(Data.(cond).trialSynapticCharge_pC,'omitnan');

end

Data.analysisConditions = analysisConditions;

Data.finalAnalysisMethod = ...
    '1-s local Gaussian histogram; amplitude-weighted synaptic charge/current';

Data.finalAnalysisEpochSec = epochSec;
Data.finalAnalysisBinWidth_pA = S.fitBinWidth_pA;

fprintf('Histogram charge/current metrics calculated for: %s\n', ...
    strjoin(strrep(analysisConditions,'_','/'),', '));

end


function analysisConditions = getAnalysisConditions(conditions,S)

if isfield(S,'excludedAnalysisConditions')
    excluded = S.excludedAnalysisConditions;
elseif isfield(S,'drugCondition')
    excluded = {S.drugCondition};
else
    excluded = {};
end

mask = ~ismember(lower(string(conditions)),lower(string(excluded)));
analysisConditions = conditions(mask);

end