function [Expt, Data] = compileEphysData_PPR(epochs, folder, conditions, Hzs, Expt, figureFolder)
% called by EPSC_PPRanalysis to actually build the Data variable and the
% metadata image
Data = struct;

for j = 1:length(epochs)
    epoch = epochs{j};
    cond = conditions{j};

    % Find all ITX files matching the current epoch
    FileNames = dir(fullfile(folder, ['*' epoch '*.itx']));

    for k = 1:numel(FileNames)
        avgdName = FileNames(k).name;
        fullPath = fullfile(folder, avgdName);

        % Extract position from filename: look for "p1", "p2", etc.
        posMatch = regexp(avgdName, 'p(\d)', 'tokens');
        posNum = str2double(posMatch{1}{1});  % Convert '1' to 1
        if posNum < 1 || posNum > numel(Hzs)
            warning('Position %d out of range in file: %s', posNum, avgdName);
            continue;
        end

        Hz = Hzs{posNum};  % Map position to Hz label

        % Read data and store it
        data = readITXwaves(fullPath);
        Data.(cond).(Hz) = data;
    end
end

%% pull individual trials into an alltrials matrix + baseline subtract

% Loop over all cond and Hz combinations
for p = 1:length(conditions)
    cond = conditions{p};
    for h = 1:length(Hzs)
        Hz = Hzs{h};
        Data.(cond).(Hz).allTrials = struct();

        % Get the struct that contains the waveforms
        waveStruct = Data.(cond).(Hz);

        % Find all field names matching AD0_<number> (excluding *_avg)
        fieldNames = fieldnames(waveStruct);
        trialFields = {};

        for i = 1:numel(fieldNames)
            field = fieldNames{i};

            if ~isempty(regexp(field, '^AD0_\d+$', 'once'))
                trialFields{end+1} = field;
            end
        end

        % Sort field names by numeric index (so AD0_10 doesn't come before AD0_2)
        % trialFields = sort(trialFields);  % Optional: sort to keep order predictable
        Data.(cond).(Hz).ADNames = trialFields;
        % Convert to matrix
        nTrials = numel(trialFields);
        if nTrials > 0
            waveformLength = length(waveStruct.(trialFields{1}));
            allTrials = zeros(waveformLength, nTrials);

            for k = 1:nTrials
                allTrials(:, k) = waveStruct.(trialFields{k});
            end

            % Save to struct
            Data.(cond).(Hz).allTrials = allTrials;
        else
            warning('No AD0_x waveforms found for %s %s', cond, Hz);
        end
    end
end

%% Baseline subtract trials
for p = 1:length(conditions)
    cond = conditions{p};

    for j = 1:length(Hzs)
        Hz = Hzs{j};
        Data.(cond).(Hz).basesubTrials = [];
        for k = 1:size(Data.(cond).(Hz).allTrials,2)
            Data.(cond).(Hz).basesubTrials(:,k) = Data.(cond).(Hz).allTrials(:,k) - mean(Data.(cond).(Hz).allTrials(1:800,k));
        end
    end
end

%% Set up time ;
Cond1 = conditions{1};
Expt.timeStart = 0;
Expt.dt = 1/10000;
Expt.Trialpts = size(Data.(Cond1).x1.basesubTrials, 1);
Expt.sec= mod(Expt.timeStart + (0:Expt.Trialpts-1)*Expt.dt, 1024);% WHY DOES THIS WORK??
Expt.sec = Expt.sec';
Expt.ms = 1000*Expt.sec;

%% Generate metadata image for printing
metadataText = sprintf([ ...
    'Experiment: %s\n' ...
    'Date: %s\n' ...
    'Conditions: %s\n' ...
    'Drug Concentrations: %s\n' ...
    'Temperature: %s\n' ...
    'Ca2+:Mg2+ : %s\n' ...
    'Trial Interval: %d\n' ...
    'Stim: %s\n' ...
    'Genotype: %s\n' ...
    'Mouse Age: %s\n' ...
    'Cell Type: %s\n' ...
    'Brain Region: %s\n'...
    'Folder: %s\n'], ...
    Expt.marker, Expt.date, ...
    strjoin(conditions, ', '), ...          
    strjoin(Expt.concentrations, ', '), ... 
    Expt.temp, Expt.CaMg, Expt.trialInterval, Expt.stim, Expt.genotype, Expt.age, Expt.cellType, Expt.region, folder);

fig = figure('Color','w','Position',[100 100 550 600], 'visible','off');

annotation('textbox',[0.05 0.05 0.9 0.9], ...
    'String', metadataText, ...
    'FontName','Consolas', ...  % nice monospaced lab vibe
    'FontSize',14, ...
    'Interpreter','none', ...
    'EdgeColor','none');

exportgraphics(fig, sprintf('%s/Experiment_Metadata.png', figureFolder), 'Resolution', 300);

 