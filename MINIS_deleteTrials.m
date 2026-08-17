function Data = MINIS_deleteTrials(Data, S, conditions, figureFolder)
% MINI IPSC TRIAL QC
% Click any visibly bad trace to hide/exclude it, then click Done.
% This is intentionally separate from later stability selection.

for p = 1:numel(conditions)
    cond = conditions{p};

    [trialNames, trialNums] = MINIS_getTrialInfo(Data, cond);

    allTrials = Data.(cond).miniData;
    nTrials = size(allTrials, 2);

    if nTrials ~= numel(trialNames)
        error(['Number of miniData columns does not match the number ' ...
               'of AD0 trial fields for condition %s.'], cond);
    end

    fig = figure('Name', cond, 'NumberTitle','off', 'Color','w', ...
        'Position',[200 100 1300 750]);
    ax = axes(fig);
    hold(ax,'on');

    time = (0:size(allTrials,1)-1) / S.Fs;
    lineHandles = gobjects(nTrials,1);

    boneMap = flipud(bone(nTrials));
    boneMap(boneMap == 1) = 0.9;

    for trialIdx = 1:nTrials
        h = plot(ax, time, allTrials(:,trialIdx), ...
            'Color',boneMap(trialIdx,:), ...
            'DisplayName',trialNames{trialIdx}, ...
            'LineWidth',0.75);
        h.ButtonDownFcn = @(src,~) set(src,'Visible','off');
        lineHandles(trialIdx) = h;
    end

    title(ax, strrep(cond,'_','/'), 'Interpreter','none');
    xlabel(ax,'Time (s)');
    ylabel(ax,'Current (pA)');
    xlim(ax,[0 time(end)]);
    legend(ax,'Interpreter','none','Location','bestoutside');
    box(ax,'off');

    % Done button changes a figure flag. No nested callback is needed.
    fig.UserData = false;
    fig.CloseRequestFcn = @(src,~) set(src,'UserData',true);
    uicontrol(fig, 'Style','pushbutton', 'String','Done', ...
        'Position',[20 20 100 30], ...
        'Callback',@(src,~) set(ancestor(src,'figure'),'UserData',true));

    drawnow;
    waitfor(fig, 'UserData', true);

    if ~isgraphics(fig)
        error('QC figure was unexpectedly destroyed.');
    end

    keepIdx = arrayfun(@(h) strcmp(h.Visible,'on'), lineHandles);
    visibleIdx = find(keepIdx);
    excludedIdx = find(~keepIdx);

    Data.(cond).QCTrialNames = trialNames(visibleIdx);
    Data.(cond).QCTrialNums = trialNums(visibleIdx);
    Data.(cond).QCOriginalIdx = visibleIdx;
    Data.(cond).finalMiniData = allTrials(:,visibleIdx);

    finalStruct = struct();
    for k = 1:numel(visibleIdx)
        idx = visibleIdx(k);
        finalStruct.(trialNames{idx}) = allTrials(:,idx);
    end
    Data.(cond).finalMiniTrials = finalStruct;

    Data.(cond).excludedTrialNames = trialNames(excludedIdx);
    Data.(cond).excludedTrialNums = trialNums(excludedIdx);

    MINIS_saveFigure(fig, figureFolder, [cond ' all Trials QC']);
    set(fig,'CloseRequestFcn','closereq');
    close(fig);
    drawnow;
end
end
