function Data = MINIS_deleteTrials(Data, S, conditions, figureFolder, funct)
% MINI IPSC TRIAL QC
% Click any visibly bad trace to hide/exclude it, then click Done.
% This is intentionally separate from later stability selection.

for p = 1:numel(conditions)
    cond = conditions{p};

    [trialNames, trialNums] = MINIS_getTrialInfo(Data, cond, funct);

    allTrials = Data.(cond).smthdMinis;
    nTrials = size(allTrials, 2);

    if nTrials ~= numel(trialNames)
        error(['Number of miniData columns does not match the number ' ...
            'of AD0 trial fields for condition %s.'], cond);
    end

    fig = figure('Name', cond, 'NumberTitle','off', 'Color','w', ...
        'Position',[200 100 1300 750]);
    fig.WindowState = 'normal';   % make sure it isn't minimized
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

 % Pause function until user clicks Done
doneButton = uicontrol(fig,'Style','pushbutton','String','Done','Position',[20 20 100 30],'Callback',@(src,~) uiresume(ancestor(src,'figure')));
fig.CloseRequestFcn = @(src,~) uiresume(src);

uiwait(fig);

% Determine which traces are still visible
keepIdx = arrayfun(@(h) strcmp(h.Visible,'on'),lineHandles);
visibleIdx = find(keepIdx);
excludedIdx = find(~keepIdx);

Data.(cond).notDelTrialNames = trialNames(visibleIdx);
Data.(cond).notDelTrialNums = trialNums(visibleIdx);
Data.(cond).notDelOriginalIdx = visibleIdx;
Data.(cond).notDelMiniData = allTrials(:,visibleIdx);

finalStruct = struct();
for k = 1:numel(visibleIdx)
    idx = visibleIdx(k);
    finalStruct.(trialNames{idx}) = allTrials(:,idx);
end

Data.(cond).notDelMiniTrials = finalStruct;
Data.(cond).excludedTrialNames = trialNames(excludedIdx);
Data.(cond).excludedTrialNums = trialNums(excludedIdx);

% Remove interactive components before saving
delete(doneButton);

for k = 1:numel(lineHandles)
    lineHandles(k).ButtonDownFcn = [];
end

drawnow;

% Save figure
baseName = fullfile(figureFolder,sprintf('%s all Trials QC',cond));
savefig(fig,fullfile(figureFolder,sprintf('%s all Trials QC.fig',cond)));
saveas(fig,fullfile(figureFolder,sprintf('%s all Trials QC.png',cond)));

close(fig);

    %close(fig);
    drawnow;
end
end
