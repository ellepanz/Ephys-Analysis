%% RUN TO ANALYZE MINI-IPSC EXPERIMENTS WITH NMDA INDUCTION +/- FOURTH CONDITION
tic
folder = '\\bunson\bunson\Higley_Lab\Lauren bunsen\260831 - LP288 - sIPSCs 2min NMDA\cell A';
figureFolder = fullfile(folder,'Matlab figures');
mkdir(figureFolder)
addpath(genpath(figureFolder))

S = MINIS_defaultSettings;

Expt.marker = 'LP288a';
Expt.date = '260831';
Expt.age = 'P26';
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
Epoch2 = 'e3'; Cond2 = 'NMDA';
Epoch3 = 'e4'; Cond3 = 'Washout';
% Epoch4 = 'e12'; Cond4 = 'SNX_482';   % e.g. 'SNX_482, not 'SNX-482', 'AgaTK'

epochs = {Epoch1,Epoch2,Epoch3};
conditions = {Cond1,Cond2,Cond3};

% NMDA is retained for QC/stability plotting but excluded from stable-range
% and final holding/phasic analysis by S.excludedAnalysisConditions.

color = assignColors(conditions); Colors
[Expt,Data] = compileEphysData_minis(epochs,folder,conditions,Expt,figureFolder,S);

clear Cond1 Cond2 Cond3 Cond4 Epoch1 Epoch2 Epoch3 Epoch4 epochs colors

%% FULL ANALYSIS

Data = MINIS_deleteTrials(Data,S,conditions,figureFolder,'raw');
% Data = MINIS_QCTestPulses(Data,S,conditions,figureFolder);
Data = MINIS_calculateTrialMetrics(Data,conditions,S,figureFolder,color);
Data = MINIS_selectStableTrials(Data,S,conditions,color,figureFolder, Expt);
MINIS_plotBaselineValidation(Data,S,conditions,color,figureFolder, Expt);
Data = MINIS_calculateImean(Data,S,conditions);
MINIS_plotImeanVariability(Data,S,conditions,color,figureFolder,Expt);

%% SAVE CELL DATA
dataFile = fullfile(folder,sprintf('%s_data.mat',Expt.marker));
save(dataFile,'Data','Expt','S','conditions','color','figureFolder','folder','-v7.3');
fprintf('Workspace saved.\n');
toc
return
%% ADD CELL TO POPULATION
[Population,PopulationLong] = MINIS_addCellToPopulation(Data,S,Expt,dataFile,conditions);

%% CREATE CELL SUMMARY PDF
[pdfFile,BinderIndex] = MINIS_createCellSummaryPDF(Expt,figureFolder,true,conditions);
% MINIS_rebuildBinder;

%% PLOT POPULATION DATA
MINIS_plotPopulation;

%% EXPORT FOR PRISM
MINIS_exportForPrism;
