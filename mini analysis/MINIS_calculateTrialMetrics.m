function Data = MINIS_calculateTrialMetrics(Data,conditions,S,figureFolder,color)
% Calculate baseline-fit and resistance metrics for all experimental conditions.
%
% Rs and Rin are calculated for every trial remaining after MINI trace QC.
% Test pulses come from Data.(cond).testPulse, created by
% compileEphysData_minis. No separate test-pulse QC is applied.

for c = 1:numel(conditions)
    cond = conditions{c};

    trialNames = Data.(cond).notDelTrialNames;
    trialNums = Data.(cond).notDelTrialNums;
    nTrials = numel(trialNames);

    % testPulse/smthdFullTrace contain all originally compiled trials.
    % Match the remaining trials back to their original columns.
    [found,originalIdx] = ismember(trialNames,Data.(cond).trialNames);

    if any(~found)
        missingTrials = strjoin(trialNames(~found),', ');
        error('Could not match remaining trials in %s: %s',cond,missingTrials);
    end

    baselineCurrent = nan(1,nTrials);
    baselineSigma = nan(1,nTrials);
    baselineFitR2 = nan(1,nTrials);

    Rs = nan(1,nTrials);
    Rtotal = nan(1,nTrials);
    Rin = nan(1,nTrials);

    Ibaseline = nan(1,nTrials);
    Ipeak = nan(1,nTrials);
    Iss = nan(1,nTrials);

    baselineFits = cell(1,nTrials);

    for k = 1:nTrials

        %% BASELINE FIT

        trial = Data.(cond).notDelMiniData(:,k);
        fit = MINIS_fitBaseline(trial,S);

        baselineFits{k} = fit;
        baselineCurrent(k) = fit.mu;
        baselineSigma(k) = fit.sigma;
        baselineFitR2(k) = fit.R2;


        %% TEST PULSE

        idx = originalIdx(k);

        % 5 ms immediately before test-pulse onset
        fullTrace = Data.(cond).smthdFullTrace(:,idx);

        baselineN = round(5/1000*S.Fs);
        baselineRange = (S.sealStartIdx-baselineN):(S.sealStartIdx-1);
        Ibaseline(k) = mean(fullTrace(baselineRange),'omitnan');

        % Compiled/smoothed test pulse
        seal = Data.(cond).testPulse(:,idx);

        peakSearchN = min(round(S.testPeakSearchMs/1000*S.Fs),numel(seal));
        [~,peakIdx] = min(seal(1:peakSearchN));
        Ipeak(k) = seal(peakIdx);

        steadyN = min(round(S.testSteadyWindowMs/1000*S.Fs),numel(seal));
        steadyRange = (numel(seal)-steadyN+1):numel(seal);
        Iss(k) = mean(seal(steadyRange),'omitnan');


        %% Rs / Rin

        deltaIpeak = Ipeak(k)-Ibaseline(k);
        deltaIss = Iss(k)-Ibaseline(k);

        if isfinite(deltaIpeak) && deltaIpeak ~= 0
            Rs(k) = 1000*abs(S.testPulse_mV/deltaIpeak);
        end

        if isfinite(deltaIss) && deltaIss ~= 0 && isfinite(Rs(k))
            Rtotal(k) = 1000*abs(S.testPulse_mV/deltaIss);
            Rin(k) = Rtotal(k)-Rs(k);
        end
    end


    %% SAVE TRIAL METRICS

    Data.(cond).baselineCurrent = baselineCurrent;
    Data.(cond).baselineSigma = baselineSigma;
    Data.(cond).baselineFitR2 = baselineFitR2;
    Data.(cond).trialBaselineFits = baselineFits;

    Data.(cond).testPulseBaselineCurrent = Ibaseline;
    Data.(cond).testPulsePeakCurrent = Ipeak;
    Data.(cond).testPulseSteadyCurrent = Iss;

    Data.(cond).Rs = Rs;
    Data.(cond).Rtotal = Rtotal;
    Data.(cond).Rin = Rin;

    Data.(cond).trialMetrics = table(trialNums(:),trialNames(:),baselineCurrent(:), ...
        baselineSigma(:),baselineFitR2(:),Rs(:),Rtotal(:),Rin(:), ...
        'VariableNames',{'TrialNum','TrialName','Baseline_pA','NoiseSigma_pA', ...
        'BaselineFitR2','Rs_MOhm','Rtotal_MOhm','Rin_MOhm'});
end


%% PLOT Rs AND Rin ACROSS THE ENTIRE EXPERIMENT

fig = figure('Color','w','Position',[200 100 900 650]);
t = tiledlayout(fig,2,1,'TileSpacing','compact','Padding','compact');

axRs = nexttile(t);
hold(axRs,'on');

axRin = nexttile(t);
hold(axRin,'on');

allRs = [];
allRin = [];

for c = 1:numel(conditions)
    cond = conditions{c};

    plot(axRs,Data.(cond).notDelTrialNums,Data.(cond).Rs,'o-','LineWidth',1, ...
        'MarkerFaceColor',color{c},'Color',color{c},'DisplayName',strrep(cond,'_','/'));

    plot(axRin,Data.(cond).notDelTrialNums,Data.(cond).Rin,'o-','LineWidth',1, ...
        'MarkerFaceColor',color{c},'Color',color{c},'DisplayName',strrep(cond,'_','/'));

    allRs = [allRs; Data.(cond).Rs(:)];
    allRin = [allRin; Data.(cond).Rin(:)];
end

allRs = allRs(isfinite(allRs));
allRin = allRin(isfinite(allRin));

ylim(axRs,[0 paddedPositiveMax(allRs)]);
ylim(axRin,[0 paddedPositiveMax(allRin)]);

ylabel(axRs,'R_s (M\Omega)');
ylabel(axRin,'R_{in} (M\Omega)');
xlabel(axRin,'Trial number');

title(axRs,'Series Resistance');
title(axRin,'Input Resistance');

legend(axRs,'Location','best');
legend(axRin,'Location','best');

box(axRs,'off');
box(axRin,'off');

if nargin >= 4 && ~isempty(figureFolder)
    savefig(fig,fullfile(figureFolder,'Rs Rin Stability.fig'));
    exportgraphics(fig,fullfile(figureFolder,'Rs Rin Stability.png'),'Resolution',300);
end

end


function ymax = paddedPositiveMax(vals)

if isempty(vals)
    ymax = 1;
else
    ymax = 1.5*max(abs(vals));

    if ~isfinite(ymax) || ymax <= 0
        ymax = 1;
    end
end

end