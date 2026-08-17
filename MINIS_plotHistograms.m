function MINIS_plotHistograms(Data, S, conditions, color, figureFolder)
% Plot stable concatenated traces and display histograms for Control/Washout.

condsToPlot = {S.controlCondition, S.washCondition};

fig = figure('Color','w','Position',[200 100 1200 750]);
tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');

allTraceData = [];
for i = 1:numel(condsToPlot)
    cond = condsToPlot{i};
    if ~isfield(Data.(cond),'stableConcatData')
        error('No stableConcatData found for %s.',cond);
    end
    allTraceData = [allTraceData; Data.(cond).stableConcatData(:)]; %#ok<AGROW>
end

maxAbsY = max(abs(allTraceData));
if maxAbsY == 0
    maxAbsY = 1;
end
maxAbsY = 1.05*maxAbsY;

histXMin = floor(min(allTraceData)/S.displayBinWidth_pA)*S.displayBinWidth_pA;
histXMax = ceil(max(allTraceData)/S.displayBinWidth_pA)*S.displayBinWidth_pA;

for i = 1:numel(condsToPlot)
    cond = condsToPlot{i};
    c = find(strcmp(conditions,cond),1);
    if isempty(c)
        error('Condition %s is not in the conditions input.',cond);
    end

    % IMPORTANT: load the correct condition inside this plotting loop.
    currentData = Data.(cond).stableConcatData;

    nexttile;
    xSec = (0:numel(currentData)-1)'/S.Fs;
    plot(xSec,currentData,'Color',color{c});
    ylabel('Current (pA)');
    xlabel('Concatenated time (s)');
    ylim([-maxAbsY maxAbsY]);
    title([strrep(cond,'_','/') ' stable trials'],'Interpreter','none');
    box off;

    nexttile;
    histogram(currentData,'BinWidth',S.displayBinWidth_pA, ...
        'FaceColor',color{c});
    xlabel('Current (pA)');
    ylabel('Frequency');
    xlim([histXMin histXMax]);
    title([strrep(cond,'_','/') ' all-points histogram'],'Interpreter','none');
    yl = ylim;
    ylim([0 max(1,yl(2)*1.10)]);
    box off;
end

sgtitle('Stable Trial Concatenation and All-Point Histograms');
MINIS_saveFigure(fig,figureFolder,'Stable concatenated traces and histograms');
end
