function V = MINIS_validateWindowLength(trial,S)
% Compare whole-trial versus 1-s segmented histogram analysis.
%
% The first 19 s of the trace are analyzed by both methods:
%   1. One Gaussian fit to the complete 19-s trace.
%   2. Nineteen independent 1-s Gaussian fits.
%
% Segment charges are summed and divided by 19 s to obtain one
% segmented synaptic-current estimate directly comparable to the
% whole-trial estimate.

trial = trial(:);

analysisDuration_s = 19;
segmentDuration_s = 1;

analysisN = analysisDuration_s*S.Fs;
segmentN = segmentDuration_s*S.Fs;
nSegments = analysisDuration_s/segmentDuration_s;

if numel(trial) < analysisN
    error('Trial contains %.3f s of data; %.1f s are required.', ...
        numel(trial)/S.Fs,analysisDuration_s);
end

trial19 = trial(1:analysisN);

%% WHOLE 19-S FIT

wholeFit = MINIS_fitBaseline(trial19,S);

%% 1-S SEGMENT FITS

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
    segmentFits{e} = MINIS_fitBaseline(segment,S);

    segmentMu(e) = segmentFits{e}.mu;
    segmentSigma(e) = segmentFits{e}.sigma;
    segmentR2(e) = segmentFits{e}.R2;
    segmentCharge_pC(e) = segmentFits{e}.synapticCharge_pC;
    segmentCurrent_pA(e) = segmentFits{e}.synapticCurrent_pA;

end

%% COMBINE SEGMENT RESULTS

segmentedCharge_pC = sum(segmentCharge_pC,'omitnan');
segmentedCurrent_pA = segmentedCharge_pC/analysisDuration_s;
segmentedMu = mean(segmentMu,'omitnan');

deltaMu_pA = segmentedMu-wholeFit.mu;
deltaCurrent_pA = segmentedCurrent_pA-wholeFit.synapticCurrent_pA;

if wholeFit.synapticCurrent_pA ~= 0
    percentCurrentDifference = 100*deltaCurrent_pA/abs(wholeFit.synapticCurrent_pA);
else
    percentCurrentDifference = NaN;
end

%% STORE RESULTS

V.analysisDuration_s = analysisDuration_s;
V.segmentDuration_s = segmentDuration_s;
V.trial = trial19;

V.wholeFit = wholeFit;

V.segmentFits = segmentFits;
V.segmentMu = segmentMu;
V.segmentSigma = segmentSigma;
V.segmentR2 = segmentR2;
V.segmentCharge_pC = segmentCharge_pC;
V.segmentCurrent_pA = segmentCurrent_pA;

V.segmentedMu = segmentedMu;
V.segmentedCharge_pC = segmentedCharge_pC;
V.segmentedCurrent_pA = segmentedCurrent_pA;

V.deltaMu_pA = deltaMu_pA;
V.deltaCurrent_pA = deltaCurrent_pA;
V.percentCurrentDifference = percentCurrentDifference;

V.summary = table( ...
    ["Whole 19 s";"Nineteen 1-s segments"], ...
    [wholeFit.mu;segmentedMu], ...
    [wholeFit.synapticCharge_pC;segmentedCharge_pC], ...
    [wholeFit.synapticCurrent_pA;segmentedCurrent_pA], ...
    'VariableNames',{'Method','HoldingCurrent_pA','SynapticCharge_pC','SynapticCurrent_pA'});

%% PRINT RESULTS

fprintf('\nWINDOW-LENGTH VALIDATION\n');
fprintf('------------------------\n');
fprintf('Whole 19-s mu:        %.3f pA\n',wholeFit.mu);
fprintf('Segmented mean mu:    %.3f pA\n',segmentedMu);
fprintf('Difference:            %.3f pA\n\n',deltaMu_pA);

fprintf('Whole 19-s charge:    %.3f pC\n',wholeFit.synapticCharge_pC);
fprintf('Segmented charge:     %.3f pC\n\n',segmentedCharge_pC);

fprintf('Whole 19-s current:   %.3f pA\n',wholeFit.synapticCurrent_pA);
fprintf('Segmented current:    %.3f pA\n',segmentedCurrent_pA);
fprintf('Difference:            %.3f pA\n',deltaCurrent_pA);
fprintf('Percent difference:    %.2f %%\n\n',percentCurrentDifference);

disp(V.summary)

%% PLOT

time_s = (0:analysisN-1)'/S.Fs;
segmentTime_s = ((1:nSegments)-0.5)';

figure('Color','w','Position',[100 100 1200 750]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

% Raw 19-s trace
nexttile
plot(time_s,trial19)
hold on

for e = 1:nSegments-1
    xline(e,':');
end

yline(wholeFit.mu,'--','Whole-trial \mu');

xlabel('Time (s)')
ylabel('Current (pA)')
title('19-s trace')
box off

% Whole-trial histogram
nexttile
bar(wholeFit.centeredCenters,wholeFit.pointFreq,1)
hold on
plot(wholeFit.centeredCenters,wholeFit.gaussianCounts,'LineWidth',2)
plot(wholeFit.centeredCenters,wholeFit.synapticExcessCounts,'LineWidth',2)
xline(0,'--')

xlabel('Baseline-subtracted current (pA)')
ylabel('Point count')
title(sprintf('Whole 19-s fit: \\mu = %.2f pA, synaptic = %.2f pA', ...
    wholeFit.mu,wholeFit.synapticCurrent_pA))
legend('Histogram','Gaussian','Synaptic excess','Location','best')
box off

% Local mu
nexttile
plot(segmentTime_s,segmentMu,'o-')
hold on
yline(wholeFit.mu,'--','Whole 19-s \mu');

xlabel('Time (s)')
ylabel('\mu (pA)')
title(sprintf('1-s baseline estimates: mean = %.2f pA',segmentedMu))
xlim([0 analysisDuration_s])
box off

% Local synaptic current
nexttile
plot(segmentTime_s,segmentCurrent_pA,'o-')
hold on
yline(wholeFit.synapticCurrent_pA,'--','Whole 19-s');
yline(segmentedCurrent_pA,':','Segmented result');

xlabel('Time (s)')
ylabel('Synaptic current (pA)')
title(sprintf('Whole = %.2f pA | Segmented = %.2f pA | \\Delta = %.2f pA', ...
    wholeFit.synapticCurrent_pA,segmentedCurrent_pA,deltaCurrent_pA))
xlim([0 analysisDuration_s])
box off

sgtitle('Whole-trial versus 1-s segmented histogram analysis')

end