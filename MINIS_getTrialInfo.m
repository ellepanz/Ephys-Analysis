function [trialNames, trialNums] = MINIS_getTrialInfo(Data, cond, funct)
% Return raw AD0 trial field names and numeric trial IDs in chronological order.


if strcmp(funct, 'raw')
    fields = fieldnames(Data.(cond));
elseif strcmp(funct, 'trialMetrics')
    fields = Data.(cond).notDelTrialNames;
end

isTrial = ~cellfun('isempty', regexp(fields, '^AD0_\d+$', 'once'));
trialNames = fields(isTrial);

trialNums = cellfun(@(x) sscanf(x, 'AD0_%d'), trialNames);
[trialNums, order] = sort(trialNums);
trialNames = trialNames(order);
trialNums = trialNums(:)';
trialNames = trialNames(:)';
end
