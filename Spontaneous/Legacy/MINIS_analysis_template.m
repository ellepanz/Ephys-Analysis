%% MINIS ANALYSIS TEMPLATE
% Canonical future-experiment structure:
%   TTX_NBQX -> NMDA -> Washout

Fs = 10000;
S = MINIS_defaultSettings(Fs);

% Example:
% folder = "\\bunson\bunson\Higley_Lab\Lauren bunsen\...";
% figureFolder = fullfile(folder,'Matlab figures');
% if ~exist(figureFolder,'dir'), mkdir(figureFolder); end

conditions = {'TTX_NBQX','NMDA','Washout'};

% Keep your existing color workflow if desired:
% color = assignColors(conditions);
%
% For reference, a simple default set would be:
% color = {[0.4 0.4 0.4], [0.2157 0.8588 0.8784], [0.1647 0.6157 0.5608]};

% Compile raw data using your existing loader before the steps below.
% [Expt,Data] = compileEphysData_minis(epochs,folder,conditions,Expt,figureFolder);

%% 1. Manual trace QC: click visibly bad trials to remove them
Data = MINIS_deleteTrials(Data,S,conditions,figureFolder);

%% 2. Per-trial Gaussian baseline + Rs/Rin
Data = MINIS_calculateTrialMetrics(Data,S,conditions);

%% 3. Plot mean current, Gaussian holding current, Rs and Rin versus real time.
% Click first/last stable Control and Washout trials after inspecting both
% holding current and Rs. Stable trials are concatenated automatically.
Data = MINIS_selectStableTrials(Data,S,conditions,color,figureFolder);

%% 4. Keep the stable concatenated-trace and histogram plots
MINIS_plotHistograms(Data,S,conditions,color,figureFolder);

%% 5. Glykys/Mody-style 1-s analysis on stable trials
Data = MINIS_analyzeStableData(Data,S,conditions,color,figureFolder);

%% Optional: save analyzed structures
% save(fullfile(folder,'MINIS_analyzed.mat'),'Data','Expt','S','conditions','-v7.3');

%% LEGACY FIRST EXPERIMENT ONLY
% If you compile the old four-condition experiment containing WashWaste and
% Wash, merge them immediately after compilation, then use the canonical
% three-condition list above:
%
% Data = MINIS_mergeLegacyWash(Data,S,false);
% conditions = {'TTX_NBQX','NMDA','Washout'};
% color = assignColors(conditions);
