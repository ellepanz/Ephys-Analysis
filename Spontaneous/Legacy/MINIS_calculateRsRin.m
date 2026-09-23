function Data = MINIS_calculateRsRin(Data,conditions,S,figureFolder,color)
% Calculate baseline-fit and resistance metrics for all experimental conditions.
%
% For every trial remaining after trace QC:
%   - Fit the full mini-current trace to estimate baseline mu, sigma, and R2.
%   - Calculate Rs and Rin from the RAW test pulse.
%
% These metrics are used for stability/QC and stable-trial selection.
% Final synaptic charge/current is calculated later by
% MINIS_calculateHistogramMetrics.

for c = 1:numel(conditions)

    cond = conditions{c};

    trialNames = Data.(cond).notDelTrialNames;
    trialNums = Data.(cond).notDelTrialNums;
    nTrials = numel(trialNames);

    %% MATCH REMAINING TRIALS TO ORIGINAL TRIALS

    [found,originalIdx] = ismember(trialNames,Data.(cond).trialNames);

    if any(~found)
        missingTrials = strjoin(trialNames(~found),', ');
        error('Could not match remaining trials in %s: %s',cond,missingTrials);
    end

    %% PREALLOCATE

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

    %% ANALYZE TRIALS

    for k = 1:nTrials

        %% BASELINE FIT

        trial = Data.(cond).notDelMiniData(:,k);

        fit = MINIS_fitBaseline(trial,S);

        baselineFits{k} = fit;
        baselineCurrent(k) = fit.mu;
        baselineSigma(k) = fit.sigma;
        baselineFitR2(k) = fit.R2;

        %% RAW TEST PULSE

        idx = originalIdx(k);

        rawTrace = Data.rawTraces.(cond).(trialNames{k});
        rawTrace = rawTrace(:);

        % Mean current during 5 ms immediately before test-pulse onset.
        baselineN = round(5/1000*S.Fs);
        baselineRange = (S.sealStartIdx-baselineN):(S.sealStartIdx-1);

        Ibaseline(k) = mean(rawTrace(baselineRange),'omitnan');

        % Pull test pulse directly from raw trace.
        seal = rawTrace(S.sealStartIdx:S.sealEndIdx);

        % Find capacitive peak during initial search window.
        peakSearchN = min( ...
            round(S.testPeakSearchMs/1000*S.Fs), ...
            numel(seal));

        [~,peakIdx] = min(seal(1:peakSearchN));
        Ipeak(k) = seal(peakIdx);

        % Steady-state current from final part of test pulse.
        steadyN = min( ...
            round(S.testSteadyWindowMs/1000*S.Fs), ...
            numel(seal));

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

    Data.(cond).trialMetrics = table( ...
        trialNums(:), ...
        trialNames(:), ...
        baselineCurrent(:), ...
        baselineSigma(:), ...
        baselineFitR2(:), ...
        Rs(:), ...
        Rtotal(:), ...
        Rin(:), ...
        'VariableNames',{ ...
        'TrialNum', ...
        'TrialName', ...
        'Baseline_pA', ...
        'NoiseSigma_pA', ...
        'BaselineFitR2', ...
        'Rs_MOhm', ...
        'Rtotal_MOhm', ...
        'Rin_MOhm'});

end

%% PLOT Rs AND Rin ACROSS ENTIRE EXPERIMENT

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

    plot(axRs, ...
        Data.(cond).notDelTrialNums, ...
        Data.(cond).Rs, ...
        'o-', ...
        'LineWidth',1, ...
        'MarkerFaceColor',color{c}, ...
        'Color',color{c}, ...
        'DisplayName',strrep(cond,'_','/'));

    plot(axRin, ...
        Data.(cond).notDelTrialNums, ...
        Data.(cond).Rin, ...
        'o-', ...
        'LineWidth',1, ...
        'MarkerFaceColor',color{c}, ...
        'Color',color{c}, ...
        'DisplayName',strrep(cond,'_','/'));

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

%% SAVE

if nargin >= 4 && ~isempty(figureFolder)

    savefig(fig, ...
        fullfile(figureFolder,'Rs Rin Stability.fig'));

    exportgraphics(fig, ...
        fullfile(figureFolder,'Rs Rin Stability.png'), ...
        'Resolution',300);

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