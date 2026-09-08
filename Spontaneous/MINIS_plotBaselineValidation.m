function MINIS_plotBaselineValidation(Data,S,conditions,color,figureFolder,Expt)
% Validate Gaussian baseline fits for every analyzed condition except NMDA.
%
% Stable trial identities come from MINIS_selectStableTrials. The Gaussian
% fits themselves are pulled from the CURRENT trialBaselineFits using the
% stored stable indices, avoiding stale copied fits after a refit.

validationConditions = getAnalysisConditions(conditions,S);
trialsPerFigure = 6;

if isempty(validationConditions)
    error('No conditions remain for baseline validation.');
end

%% SUMMARY FIGU

figSummary = figure('Color','w','Position',[150 100 1200 750]);
t = tiledlayout(figSummary,3,1,'TileSpacing','compact','Padding','compact');

axMu = nexttile(t);
hold(axMu,'on');

axSigma = nexttile(t);
hold(axSigma,'on');

axR2 = nexttile(t);
hold(axR2,'on');

allMu = [];
allSigma = [];

for c = 1:numel(validationConditions)
    cond = validationConditions{c};

    if ~isfield(Data.(cond),'stableNotDelIdx')
        error('Stable trials have not been selected for condition %s.',cond);
    end

    idx = Data.(cond).stableNotDelIdx;
    tm = Data.(cond).trialTimeMin(idx);

    currentMu = Data.(cond).baselineCurrent(idx);
    currentSigma = Data.(cond).baselineSigma(idx);
    currentR2 = Data.(cond).baselineFitR2(idx);

    condIdx = find(strcmp(conditions,cond),1);
    condColor = color{condIdx};

    plot(axMu,tm,currentMu,'-o','Color',condColor,'MarkerFaceColor',condColor, ...
        'LineWidth',1.2,'DisplayName',strrep(cond,'_','/'));

    plot(axSigma,tm,currentSigma,'-o','Color',condColor,'MarkerFaceColor',condColor, ...
        'LineWidth',1.2,'HandleVisibility','off');

    plot(axR2,tm,currentR2,'-o','Color',condColor,'MarkerFaceColor',condColor, ...
        'LineWidth',1.2,'HandleVisibility','off');

    allMu = [allMu; currentMu(:)];
    allSigma = [allSigma; currentSigma(:)];
end

allMu = allMu(isfinite(allMu));
allSigma = allSigma(isfinite(allSigma));

title(t,sprintf('%s, %s', 'Stable Trial Gaussian Baseline Validation', Expt.marker));

if isempty(allMu)
    ylim(axMu,[-1 0]);
else
    maxAbsMu = max(abs(allMu));
    if maxAbsMu <= 0 || ~isfinite(maxAbsMu)
        maxAbsMu = 1;
    end
    ylim(axMu,[-1.3*maxAbsMu 0]);
end

ylim(axSigma,[0 paddedPositiveMax(allSigma)]);
ylim(axR2,[0.8 1.2]);

ylabel(axMu,'Baseline \mu (pA)');
ylabel(axSigma,'Gaussian \sigma (pA)');
ylabel(axR2,'Fit R^2');
xlabel(axR2,'Experimental time (min)');
legend(axMu,'Location','best');
linkaxes([axMu axSigma axR2],'x');
set([axMu axSigma axR2],'Box','off');

if nargin >= 5 && ~isempty(figureFolder)
    savefig(figSummary,fullfile(figureFolder,'Stable Baseline Fit Summary.fig'));
    exportgraphics(figSummary,fullfile(figureFolder,'Stable Baseline Fit Summary.png'),'Resolution',300);
end


%% DETAILED TRACE + HISTOGRAM VALIDATION


end

for c = 1:numel(validationConditions)
    cond = validationConditions{c};
    idx = Data.(cond).stableNotDelIdx;

    trialNames = Data.(cond).notDelTrialNames(idx);
    trialTimes = Data.(cond).trialTimeMin(idx);
    miniData = Data.(cond).notDelMiniData(:,idx);
    baselineFits = Data.(cond).trialBaselineFits(idx);

    nTrials = numel(trialNames);
    condIdx = find(strcmp(conditions,cond),1);
    condColor = color{condIdx};

    nPages = ceil(nTrials/trialsPerFigure);

    for page = 1:nPages
        firstTrial = (page-1)*trialsPerFigure + 1;
        lastTrial = min(page*trialsPerFigure,nTrials);
        trialIdx = firstTrial:lastTrial;
        nThisPage = numel(trialIdx);

        fig = figure('Color','w','Position',[50 30 1500 950], ...
            'Name',sprintf('%s Baseline Validation Page %d',cond,page),'NumberTitle','off');

        tl = tiledlayout(fig,nThisPage,2,'TileSpacing','compact','Padding','compact');
        title(tl,sprintf('%s Stable Baseline Fits — Page %d/%d', ...
            strrep(cond,'_','/'),page,nPages),'Interpreter','none');

        for j = 1:nThisPage
            k = trialIdx(j);
            trial = miniData(:,k);
            fit = baselineFits{k};
            time = (0:numel(trial)-1)/S.Fs;

            axTrace = nexttile(tl);
            hold(axTrace,'on');

            plot(axTrace,time,trial,'Color',condColor,'LineWidth',0.6);
            yline(axTrace,fit.mu,'--',sprintf('\\mu = %.2f pA',fit.mu),'LineWidth',1.2);

            xlim(axTrace,[0 time(end)]);
            ylabel(axTrace,'Current (pA)');
            title(axTrace,sprintf('%s | %.2f min',trialNames{k},trialTimes(k)),'Interpreter','none');
            box(axTrace,'off');

            if j == nThisPage
                xlabel(axTrace,'Time (s)');
            end

            axHist = nexttile(tl);
            hold(axHist,'on');

            bar(axHist,fit.centers,fit.pointFreq,1,'FaceColor',[0.8 0.8 0.8],'EdgeColor','none');
            plot(axHist,fit.centers,fit.gaussianCounts,'-','Color',condColor,'LineWidth',1.8);
            plot(axHist,fit.xFit,fit.yFit,'o','Color',condColor,'MarkerSize',3);

            xline(axHist,fit.peakCurrent,'--','LineWidth',1);
            xline(axHist,fit.mu,'-.','\mu','LineWidth',1.2);

            ylabel(axHist,'Point count');
            title(axHist,sprintf('\\mu = %.2f pA   \\sigma = %.2f pA   R^2 = %.3f', ...
                fit.mu,fit.sigma,fit.R2));
            box(axHist,'off');

            if j == nThisPage
                xlabel(axHist,'Current (pA)');
            end
        end

        if nargin >= 5 && ~isempty(figureFolder)
            fileBase = sprintf('%s Stable Baseline Validation Page %d',cond,page);
            savefig(fig,fullfile(figureFolder,[fileBase '.fig']));
            exportgraphics(fig,fullfile(figureFolder,[fileBase '.png']),'Resolution',300);
        end
    end
end

end

function validationConditions = getAnalysisConditions(conditions,S)

if isfield(S,'excludedAnalysisConditions')
    excluded = S.excludedAnalysisConditions;
elseif isfield(S,'drugCondition')
    excluded = {S.drugCondition};
else
    excluded = {'NMDA'};
end

mask = ~ismember(lower(string(conditions)),lower(string(excluded)));
validationConditions = conditions(mask);

end

function ymax = paddedPositiveMax(vals)

if isempty(vals)
    ymax = 1;
else
    ymax = 1.1*max(abs(vals));
    if ~isfinite(ymax) || ymax <= 0
        ymax = 1;
    end
end