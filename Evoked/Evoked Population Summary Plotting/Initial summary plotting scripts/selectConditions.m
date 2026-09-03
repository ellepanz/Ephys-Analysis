function selectConditions
% Creates a uifigure to choose pharmacology/plots, calls Datasum to pull
% relevant data, then uses the nested function saveSelections to call selected plotting functions

fig = uifigure('Position',[858 409 189 559]);

xLeft = 23; labelWidth = 180; labelHeight = 22; cbWidth = 120; cbHeight = 22;
vSpace = 28; yTop = 530;

%% First pharmacology
uilabel(fig,'Text','First condition:',...
    'Position',[xLeft yTop labelWidth labelHeight],'FontWeight','bold');
firstPharm = {'AgaTK','ConoGVIA','Muscarine'};
yPos = yTop - vSpace;
cb1 = gobjects(1,numel(firstPharm));
for k = 1:numel(firstPharm)
    cb1(k) = uicheckbox(fig,'Text',firstPharm{k},...
        'Position',[xLeft yPos cbWidth cbHeight]);
    yPos = yPos - vSpace;
end

%% Second pharmacology
uilabel(fig,'Text','Second pharmacology:',...
    'Position',[xLeft yPos-5 labelWidth labelHeight],'FontWeight','bold');
yPos = yPos - vSpace - 5;
secondPharm = {'AgaTK','ConoGVIA','CdCl2','Muscarine','AMN082','10uM AMN082','100uM AMN082'};
cb2 = gobjects(1,numel(secondPharm));
for k = 1:numel(secondPharm)
    cb2(k) = uicheckbox(fig,'Text',secondPharm{k},...
        'Position',[xLeft yPos cbWidth cbHeight]);
    yPos = yPos - vSpace;
end

%% Plots selection
uilabel(fig,'Text','Select Plots to Generate',...
    'Position',[xLeft yPos labelWidth labelHeight],'FontWeight','bold');
yPos = yPos - vSpace;

% Add new checkbox for EPSC Trains
plotChecks = {'Average Waves','PPRs','Peaks over Time','Peaks per Condition', 'EPSC Trains'};
cbPlots = gobjects(1,numel(plotChecks));
for k = 1:numel(plotChecks)
    cbPlots(k) = uicheckbox(fig,'Text',plotChecks{k},...
        'Position',[xLeft yPos cbWidth cbHeight]);
    yPos = yPos - vSpace;
end

%% Plot button
uibutton(fig,'Text','Plot!','Position',[xLeft+40 yPos 88 28],...
    'ButtonPushedFcn', @saveSelections);

%% ---- Nested Function ----
    function saveSelections(~,~)
        % Collect selected pharmacologies
        selPharm1 = string({cb1([cb1.Value]).Text});
        selPharm2 = string({cb2([cb2.Value]).Text});
        selectedPlots = string({cbPlots([cbPlots.Value]).Text});

        % Initialize condList
        condList = {'Control'};

        % Add first pharmacology alone
        condList = [condList, selPharm1];

        % Build combined condition list
        for i = 1:numel(selPharm1)
            for j = 1:numel(selPharm2)
                condList{end+1} = sprintf('%s_%s', selPharm1(i), selPharm2(j));
            end
        end

        % ---- CALL DATASUM ----
        for i = 1:numel(selPharm1)
            if isempty(selPharm2)
                Datasum(selPharm1(i));
            else
                Datasum(selPharm1(i), selPharm2);
            end
        end

        % Fetch DataSum from base workspace
        DataSum = evalin('base','DataSum');

        % ---- CALL PLOTS BASED ON CHECKBOXES ----
        for k = 1:numel(selectedPlots)
            switch selectedPlots(k)
                case "Average Waves"
                    plotSummaryTraces(DataSum, condList);
                case "PPRs"
                    compilePPRs(DataSum, condList);
                case "Peaks per Condition"
                    calcCondPeaks(DataSum, condList);
                case "EPSC Trains"
                    plotEPSCTrains(DataSum, condList);
                case 'Peaks over Time'
                    calcEPSCpeaks(DataSum, condList);

            end
        end

        % Close GUI
        delete(fig);
    end

end  % closes selectConditions
