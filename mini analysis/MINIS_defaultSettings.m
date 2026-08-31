function S = MINIS_defaultSettings
% Default settings for miniature IPSC analysis.

S.Fs = 10000;

% Acquisition timing
S.trialStartIntervalSec = 30;
S.miniDurationSec = 19.9;
S.baselineWindowSec = 1.0;
S.recordingLength = 20;

% Test pulse
S.testPulse_mV = -5;
S.testPulseStartSec = 19.9;
S.testPulseDurationSec = 0.030;
S.testPeakSearchMs = 2.0;
S.testPeakAverageSamples = 3;
S.testSteadyWindowMs = 5.0;

% Glykys/Mody-style all-points histogram baseline fit
S.fitBinWidth_pA = 0.5;
S.fitLeftOffset_pA = 1;
S.sgOrder = 2;
S.sgFrame = 111;
S.maxMuShiftFromPeak_pA = 5;

% Display histograms
S.displayBinWidth_pA = 5;

% Canonical condition names
S.controlCondition = 'TTX_NBQX';
S.drugCondition = 'NMDA';
S.washCondition = 'Washout';

% Conditions that should be shown for QC but excluded from stable-range,
% baseline-validation, and final 1-s holding/phasic analyses.
S.excludedAnalysisConditions = {'NMDA'};

% Derived sample indices
S.miniSamples = round(S.miniDurationSec*S.Fs);
S.baselineSamples = round(S.baselineWindowSec*S.Fs);
S.sealStartIdx = round(S.testPulseStartSec*S.Fs) + 1;
S.sealSamples = round(S.testPulseDurationSec*S.Fs);
S.sealEndIdx = S.sealStartIdx + S.sealSamples - 1;

end
