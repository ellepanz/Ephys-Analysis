function finalizeCurrentFigure(Hzs, lineHandles, pharm, allData, fig)
    Data = evalin('base', 'Data');  % Pull Data from base workspace

    for j = 1:length(Hzs)
        Hz = Hzs{j};
        keepIdx = arrayfun(@(h) strcmp(h.Visible, 'on'), lineHandles{j});

        traces = allData{j};  % 14000 x N matrix
        trialNames = Data.(pharm).(Hz).ADNames;  % e.g. {'AD0_99', 'AD0_104'}

        finalStruct = struct();  % initialize empty structure

        % Find indices of visible traces
        visibleIdx = find(keepIdx);

        for k = 1:length(visibleIdx)
            idx = visibleIdx(k);
            thisName = trialNames{idx};
            finalStruct.(thisName) = traces(:, idx);  % Assign vector to field
        end

        % Assign the struct with named traces
        Data.(pharm).(Hz).finalallTrials = finalStruct;
    end

    assignin('base', 'Data', Data);  % Push updated Data back to base workspace
    close(fig);  % Close the GUI
end
