function Data = MINIS_selectStableTrials(Data,S,conditions,color,figureFolder)
% MINIS_selectStableTrials
%
% Plot trial-by-trial recording stability over experimental time and
% manually select stable ranges for every condition except NMDA.
%
% Uses trials remaining after trace QC:
%   Data.(cond).notDelTrialNames
%   Data.(cond).notDelTrialNums
%   Data.(cond).notDelMiniData
%
% Displays:
%   1) Gaussian baseline current (mu)
%   2) Gaussian sigma
%   3) Series resistance (Rs)
%   4) Input resistance (Rin)
%
% The unselected stability figure is saved immediately after it is
% generated. If stable ranges are selected successfully, the same files
% are overwritten with the highlighted final version.
%
% Holding-current y-limits are determined from all non-NMDA conditions so
% the acute NMDA current does not compress the stability view.
%
% Test-pulse QC affects Rs/Rin only. A NaN Rs or Rin does NOT remove that
% trial from the mini-IPSC analysis.

%% CHECK REQUIRED DATA

for c = 1:numel(conditions)
    cond = conditions{c};
    requiredFields = {'notDelTrialNames','notDelTrialNums','notDelMiniData','baselineCurrent','baselineSigma','baselineFitR2','trialBaselineFits','Rs','Rin'};

    for f = 1:numel(requiredFields)
        if ~isfield(Data.(cond),requiredFields{f})
            error('Data.%s.%s does not exist.',cond,requiredFields{f});
        end
    end
end

%% CONDITIONS ELIGIBLE FOR STABLE-RANGE SELECTION

selectableConditions = conditions(~strcmpi(conditions,'NMDA'));

if isempty(selectableConditions)
    error('No selectable conditions were found. Stable ranges are selected for every condition except NMDA.');
end

%% FIND START OF EXPERIMENT

allTrialNums = [];

for c = 1:numel(conditions)
    cond = conditions{c};
    [~,rawTrialNums] = MINIS_getTrialInfo(Data,cond,'raw');
    allTrialNums = [allTrialNums rawTrialNums(:)'];
end

firstTrialNum = min(allTrialNums);

%% CALCULATE EXPERIMENTAL TIME

conditionStartTimes = nan(1,numel(conditions));

for c = 1:numel(conditions)
    cond = conditions{c};
    trialNums = Data.(cond).notDelTrialNums;

    trialTimeMin = ((trialNums-firstTrialNum)*S.trialStartIntervalSec)/60;
    Data.(cond).trialTimeMin = trialTimeMin;

    [~,rawTrialNums] = MINIS_getTrialInfo(Data,cond,'raw');
    firstCondTrial = min(rawTrialNums);
    conditionStartTimes(c) = ((firstCondTrial-firstTrialNum)*S.trialStartIntervalSec)/60;
end

%% CREATE STABILITY FIGURE

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

%% PLOT ALL CONDITIONS

for c = 1:numel(conditions)
    cond = conditions{c};
    tm = Data.(cond).trialTimeMin;

    plot(axBase,tm,Data.(cond).baselineCurrent,'-o','Color',color{c},'MarkerFaceColor',color{c},'LineWidth',1.2,'DisplayName',strrep(cond,'_','/'));
    plot(axSigma,tm,Data.(cond).baselineSigma,'-o','Color',color{c},'MarkerFaceColor',color{c},'LineWidth',1.2,'HandleVisibility','off');
    plot(axRs,tm,Data.(cond).Rs,'-o','Color',color{c},'MarkerFaceColor',color{c},'LineWidth',1.2,'HandleVisibility','off');
    plot(axRin,tm,Data.(cond).Rin,'-o','Color',color{c},'MarkerFaceColor',color{c},'LineWidth',1.2,'HandleVisibility','off');
end

%% SET Y-LIMITS AFTER ALL CONDITIONS ARE PLOTTED

holdingForLimits = collectFiniteField(Data,selectableConditions,'baselineCurrent');

if isempty(holdingForLimits)
    ylim(axBase,[-1 0]);
else
    maxAbsHolding = max(abs(holdingForLimits));
    if maxAbsHolding == 0
        maxAbsHolding = 1;
    end
    ylim(axBase,[-1.5*maxAbsHolding 0]);
end

allSigma = collectFiniteField(Data,conditions,'baselineSigma');
allRs = collectFiniteField(Data,conditions,'Rs');
allRin = collectFiniteField(Data,conditions,'Rin');

ylim(axSigma,[0 paddedPositiveMax(allSigma)]);
ylim(axRs,[0 paddedPositiveMax(allRs)]);
ylim(axRin,[0 paddedPositiveMax(allRin)]);

%% DRAW CONDITION BOUNDARIES

axs = [axBase axSigma axRs axRin];

for c = 2:numel(conditions)
    for a = 1:numel(axs)
        xline(axs(a),conditionStartTimes(c),'--','LineWidth',1.2,'Color',[0.4 0.4 0.4],'HandleVisibility','off');
    end
end

%% FORMAT FIGURE

title(t,'Mini-IPSC Trial Stability / QC');
ylabel(axBase,'Gaussian baseline \mu (pA)');
ylabel(axSigma,'Gaussian \sigma (pA)');
ylabel(axRs,'R_s (M\Omega)');
ylabel(axRin,'R_{in} (M\Omega)');
xlabel(axRin,'Experimental time (min)');
legend(axBase,'Location','bestoutside');
linkaxes(axs,'x');
set(axs,'Box','off');

%% SAVE INITIAL QC FIGURE BEFORE USER SELECTION

if nargin >= 5 && ~isempty(figureFolder)
    saveStabilityFigure(fig,figureFolder);
end

%% SELECT STABLE RANGE FOR EVERY NON-NMDA CONDITION

for c = 1:numel(selectableConditions)
    cond = selectableConditions{c};

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

%% OVERWRITE WITH FINAL SELECTED-RANGE FIGURE

if nargin >= 5 && ~isempty(figureFolder)
    saveStabilityFigure(fig,figureFolder);
end

end


%% SAVE STABILITY FIGURE

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


%% COLLECT FINITE VALUES FOR ONE FIELD ACROSS CONDITIONS

function vals = collectFiniteField(Data,conditions,fieldName)

vals = [];

for c = 1:numel(conditions)
    cond = conditions{c};
    vals = [vals; Data.(cond).(fieldName)(:)];
end

vals = vals(isfinite(vals));

end


%% RETURN PADDED POSITIVE Y-MAX

function ymax = paddedPositiveMax(vals)

if isempty(vals)
    ymax = 1;
    return
end

ymax = 1.5*max(abs(vals));

if ~isfinite(ymax) || ymax <= 0
    ymax = 1;
end

end


%% FIND NEAREST SELECTED RANGE

function idx = nearestRange(times,x1,x2)

[~,i1] = min(abs(times-x1));
[~,i2] = min(abs(times-x2));
idx = min(i1,i2):max(i1,i2);

end


%% REPORT SELECTED RANGE

function reportStableRange(Data,cond,idx,S)

nTrials = numel(idx);
firstToLastMin = Data.(cond).trialTimeMin(idx(end))-Data.(cond).trialTimeMin(idx(1));

requiredStableMin = 5;
requiredTrials = ceil(requiredStableMin*60/S.trialStartIntervalSec);

fprintf('\n%s selected: %d trials; first-to-last span %.2f min\n',strrep(cond,'_','/'),nTrials,firstToLastMin);

if nTrials < requiredTrials
    warning('%s selected range contains %d trials; at least %d trials are needed for approximately %.1f min of stable trial-start intervals.',cond,nTrials,requiredTrials,requiredStableMin);
end

end


%% STORE STABLE TRIAL RANGE

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


%% HIGHLIGHT STABLE RANGE

function highlightRange(ax,Data,cond,idx,fieldName)

plot(ax,Data.(cond).trialTimeMin(idx),Data.(cond).(fieldName)(idx),'ko','MarkerSize',10,'LineWidth',1.8,'HandleVisibility','off');

end
