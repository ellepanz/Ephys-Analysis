function selectedIdx = selectPharmsWithCheckbox(pharmSave)
    % Append 'All' to the end of the list
    options = [pharmSave(:)];  

    % Create checkbox list dialog
    [selection, ok] = listdlg( ...
        'PromptString', 'Select condition(s) to display:', ...
        'SelectionMode', 'multiple', ...
        'ListString', options, ...
        'Name', 'Select Conditions', ...
        'ListSize', [300 200]);

    if ~ok
        % User hit cancel
        return;
    end

    % If 'All' was selected (last item), return all indices except 'All'
    if any(selection == numel(options))
        selectedIdx = 1:numel(pharmSave);  % all conditions
    else
        selectedIdx = selection;
        assignin('base','selectedIdx',selectedIdx)
    end
end
