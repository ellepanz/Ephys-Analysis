function Data = MINIS_analyzeStableData(Data, S, conditions, color, figureFolder)
% Apply the Glykys/Mody-style 1-s analysis to stable Control and Washout.
%
% Each 19.9-s trial is analyzed separately in 1-s epochs. The final 0.9 s
% is not joined to the next trial, avoiding artificial epochs across the
% 10-s inter-trial gap.
%
% Outputs per 1-s epoch:
%   baseline1s_pA          Gaussian center (holding current)
%   noiseSigma1s_pA        Gaussian sigma / RMS-like baseline noise
%   phasicImeanSigned1s_pA mean(raw - Gaussian center)
%   phasicImeanMag1s_pA    absolute magnitude of the above
%   synapticExcessFraction histogram mass above Gaussian on negative side
%
% This method quantifies mean phasic current. It does NOT identify the
% timing/amplitude of individual mIPSC events.

condsToAnalyze = {S.baselineCondition, S.washCondition};
firstTrialNum = findFirstTrialNum(Data,conditions);

fig = figure('Color','w','Position',[150 80 1300 850]);
t = tiledlayout(fig,3,1,'TileSpacing','compact','Padding','compact');
axBase = nexttile(t); hold(axBase,'on');
axPhasic = nexttile(t); hold(axPhasic,'on');
axNoise = nexttile(t); hold(axNoise,'on');

for i = 1:numel(condsToAnalyze)
    cond = condsToAnalyze{i};
    c = find(strcmp(conditions,cond),1);

    trials = Data.(cond).stableMiniData;
    trialNums = Data.(cond).stableTrialNums;
    nFullEpochs = floor(size(trials,1)/S.Fs);
    nTotalEpochs = nFullEpochs * size(trials,2);

    baseline = nan(1,nTotalEpochs);
    sigma = nan(1,nTotalEpochs);
    fitR2 = nan(1,nTotalEpochs);
    phasicSigned = nan(1,nTotalEpochs);
    phasicMag = nan(1,nTotalEpochs);
    excessFrac = nan(1,nTotalEpochs);
    epochTimeMin = nan(1,nTotalEpochs);
    epochTrialNum = nan(1,nTotalEpochs);
    epochInTrial = nan(1,nTotalEpochs);
    epochFits = cell(1,nTotalEpochs);

    q = 0;
    for k = 1:size(trials,2)
        for e = 1:nFullEpochs
            q = q + 1;
            idx = (e-1)*S.Fs + (1:S.Fs);
            segment = trials(idx,k);
            fit = MINIS_fitBaseline(segment,S);

            baseline(q) = fit.mu;
            sigma(q) = fit.sigma;
            fitR2(q) = fit.R2;

            % Mody-style mean phasic current: subtract Gaussian center so
            % symmetric baseline noise sums to ~0; inward IPSCs remain.
            phasicSigned(q) = mean(segment - fit.mu,'omitnan');
            phasicMag(q) = abs(phasicSigned(q));
            excessFrac(q) = fit.synapticExcessFraction;
            epochFits{q} = fit;

            trialStartSec = (trialNums(k)-firstTrialNum)*S.trialStartIntervalSec;
            epochTimeMin(q) = (trialStartSec + (e-0.5)) / 60;
            epochTrialNum(q) = trialNums(k);
            epochInTrial(q) = e;
        end
    end

    Data.(cond).mody1s.baseline_pA = baseline;
    Data.(cond).mody1s.noiseSigma_pA = sigma;
    Data.(cond).mody1s.fitR2 = fitR2;
    Data.(cond).mody1s.phasicImeanSigned_pA = phasicSigned;
    Data.(cond).mody1s.phasicImeanMagnitude_pA = phasicMag;
    Data.(cond).mody1s.synapticExcessFraction = excessFrac;
    Data.(cond).mody1s.timeMin = epochTimeMin;
    Data.(cond).mody1s.trialNum = epochTrialNum;
    Data.(cond).mody1s.epochInTrial = epochInTrial;
    Data.(cond).mody1s.fits = epochFits;

    Data.(cond).mody1s.meanBaseline_pA = mean(baseline,'omitnan');
    Data.(cond).mody1s.meanPhasicImeanMagnitude_pA = mean(phasicMag,'omitnan');
    Data.(cond).mody1s.meanNoiseSigma_pA = mean(sigma,'omitnan');

    plot(axBase,epochTimeMin,baseline,'.-','Color',color{c}, ...
        'DisplayName',strrep(cond,'_','/'));
    plot(axPhasic,epochTimeMin,phasicMag,'.-','Color',color{c});
    plot(axNoise,epochTimeMin,sigma,'.-','Color',color{c});
end

ylabel(axBase,'Baseline (pA)');
ylabel(axPhasic,'|Phasic I_{mean}| (pA)');
ylabel(axNoise,'Gaussian \sigma (pA)');
xlabel(axNoise,'Experimental time (min)');
legend(axBase,'Location','bestoutside');
linkaxes([axBase axPhasic axNoise],'x');
set([axBase axPhasic axNoise],'Box','off');
sgtitle(t,'Glykys/Mody-Style 1-s Analysis of Stable Trials');
MINIS_saveFigure(fig,figureFolder,'Mody 1s baseline phasic Imean noise');

% Diagnostic Gaussian/residual figure: show one good-fit 1-s epoch per condition.
fig2 = figure('Color','w','Position',[250 180 1100 450]);
tiledlayout(fig2,1,2,'TileSpacing','compact','Padding','compact');

for i = 1:numel(condsToAnalyze)
    cond = condsToAnalyze{i};
    c = find(strcmp(conditions,cond),1);
    fits = Data.(cond).mody1s.fits;
    r2 = Data.(cond).mody1s.fitR2;

    % Use a high-quality representative epoch for fit visualization.
    [~,bestIdx] = max(r2);
    f = fits{bestIdx};

    nexttile;
    bar(f.centers,f.counts,1,'FaceColor',color{c},'EdgeColor','none', ...
        'FaceAlpha',0.35); hold on;
    plot(f.centers,f.smoothCounts,'k-','LineWidth',1.2);
    plot(f.centers,f.gaussianCounts,'k--','LineWidth',1.8);
    plot(f.centers,f.synapticExcessCounts,'r-','LineWidth',1.3);
    xline(f.mu,':','LineWidth',1.2);
    xlabel('Current (pA)'); ylabel('Frequency');
    title(sprintf('%s: representative 1-s fit',strrep(cond,'_','/')), ...
        'Interpreter','none');
    legend({'Raw histogram','Smoothed histogram','Gaussian noise model', ...
        'Negative-side excess','Gaussian \mu'},'Location','best');
    box off;
end

sgtitle('Gaussian Baseline Fit and Synaptic Histogram Excess');
MINIS_saveFigure(fig2,figureFolder,'Mody Gaussian fit diagnostics');
end

function firstTrialNum = findFirstTrialNum(Data, conditions)
allNums = [];
for c = 1:numel(conditions)
    [~,nums] = MINIS_getTrialInfo(Data,conditions{c});
    allNums = [allNums; nums(:)]; %#ok<AGROW>
end
firstTrialNum = min(allNums);
end
