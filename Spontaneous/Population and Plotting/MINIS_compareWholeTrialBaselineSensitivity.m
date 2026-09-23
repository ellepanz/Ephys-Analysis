function Sensitivity = MINIS_compareWholeTrialBaselineSensitivity(Data,S,conditions,color,figureFolder,Expt)
% Compare three analyses using the SAME manually selected stable trials:
%
%   1) Whole-trial analysis: all selected stable trials
%   2) Whole-trial analysis: selected stable trials after removing trials
%      manually marked as baseline-unstable
%   3) 1-s local analysis: all selected stable trials
%
% The third column uses the existing trial-level 1-s results already stored
% by MINIS_calculateHistogramMetrics:
%   Data.(cond).trialHoldingCurrent
%   Data.(cond).trialSynapticCurrent_pA
%
% This function does not modify Data.

analysisDurationSec = S.miniDurationSec;
analysisSamples = S.miniSamples;

if ~isfield(S,'controlCondition') || ~isfield(S,'washCondition')
    error('S.baselineCondition and S.washCondition must be defined.');
end

plotConditions = {S.baselineCondition,S.washCondition};
Sensitivity = struct;
Sensitivity.analysisDurationSec = analysisDurationSec;
Sensitivity.analysisSamples = analysisSamples;

%% COLORS

plotColors = cell(1,2);

for c = 1:2
    cond = plotConditions{c};

    if ~isfield(Data,cond)
        error('Data.%s does not exist.',cond);
    end

    condIdx = find(strcmp(conditions,cond),1);

    if isempty(condIdx)
        error('Condition %s was not found in conditions.',cond);
    end

    plotColors{c} = color{condIdx};
end

%% CALCULATE WHOLE-TRIAL ANALYSIS + LOAD EXISTING 1-S TRIAL VALUES

for c = 1:2
    cond = plotConditions{c};

    requiredFields = {'stableMiniData','stableTrialNames', ...
        'trialHoldingCurrent','trialSynapticCurrent_pA'};

    for f = 1:numel(requiredFields)
        if ~isfield(Data.(cond),requiredFields{f})
            error('Data.%s.%s does not exist.',cond,requiredFields{f});
        end
    end

    trialNames = string(Data.(cond).stableTrialNames);
    stableMiniData = Data.(cond).stableMiniData;
    nTrials = numel(trialNames);

    if size(stableMiniData,2) ~= nTrials
        error('Data.%s.stableMiniData columns do not match stableTrialNames.',cond);
    end

    if size(stableMiniData,1) < analysisSamples
        error('Data.%s.stableMiniData is shorter than the expected %.1f s.',cond,analysisDurationSec);
    end

    %% Whole-trial fits for every selected stable trial

    wholeHolding = nan(1,nTrials);
    wholeSynaptic = nan(1,nTrials);
    wholeFits = cell(1,nTrials);

    for k = 1:nTrials
        trial = stableMiniData(1:analysisSamples,k);
        fit = MINIS_fitBaseline(trial,S);

        wholeFits{k} = fit;
        wholeHolding(k) = fit.mu;
        wholeSynaptic(k) = fit.synapticCurrent_pA;
    end

    %% Manually marked baseline-unstable trials

    excludedNames = strings(0,1);

    if isfield(Data.(cond),'baselineSensitivityExcludedTrialNames') && ...
            ~isempty(Data.(cond).baselineSensitivityExcludedTrialNames)
        excludedNames = string(Data.(cond).baselineSensitivityExcludedTrialNames(:));
    end

    excludedMask = ismember(trialNames,excludedNames);
    retainedMask = ~excludedMask;

    %% Existing 1-s local trial values for THE SAME stable trials

    localHolding = Data.(cond).trialHoldingCurrent(:)';
    localSynaptic = Data.(cond).trialSynapticCurrent_pA(:)';

    if numel(localHolding) ~= nTrials || numel(localSynaptic) ~= nTrials
        error(['Stored 1-s trial metrics for %s do not match the number of ' ...
            'selected stable trials.'],cond);
    end

    %% Store

    Sensitivity.(cond).excludedTrialNames = trialNames(excludedMask);
    Sensitivity.(cond).excludedMask = excludedMask;
    Sensitivity.(cond).retainedMask = retainedMask;
    Sensitivity.(cond).wholeFits = wholeFits;

    Sensitivity.(cond).wholeAllStable.trialNames = trialNames;
    Sensitivity.(cond).wholeAllStable.holdingCurrent_pA = wholeHolding;
    Sensitivity.(cond).wholeAllStable.synapticCurrent_pA = wholeSynaptic;
    Sensitivity.(cond).wholeAllStable.avgHoldingCurrent_pA = mean(wholeHolding,'omitnan');
    Sensitivity.(cond).wholeAllStable.avgSynapticCurrent_pA = mean(wholeSynaptic,'omitnan');
    Sensitivity.(cond).wholeAllStable.nTrials = nTrials;

    Sensitivity.(cond).wholeRetained.trialNames = trialNames(retainedMask);
    Sensitivity.(cond).wholeRetained.holdingCurrent_pA = wholeHolding(retainedMask);
    Sensitivity.(cond).wholeRetained.synapticCurrent_pA = wholeSynaptic(retainedMask);
    Sensitivity.(cond).wholeRetained.avgHoldingCurrent_pA = mean(wholeHolding(retainedMask),'omitnan');
    Sensitivity.(cond).wholeRetained.avgSynapticCurrent_pA = mean(wholeSynaptic(retainedMask),'omitnan');
    Sensitivity.(cond).wholeRetained.nTrials = sum(retainedMask);

    Sensitivity.(cond).localStable.trialNames = trialNames;
    Sensitivity.(cond).localStable.holdingCurrent_pA = localHolding;
    Sensitivity.(cond).localStable.synapticCurrent_pA = localSynaptic;
    Sensitivity.(cond).localStable.avgHoldingCurrent_pA = mean(localHolding,'omitnan');
    Sensitivity.(cond).localStable.avgSynapticCurrent_pA = mean(localSynaptic,'omitnan');
    Sensitivity.(cond).localStable.nTrials = nTrials;
end

%% CONTROL -> WASHOUT DELTAS

controlCond = S.baselineCondition;
washCond = S.washCondition;

Sensitivity.delta.wholeAllStable.holdingCurrent_pA = ...
    Sensitivity.(washCond).wholeAllStable.avgHoldingCurrent_pA - ...
    Sensitivity.(controlCond).wholeAllStable.avgHoldingCurrent_pA;

Sensitivity.delta.wholeAllStable.synapticCurrent_pA = ...
    Sensitivity.(washCond).wholeAllStable.avgSynapticCurrent_pA - ...
    Sensitivity.(controlCond).wholeAllStable.avgSynapticCurrent_pA;

Sensitivity.delta.wholeRetained.holdingCurrent_pA = ...
    Sensitivity.(washCond).wholeRetained.avgHoldingCurrent_pA - ...
    Sensitivity.(controlCond).wholeRetained.avgHoldingCurrent_pA;

Sensitivity.delta.wholeRetained.synapticCurrent_pA = ...
    Sensitivity.(washCond).wholeRetained.avgSynapticCurrent_pA - ...
    Sensitivity.(controlCond).wholeRetained.avgSynapticCurrent_pA;

Sensitivity.delta.localStable.holdingCurrent_pA = ...
    Sensitivity.(washCond).localStable.avgHoldingCurrent_pA - ...
    Sensitivity.(controlCond).localStable.avgHoldingCurrent_pA;

Sensitivity.delta.localStable.synapticCurrent_pA = ...
    Sensitivity.(washCond).localStable.avgSynapticCurrent_pA - ...
    Sensitivity.(controlCond).localStable.avgSynapticCurrent_pA;

%% FIGURE

fig = figure('Color','w','Position',[60 60 1800 850]);
t = tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');

ax1 = nexttile(t,1);
ax2 = nexttile(t,2);
ax3 = nexttile(t,3);
ax4 = nexttile(t,4);
ax5 = nexttile(t,5);
ax6 = nexttile(t,6);

plotPanel(ax1,Sensitivity,plotConditions,plotColors, ...
    'wholeAllStable','holdingCurrent_pA', ...
    Sensitivity.delta.wholeAllStable.holdingCurrent_pA,true);

plotPanel(ax2,Sensitivity,plotConditions,plotColors, ...
    'wholeRetained','holdingCurrent_pA', ...
    Sensitivity.delta.wholeRetained.holdingCurrent_pA,false);

plotPanel(ax3,Sensitivity,plotConditions,plotColors, ...
    'localStable','holdingCurrent_pA', ...
    Sensitivity.delta.localStable.holdingCurrent_pA,true);

plotPanel(ax4,Sensitivity,plotConditions,plotColors, ...
    'wholeAllStable','synapticCurrent_pA', ...
    Sensitivity.delta.wholeAllStable.synapticCurrent_pA,true);

plotPanel(ax5,Sensitivity,plotConditions,plotColors, ...
    'wholeRetained','synapticCurrent_pA', ...
    Sensitivity.delta.wholeRetained.synapticCurrent_pA,false);

plotPanel(ax6,Sensitivity,plotConditions,plotColors, ...
    'localStable','synapticCurrent_pA', ...
    Sensitivity.delta.localStable.synapticCurrent_pA,true);

title(ax1,sprintf('Whole %.1f s: all stable trials',analysisDurationSec));
title(ax2,sprintf('Whole %.1f s: unstable trials removed',analysisDurationSec));
title(ax3,'1-s local: same stable trials');

title(ax4,sprintf('Whole %.1f s: all stable trials',analysisDurationSec));
title(ax5,sprintf('Whole %.1f s: unstable trials removed',analysisDurationSec));
title(ax6,'1-s local: same stable trials');

ylabel(ax1,'Gaussian holding current, \mu (pA)');
ylabel(ax2,'Gaussian holding current, \mu (pA)');
ylabel(ax3,'Gaussian holding current, \mu (pA)');

ylabel(ax4,'Synaptic current magnitude (pA)');
ylabel(ax5,'Synaptic current magnitude (pA)');
ylabel(ax6,'Synaptic current magnitude (pA)');

holdingVals = collectValues(Sensitivity,plotConditions, ...
    {'wholeAllStable','wholeRetained','localStable'},'holdingCurrent_pA');

synapticVals = collectValues(Sensitivity,plotConditions, ...
    {'wholeAllStable','wholeRetained','localStable'},'synapticCurrent_pA');

setSharedLimits([ax1 ax2 ax3],holdingVals,false);
setSharedLimits([ax4 ax5 ax6],synapticVals,true);

if isfield(Expt,'marker')
    marker = string(Expt.marker);
else
    marker = "";
end

sgtitle(t,sprintf('%s | Whole-trial sensitivity + 1-s stable-trial comparison',marker), ...
    'Interpreter','none');

%% PRINT SUMMARY

fprintf('\n============================================================\n');
fprintf('%s analysis comparison\n',marker);
fprintf('============================================================\n');

for c = 1:2
    cond = plotConditions{c};

    fprintf('\n%s\n',strrep(cond,'_','/'));

    fprintf('Whole 19 s, all stable: n=%d | holding %.2f pA | synaptic %.2f pA\n', ...
        Sensitivity.(cond).wholeAllStable.nTrials, ...
        Sensitivity.(cond).wholeAllStable.avgHoldingCurrent_pA, ...
        Sensitivity.(cond).wholeAllStable.avgSynapticCurrent_pA);

    fprintf('Whole 19 s, unstable removed: n=%d | holding %.2f pA | synaptic %.2f pA\n', ...
        Sensitivity.(cond).wholeRetained.nTrials, ...
        Sensitivity.(cond).wholeRetained.avgHoldingCurrent_pA, ...
        Sensitivity.(cond).wholeRetained.avgSynapticCurrent_pA);

    if isempty(Sensitivity.(cond).excludedTrialNames)
        fprintf('Excluded: none\n');
    else
        fprintf('Excluded: %s\n', ...
            strjoin(Sensitivity.(cond).excludedTrialNames,', '));
    end

    fprintf('1-s local, same stable trials: n=%d | holding %.2f pA | synaptic %.2f pA\n', ...
        Sensitivity.(cond).localStable.nTrials, ...
        Sensitivity.(cond).localStable.avgHoldingCurrent_pA, ...
        Sensitivity.(cond).localStable.avgSynapticCurrent_pA);
end

fprintf('\nControl -> Washout deltas\n');

fprintf('Whole 19 s, all stable: holding %.2f pA | synaptic %.2f pA\n', ...
    Sensitivity.delta.wholeAllStable.holdingCurrent_pA, ...
    Sensitivity.delta.wholeAllStable.synapticCurrent_pA);

fprintf('Whole 19 s, unstable removed: holding %.2f pA | synaptic %.2f pA\n', ...
    Sensitivity.delta.wholeRetained.holdingCurrent_pA, ...
    Sensitivity.delta.wholeRetained.synapticCurrent_pA);

fprintf('1-s local, same stable trials: holding %.2f pA | synaptic %.2f pA\n', ...
    Sensitivity.delta.localStable.holdingCurrent_pA, ...
    Sensitivity.delta.localStable.synapticCurrent_pA);

fprintf('============================================================\n');

%% SAVE

if nargin >= 5 && ~isempty(figureFolder)
    if ~exist(figureFolder,'dir')
        mkdir(figureFolder);
    end

    savefig(fig,fullfile(figureFolder,'Whole Trial and 1s Analysis Comparison.fig'));

    exportgraphics(t, ...
        fullfile(figureFolder,'Whole Trial and 1s Analysis Comparison.png'), ...
        'Resolution',300);
end

end


function plotPanel(ax,Sensitivity,plotConditions,plotColors,analysisName,fieldName,deltaValue,showExcluded)

hold(ax,'on');

for c = 1:numel(plotConditions)
    cond = plotConditions{c};

    values = Sensitivity.(cond).(analysisName).(fieldName)(:);
    trialNames = string(Sensitivity.(cond).(analysisName).trialNames(:));
    x = repmat(c,numel(values),1);

    excludedMask = false(size(values));

    if showExcluded
        excludedMask = ismember(trialNames,Sensitivity.(cond).excludedTrialNames);
    end

    includedMask = ~excludedMask;

    scatter(ax,x(includedMask),values(includedMask),55,plotColors{c}, ...
        'filled','MarkerEdgeColor','k');

    if any(excludedMask)
        scatter(ax,x(excludedMask),values(excludedMask),55,'r', ...
            'filled','MarkerEdgeColor','k');
    end

    thisMean = mean(values,'omitnan');

    if isempty(values)
        text(ax,c,0.5,'No retained trials', ...
            'Units','data','HorizontalAlignment','center', ...
            'FontAngle','italic','Color',[0.35 0.35 0.35]);
    else
        plot(ax,[c-0.25 c+0.25],[thisMean thisMean],'k-','LineWidth',2);
    end
end

set(ax,'XTick',1:numel(plotConditions), ...
    'XTickLabel',strrep(plotConditions,'_','/'));

xlim(ax,[0.5 numel(plotConditions)+0.5]);
box(ax,'off');

text(ax,0.02,0.98,sprintf('\\Delta wash-control = %.2f pA',deltaValue), ...
    'Units','normalized','VerticalAlignment','top','FontWeight','bold');

end


function vals = collectValues(Sensitivity,plotConditions,analysisNames,fieldName)

vals = [];

for a = 1:numel(analysisNames)
    analysisName = analysisNames{a};

    for c = 1:numel(plotConditions)
        cond = plotConditions{c};
        x = Sensitivity.(cond).(analysisName).(fieldName);
        vals = [vals x(:)']; %#ok<AGROW>
    end
end

vals = vals(isfinite(vals));

end


function setSharedLimits(axesHandles,values,forceZeroLower)

values = values(isfinite(values));

if isempty(values)
    return
end

ymin = min(values);
ymax = max(values);

if forceZeroLower
    ymin = 0;
end

span = ymax-ymin;

if ~isfinite(span) || span == 0
    span = max(abs([ymin ymax]));

    if ~isfinite(span) || span == 0
        span = 1;
    end
end

pad = 0.10*span;

if forceZeroLower
    lims = [0 ymax+pad];
else
    lims = [ymin-pad ymax+pad];
end

for k = 1:numel(axesHandles)
    ylim(axesHandles(k),lims);
end

end
