function Data = MINIS_QCTestPulses(Data,S,conditions,figureFolder)
% Visually inspect test pulses from trials that passed MINI trace QC.
%
% State 1: GOOD       -> use for Rs and Rin
% State 2: BAD Rin    -> use for Rs, exclude from Rin
% State 3: BAD Rs/Rin -> exclude from both
%
% These flags affect resistance calculations only; they do not remove minis.

if ~exist(figureFolder,'dir')
    mkdir(figureFolder);
end

prePulseSec = 0.2;
prePulseSamples = round(prePulseSec*S.Fs);

for c = 1:numel(conditions)
    cond = conditions{c};

    trialNames = Data.(cond).notDelTrialNames(:)';
    nTrials = numel(trialNames);

    if nTrials == 0
        error('No trials remain after MINI QC for condition %s.',cond);
    end

    trialNums = cellfun(@(x) sscanf(x,'AD0_%d'),trialNames);

    for k = 1:nTrials
        if ~isfield(Data.rawTraces.(cond),trialNames{k})
            error('Raw trace %s is missing from Data.rawTraces.%s.',trialNames{k},cond);
        end
    end

    state = ones(1,nTrials);

    if isfield(Data.(cond),'RsValid') && isfield(Data.(cond),'RinValid') && ...
            numel(Data.(cond).RsValid) == nTrials && numel(Data.(cond).RinValid) == nTrials

        oldRsValid = Data.(cond).RsValid;
        oldRinValid = Data.(cond).RinValid;

        for k = 1:nTrials
            if ~oldRsValid(k)
                state(k) = 3;
            elseif ~oldRinValid(k)
                state(k) = 2;
            end
        end
    end

    fig = figure('Name',[strrep(cond,'_','/') ' Test Pulse QC'],'NumberTitle','off', ...
        'Color','w','Position',[100 50 1500 850]);

    tl = tiledlayout(fig,'TileSpacing','compact','Padding','compact');
    title(tl,[strrep(cond,'_','/') ' Test Pulses'],'Interpreter','none');

    lineHandles = gobjects(1,nTrials);
    axHandles = gobjects(1,nTrials);

    for k = 1:nTrials
        rawTrace = Data.rawTraces.(cond).(trialNames{k});
        startIdx = max(1,S.sealStartIdx-prePulseSamples);
        endIdx = numel(rawTrace);

        pulseTrace = rawTrace(startIdx:endIdx);
        sampleIdx = startIdx:endIdx;
        timeMs = (sampleIdx-S.sealStartIdx)/S.Fs*1000;

        ax = nexttile(tl);
        hold(ax,'on');

        h = plot(ax,timeMs,pulseTrace,'LineWidth',0.75);
        onsetLine = xline(ax,0,'--');
        onsetLine.HitTest = 'off';

        xlabel(ax,'Time from pulse onset (ms)');
        ylabel(ax,'Current (pA)');
        box(ax,'off');

        h.ButtonDownFcn = @(src,event) cyclePulseState(src,event,k);
        ax.ButtonDownFcn = @(src,event) cyclePulseState(src,event,k);
        h.PickableParts = 'all';
        h.HitTest = 'on';

        lineHandles(k) = h;
        axHandles(k) = ax;
    end

    fig.UserData.state = state;
    fig.UserData.lineHandles = lineHandles;
    fig.UserData.axHandles = axHandles;
    fig.UserData.trialNames = trialNames;

    for k = 1:nTrials
        updatePulseDisplay(fig,k);
    end

    annotation(fig,'textbox',[0.01 0.01 0.75 0.04], ...
        'String','Click a tile to cycle: GOOD -> BAD Rin -> BAD Rs/Rin -> GOOD', ...
        'EdgeColor','none','FontSize',11);

    doneButton = uicontrol(fig,'Style','pushbutton','String','Done','Position',[20 45 100 30], ...
        'Callback',@(src,~) uiresume(ancestor(src,'figure')));
    fig.CloseRequestFcn = @(src,~) uiresume(src);

    drawnow;
    uiwait(fig);

    if ~isgraphics(fig)
        error('Test-pulse QC figure was unexpectedly destroyed.');
    end

    state = fig.UserData.state;
    RsValid = state ~= 3;
    RinValid = state == 1;

    Data.(cond).resistanceQCTrialNames = trialNames;
    Data.(cond).resistanceQCTrialNums = trialNums;
    Data.(cond).RsValid = RsValid;
    Data.(cond).RinValid = RinValid;
    Data.(cond).badRsTrialNames = trialNames(~RsValid);
    Data.(cond).badRinTrialNames = trialNames(~RinValid);
    Data.(cond).badRsTrialNums = trialNums(~RsValid);
    Data.(cond).badRinTrialNums = trialNums(~RinValid);

    Data.(cond).resistanceQC = table(trialNums(:),trialNames(:),RsValid(:),RinValid(:), ...
        'VariableNames',{'TrialNum','TrialName','RsValid','RinValid'});

    delete(doneButton);

    for k = 1:nTrials
        lineHandles(k).ButtonDownFcn = [];
        axHandles(k).ButtonDownFcn = [];
    end

    fig.CloseRequestFcn = 'closereq';

    savefig(fig,fullfile(figureFolder,[cond ' Test Pulse QC.fig']));
    exportgraphics(fig,fullfile(figureFolder,[cond ' Test Pulse QC.png']),'Resolution',300);

    close(fig);
    drawnow;
end

end

function cyclePulseState(src,~,trialIdx)

fig = ancestor(src,'figure');
state = fig.UserData.state;
state(trialIdx) = mod(state(trialIdx),3) + 1;
fig.UserData.state = state;
updatePulseDisplay(fig,trialIdx);

end

function updatePulseDisplay(fig,trialIdx)

state = fig.UserData.state;
h = fig.UserData.lineHandles(trialIdx);
ax = fig.UserData.axHandles(trialIdx);
trialName = fig.UserData.trialNames{trialIdx};

switch state(trialIdx)
    case 1
        status = 'GOOD';
        h.LineStyle = '-';
        h.LineWidth = 0.75;

    case 2
        status = 'BAD Rin';
        h.LineStyle = '--';
        h.LineWidth = 1.5;

    case 3
        status = 'BAD Rs/Rin';
        h.LineStyle = ':';
        h.LineWidth = 2;
end

title(ax,sprintf('%s | %s',trialName,status),'Interpreter','none');

end
