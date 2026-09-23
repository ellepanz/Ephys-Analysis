function binderFile = MINIS_rebuildBinder(Expt,varargin)
% Rebuild binder by concatenating existing individual cell summary PDFs.
% This preserves old PDFs exactly and does not regenerate cell summaries.

tic

p = inputParser;
addParameter(p,'StudyID',"",@(x) ischar(x) || isstring(x));
addParameter(p,'PopulationOnly',false,@(x) islogical(x) && isscalar(x));
addParameter(p,'SkipMissing',false,@(x) islogical(x) && isscalar(x));
parse(p,varargin{:});

if ~isfield(Expt,'recordingType') || strlength(string(Expt.recordingType)) == 0
    error('Expt.recordingType must be defined.');
end

paths = MINIS_getPopulationPaths(Expt);
binderIndexFile = paths.binderIndexFile;
binderFile = paths.binderFile;

if ~isfile(binderIndexFile)
    error('BinderIndex not found: %s',binderIndexFile);
end

tmp = load(binderIndexFile,'BinderIndex');

if ~isfield(tmp,'BinderIndex') || ~istable(tmp.BinderIndex)
    error('File does not contain BinderIndex table: %s',binderIndexFile);
end

BinderIndex = upgradeBinderIndex(tmp.BinderIndex);

keep = strcmpi(strtrim(string(BinderIndex.RecordingType)),strtrim(string(Expt.recordingType)));

studyID = strtrim(string(p.Results.StudyID));
if strlength(studyID) > 0
    keep = keep & strcmpi(strtrim(string(BinderIndex.StudyID)),studyID);
end

if p.Results.PopulationOnly
    keep = keep & BinderIndex.IncludeInPopulation;
end

BinderIndex = BinderIndex(keep,:);
BinderIndex = sortrows(BinderIndex,'Marker');

if isempty(BinderIndex)
    error('No BinderIndex rows matched the requested filters.');
end

pdfFiles = resolveSummaryPDFs(BinderIndex);
missingPDF = ~isfile(pdfFiles);

if any(missingPDF)
    missingTable = table(BinderIndex.Marker(missingPDF),pdfFiles(missingPDF), ...
        'VariableNames',{'Marker','MissingSummaryPDF'});
    disp(missingTable)

    if p.Results.SkipMissing
        BinderIndex = BinderIndex(~missingPDF,:);
        pdfFiles = pdfFiles(~missingPDF);
    else
        error('One or more summary PDFs are missing. Binder was not rebuilt.');
    end
end

if isempty(pdfFiles)
    error('No valid summary PDFs found. Binder was not rebuilt.');
end

[binderFolder,binderName,binderExt] = fileparts(binderFile);
tempBinder = fullfile(binderFolder,[binderName '_building' binderExt]);

if isfile(tempBinder)
    delete(tempBinder);
end

gs = findGhostscript;
mergePDFsWithGhostscript(gs,pdfFiles,tempBinder);

if ~isfile(tempBinder)
    error('Ghostscript finished, but temp binder was not created.');
end

if isfile(binderFile)
    backupBinder = fullfile(binderFolder,[binderName '_backup' binderExt]);

    if isfile(backupBinder)
        delete(backupBinder);
    end

    movefile(binderFile,backupBinder);
end

try
    movefile(tempBinder,binderFile);

    if exist('backupBinder','var') && isfile(backupBinder)
        delete(backupBinder);
    end
catch ME
    if exist('backupBinder','var') && isfile(backupBinder)
        movefile(backupBinder,binderFile);
    end
    rethrow(ME);
end

fprintf('\nBinder rebuilt successfully:\n%s\n',binderFile);
fprintf('Included %d summary PDFs.\n',numel(pdfFiles));
toc

end

function BinderIndex = upgradeBinderIndex(BinderIndex)

n = height(BinderIndex);

if ~ismember('Marker',BinderIndex.Properties.VariableNames)
    error('BinderIndex is missing Marker.');
end

varsToAdd = {
    'RecordingType', strings(n,1)
    'StudyID', strings(n,1)
    'DataFile', strings(n,1)
    'FigureFolder', strings(n,1)
    'SummaryFig', strings(n,1)
    'SummaryPDF', strings(n,1)
    'IncludeValidation', false(n,1)
    'IncludeInPopulation', false(n,1)
    'ExclusionReason', strings(n,1)
    'LastUpdated', NaT(n,1)
};

for k = 1:size(varsToAdd,1)
    varName = varsToAdd{k,1};
    defaultValue = varsToAdd{k,2};

    if ~ismember(varName,BinderIndex.Properties.VariableNames)
        BinderIndex.(varName) = defaultValue;
    end
end

vars = {'Marker','RecordingType','StudyID','DataFile','FigureFolder','SummaryFig', ...
    'SummaryPDF','IncludeValidation','IncludeInPopulation','ExclusionReason','LastUpdated'};

BinderIndex = BinderIndex(:,vars);

end

function [pdfFiles,BinderIndex] = resolveSummaryPDFs(BinderIndex)

% the helper that figures out where each cell’s summary PDF actually lives
% right now for the summary binder


pdfFiles = strings(height(BinderIndex),1);

searchRoot = '\\bunson\bunson\Higley_Lab\Lauren bunsen';

for k = 1:height(BinderIndex)

    marker = strtrim(string(BinderIndex.Marker(k)));
    pdfFile = strtrim(string(BinderIndex.SummaryPDF(k)));

    % 1. First try the currently stored SummaryPDF path.
    if strlength(pdfFile) > 0 && isfile(pdfFile)
        pdfFiles(k) = pdfFile;
        continue
    end

    % 2. If SummaryPDF is empty, try deriving it from FigureFolder.
    if strlength(pdfFile) == 0 && strlength(string(BinderIndex.FigureFolder(k))) > 0
        cellFolder = fileparts(char(BinderIndex.FigureFolder(k)));
        candidate = string(fullfile(cellFolder,sprintf('%s_summary.pdf',marker)));

        if isfile(candidate)
            pdfFiles(k) = candidate;
            BinderIndex.SummaryPDF(k) = candidate;
            continue
        end
    end

    % 3. Stored paths are stale. Search the archive/current folders by marker.
    targetName = sprintf('%s_summary.pdf',marker);
    matches = dir(fullfile(searchRoot,'**',targetName));

    if isempty(matches)
        pdfFiles(k) = pdfFile;
        continue
    end

    if numel(matches) > 1
        matchPaths = strings(numel(matches),1);

        for j = 1:numel(matches)
            matchPaths(j) = string(fullfile(matches(j).folder,matches(j).name));
        end

        fprintf('\nMultiple summary PDFs found for %s:\n',marker);
        disp(matchPaths)

        error('Multiple summary PDFs found for %s. Binder was not rebuilt.',marker);
    end

    % 4. Exactly one current PDF found. Use it and repair BinderIndex.
    resolvedPDF = string(fullfile(matches(1).folder,matches(1).name));

    pdfFiles(k) = resolvedPDF;
    BinderIndex.SummaryPDF(k) = resolvedPDF;

    % Also refresh FigureFolder if the summary PDF sits beside the cell folder.
    cellFolder = fileparts(char(resolvedPDF));
    candidateFigureFolder = fullfile(cellFolder,'Matlab figures');

    if isfolder(candidateFigureFolder)
        BinderIndex.FigureFolder(k) = string(candidateFigureFolder);
    end

    BinderIndex.LastUpdated(k) = datetime('now');

    fprintf('Updated archived path for %s:\n%s\n',marker,resolvedPDF);

end

end

function gs = findGhostscript

[status,out] = system('where gswin64c');

if status == 0
    lines = splitlines(string(strtrim(out)));
    lines = lines(strlength(lines) > 0);
    gs = lines(1);
    return
end

[status,out] = system('where gswin32c');

if status == 0
    lines = splitlines(string(strtrim(out)));
    lines = lines(strlength(lines) > 0);
    gs = lines(1);
    return
end

[status,out] = system('where gs');

if status == 0
    lines = splitlines(string(strtrim(out)));
    lines = lines(strlength(lines) > 0);
    gs = lines(1);
    return
end

error('Ghostscript not found. Confirm that system(''where gswin64c'') works.');

end

function mergePDFsWithGhostscript(gs,pdfFiles,outFile)

cmd = sprintf('"%s" -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dAutoRotatePages=/None -sOutputFile="%s"',gs,outFile);

for k = 1:numel(pdfFiles)
    cmd = sprintf('%s "%s"',cmd,pdfFiles(k));
end

[status,out] = system(cmd);

if status ~= 0
    fprintf('%s\n',out);
    error('Ghostscript PDF merge failed.');
end

end