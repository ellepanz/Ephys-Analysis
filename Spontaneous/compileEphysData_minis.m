function [Expt,Data] = compileEphysData_minis(epochs,folder,conditions,Expt,figureFolder,S)
% Load miniature-current ITX files and organize trials for downstream analysis.

if numel(epochs) ~= numel(conditions)
    error('epochs and conditions must contain the same number of entries.');
end

if ~exist(figureFolder,'dir')
    mkdir(figureFolder);
end

Data = struct;
Data.rawTraces = struct;

%% LOAD ITX DATA

for j = 1:numel(epochs)
    epoch = epochs{j};
    cond = conditions{j};

    Data.rawTraces.(cond) = struct;
    FileNames = dir(fullfile(folder,['*' epoch '*.itx']));

    if isempty(FileNames)
        error('No ITX files matching epoch "%s" were found for condition "%s".',epoch,cond);
    end

    for k = 1:numel(FileNames)
        fullPath = fullfile(folder,FileNames(k).name);
        loadedData = readITXwaves(fullPath);
        loadedFields = fieldnames(loadedData);

        for f = 1:numel(loadedFields)
            fieldName = loadedFields{f};
            Data.rawTraces.(cond).(fieldName) = loadedData.(fieldName);
        end
    end
end

%% SEPARATE MINI DATA AND TEST PULSES

expectedFullSamples = round(S.recordingLength*S.Fs);

for j = 1:numel(conditions)
    cond = conditions{j};

    fields = fieldnames(Data.rawTraces.(cond));
    isTrial = ~cellfun('isempty',regexp(fields,'^AD0_\d+$','once'));
    trialNames = fields(isTrial);

    if isempty(trialNames)
        error('No individual AD0_## trials found for %s.',cond);
    end

    trialNums = cellfun(@(x) sscanf(x,'AD0_%d'),trialNames);
    [trialNums,order] = sort(trialNums);
    trialNames = trialNames(order);

    trialNums = trialNums(:)';
    trialNames = trialNames(:)';
    nTrials = numel(trialNames);

    Data.(cond).smthdFullTrace = nan(expectedFullSamples,nTrials);
    Data.(cond).smthdMinis = nan(S.miniSamples,nTrials);
    Data.(cond).testPulse = nan(S.sealSamples,nTrials);

    for k = 1:nTrials
        fullTrace = Data.rawTraces.(cond).(trialNames{k});
        fullTrace = fullTrace(:);

        if numel(fullTrace) ~= expectedFullSamples
            error('%s.%s contains %d samples; expected %d.',cond,trialNames{k},numel(fullTrace),expectedFullSamples);
        end

        Data.(cond).(trialNames{k}) = fullTrace;

        smthdTrace = sgolayfilt(fullTrace,S.sgOrder,S.sgFrame);
       
        Data.(cond).smthdFullTrace(:,k) = smthdTrace;
        Data.(cond).smthdMinis(:,k) = smthdTrace(1:S.miniSamples);
        Data.(cond).testPulse(:,k) = fullTrace(S.sealStartIdx:S.sealEndIdx);
    end

    Data.(cond).trialNames = trialNames;
    Data.(cond).trialNums = trialNums;
end

%% GENERATE METADATA IMAGE

metadataText = sprintf([ ...
    'Experiment: %s\n' ...
    'Date: %s\n' ...
    'Recording Type: %s\n' ...
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
    Expt.marker,Expt.date,Expt.recordingType,Expt.startingCond,Expt.drugCond,Expt.internal,Expt.Vh, ...
    Expt.temp,Expt.CaMg,Expt.genotype,Expt.age,Expt.cellType,Expt.region,folder);

fig = figure('Color','w','Position',[100 100 600 650],'Visible','off');
annotation(fig,'textbox',[0.05 0.05 0.9 0.9],'String',metadataText,'FontName','Consolas', ...
    'FontSize',14,'Interpreter','none','EdgeColor','none');
exportgraphics(fig,fullfile(figureFolder,'Experiment_Metadata.png'),'Resolution',300);
close(fig);

end
