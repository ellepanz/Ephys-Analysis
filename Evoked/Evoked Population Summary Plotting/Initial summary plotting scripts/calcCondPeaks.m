function calcCondPeaks(DataSum, condList)
% Compiles the single stim EPSC peaks for plotting in prism
%
%   DataSum: struct with DataSum.(cond)(i).Expt and DataSum.(cond)(i).AvgPeaks.x1
%   condList: cell array of conditions, e.g. {'Control','AgaTK','AgaTK_CdCl2'}
%
%   results: struct with fields
%       .expts - list of matched experiment IDs
%       .peaks.(cond) - vector of EPSC peak values for each matched experiment
%       .mean.(cond)  - mean across experiments
%       .sem.(cond)   - SEM across experiments

    % --- Step 1: collect experiment IDs per condition ---
    condExpts = cell(numel(condList),1);
    for c = 1:numel(condList)
        cond = condList{c};
        condExpts{c} = {DataSum.(cond).Expt};
    end
    
    % --- Step 2: find common experiments ---
    commonExpts = condExpts{1};
    for c = 2:numel(condExpts)
        commonExpts = intersect(commonExpts, condExpts{c});
    end
    
    if isempty(commonExpts)
        warning('No common experiments across conditions');
        results = [];
        return;
    end
    
    % --- Step 3: pull AvgPeaks.x1 for matched experiments ---
    results.expts = commonExpts;
    for c = 1:numel(condList)
        cond = condList{c};
        peaks = nan(1, numel(commonExpts));
        for e = 1:numel(commonExpts)
            % find index of this Expt in DataSum.(cond)
            idx = find(strcmp({DataSum.(cond).Expt}, commonExpts{e}), 1);
            if isempty(idx)
                continue;
            end
            if isfield(DataSum.(cond)(idx).AvgPeaks,'x1')
                peaks(e) = DataSum.(cond)(idx).AvgPeaks.x1;
            end
        end
        results.peaks.(cond) = peaks;
        results.mean.(cond)  = mean(peaks, 'omitnan');
        results.sem.(cond)   = std(peaks, 'omitnan') ./ sqrt(sum(~isnan(peaks)));
    end
    assignin('base','condPeaks',results)
end
