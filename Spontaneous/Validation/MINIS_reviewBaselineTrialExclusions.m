function [Data,Review] = MINIS_reviewBaselineTrialExclusions(Data,S,conditions,color,Expt)
% Interactively mark SELECTED STABLE trials whose whole-trial baseline is
% unsuitable for the whole-trial histogram analysis.
%
% This function does NOT delete trials and does NOT change stableMiniData.
% The marks are used only by the whole-trial analysis. The 1-s analysis can
% still use the complete selected stable-trial set.
%
% Each displayed trial is analyzed over S.miniDurationSec:
%   - trace on left
%   - whole-trial histogram + Gaussian fit on right
%
% Click either panel to toggle EXCLUDE.
%
% Stored fields:
%   Data.(cond).baselineSensitivityExcludedTrialNames
%   Data.(cond).baselineSensitivityExcludedStableMask
%   Data.(cond).baselineSensitivityReviewDate

analysisConditions = getAnalysisConditions(conditions,S);
analysisDurationSec = S.miniDurationSec;
analysisSamples = S.miniSamples;

trialsPerPage = 6;

if isempty(analysisConditions)
    error('No conditions remain for baseline review.');
end

review = struct;

for c = 1:numel(analysisConditions)
    cond = analysisConditions{c};

    requiredFields = {'stableMiniData','stableTrialNames','stableTrialTimeMin'};

    for f = 1:numel(requiredFields)
        if ~isfield(Data.(cond),requiredFields{f})
            error('Data.%s.%s does not exist.',cond,requiredFields{f});
        end
    end

    if size(Data.(cond).stableMiniData,1) < analysisSamples
        error('Data.%s.stableMiniData is shorter than the expected %.1f s.',cond,analysisDurationSec);
    end

    miniData = Data.(cond).stableMiniData(1:analysisSamples,:);
    nTrials = size(miniData,2);

    review(c).cond = cond;
    review(c).trialNames = string(Data.(cond).stableTrialNames);
    review(c).trialTimes = Data.(cond).stableTrialTimeMin;
    review(c).miniData = miniData;
    review(c).baselineFits = cell(1,nTrials);
    review(c).excluded = false(1,nTrials);

    if numel(review(c).trialNames) ~= nTrials
        error('Data.%s.stableTrialNames does not match stableMiniData columns.',cond);
    end

    for k = 1:nTrials
        review(c).baselineFits{k} = MINIS_fitBaseline(miniData(:,k),S);
    end

    if isfield(Data.(cond),'baselineSensitivityExcludedTrialNames') && ...
            ~isempty(Data.(cond).baselineSensitivityExcludedTrialNames)
        oldExcluded = string(Data.(cond).baselineSensitivityExcludedTrialNames);
        review(c).excluded = ismember(review(c).trialNames,oldExcluded);
    end

    condIdx = find(strcmp(conditions,cond),1);

    if isempty(condIdx)
        error('Condition %s was not found in conditions.',cond);
    end

    review(c).color = color{condIdx};
end

currentCond = 1;
currentPage = 1;
saved = false;
Review = table;

fig = figure('Color','w','Position',[40 20 1550 980], ...
    'Name','Whole-trial Baseline Review','NumberTitle','off', ...
    'CloseRequestFcn',@cancelReview);

renderPage;
uiwait(fig);

if ~saved
    return
end

Condition = strings(0,1);
TrialName = strings(0,1);
TrialTimeMin = zeros(0,1);
Excluded = false(0,1);

for c = 1:numel(analysisConditions)
    cond = review(c).cond;
    mask = review(c).excluded;

    Data.(cond).baselineSensitivityExcludedTrialNames = ...
        cellstr(review(c).trialNames(mask));

    Data.(cond).baselineSensitivityExcludedStableMask = mask;
    Data.(cond).baselineSensitivityReviewDate = datetime('now');

    n = numel(mask);

    Condition = [Condition; repmat(string(cond),n,1)]; %#ok<AGROW>
    TrialName = [TrialName; review(c).trialNames(:)]; %#ok<AGROW>
    TrialTimeMin = [TrialTimeMin; review(c).trialTimes(:)]; %#ok<AGROW>
    Excluded = [Excluded; mask(:)]; %#ok<AGROW>
end

Review = table(Condition,TrialName,TrialTimeMin,Excluded);

fprintf('\nWhole-trial baseline review saved.\n');

for c = 1:numel(analysisConditions)
    names = review(c).trialNames(review(c).excluded);

    fprintf('%s: %d/%d stable trials marked EXCLUDE', ...
        strrep(review(c).cond,'_','/'),numel(names),numel(review(c).trialNames));

    if isempty(names)
        fprintf('.\n');
    else
        fprintf(' -> %s\n',strjoin(names,', '));
    end
end


    function renderPage
        clf(fig);

        cond = review(currentCond).cond;
        nTrials = numel(review(currentCond).trialNames);
        nPages = max(1,ceil(nTrials/trialsPerPage));

        currentPage = min(max(currentPage,1),nPages);

        firstTrial = (currentPage-1)*trialsPerPage + 1;
        lastTrial = min(currentPage*trialsPerPage,nTrials);
        trialIdx = firstTrial:lastTrial;
        nThisPage = numel(trialIdx);

        tl = tiledlayout(fig,nThisPage,2,'TileSpacing','compact','Padding','compact');
        tl.OuterPosition = [0.03 0.09 0.94 0.86];

        marker = "";

        if isfield(Expt,'marker')
            marker = string(Expt.marker);
        end

        title(tl,sprintf('%s | %s | Whole %.1f s | Page %d/%d | Click to toggle EXCLUDE', ...
            marker,strrep(cond,'_','/'),analysisDurationSec,currentPage,nPages),'Interpreter','none');

        for j = 1:nThisPage
            k = trialIdx(j);

            trial = review(currentCond).miniData(:,k);
            fit = review(currentCond).baselineFits{k};
            trialName = review(currentCond).trialNames(k);
            trialTime = review(currentCond).trialTimes(k);
            condColor = review(currentCond).color;
            tSec = (0:numel(trial)-1)/S.Fs;

            axTrace = nexttile(tl);
            hold(axTrace,'on');

            hTrace = plot(axTrace,tSec,trial,'Color',condColor,'LineWidth',0.6);
            hMu = yline(axTrace,fit.mu,'--',sprintf('\\mu = %.2f pA',fit.mu),'LineWidth',1.2);

            xlim(axTrace,[0 analysisDurationSec]);
            ylabel(axTrace,'Current (pA)');
            box(axTrace,'off');

            if j == nThisPage
                xlabel(axTrace,'Time (s)');
            end

            axHist = nexttile(tl);
            hold(axHist,'on');

            hBar = bar(axHist,fit.centers,fit.pointFreq,1, ...
                'FaceColor',[0.8 0.8 0.8],'EdgeColor','none');

            hGauss = plot(axHist,fit.centers,fit.gaussianCounts,'-', ...
                'Color',condColor,'LineWidth',1.8);

            hFit = plot(axHist,fit.xFit,fit.yFit,'o', ...
                'Color',condColor,'MarkerSize',3);

            hFitMu = xline(axHist,fit.mu,'-.','\mu','LineWidth',1.2);

            ylabel(axHist,'Point count');
            box(axHist,'off');

            if j == nThisPage
                xlabel(axHist,'Current (pA)');
            end

            updateTrialAppearance(axTrace,axHist,k,trialName,trialTime,fit);

            clickable = [axTrace; axHist; hTrace; hMu; hBar; hGauss; hFit; hFitMu];

            for q = 1:numel(clickable)
                if isprop(clickable(q),'ButtonDownFcn')
                    clickable(q).ButtonDownFcn = @(~,~)toggleTrial(k);
                end

                if isprop(clickable(q),'HitTest')
                    clickable(q).HitTest = 'on';
                end

                if isprop(clickable(q),'PickableParts')
                    clickable(q).PickableParts = 'all';
                end
            end
        end

        prevEnable = 'on';
        nextEnable = 'on';

        if currentCond == 1 && currentPage == 1
            prevEnable = 'off';
        end

        if currentCond == numel(analysisConditions) && currentPage == nPages
            nextEnable = 'off';
        end

        uicontrol(fig,'Style','pushbutton','String','Previous','Units','normalized', ...
            'Position',[0.03 0.025 0.10 0.04],'Enable',prevEnable,'Callback',@goPrevious);

        uicontrol(fig,'Style','pushbutton','String','Next','Units','normalized', ...
            'Position',[0.14 0.025 0.10 0.04],'Enable',nextEnable,'Callback',@goNext);

        uicontrol(fig,'Style','pushbutton','String','Done / save marks','Units','normalized', ...
            'Position',[0.78 0.025 0.18 0.04],'FontWeight','bold','Callback',@finishReview);

        nExcluded = sum(review(currentCond).excluded);

        uicontrol(fig,'Style','text', ...
            'String',sprintf('%d/%d stable trials marked EXCLUDE in %s', ...
            nExcluded,nTrials,strrep(cond,'_','/')), ...
            'Units','normalized','Position',[0.32 0.025 0.40 0.035], ...
            'BackgroundColor','w','HorizontalAlignment','center');
    end


    function toggleTrial(k)
        review(currentCond).excluded(k) = ~review(currentCond).excluded(k);
        renderPage;
    end


    function updateTrialAppearance(axTrace,axHist,k,trialName,trialTime,fit)
        if review(currentCond).excluded(k)
            axTrace.Color = [1 0.92 0.92];
            axHist.Color = [1 0.92 0.92];

            title(axTrace,sprintf('[EXCLUDE] %s | %.2f min',trialName,trialTime), ...
                'Interpreter','none','Color',[0.75 0 0],'FontWeight','bold');

            title(axHist,sprintf('[EXCLUDE] \\mu = %.2f pA   \\sigma = %.2f pA   R^2 = %.3f', ...
                fit.mu,fit.sigma,fit.R2),'Color',[0.75 0 0],'FontWeight','bold');
        else
            axTrace.Color = 'w';
            axHist.Color = 'w';

            title(axTrace,sprintf('%s | %.2f min',trialName,trialTime), ...
                'Interpreter','none');

            title(axHist,sprintf('\\mu = %.2f pA   \\sigma = %.2f pA   R^2 = %.3f', ...
                fit.mu,fit.sigma,fit.R2));
        end
    end


    function goNext(~,~)
        nTrials = numel(review(currentCond).trialNames);
        nPages = max(1,ceil(nTrials/trialsPerPage));

        if currentPage < nPages
            currentPage = currentPage + 1;
        elseif currentCond < numel(analysisConditions)
            currentCond = currentCond + 1;
            currentPage = 1;
        end

        renderPage;
    end


    function goPrevious(~,~)
        if currentPage > 1
            currentPage = currentPage - 1;
        elseif currentCond > 1
            currentCond = currentCond - 1;
            nTrials = numel(review(currentCond).trialNames);
            currentPage = max(1,ceil(nTrials/trialsPerPage));
        end

        renderPage;
    end


    function finishReview(~,~)
        saved = true;
        uiresume(fig);
        delete(fig);
    end


    function cancelReview(~,~)
        choice = questdlg('Close without saving the trial markings?', ...
            'Cancel baseline review', ...
            'Close without saving','Keep reviewing','Keep reviewing');

        if strcmp(choice,'Close without saving')
            saved = false;
            uiresume(fig);
            delete(fig);
        end
    end

end


function analysisConditions = getAnalysisConditions(conditions,S)

if isfield(S,'excludedAnalysisConditions')
    excluded = S.excludedAnalysisConditions;
elseif isfield(S,'drugCondition')
    excluded = {S.drugCondition};
else
    excluded = {};
end

mask = ~ismember(lower(string(conditions)),lower(string(excluded)));
analysisConditions = conditions(mask);

end
