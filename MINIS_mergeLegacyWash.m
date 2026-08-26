function Data = MINIS_mergeLegacyWash(Data,removeOldFields)
% Merge legacy WashWaste + Wash into one canonical Washout condition.
% The resulting Data.Washout is structured like a normal compiled condition.

if nargin < 2
    removeOldFields = false;
end

sources = {'WashWaste','Wash'};

%% Check fields

for i = 1:numel(sources)
    cond = sources{i};

    if ~isfield(Data,cond)
        error('Data.%s is missing.',cond);
    end

    if ~isfield(Data.rawTraces,cond)
        error('Data.rawTraces.%s is missing.',cond);
    end
end

%% Create merged conditions

Data.Washout = struct();
Data.rawTraces.Washout = struct();

%% Copy individual AD0 trials

for i = 1:numel(sources)
    cond = sources{i};

    fields = fieldnames(Data.(cond));
    isTrial = ~cellfun('isempty',regexp(fields,'^AD0_\d+$','once'));
    names = fields(isTrial);

    for k = 1:numel(names)
        name = names{k};
        Data.Washout.(name) = Data.(cond).(name);
        Data.rawTraces.Washout.(name) = Data.rawTraces.(cond).(name);
    end
end

%% Combine processed data exactly as compileEphysData_minis produced it

Data.Washout.smthdFullTrace = [Data.WashWaste.smthdFullTrace Data.Wash.smthdFullTrace];
Data.Washout.smthdMinis = [Data.WashWaste.smthdMinis Data.Wash.smthdMinis];
Data.Washout.testPulse = [Data.WashWaste.testPulse Data.Wash.testPulse];

%% Combine trial identities

Data.Washout.trialNames = [Data.WashWaste.trialNames Data.Wash.trialNames];
Data.Washout.trialNums = [Data.WashWaste.trialNums Data.Wash.trialNums];

%% Optionally remove legacy condition names

if removeOldFields
    Data = rmfield(Data,sources);
    Data.rawTraces = rmfield(Data.rawTraces,sources);
end

end