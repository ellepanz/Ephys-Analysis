function MINIS_plotSynapticExcessVariability(Data,S,conditions,color,figureFolder,Expt)
% Plot 1-s holding-current and synaptic-excess variability.
%
% Small dots      = individual 1-s epochs
% Large circles   = per-trial means
% Black bars      = mean across stable trials

plotConditions = getAnalysisConditions(conditions,S);
nCond = numel(plotConditions);

if nCond == 0
    error('No conditions remain for holding/synaptic-excess variability plotting.');
end

plotColors = cell(1,nCond);

for c = 1:nCond
    condIdx = find(strcmp(conditions,plotConditions{c}),1);

    if isempty(condIdx)
        error('Condition %s was not found in conditions.',plotConditions{c});
    end

    plotColors{c} = color{condIdx};
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
    values = Data.(cond).oneSecEpoch.epochHoldingCurrent;

    epochValues = values(:);
    epochValues = epochValues(isfinite(epochValues));
    allHolding = [allHolding; epochValues];

    if ~isempty(epochValues)
        x = c + linspace(-0.15,0.15,numel(epochValues))';
        scatter(axHolding,x,epochValues,15,plotColors{c},'filled','MarkerFaceAlpha',0.25);
    end

    trialMeans = mean(values,1,'omitnan');
    validTrialMeans = trialMeans(isfinite(trialMeans));

    scatter(axHolding,repmat(c,size(validTrialMeans)),validTrialMeans,55,plotColors{c}, ...
        'filled','MarkerEdgeColor','k');

    holdingMeans(c) = mean(validTrialMeans,'omitnan');
    plot(axHolding,[c-0.25 c+0.25],[holdingMeans(c) holdingMeans(c)],'k-','LineWidth',2);
end

set(axHolding,'XTick',1:nCond,'XTickLabel',strrep(plotConditions,'_','/'));
xlim(axHolding,[0.5 nCond+0.5]);

if ~isempty(allHolding)
    maxAbsHolding = max(abs(allHolding));

    if maxAbsHolding <= 0 || ~isfinite(maxAbsHolding)
        maxAbsHolding = 1;
    end

    ylim(axHolding,[-1.15*maxAbsHolding 0]);
end

ylabel(axHolding,'Gaussian holding current, \mu (pA)');
title(axHolding,'Holding current');
box(axHolding,'off');

%% SYNAPTIC EXCESS FRACTION

axExcess = nexttile(t);
hold(axExcess,'on');

excessMeans = nan(1,nCond);
allExcess = [];

for c = 1:nCond
    cond = plotConditions{c};
    values = Data.(cond).oneSecEpoch.epochSynapticExcessFraction;

    epochValues = values(:);
    epochValues = epochValues(isfinite(epochValues));
    allExcess = [allExcess; epochValues];

    if ~isempty(epochValues)
        x = c + linspace(-0.15,0.15,numel(epochValues))';
        scatter(axExcess,x,epochValues,15,plotColors{c},'filled','MarkerFaceAlpha',0.25);
    end

    trialMeans = mean(values,1,'omitnan');
    validTrialMeans = trialMeans(isfinite(trialMeans));

    scatter(axExcess,repmat(c,size(validTrialMeans)),validTrialMeans,55,plotColors{c}, ...
        'filled','MarkerEdgeColor','k');

    excessMeans(c) = mean(validTrialMeans,'omitnan');
    plot(axExcess,[c-0.25 c+0.25],[excessMeans(c) excessMeans(c)],'k-','LineWidth',2);
end

set(axExcess,'XTick',1:nCond,'XTickLabel',strrep(plotConditions,'_','/'));
xlim(axExcess,[0.5 nCond+0.5]);

if ~isempty(allExcess)
    ymax = 1.15*max(allExcess);

    if ~isfinite(ymax) || ymax <= 0
        ymax = 1;
    end

    ylim(axExcess,[0 ymax]);
end

ylabel(axExcess,'Synaptic excess fraction');
title(axExcess,'Histogram synaptic excess');
box(axExcess,'off');

sgtitle(sprintf('%s Summary',Expt.marker));

for c = 2:nCond
    fprintf('%s -> %s: holding delta %.2f pA; synaptic-excess delta %.4f\n', ...
        strrep(plotConditions{c-1},'_','/'),strrep(plotConditions{c},'_','/'), ...
        holdingMeans(c)-holdingMeans(c-1),excessMeans(c)-excessMeans(c-1));
end

if nargin >= 5 && ~isempty(figureFolder)
    savefig(fig,fullfile(figureFolder,'Holding Synaptic Excess Variability.fig'));
    exportgraphics(fig,fullfile(figureFolder,'Holding Synaptic Excess Variability.png'),'Resolution',300);
end

end


function plotConditions = getAnalysisConditions(conditions,S)

if isfield(S,'excludedAnalysisConditions')
    excluded = S.excludedAnalysisConditions;
elseif isfield(S,'drugCondition')
    excluded = {S.drugCondition};
else
    excluded = {'NMDA'};
end

mask = ~ismember(lower(string(conditions)),lower(string(excluded)));
plotConditions = conditions(mask);

end
