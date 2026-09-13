%% RUN TO ANALYZE MINI-IPSC EXPERIMENTS WITH NMDA INDUCTION +/- FOURTH CONDITION
tic
folder = '\\bunson\bunson\Higley_Lab\Lauren bunsen\260910 - LP292 - sIPSCs NMDA Aga\cell A';
figureFolder = fullfile(folder,'Matlab figures');
mkdir(figureFolder)
addpath(genpath(figureFolder))

S = MINIS_defaultSettings;

Expt.marker = 'LP292a';
Expt.date = '260910';
Expt.age = 'P34';
Expt.recordingType = 'sIPSC'; % what kind of recording
Expt.studyID = 'NMDA'; % what overall dataset/population
Expt.internal = 'high Cl- CsGluc';
Expt.temp = 'RT';
Expt.Vh = '-70mV';
Expt.CaMg = '2mM Ca, 1mM Mg';
Expt.region = 'med PFC';
Expt.trialInterval = S.trialStartIntervalSec;
Expt.cellType = 'pyramidal';
Expt.genotype = 'WT';
Expt.startingCond = '10uM NBQX';
Expt.drugCond = '20uM NMDA';
Expt.drugTime = '2 min';

Epoch1 = 'e2'; Cond1 = 'NBQX';
Epoch2 = 'e3'; Cond2 = 'NBQX_AgaTK';
Epoch3 = 'e4'; Cond3 = 'NMDA';
Epoch4 = 'e5'; Cond4 = 'Washout';   % e.g. 'SNX_482, not 'SNX-482', 'AgaTK'

epochs = {Epoch1,Epoch2,Epoch3,Epoch4};
conditions = {Cond1,Cond2,Cond3,Cond4};

% NMDA is retained for QC/stability plotting but excluded from stable-range
% and final holding/phasic analysis by S.excludedAnalysisConditions.

color = assignColors(conditions); Colors
[Expt,Data] = compileEphysData_minis(epochs,folder,conditions,Expt,figureFolder,S);

clear Cond1 Cond2 Cond3 Cond4 Epoch1 Epoch2 Epoch3 Epoch4 epochs colors

%% FULL ANALYSIS

Data = MINIS_deleteTrials(Data,S,conditions,figureFolder,'raw'); % gross trace QC only
% Data = MINIS_QCTestPulses(Data,S,conditions,figureFolder);

Data = MINIS_calculateTrialMetrics(Data,conditions,S,figureFolder,color); % calcs Rs/Rin and fits gaussian to full trace
Data = MINIS_selectStableTrials(Data,S,conditions,color,figureFolder,Expt);  

% Review the selected stable trials for whole 19s baseline instability.
% Marked trials are excluded from the whole-trial analysis but remain in the 1s segmented analysis.
[Data,Review] = MINIS_reviewBaselineTrialExclusions(Data,S,conditions,color,Expt);

% Mike analysis: one Gaussian fit across each 19-s trial after baseline-QC exclusions.
Data = MINIS_calculateWholeTrialMetrics(Data,S,conditions);

% Chiayu analysis: same originally selected stable trials, segmented into 1-s epochs.
Data = MINIS_calculateHistogramMetrics(Data,S,conditions);

% Existing validation/summary outputs.
MINIS_plotBaselineValidation(Data,S,conditions,color,figureFolder,Expt);
MINIS_plotSynapticExcessVariability(Data,S,conditions,color,figureFolder,Expt);

% Side-by-side whole-trial sensitivity + 1-s comparison.
Sensitivity = MINIS_compareWholeTrialBaselineSensitivity(Data,S,conditions,color,figureFolder,Expt);
    
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
includeInPopulation = false;
reason = "never stabilized";
BinderIndex = MINIS_setPopulationInclusion(Expt,includeInPopulation,reason,dataFile,figureFolder)
%% CREATE CELL SUMMARY PDF
[pdfFile,BinderIndex] = MINIS_createCellSummaryPDF(Expt,figureFolder,true,conditions);
% binderFile = MINIS_rebuildBinder(Expt)

%% PLOT POPULATION DATA
MINIS_plotPopulation(Expt);

%% EXPORT FOR PRISM
MINIS_exportForPrism(Expt,S);

