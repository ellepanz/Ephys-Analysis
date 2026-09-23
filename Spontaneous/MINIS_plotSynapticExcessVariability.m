function MINIS_plotSynapticExcessVariability(Data,S,conditions,color,figureFolder,Expt)
% Plot whole-trial holding-current and synaptic-current variability.
%
% Dots       = individual analyzed whole trials
% Black bars = mean across analyzed trials
%
% Trials excluded during whole-trial baseline QC are not plotted.

plotConditions = getAnalysisConditions(conditions,S);
nCond = numel(plotConditions);

if nCond == 0
    error('No conditions remain for holding/synaptic-current plotting.');
end

plotColors = cell(1,nCond);

for c = 1:nCond
    condIdx = find(strcmp(conditions,plotConditions{c}),1);

    if isempty(condIdx)
        error('Condition %s was not found in conditions.',plotConditions{c});
    end

    plotColors{c} = color{condIdx};

    if ~isfield(Data.(plotConditions{c}),'wholeTrial')
        error('Data.%s.wholeTrial is missing. Run MINIS_calculateWholeTrialMetrics first.',plotConditions{c});
    end
end

fig = figure('Color','w','Position',[200 100 1200 500]);
t = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');

%% HOLDING CURRENT

axHolding = nexttile(t);
hold(axHolding,'on');

holdingMeans = nan(1,nCond);
allHolding = [];

for c = 1:nCond
    cond = plotConditions{c};
    trialValues = Data.(cond).wholeTrial.trialHoldingCurrent;
    trialValues = trialValues(isfinite(trialValues));

    allHolding = [allHolding; trialValues(:)];

    if ~isempty(trialValues)
        x = c + linspace(-0.12,0.12,numel(trialValues));

        scatter(axHolding,x,trialValues,55,plotColors{c}, ...
            'filled','MarkerEdgeColor','k');
    end

    holdingMeans(c) = mean(trialValues,'omitnan');

    plot(axHolding,[c-0.25 c+0.25], ...
        [holdingMeans(c) holdingMeans(c)], ...
        'k-','LineWidth',2);
end

set(axHolding,'XTick',1:nCond, ...
    'XTickLabel',strrep(plotConditions,'_','/'));

xlim(axHolding,[0.5 nCond+0.5]);

if ~isempty(allHolding)
    ymin = min(allHolding);
    ymax = max(allHolding);
    pad = 0.1*(ymax-ymin);

    if ~isfinite(pad) || pad == 0
        pad = 1;
    end

    ylim(axHolding,[ymin-pad ymax+pad]);
end

ylabel(axHolding,'Gaussian holding current, \mu (pA)');
title(axHolding,'Holding current');
box(axHolding,'off');

%% SYNAPTIC CURRENT

axSynaptic = nexttile(t);
hold(axSynaptic,'on');

synapticMeans = nan(1,nCond);
allSynaptic = [];

for c = 1:nCond
    cond = plotConditions{c};
    trialValues = Data.(cond).wholeTrial.trialSynapticCurrent_pA;
    trialValues = trialValues(isfinite(trialValues));

    allSynaptic = [allSynaptic; trialValues(:)];

    if ~isempty(trialValues)
        x = c + linspace(-0.12,0.12,numel(trialValues));

        scatter(axSynaptic,x,trialValues,55,plotColors{c}, ...
            'filled','MarkerEdgeColor','k');
    end

    synapticMeans(c) = mean(trialValues,'omitnan');

    plot(axSynaptic,[c-0.25 c+0.25], ...
        [synapticMeans(c) synapticMeans(c)], ...
        'k-','LineWidth',2);
end

set(axSynaptic,'XTick',1:nCond, ...
    'XTickLabel',strrep(plotConditions,'_','/'));

xlim(axSynaptic,[0.5 nCond+0.5]);

if ~isempty(allSynaptic)
    ymax = 1.15*max(allSynaptic);

    if ~isfinite(ymax) || ymax <= 0
        ymax = 1;
    end

    ylim(axSynaptic,[0 ymax]);
end

ylabel(axSynaptic,'Synaptic current magnitude (pA)');
title(axSynaptic,'Phasic synaptic current');
box(axSynaptic,'off');

sgtitle(sprintf('%s Whole-Trial Summary',Expt.marker));

%% PRINT CONDITION CHANGES

for c = 2:nCond
    fprintf('%s -> %s: holding delta %.2f pA; synaptic-current delta %.2f pA\n', ...
        strrep(plotConditions{c-1},'_','/'), ...
        strrep(plotConditions{c},'_','/'), ...
        holdingMeans(c)-holdingMeans(c-1), ...
        synapticMeans(c)-synapticMeans(c-1));
end

%% SAVE

if nargin >= 5 && ~isempty(figureFolder)
    savefig(fig, ...
        fullfile(figureFolder,'Holding Synaptic Excess Variability.fig'));

    exportgraphics(t, ...
        fullfile(figureFolder,'Holding Synaptic Excess Variability.png'), ...
        'Resolution',300);
end

end


function plotConditions = getAnalysisConditions(conditions,S)

if isfield(S,'excludedAnalysisConditions')
    excluded = S.excludedAnalysisConditions;
elseif isfield(S,'drugCondition')
    excluded = {S.drugCondition};
else
    excluded = {};
end

mask = ~ismember(lower(string(conditions)),lower(string(excluded)));
plotConditions = conditions(mask);

end