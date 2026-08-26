%% 8/15/26 RUN TO ANALYZE EXPERIMENTS RECORDING MINIS +/- DRUG

folder = '\\bunson\bunson\Higley_Lab\Lauren bunsen\260825 - LP285 - mIPSCs 2min NMDA gbz\cell A';
figureFolder = fullfile(folder, 'Matlab figures');
mkdir(figureFolder)
addpath(genpath(figureFolder))

Expt.marker = 'LP285a';
Expt.date = '260825';
Expt.age = 'P20';
Expt.internal = 'high Cl- CsGluc';
Expt.temp = 'RT';
Expt.Vh = '-70mV';
Expt.CaMg = '2mM Ca, 1mM Mg';
Expt.region = 'med PFC';
Expt.trialInterval = 10; % ISI seconds
Expt.cellType = 'pyramidal';
Expt.genotype = 'WT';
Expt.startingCond = '1uM TTX, 10uM NBQX';
Expt.drugCond = '20uM NMDA; 10uM gabazine';
Expt.drugTime = '2 min';
S = MINIS_defaultSettings;

%dataset = Expt.genotype; % what datasum variable do you want to pull at the end?
Epoch1 = 'e1';        Cond1 = 'TTX_NBQX';
Epoch2 = 'e2';        Cond2 = 'NMDA'; % ConoGVIA, can't have -
Epoch3 = 'e3';        Cond3 = 'Washout';
Epoch4 = 'e5';        Cond4 = 'Gabazine';

epochs = {Epoch1, Epoch2, Epoch3, Epoch4};
conditions = {Cond1, Cond2, Cond3, Cond4};

color = assignColors(conditions); Colors
[Expt, Data] = compileEphysData_minis(epochs, folder, conditions, Expt, figureFolder, S);

clear Cond1 Cond2 Cond3 Cond4 Epoch1 Epoch2 Epoch3 Epoch4 epochs colors 
%% =========================================================
% FULL ANALYSIS
% ==========================================================
Data = MINIS_deleteTrials(Data,S,conditions,figureFolder,'raw');
Data = MINIS_QCTestPulses(Data,S,conditions,figureFolder);
Data = MINIS_calculateTrialMetrics(Data,conditions,S,figureFolder,color);
Data = MINIS_selectStableTrials(Data,S,conditions,color,figureFolder);
MINIS_plotBaselineValidation(Data,S,conditions,color,figureFolder);
Data = MINIS_calculateImean(Data,S);
MINIS_plotImeanVariability(Data,S,conditions,color,figureFolder,Expt);


%% =========================================================
% SAVE CELL DATA
% ==========================================================
dataFile = fullfile(folder,sprintf('%s_data.mat',Expt.marker));
save(dataFile,'Data','Expt','S','conditions','color','figureFolder','folder','-v7.3');
fprintf('Workspace saved.\n');

return
%% =========================================================
% ADD CELL TO POPULATION
% ==========================================================
Population = MINIS_addCellToPopulation(Data,S,Expt,dataFile);

%% =========================================================
% CREATE CELL SUMMARY PDF
% ==========================================================
% true if you want to include validation pages in binder.
populationFile = "\\bunson\bunson\Higley_Lab\Lauren bunsen\Data Summaries\mIPSCs with NMDA";
[pdfFile,binderFile] = MINIS_createCellSummaryPDF(Expt,figureFolder,true); % if don't want single trace validation pages set to 'false'
%MINIS_rebuildBinder; % run whenever want to build and print PDF summaries for binder

%% =========================================================
% PLOT POPULATION DATA
% ==========================================================
MINIS_plotPopulation;

%% =========================================================
% EXPORT FOR PRISM
% ==========================================================
MINIS_exportForPrism


