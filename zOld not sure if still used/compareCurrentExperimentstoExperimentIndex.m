%% compareCurrentExptsToExperimentIndex
% Compares Expt markers across:
%   ExperimentIndex.Expt
%   AgaTK_current.AgaTK.Expt
%   ConoGVIA_current.ConoGVIA.Expt

%% Pull experiment lists

indexExpts = string(ExperimentIndex.Expt);

agaExpts = string({AgaTK_current.AgaTK.Expt});
conoExpts = string({ConoGVIA_current.ConoGVIA.Expt});

combinedCurrentExpts = [agaExpts(:); conoExpts(:)];

%% Unique lists

uniqueIndexExpts = unique(indexExpts, 'stable');
uniqueAgaExpts = unique(agaExpts, 'stable');
uniqueConoExpts = unique(conoExpts, 'stable');
uniqueCombinedCurrentExpts = unique(combinedCurrentExpts, 'stable');

%% Basic counts

fprintf('\n===== BASIC COUNTS =====\n');
fprintf('ExperimentIndex rows:                  %d\n', numel(indexExpts));
fprintf('ExperimentIndex unique Expt markers:   %d\n', numel(uniqueIndexExpts));
fprintf('AgaTK_current.AgaTK entries:           %d\n', numel(agaExpts));
fprintf('AgaTK_current.AgaTK unique markers:    %d\n', numel(uniqueAgaExpts));
fprintf('ConoGVIA_current.ConoGVIA entries:     %d\n', numel(conoExpts));
fprintf('ConoGVIA_current.ConoGVIA unique:      %d\n', numel(uniqueConoExpts));
fprintf('Aga + Cono combined entries:           %d\n', numel(combinedCurrentExpts));
fprintf('Aga + Cono combined unique markers:    %d\n', numel(uniqueCombinedCurrentExpts));

%% Missing checks

missingFromCurrent = setdiff(uniqueIndexExpts, uniqueCombinedCurrentExpts, 'stable');
missingFromIndex = setdiff(uniqueCombinedCurrentExpts, uniqueIndexExpts, 'stable');

fprintf('\n===== MISSING CHECKS =====\n');

fprintf('\nIn ExperimentIndex but NOT in AgaTK_current or ConoGVIA_current:\n');
disp(missingFromCurrent)

fprintf('\nIn AgaTK_current or ConoGVIA_current but NOT in ExperimentIndex:\n');
disp(missingFromIndex)

%% Experiments appearing in both Aga and Cono

inBothAgaAndCono = intersect(uniqueAgaExpts, uniqueConoExpts, 'stable');

fprintf('\n===== OVERLAP BETWEEN AGA AND CONO CURRENT =====\n');
fprintf('Experiments present in BOTH AgaTK_current.AgaTK and ConoGVIA_current.ConoGVIA:\n');
disp(inBothAgaAndCono)

%% Duplicate checks

dupIndex = findDuplicates(indexExpts);
dupAga = findDuplicates(agaExpts);
dupCono = findDuplicates(conoExpts);
dupCombined = findDuplicates(combinedCurrentExpts);

fprintf('\n===== DUPLICATE CHECKS =====\n');

fprintf('\nDuplicates within ExperimentIndex:\n');
disp(dupIndex)

fprintf('\nDuplicates within AgaTK_current.AgaTK:\n');
disp(dupAga)

fprintf('\nDuplicates within ConoGVIA_current.ConoGVIA:\n');
disp(dupCono)

fprintf('\nDuplicates across combined Aga + Cono current lists:\n');
disp(dupCombined)

%% Build a comparison table

allExpts = unique([uniqueIndexExpts(:); uniqueCombinedCurrentExpts(:)], 'stable');

CompareTable = table();
CompareTable.Expt = allExpts;
CompareTable.InExperimentIndex = ismember(allExpts, indexExpts);
CompareTable.InAgaTK_current = ismember(allExpts, agaExpts);
CompareTable.InConoGVIA_current = ismember(allExpts, conoExpts);
CompareTable.InEitherCurrent = CompareTable.InAgaTK_current | CompareTable.InConoGVIA_current;

CompareTable.Status = strings(height(CompareTable), 1);

for i = 1:height(CompareTable)

    if CompareTable.InExperimentIndex(i) && CompareTable.InEitherCurrent(i)
        CompareTable.Status(i) = "OK";
    elseif CompareTable.InExperimentIndex(i) && ~CompareTable.InEitherCurrent(i)
        CompareTable.Status(i) = "In index only";
    elseif ~CompareTable.InExperimentIndex(i) && CompareTable.InEitherCurrent(i)
        CompareTable.Status(i) = "In current only";
    end

    if CompareTable.InAgaTK_current(i) && CompareTable.InConoGVIA_current(i)
        CompareTable.Status(i) = CompareTable.Status(i) + " / in both Aga and Cono";
    end
end

CompareTable = sortrows(CompareTable, 'Expt');

fprintf('\n===== FULL COMPARISON TABLE =====\n');
disp(CompareTable)

%% Optional: save comparison output

save('CurrentExpt_IndexComparison.mat', ...
    'CompareTable', ...
    'missingFromCurrent', ...
    'missingFromIndex', ...
    'inBothAgaAndCono', ...
    'dupIndex', ...
    'dupAga', ...
    'dupCono', ...
    'dupCombined');

fprintf('\nSaved comparison results to CurrentExpt_IndexComparison.mat\n');


%% Local helper function

function dupes = findDuplicates(exptList)

    uniqueExpts = unique(exptList, 'stable');
    counts = zeros(size(uniqueExpts));

    for k = 1:numel(uniqueExpts)
        counts(k) = sum(exptList == uniqueExpts(k));
    end

    dupes = uniqueExpts(counts > 1);
end