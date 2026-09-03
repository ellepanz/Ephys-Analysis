% Overall EPSC summary: v1 7/10/25
% v2: 7/10, added a section to compile avg peaks
% v3: Changed to function to run within summary plots script 8/12/25
% 9/28/25: trying to update this again to be a summarizing/plotting
% function? so lost
% 
% 10/2/25: rewrote - creates a variable, DataSum, that dynamically just
% pulls whatever summary data you want (ie Agasum, Conosum, whatever). Then
% puts it in the base so selectConditions can pass it to the correct
% plotting function

function Datasum(pharm1, varargin)
% Datasum - Load EPSC data for selected pharmacology conditions and compile.
%
% pharm1: string or char scalar for the first pharmacology
% varargin{1} (optional): string scalar for the second pharmacology

% Ensure scalar strings
if isstring(pharm1)
    pharm1 = pharm1(1);
elseif iscell(pharm1)
    pharm1 = string(pharm1{1});
end

if ~isempty(varargin)
    pharm2 = varargin{1};
    if isstring(pharm2)
        pharm2 = pharm2(1);
    elseif iscell(pharm2)
        pharm2 = string(pharm2{1});
    end
else
    pharm2 = [];
end

%% Load first pharmacology data
switch pharm1
    case "AgaTK"
        load('EPSCsAgaTK.mat'); % variable inside: AgaTK
        structPharm1 = AgaTK;
        dataPharm1 = AgaTK.AgaTK;
        dataControl = AgaTK.Control;
    case "ConoGVIA"
        load('EPSCsConoGVIA.mat');
        structPharm1 = ConoGVIA;
        dataPharm1 = ConoGVIA.ConoGVIA;
        dataControl = ConoGVIA.Control;
    case "Muscarine"
        load('EPSCsMuscarine.mat');
        structPharm1 = Muscarine;
        dataPharm1 = Muscarine.Muscarine;
        dataControl = Muscarine.Control;
    otherwise
        error('Unknown first pharmacology: %s', pharm1);
end

%% Initialize summary
DataSum.Control = dataControl;
DataSum.(pharm1) = dataPharm1;

%% If second pharmacology is selected
if ~isempty(pharm2)
    % Build combined field name: e.g., AgaTK_CdCl2
    combinedField = sprintf('%s_%s', pharm1, pharm2);

    % Make sure the field exists
    if isfield(structPharm1, combinedField)
        dataPharm2 = structPharm1.(combinedField);
    else
        error('Field "%s" not found in struct "%s".', combinedField, pharm1);
    end

    % Store in summary
    DataSum.(combinedField) = dataPharm2;

    % Optional: assign to base for debugging
    assignin('base','dataStructPharm2',dataPharm2);
end

% Assign overall summary to base
assignin('base','DataSum',DataSum);

end
