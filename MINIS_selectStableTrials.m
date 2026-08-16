function Data = MINIS_selectStableTrials(Data, conditions, color)

%% Plot mean current of QC-passed trials versus experimental time

figure('Color','w', 'position', [1 49 1920 955]);
hold on

%% Find first trial number in experiment
allTrialNums = [];

for c = 1:numel(conditions)
    cond = conditions{c};

    fields = fieldnames(Data.(cond));

    isTrial = ~cellfun('isempty', ...
        regexp(fields,'^AD0_\d+$','once'));

    names = fields(isTrial);

    nums = cellfun(@(x) sscanf(x,'AD0_%d'), names)';

    allTrialNums = [allTrialNums nums];
end

firstTrialNum = min(allTrialNums);


%% Loop through conditions

conditionStartTimes = nan(1,numel(conditions));
for c = 1:numel(conditions)

    cond = conditions{c};

    %% QC-passed trials
    trialNums = Data.(cond).QCTrialNums;
    allTrials = Data.(cond).finalMiniData;

    nTrials = numel(trialNums);

    meanCurrent = nan(1,nTrials);
    trialTime = nan(1,nTrials);

    %% Calculate mean of each QC-passed trial

    for k = 1:nTrials
        trace = allTrials(:,k);

        meanCurrent(k) = mean(trace);

        % Each acquisition starts exactly 30 sec apart.
        % Plot mean at midpoint of 20-sec acquisition.
        trialTime(k) = ...
            ((trialNums(k) - firstTrialNum)*30 + 10)/60;
    end

    %% Store
    Data.(cond).meanCurrent = meanCurrent;
    Data.(cond).trialTimeSec = trialTime;

    %% Find actual start of condition
    fields = fieldnames(Data.(cond));

    isTrial = ~cellfun('isempty', ...
        regexp(fields,'^AD0_\d+$','once'));

    originalNames = fields(isTrial);

    originalNums = cellfun(@(x) ...
        sscanf(x,'AD0_%d'), originalNames);

    firstCondTrial = min(originalNums);

    conditionStartTimes(c) = ...
        ((firstCondTrial-firstTrialNum)*30)/60;

    %% Plot

    plot(trialTime, meanCurrent, '-o', ...
        'Color',color{c}, ...
        'MarkerFaceColor',color{c}, ...
        'LineWidth',1.5, ...
        'DisplayName',strrep(cond,'_','/'));
end


%% Condition boundaries
for c = 2:numel(conditions)
    xline(conditionStartTimes(c), ...
        '--', ...
        'LineWidth',1.5, ...
        'Color',[0.4 0.4 0.4], ...
        'HandleVisibility','off');
end

%% Formatting
title('All-Point Mean Per Trial');
xlabel('Time (min)');
ylabel('Mean Current (pA)');
legend('Location','best');

%% =========================================================
% SELECT STABLE CONTROL TRIALS
% ==========================================================

disp('Click FIRST stable TTX/NBQX trial');
[x1,~] = ginput(1);

disp('Click LAST stable TTX/NBQX trial');
[x2,~] = ginput(1);

% Find nearest QC-passed points
[~,idx1] = min(abs(Data.TTX_NBQX.trialTime - x1));
[~,idx2] = min(abs(Data.TTX_NBQX.trialTime - x2));

controlIdx = min(idx1,idx2):max(idx1,idx2);

%% Store stable control trials

Data.TTX_NBQX.stableTrialNums = ...
    Data.TTX_NBQX.QCTrialNums(controlIdx);

Data.TTX_NBQX.stableTrialNames = ...
    Data.TTX_NBQX.QCTrialNames(controlIdx);

Data.TTX_NBQX.stableMiniData = ...
    Data.TTX_NBQX.finalMiniData(:,controlIdx);

% Highlight selected trials
plot( ...
    Data.TTX_NBQX.trialTime(controlIdx), ...
    Data.TTX_NBQX.meanCurrent(controlIdx), ...
    'ko', ...
    'MarkerSize',10, ...
    'LineWidth',2, ...
    'HandleVisibility','off');


%% =========================================================
% SELECT STABLE WASH TRIALS
% ==========================================================

disp('Click FIRST stable Wash trial');
[x1,~] = ginput(1);

disp('Click LAST stable Wash trial');
[x2,~] = ginput(1);

[~,idx1] = min(abs(Data.Wash.trialTime - x1));
[~,idx2] = min(abs(Data.Wash.trialTime - x2));

washIdx = min(idx1,idx2):max(idx1,idx2);

%% Store stable wash trials

Data.Wash.stableTrialNums = ...
    Data.Wash.QCTrialNums(washIdx);

Data.Wash.stableTrialNames = ...
    Data.Wash.QCTrialNames(washIdx);

Data.Wash.stableMiniData = ...
    Data.Wash.finalMiniData(:,washIdx);

% Highlight selected trials
plot( ...
    Data.Wash.trialTime(washIdx), ...
    Data.Wash.meanCurrent(washIdx), ...
    'ko', ...
    'MarkerSize',10, ...
    'LineWidth',2, ...
    'HandleVisibility','off');

%% Concatenate stable trials
for c = 1:numel(conditions)

    cond = conditions{c};

    if isfield(Data.(cond), 'stableMiniData')

        Data.(cond).stableConcatData = ...
            Data.(cond).stableMiniData(:);

    end
end
end