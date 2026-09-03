function calcEPSCPeaks(DataSum, condList)
peakWindow = 1100:1300;

for i = 1:numel(condList)
    cond = condList{i};
    condData = DataSum.(cond);
    
    % figure out max trials across experiments
    maxTrials = 0;
    for e = 1:numel(condData)
        if isfield(condData(e).x1,'basesubTrials')
            maxTrials = max(maxTrials, size(condData(e).x1.basesubTrials,2));
        end
    end
    
    condMatrix = nan(maxTrials, numel(condData)); % preallocate padded matrix
    
    for e = 1:numel(condData)
        if isfield(condData(e).x1,'basesubTrials')
            trials = condData(e).x1.basesubTrials;
            peaks = min(trials(peakWindow,:), [], 1); % min per trial
            condData(e).x1.peakVals = peaks; % save back
            condMatrix(1:numel(peaks), e) = peaks(:);
        end
    end
    
    % update DataSum and push condition matrix
    DataSum.(cond) = condData;
    varName = [cond '_peakVals'];
    assignin('base', varName, condMatrix);
end

assignin('base','DataSum',DataSum); % update structure in base
end
