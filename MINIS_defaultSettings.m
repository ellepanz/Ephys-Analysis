function S = MINIS_defaultSettings
% Default settings for miniature IPSC analysis.

S.Fs = 10000; % recording rate

% Acquisition timing
S.trialStartIntervalSec = 30;     % acquisition starts are exactly 30 s apart
S.miniDurationSec = 19.9;         % usable mini recording before test pulse
S.baselineWindowSec = 1.0;        % final 1 s used to estimate pre-pulse baseline

% Test pulse
S.testPulse_mV = -5;
S.testPulseStartSec = 19.9;
S.testPulseDurationSec = 0.030;
S.testPeakSearchMs = 2.0;         % search first 2 ms for capacitive peak
S.testPeakAverageSamples = 3;     % average around peak to reduce single-sample noise
S.testSteadyWindowMs = 5.0;       % final 5 ms used for steady-state current

% Glykys/Mody-style all-points histogram baseline fit
S.fitBinWidth_pA = 0.5;           % fine bins for fitting, not display
S.fitLeftOffset_pA = 3;           % fit starts 3 pA negative to histogram peak
S.sgOrder = 2;
S.sgFrame = 11;                   % must be odd
S.maxMuShiftFromPeak_pA = 5;      % keeps nonlinear fit near histogram mode

% Display histograms
S.displayBinWidth_pA = 5;

% Canonical condition names for future experiments
S.controlCondition = 'TTX_NBQX';
S.drugCondition = 'NMDA';
S.washCondition = 'Washout';

% Derived sample indices
S.miniSamples = round(S.miniDurationSec * S.Fs);
S.baselineSamples = round(S.baselineWindowSec * S.Fs);
S.sealStartIdx = round(S.testPulseStartSec * S.Fs) + 1;
S.sealSamples = round(S.testPulseDurationSec * S.Fs);
S.sealEndIdx = S.sealStartIdx + S.sealSamples - 1;
end
