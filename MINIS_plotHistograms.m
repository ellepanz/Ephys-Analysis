function MINIS_plotHistograms(Data, color, conditions)

condsToPlot = {'TTX_NBQX','Wash'};

figure('Color','w', ...
    'Position',[200 200 1100 450]);

tiledlayout(2,2, ...
    'TileSpacing','compact', ...
    'Padding','compact');

%% Get shared Y limits for traces
allTraceData = [];

for i = 1:numel(condsToPlot)

    cond = condsToPlot{i};
    currentData = Data.(cond).stableConcatData;

    allTraceData = [allTraceData; currentData(:)];

end

minY = min(allTraceData) * 1.05;
maxY = max(allTraceData) * 1.05;


%% Plot
for i = 1:numel(condsToPlot)

    cond = condsToPlot{i};

    % Find this condition in original conditions list
    c = find(strcmp(conditions,cond));

    % IMPORTANT: reload data for this condition
    currentData = Data.(cond).stableConcatData;

    %% Concatenated trace
    nexttile;

    x = (1:length(currentData))';

    plot(x,currentData, ...
        'Color',color{c});

    ylabel('pA');
    xlabel('Sample');
    ylim([minY maxY]);

    title(strrep(cond,'_','/'), ...
        'Interpreter','none');


    %% Histogram
    nexttile;

    histogram(currentData, ...
        'BinWidth',5, ...
        'FaceColor',color{c});

    xlabel('Current (pA)');
    ylabel('Frequency');

    title(strrep(cond,'_','/'), ...
        'Interpreter','none');

    yl = ylim;
    ylim([0 yl(2)*1.10]);

end

sgtitle('All-Point Current Histograms');

end