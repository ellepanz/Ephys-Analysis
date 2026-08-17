function [trialNames, trialNums] = MINIS_getTrialInfo(Data, cond)
% Return raw AD0 trial field names and numeric trial IDs in chronological order.

fields = fieldnames(Data.(cond));
isTrial = ~cellfun('isempty', regexp(fields, '^AD0_\d+$', 'once'));
trialNames = fields(isTrial);

if isempty(trialNames)
    error('No AD0_# trial fields found in Data.%s.', cond);
end

trialNums = cellfun(@(x) sscanf(x, 'AD0_%d'), trialNames);
[trialNums, order] = sort(trialNums);
trialNames = trialNames(order);
trialNums = trialNums(:)';
trialNames = trialNames(:)';
end
