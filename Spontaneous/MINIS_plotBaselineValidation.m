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

%% SUMMARY FIGURE

analysisDurationSec = S.miniDurationSec;
analysisSamples = S.miniSamples;

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
currentFits = struct;

for c = 1:numel(validationConditions)
    cond = validationConditions{c};

    if ~isfield(Data.(cond),'stableMiniData') || ~isfield(Data.(cond),'stableTrialNames')
        error('Stable trials have not been selected for condition %s.',cond);
    end

    miniData = Data.(cond).stableMiniData;

    if size(miniData,1) < analysisSamples
        error('Data.%s.stableMiniData is shorter than the expected %.1f s.',cond,analysisDurationSec);
    end

    nTrials = size(miniData,2);
    fits = cell(1,nTrials);
    currentMu = nan(1,nTrials);
    currentSigma = nan(1,nTrials);
    currentR2 = nan(1,nTrials);

    for k = 1:nTrials
        fit = MINIS_fitBaseline(miniData(1:analysisSamples,k),S);
        fits{k} = fit;
        currentMu(k) = fit.mu;
        currentSigma(k) = fit.sigma;
        currentR2(k) = fit.R2;
    end

    currentFits.(cond) = fits;

    tm = Data.(cond).stableTrialTimeMin;
    condIdx = find(strcmp(conditions,cond),1);
    condColor = color{condIdx};

    plot(axMu,tm,currentMu,'-o','Color',condColor,'MarkerFaceColor',condColor, ...
        'LineWidth',1.2,'DisplayName',strrep(cond,'_','/'));

    plot(axSigma,tm,currentSigma,'-o','Color',condColor,'MarkerFaceColor',condColor, ...
        'LineWidth',1.2,'HandleVisibility','off');

    plot(axR2,tm,currentR2,'-o','Color',condColor,'MarkerFaceColor',condColor, ...
        'LineWidth',1.2,'HandleVisibility','off');

    excludedMask = false(1,nTrials);

    if isfield(Data.(cond),'baselineSensitivityExcludedTrialNames') && ...
            ~isempty(Data.(cond).baselineSensitivityExcludedTrialNames)
        excludedMask = ismember(string(Data.(cond).stableTrialNames), ...
            string(Data.(cond).baselineSensitivityExcludedTrialNames));
    end

    if any(excludedMask)
        scatter(axMu,tm(excludedMask),currentMu(excludedMask),70,'x', ...
            'MarkerEdgeColor','k','LineWidth',1.7,'HandleVisibility','off');
        scatter(axSigma,tm(excludedMask),currentSigma(excludedMask),70,'x', ...
            'MarkerEdgeColor','k','LineWidth',1.7,'HandleVisibility','off');
        scatter(axR2,tm(excludedMask),currentR2(excludedMask),70,'x', ...
            'MarkerEdgeColor','k','LineWidth',1.7,'HandleVisibility','off');
    end

    allMu = [allMu; currentMu(:)]; %#ok<AGROW>
    allSigma = [allSigma; currentSigma(:)]; %#ok<AGROW>
end

allMu = allMu(isfinite(allMu));
allSigma = allSigma(isfinite(allSigma));

title(t,sprintf('Stable Trial Whole-%.1f-s Baseline Validation, %s', ...
    analysisDurationSec,Expt.marker),'Interpreter','none');

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
    exportgraphics(t,fullfile(figureFolder,'Stable Baseline Fit Summary.png'),'Resolution',300);
end


%% DETAILED TRACE + HISTOGRAM VALIDATION

for c = 1:numel(validationConditions)
    cond = validationConditions{c};
    trialNames = Data.(cond).stableTrialNames;
    trialTimes = Data.(cond).stableTrialTimeMin;
    miniData = Data.(cond).stableMiniData(1:analysisSamples,:);
    baselineFits = currentFits.(cond);

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

            xlim(axTrace,[0 analysisDurationSec]);
            ylabel(axTrace,'Current (pA)');
            isExcluded = false;

            if isfield(Data.(cond),'baselineSensitivityExcludedTrialNames') && ...
                    ~isempty(Data.(cond).baselineSensitivityExcludedTrialNames)
                isExcluded = ismember(string(trialNames{k}), ...
                    string(Data.(cond).baselineSensitivityExcludedTrialNames));
            end

            if isExcluded
                axTrace.Color = [1 0.92 0.92];
                title(axTrace,sprintf('[EXCLUDED FROM WHOLE-TRIAL] %s | %.2f min', ...
                    trialNames{k},trialTimes(k)),'Interpreter','none', ...
                    'Color',[0.75 0 0],'FontWeight','bold');
            else
                title(axTrace,sprintf('%s | %.2f min',trialNames{k},trialTimes(k)), ...
                    'Interpreter','none');
            end

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
            if isExcluded
                axHist.Color = [1 0.92 0.92];
                title(axHist,sprintf('[EXCLUDED] \\mu = %.2f pA   \\sigma = %.2f pA   R^2 = %.3f', ...
                    fit.mu,fit.sigma,fit.R2), ...
                    'Color',[0.75 0 0],'FontWeight','bold');
            else
                title(axHist,sprintf('\\mu = %.2f pA   \\sigma = %.2f pA   R^2 = %.3f', ...
                    fit.mu,fit.sigma,fit.R2));
            end

            box(axHist,'off');

            if j == nThisPage
                xlabel(axHist,'Current (pA)');
            end
        end

        if nargin >= 5 && ~isempty(figureFolder)
            fileBase = sprintf('%s Stable Baseline Validation Page %d',cond,page);
            savefig(fig,fullfile(figureFolder,[fileBase '.fig']));
            exportgraphics(tl,fullfile(figureFolder,[fileBase '.png']),'Resolution',300);
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

end
