function [Expt, Data] = compileEphysData_minis( ...
    epochs, folder, conditions, Expt, figureFolder, S)

% COMPILEEPHYSDATA_MINIS
%
% Loads miniature-current ITX files and organizes individual trials for
% downstream MINI-IPSC analysis.
%

% Acquisition timing is taken from S rather than hard-coded here.

%% =========================================================
% LOAD ITX DATA
% ==========================================================

Data = struct();

for j = 1:numel(epochs)
    epoch = epochs{j};
    cond = conditions{j};

    % Find ITX files matching this epoch
    FileNames = dir(fullfile(folder, ['*' epoch '*.itx']));

    % Read each matching ITX file
    for k = 1:numel(FileNames)

        fullPath = fullfile(folder, FileNames(k).name);
        loadedData = readITXwaves(fullPath);

        loadedFields = fieldnames(loadedData);

        % Copy each wave into condition structure
        for f = 1:numel(loadedFields)

            fieldName = loadedFields{f};
            Data.rawTraces.(cond).(fieldName) = loadedData.(fieldName);
        end
    end
end


%% =========================================================
% SEPARATE MINI DATA AND TEST PULSES
% ==========================================================

for j = 1:numel(conditions)
    cond = conditions{j};

    %% Find and sort individual AD0 trials

    fields = fieldnames(Data.rawTraces.(cond));

    isTrial = ~cellfun('isempty', ...
        regexp(fields, '^AD0_\d+$', 'once'));

    trialNames = fields(isTrial);

    if isempty(trialNames)
        error('No individual AD0_## trials found for %s.', cond);
    end

    trialNums = cellfun(@(x) ...
       sscanf(x, 'AD0_%d'), trialNames);

    [trialNums, order] = sort(trialNums);
    trialNames = trialNames(order);

    % Keep everything consistently as row vectors
    trialNums = trialNums(:)';
    trialNames = trialNames(:)';

    nTrials = numel(trialNames);


    %% Preallocate
    Data.(cond).smthdFullTrace = nan(S.recordingLength*S.Fs, nTrials);

    %% Separate each raw trace
    for k = 1:nTrials

        fullTrace = Data.rawTraces.(cond).(trialNames{k});
             
         % Save the individual raw trial using its original AD0_## name
        Data.(cond).(trialNames{k}) = fullTrace;

        % Apply Savitsky-Golay filter w/ parameters set in variable S
        smthdTrace = sgolayfilt(fullTrace, S.sgOrder, S.sgFrame);

        % 
        Data.(cond).smthdFullTrace(:,k) = smthdTrace; % pulls just the 199000 that are before the test pulse
        Data.(cond).smthdMinis(:, k) = smthdTrace(1:S.miniSamples);

        % Test pulse
        Data.(cond).testPulse(:,k) = smthdTrace(S.sealStartIdx:S.sealEndIdx);
    end

    %% Concatenate all mini-current recordings
    % MATLAB stacks columns sequentially:
    % trial 1 -> trial 2 -> trial 3 -> ...
    % Data.(cond).concatData = Data.(cond).smthdMinis(:);

    %% Save trial identity/order
    Data.(cond).trialNames = trialNames;
    Data.(cond).trialNums = trialNums;
end


%% =========================================================
% GENERATE METADATA IMAGE
% ==========================================================

metadataText = sprintf([ ...
    'Experiment: %s\n' ...
    'Date: %s\n' ...
    'Starting Condition: %s\n' ...
    'Drug Condition: %s\n' ...
    'Internal: %s\n' ...
    'Holding potential: %s\n' ...
    'Temperature: %s\n' ...
    'Ca2+/Mg2+: %s\n' ...
    'Genotype: %s\n' ...
    'Mouse Age: %s\n' ...
    'Cell Type: %s\n' ...
    'Brain Region: %s\n' ...
    'Folder: %s\n'], ...
    Expt.marker, ...
    Expt.date, ...
    Expt.startingCond, ...
    Expt.drugCond, ...
    Expt.internal, ...
    Expt.Vh, ...
    Expt.temp, ...
    Expt.CaMg, ...
    Expt.genotype, ...
    Expt.age, ...
    Expt.cellType, ...
    Expt.region, ...
    folder);

fig = figure('Color','w', 'Position',[100 100 600 650], 'Visible','off');
    
annotation(fig, ...
    'textbox', [0.05 0.05 0.9 0.9], ...
    'String', metadataText, ...
    'FontName','Consolas', ...
    'FontSize',14, ...
    'Interpreter','none', ...
    'EdgeColor','none');

exportgraphics(fig, ...
    fullfile(figureFolder, 'Experiment_Metadata.png'), 'Resolution',300);

close(fig);

end