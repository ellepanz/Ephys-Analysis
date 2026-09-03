%% Summary plotting - AgaTK and ConoGVIA datasets
% For each dataset: tile 1 = mean waves only, tile 2 = individual + mean
% waves, tile 3 = peak scatter (raw), tile 4 = peak scatter (normalized)

datasets = {'AgaTK', 'ConoGVIA'};

for d = 1:numel(datasets)
    drug = datasets{d};
    AMN  = [drug '_AMN082'];

    % Assign colors for this dataset's two conditions
    condPair = {drug, AMN};
    assignColors(condPair);  % populates color{1}, color{2} in base workspace
    drugColor = color{1};
    amnColor  = color{2};

    %% Collect waves and peaks across experiments
    drugWaves = {};
    amnWaves  = {};
    drugPeaks = [];
    amnPeaks  = [];

    % --- drug condition ---
    nDrug = numel(eval(drug + "." + drug));  % e.g. AgaTK.AgaTK
    drugStruct = eval(drug + "." + drug);

    for i = 1:nDrug
        % Detect experiment type and grab wave
        if ~isempty(drugStruct(i).x5_20Hz) && ~isempty(drugStruct(i).x5_20Hz.avgWave)
            w = drugStruct(i).x5_20Hz.avgWave;
        elseif ~isempty(drugStruct(i).Hz_20) && ~isempty(drugStruct(i).Hz_20.avgWave)
            w = drugStruct(i).Hz_20.avgWave;
        else
            warning('%s.%s(%d): No valid 20Hz wave found, skipping.', drug, drug, i);
            continue
        end
        drugWaves{end+1} = w;
        drugPeaks(end+1) = drugStruct(i).AvgPeaks.x1;
    end

    % --- AMN082 condition ---
    amnStruct = eval(drug + "." + AMN);
    nAMN = numel(amnStruct);

    % Find matched experiments (only cells with both drug and AMN082 recordings)
drugMarkers = {drugStruct.Expt};
amnMarkers  = {amnStruct.Expt};

matchedIdx  = find(ismember(drugMarkers, amnMarkers));

if isempty(matchedIdx)
    warning('No matched experiments found for %s. Skipping.', drug);
    continue
end

drugStruct = drugStruct(matchedIdx);  % trim to matched only
% amnStruct already only contains experiments that have AMN082, no trimming needed
% but reorder it to match drugStruct order
[~, amnOrder] = ismember({drugStruct.Expt}, amnMarkers);
amnStruct = amnStruct(amnOrder);

fprintf('%s: %d matched experiments found.\n', drug, numel(matchedIdx));
    for i = 1:nAMN
        if ~isempty(amnStruct(i).x5_20Hz) && ~isempty(amnStruct(i).x5_20Hz.avgWave)
            w = amnStruct(i).x5_20Hz.avgWave;
        elseif ~isempty(amnStruct(i).Hz_20) && ~isempty(amnStruct(i).Hz_20.avgWave)
            w = amnStruct(i).Hz_20.avgWave;
        else
            warning('%s.%s(%d): No valid 20Hz wave found, skipping.', drug, AMN, i);
            continue
        end
        amnWaves{end+1} = w;
        amnPeaks(end+1) = amnStruct(i).AvgPeaks.x1;
    end

    % Convert wave cell arrays to matrices [samples x nExpts]
drugWaveMat = horzcat(drugWaves{:});  % [14000 x nDrugExpts]
amnWaveMat  = horzcat(amnWaves{:});   % [14000 x nAMNExpts]

    drugMean = mean(drugWaveMat, 2);
    amnMean  = mean(amnWaveMat, 2);

    nSamples = size(drugWaveMat, 1);
    xAxis    = 1:nSamples;

    %% Figure
    fig = figure('Name', drug, 'Position', [100 100 1200 900]);
    t   = tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    sgtitle(drug, 'FontSize', 16, 'Interpreter', 'none');

    %% Tile 1: Mean waves only
    nexttile; hold on;
    plot(xAxis, drugMean, 'Color', drugColor, 'LineWidth', 2, 'DisplayName', drug);
    plot(xAxis, amnMean,  'Color', amnColor,  'LineWidth', 2, 'DisplayName', AMN);
    xlim([800 1950]);
    xlabel('Sample'); ylabel('pA');
    title('Mean waves');
    legend('Interpreter', 'none', 'Location', 'best');

    %% Tile 2: Individual traces + mean overlaid - drug
    nexttile; hold on;
    title([drug ' — individual traces']);
    nD = size(drugWaveMat, 2);
    boneD = flipud(bone(nD + 2));
    boneD(boneD == 1) = 0.9;
    for i = 1:nD
        plot(xAxis, drugWaveMat(:,i), 'Color', boneD(i,:), 'LineWidth', 0.8, ...
            'HandleVisibility', 'off');
    end
    plot(xAxis, drugMean, 'Color', drugColor, 'LineWidth', 2.5, 'DisplayName', 'Mean');
    xlim([800 1950]);
    xlabel('Sample'); ylabel('pA');
    legend('Interpreter', 'none', 'Location', 'best');

    %% Tile 3: Individual traces + mean overlaid - AMN082
    nexttile; hold on;
    title([AMN ' — individual traces'], 'Interpreter', 'none');
    nA = size(amnWaveMat, 2);
    boneA = flipud(bone(nA + 2));
    boneA(boneA == 1) = 0.9;
    for i = 1:nA
        plot(xAxis, amnWaveMat(:,i), 'Color', boneA(i,:), 'LineWidth', 0.8, ...
            'HandleVisibility', 'off');
    end
    plot(xAxis, amnMean, 'Color', amnColor, 'LineWidth', 2.5, 'DisplayName', 'Mean');
    xlim([800 1950]);
    xlabel('Sample'); ylabel('pA');
    legend('Interpreter', 'none', 'Location', 'best');

    %% Tile 4: Peak scatter - raw and normalized side by side
    nexttile; hold on;
    title('First stim peak amplitude');

    % Raw peaks
    scatter(ones(size(drugPeaks)),  drugPeaks, 50, drugColor, 'filled', ...
        'MarkerEdgeColor', 'k', 'DisplayName', drug);
    scatter(2*ones(size(amnPeaks)), amnPeaks,  50, amnColor,  'filled', ...
        'MarkerEdgeColor', 'k', 'DisplayName', AMN);

    % Normalized peaks (each cell normalized to mean of drug condition)
    drugBaseline = mean(drugPeaks);
    scatter(4*ones(size(drugPeaks)),  drugPeaks/drugBaseline,  50, drugColor, 'filled', ...
        'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
    scatter(5*ones(size(amnPeaks)),   amnPeaks/drugBaseline,   50, amnColor,  'filled', ...
        'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');

    % Dividing line between raw and normalized
    xline(3, 'k--', 'HandleVisibility', 'off');
    yline(0, 'Color', colors.gray, 'HandleVisibility', 'off');

    xticks([1 2 4 5]);
    xticklabels({drug, AMN, [drug ' norm'], [AMN ' norm']});
    xtickangle(25);
    xlim([0 6]);
    ylabel('pA / normalized');
    legend('Interpreter', 'none', 'Location', 'best');

    saveas(fig, fullfile(figureFolder, [drug '_summary.fig']));
    saveas(fig, fullfile(figureFolder, [drug '_summary.png']));
end