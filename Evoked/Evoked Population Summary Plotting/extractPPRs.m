function PPRdata = extractPPRs(compiledData, condList)
% extractPPRs - Extract PPRs by frequency across selected conditions.
%
% Combines equivalent PPR measurements:
%   PPR.x5_20Hz.PPR and PPR.Hz_20.PPR are both stored as Hz_20.
%
% Output:
%   PPRdata.values.Hz_5.(cond)
%   PPRdata.values.Hz_20.(cond)
%   PPRdata.values.Hz_40.(cond)


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

%% Define analysis-level PPR frequencies
freqMap = struct();

freqMap.Hz_5  = {'x5_5Hz'};
freqMap.Hz_20 = {'x5_20Hz', 'Hz_20'};
freqMap.Hz_40 = {'x5_40Hz'};

freqNames = fieldnames(freqMap);

%% Initialize output
PPRdata = struct();
PPRdata.condList = condList;
PPRdata.commonExpts = commonExpts;
PPRdata.freqNames = freqNames;
PPRdata.values = struct();
PPRdata.sourceProtocol = struct();

%% Extract values frequency-by-frequency
for f = 1:numel(freqNames)

    freqName = freqNames{f};
    possibleProtocols = freqMap.(freqName);

    for c = 1:numel(condList)

        cond = condList{c};
        condExpts = {compiledData.(cond).Expt};

        % preallocate 
        vals = nan(1, numel(commonExpts));
        sourceProtocol = cell(1, numel(commonExpts));

        for e = 1:numel(commonExpts)

            exptName = commonExpts{e};
            idx = find(strcmp(condExpts, exptName), 1);

            if isempty(idx)
                continue
            end

            cellData = compiledData.(cond)(idx);

            if ~isfield(cellData, 'PPR') || isempty(cellData.PPR)
               warning('No PPR data found.')
                continue
            end

            for p = 1:numel(possibleProtocols)

                protocol = possibleProtocols{p};

                if isfield(cellData.PPR, protocol)

                    thisPPR = cellData.PPR.(protocol);

                    if isstruct(thisPPR) && isfield(thisPPR, 'PPR')
                        vals(e) = thisPPR.PPR;
                        sourceProtocol{e} = protocol;
                        break

                    elseif isnumeric(thisPPR) && isscalar(thisPPR)
                        vals(e) = thisPPR;
                        sourceProtocol{e} = protocol;
                        break
                    end
                end
            end
        end

        PPRdata.values.(freqName).(cond) = vals';
        PPRdata.sourceProtocol.(freqName).(cond) = sourceProtocol;
        assignin('base', 'PPRdata', PPRdata)

    end
end

end