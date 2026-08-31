function MINIS_plotBaselineValidation(Data, S, conditions, color, figureFolder)
% MINIS_plotBaselineValidation
%
% Validate Gaussian baseline fits using ONLY the stable trials selected in
% MINIS_selectStableTrials.
%
% Validation is performed for:
%   S.controlCondition
%   S.washCondition
%
% This function does NOT recalculate the Gaussian fits.
% It uses the exact fits stored in:
%
%   Data.(cond).stableTrialBaselineFits
%
% and the exact traces used for those fits:
%
%   Data.(cond).stableMiniData
%
% Outputs:
%   1) Summary figure:
%        - baseline mu vs experimental time
%        - Gaussian sigma vs experimental time
%        - fit R^2 vs experimental time
%
%   2) Detailed figures:
%        - trace + fitted baseline
%        - histogram + Gaussian fit
%
% Detailed figures are split across pages to keep them readable.


%% =========================================================
% CONDITIONS TO VALIDATE
% ==========================================================

validationConditions = { ...
    S.controlCondition, ...
    S.washCondition};

% Number of trials shown per detailed figure
trialsPerFigure = 6;

%% =========================================================
% SUMMARY FIGURE
% ==========================================================

figSummary = figure( ...
    'Color','w', ...
    'Position',[150 100 1200 750]);

t = tiledlayout(figSummary,3,1, ...
    'TileSpacing','compact', ...
    'Padding','compact');


axMu = nexttile(t);
hold(axMu,'on'); 

axSigma = nexttile(t);
hold(axSigma,'on');

axR2 = nexttile(t);
hold(axR2,'on');


for c = 1:numel(validationConditions)
    cond = validationConditions{c};

    % Find this condition's color from the original conditions list
    condIdx = find(strcmp(conditions,cond),1);

    if isempty(condIdx)
        error('Condition %s was not found in conditions.',cond);
    end

    condColor = color{condIdx};
    tm = Data.(cond).stableTrialTimeMin;

    %% Baseline mu

    plot(axMu, ...
        tm, ...
        Data.(cond).stableBaselineCurrent, ...
        '-o', ...
        'Color',condColor, ...
        'MarkerFaceColor',condColor, ...
        'LineWidth',1.2, ...
        'DisplayName',strrep(cond,'_','/'));

    %% Gaussian sigma
    plot(axSigma, ...
        tm, ...
        Data.(cond).stableBaselineSigma, ...
        '-o', ...
        'Color',condColor, ...
        'MarkerFaceColor',condColor, ...
        'LineWidth',1.2);

    %% R squared
    plot(axR2, ...
        tm, ...
        Data.(cond).stableBaselineFitR2, ...
        '-o', ...
        'Color',condColor, ...
        'MarkerFaceColor',condColor, ...
        'LineWidth',1.2);
end

%% Format summary figure
title(t,'Stable-Trial Gaussian Baseline Validation');

ymin = round(min(Data.(cond).stableBaselineCurrent));
ymin = ymin*1.3;
ylim(axMu,[ymin 0])

ymax = round(max(Data.(cond).stableBaselineSigma));
ymax = ymax*1.5;
ylim(axSigma,[0 ymax])

ylim(axR2,[0.8 1.2])

ylabel(axMu,'Baseline \mu (pA)');
ylabel(axSigma,'Gaussian \sigma (pA)');
ylabel(axR2,'Fit R^2');
xlabel(axR2,'Experimental time (min)');

legend(axMu,'Location','best');

linkaxes([axMu axSigma axR2],'x');

set([axMu axSigma axR2],'Box','off');


%% Save summary figure

if nargin >= 5 && ~isempty(figureFolder)

    saveas(figSummary, ...
        fullfile(figureFolder, ...
        'Stable Baseline Fit Summary.fig'));

    saveas(figSummary, ...
        fullfile(figureFolder, ...
        'Stable Baseline Fit Summary.png'));

end


%% =========================================================
% DETAILED TRACE + HISTOGRAM VALIDATION
% ==========================================================

for c = 1:numel(validationConditions)

    cond = validationConditions{c};

    trialNames = Data.(cond).stableTrialNames;
    trialTimes = Data.(cond).stableTrialTimeMin;
    miniData = Data.(cond).stableMiniData;
    baselineFits = Data.(cond).stableTrialBaselineFits;

    nTrials = numel(trialNames);


    % Find condition color
    condIdx = find(strcmp(conditions,cond),1);
    condColor = color{condIdx};


    %% Determine number of pages

    nPages = ceil(nTrials/trialsPerFigure);


    for page = 1:nPages

        firstTrial = ...
            (page-1)*trialsPerFigure + 1;

        lastTrial = ...
            min(page*trialsPerFigure,nTrials);

        trialIdx = firstTrial:lastTrial;

        nThisPage = numel(trialIdx);


        %% Create figure

        fig = figure( ...
            'Color','w', ...
            'Position',[50 30 1500 950], ...
            'Name',sprintf('%s Baseline Validation Page %d', ...
                cond,page), ...
            'NumberTitle','off');


        tl = tiledlayout(fig,nThisPage,2, ...
            'TileSpacing','compact', ...
            'Padding','compact');


        title(tl, ...
            sprintf('%s Stable Baseline Fits — Page %d/%d', ...
            strrep(cond,'_','/'),page,nPages), ...
            'Interpreter','none');


        %% ---------------------------------------------
        % Plot each stable trial
        % ----------------------------------------------

        for j = 1:nThisPage

            k = trialIdx(j);

            trial = miniData(:,k);
            fit = baselineFits{k};

            time = ...
                (0:numel(trial)-1) / S.Fs;


            %% =========================================
            % LEFT: TRACE
            % ==========================================

            axTrace = nexttile(tl);
            hold(axTrace,'on');


            plot(axTrace, ...
                time, ...
                trial, ...
                'Color',condColor, ...
                'LineWidth',0.6);


            % Gaussian-derived baseline
            yline(axTrace, ...
                fit.mu, ...
                '--', ...
                sprintf('\\mu = %.2f pA',fit.mu), ...
                'LineWidth',1.2);


            xlim(axTrace,[0 time(end)]);

            ylabel(axTrace,'Current (pA)');

            title(axTrace, ...
                sprintf('%s   |   %.2f min', ...
                trialNames{k},trialTimes(k)), ...
                'Interpreter','none');

            box(axTrace,'off');


            if j == nThisPage
                xlabel(axTrace,'Time (s)');
            end


            %% =========================================
            % RIGHT: HISTOGRAM + GAUSSIAN
            % ==========================================

            axHist = nexttile(tl);
            hold(axHist,'on');


            % Full all-points histogram
            bar(axHist, ...
                fit.centers, ...
                fit.pointFreq, ...
                1, ...
                'FaceColor',[0.8 0.8 0.8], ...
                'EdgeColor','none');


            % Full fitted symmetric Gaussian
            plot(axHist, ...
                fit.centers, ...
                fit.gaussianCounts, ...
                '-', ...
                'Color',condColor, ...
                'LineWidth',1.8);


            % Histogram points that actually contributed to the fit
            plot(axHist, ...
                fit.xFit, ...
                fit.yFit, ...
                'o', ...
                'Color',condColor, ...
                'MarkerSize',3);


            %% Important x positions

            % Histogram mode
            xline(axHist,fit.peakCurrent,':', 'LineWidth',1)

            % Beginning of Gaussian fitting region
            xline(axHist, fit.fitStartCurrent,'--','LineWidth',1);

            % Gaussian center = estimated holding current
            xline(axHist, ...
                fit.mu, ...
                '-.', ...
                '\mu', ...
                'LineWidth',1.2);


            ylabel(axHist,'Point count');

            title(axHist, ...
                sprintf('\\mu = %.2f pA   \\sigma = %.2f pA   R^2 = %.3f', ...
                fit.mu, ...
                fit.sigma, ...
                fit.R2));


            box(axHist,'off');


            if j == nThisPage
                xlabel(axHist,'Current (pA)');
            end

        end


        %% ---------------------------------------------
        % Save detailed page
        % ----------------------------------------------

        if nargin >= 5 && ~isempty(figureFolder)

            fileBase = sprintf( ...
                '%s Stable Baseline Validation Page %d', ...
                cond,page);


            saveas(fig, ...
                fullfile(figureFolder, ...
                [fileBase '.fig']));


            saveas(fig, ...
                fullfile(figureFolder, ...
                [fileBase '.png']));

        end

    end

end

end