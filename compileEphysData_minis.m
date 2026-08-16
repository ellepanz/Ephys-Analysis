function [Expt, Data] = compileEphysData_minis(epochs, folder, conditions, Expt, figureFolder)
% called by MINIS_analysis to build the Data variable and the metadata image
Data = struct;

for j = 1:length(epochs)
    epoch = epochs{j};
    cond = conditions{j};

    % Find all ITX files matching the current epoch
    FileNames = dir(fullfile(folder, ['*' epoch '*.itx']));

    for k = 1:numel(FileNames)
        avgdName = FileNames(k).name;
        fullPath = fullfile(folder, avgdName);

        % Read data and store it
        data = readITXwaves(fullPath);
        Data.(cond) = data;
    end
end


%% Separate seal tests and mini trial data
 
Fs = 10000;              % Sampling rate (Hz)
sealStart = 19.9;         % Seal test starts at 19.9 sec
sealDuration = 0.030;     % 30 ms

sealStartIdx = sealStart * Fs + 1;      % 199001
sealEndIdx = sealStartIdx + sealDuration * Fs - 1;  % 199300

for j = 4:length(conditions)
    cond = conditions{j};

    % Get all fields in this condition
    fields = fieldnames(Data.(cond));

    % Keep only individual trials: AD0_29, AD0_30, etc. not AD0_avg
    isTrial = ~cellfun('isempty', regexp(fields, '^AD0_\d+$', 'once'));
    trialNames = fields(isTrial);

        % Sort trials by their numeric trial number
    trialNums = cellfun(@(x) sscanf(x, 'AD0_%d'), trialNames);
    [~, order] = sort(trialNums);
    trialNames = trialNames(order);

    % Preallocate
    nTrials = length(trialNames);
    Data.(cond).sealTests = nan(sealDuration * Fs, nTrials);
    Data.(cond).miniData = nan(sealStartIdx-1, nTrials);

    for k = 1:nTrials
        trace = Data.(cond).(trialNames{k});

        Data.(cond).sealTests(:,k) = trace(sealStartIdx:sealEndIdx);
        Data.(cond).miniData(:, k) = trace(1:sealStartIdx-1);
    end
end

% --- CONCATENATE TRIAL DATA
% Use data before seal test
dataEndIdx = sealStart*Fs;   % 199000

for j = 4:length(conditions)
    cond = conditions{j};

    % Get all fields in this condition
    fields = fieldnames(Data.(cond));

    % Keep only individual trials not averages
    isTrial = ~cellfun('isempty', regexp(fields, '^AD0_\d+$', 'once'));
    trialNames = fields(isTrial);

            % Sort trials by their numeric trial number
    trialNums = cellfun(@(x) sscanf(x, 'AD0_%d'), trialNames);
    [~, order] = sort(trialNums);
    trialNames = trialNames(order);

    % Preallocate concatenated vector
    nTrials = length(trialNames);
    Data.(cond).concatData = nan(dataEndIdx * nTrials, 1);

    for k = 1:nTrials
        trace = Data.(cond).(trialNames{k});

        idx = (k-1)*dataEndIdx + (1:dataEndIdx);

        Data.(cond).concatData(idx) = trace(1:dataEndIdx);
    end
end

%% Generate metadata image for printing
metadataText = sprintf([ ...
    'Experiment: %s\n' ...
    'Date: %s\n' ...
    'Starting Condition: %s\n' ...
    'Drug Condition: %s\n' ...
    'Internal: %s\n' ...
    'Holding potential: %s\n' ...
    'Temperature: %s\n' ...
    'Ca2+:Mg2+ : %s\n' ...
    'Trial Interval: %d\n' ...
    'Genotype: %s\n' ...
    'Mouse Age: %s\n' ...
    'Cell Type: %s\n' ...
    'Brain Region: %s\n'...
    'Folder: %s\n'], ...
    Expt.marker, Expt.date, ...
    Expt.startingCond, Expt.drugCond, ... 
    Expt.temp, Expt.CaMg, Expt.trialInterval, Expt.genotype, Expt.age, Expt.cellType, Expt.region, folder);

fig = figure('Color','w','Position',[100 100 550 600], 'visible','off');

annotation('textbox',[0.05 0.05 0.9 0.9], ...
    'String', metadataText, ...
    'FontName','Consolas', ...  % nice monospaced lab vibe
    'FontSize',14, ...
    'Interpreter','none', ...
    'EdgeColor','none');

exportgraphics(fig, sprintf('%s/Experiment_Metadata.png', figureFolder), 'Resolution', 300);

 