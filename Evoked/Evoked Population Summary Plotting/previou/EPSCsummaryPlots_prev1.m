% v1: 7/14/25

%% 
folder = "C:\Users\Lauren Panzera\Cardin-Higley Lab Dropbox\HigleyLab Team Folder\Lauren\Data Summaries";
currentfolder = "C:\Users\Lauren Panzera\Cardin-Higley Lab Dropbox\HigleyLab Team Folder\Lauren\Data Summaries\Current";
Hzs = {'x1', 'Hz5', 'Hz20', 'Hz40'};
displayHzs = {'Single Stim', '5 Hz','20 Hz','40 Hz'};

file = sprintf('%s%s', datetime('today'), '_EPSC summaries');
folder = fullfile(folder, file);
mkdir(folder)
addpath(genpath(folder))



%% Compile average traces

selectConditions % GUI with checkboxes to choose drugs


for c = 1:length(conds)+1
    cond = cond{c};

    for h = 1:length(Hzs)
        Hz = Hzs{h};
        waveName = [Hz '_' pharm 'avgWave']; 
        
        numTrials = 11:14;
        % tempMatrix = zeros(14000, numTrials);

        for i = numTrials
            if ~isempty(DataSum.EPSCs.AgaTK(i).(waveName))
            tempMatrix(:, i) = DataSum.EPSCs.AgaTK(i).(waveName);
            end
        end

        waves.AgaTK_AgaTK.(Hz) = tempMatrix;
        if strcmp(pharm, 'AgaTK')
            % take out LP151f, which is spiking with CdCl2
            waves.CdCl2.x1(:,6) = NaN;
            waves.CdCl2.Hz5(:,6) = NaN;
            waves.CdCl2.Hz20(:,6) = NaN;
            waves.CdCl2.Hz40(:,6) = NaN;
        end
        avgdWaves.AgaTK_AgaTK.(Hz) = nanmean(waves.AgaTK_AgaTK.(Hz)(:,11:14),2);
    end


end
            
%% Plot avg traces across Hz

color = cell(1, numel(conds));  % initialize color cell array
color{1} = colors.gray;         

if numel(conds) >= 2
    if strcmp(conds{2}, 'AgaTK')
        color{2} = colors.Aga;
    elseif strcmp(conds{2}, 'ConoGVIA')
        color{2} = colors.Cono;
    elseif strcmp(conds{2}, 'Muscarine')
        color{2} = colors.Muscarine;
    end
end

if numel(conds) >= 3
    if contains(conds{3}, 'CdCl2')
        color{3} = colors.CdCl2;
    elseif strcmp(conds{3}, 'ConoGVIA')
        color{3} = colors.Cono;
    elseif strcmp(conds{3}, 'Muscarine')
        color{3} = colors.Muscarine;
    else, color{3} = colors.black;
    end
end

% Plot overlaid traces
figure('position',[312 127 1365 823]);
for j = 1:length(Hzs)
    Hz = Hzs{j};
    displayHz = displayHzs{j};
    nexttile

    for p = 1:length(conds)
        pharm = conds{p};
        pharmLegend = pharmLegends{p};
        hold on

        plot(TrialTime.sec.ephys, avgdWaves.(pharm).(Hz),'color', color{p},'linewidth',1.5,'DisplayName',pharmLegend);


            switch j
            case 1; xlim([.0800 0.2000]); 
            case 2; xlim([.000 1.10000]); 
            case 3; xlim([.08500 .4000]); 
            case 4; xlim([.0800 .28]);
            end

            % Calculate ylim
            lines = findall(gca, 'Type', 'line');

            % Desired x-range to find minimum of first peaks
            xrange = [0.1050 0.1200];
            allY = [];  % collect y-values within the range
            
            for i = 1:numel(lines)
                x = get(lines(i), 'XData');
                y = get(lines(i), 'YData');
            
                % Keep only y-values within your x-range
                inRange = x >= xrange(1) & x <= xrange(2);
                allY = [allY, y(inRange)];
            end
            
            % Now set Y-limits based on that range
            ymin = min(allY);
            ymax = max(allY);
            % ylim([ymin-100, ymax+40]);  % add buffer
            ylim([-300 50])
        
        sgtitle('EPSC Averages')
        title(displayHz)
        ylabel('EPSC (pA)')
        xlabel('Time (sec)')
        
    end
    legend('interpreter','tex', 'location','southeast')
end
saveas(gcf, fullfile(folder, 'EPSC averages over Hz'))


%% Calculate single stim peaks by condition (plot in prism from peaks variable)
tempMatrix = [];
% for p = 1:length(conds)
    % pharm = conds{p};

        Name = ['AvgPeaks_' pharm]; 
        numTrials = 11:14;

        for i = numTrials
            tempMatrix(:, i) = DataSum.EPSCs.AgaTK(i).(Name).x1;
        end

        peaks.Muscarine = tempMatrix;

        avgdPeaks.Muscarine = nanmean(peaks.Muscarine(:,11:14),1);





%% Normalized EPSC amplitude with trains

w

%% PPR vs ISI

tempMatrix = [];

 for p = 1:(length(conds))-1
     pharm = conds{p};

    for h = 2:length(Hzs)
        Hz = Hzs{h};

        Name = [Hz, '_', pharm, 'PPR']; 
        numTrials = 11:14;

        for i = numTrials
            tempMatrix(i, 1) = DataSum.EPSCs.AgaTK(i).(Name);
        end

        PPR.(pharm).(Hz) = tempMatrix;
    end
 end   


%% EPSC amplitude %change vs delta PPR
% Calculate amplitude  percent change
AgaAmp = [];
AgaControlAmp = [];
ConoAmp = [];
ConoControlAmp = [];
MuscAmp = [];
MuscControlAmp = [];

for i = 1:numel(fieldnames(DataSum.EPSCs))
    pharm = pharms{i};

    for j = 1:length(DataSum.EPSCs.(pharm))
        
        if i == 1
            AgaAmp(j,1) = DataSum.EPSCs.(pharm)(j).AvgPeaks_AgaTK.x1;
            AgaControlAmp(j,1) = DataSum.EPSCs.(pharm)(j).AvgPeaks_Ctrl.x1;
            
           
        elseif i == 2 
            ConoAmp(j,1) = DataSum.EPSCs.(pharm)(j).AvgPeaks_ConoGVIA.x1;
            ConoControlAmp(j,1) = DataSum.EPSCs.(pharm)(j).AvgPeaks_Ctrl.x1;
        elseif i == 3
            MuscAmp(j,1) = DataSum.EPSCs.(pharm)(j).AvgPeaks_Muscarine.x1;
            MuscControlAmp(j,1) = DataSum.EPSCs.(pharm)(j).AvgPeaks_Ctrl.x1;
        end
    end
    end


AgaPercentChg = 100*((AgaAmp-AgaControlAmp)./AgaControlAmp);
ConoPercentChg = 100*((ConoAmp-ConoControlAmp)./ConoControlAmp);
MuscPercentChg = 100*((MuscAmp-MuscControlAmp)./MuscControlAmp);

% Calculate delta PPR
for i = 1:2
    pharm = pharms{i};

    for j = 1:length(DataSum.EPSCs.(pharm))
        
        for h = 2:length(Hzs)
            Hz = Hzs{h};

            if i == 1
                name = [Hz '_' pharm 'PPR'];
                AgaPPR.(Hz)(j,1) = DataSum.EPSCs.(pharm)(j).(name);
                controlname = [Hz '_CtrlPPR'];
                AgaControlPPR.(Hz)(j,1) = DataSum.EPSCs.(pharm)(j).(controlname);

            elseif i == 2
                name = [Hz '_' pharm 'PPR'];
                ConoPPR.(Hz)(j,1) = DataSum.EPSCs.(pharm)(j).(name);
                controlname = [Hz '_CtrlPPR'];
                ConoControlPPR.(Hz)(j,1) = DataSum.EPSCs.(pharm)(j).(controlname);
            end
        end
    end
end

for h = 2:length(Hzs)
    Hz = Hzs{h};

    AgadPPR.(Hz) = AgaPPR.(Hz) - AgaControlPPR.(Hz);
    ConodPPR.(Hz) = ConoPPR.(Hz) - ConoControlPPR.(Hz);
end


%% Plot PPR vs percent change


figure('position', [85 499 1530 379]);

for h = 2:length(Hzs)
    Hz = Hzs{h};
    displayHz = displayHzs{h};

    nexttile
    hold on

    scatter(AgaPercentChg, AgadPPR.(Hz), 50, 'markerFaceColor', colors.Aga, 'MarkerEdgeColor','none');
    scatter(ConoPercentChg, ConodPPR.(Hz), 50, 'MarkerFaceColor', colors.Cono, 'MarkerEdgeColor','none');
    title(displayHz)
    xlabel('Percent Change');
    ylabel('\DeltaPPR');
    ylim([-1.5 1]); 
    
    if h == 2
        legend('AgaTK','Cono-GVIA', 'location','best');
    end
end

saveas(gcf,sprintf('%s/%s', folder, 'PPR vs percent change.png'))
saveas(gcf,sprintf('%s/%s%s', currentfolder, datetime('today'), '_PPR vs percent change.png'))

            
