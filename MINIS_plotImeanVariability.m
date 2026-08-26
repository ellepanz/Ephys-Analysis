function MINIS_plotImeanVariability(Data,S,conditions,color,figureFolder,Expt)

% Plot variability in 1-s holding-current and phasic-current measurements
% for the selected stable baseline and washout periods.
%
% Small dots    = individual 1-s epochs
% Large circles = mean of the 1-s epochs within each trial
% Black bar     = mean across stable trials

plotConditions = {S.controlCondition,S.washCondition};

controlColorIdx = find(strcmp(conditions,S.controlCondition),1);
washColorIdx = find(strcmp(conditions,S.washCondition),1);
plotColors = {color{controlColorIdx},color{washColorIdx}};

fig = figure('Color','w','Position',[200 100 1100 500]);
t = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');


%% HOLDING CURRENT

ax = nexttile(t);
hold(ax,'on');

conditionMeans = nan(1,2);

for c = 1:2
    cond = plotConditions{c};

    values = Data.(cond).oneSecEpoch.epochHoldingCurrent;
    epochValues = values(:);
    epochValues = epochValues(isfinite(epochValues));

    x = c + linspace(-0.15,0.15,numel(epochValues))';
    scatter(ax,x,epochValues,15,plotColors{c},'filled','MarkerFaceAlpha',0.25);

    trialMeans = mean(values,1,'omitnan');
    scatter(ax,repmat(c,size(trialMeans)),trialMeans,55,plotColors{c},'filled','MarkerEdgeColor','k');

    conditionMeans(c) = mean(trialMeans,'omitnan');
    plot(ax,[c-0.25 c+0.25],[conditionMeans(c) conditionMeans(c)],'k-','LineWidth',2);
end


set(ax,'XTick',[1 2],'XTickLabel',{strrep(S.controlCondition,'_','/'),strrep(S.washCondition,'_','/')});
xlim(ax,[0.5 2.5]);
yl = ylim(ax);
ylim(ax,[yl(1) 0]);
ylabel(ax,'Gaussian holding current, \mu (pA)');
title(ax,sprintf('Holding current   \\Delta = %.2f pA',conditionMeans(2)-conditionMeans(1)));
box(ax,'off');


%% PHASIC Imean

ax = nexttile(t);
hold(ax,'on');

conditionMeans = nan(1,2);

for c = 1:2
    cond = plotConditions{c};

    values = Data.(cond).oneSecEpoch.epochPhasicImean;
    epochValues = values(:);
    epochValues = epochValues(isfinite(epochValues));

    x = c + linspace(-0.15,0.15,numel(epochValues))';
    scatter(ax,x,epochValues,15,plotColors{c},'filled','MarkerFaceAlpha',0.25);

    trialMeans = mean(values,1,'omitnan');
    scatter(ax,repmat(c,size(trialMeans)),trialMeans,55,plotColors{c},'filled','MarkerEdgeColor','k');

    conditionMeans(c) = mean(trialMeans,'omitnan');
    plot(ax,[c-0.25 c+0.25],[conditionMeans(c) conditionMeans(c)],'k-','LineWidth',2);
end

yline(ax,0,':');
set(ax,'XTick',[1 2],'XTickLabel',{strrep(S.controlCondition,'_','/'),strrep(S.washCondition,'_','/')});
xlim(ax,[0.5 2.5]);
ylabel(ax,'Phasic I_{mean} (pA)');
title(ax,sprintf('Phasic current   \\Delta = %.2f pA',conditionMeans(2)-conditionMeans(1)));
box(ax,'off');
sgtitle(sprintf('%s Summary', Expt.marker));

%% SAVE

if nargin >= 5 && ~isempty(figureFolder)
    savefig(fig,fullfile(figureFolder,'Phasic Holding Current Variability.fig'));
    saveas(fig,fullfile(figureFolder,'Phasic Holding Current Variability.png'));
end

end