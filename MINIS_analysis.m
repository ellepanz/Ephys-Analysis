%% 8/15/26 RUN TO ANALYZE EXPERIMENTS RECORDING MINIS +/- DRUG

folder = "\\bunson\bunson\Higley_Lab\Lauren bunsen\260813 - LP279 - minis\cell B";
figureFolder = fullfile(folder, 'Matlab figures');
mkdir(figureFolder)
addpath(genpath(figureFolder))

Expt.marker = 'LP279b';
Expt.date = '260813';
Expt.age = 'P49';
Expt.internal = 'high Cl- CsGluc';
Expt.temp = 'RT';
Expt.Vh = '-70mV';
Expt.CaMg = '2mM Ca, 1mM Mg';
Expt.region = 'med PFC';
Expt.trialInterval = 10; % ISI seconds
Expt.cellType = 'pyramidal L2/3';
Expt.genotype = 'WT';
Expt.startingCond = '1uM TTX, 10uM NBQX';
Expt.drugCond = '20uM NMDA';
Expt.drugTime = '2 min';


dataset = Expt.genotype; % what datasum variable do you want to pull at the end?
Epoch1 = 'e2';        Cond1 = 'TTX_NBQX';
Epoch2 = 'e3';        Cond2 = 'NMDA'; % ConoGVIA, can't have -
Epoch3 = 'e4';        Cond3 = 'WashWaste';
Epoch4 = 'e5';        Cond4 = 'Wash';

epochs = {Epoch1, Epoch2, Epoch3, Epoch4};
conditions = {Cond1, Cond2, Cond3, Cond4};

color = assignColors(conditions); Colors
[Expt, Data] = compileEphysData_minis(epochs, folder, conditions, Expt, figureFolder);

%% CHOOSE STABLE TRIALS
Data = MINIS_deleteTrials(Data, Fs, conditions, figureFolder);
Data = MINIS_selectStableTrials(Data, conditions, color);
Data = MINIS_plotRs 

% if this changes from TTX/NBQX, then NMDA, then washout this needs to be
% changed from only using conditions [1 3]
MINIS_plotHistograms(Data, color, conditions);
