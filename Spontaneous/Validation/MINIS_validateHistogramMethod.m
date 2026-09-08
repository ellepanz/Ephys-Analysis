function V = MINIS_validateHistogramMethod(trial,S)
% Compare whole-trial versus 1-s histogram analysis using 0.5- and 1-pA bins.
%
% Exactly the first 19 s are analyzed for every method.
%
% Methods:
%   1. One Gaussian fit to the complete 19-s trace, 0.5-pA bins
%   2. Nineteen independent 1-s fits, 0.5-pA bins
%   3. One Gaussian fit to the complete 19-s trace, 1-pA bins
%   4. Nineteen independent 1-s fits, 1-pA bins
%
% For segmented analysis, the nineteen charges are summed and divided by
% the total 19-s duration to produce one synaptic-current value.

trial = trial(:);

analysisDuration_s = 19;
segmentDuration_s = 1;

analysisN = analysisDuration_s*S.Fs;
segmentN = segmentDuration_s*S.Fs;
nSegments = analysisDuration_s/segmentDuration_s;

if numel(trial) < analysisN
    error('Trial contains only %.2f s. Validation requires 19 s.', ...
        numel(trial)/S.Fs);
end

trial19 = trial(1:analysisN);

binWidths = [0.5 1];

%% RUN ANALYSIS

for b = 1:numel(binWidths)

    binWidth = binWidths(b);

    Stest = S;
    Stest.fitBinWidth_pA = binWidth;

    %% WHOLE 19-S FIT

    wholeFit = MINIS_fitBaseline(trial19,Stest);

    %% NINETEEN 1-S FITS

    segmentFits = cell(nSegments,1);

    segmentMu = nan(nSegments,1);
    segmentSigma = nan(nSegments,1);
    segmentR2 = nan(nSegments,1);
    segmentCharge_pC = nan(nSegments,1);
    segmentCurrent_pA = nan(nSegments,1);

    for e = 1:nSegments

        idx1 = (e-1)*segmentN + 1;
        idx2 = e*segmentN;

        segment = trial19(idx1:idx2);

        segmentFits{e} = MINIS_fitBaseline(segment,Stest);

        segmentMu(e) = segmentFits{e}.mu;
        segmentSigma(e) = segmentFits{e}.sigma;
        segmentR2(e) = segmentFits{e}.R2;
        segmentCharge_pC(e) = segmentFits{e}.synapticCharge_pC;
        segmentCurrent_pA(e) = segmentFits{e}.synapticCurrent_pA;

    end

    %% COMBINE SEGMENT RESULTS

    segmentedCharge_pC = sum(segmentCharge_pC);
    segmentedCurrent_pA = segmentedCharge_pC/analysisDuration_s;
    segmentedMu = mean(segmentMu);

    % Since every segment is exactly 1 s, these should be identical.
    meanSegmentCurrent_pA = mean(segmentCurrent_pA);

    result.binWidth_pA = binWidth;

    result.wholeFit = wholeFit;

    result.segmentFits = segmentFits;
    result.segmentMu = segmentMu;
    result.segmentSigma = segmentSigma;
    result.segmentR2 = segmentR2;
    result.segmentCharge_pC = segmentCharge_pC;
    result.segmentCurrent_pA = segmentCurrent_pA;

    result.segmentedMu = segmentedMu;
    result.segmentedCharge_pC = segmentedCharge_pC;
    result.segmentedCurrent_pA = segmentedCurrent_pA;
    result.meanSegmentCurrent_pA = meanSegmentCurrent_pA;

    result.deltaMu_pA = segmentedMu-wholeFit.mu;
    result.deltaCurrent_pA = segmentedCurrent_pA-wholeFit.synapticCurrent_pA;

    if wholeFit.synapticCurrent_pA ~= 0
        result.percentCurrentDifference = ...
            100*result.deltaCurrent_pA/wholeFit.synapticCurrent_pA;
    else
        result.percentCurrentDifference = NaN;
    end

    fieldName = sprintf('bin_%gpA',binWidth);
    fieldName = strrep(fieldName,'.','_');

    V.(fieldName) = result;

end

V.analysisDuration_s = analysisDuration_s;
V.trial = trial19;

%% SHORT NAMES

r05 = V.bin_0_5pA;
r10 = V.bin_1pA;

%% SUMMARY TABLE

Method = [
    "Whole 19 s"
    "Nineteen 1-s segments"
    "Whole 19 s"
    "Nineteen 1-s segments"
    ];

BinWidth_pA = [
    0.5
    0.5
    1
    1
    ];

HoldingCurrent_pA = [
    r05.wholeFit.mu
    r05.segmentedMu
    r10.wholeFit.mu
    r10.segmentedMu
    ];

SynapticCharge_pC = [
    r05.wholeFit.synapticCharge_pC
    r05.segmentedCharge_pC
    r10.wholeFit.synapticCharge_pC
    r10.segmentedCharge_pC
    ];

SynapticCurrent_pA = [
    r05.wholeFit.synapticCurrent_pA
    r05.segmentedCurrent_pA
    r10.wholeFit.synapticCurrent_pA
    r10.segmentedCurrent_pA
    ];

V.summary = table(Method,BinWidth_pA,HoldingCurrent_pA, ...
    SynapticCharge_pC,SynapticCurrent_pA);

%% PRINT RESULTS

fprintf('\nHISTOGRAM METHOD VALIDATION\n');
fprintf('===========================\n\n');

disp(V.summary)

fprintf('0.5-pA bins\n');
fprintf('-----------\n');
fprintf('Whole 19-s mu:              %.3f pA\n',r05.wholeFit.mu);
fprintf('Mean 1-s mu:                %.3f pA\n',r05.segmentedMu);
fprintf('Mu difference:              %.3f pA\n\n',r05.deltaMu_pA);

fprintf('Whole 19-s current:         %.3f pA\n',r05.wholeFit.synapticCurrent_pA);
fprintf('Segmented current:          %.3f pA\n',r05.segmentedCurrent_pA);
fprintf('Mean of 1-s currents:       %.3f pA\n',r05.meanSegmentCurrent_pA);
fprintf('Current difference:         %.3f pA\n',r05.deltaCurrent_pA);
fprintf('Percent difference:         %.2f %%\n\n',r05.percentCurrentDifference);

fprintf('1-pA bins\n');
fprintf('---------\n');
fprintf('Whole 19-s mu:              %.3f pA\n',r10.wholeFit.mu);
fprintf('Mean 1-s mu:                %.3f pA\n',r10.segmentedMu);
fprintf('Mu difference:              %.3f pA\n\n',r10.deltaMu_pA);

fprintf('Whole 19-s current:         %.3f pA\n',r10.wholeFit.synapticCurrent_pA);
fprintf('Segmented current:          %.3f pA\n',r10.segmentedCurrent_pA);
fprintf('Mean of 1-s currents:       %.3f pA\n',r10.meanSegmentCurrent_pA);
fprintf('Current difference:         %.3f pA\n',r10.deltaCurrent_pA);
fprintf('Percent difference:         %.2f %%\n\n',r10.percentCurrentDifference);

%% FIGURE

time_s = (0:analysisN-1)'/S.Fs;
segmentTime_s = (0.5:1:18.5)';

figure('Color','w','Position',[80 60 1400 1000]);

tiledlayout(3,2,'TileSpacing','compact','Padding','compact');

%% 1. RAW TRACE

nexttile

plot(time_s,trial19)
hold on

for e = 1:nSegments-1
    xline(e,':');
end

xlabel('Time (s)')
ylabel('Current (pA)')
title('First 19 s of trial')
xlim([0 19])
box off

%% 2. WHOLE-TRIAL HISTOGRAM: 0.5-pA BINS

nexttile

bar(r05.wholeFit.centeredCenters,r05.wholeFit.pointFreq,1, ...
    'FaceAlpha',0.25,'EdgeColor','none')
hold on

plot(r05.wholeFit.centeredCenters, ...
    r05.wholeFit.gaussianCounts,'LineWidth',2)

plot(r05.wholeFit.centeredCenters, ...
    r05.wholeFit.synapticExcessCounts,'LineWidth',2)

xline(0,'--')

xlabel('Baseline-subtracted current (pA)')
ylabel('Point count')

title(sprintf(['Whole 19-s fit: 0.5-pA bins\n' ...
    '\\mu = %.2f pA | Synaptic current = %.2f pA'], ...
    r05.wholeFit.mu,r05.wholeFit.synapticCurrent_pA))

legend('Histogram','Gaussian prediction','Synaptic excess', ...
    'Location','best')

box off

%% 3. WHOLE-TRIAL HISTOGRAM: 1-pA BINS

nexttile

bar(r10.wholeFit.centeredCenters,r10.wholeFit.pointFreq,1, ...
    'FaceAlpha',0.25,'EdgeColor','none')
hold on

plot(r10.wholeFit.centeredCenters, ...
    r10.wholeFit.gaussianCounts,'LineWidth',2)

plot(r10.wholeFit.centeredCenters, ...
    r10.wholeFit.synapticExcessCounts,'LineWidth',2)

xline(0,'--')

xlabel('Baseline-subtracted current (pA)')
ylabel('Point count')

title(sprintf(['Whole 19-s fit: 1-pA bins\n' ...
    '\\mu = %.2f pA | Synaptic current = %.2f pA'], ...
    r10.wholeFit.mu,r10.wholeFit.synapticCurrent_pA))

legend('Histogram','Gaussian prediction','Synaptic excess', ...
    'Location','best')

box off

%% 4. ONE-SECOND BASELINE ESTIMATES

nexttile

plot(segmentTime_s,r05.segmentMu,'o-')
hold on
plot(segmentTime_s,r10.segmentMu,'o-')

yline(r05.wholeFit.mu,'--')
yline(r10.wholeFit.mu,':')

xlabel('Time (s)')
ylabel('\mu (pA)')

title('1-s baseline estimates with whole-trial reference')

legend( ...
    '1-s estimates, 0.5-pA bins', ...
    '1-s estimates, 1-pA bins', ...
    'Whole 19-s \mu, 0.5-pA bins', ...
    'Whole 19-s \mu, 1-pA bins', ...
    'Location','best')

xlim([0 19])
box off

%% 5. ONE-SECOND SYNAPTIC CURRENT ESTIMATES

nexttile

plot(segmentTime_s,r05.segmentCurrent_pA,'o-')
hold on
plot(segmentTime_s,r10.segmentCurrent_pA,'o-')

yline(r05.wholeFit.synapticCurrent_pA,'--')
yline(r10.wholeFit.synapticCurrent_pA,':')

xlabel('Time (s)')
ylabel('Synaptic current magnitude (pA)')

title('1-s synaptic current estimates with whole-trial reference')

legend( ...
    '1-s estimates, 0.5-pA bins', ...
    '1-s estimates, 1-pA bins', ...
    'Whole 19-s, 0.5-pA bins', ...
    'Whole 19-s, 1-pA bins', ...
    'Location','best')

xlim([0 19])
box off

%% 6. FINAL METHOD COMPARISON

nexttile

summaryVals = [ ...
    r05.wholeFit.synapticCurrent_pA, ...
    r05.segmentedCurrent_pA, ...
    r10.wholeFit.synapticCurrent_pA, ...
    r10.segmentedCurrent_pA];

bar(1:4,summaryVals)

set(gca,'XTick',1:4, ...
    'XTickLabel',{ ...
    'Whole 19 s, 0.5 pA', ...
    '1-s segments, 0.5 pA', ...
    'Whole 19 s, 1 pA', ...
    '1-s segments, 1 pA'})

ylabel('Synaptic current magnitude (pA)')
title('Final whole-trial versus segmented comparison')

xtickangle(20)
box off

sgtitle('Histogram analysis validation')

end