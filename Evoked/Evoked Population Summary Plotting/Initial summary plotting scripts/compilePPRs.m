function compilePPRs(DataSum, condList)
% compiles paired-pulse ratios (PPRs) for experiments present in all conditions
% Inputs:
%   DataSum  - struct with fields for each condition
%   condList - cell array of condition names (e.g., {'Control','AgaTK','AgaTK_CdCl2'})

HzList = {'x5_5Hz','x5_20Hz','x5_40Hz'};

% --- Find experiments present in all conditions ---
allExpts = cell(1, numel(condList));
for i = 1:numel(condList)
    cond = condList{i};
    allExpts{i} = {DataSum.(cond).Expt};  % collect experiment names
end

% Intersection across all conditions
commonExpts = allExpts{1};
for i = 2:numel(allExpts)
    commonExpts = intersect(commonExpts, allExpts{i}, 'stable');
end

% --- Compile PPRs only for common experiments ---
for i = 1:numel(condList)
    cond = condList{i};
    PPRs = struct();
    
    for h = 1:numel(HzList)
        Hz = HzList{h};
        vals = [];
        
        for e = 1:numel(DataSum.(cond))
            exptName = DataSum.(cond)(e).Expt;
            if ismember(exptName, commonExpts)
                if isfield(DataSum.(cond)(e),'PPR') && isfield(DataSum.(cond)(e).PPR,Hz)
                    vals(end+1) = DataSum.(cond)(e).PPR.(Hz).PPR;
                end
            end
        end
        
        PPRs.(Hz) = vals;
    end
    
    varName = [cond '_PPR'];
    assignin('base', varName, PPRs);
end
end
