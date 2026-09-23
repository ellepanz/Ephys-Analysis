function Data = MINIS_calculateWholeTrialMetrics(Data,S,conditions)
% Calculate Mike-style whole-trial Gaussian histogram metrics.
%
% Uses the manually selected stable trials, then removes ONLY trials marked
% by MINIS_reviewBaselineTrialExclusions as having unstable/bimodal
% whole-trial baselines.
%
% This does not alter stableMiniData or the 1-s analysis.
%
% Stored under:
%   Data.(cond).wholeTrial

analysisConditions = getAnalysisConditions(conditions,S);
analysisDurationSec = S.miniDurationSec;
analysisSamples = S.miniSamples;

if isempty(analysisConditions)
    error('No conditions remain for whole-trial analysis.');
end

for c = 1:numel(analysisConditions)
    cond = analysisConditions{c};

    requiredFields = {'stableMiniData','stableTrialNames','stableTrialTimeMin', ...
        'baselineSensitivityExcludedTrialNames'};

    for f = 1:numel(requiredFields)
        if ~isfield(Data.(cond),requiredFields{f})
            error(['Data.%s.%s does not exist. Run stable selection and ' ...
                'MINIS_reviewBaselineTrialExclusions first.'],cond,requiredFields{f});
        end
    end

    miniData = Data.(cond).stableMiniData;
    trialNames = string(Data.(cond).stableTrialNames);
    trialTimes = Data.(cond).stableTrialTimeMin;
    nTrials = size(miniData,2);

    if size(miniData,1) < analysisSamples
        error('Data.%s.stableMiniData is shorter than the expected %.1f s.',cond,analysisDurationSec);
    end

    if numel(trialNames) ~= nTrials
        error('Data.%s.stableTrialNames does not match stableMiniData columns.',cond);
    end

    excludedNames = string(Data.(cond).baselineSensitivityExcludedTrialNames(:));

    if ~isempty(excludedNames)
        missing = excludedNames(~ismember(excludedNames,trialNames));

        if ~isempty(missing)
            error(['Baseline-review exclusions for %s are not present in the ' ...
                'current stable trial set: %s'],cond,strjoin(missing,', '));
        end
    end

    excludedMask = ismember(trialNames,excludedNames);
    includedMask = ~excludedMask;

    allHolding = nan(1,nTrials);
    allSynapticCharge = nan(1,nTrials);
    allSynapticCurrent = nan(1,nTrials);
    allSigma = nan(1,nTrials);
    allR2 = nan(1,nTrials);
    allFits = cell(1,nTrials);

    allSelectedMu = nan(1,nTrials);

    for k = 1:nTrials
        trial = miniData(1:analysisSamples,k);

        binWidth = S.fitBinWidth_pA;
        lo = floor(min(trial)/binWidth)*binWidth;
        hi = ceil(max(trial)/binWidth)*binWidth;
        edges = lo:binWidth:(hi+binWidth);

        if numel(edges) < 2
            edges = [lo lo+binWidth];
        end

        [pointFreq,edges] = histcounts(trial,edges);
        centers = edges(1:end-1) + diff(edges)/2;

        [~,peakIdx] = max(pointFreq);
        peakCurrent = centers(peakIdx);

        figure('Name',sprintf('%s - %s',cond,trialNames(k)),'Color','w');
        bar(centers,pointFreq,1,'FaceColor',[0.8 0.8 0.8],'EdgeColor','none');
        hold on
        xline(peakCurrent,'k--','Histogram peak');
        xlabel('Current (pA)');
        ylabel('Point count');
        title(sprintf('%s | %s | Click desired mu',strrep(cond,'_','/'),trialNames(k)));
        box off

        [selectedMu,~] = ginput(1);
        selectedMu = centers(find(abs(centers-selectedMu) == min(abs(centers-selectedMu)),1,'first'));
        close(gcf);

        allSelectedMu(k) = selectedMu;

        fit = MINIS_fitBaseline(trial,S,selectedMu);

        allFits{k} = fit;
        allHolding(k) = fit.mu;
        allSynapticCharge(k) = fit.synapticCharge_pC;
        allSynapticCurrent(k) = fit.synapticCurrent_pA;
        allSigma(k) = fit.sigma;
        allR2(k) = fit.R2;
    end

    W = struct;

    W.allStableTrialNames = cellstr(trialNames);
    W.allStableTrialTimeMin = trialTimes;
    W.allStableHoldingCurrent = allHolding;
    W.allStableSynapticCharge_pC = allSynapticCharge;
    W.allStableSynapticCurrent_pA = allSynapticCurrent;
    W.allStableSigma = allSigma;
    W.allStableFitR2 = allR2;
    W.allStableFits = allFits;
    W.allStableSelectedMu = allSelectedMu;

    W.avgAllStableHoldingCurrent = mean(allHolding,'omitnan');
    W.avgAllStableSynapticCharge_pC = mean(allSynapticCharge,'omitnan');
    W.avgAllStableSynapticCurrent_pA = mean(allSynapticCurrent,'omitnan');

    W.excludedTrialNames = cellstr(trialNames(excludedMask));
    W.excludedStableMask = excludedMask;
    W.includedStableMask = includedMask;

    W.trialNames = cellstr(trialNames(includedMask));
    W.trialTimeMin = trialTimes(includedMask);
    W.trialHoldingCurrent = allHolding(includedMask);
    W.trialSynapticCharge_pC = allSynapticCharge(includedMask);
    W.trialSynapticCurrent_pA = allSynapticCurrent(includedMask);
    W.trialSigma = allSigma(includedMask);
    W.trialFitR2 = allR2(includedMask);
    W.trialFits = allFits(includedMask);
    W.trialSelectedMu = allSelectedMu(includedMask);

    W.avgHoldingCurrent = mean(W.trialHoldingCurrent,'omitnan');
    W.avgSynapticCharge_pC = mean(W.trialSynapticCharge_pC,'omitnan');
    W.avgSynapticCurrent_pA = mean(W.trialSynapticCurrent_pA,'omitnan');

    W.nSelectedStableTrials = nTrials;
    W.nExcludedBaselineTrials = sum(excludedMask);
    W.nAnalyzedTrials = sum(includedMask);
    W.isAnalyzable = W.nAnalyzedTrials > 0;

    W.analysisDurationSec = analysisDurationSec;
    W.analysisMethod = sprintf( ...
        'Whole %.1f-s Gaussian histogram; manually baseline-unstable trials excluded', ...
        analysisDurationSec);

    Data.(cond).wholeTrial = W;

    fprintf('%s whole %.1f s: %d stable -> %d excluded -> %d analyzed\n', ...
        strrep(cond,'_','/'),analysisDurationSec, ...
        W.nSelectedStableTrials,W.nExcludedBaselineTrials,W.nAnalyzedTrials);

    if ~W.isAnalyzable
        fprintf('  Whole-trial analysis unavailable for %s: all selected stable trials were excluded by baseline QC.\n', ...
            strrep(cond,'_','/'));
    end
end

Data.wholeTrialAnalysisMethod = sprintf( ...
    'Whole %.1f-s Gaussian histogram; manually baseline-unstable trials excluded', ...
    analysisDurationSec);

Data.wholeTrialAnalysisDurationSec = analysisDurationSec;

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
