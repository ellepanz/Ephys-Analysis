function plotSummaryTraces(DataSum, condList)
% plotSummaryTraces - plots single stim avgWave traces for multiple conditions
%
% Inputs:
%   DataSum   - struct containing Control and other pharmacology conditions
%   condList  - cell array of strings, e.g., {'Control','ConoGVIA','ConoGVIA_AMN082'}

% --- Find experiments present in all conditions ---
allExpts = {DataSum.Control.Expt};  % start with Control
for c = 1:numel(condList)
    condName = condList{c};
    if ~isfield(DataSum, condName)
        warning('Condition "%s" not found in DataSum. Skipping.', condName);
        continue
    end
    allExpts = intersect(allExpts, {DataSum.(condName).Expt}, 'stable');
end

if isempty(allExpts)
    error('No experiments found in all selected conditions.');
end

% --- Collect Waves and AverageWaves ---
Waves = struct();
AverageWaves = struct();

for c = 1:numel(condList)
    condName = condList{c};
    condData = DataSum.(condName);
    
    matchedTraces = [];
    for i = 1:numel(condData)
        exptName = condData(i).Expt;
        if ~ismember(exptName, allExpts)
            continue
        end
        xDrug = condData(i).x1.avgWave(:);   % column vector
        matchedTraces(:, end+1) = xDrug;
    end
    
    Waves.(condName) = matchedTraces;
    AverageWaves.(condName) = mean(matchedTraces,2);
end

assignin('base','Waves',Waves);
assignin('base','AverageWaves',AverageWaves);

% --- Plotting ---
figure; hold on;
condColors = getCondColors(condList);
load('TrialTime_sec.mat');

legendEntries = {};
for c = 1:numel(condList)
    condName = condList{c};
    plot(TrialTime.sec.ephys, AverageWaves.(condName), 'Color', condColors{c}, 'LineWidth', 2);
    legendEntries{end+1} = condName;
end

xlabel('Time (sec)', 'FontSize', 14);
ylabel('pA', 'FontSize', 14);
title('Average EPSCs', 'FontSize', 14);
set(gca, 'FontSize', 14); 

legend(legendEntries,'Location','best','Interpreter','none');

ylim([-200 50]);
xlim([0.09 0.2]);

end
