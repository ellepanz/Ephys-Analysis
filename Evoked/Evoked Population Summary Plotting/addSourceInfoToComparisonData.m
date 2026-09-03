function ComparisonData = addSourceInfoToComparisonData(ComparisonData)

warning('Is ExperimentIndex up to date?');

dataStorageFolder = 'C:\Users\Lauren Panzera\Cardin-Higley Lab Dropbox\HigleyLab Team Folder\Lauren\Data Summaries\EPSC PP trains Aga Cono Musc';
load(fullfile(dataStorageFolder, "ExperimentIndex.mat"), 'ExperimentIndex');
assignin('base', 'ExperimentIndex', ExperimentIndex)

for i = 1:numel(ComparisonData.PairEntries)

    exptName = string(ComparisonData.PairEntries(i).Expt);

    idx = strcmp(string(ExperimentIndex.Expt), exptName);

    if ~any(idx)
        warning('Experiment "%s" not found in ExperimentIndex.', exptName);
        ComparisonData.PairEntries(i).Source = struct();
        continue
    end

    if sum(idx) > 1
        warning('Experiment "%s" appears multiple times in ExperimentIndex. Using first match.', exptName);
        idx = find(idx, 1);
    end

    ComparisonData.PairEntries(i).Source.folder = ExperimentIndex.folder{idx};
    ComparisonData.PairEntries(i).Source.figureFolder = ExperimentIndex.figureFolder{idx};
    ComparisonData.PairEntries(i).Source.experimentMatFile = ExperimentIndex.experimentMatFile{idx};
    ComparisonData.PairEntries(i).Source.rsFigureFile = ExperimentIndex.rsFigureFile{idx};

    ComparisonData.PairEntries(i).Source.folderExists = ...
        exist(ExperimentIndex.folder{idx}, 'dir') == 7;

    ComparisonData.PairEntries(i).Source.experimentMatFileExists = ...
        exist(ExperimentIndex.experimentMatFile{idx}, 'file') == 2;

    ComparisonData.PairEntries(i).Source.rsFigureFileExists = ...
        exist(ExperimentIndex.rsFigureFile{idx}, 'file') == 2;
end

end