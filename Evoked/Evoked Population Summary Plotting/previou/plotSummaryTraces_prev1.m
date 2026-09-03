function plotSummaryTraces(DataSum, condList)
% plotSummaryTracesAll - plots single stim avgWave traces for multiple conditions
%
% Inputs:
%   DataSum - struct containing Control and other pharmacology conditions
%   condList - cell array of strings, e.g., {'AgaTK','AgaTK_AMN082'}
assignin('base','condList',condList);

controlData = DataSum.Control;

% Loop through all selected conditions
for c = 1:numel(condList)
    condName = condList{c};
    if ~isfield(DataSum, condName)
        warning('Condition "%s" not found in DataSum. Skipping.', condName);
        continue
    end
    
    condData = DataSum.(condName);
    
    % Collect all matched traces
    matchedTraces = [];
    
    for i = 1:numel(condData)
        exptName = condData(i).Expt;
        
        % Match to Control
        controlIdx = find(strcmp({controlData.Expt}, exptName), 1);
        if isempty(controlIdx)
            warning('No matching Control for %s in %s', exptName, condName);
            continue
        end
        
        % Extract traces
        xDrug = condData(i).x1.avgWave(:);  % ensure column vector
        matchedTraces(:, end+1) = xDrug;
    end
    
    Waves.(condName) = matchedTraces;
    AverageWaves.(condName) = mean(matchedTraces,2);
        assignin('base','Waves',Waves);
        assignin('base','AverageWaves',AverageWaves);
end

legendEntries = {};

% Setup figure
figure; hold on;
condColors = getCondColors(condList);
    assignin('base','condColors',condColors)
load('TrialTime_sec.mat');
        
        % Plot mean ± SEM
        for i = 1:(numel(condList))
            cond = condList{i};
            plot(TrialTime.sec.ephys, AverageWaves.(cond), 'Color', condColors{i}, 'linewidth',2)
            legendEntries{end+1} = cond;
end

xlabel('Time (sec)')
ylabel('pA')
title('Average EPSCs')
legend(legendEntries,'Location','best', 'interpreter','none')
ylim([-200 50])
xlim([0.09 0.2])

end
