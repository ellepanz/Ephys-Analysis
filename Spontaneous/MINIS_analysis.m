%% RUN TO ANALYZE MINI-IPSC EXPERIMENTS WITH NMDA INDUCTION +/- FOURTH CONDITION
tic
folder = '\\bunson\bunson\Higley_Lab\Lauren bunsen\260913 - LP293 - sIPSCs NMDA TB\cell B';
figureFolder = fullfile(folder,'Matlab figures');
mkdir(figureFolder)
addpath(genpath(figureFolder))

S = MINIS_defaultSettings;

Expt.marker = 'LP293b';
Expt.date = '260913';
Expt.age = 'P31';
Expt.recordingType = 'sIPSC'; % what kind of recording
Expt.studyID = 'NMDA_TB21007'; % what overall dataset/population
Expt.internal = 'high Cl- CsGluc';
Expt.temp = 'RT';
Expt.Vh = '-70mV';
Expt.CaMg = '2mM Ca, 1mM Mg';
Expt.region = 'med PFC';
Expt.trialInterval = S.trialStartIntervalSec;
Expt.cellType = 'pyramidal';
Expt.genotype = 'WT';
Expt.startingCond = '10uM NBQX, 10nM TB21007';
Expt.drugCond = '20uM NMDA';
Expt.drugTime = '2 min';

Epoch1 = 'e4'; Cond1 = 'NBQX_TB21007'; % e.g. 'SNX_482, not 'SNX-482', 'AgaTK'
Epoch2 = 'e5'; Cond2 = 'NMDA';
Epoch3 = 'e6'; Cond3 = 'Washout';  

epochs = {Epoch1,Epoch2,Epoch3};
conditions = {Cond1,Cond2,Cond3};

% NMDA is retained for QC/stability plotting but excluded from stable-range
% and final holding/phasic analysis by S.excludedAnalysisConditions.

color = assignColors(conditions); Colors
[Expt,Data] = compileEphysData_minis(epochs,folder,conditions,Expt,figureFolder,S);

clear Cond1 Cond2 Cond3 Cond4 Epoch1 Epoch2 Epoch3 Epoch3 epochs colors

%% FULL ANALYSIS
Data = MINIS_deleteTrials(Data,S,conditions,figureFolder,'raw'); % gross trace QC only
% Data = MINIS_QCTestPulses(Data,S,conditions,figureFolder);

Data = MINIS_calculateTrialMetrics(Data,conditions,S,figureFolder,color); % calcs Rs/Rin and fits Gaussian to full trace
Data = MINIS_selectStableTrials(Data,S,conditions,color,figureFolder,Expt);

% Review selected stable trials for whole-trial baseline instability.
% Marked trials are excluded from the final whole-trial analysis.
[Data,Review] = MINIS_reviewBaselineTrialExclusions(Data,S,conditions,color,Expt);

% Final analysis: one Gaussian fit across each whole trial after baseline-QC exclusions.
Data = MINIS_calculateWholeTrialMetrics(Data,S,conditions);

% Whole-trial Gaussian fit QC.
MINIS_plotBaselineValidation(Data,S,conditions,color,figureFolder,Expt);

% Whole-trial holding-current and phasic-current summary.
MINIS_plotSynapticExcessVariability(Data,S,conditions,color,figureFolder,Expt);

    
% Data = MINIS_calculateImean(Data,S,conditions); % use for original analysis calculating current mean
% MINIS_plotImeanVariability(Data,S,conditions,color,figureFolder,Expt); % use for original analysis 

%% SAVE CELL DATA
dataFile = fullfile(folder,sprintf('%s_data.mat',Expt.marker));
save(dataFile,'Data','Expt','S','conditions','color','figureFolder','folder','-v7.3');

fprintf('Workspace saved.\n');
toc

return

%% ADD CELL TO POPULATION OR NOT
[Population,PopulationLong] = MINIS_addCellToPopulation(Data,S,Expt,dataFile,conditions);
% OR
reason = "never stabilized";  % reason cell isn't included in population
BinderIndex = MINIS_excludeCellFromPopulation(Expt,reason,dataFile,figureFolder)
%% CREATE CELL SUMMARY PDF
[pdfFile,BinderIndex] = MINIS_createCellSummaryPDF(Expt,figureFolder,true,conditions);

%% BUILD BINDER
Expt.recordingType = 'sIPSC'; % 'sIPSC' or 'mIPSC'
Expt.studyID = 'NMDA'
binderFile = MINIS_rebuildBinder(Expt)

%% PLOT POPULATION DATA
MINIS_plotPopulation(Expt);

%% EXPORT FOR PRISM
Expt.recordingType = 'mIPSC'; % 'sIPSC' or 'mIPSC'
Expt.studyID = 'NMDA';
S.baselineCondition = 'TTX_NBQX'; % 'NBQX' or 'TTX_NBQX'
S.washCondition = 'Washout';

MINIS_exportForPrism(Expt,S);

%% PULL UP POPULATION DATA
Expt.recordingType = 'sIPSC';   % or 'sIPSC'
Expt.studyID = 'NMDA';

paths = MINIS_getPopulationPaths(Expt);
tmp = load(paths.populationFile,'Population');
Population = tmp.Population;