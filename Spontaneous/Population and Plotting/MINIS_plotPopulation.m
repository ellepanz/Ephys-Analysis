function MINIS_plotPopulation(Expt)
% Plot presentation-ready population summaries for the dual analysis.
%
% Uses only rows marked DualReprocessed=true.
%
% Figure 1:
%   Whole19 and Local1s baseline-vs-washout holding + synaptic current
%
% Figure 2:
%   Direct comparison of each cell's washout-baseline delta between methods

paths = MINIS_getPopulationPaths(Expt);
populationFile = paths.populationFile;

if ~isfile(populationFile)
    error('Population file not found: %s',populationFile);
end

tmp = load(populationFile,'Population');

if ~isfield(tmp,'Population') || ~istable(tmp.Population)
    error('Population variable not found in %s.',populationFile);
end

Population = tmp.Population;

requiredVars = { ...
    'DualReprocessed', ...
    'Whole19_avgBaselineHolding','Whole19_avgWashoutHolding','Whole19_DeltaHolding', ...
    'Whole19_avgBaselineSynapticCurrent_pA','Whole19_avgWashoutSynapticCurrent_pA','Whole19_DeltaSynapticCurrent_pA', ...
    'Local1s_avgBaselineHolding','Local1s_avgWashoutHolding','Local1s_DeltaHolding', ...
    'Local1s_avgBaselineSynapticCurrent_pA','Local1s_avgWashoutSynapticCurrent_pA','Local1s_DeltaSynapticCurrent_pA'};

missingVars = setdiff(requiredVars,Population.Properties.VariableNames);

if ~isempty(missingVars)
    error('Population is missing dual-analysis columns: %s',strjoin(missingVars,', '));
end

Population = Population(Population.DualReprocessed == true,:);

if isempty(Population)
    error('No dual-reprocessed cells are currently in the population.');
end

fprintf('Plotting %s / %s dual population: n = %d cells.\n', ...
    Expt.recordingType,Expt.studyID,height(Population));

outFolder = paths.folder;

if ~exist(outFolder,'dir')
    mkdir(outFolder);
end

%% FIGURE 1: BOTH METHODS

fig = figure('Color','w','Position',[100 80 1250 850]);
t = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');

ax1 = nexttile(t,1);
plotPairedSummary(ax1, ...
    Population.Whole19_avgBaselineHolding, ...
    Population.Whole19_avgWashoutHolding, ...
    'Gaussian holding current, \mu (pA)','Whole 19 s: holding current');

ax2 = nexttile(t,2);
plotPairedSummary(ax2, ...
    Population.Whole19_avgBaselineSynapticCurrent_pA, ...
    Population.Whole19_avgWashoutSynapticCurrent_pA, ...
    'Synaptic current magnitude (pA)','Whole 19 s: synaptic current');

ax3 = nexttile(t,3);
plotPairedSummary(ax3, ...
    Population.Local1s_avgBaselineHolding, ...
    Population.Local1s_avgWashoutHolding, ...
    'Gaussian holding current, \mu (pA)','1-s local: holding current');

ax4 = nexttile(t,4);
plotPairedSummary(ax4, ...
    Population.Local1s_avgBaselineSynapticCurrent_pA, ...
    Population.Local1s_avgWashoutSynapticCurrent_pA, ...
    'Synaptic current magnitude (pA)','1-s local: synaptic current');

title(t,sprintf('%s %s Population | Dual Histogram Analysis | n = %d', ...
    Expt.recordingType,Expt.studyID,height(Population)),'Interpreter','none');

savefig(fig,fullfile(outFolder,'Population Dual Analysis Summary.fig'));
exportgraphics(t,fullfile(outFolder,'Population Dual Analysis Summary.png'),'Resolution',300);

%% FIGURE 2: DIRECT METHOD COMPARISON OF DELTAS

fig2 = figure('Color','w','Position',[150 120 1100 480]);
t2 = tiledlayout(fig2,1,2,'TileSpacing','compact','Padding','compact');

ax = nexttile(t2,1);
plotMethodDeltaComparison(ax, ...
    Population.Whole19_DeltaHolding, ...
    Population.Local1s_DeltaHolding, ...
    'Washout - Baseline holding current (pA)', ...
    'Holding-current effect');

ax = nexttile(t2,2);
plotMethodDeltaComparison(ax, ...
    Population.Whole19_DeltaSynapticCurrent_pA, ...
    Population.Local1s_DeltaSynapticCurrent_pA, ...
    'Washout - Baseline synaptic current (pA)', ...
    'Synaptic-current effect');

title(t2,sprintf('%s %s | Whole 19 s vs 1-s Local', ...
    Expt.recordingType,Expt.studyID),'Interpreter','none');

savefig(fig2,fullfile(outFolder,'Population Method Delta Comparison.fig'));
exportgraphics(t2,fullfile(outFolder,'Population Method Delta Comparison.png'),'Resolution',300);

fprintf('Saved population figures to %s\n',outFolder);

end


function plotPairedSummary(ax,base,wash,yLabelText,titleText)

hold(ax,'on');

valid = isfinite(base) & isfinite(wash);
base = base(valid);
wash = wash(valid);
n = numel(base);

for k = 1:n
    plot(ax,[1 2],[base(k) wash(k)],'-o', ...
        'Color',[0.7 0.7 0.7], ...
        'MarkerFaceColor',[0.7 0.7 0.7], ...
        'MarkerEdgeColor',[0.3 0.3 0.3], ...
        'HandleVisibility','off');
end

if n > 0
    meanBase = mean(base,'omitnan');
    meanWash = mean(wash,'omitnan');
    semBase = std(base,'omitnan')/sqrt(n);
    semWash = std(wash,'omitnan')/sqrt(n);

    errorbar(ax,1,meanBase,semBase,'ko','MarkerFaceColor','k','LineWidth',1.5,'MarkerSize',8);
    errorbar(ax,2,meanWash,semWash,'ko','MarkerFaceColor','k','LineWidth',1.5,'MarkerSize',8);
    plot(ax,[1 2],[meanBase meanWash],'k-','LineWidth',2);

    meanDelta = mean(wash-base,'omitnan');
else
    meanDelta = NaN;
end

xlim(ax,[0.5 2.5]);
set(ax,'XTick',[1 2],'XTickLabel',{'Baseline','Washout'});
ylabel(ax,yLabelText);
title(ax,sprintf('%s | n = %d | mean \\Delta = %.2f',titleText,n,meanDelta));
box(ax,'off');

end


function plotMethodDeltaComparison(ax,wholeDelta,localDelta,yLabelText,titleText)

hold(ax,'on');

valid = isfinite(wholeDelta) & isfinite(localDelta);
wholeDelta = wholeDelta(valid);
localDelta = localDelta(valid);
n = numel(wholeDelta);

for k = 1:n
    plot(ax,[1 2],[wholeDelta(k) localDelta(k)],'-o', ...
        'Color',[0.7 0.7 0.7], ...
        'MarkerFaceColor',[0.7 0.7 0.7], ...
        'MarkerEdgeColor',[0.3 0.3 0.3], ...
        'HandleVisibility','off');
end

yline(ax,0,'--','Color',[0.4 0.4 0.4]);

if n > 0
    meanWhole = mean(wholeDelta,'omitnan');
    meanLocal = mean(localDelta,'omitnan');
    semWhole = std(wholeDelta,'omitnan')/sqrt(n);
    semLocal = std(localDelta,'omitnan')/sqrt(n);

    errorbar(ax,1,meanWhole,semWhole,'ko','MarkerFaceColor','k','LineWidth',1.5,'MarkerSize',8);
    errorbar(ax,2,meanLocal,semLocal,'ko','MarkerFaceColor','k','LineWidth',1.5,'MarkerSize',8);
    plot(ax,[1 2],[meanWhole meanLocal],'k-','LineWidth',2);
end

xlim(ax,[0.5 2.5]);
set(ax,'XTick',[1 2],'XTickLabel',{'Whole 19 s','1-s local'});
ylabel(ax,yLabelText);
title(ax,sprintf('%s | n = %d',titleText,n));
box(ax,'off');

end
