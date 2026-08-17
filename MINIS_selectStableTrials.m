function Data = MINIS_selectStableTrials(Data, S, conditions, color, figureFolder)
% Plot QC-passed trial metrics over true experimental time and select a
% contiguous stable range for Control and Washout.
%
% Selection is manual by design: inspect BOTH Gaussian holding current and
% Rs, then click first/last stable trial on the holding-current panel.

% Preserve the original all-point-mean-per-trial plot as its own figure.
figMean = figure('Color','w','Position',[120 120 1200 500]);
axMeanOnly = axes(figMean); hold(axMeanOnly,'on');

firstTrialNum = findFirstTrialNum(Data, conditions);
conditionStartTimes = nan(1,numel(conditions));
for c = 1:numel(conditions)
    cond = conditions{c};
    tm = Data.(cond).trialTimeMin;
    plot(axMeanOnly,tm,Data.(cond).meanCurrent,'-o', ...
        'Color',color{c},'MarkerFaceColor',color{c},'LineWidth',1.2, ...
        'DisplayName',strrep(cond,'_','/'));
    [~,originalNums] = MINIS_getTrialInfo(Data,cond);
    conditionStartTimes(c) = ...
        ((min(originalNums)-firstTrialNum)*S.trialStartIntervalSec)/60;
end
for c = 2:numel(conditions)
    xline(axMeanOnly,conditionStartTimes(c),'--','LineWidth',1.2, ...
        'Color',[0.4 0.4 0.4],'HandleVisibility','off');
end
title(axMeanOnly,'All-Point Mean Per Trial');
xlabel(axMeanOnly,'Experimental time (min)');
ylabel(axMeanOnly,'Mean current (pA)');
legend(axMeanOnly,'Location','best');
box(axMeanOnly,'off');
MINIS_saveFigure(figMean,figureFolder,'All point mean per trial');

fig = figure('Color','w','Position',[1 49 1500 950]);
t = tiledlayout(fig,4,1,'TileSpacing','compact','Padding','compact');

axMean = nexttile(t); hold(axMean,'on');
axBase = nexttile(t); hold(axBase,'on');
axRs   = nexttile(t); hold(axRs,'on');
axRin  = nexttile(t); hold(axRin,'on');

for c = 1:numel(conditions)
    cond = conditions{c};

    if ~isfield(Data.(cond),'baselineCurrent')
        error('Run MINIS_calculateTrialMetrics before selecting stable trials.');
    end

    tm = Data.(cond).trialTimeMin;

    plot(axMean,tm,Data.(cond).meanCurrent,'-o', ...
        'Color',color{c},'MarkerFaceColor',color{c},'LineWidth',1.2, ...
        'DisplayName',strrep(cond,'_','/'));
    plot(axBase,tm,Data.(cond).baselineCurrent,'-o', ...
        'Color',color{c},'MarkerFaceColor',color{c},'LineWidth',1.2);
    plot(axRs,tm,Data.(cond).Rs,'-o', ...
        'Color',color{c},'MarkerFaceColor',color{c},'LineWidth',1.2);
    plot(axRin,tm,Data.(cond).Rin,'-o', ...
        'Color',color{c},'MarkerFaceColor',color{c},'LineWidth',1.2);

    [~,originalNums] = MINIS_getTrialInfo(Data,cond);
    conditionStartTimes(c) = ...
        ((min(originalNums)-firstTrialNum)*S.trialStartIntervalSec)/60;
end

% Draw condition boundaries on all panels.
axs = [axMean axBase axRs axRin];
for c = 2:numel(conditions)
    for a = 1:numel(axs)
        xline(axs(a),conditionStartTimes(c),'--','LineWidth',1.2, ...
            'Color',[0.4 0.4 0.4],'HandleVisibility','off');
    end
end

% Formatting
sgtitle(t,'Mini-IPSC Trial Stability / QC');
ylabel(axMean,'All-point mean (pA)');
ylabel(axBase,'Gaussian baseline (pA)');
ylabel(axRs,'R_s (M\Omega)');
ylabel(axRin,'R_{in} (M\Omega)');
xlabel(axRin,'Experimental time (min)');
legend(axMean,'Location','bestoutside');
linkaxes(axs,'x');
set(axs,'Box','off');

% Select stable Control range.
controlCond = S.controlCondition;
washCond = S.washCondition;

if ~isfield(Data,controlCond)
    error('Control condition "%s" was not found.', controlCond);
end
if ~isfield(Data,washCond)
    error('Wash condition "%s" was not found.', washCond);
end

axes(axBase); %#ok<LAXES>
disp(['Inspect Gaussian baseline and Rs. Click FIRST stable ' controlCond ' trial.']);
[x1,~] = ginput(1);
disp(['Click LAST stable ' controlCond ' trial.']);
[x2,~] = ginput(1);
controlIdx = nearestRange(Data.(controlCond).trialTimeMin,x1,x2);
Data = storeStableRange(Data,controlCond,controlIdx);

% Select stable Washout range.
axes(axBase); %#ok<LAXES>
disp(['Inspect Gaussian baseline and Rs. Click FIRST stable ' washCond ' trial.']);
[x1,~] = ginput(1);
disp(['Click LAST stable ' washCond ' trial.']);
[x2,~] = ginput(1);
washIdx = nearestRange(Data.(washCond).trialTimeMin,x1,x2);
Data = storeStableRange(Data,washCond,washIdx);

% Highlight selected trial points on every panel.
highlightRange(axMean,Data,controlCond,controlIdx,'meanCurrent');
highlightRange(axBase,Data,controlCond,controlIdx,'baselineCurrent');
highlightRange(axRs,Data,controlCond,controlIdx,'Rs');
highlightRange(axRin,Data,controlCond,controlIdx,'Rin');

highlightRange(axMean,Data,washCond,washIdx,'meanCurrent');
highlightRange(axBase,Data,washCond,washIdx,'baselineCurrent');
highlightRange(axRs,Data,washCond,washIdx,'Rs');
highlightRange(axRin,Data,washCond,washIdx,'Rin');

MINIS_saveFigure(fig,figureFolder,'All point mean baseline Rs Rin stable selection');
end

function idx = nearestRange(times,x1,x2)
[~,i1] = min(abs(times-x1));
[~,i2] = min(abs(times-x2));
idx = min(i1,i2):max(i1,i2);
end

function Data = storeStableRange(Data,cond,idx)
Data.(cond).stableQCIdx = idx;
Data.(cond).stableTrialNums = Data.(cond).QCTrialNums(idx);
Data.(cond).stableTrialNames = Data.(cond).QCTrialNames(idx);
Data.(cond).stableMiniData = Data.(cond).finalMiniData(:,idx);
Data.(cond).stableConcatData = Data.(cond).stableMiniData(:);
Data.(cond).stableBaselineCurrent = Data.(cond).baselineCurrent(idx);
Data.(cond).stableRs = Data.(cond).Rs(idx);
Data.(cond).stableRin = Data.(cond).Rin(idx);
end

function highlightRange(ax,Data,cond,idx,fieldName)
plot(ax,Data.(cond).trialTimeMin(idx),Data.(cond).(fieldName)(idx),'ko', ...
    'MarkerSize',10,'LineWidth',1.8,'HandleVisibility','off');
end

function firstTrialNum = findFirstTrialNum(Data, conditions)
allNums = [];
for c = 1:numel(conditions)
    [~,nums] = MINIS_getTrialInfo(Data,conditions{c});
    allNums = [allNums; nums(:)]; %#ok<AGROW>
end
firstTrialNum = min(allNums);
end
