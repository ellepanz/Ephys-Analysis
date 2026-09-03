% Overall EPSC summary: v1 7/10/25
% v2: 7/10, added a section to compile avg peaks
% v3: Changed to function to run within summary plots script 8/12/25
% 9/28/25: trying to update this again to be a summarizing/plotting
% function? so lost

function Datasum(numConds, pharm1, varagin)


hzFields = {'x1', 'x5_5Hz', 'x5_20Hz', 'x5_40Hz'};
hzSuffixes = {'x1', 'Hz5', 'Hz20', 'Hz40'};
pharmConds = {'Control', pharmSave, 'AgaTK_CdCl2', 'AgaTK_Muscarine'};
pharmSuffixes = {'Ctrl', pharmSave, 'CdCl2', 'Muscarine'}; % Can't have - 

% Pre-extract experiment names for fast matching
exptLists = struct();
for c = 1:length(pharmConds)
    cond = pharmConds{c};
    exptLists.(cond) = {EPSC_SUMMARY.(cond).Expt};
end

for jj = 1:length(selectedRows)
    j = selectedRows(jj);
    exptName = EPSC_SUMMARY.(pharmSave)(j).Expt;

    % Append to end of DaraSum.EPSCs.(pharmSave)
    if isfield(DataSum.EPSCs, pharmSave)
        rowNum = numel(DataSum.EPSCs.(pharmSave)) + 1;
    else
        rowNum = 1;
    end

    DataSum.EPSCs.(pharmSave)(rowNum).Expt = exptName;   

    for c = 1:length(pharmConds)
        cond = pharmConds{c};
        condSuffix = pharmSuffixes{c};
        matchIdx = find(strcmp(exptLists.(cond), exptName), 1);

        if isempty(matchIdx)
            continue
        end

        for h = 1:length(hzFields)
            hzField = hzFields{h};       % e.g., 'x1'
            hzSuffix = hzSuffixes{h};   % e.g., 'Hz5'

            % avgWave
            if isfield(EPSC_SUMMARY.(cond)(matchIdx), hzField)
                avgWave = EPSC_SUMMARY.(cond)(matchIdx).(hzField).avgWave;
                dataField = sprintf('%s_%savgWave', hzSuffix, condSuffix);
                DataSum.EPSCs.(pharmSave)(rowNum).(dataField) = avgWave;
            end

            % PPR
            if isfield(EPSC_SUMMARY.(cond)(matchIdx), 'PPR') && ...
               isfield(EPSC_SUMMARY.(cond)(matchIdx).PPR, hzField)
                PPRval = EPSC_SUMMARY.(cond)(matchIdx).PPR.(hzField).PPR;
                pprField = sprintf('%s_%sPPR', hzSuffix, condSuffix);
                DataSum.EPSCs.(pharmSave)(rowNum).(pprField) = PPRval;
            end
        end

        % AvgPeaks (only stored once per condition per expt)
        if isfield(EPSC_SUMMARY.(cond)(matchIdx), 'AvgPeaks')
            DataSum.EPSCs.(pharmSave)(rowNum).(['AvgPeaks_' condSuffix]) = ...
                EPSC_SUMMARY.(cond)(matchIdx).AvgPeaks;
        end
    end
end
