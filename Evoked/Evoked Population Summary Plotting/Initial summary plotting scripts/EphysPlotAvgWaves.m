function EphysPlotAvgWaves(DataSum, numConds, pharm1, varargin)
temp = load('Colors.mat');
colors = temp.colors;
clear temp

temp = load('TrialTime_sec.mat');
TrialTime = temp.TrialTime;
clear temp
if ~isempty(varargin)
    pharm2 = varargin{1};
    pharm2 = sprintf('%s_%s', pharm1, pharm2);
    pharmConds = {'Control', pharm1, pharm2};
else
    pharmConds = {'Control', pharm1};
end

color = cell(1, numConds);  % initialize color cell array
color{1} = colors.gray;         

if numConds >= 2
    if strcmp(pharmConds{2}, 'AgaTK')
        color{2} = colors.Aga;
    elseif strcmp(pharmConds{2}, 'ConoGVIA')
        color{2} = colors.Cono;
    elseif strcmp(pharmConds{2}, 'Muscarine')
        color{2} = colors.Muscarine;
    end
end

if numConds == 3
    if contains(pharmConds{3}, 'CdCl2')
        color{3} = colors.CdCl2;
    elseif contains(pharmConds{3}, 'ConoGVIA')
        color{3} = colors.Cono;
    elseif contains(pharmConds{3}, 'Muscarine')
        color{3} = colors.Muscarine;
    elseif contains(pharmConds{3}, 'AgaTK')
        color{3} = colors.Aga;
    else, color{3} = colors.black;
    end
end

% Plot overlaid traces of conditions
figure('position',[312 127 1365 823]);
Hzs = {'x1', 'x5_5Hz', 'x5_20Hz', 'x5_40Hz'};
displayHzs = {'Single Stim', '5 Hz','20 Hz','40 Hz'};
numCells = size(DataSum.Control.x1.Waves,2);

for j = 1:length(Hzs)
    Hz = Hzs{j};
    displayHz = displayHzs{j};
    nexttile

    for p = 1:numConds
        cond = pharmConds{p};
        hold on

        plot(TrialTime.sec.ephys, DataSum.(cond).(Hz).popAvgWave,'color', color{p},'linewidth',1.5,'DisplayName',cond);
        disp(color{p})
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
        
        sgtitle(sprintf('EPSC Averages, n=%d cells', numCells),'FontWeight','bold')
        title(displayHz)
        ylabel('EPSC (pA)')
        xlabel('Time (sec)')
        
    end
    legend('interpreter','none','location','southeast')
end
%saveas(gcf, fullfile(folder, 'EPSC averages over Hz'))