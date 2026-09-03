% v1: 7/14/25

%% 
folder = "C:\Users\Lauren Panzera\Cardin-Higley Lab Dropbox\HigleyLab Team Folder\Lauren\Data Summaries";
currentfolder = "C:\Users\Lauren Panzera\Cardin-Higley Lab Dropbox\HigleyLab Team Folder\Lauren\Data Summaries\Current";
Hzs = {'x1', 'Hz5', 'Hz20', 'Hz40'};
displayHzs = {'Single Stim', '5 Hz','20 Hz','40 Hz'};

file = sprintf('%s%s', datetime('today'), '_EPSC summaries');
folder = fullfile(folder, file);
mkdir(folder)
addpath(genpath(folder))



%% Compile average traces

selectConditions % GUI with checkboxes to choose drugs
