function Data = MINIS_calculateImean(Data,S,conditions)
% Glykys/Mody-style 1-s analysis for every stable non-NMDA condition.
%
% For every complete 1-s epoch:
%   Gaussian mu = holding current
%   mean(epoch-mu) = phasic Imean
%   sum(epoch-mu)/Fs = phasic charge in pC for a 1-s epoch

analysisConditions = getAnalysisConditions(conditions,S);

if isempty(analysisConditions)
    error('No conditions remain for 1-s holding/phasic analysis.');
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

    n1sEpochs = floor(nSamples/epochSamples);
    nTracePts = n1sEpochs*epochSamples;

    epochHoldingCurrent = nan(n1sEpochs,nTrials);
    epochPhasicImean = nan(n1sEpochs,nTrials);
    epochPhasicCharge = nan(n1sEpochs,nTrials);
    epochSigma = nan(n1sEpochs,nTrials);
    epochFitR2 = nan(n1sEpochs,nTrials);
    epochTimeMin = nan(n1sEpochs,nTrials);
    epochFits = cell(n1sEpochs,nTrials);

    for k = 1:nTrials
        trial = miniData(:,k);
        trialStartMin = Data.(cond).stableTrialTimeMin(k);

        for e = 1:n1sEpochs
            startIdx = (e-1)*epochSamples + 1;
            endIdx = e*epochSamples;
            epoch = trial(startIdx:endIdx);

            fit = MINIS_fitBaseline(epoch,S);
            epochFits{e,k} = fit;
            epochHoldingCurrent(e,k) = fit.mu;
            epochSigma(e,k) = fit.sigma;
            epochFitR2(e,k) = fit.R2;

            baselineSubtractedEpoch = epoch-fit.mu;
            epochPhasicImean(e,k) = mean(baselineSubtractedEpoch,'omitnan');
            epochPhasicCharge(e,k) = sum(baselineSubtractedEpoch,'omitnan')/S.Fs;

            epochTimeMin(e,k) = trialStartMin + ((e-0.5)*epochSec)/60;
        end
    end

    Data.(cond).oneSecEpoch.epochHoldingCurrent = epochHoldingCurrent;
    Data.(cond).oneSecEpoch.epochPhasicImean = epochPhasicImean;
    Data.(cond).oneSecEpoch.epochPhasicCharge = epochPhasicCharge;
    Data.(cond).oneSecEpoch.epochSigma = epochSigma;
    Data.(cond).oneSecEpoch.epochFitR2 = epochFitR2;
    Data.(cond).oneSecEpoch.epochTimeMin = epochTimeMin;
    Data.(cond).oneSecEpoch.epochFits = epochFits;
    Data.(cond).oneSecEpoch.ImeanEpochSec = epochSec;
    Data.(cond).oneSecEpoch.ImeanEpochSamples = epochSamples;
    Data.(cond).oneSecEpoch.ImeanEpochsPerTrial = n1sEpochs;
    Data.(cond).oneSecEpoch.ImeanAnalyzedSamplesPerTrial = nTracePts;

    Data.(cond).trialHoldingCurrent = mean(epochHoldingCurrent,1,'omitnan');
    Data.(cond).trialPhasicImean = mean(epochPhasicImean,1,'omitnan');
    Data.(cond).trialPhasicCharge = mean(epochPhasicCharge,1,'omitnan');

    Data.(cond).avgHoldingCurrent = mean(Data.(cond).trialHoldingCurrent,'omitnan');
    Data.(cond).avgPhasicImean = mean(Data.(cond).trialPhasicImean,'omitnan');
    Data.(cond).avgPhasicCharge = mean(Data.(cond).trialPhasicCharge,'omitnan');
end

Data.analysisConditions = analysisConditions;
fprintf('Imeans calculated for: %s\n',strjoin(strrep(analysisConditions,'_','/'),', '));

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
