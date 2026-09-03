function compiledData = buildCompiledData(mainPharm, condList)
% called by GUI_selectPlots, hands compiledData back 
% 
% 
% make compiledData  - Load one main EPSC dataset and pull selected condition fields.
%
% Example:
%   compiledData = buildCompiledData("AgaTK", ["Control","AgaTK","AgaTK_AMN082"]);
%   compiledData = buildCompiledData("AgaTK", ["AgaTK","AgaTK_AMN082"]);

mainPharm = string(mainPharm);
condList = string(condList);

%% Load main dataset
switch mainPharm
    case "AgaTK"
        S = load('EPSCsAgaTK_current.mat');
        rawData = S.AgaTK_current;

    case "ConoGVIA"
        S = load('EPSCsConoGVIA_current.mat');
        rawData = S.ConoGVIA_current;

    case "Muscarine"
        S = load('EPSCsMuscarine.mat');
        rawData = S.Muscarine;

    otherwise
        error('Unknown main pharmacology: %s', mainPharm);
end

%% Pull requested conditions
compiledData = struct();

for c = 1:numel(condList)
    cond = condList{c};

    if ~isfield(rawData, cond)
        warning('Condition "%s" not found in %s dataset. Skipping.', cond, mainPharm);
        continue
    end

    compiledData.(cond) = rawData.(cond);
end

assignin('base','compiledData',compiledData); % optional for debugging
end