function openQCTraceFigureForPair(ComparisonData, pairID)
% openQCTraceFigureForPair
%
% Opens the saved Rs or Rs/Rin quality-control figure for a given PairID.

if pairID > numel(ComparisonData.PairEntries)
    error('PairID %d exceeds number of PairEntries.', pairID);
end

entry = ComparisonData.PairEntries(pairID);

if ~isfield(entry, 'Source') || ~isfield(entry.Source, 'rsFigureFile')
    error('No Source.rsFigureFile found for PairID %d.', pairID);
end

qcFile = entry.Source.rsFigureFile;

if ~exist(qcFile, 'file')
    error('QC figure file not found: %s', qcFile);
end

fig = openfig(qcFile);

set(fig, 'Name', sprintf('QC | PairID %d | %s', ...
    pairID, entry.Expt), ...
    'NumberTitle', 'off');

end