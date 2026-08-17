function Data = MINIS_calculateTrialMetrics(Data, S, conditions)
% For every QC-passed trial:
%   - calculate all-point mean current over the 19.9-s mini trace
%   - estimate holding current from the final 1 s using Gaussian fit
%   - calculate series resistance from the test-pulse peak
%   - calculate steady-state total resistance and corrected input resistance

firstTrialNum = findFirstTrialNum(Data, conditions);

for c = 1:numel(conditions)
    cond = conditions{c};

    if ~isfield(Data.(cond),'QCTrialNames')
        error('Run MINIS_deleteTrials before MINIS_calculateTrialMetrics.');
    end

    trialNames = Data.(cond).QCTrialNames;
    trialNums = Data.(cond).QCTrialNums;
    allTrials = Data.(cond).finalMiniData;
    nTrials = numel(trialNames);

    meanCurrent = nan(1,nTrials);
    baselineCurrent = nan(1,nTrials);
    baselineSigma = nan(1,nTrials);
    baselineFitR2 = nan(1,nTrials);
    Rs = nan(1,nTrials);
    Rtotal = nan(1,nTrials);
    Rin = nan(1,nTrials);
    Ipeak = nan(1,nTrials);
    Iss = nan(1,nTrials);
    trialTimeMin = nan(1,nTrials);
    baselineFits = cell(1,nTrials);

    for k = 1:nTrials
        trace = allTrials(:,k);
        meanCurrent(k) = mean(trace,'omitnan');

        % Last 1 s immediately before the -5 mV test pulse.
        if numel(trace) < S.baselineSamples
            error('Trial %s is shorter than the requested baseline window.', trialNames{k});
        end
        baselineSegment = trace(end-S.baselineSamples+1:end);
        fit = MINIS_fitBaseline(baselineSegment, S);
        baselineFits{k} = fit;
        baselineCurrent(k) = fit.mu;
        baselineSigma(k) = fit.sigma;
        baselineFitR2(k) = fit.R2;

        % Pull the seal test directly from the raw AD0 trace so trial identity
        % cannot become misaligned after manual QC exclusions.
        rawTrace = Data.(cond).(trialNames{k});
        if numel(rawTrace) < S.sealEndIdx
            error('Raw trial %s does not contain the expected test pulse.', trialNames{k});
        end
        seal = rawTrace(S.sealStartIdx:S.sealEndIdx);

        peakSearchN = min(numel(seal), max(3, round(S.testPeakSearchMs/1000*S.Fs)));
        if S.testPulse_mV < 0
            [~,peakIdx] = min(seal(1:peakSearchN));
        else
            [~,peakIdx] = max(seal(1:peakSearchN));
        end

        halfWidth = floor(S.testPeakAverageSamples/2);
        peakRange = max(1,peakIdx-halfWidth):min(numel(seal),peakIdx+halfWidth);
        Ipeak(k) = mean(seal(peakRange),'omitnan');

        steadyN = max(1, round(S.testSteadyWindowMs/1000*S.Fs));
        steadyRange = max(1,numel(seal)-steadyN+1):numel(seal);
        Iss(k) = mean(seal(steadyRange),'omitnan');

        deltaIpeak = Ipeak(k) - baselineCurrent(k);
        deltaIss = Iss(k) - baselineCurrent(k);

        % mV / pA * 1000 = MOhm
        Rs(k) = 1000 * abs(S.testPulse_mV / deltaIpeak);
        Rtotal(k) = 1000 * abs(S.testPulse_mV / deltaIss);

        % For a series access resistance followed by the membrane resistance,
        % the steady-state voltage-step resistance is Rs + Rin.
        Rin(k) = Rtotal(k) - Rs(k);

        % Plot each 19.9-s mean/baseline point near the center of its acquisition.
        trialTimeMin(k) = ((trialNums(k)-firstTrialNum)*S.trialStartIntervalSec ...
            + S.miniDurationSec/2) / 60;
    end

    Data.(cond).meanCurrent = meanCurrent;
    Data.(cond).baselineCurrent = baselineCurrent;
    Data.(cond).baselineSigma = baselineSigma;
    Data.(cond).baselineFitR2 = baselineFitR2;
    Data.(cond).Rs = Rs;
    Data.(cond).Rtotal = Rtotal;
    Data.(cond).Rin = Rin;
    Data.(cond).testPulsePeakCurrent = Ipeak;
    Data.(cond).testPulseSteadyCurrent = Iss;
    Data.(cond).trialTimeMin = trialTimeMin;
    Data.(cond).trialBaselineFits = baselineFits;

    Data.(cond).trialMetrics = table( ...
        trialNums(:), trialNames(:), trialTimeMin(:), meanCurrent(:), ...
        baselineCurrent(:), baselineSigma(:), baselineFitR2(:), ...
        Rs(:), Rtotal(:), Rin(:), ...
        'VariableNames', {'TrialNum','TrialName','TimeMin','AllPointMean_pA', ...
        'Baseline_pA','NoiseSigma_pA','BaselineFitR2','Rs_MOhm', ...
        'Rtotal_MOhm','Rin_MOhm'});
end
end

function firstTrialNum = findFirstTrialNum(Data, conditions)
allNums = [];
for c = 1:numel(conditions)
    [~,nums] = MINIS_getTrialInfo(Data, conditions{c});
    allNums = [allNums; nums(:)]; %#ok<AGROW>
end
firstTrialNum = min(allNums);
end
