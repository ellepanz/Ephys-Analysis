function WaveData = extractAverageEPSCs(compiledData, condList)

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
    error('No experiments found in all selected conditions.');
end

%% Define analysis-level protocol groups
protocolMap = struct();
protocolMap.SingleStim = {'x1'};
protocolMap.Hz_20 = {'x5_20Hz', 'Hz_20'};

protocols = fieldnames(protocolMap);

%% Initialize output
WaveData = struct();
WaveData.condList = condList;
WaveData.commonExpts = commonExpts;
WaveData.protocols = protocols;
WaveData.sourceProtocol = struct();

%% Extract waves
for p = 1:numel(protocols)

    analysisProtocol = protocols{p};
    possibleProtocols = protocolMap.(analysisProtocol);

    for c = 1:numel(condList)

        cond = condList{c};
        condExpts = {compiledData.(cond).Expt};

        waves = [];
        sourceProtocol = {};

        for e = 1:numel(commonExpts)

            exptName = commonExpts{e};
            idx = find(strcmp(condExpts, exptName), 1);

            if isempty(idx)
                continue
            end

            cellData = compiledData.(cond)(idx);

            for pp = 1:numel(possibleProtocols)

                sourceProt = possibleProtocols{pp};

                if isfield(cellData, sourceProt) && ...
                        isstruct(cellData.(sourceProt)) && ...
                        isfield(cellData.(sourceProt), 'avgWave') && ...
                        ~isempty(cellData.(sourceProt).avgWave)

                    trace = cellData.(sourceProt).avgWave(:);
                    waves = padAndAppend(waves, trace);

                    sourceProtocol{end+1,1} = sourceProt;
                end
            end
        end

        WaveData.waves.(analysisProtocol).(cond) = waves;
        WaveData.avgWave.(analysisProtocol).(cond) = mean(waves, 2, 'omitnan');
        WaveData.n.(analysisProtocol).(cond) = size(waves, 2);
        WaveData.sourceProtocol.(analysisProtocol).(cond) = sourceProtocol;
    end
end
assignin('base','waveData', WaveData)

end


function waves = padAndAppend(waves, trace)

if isempty(waves)
    waves = trace;
    return
end

nOld = size(waves, 1);
nNew = numel(trace);

if nNew > nOld
    waves(end+1:nNew, :) = nan;
elseif nNew < nOld
    trace(end+1:nOld, 1) = nan;
end

waves(:, end+1) = trace;

end