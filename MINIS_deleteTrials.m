function Data = MINIS_deleteTrials(Data, Fs, conditions, figureFolder)

%% MINI IPSC TRIAL QC
% Click any bad trace to hide it.
% Click Done to save only the visible trials.

for p = 1:length(conditions)

    cond = conditions{p};

    %% Get trial names and sort chronologically
    fields = fieldnames(Data.(cond));

    isTrial = ~cellfun('isempty', ...
        regexp(fields, '^AD0_\d+$', 'once'));

    trialNames = fields(isTrial);

    trialNums = cellfun(@(x) sscanf(x, 'AD0_%d'), trialNames);

    [trialNums, order] = sort(trialNums);
    trialNames = trialNames(order);


    %% Pull mini data
    allTrials = Data.(cond).miniData;
    nTrials = size(allTrials, 2);

    if nTrials ~= numel(trialNames)
        error(['Number of miniData columns does not match the number ' ...
               'of AD0 trial fields for condition %s.'], cond);
    end


    %% Create figure
    fig = figure( ...
        'Name', cond, ...
        'NumberTitle', 'off', ...
        'Color', 'w', ...
        'Position', [200 100 1300 750]);

    ax = axes(fig);
    hold(ax, 'on');


    %% Time axis
    nSamples = size(allTrials, 1);
    time = (0:nSamples-1) / Fs;


    %% Plot trials
    lineHandles = gobjects(nTrials, 1);

    boneMap = flipud(bone(nTrials));
    boneMap(boneMap == 1) = 0.9;

    for trialIdx = 1:nTrials

        h = plot(ax, ...
            time, ...
            allTrials(:, trialIdx), ...
            'Color', boneMap(trialIdx,:), ...
            'DisplayName', trialNames{trialIdx}, ...
            'LineWidth', 0.75);

        % Click trace to hide/exclude it
        h.ButtonDownFcn = @(src, ~) set(src, 'Visible', 'off');

        lineHandles(trialIdx) = h;
    end


    %% Formatting
    title(ax, strrep(cond, '_', '/'), ...
        'Interpreter', 'none');

    xlabel(ax, 'Time (s)');
    ylabel(ax, 'Current (pA)');

    xlim(ax, [0 time(end)]);

    legend(ax, ...
        'Interpreter', 'none', ...
        'Location', 'bestoutside');

    box(ax, 'off');

%% Done button
% Flag indicating that selection is not finished yet
fig.UserData = false;

uicontrol(fig, ...
    'Style', 'pushbutton', ...
    'String', 'Done', ...
    'Position', [20 20 100 30], ...
    'Callback', @(~,~) set(fig, 'UserData', true));

% Make sure figure is completely rendered
drawnow;

% Wait here until Done changes UserData to true
waitfor(fig, 'UserData', true);

    %% Determine which traces remain visible
    keepIdx = arrayfun(@(h) ...
        strcmp(h.Visible, 'on'), lineHandles);

    visibleIdx = find(keepIdx);
    excludedIdx = find(~keepIdx);


    %% Store QC-passed trials
    Data.(cond).QCTrialNames = ...
        trialNames(visibleIdx);

    Data.(cond).QCTrialNums = ...
        trialNums(visibleIdx);

    Data.(cond).finalMiniData = ...
        allTrials(:, visibleIdx);


    %% Store QC-passed trials as named fields
    finalStruct = struct();

    for k = 1:length(visibleIdx)

        idx = visibleIdx(k);
        thisName = trialNames{idx};

        finalStruct.(thisName) = ...
            allTrials(:, idx);

    end

    Data.(cond).finalMiniTrials = finalStruct;


    %% Store excluded trials
    Data.(cond).excludedTrialNames = ...
        trialNames(excludedIdx);

    Data.(cond).excludedTrialNums = ...
        trialNums(excludedIdx);


    %% Close and move to next condition
    saveas(gcf, sprintf('%s/%s%s', figureFolder, cond, ' all Trials'))
    close(fig);

end

end