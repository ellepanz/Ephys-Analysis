function Data = MINIS_selectStableTrials(Data,S,conditions,color,figureFolder,Expt)
% Plot trial-by-trial stability and select stable ranges for every condition
% except those listed in S.excludedAnalysisConditions (normally NMDA).

analysisConditions = getAnalysisConditions(conditions,S);

if isempty(analysisConditions)
    error('No conditions remain for stable-range analysis.');
end

requiredFields = {'notDelTrialNames','notDelTrialNums','notDelMiniData','baselineCurrent', ...
    'baselineSigma','baselineFitR2','trialBaselineFits','Rs','Rin'};

for c = 1:numel(conditions)
    cond = conditions{c};

    for f = 1:numel(requiredFields)
        if ~isfield(Data.(cond),requiredFields{f})
            error('Data.%s.%s does not exist.',cond,requiredFields{f});
        end
    end
end

%% EXPERIMENTAL TIME

allTrialNums = [];

for c = 1:numel(conditions)
    cond = conditions{c};
    [~,rawTrialNums] = MINIS_getTrialInfo(Data,cond,'raw');
    allTrialNums = [allTrialNums rawTrialNums(:)'];
end

firstTrialNum = min(allTrialNums);
conditionStartTimes = nan(1,numel(conditions));

for c = 1:numel(conditions)
    cond = conditions{c};

    trialNums = Data.(cond).notDelTrialNums;
    Data.(cond).trialTimeMin = ((trialNums-firstTrialNum)*S.trialStartIntervalSec)/60;

    [~,rawTrialNums] = MINIS_getTrialInfo(Data,cond,'raw');
    firstCondTrial = min(rawTrialNums);
    conditionStartTimes(c) = ((firstCondTrial-firstTrialNum)*S.trialStartIntervalSec)/60;
end

%% STABILITY FIGURE

fig = figure('Color','w','Position',[100 50 1400 900]);
t = tiledlayout(fig,4,1,'TileSpacing','compact','Padding','compact');

axBase = nexttile(t);
hold(axBase,'on');

axSigma = nexttile(t);
hold(axSigma,'on');

axRs = nexttile(t);
hold(axRs,'on');

axRin = nexttile(t);
hold(axRin,'on');

for c = 1:numel(conditions)
    cond = conditions{c};
    tm = Data.(cond).trialTimeMin;

    plot(axBase,tm,Data.(cond).baselineCurrent,'-o','Color',color{c}, ...
        'MarkerFaceColor',color{c},'LineWidth',1.2,'DisplayName',strrep(cond,'_','/'));

    plot(axSigma,tm,Data.(cond).baselineSigma,'-o','Color',color{c}, ...
        'MarkerFaceColor',color{c},'LineWidth',1.2,'HandleVisibility','off');

    plot(axRs,tm,Data.(cond).Rs,'-o','Color',color{c}, ...
        'MarkerFaceColor',color{c},'LineWidth',1.2,'HandleVisibility','off');

    plot(axRin,tm,Data.(cond).Rin,'-o','Color',color{c}, ...
        'MarkerFaceColor',color{c},'LineWidth',1.2,'HandleVisibility','off');
end

% Holding-current scale intentionally ignores NMDA/anomaly conditions.
holdingForLimits = collectTailFiniteField(Data,analysisConditions,'baselineCurrent',10);
allSigma = collectFiniteField(Data,conditions,'baselineSigma');
allRs = collectFiniteField(Data,conditions,'Rs');
allRin = collectFiniteField(Data,conditions,'Rin');

fprintf('\nBaseline-current y-limit calculation:\n');

for c = 1:numel(analysisConditions)
    cond = analysisConditions{c};
    vals = Data.(cond).baselineCurrent;
    fprintf('%s: min = %.1f, max = %.1f, max abs = %.1f pA\n', ...
        cond,min(vals,[],'omitnan'),max(vals,[],'omitnan'),max(abs(vals),[],'omitnan'));
end

fprintf('Combined max abs = %.1f pA\n',max(abs(holdingForLimits)));

if isempty(holdingForLimits)
    ylim(axBase,[-1 0]);
else
    maxAbsHolding = max(abs(holdingForLimits));
    if maxAbsHolding <= 0 || ~isfinite(maxAbsHolding)
        maxAbsHolding = 1;
    end
    ylim(axBase,[-1.5*maxAbsHolding 0]);
end

ylim(axSigma,[0 paddedPositiveMax(allSigma)]);
ylim(axRs,[0 paddedPositiveMax(allRs)]);
ylim(axRin,[0 paddedPositiveMax(allRin)]);

axs = [axBase axSigma axRs axRin];

for c = 2:numel(conditions)
    for a = 1:numel(axs)
        xline(axs(a),conditionStartTimes(c),'--','LineWidth',1.2, ...
            'Color',[0.4 0.4 0.4],'HandleVisibility','off');
    end
end

title(t,sprintf('%s %s', 'Trial Stability / QC, Experiment', Expt.marker))
ylabel(axBase,'Gaussian baseline \mu (pA)');
ylabel(axSigma,'Gaussian \sigma (pA)');
ylabel(axRs,'R_s (M\Omega)');
ylabel(axRin,'R_{in} (M\Omega)');
xlabel(axRin,'Experimental time (min)');
legend(axBase,'Location','bestoutside');
linkaxes(axs,'x');
set(axs,'Box','off');

% Save BEFORE ginput so failed cells retain a QC record.
if nargin >= 5 && ~isempty(figureFolder)
    saveStabilityFigure(fig,figureFolder);
end

%% SELECT STABLE RANGE FOR EACH ANALYZED CONDITION

for c = 1:numel(analysisConditions)
    cond = analysisConditions{c};

    figure(fig);
    axes(axBase); %#ok<LAXES>

    disp(' ');
    disp('Inspect baseline, sigma, Rs, and Rin.');
    disp(['Click FIRST stable ' strrep(cond,'_','/') ' trial.']);
    [x1,~] = ginput(1);

    disp(['Click LAST stable ' strrep(cond,'_','/') ' trial.']);
    [x2,~] = ginput(1);

    idx = nearestRange(Data.(cond).trialTimeMin,x1,x2);
    Data = storeStableRange(Data,cond,idx);

    reportStableRange(Data,cond,idx,S);

    highlightRange(axBase,Data,cond,idx,'baselineCurrent');
    highlightRange(axSigma,Data,cond,idx,'baselineSigma');
    highlightRange(axRs,Data,cond,idx,'Rs');
    highlightRange(axRin,Data,cond,idx,'Rin');
end

Data.analysisConditions = analysisConditions;

if nargin >= 5 && ~isempty(figureFolder)
    saveStabilityFigure(fig,figureFolder);
end

end

function analysisConditions = getAnalysisConditions(conditions,S)

if isfield(S,'excludedAnalysisConditions')
    excluded = S.excludedAnalysisConditions;
elseif isfield(S,'drugCondition')
    excluded = {S.drugCondition};
else
    fprintf('No conditions excluded from analysis.\n');
end

mask = ~ismember(lower(string(conditions)),lower(string(excluded)));
analysisConditions = conditions(mask);

end

function saveStabilityFigure(fig,figureFolder)

if ~exist(figureFolder,'dir')
    mkdir(figureFolder);
end

figFile = fullfile(figureFolder,'Baseline Sigma Rs Rin Stable Selection.fig');
pngFile = fullfile(figureFolder,'Baseline Sigma Rs Rin Stable Selection.png');

drawnow;

if isfile(figFile)
    delete(figFile);
end

savefig(fig,figFile);
exportgraphics(fig,pngFile,'Resolution',300);

end

function vals = collectFiniteField(Data,analysisConditions,fieldName)

vals = [];

for c = 1:numel(analysisConditions)
    vals = [vals; Data.(analysisConditions{c}).(fieldName)(:)];
end

vals = vals(isfinite(vals));

end


function vals = collectTailFiniteField(Data,conditions,fieldName,nTrials)

vals = [];

for c = 1:numel(conditions)
    x = Data.(conditions{c}).(fieldName);
    startIdx = max(1,numel(x)-nTrials+1);
    tail = x(startIdx:end);
    vals = [vals; tail(:)];
end

vals = vals(isfinite(vals));

end


function ymax = paddedPositiveMax(vals)

if isempty(vals)
    ymax = 1;
else
    ymax = 1.5*max(abs(vals));
    if ~isfinite(ymax) || ymax <= 0
        ymax = 1;
    end
end

end

function idx = nearestRange(times,x1,x2)

[~,i1] = min(abs(times-x1));
[~,i2] = min(abs(times-x2));
idx = min(i1,i2):max(i1,i2);

end

function reportStableRange(Data,cond,idx,S)

nTrials = numel(idx);
firstToLastMin = Data.(cond).trialTimeMin(idx(end))-Data.(cond).trialTimeMin(idx(1));

requiredStableMin = 5;
requiredTrials = ceil(requiredStableMin*60/S.trialStartIntervalSec);

fprintf('\n%s selected: %d trials; first-to-last span %.2f min\n', ...
    strrep(cond,'_','/'),nTrials,firstToLastMin);

if nTrials < requiredTrials
    warning('%s selected range contains %d trials; target is at least %d trials for approximately %.1f min.', ...
        cond,nTrials,requiredTrials,requiredStableMin);
end

end

function Data = storeStableRange(Data,cond,idx)

Data.(cond).stableNotDelIdx = idx;
Data.(cond).stableTrialNums = Data.(cond).notDelTrialNums(idx);
Data.(cond).stableTrialNames = Data.(cond).notDelTrialNames(idx);
Data.(cond).stableTrialTimeMin = Data.(cond).trialTimeMin(idx);

if isfield(Data.(cond),'notDelOriginalIdx')
    Data.(cond).stableOriginalIdx = Data.(cond).notDelOriginalIdx(idx);
end

Data.(cond).stableMiniData = Data.(cond).notDelMiniData(:,idx);
Data.(cond).stableConcatData = Data.(cond).stableMiniData(:);
Data.(cond).stableBaselineCurrent = Data.(cond).baselineCurrent(idx);
Data.(cond).stableBaselineSigma = Data.(cond).baselineSigma(idx);
Data.(cond).stableBaselineFitR2 = Data.(cond).baselineFitR2(idx);
Data.(cond).stableTrialBaselineFits = Data.(cond).trialBaselineFits(idx);
Data.(cond).stableRs = Data.(cond).Rs(idx);
Data.(cond).stableRin = Data.(cond).Rin(idx);

if isfield(Data.(cond),'Rtotal')
    Data.(cond).stableRtotal = Data.(cond).Rtotal(idx);
end

if isfield(Data.(cond),'RsValid')
    Data.(cond).stableRsValid = Data.(cond).RsValid(idx);
end

if isfield(Data.(cond),'RinValid')
    Data.(cond).stableRinValid = Data.(cond).RinValid(idx);
end

end

function highlightRange(ax,Data,cond,idx,fieldName)

plot(ax,Data.(cond).trialTimeMin(idx),Data.(cond).(fieldName)(idx),'ko', ...
    'MarkerSize',10,'LineWidth',1.8,'HandleVisibility','off');

end
