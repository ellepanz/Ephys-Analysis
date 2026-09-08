function V = MINIS_validateArtificialDrift(trial,S,figureFolder)
% Test whether whole-trial versus local 1-s histogram analysis is sensitive
% to artificial baseline drift.
%
% The synaptic signal is unchanged. Only a known baseline offset is added.
%
% Two forms of drift are tested:
%   1) Step shift beginning after 9 s
%   2) Linear drift across the complete 19 s
%
% Drift amplitudes tested: 0, 5, 10, and 15 pA inward.
%
% If a method measures phasic synaptic current independently of baseline
% position, its synaptic-current estimate should remain close to the
% no-drift value.

if nargin < 3
    figureFolder = [];
end

trial = trial(:);

analysisDuration_s = 19;
analysisN = analysisDuration_s*S.Fs;
epochN = S.Fs;
nEpochs = analysisDuration_s;

if numel(trial) < analysisN
    error('Trial contains only %.2f s; 19 s are required.',numel(trial)/S.Fs);
end

trial = trial(1:analysisN);
time_s = (0:analysisN-1)'/S.Fs;

driftAmplitudes_pA = [0 5 10 15];
nDrifts = numel(driftAmplitudes_pA);

%% PREALLOCATE

wholeStepCurrent = nan(1,nDrifts);
localStepCurrent = nan(1,nDrifts);

wholeRampCurrent = nan(1,nDrifts);
localRampCurrent = nan(1,nDrifts);

wholeStepMu = nan(1,nDrifts);
localStepMu = nan(1,nDrifts);

wholeRampMu = nan(1,nDrifts);
localRampMu = nan(1,nDrifts);

stepTraces = cell(1,nDrifts);
rampTraces = cell(1,nDrifts);

%% RUN ARTIFICIAL DRIFT TESTS

for d = 1:nDrifts

    amp = driftAmplitudes_pA(d);

    %% STEP DRIFT

    stepTrace = trial;

    % First 9 s unchanged; final 10 s shifted inward.
    stepStartIdx = 9*S.Fs + 1;
    stepTrace(stepStartIdx:end) = stepTrace(stepStartIdx:end)-amp;

    stepTraces{d} = stepTrace;

    wholeFit = MINIS_fitBaseline(stepTrace,S);
    localFit = analyzeLocal(stepTrace,S,nEpochs,epochN);

    wholeStepCurrent(d) = wholeFit.synapticCurrent_pA;
    localStepCurrent(d) = localFit.synapticCurrent_pA;

    wholeStepMu(d) = wholeFit.mu;
    localStepMu(d) = localFit.mu;

    %% LINEAR DRIFT

    ramp = linspace(0,-amp,analysisN)';
    rampTrace = trial+ramp;

    rampTraces{d} = rampTrace;

    wholeFit = MINIS_fitBaseline(rampTrace,S);
    localFit = analyzeLocal(rampTrace,S,nEpochs,epochN);

    wholeRampCurrent(d) = wholeFit.synapticCurrent_pA;
    localRampCurrent(d) = localFit.synapticCurrent_pA;

    wholeRampMu(d) = wholeFit.mu;
    localRampMu(d) = localFit.mu;

end

%% CHANGE FROM NO-DRIFT VALUE

wholeStepChange = wholeStepCurrent-wholeStepCurrent(1);
localStepChange = localStepCurrent-localStepCurrent(1);

wholeRampChange = wholeRampCurrent-wholeRampCurrent(1);
localRampChange = localRampCurrent-localRampCurrent(1);

wholeStepError = abs(wholeStepChange);
localStepError = abs(localStepChange);

wholeRampError = abs(wholeRampChange);
localRampError = abs(localRampChange);

%% STORE

V.driftAmplitudes_pA = driftAmplitudes_pA;

V.wholeStepCurrent_pA = wholeStepCurrent;
V.localStepCurrent_pA = localStepCurrent;
V.wholeRampCurrent_pA = wholeRampCurrent;
V.localRampCurrent_pA = localRampCurrent;

V.wholeStepMu_pA = wholeStepMu;
V.localStepMu_pA = localStepMu;
V.wholeRampMu_pA = wholeRampMu;
V.localRampMu_pA = localRampMu;

V.wholeStepChange_pA = wholeStepChange;
V.localStepChange_pA = localStepChange;
V.wholeRampChange_pA = wholeRampChange;
V.localRampChange_pA = localRampChange;

V.wholeStepError_pA = wholeStepError;
V.localStepError_pA = localStepError;
V.wholeRampError_pA = wholeRampError;
V.localRampError_pA = localRampError;

V.originalTrace = trial;
V.stepTraces = stepTraces;
V.rampTraces = rampTraces;

%% TABLE

V.summary = table( ...
    driftAmplitudes_pA(:), ...
    wholeStepCurrent(:), ...
    localStepCurrent(:), ...
    wholeStepError(:), ...
    localStepError(:), ...
    wholeRampCurrent(:), ...
    localRampCurrent(:), ...
    wholeRampError(:), ...
    localRampError(:), ...
    'VariableNames',{ ...
    'InjectedDrift_pA', ...
    'WholeStepCurrent_pA', ...
    'LocalStepCurrent_pA', ...
    'WholeStepError_pA', ...
    'LocalStepError_pA', ...
    'WholeRampCurrent_pA', ...
    'LocalRampCurrent_pA', ...
    'WholeRampError_pA', ...
    'LocalRampError_pA'});

fprintf('\nARTIFICIAL BASELINE DRIFT VALIDATION\n');
fprintf('====================================\n');
fprintf('Synaptic events are identical in every trace.\n');
fprintf('Only baseline position was altered.\n\n');

disp(V.summary)

%% FIGURE

fig = figure('Color','w','Position',[80 50 1450 850]);
t = tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');

%% 1. STEP EXAMPLE TRACE

ax1 = nexttile(t);
hold(ax1,'on');

plot(ax1,time_s,trial);
plot(ax1,time_s,stepTraces{end});

xline(ax1,9,'--');

xlabel(ax1,'Time (s)');
ylabel(ax1,'Current (pA)');
title(ax1,sprintf('Artificial %.0f-pA step shift',driftAmplitudes_pA(end)));

legend(ax1,'Original','Baseline shifted','Shift begins','Location','best');
xlim(ax1,[0 19]);
box(ax1,'off');

%% 2. STEP: CALCULATED SYNAPTIC CURRENT

%% 2. STEP: CALCULATED SYNAPTIC CURRENT

ax2 = nexttile(t);
hold(ax2,'on');

hWhole = plot(ax2,driftAmplitudes_pA,wholeStepCurrent,'o-','LineWidth',1.5);
hLocal = plot(ax2,driftAmplitudes_pA,localStepCurrent,'o-','LineWidth',1.5);

yline(ax2,wholeStepCurrent(1),'--', ...
    'Original whole-trial value', ...
    'Color',hWhole.Color, ...
    'HandleVisibility','on');

yline(ax2,localStepCurrent(1),'--', ...
    'Original local value', ...
    'Color',hLocal.Color, ...
    'HandleVisibility','on');

xlabel(ax2,'Injected baseline shift (pA)');
ylabel(ax2,'Calculated synaptic current (pA)');
title(ax2,'Step shift: does the calculated current change?');

legend(ax2, ...
    'Drifted trace: whole 19-s fit', ...
    'Drifted trace: local 1-s fits', ...
    'Original trace: whole 19-s', ...
    'Original trace: local 1-s', ...
    'Location','best');

box(ax2,'off');

%% 3. STEP: ERROR FROM NO-DRIFT VALUE

ax3 = nexttile(t);
hold(ax3,'on');

plot(ax3,driftAmplitudes_pA,wholeStepError,'o-','LineWidth',1.5);
plot(ax3,driftAmplitudes_pA,localStepError,'o-','LineWidth',1.5);

xlabel(ax3,'Injected baseline shift (pA)');
ylabel(ax3,'Change from no-drift result (pA)');
title(ax3,'Step shift: analysis error');

legend(ax3,'Whole 19-s fit','Local 1-s fits','Location','best');
box(ax3,'off');

%% 4. LINEAR-DRIFT EXAMPLE TRACE

ax4 = nexttile(t);
hold(ax4,'on');

plot(ax4,time_s,trial);
plot(ax4,time_s,rampTraces{end});

xlabel(ax4,'Time (s)');
ylabel(ax4,'Current (pA)');
title(ax4,sprintf('Artificial %.0f-pA linear drift',driftAmplitudes_pA(end)));

legend(ax4,'Original','Baseline drifted','Location','best');
xlim(ax4,[0 19]);
box(ax4,'off');

%% 5. RAMP: CALCULATED SYNAPTIC CURRENT

%% 5. LINEAR DRIFT: CALCULATED SYNAPTIC CURRENT

ax5 = nexttile(t);
hold(ax5,'on');

hWhole = plot(ax5,driftAmplitudes_pA,wholeRampCurrent,'o-','LineWidth',1.5);
hLocal = plot(ax5,driftAmplitudes_pA,localRampCurrent,'o-','LineWidth',1.5);

yline(ax5,wholeRampCurrent(1),'--', ...
    'Original whole-trial value', ...
    'Color',hWhole.Color, ...
    'HandleVisibility','on');

yline(ax5,localRampCurrent(1),'--', ...
    'Original local value', ...
    'Color',hLocal.Color, ...
    'HandleVisibility','on');

xlabel(ax5,'Total baseline drift (pA)');
ylabel(ax5,'Calculated synaptic current (pA)');
title(ax5,'Linear drift: does the calculated current change?');

legend(ax5, ...
    'Drifted trace: whole 19-s fit', ...
    'Drifted trace: local 1-s fits', ...
    'Original trace: whole 19-s', ...
    'Original trace: local 1-s', ...
    'Location','best');

box(ax5,'off');


%% 6. RAMP: ERROR FROM NO-DRIFT VALUE

ax6 = nexttile(t);
hold(ax6,'on');

plot(ax6,driftAmplitudes_pA,wholeRampError,'o-','LineWidth',1.5);
plot(ax6,driftAmplitudes_pA,localRampError,'o-','LineWidth',1.5);

xlabel(ax6,'Total baseline drift (pA)');
ylabel(ax6,'Change from no-drift result (pA)');
title(ax6,'Linear drift: analysis error');

legend(ax6,'Whole 19-s fit','Local 1-s fits','Location','best');
box(ax6,'off');

sgtitle(t,sprintf('Artificial Baseline-Drift Validation | %.1f-pA histogram bins',S.fitBinWidth_pA));

%% SAVE

if ~isempty(figureFolder)

    savefig(fig,fullfile(figureFolder,'Artificial Baseline Drift Validation.fig'));

    exportgraphics(fig,fullfile(figureFolder,'Artificial Baseline Drift Validation.png'), ...
        'Resolution',300);
end

end


function result = analyzeLocal(trial,S,nEpochs,epochN)

mu = nan(nEpochs,1);
charge = nan(nEpochs,1);
current = nan(nEpochs,1);

for e = 1:nEpochs

    idx1 = (e-1)*epochN + 1;
    idx2 = e*epochN;

    fit = MINIS_fitBaseline(trial(idx1:idx2),S);

    mu(e) = fit.mu;
    charge(e) = fit.synapticCharge_pC;
    current(e) = fit.synapticCurrent_pA;

end

result.epochMu = mu;
result.epochCharge_pC = charge;
result.epochCurrent_pA = current;

result.mu = mean(mu,'omitnan');
result.synapticCharge_pC = sum(charge,'omitnan');
result.synapticCurrent_pA = result.synapticCharge_pC/nEpochs;

end