function [trialNames,trialNums] = MINIS_getTrialInfo(Data,cond,funct)
% Return AD0 trial names and numeric trial IDs in chronological order.

switch funct
    case 'raw'
        fields = fieldnames(Data.(cond));

    case 'trialMetrics'
        fields = Data.(cond).notDelTrialNames;

    otherwise
        error('Unknown trial-info mode "%s". Use "raw" or "trialMetrics".',funct);
end

fields = fields(:);
isTrial = ~cellfun('isempty',regexp(fields,'^AD0_\d+$','once'));
trialNames = fields(isTrial);

if isempty(trialNames)
    trialNums = [];
    trialNames = {};
    return
end

trialNums = cellfun(@(x) sscanf(x,'AD0_%d'),trialNames);
[trialNums,order] = sort(trialNums);
trialNames = trialNames(order);

trialNums = trialNums(:)';
trialNames = trialNames(:)';

end
