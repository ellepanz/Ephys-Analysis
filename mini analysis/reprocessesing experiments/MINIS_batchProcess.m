function Results = MINIS_batchProcess(processorFcn,varargin)
% MINIS_batchProcess
%
% General-purpose batch loader for saved MINI-IPSC experiments listed in
% the master Population table.
%
% PROCESSORFCN:
%   cellData = processorFcn(cellData,dataFile)
%
% Options:
%   'SaveChanges'      false
%   'BackupBeforeSave' true
%   'StopOnError'      false
%
% Legacy filename support:
%   If Population.DataFile points to LP279b_data.mat but that file does not
%   exist, this function also checks for LP279b.mat in the same folder.
%   The reverse is also supported.
%
% GPT metaphor:
%   MINIS_batchProcess = washing machine
%   processorFcn       = wash cycle

populationFile = '\\bunson\bunson\Higley_Lab\Lauren bunsen\Data Summaries\mIPSCs with NMDA\NMDAmIPSCs_population.mat';

%% OPTIONS

p = inputParser;
addParameter(p,'SaveChanges',false,@(x) islogical(x) && isscalar(x));
addParameter(p,'BackupBeforeSave',true,@(x) islogical(x) && isscalar(x));
addParameter(p,'StopOnError',false,@(x) islogical(x) && isscalar(x));
parse(p,varargin{:});

%% GET SAVED EXPERIMENT FILES

dataFiles = resolveDataFiles(populationFile);
nFiles = numel(dataFiles);

CellID = strings(nFiles,1);
RequestedDataFile = strings(nFiles,1);
DataFile = strings(nFiles,1);
Status = strings(nFiles,1);
Message = strings(nFiles,1);
ErrorFunction = strings(nFiles,1);
ErrorLine = nan(nFiles,1);
ElapsedSec = nan(nFiles,1);

%% PROCESS EACH EXPERIMENT

for i = 1:nFiles

    requestedFile = char(dataFiles(i));
    RequestedDataFile(i) = string(requestedFile);
    tStart = tic;

    fprintf('\n========================================\n');
    fprintf('Experiment %d/%d\n',i,nFiles);
    fprintf('Population path: %s\n',requestedFile);
    fprintf('========================================\n');

    try
        % Resolve old LP###x.mat versus newer LP###x_data.mat naming.
        dataFile = resolveExperimentFile(requestedFile);
        DataFile(i) = string(dataFile);

        if ~strcmp(dataFile,requestedFile)
            fprintf('Using actual file: %s\n',dataFile);
        end

        cellData = load(dataFile);

        if isfield(cellData,'Expt') && isfield(cellData.Expt,'marker')
            CellID(i) = string(cellData.Expt.marker);
            fprintf('Cell: %s\n',CellID(i));
        end

        updatedData = processorFcn(cellData,dataFile);

        if ~isempty(updatedData)
            if ~isstruct(updatedData)
                error('processorFcn must return cellData or [].');
            end
            cellData = updatedData;
        end

        if p.Results.SaveChanges
            if p.Results.BackupBeforeSave
                backupFile = [dataFile '.bak'];

                if ~isfile(backupFile)
                    copyfile(dataFile,backupFile);
                end
            end

            save(dataFile,'-struct','cellData','-v7.3');
        end

        Status(i) = "OK";

    catch ME
        Status(i) = "ERROR";
        Message(i) = string(ME.message);

        if ~isempty(ME.stack)
            ErrorFunction(i) = string(ME.stack(1).name);
            ErrorLine(i) = ME.stack(1).line;

            warning('%s failed in %s at line %d: %s', ...
                requestedFile,ME.stack(1).name,ME.stack(1).line,ME.message);
        else
            warning('%s failed: %s',requestedFile,ME.message);
        end

        if p.Results.StopOnError
            rethrow(ME);
        end
    end

    ElapsedSec(i) = toc(tStart);
end

%% RESULTS

Results = table(CellID,RequestedDataFile,DataFile,Status,Message,ErrorFunction,ErrorLine,ElapsedSec);

fprintf('\n========================================\n');
fprintf('Batch complete.\n');
fprintf('Successful: %d\n',sum(Status=="OK"));
fprintf('Failed:     %d\n',sum(Status=="ERROR"));
fprintf('========================================\n');

end


%% RESOLVE POPULATION FILE INTO EXPERIMENT FILE LIST

function dataFiles = resolveDataFiles(populationFile)

if ~isfile(populationFile)
    error('Population file does not exist: %s',populationFile);
end

tmp = load(populationFile,'Population');

if ~isfield(tmp,'Population') || ~istable(tmp.Population)
    error('Population file does not contain a Population table.');
end

if ~ismember('DataFile',tmp.Population.Properties.VariableNames)
    error('Population table does not contain a DataFile column.');
end

dataFiles = string(tmp.Population.DataFile);
dataFiles = dataFiles(strlength(dataFiles)>0);
dataFiles = unique(dataFiles,'stable');

end


%% RESOLVE CURRENT VS LEGACY SAVED-DATA FILENAMES

function dataFile = resolveExperimentFile(requestedFile)

% First use the path exactly as stored in Population.
if isfile(requestedFile)
    dataFile = requestedFile;
    return
end

[folder,name,ext] = fileparts(requestedFile);

% Population points to newer *_data.mat, but experiment was saved using the
% older LP###x.mat convention.
if endsWith(name,'_data')
    legacyName = extractBefore(name,strlength(name)-4);
    legacyFile = fullfile(folder,[char(legacyName) ext]);

    if isfile(legacyFile)
        dataFile = legacyFile;
        return
    end
else
    % Also support the reverse situation.
    newerFile = fullfile(folder,[name '_data' ext]);

    if isfile(newerFile)
        dataFile = newerFile;
        return
    end
end

error('Saved data file does not exist. Checked stored path and legacy/new filename alternative.');

end
