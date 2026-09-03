function plotIndividualAvgdWaves(ComparisonData)
%
% Batch plots all the averaged EPSCs with each cell in a new figure
% for all cells in ComparisonData

% This function loops through all PairIDs and calls plotEPSCTracePair.
% All plotting formatting should be edited in plotEPSCTracePair.m.
%


if ~isfield(ComparisonData, 'PairEntries') || isempty(ComparisonData.PairEntries)
    warning('ComparisonData has no PairEntries to plot.')
    return
end

for pairID = 1:numel(ComparisonData.PairEntries)
    plotEPSCTracePair(ComparisonData, pairID);
end

end