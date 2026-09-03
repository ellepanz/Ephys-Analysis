function selectConditions
% Creates a uifigure to choose pharmacology/plots and calls Datasum

fig = uifigure('Position',[800 500 250 500]);

xLeft = 23; labelWidth = 180; labelHeight = 22; cbWidth = 120; cbHeight = 22;
vSpace = 28; yTop = 460;

%% First pharmacology
uilabel(fig,'Text','First pharmacology:','Position',[xLeft yTop labelWidth labelHeight],'FontWeight','bold');
firstPharm = {'AgaTK','ConoGVIA','Muscarine'};
yPos = yTop - vSpace;
cb1 = gobjects(1,numel(firstPharm));
for k = 1:numel(firstPharm)
    cb1(k) = uicheckbox(fig,'Text',firstPharm{k},'Position',[xLeft yPos cbWidth cbHeight]);
    yPos = yPos - vSpace;
end

%% Second pharmacology
uilabel(fig,'Text','Second pharmacology:','Position',[xLeft yPos-5 labelWidth labelHeight],'FontWeight','bold');
yPos = yPos - vSpace - 5;
secondPharm = {'AgaTK','ConoGVIA','CdCl2','Muscarine','AMN082','10uM AMN082','100uM AMN082'};
cb2 = gobjects(1,numel(secondPharm));
for k = 1:numel(secondPharm)
    cb2(k) = uicheckbox(fig,'Text',secondPharm{k},'Position',[xLeft yPos cbWidth cbHeight]);
    yPos = yPos - vSpace;
end

%% Plots selection
uilabel(fig,'Text','Select Plots to Generate','Position',[xLeft yPos labelWidth labelHeight],'FontWeight','bold');
yPos = yPos - vSpace;
plotChecks = {'Average Waves','PPRs','Peaks'};
cbPlots = gobjects(1,numel(plotChecks));
for k = 1:numel(plotChecks)
    cbPlots(k) = uicheckbox(fig,'Text',plotChecks{k},'Position',[xLeft yPos cbWidth cbHeight]);
    yPos = yPos - vSpace;
end

%% Plot button
uibutton(fig,'Text','Plot!','Position',[xLeft+40 yPos 88 28],...
    'ButtonPushedFcn', @saveSelections);

%% ---- Nested Function ----
    function saveSelections(~,~)
        % Collect selections
        pharm1 = string({cb1([cb1.Value]).Text});
        pharm2 = string({cb2([cb2.Value]).Text});
        selectedPlots = string({cbPlots([cbPlots.Value]).Text});
        
        assignin('base','pharm1',pharm1);
        assignin('base','pharm2',pharm2);
        % Call Datasum
        if isempty(pharm2)
            Datasum(pharm1, varargin);
        else
            Datasum(pharm1, pharm2);
        end
        
        % Close GUI
        delete(fig);
    end
end
