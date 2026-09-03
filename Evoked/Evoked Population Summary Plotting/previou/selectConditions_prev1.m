
function selectConditions
% Creates a uifigure with checkboxes to choose which pharmacology/plots you
% want plotted. Calls nested function saveConditions, which calls Datasum
% to execute actual summarizing/plotting


% Create centered figure
fig = uifigure('Position',[800 500 250 500]);

% Vertical spacing parameters
xLeft = 23;
labelWidth = 180;
labelHeight = 22;
cbWidth = 120;
cbHeight = 22;
vSpace = 28;  % vertical spacing between items
yTop = 460;   % starting y position

% First pharmacology
uilabel(fig,'Text','First pharmacology:',...
    'Position',[xLeft yTop labelWidth labelHeight],'FontWeight','bold');

firstPharm = {'AgaTK','ConoGVIA','Muscarine'};
yPos = yTop - vSpace;
cb1 = gobjects(1,numel(firstPharm));
for i = 1:numel(firstPharm)
    cb1(i) = uicheckbox(fig,'Text',firstPharm{i},'Position',[xLeft yPos cbWidth cbHeight]);
    yPos = yPos - vSpace;
end

% Second pharmacology
uilabel(fig,'Text','Second pharmacology:',...
    'Position',[xLeft yPos-5 labelWidth labelHeight],'FontWeight','bold');
yPos = yPos - vSpace - 5;

secondPharm = {'AgaTK','ConoGVIA','CdCl2','Muscarine','AMN082','10uM AMN082','100uM AMN082'};
cb2 = gobjects(1,numel(secondPharm));
for i = 1:numel(secondPharm)
    cb2(i) = uicheckbox(fig,'Text',secondPharm{i},'Position',[xLeft yPos cbWidth cbHeight]);
    yPos = yPos - vSpace;
end

% Plots selection
uilabel(fig,'Text','Select Plots to Generate','Position',[xLeft yPos labelWidth labelHeight],...
    'FontWeight','bold');
yPos = yPos - vSpace;

plotChecks = {'Average Waves','PPRs','Peaks'};
cbPlots = gobjects(1, numel(plotChecks));
for i = 1:numel(plotChecks)
    cbPlots(i) = uicheckbox(fig,'Text',plotChecks{i},'Position',[xLeft yPos cbWidth cbHeight]);
    yPos = yPos - vSpace;
end

% Plot button
uibutton(fig,'Text','Plot!','Position',[xLeft+40 yPos 88 28],...
    'ButtonPushedFcn', @saveSelections);

% ---- Nested Function ----
    function saveSelections(~,~)

        % First condition selections
        pharm1 = {};
        for j = 1:numel(cb1)
            if cb1(j).Value
                pharm1{end+1} = firstPharm{j};
            end
        end

        % Second condition selections
        pharm2 = {};
        for j = 1:numel(cb2)
            if cb2(j).Value
                pharm2{end+1} = secondPharm{j};
            end
        end

        % Plot selections
        selectedPlots = {};
        for j = 1:numel(cbPlots)
            if cbPlots(j).Value
                selectedPlots{end+1} = cbPlots(j).Text;
            end
        end

        % Convert to strings
        pharm1 = string(pharm1);
        if ~isempty(pharm2)
            pharm2 = string(pharm2);
            numConds = 3;
        else
            numConds = 2;
        end

        % Call main function
        if isempty(pharm2)
            DataSum = Datasum(numConds, pharm1, varargin);
        else
            DataSum = Datasum(numConds, pharm1, pharm2);
        end

        % Close the GUI
        delete(fig);
    end
end