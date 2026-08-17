function Data = MINIS_mergeLegacyWash(Data, S, removeOldFields)
% Optional helper for the first experiment in which washout was split into
% Data.WashWaste and Data.Wash. Creates a canonical Data.Washout condition.

if nargin < 3
    removeOldFields = false;
end

sources = {'WashWaste','Wash'};
for i = 1:numel(sources)
    if ~isfield(Data,sources{i})
        error('Data.%s is missing.',sources{i});
    end
end

Washout = struct();

% Copy only raw AD0_# trials from both source conditions.
for i = 1:numel(sources)
    cond = sources{i};
    [names,~] = MINIS_getTrialInfo(Data,cond);
    for k = 1:numel(names)
        Washout.(names{k}) = Data.(cond).(names{k});
    end
end

Data.Washout = Washout;
[names,~] = MINIS_getTrialInfo(Data,'Washout');
nTrials = numel(names);

Data.Washout.miniData = nan(S.miniSamples,nTrials);
Data.Washout.sealTests = nan(S.sealSamples,nTrials);

for k = 1:nTrials
    tr = Data.Washout.(names{k});
    Data.Washout.miniData(:,k) = tr(1:S.miniSamples);
    Data.Washout.sealTests(:,k) = tr(S.sealStartIdx:S.sealEndIdx);
end

Data.Washout.concatData = Data.Washout.miniData(:);

if removeOldFields
    Data = rmfield(Data,sources);
end
end
