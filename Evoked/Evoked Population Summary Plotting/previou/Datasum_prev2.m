% Overall EPSC summary: v1 7/10/25
% v2: 7/10, added a section to compile avg peaks
% v3: Changed to function to run within summary plots script 8/12/25
% 9/28/25: trying to update this again to be a summarizing/plotting
% function? so lost

function Datasum(pharm1, varargin)

% Load first pharmacology data
switch pharm1
    case "AgaTK"
        load('EPSCsAgaTK.mat'); % variable inside: EPSCsAgaTK
        dataPharm1 = AgaTK.AgaTK;
        dataControl = AgaTK.Control;
    case "ConoGVIA"
        load('EPSCsConoGVIA.mat');
        dataPharm1 = ConoGVIA.ConoGVIA;
        dataControl = ConoGVIA.Control;
    case "Muscarine"
        load('EPSCsMuscarine.mat');
        dataPharm1 = Muscarine;
        dataControl = Muscarine.Control;strc
end

DataSum.Control = dataControl;
DataSum.(pharm1) = dataPharm1;

% If second pharmacology selected
if ~isempty(varargin)
    % First drug (struct name)
    pharm1 = char(pharm1);   % ensure string → char
    
    % Second drug (suffix)
    drug2 = char(varargin{1});

    % Build combined field name
    pharm2 = sprintf('%s_%s', pharm1, drug2);

    % Get the struct for pharm1 from the base workspace
    structPharm1 = evalin('base', pharm1);

    % Dynamically index pharm2 inside pharm1
    if isfield(structPharm1, pharm2)
        dataPharm2 = structPharm1.(pharm2);
    else
        error('Field "%s" not found in struct "%s".', pharm2, pharm1);
    end

    % Store result
    DataSum.(pharm2) = dataPharm2;

    % Push back to base
    assignin('base','DataSum',DataSum); 
    assignin('base','dataStructPharm2',dataPharm2);
end



if ~isempty(varargin)
    pharm2 = varargin{1};
    switch pharm2
        case "AgaTK"
            pharm2 = sprintf('%s_%s', pharm1, pharm2);
            dataPharm2 = (pharm1).(pharm2);
        case "ConoGVIA"
            pharm2 = sprintf('%s_%s', pharm1, pharm2);
            dataPharm2 = dataPharm1.(pharm2);
        case "CdCl2"
            pharm2 = sprintf('%s_%s', pharm1, pharm2);
            dataPharm2 = dataPharm1.(pharm2);
        case "Muscarine"
            pharm2 = sprintf('%s_%s', pharm1, pharm2);
            dataPharm2 = dataPharm1.(pharm2);
        case "AMN082"
            pharm2 = sprintf('%s_%s', pharm1, pharm2);
            dataPharm2 = dataPharm1.(pharm2);
        case "10uM AMN082"
            pharm2 = sprintf('%s_%s', pharm1, pharm2);
            dataPharm2 = dataPharm1.(pharm2);
        case "100uM AMN082"
            pharm2 = sprintf('%s_%s', pharm1, pharm2);
            dataPharm2 = dataPharm1.(pharm2);
    end

    assignin('base','dataStructPharm2',dataPharm2);

DataSum.(pharm2) = dataPharm2;
    assignin('base','DataSum',DataSum); 
end
