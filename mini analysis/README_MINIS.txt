MINI-IPSC analysis rewrite
==========================

Recommended order
-----------------
1. Compile raw AD0 trials into Data as before.
2. MINIS_deleteTrials
   - overlays every 19.9-s trial by condition
   - click visibly bad traces to exclude them
   - preserves QCTrialNames/QCTrialNums/finalMiniData
3. MINIS_calculateTrialMetrics
   - all-point mean per 19.9-s trace
   - baseline holding current from Gaussian fit to FINAL 1 s before test pulse
   - Rs from initial -5 mV test-pulse current transient
   - Rtotal from steady-state test-pulse current
   - Rin = Rtotal - Rs
4. MINIS_selectStableTrials
   - plots all-point mean, Gaussian baseline, Rs, Rin versus true time
   - missing manually excluded trials remain missing in their original time slots
   - click first/last stable TTX_NBQX and Washout trials
   - creates stableMiniData and stableConcatData
5. MINIS_plotHistograms
   - plots stable concatenated traces and 5-pA-bin display histograms
6. MINIS_analyzeStableData
   - analyzes each stable trial in 1-s epochs (10,000 points)
   - does NOT join the 0.9-s remainder of one trial to the next trial
   - stores Gaussian baseline, Gaussian sigma, phasic Imean, histogram excess

Gaussian baseline defaults
--------------------------
Internal fit bin width: 0.5 pA
Savitzky-Golay: polynomial order 2, frame 11 bins
Fit starts: 3 pA negative to the smoothed histogram mode
Fit extends: through the positive/right side
Baseline: fitted Gaussian center (mu)

Phasic analysis
---------------
The Gaussian is treated as the symmetric baseline-noise distribution.
Negative-side histogram mass above that Gaussian is stored as a distributional
'synapticExcessFraction'. Mean phasic current is calculated by subtracting mu
from each raw 1-s trace and taking its mean. This does NOT produce individual
mIPSC event times/amplitudes; individual-event detection should be a separate
analysis step.

Resistance assumptions
----------------------
Voltage step: -5 mV
Pulse starts: 19.9 s
Pulse duration: 30 ms
Baseline: Gaussian mu from final 1 s before pulse
Ipeak: averaged around the largest inward transient in first 2 ms
Iss: average of final 5 ms of pulse
Rs = |dV / dIpeak|
Rtotal = |dV / dIss|
Rin = Rtotal - Rs

Legacy first experiment
-----------------------
MINIS_mergeLegacyWash combines WashWaste and Wash into Washout without
requiring the rest of the pipeline to know about that historical split.
