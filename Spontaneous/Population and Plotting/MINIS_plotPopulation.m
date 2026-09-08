function MINIS_plotPopulation(Expt)
% Plot population-level holding current and histogram synaptic current/charge.
%
% Population is selected from Expt.recordingType and Expt.studyID.
%
% Figure 1:
%   Baseline versus washout
%
% Figure 2:
%   Absolute change from baseline
%
% Figure 3:
%   Percent change from baseline

%% LOAD POPULATION TABLE

paths = MINIS_getPopulationPaths(Expt);
populationFile = paths.populationFile;

if ~isfile(populationFile)
    error('Population file not found: %s',populationFile);
end

tmp = load(populationFile,'Population');

if ~isfield(tmp,'Population')
    error('Population variable not found in %s.',populationFile);
end

Population = tmp.Population;
nCells = height(Population);

requiredVars = { ...
    'avgBaselineHolding', ...
    'avgWashoutHolding', ...
    'DeltaHolding', ...
    'avgBaselineSynapticCurrent_pA', ...
    'avgWashoutSynapticCurrent_pA', ...
    'DeltaSynapticCurrent_pA', ...
    'avgBaselineSynapticCharge_pC', ...
    'avgWashoutSynapticCharge_pC', ...
    'DeltaSynapticCharge_pC'};

missingVars = setdiff(requiredVars,Population.Properties.VariableNames);

if ~isempty(missingVars)
    error('Population table is missing current histogram metric columns: %s. Re-run MINIS_addCellToPopulation with the updated code.', ...
        strjoin(missingVars,', '));
end

fprintf('Plotting %s / %s population of %d cells.\n', ...
    Expt.recordingType,Expt.studyID,nCells);

%% =========================================================
% FIGURE 1: BASELINE VS WASHOUT
% ==========================================================

fig = figure('Color','w','Position',[200 100 1300 500]);
t = tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');

%% HOLDING CURRENT

ax = nexttile(t);
hold(ax,'on');

base = Population.avgBaselineHolding;
wash = Population.avgWashoutHolding;
valid = isfinite(base) & isfinite(wash);

plotPairedData(ax,base,wash,valid);

meanBase = mean(base(valid),'omitnan');
meanWash = mean(wash(valid),'omitnan');

semBase = std(base(valid),'omitnan')/sqrt(sum(valid));
semWash = std(wash(valid),'omitnan')/sqrt(sum(valid));

hMean = errorbar(ax,1,meanBase,semBase,'ko','MarkerFaceColor','k','LineWidth',1.5, ...
    'MarkerSize',8,'DisplayName','Population mean \pm SEM');

errorbar(ax,2,meanWash,semWash,'ko','MarkerFaceColor','k','LineWidth',1.5, ...
    'MarkerSize',8,'HandleVisibility','off');

plot(ax,[1 2],[meanBase meanWash],'k-','LineWidth',2,'HandleVisibility','off');

xlim(ax,[0.5 2.5]);
set(ax,'XTick',[1 2],'XTickLabel',{'Baseline','Washout'});
ylabel(ax,'Gaussian holding current, \mu (pA)');
title(ax,sprintf('Holding current | n = %d | mean \\Delta = %.2f pA', ...
    sum(valid),mean(wash(valid)-base(valid),'omitnan')));

addPopulationLegend(ax,hMean);
box(ax,'off');

%% SYNAPTIC CURRENT

ax = nexttile(t);
hold(ax,'on');

base = Population.avgBaselineSynapticCurrent_pA;
wash = Population.avgWashoutSynapticCurrent_pA;
valid = isfinite(base) & isfinite(wash);

plotPairedData(ax,base,wash,valid);

meanBase = mean(base(valid),'omitnan');
meanWash = mean(wash(valid),'omitnan');

semBase = std(base(valid),'omitnan')/sqrt(sum(valid));
semWash = std(wash(valid),'omitnan')/sqrt(sum(valid));

hMean = errorbar(ax,1,meanBase,semBase,'ko','MarkerFaceColor','k','LineWidth',1.5, ...
    'MarkerSize',8,'DisplayName','Population mean \pm SEM');

errorbar(ax,2,meanWash,semWash,'ko','MarkerFaceColor','k','LineWidth',1.5, ...
    'MarkerSize',8,'HandleVisibility','off');

plot(ax,[1 2],[meanBase meanWash],'k-','LineWidth',2,'HandleVisibility','off');

xlim(ax,[0.5 2.5]);
set(ax,'XTick',[1 2],'XTickLabel',{'Baseline','Washout'});
ylabel(ax,'Synaptic current magnitude (pA)');
title(ax,sprintf('Synaptic current | n = %d | mean \\Delta = %.2f pA', ...
    sum(valid),mean(wash(valid)-base(valid),'omitnan')));

addPopulationLegend(ax,hMean);
box(ax,'off');

%% SYNAPTIC CHARGE

ax = nexttile(t);
hold(ax,'on');

base = Population.avgBaselineSynapticCharge_pC;
wash = Population.avgWashoutSynapticCharge_pC;
valid = isfinite(base) & isfinite(wash);

plotPairedData(ax,base,wash,valid);

meanBase = mean(base(valid),'omitnan');
meanWash = mean(wash(valid),'omitnan');

semBase = std(base(valid),'omitnan')/sqrt(sum(valid));
semWash = std(wash(valid),'omitnan')/sqrt(sum(valid));

hMean = errorbar(ax,1,meanBase,semBase,'ko','MarkerFaceColor','k','LineWidth',1.5, ...
    'MarkerSize',8,'DisplayName','Population mean \pm SEM');

errorbar(ax,2,meanWash,semWash,'ko','MarkerFaceColor','k','LineWidth',1.5, ...
    'MarkerSize',8,'HandleVisibility','off');

plot(ax,[1 2],[meanBase meanWash],'k-','LineWidth',2,'HandleVisibility','off');

xlim(ax,[0.5 2.5]);
set(ax,'XTick',[1 2],'XTickLabel',{'Baseline','Washout'});
ylabel(ax,'Synaptic charge magnitude (pC)');
title(ax,sprintf('Synaptic charge | n = %d | mean \\Delta = %.2f pC', ...
    sum(valid),mean(wash(valid)-base(valid),'omitnan')));

addPopulationLegend(ax,hMean);
box(ax,'off');

title(t,sprintf('%s %s Population Summary',Expt.recordingType,Expt.studyID), ...
    'Interpreter','none');

%% =========================================================
% FIGURE 2: CHANGE FROM BASELINE
% ==========================================================

fig2 = figure('Color','w','Position',[250 150 1200 450]);
t2 = tiledlayout(fig2,1,3,'TileSpacing','compact','Padding','compact');

%% DELTA HOLDING

ax = nexttile(t2);
hold(ax,'on');

delta = Population.DeltaHolding;
delta = delta(isfinite(delta));

plotDeltaData(ax,delta);

meanDelta = mean(delta,'omitnan');
semDelta = std(delta,'omitnan')/sqrt(numel(delta));

ylabel(ax,'Washout - Baseline (pA)');
title(ax,sprintf('Holding current change | %.2f +/- %.2f pA',meanDelta,semDelta));
box(ax,'off');

%% DELTA SYNAPTIC CURRENT

ax = nexttile(t2);
hold(ax,'on');

delta = Population.DeltaSynapticCurrent_pA;
delta = delta(isfinite(delta));

plotDeltaData(ax,delta);

meanDelta = mean(delta,'omitnan');
semDelta = std(delta,'omitnan')/sqrt(numel(delta));

ylabel(ax,'Washout - Baseline (pA)');
title(ax,sprintf('Synaptic current change | %.2f +/- %.2f pA',meanDelta,semDelta));
box(ax,'off');

%% DELTA SYNAPTIC CHARGE

ax = nexttile(t2);
hold(ax,'on');

delta = Population.DeltaSynapticCharge_pC;
delta = delta(isfinite(delta));

plotDeltaData(ax,delta);

meanDelta = mean(delta,'omitnan');
semDelta = std(delta,'omitnan')/sqrt(numel(delta));

ylabel(ax,'Washout - Baseline (pC)');
title(ax,sprintf('Synaptic charge change | %.2f +/- %.2f pC',meanDelta,semDelta));
box(ax,'off');

title(t2,sprintf('%s %s Change from Baseline',Expt.recordingType,Expt.studyID), ...
    'Interpreter','none');

%% =========================================================
% FIGURE 3: PERCENT CHANGE FROM BASELINE
% ==========================================================

fig3 = figure('Color','w','Position',[300 200 1200 450]);
t3 = tiledlayout(fig3,1,3,'TileSpacing','compact','Padding','compact');

%% PERCENT CHANGE HOLDING

ax = nexttile(t3);
hold(ax,'on');

base = Population.avgBaselineHolding;
wash = Population.avgWashoutHolding;

valid = isfinite(base) & isfinite(wash) & base ~= 0;
percentChange = (wash(valid)-base(valid))./abs(base(valid))*100;

plotDeltaData(ax,percentChange);

meanPercent = mean(percentChange,'omitnan');
semPercent = std(percentChange,'omitnan')/sqrt(numel(percentChange));

ylabel(ax,'Change from baseline (%)');
title(ax,sprintf('Holding current | %.2f +/- %.2f%%',meanPercent,semPercent));
box(ax,'off');

%% PERCENT CHANGE SYNAPTIC CURRENT

ax = nexttile(t3);
hold(ax,'on');

base = Population.avgBaselineSynapticCurrent_pA;
wash = Population.avgWashoutSynapticCurrent_pA;

valid = isfinite(base) & isfinite(wash) & base ~= 0;
percentChange = (wash(valid)-base(valid))./abs(base(valid))*100;

plotDeltaData(ax,percentChange);

meanPercent = mean(percentChange,'omitnan');
semPercent = std(percentChange,'omitnan')/sqrt(numel(percentChange));

ylabel(ax,'Change from baseline (%)');
title(ax,sprintf('Synaptic current | %.2f +/- %.2f%%',meanPercent,semPercent));
box(ax,'off');

%% PERCENT CHANGE SYNAPTIC CHARGE

ax = nexttile(t3);
hold(ax,'on');

base = Population.avgBaselineSynapticCharge_pC;
wash = Population.avgWashoutSynapticCharge_pC;

valid = isfinite(base) & isfinite(wash) & base ~= 0;
percentChange = (wash(valid)-base(valid))./abs(base(valid))*100;

plotDeltaData(ax,percentChange);

meanPercent = mean(percentChange,'omitnan');
semPercent = std(percentChange,'omitnan')/sqrt(numel(percentChange));

ylabel(ax,'Change from baseline (%)');
title(ax,sprintf('Synaptic charge | %.2f +/- %.2f%%',meanPercent,semPercent));
box(ax,'off');

title(t3,sprintf('%s %s Percent Change from Baseline',Expt.recordingType,Expt.studyID), ...
    'Interpreter','none');

end


%% PLOT PAIRED BASELINE/WASHOUT DATA

function plotPairedData(ax,base,wash,valid)

validIdx = find(valid);

for ii = 1:numel(validIdx)

    k = validIdx(ii);

    if ii == 1
        plot(ax,[1 2],[base(k) wash(k)],'-o','Color',[0.7 0.7 0.7], ...
            'MarkerFaceColor',[0.7 0.7 0.7],'DisplayName','Individual cell');
    else
        plot(ax,[1 2],[base(k) wash(k)],'-o','Color',[0.7 0.7 0.7], ...
            'MarkerFaceColor',[0.7 0.7 0.7],'HandleVisibility','off');
    end
end

end


%% ADD POPULATION LEGEND

function addPopulationLegend(ax,hMean)

hCell = findobj(ax,'DisplayName','Individual cell');

if isempty(hCell)
    legend(ax,hMean,'Location','best');
else
    legend(ax,[hCell(1) hMean],'Location','best');
end

end


%% PLOT DELTA DATA

function plotDeltaData(ax,delta)

hCell = scatter(ax,ones(size(delta)),delta,50,'filled','DisplayName','Individual cell');
hZero = yline(ax,0,'--','DisplayName','No change');

meanDelta = mean(delta,'omitnan');
semDelta = std(delta,'omitnan')/sqrt(numel(delta));

hMean = errorbar(ax,1.25,meanDelta,semDelta,'ko','MarkerFaceColor','k','LineWidth',1.5, ...
    'MarkerSize',8,'DisplayName','Population mean \pm SEM');

xlim(ax,[0.7 1.5]);
set(ax,'XTick',[]);
legend(ax,[hCell hMean hZero],'Location','best');

end
