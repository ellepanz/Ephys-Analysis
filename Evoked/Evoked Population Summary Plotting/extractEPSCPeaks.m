function PeakData = extractEPSCPeaks(compiledData, condList)
% extractEPSCPeaks - Extract average EPSC peak amplitudes across conditions.
%
% Expected structure:
%   compiledData.(cond)(i).AvgPeaks.x1
%   compiledData.(cond)(i).AvgPeaks.x5_5Hz
%   compiledData.(cond)(i).AvgPeaks.x5_20Hz
%   compiledData.(cond)(i).AvgPeaks.x5_40Hz
%   compiledData.(cond)(i).AvgPeaks.Hz_20
%
% Combines:
%   x5_20Hz and Hz_20 are both stored under Hz_20.

condList = cellstr(condList);

%% Find experiments present in all selected conditions
allExpts = cell(1, numel(condList));

for c = 1:numel(condList)
    cond = condList{c};

    if ~isfield(compiledData, cond)
        error('Condition "%s" not found in compiledData.', cond);
    end

    allExpts{c} = {compiledData.(cond).Expt};
end

commonExpts = allExpts{1};

for c = 2:numel(allExpts)
    commonExpts = intersect(commonExpts, allExpts{c}, 'stable');
end

if isempty(commonExpts)
    warning('No experiments found in all selected conditions.');
end

%% Define analysis-level peak groups
peakMap = struct();

peakMap.SingleStim = {'x1'};
peakMap.Hz_5       = {'x5_5Hz'};
peakMap.Hz_20      = {'x5_20Hz', 'Hz_20'};
peakMap.Hz_40      = {'x5_40Hz'};

peakNames = fieldnames(peakMap);

%% Initialize output
PeakData = struct();
PeakData.condList = condList;
PeakData.commonExpts = commonExpts;
PeakData.peakNames = peakNames;
PeakData.values = struct();
PeakData.sourceProtocol = struct();

%% Extract peak values
for f = 1:numel(peakNames)

    peakName = peakNames{f};
    possibleProtocols = peakMap.(peakName);

    for c = 1:numel(condList)

        cond = condList{c};
        condExpts = {compiledData.(cond).Expt};

        vals = nan(numel(commonExpts), 1);
        sourceProtocol = cell(numel(commonExpts), 1);

        for e = 1:numel(commonExpts)

            exptName = commonExpts{e};
            idx = find(strcmp(condExpts, exptName), 1);

            if isempty(idx)
                continue
            end

            cellData = compiledData.(cond)(idx);

            if ~isfield(cellData, 'AvgPeaks') || isempty(cellData.AvgPeaks)
                continue
            end

            for p = 1:numel(possibleProtocols)

                protocol = possibleProtocols{p};

                if isfield(cellData.AvgPeaks, protocol) && ...
                        ~isempty(cellData.AvgPeaks.(protocol))

                    thisPeaks = cellData.AvgPeaks.(protocol)(:)';

                    vals = padPeakMatrix(vals, e, thisPeaks);
                    sourceProtocol{e} = protocol;

                    break
                end
            end
        end

        PeakData.values.(peakName).(cond) = vals;
        PeakData.sourceProtocol.(peakName).(cond) = sourceProtocol;
    end
end

assignin('base', 'PeakData', PeakData)

end


function vals = padPeakMatrix(vals, rowIdx, thisPeaks)

nCurrentCols = size(vals, 2);
nNewCols = numel(thisPeaks);

if nNewCols > nCurrentCols
    vals(:, end+1:nNewCols) = nan;
end

vals(rowIdx, 1:nNewCols) = thisPeaks;

end