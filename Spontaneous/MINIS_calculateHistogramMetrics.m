function Data = MINIS_calculateHistogramMetrics(Data,S,conditions)
% Calculate final 1-s histogram metrics for every stable analyzed condition.
%
% For every complete 1-s epoch:
%   1) Fit the baseline/noise Gaussian with MINIS_fitBaseline.
%   2) Gaussian mu is the estimated holding current.
%   3) Subtract Gaussian counts from observed histogram counts on the
%      inward/negative side.
%   4) Synaptic excess fraction = summed positive residual counts divided
%      by the total number of histogram counts.
%
% Synaptic excess fraction is dimensionless. It is not a current in pA.

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

    epochHoldingCurrent = nan(nEpochs,nTrials);
    epochSynapticExcessFraction = nan(nEpochs,nTrials);
    epochSynapticExcessCount = nan(nEpochs,nTrials);
    epochSigma = nan(nEpochs,nTrials);
    epochFitR2 = nan(nEpochs,nTrials);
    epochTimeMin = nan(nEpochs,nTrials);
    epochFits = cell(nEpochs,nTrials);

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
            epochSynapticExcessFraction(e,k) = fit.synapticExcessFraction;
            epochSynapticExcessCount(e,k) = fit.synapticExcessCount;
            epochSigma(e,k) = fit.sigma;
            epochFitR2(e,k) = fit.R2;
            epochTimeMin(e,k) = trialStartMin + ((e-0.5)*epochSec)/60;
        end
    end

    % Remove fields from the retired time-domain Imean analysis if this is
    % an older Data struct being reprocessed.
    if isfield(Data.(cond),'oneSecEpoch')
        oldEpochFields = {'epochPhasicImean','epochPhasicCharge', ...
            'ImeanEpochSec','ImeanEpochSamples','ImeanEpochsPerTrial','ImeanAnalyzedSamplesPerTrial'};
        present = oldEpochFields(isfield(Data.(cond).oneSecEpoch,oldEpochFields));

        if ~isempty(present)
            Data.(cond).oneSecEpoch = rmfield(Data.(cond).oneSecEpoch,present);
        end
    end

    oldConditionFields = {'trialPhasicImean','trialPhasicCharge','avgPhasicImean','avgPhasicCharge'};
    present = oldConditionFields(isfield(Data.(cond),oldConditionFields));

    if ~isempty(present)
        Data.(cond) = rmfield(Data.(cond),present);
    end

    Data.(cond).oneSecEpoch.epochHoldingCurrent = epochHoldingCurrent;
    Data.(cond).oneSecEpoch.epochSynapticExcessFraction = epochSynapticExcessFraction;
    Data.(cond).oneSecEpoch.epochSynapticExcessCount = epochSynapticExcessCount;
    Data.(cond).oneSecEpoch.epochSigma = epochSigma;
    Data.(cond).oneSecEpoch.epochFitR2 = epochFitR2;
    Data.(cond).oneSecEpoch.epochTimeMin = epochTimeMin;
    Data.(cond).oneSecEpoch.epochFits = epochFits;

    Data.(cond).oneSecEpoch.epochDurationSec = epochSec;
    Data.(cond).oneSecEpoch.epochSamples = epochSamples;
    Data.(cond).oneSecEpoch.epochsPerTrial = nEpochs;
    Data.(cond).oneSecEpoch.analyzedSamplesPerTrial = nAnalyzedSamples;

    Data.(cond).trialHoldingCurrent = mean(epochHoldingCurrent,1,'omitnan');
    Data.(cond).trialSynapticExcessFraction = mean(epochSynapticExcessFraction,1,'omitnan');

    Data.(cond).avgHoldingCurrent = mean(Data.(cond).trialHoldingCurrent,'omitnan');
    Data.(cond).avgSynapticExcessFraction = mean(Data.(cond).trialSynapticExcessFraction,'omitnan');
end

Data.analysisConditions = analysisConditions;
Data.finalAnalysisMethod = 'Gaussian histogram synaptic-excess fraction';

fprintf('Histogram metrics calculated for: %s\n', ...
    strjoin(strrep(analysisConditions,'_','/'),', '));

end


function analysisConditions = getAnalysisConditions(conditions,S)

if isfield(S,'excludedAnalysisConditions')
    excluded = S.excludedAnalysisConditions;
elseif isfield(S,'drugCondition')
    excluded = {S.drugCondition};
else
    excluded = {'NMDA'};
end

mask = ~ismember(lower(string(conditions)),lower(string(excluded)));
analysisConditions = conditions(mask);

end
