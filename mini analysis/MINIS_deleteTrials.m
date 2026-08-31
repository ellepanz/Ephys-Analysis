function Data = MINIS_deleteTrials(Data,S,conditions,figureFolder,funct)
% MINI-IPSC trace QC. Click visibly bad traces to hide/exclude them, then Done.

if ~exist(figureFolder,'dir')
    mkdir(figureFolder);
end

for p = 1:numel(conditions)
    cond = conditions{p};

    [trialNames,trialNums] = MINIS_getTrialInfo(Data,cond,funct);
    allTrials = Data.(cond).smthdMinis;
    nTrials = size(allTrials,2);

    if nTrials ~= numel(trialNames)
        error('Number of miniData columns does not match AD0 trial fields for condition %s.',cond);
    end

    if nTrials == 0
        error('No trials found for condition %s.',cond);
    end

    fig = figure('Name',cond,'NumberTitle','off','Color','w','Position',[200 100 1300 750]);
    fig.WindowState = 'normal';
    ax = axes(fig);
    hold(ax,'on');

    time = (0:size(allTrials,1)-1)/S.Fs;
    lineHandles = gobjects(nTrials,1);

    boneMap = flipud(bone(nTrials));
    boneMap(boneMap == 1) = 0.9;

    for trialIdx = 1:nTrials
        h = plot(ax,time,allTrials(:,trialIdx),'Color',boneMap(trialIdx,:), ...
            'DisplayName',trialNames{trialIdx},'LineWidth',0.75);
        h.ButtonDownFcn = @(src,~) set(src,'Visible','off');
        lineHandles(trialIdx) = h;
    end

    title(ax,strrep(cond,'_','/'),'Interpreter','none');
    xlabel(ax,'Time (s)');
    ylabel(ax,'Current (pA)');
    xlim(ax,[0 time(end)]);
    legend(ax,'Interpreter','none','Location','bestoutside');
    box(ax,'off');

    doneButton = uicontrol(fig,'Style','pushbutton','String','Done','Position',[20 20 100 30], ...
        'Callback',@(src,~) uiresume(ancestor(src,'figure')));
    fig.CloseRequestFcn = @(src,~) uiresume(src);

    uiwait(fig);

    if ~isgraphics(fig)
        error('Trial-QC figure was unexpectedly destroyed.');
    end

    keepIdx = arrayfun(@(h) strcmp(h.Visible,'on'),lineHandles);
    visibleIdx = find(keepIdx);
    excludedIdx = find(~keepIdx);

    Data.(cond).notDelTrialNames = trialNames(visibleIdx);
    Data.(cond).notDelTrialNums = trialNums(visibleIdx);
    Data.(cond).notDelOriginalIdx = visibleIdx;
    Data.(cond).notDelMiniData = allTrials(:,visibleIdx);

    finalStruct = struct;
    for k = 1:numel(visibleIdx)
        idx = visibleIdx(k);
        finalStruct.(trialNames{idx}) = allTrials(:,idx);
    end

    Data.(cond).notDelMiniTrials = finalStruct;
    Data.(cond).excludedTrialNames = trialNames(excludedIdx);
    Data.(cond).excludedTrialNums = trialNums(excludedIdx);

    delete(doneButton);

    for k = 1:numel(lineHandles)
        lineHandles(k).ButtonDownFcn = [];
    end

    fig.CloseRequestFcn = 'closereq';
    drawnow;

    savefig(fig,fullfile(figureFolder,sprintf('%s all Trials QC.fig',cond)));
    exportgraphics(fig,fullfile(figureFolder,sprintf('%s all Trials QC.png',cond)),'Resolution',300);

    close(fig);
    drawnow;
end

end
