function Validation = MINIS_plotLocalFitValidation(Data,S,conditions,figureFolder,Expt)
% Validate whole-trial versus local 1-s Gaussian histogram analysis.
%
% For each analyzed condition:
%   1) Calculate a whole 19-s Gaussian fit for every stable trial.
%   2) Compare whole-trial synaptic current with the final 1-s local result.
%   3) Quantify within-trial baseline variability from the nineteen local mu values.
%   4) Show the trial with the largest local-mu range in detail.
%
% This function is for validation/visualization only.
% It does not alter Data or the final analysis.

analysisConditions = getAnalysisConditions(conditions,S);

analysisDurationSec = 19;
analysisSamples = analysisDurationSec*S.Fs;
epochSamples = S.Fs;

Validation = struct;

for c = 1:numel(analysisConditions)

    cond = analysisConditions{c};

    if ~isfield(Data.(cond),'stableMiniData')
        error('Data.%s.stableMiniData is missing.',cond);
    end

    if ~isfield(Data.(cond),'oneSecEpoch')
        error('Run MINIS_calculateHistogramMetrics before validation.');
    end

    miniData = Data.(cond).stableMiniData;
    nTrials = size(miniData,2);

    epochMu = Data.(cond).oneSecEpoch.epochHoldingCurrent;
    epochFits = Data.(cond).oneSecEpoch.epochFits;

    localTrialCurrent = Data.(cond).trialSynapticCurrent_pA;
    localTrialMu = Data.(cond).trialHoldingCurrent;

    wholeMu = nan(1,nTrials);
    wholeCurrent = nan(1,nTrials);
    wholeCharge = nan(1,nTrials);
    wholeFits = cell(1,nTrials);

    muRange = nan(1,nTrials);

    %% WHOLE-TRIAL FITS FOR COMPARISON

    for k = 1:nTrials

        trial19 = miniData(1:analysisSamples,k);

        fit = MINIS_fitBaseline(trial19,S);

        wholeFits{k} = fit;
        wholeMu(k) = fit.mu;
        wholeCurrent(k) = fit.synapticCurrent_pA;
        wholeCharge(k) = fit.synapticCharge_pC;

        thisMu = epochMu(:,k);
        thisMu = thisMu(isfinite(thisMu));

        if ~isempty(thisMu)
            muRange(k) = max(thisMu)-min(thisMu);
        end
    end

    deltaCurrent = localTrialCurrent-wholeCurrent;
    deltaMu = localTrialMu-wholeMu;

    %% SELECT TRIAL WITH LARGEST LOCAL BASELINE RANGE

    [~,worstIdx] = max(muRange);

    trial19 = miniData(1:analysisSamples,worstIdx);
    worstWholeFit = wholeFits{worstIdx};
    worstEpochMu = epochMu(:,worstIdx);

    trialName = Data.(cond).stableTrialNames{worstIdx};

    %% BUILD LOCAL-MU TRACE

    localMuTrace = nan(analysisSamples,1);

    for e = 1:analysisDurationSec

        idx1 = (e-1)*epochSamples + 1;
        idx2 = e*epochSamples;

        localMuTrace(idx1:idx2) = worstEpochMu(e);

    end

    timeSec = (0:analysisSamples-1)'/S.Fs;

    %% BUILD COMBINED LOCALLY CENTERED HISTOGRAM

    centeredTrace = nan(analysisSamples,1);

    for e = 1:analysisDurationSec

        idx1 = (e-1)*epochSamples + 1;
        idx2 = e*epochSamples;

        centeredTrace(idx1:idx2) = ...
            trial19(idx1:idx2)-worstEpochMu(e);

    end

    binWidth = S.fitBinWidth_pA;

    lo = floor(min(centeredTrace)/binWidth)*binWidth;
    hi = ceil(max(centeredTrace)/binWidth)*binWidth;

    edges = lo:binWidth:(hi+binWidth);

    [localPointFreq,edges] = histcounts(centeredTrace,edges);
    localCenters = edges(1:end-1)+diff(edges)/2;

    localGaussian = zeros(size(localCenters));
    localExcess = zeros(size(localCenters));

    for e = 1:analysisDurationSec

        fit = epochFits{e,worstIdx};

        localGaussian = localGaussian + interp1( ...
            fit.centeredCenters, ...
            fit.gaussianCounts, ...
            localCenters, ...
            'linear',0);

        localExcess = localExcess + interp1( ...
            fit.centeredCenters, ...
            fit.synapticExcessCounts, ...
            localCenters, ...
            'linear',0);

    end

    %% STORE VALIDATION RESULTS

    V.condition = cond;

    V.wholeMu = wholeMu;
    V.localMu = localTrialMu;
    V.deltaMu = deltaMu;

    V.wholeSynapticCurrent_pA = wholeCurrent;
    V.localSynapticCurrent_pA = localTrialCurrent;
    V.deltaSynapticCurrent_pA = deltaCurrent;

    V.muRange_pA = muRange;

    V.worstTrialIdx = worstIdx;
    V.worstTrialName = trialName;

    V.worstWholeFit = worstWholeFit;
    V.worstEpochMu = worstEpochMu;

    Validation.(cond) = V;

    %% FIGURE

    fig = figure('Color','w','Position',[80 50 1450 900]);

    t = tiledlayout(fig,2,3, ...
        'TileSpacing','compact', ...
        'Padding','compact');

    %% 1. LOCAL MU RANGE ACROSS TRIALS

    ax1 = nexttile(t);
    hold(ax1,'on');

    plot(ax1,1:nTrials,muRange,'o-');

    % scatter(ax1,worstIdx,muRange(worstIdx),90,'filled');

    xlabel(ax1,'Stable trial');
    ylabel(ax1,'1s \mu range (pA)');
    title(ax1,'Within-trial baseline variability');

    box(ax1,'off');

    %% 2. WHOLE VS LOCAL SYNAPTIC CURRENT

    ax2 = nexttile(t);
    hold(ax2,'on');

    scatter(ax2,wholeCurrent,localTrialCurrent,60,'filled');

    vals = [wholeCurrent localTrialCurrent];
    vals = vals(isfinite(vals));

    if ~isempty(vals)
        limMax = 1.1*max(vals);

        if limMax <= 0 || ~isfinite(limMax)
            limMax = 1;
        end

        plot(ax2,[0 limMax],[0 limMax],'--');
        xlim(ax2,[0 limMax]);
        ylim(ax2,[0 limMax]);
    end

    xlabel(ax2,'Whole 19s current (pA)');
    ylabel(ax2,'1s local current (pA)');
    title(ax2,'Whole-trial vs local analysis');

    axis(ax2,'square');
    box(ax2,'off');

    %% 3. EFFECT OF BASELINE VARIABILITY

    ax3 = nexttile(t);
    hold(ax3,'on');

    scatter(ax3,muRange,deltaCurrent,60,'filled');

    yline(ax3,0,'--');

    xlabel(ax3,'1s \mu range (pA)');
    ylabel(ax3,'Local - whole current (pA)');
    title(ax3,'Does baseline drift change the result?');

    box(ax3,'off');

    %% 4. WORST-DRIFT TRACE

    ax4 = nexttile(t);
    hold(ax4,'on');

    plot(ax4,timeSec,trial19);
    plot(ax4,timeSec,localMuTrace,'LineWidth',2);

    for e = 1:analysisDurationSec-1
        xline(ax4,e,':');
    end

    xlabel(ax4,'Time (s)');
    ylabel(ax4,'Current (pA)');

    title(ax4,sprintf( ...
        '%s: raw trace with local 1s \\mu', ...
        strrep(trialName,'_','\_')));

    legend(ax4,'Trace','Local \mu','Location','best');
    xlim(ax4,[0 analysisDurationSec]);

    box(ax4,'off');

    %% 5. WHOLE-TRIAL HISTOGRAM

    ax5 = nexttile(t);
    hold(ax5,'on');

    bar(ax5, ...
        worstWholeFit.centeredCenters, ...
        worstWholeFit.pointFreq, ...
        1, ...
        'FaceAlpha',0.3, ...
        'EdgeColor','none');

    plot(ax5, ...
        worstWholeFit.centeredCenters, ...
        worstWholeFit.gaussianCounts, ...
        'LineWidth',2);

    plot(ax5, ...
        worstWholeFit.centeredCenters, ...
        worstWholeFit.synapticExcessCounts, ...
        'LineWidth',2);

    xline(ax5,0,'--');

    xlabel(ax5,'Current relative to whole-trial \mu (pA)');
    ylabel(ax5,'Point count');

    title(ax5,sprintf( ...
        'Whole 19s fit: %.2f pA synaptic current', ...
        wholeCurrent(worstIdx)));

    legend(ax5, ...
        'Histogram', ...
        'Gaussian prediction', ...
        'Synaptic excess', ...
        'Location','best');

    box(ax5,'off');

    %% 6. LOCALLY CENTERED HISTOGRAM

    ax6 = nexttile(t);
    hold(ax6,'on');

    bar(ax6, ...
        localCenters, ...
        localPointFreq, ...
        1, ...
        'FaceAlpha',0.3, ...
        'EdgeColor','none');

    plot(ax6, ...
        localCenters, ...
        localGaussian, ...
        'LineWidth',2);

    plot(ax6, ...
        localCenters, ...
        localExcess, ...
        'LineWidth',2);

    xline(ax6,0,'--');

    xlabel(ax6,'Current relative to local 1s \mu (pA)');
    ylabel(ax6,'Point count');

    title(ax6,sprintf( ...
        '19s trial using local 1-s baseline fits: %.2f pA', ...
        localTrialCurrent(worstIdx)));

    legend(ax6, ...
        'Locally centered histogram', ...
        'Summed Gaussian prediction', ...
        'Summed synaptic excess', ...
        'Location','best');

    box(ax6,'off');

    %% TITLE

    sgtitle(t,sprintf( ...
        '%s | %s | Local-Gaussian Analysis Validation', ...
        Expt.marker,strrep(cond,'_','/')));

    %% SAVE

    safeCond = regexprep(cond,'[^A-Za-z0-9_-]','_');

    savefig(fig,fullfile( ...
        figureFolder, ...
        sprintf('Local Fit Validation - %s.fig',safeCond)));

    exportgraphics(fig,fullfile( ...
        figureFolder, ...
        sprintf('Local Fit Validation - %s.png',safeCond)), ...
        'Resolution',300);

end

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