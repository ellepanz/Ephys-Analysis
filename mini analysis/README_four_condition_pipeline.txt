FOUR-CONDITION MINI-IPSC PIPELINE

Core rule:
- All conditions are retained for raw trace QC, test-pulse QC, trial metrics, and the full stability/QC plot.
- Conditions listed in S.excludedAnalysisConditions are excluded from stable-range selection, baseline validation, 1-s holding/phasic analysis, and individual-cell holding/phasic summary plots.
- Default: S.excludedAnalysisConditions = {'NMDA'}.

Example condition order:
TTX_NBQX -> NMDA -> Washout -> Gabazine
or
TTX_NBQX -> NMDA -> Washout -> AgaTK

Analyzed conditions are therefore:
TTX_NBQX, Washout, Gabazine/AgaTK

Important API changes:
1. MINIS_calculateImean now takes conditions:
   Data = MINIS_calculateImean(Data,S,conditions);

2. MINIS_addCellToPopulation now takes conditions and can optionally return PopulationLong:
   [Population,PopulationLong] = MINIS_addCellToPopulation(Data,S,Expt,dataFile,conditions);

Population output:
- Population remains the legacy one-row-per-cell baseline/washout table so existing code is not broken.
- PopulationLong is saved in the same NMDAmIPSCs_population.mat file and has one row per cell per analyzed condition. This is where the fourth condition is stored.
- DeltaHoldingFromPrevious and DeltaPhasicFromPrevious compare each analyzed condition to the preceding analyzed condition. Thus for Gabazine/AgaTK after Washout, the delta is fourth-condition minus Washout.

Baseline validation:
- Uses the stable trial indices but pulls the CURRENT trialBaselineFits rather than the copied stableTrialBaselineFits. Re-running MINIS_calculateTrialMetrics after changing Gaussian-fit settings therefore updates validation plots without requiring stable ranges to be selected again.

Files MINIS_plotPopulation and MINIS_exportForPrism were not part of the supplied file set and are not modified in this package. Existing versions that read only Population baseline/washout columns will still plot/export only those conditions. PopulationLong is ready for those functions to be updated next.
