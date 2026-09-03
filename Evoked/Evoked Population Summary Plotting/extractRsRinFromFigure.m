function QC = extractRsRinFromFigure(rsFigureFile)
% extractRsRinFromFigure
%
% Extracts plotted Rs/Rin data from a saved MATLAB .fig file.
%
% Handles both:
%   - old figures with only Rs
%   - newer figures with Rs and Rin
%
% Output:
%   QC.Rs.x
%   QC.Rs.y
%   QC.Rin.x
%   QC.Rin.y
%   QC.sourceFile

QC = struct();
QC.sourceFile = rsFigureFile;
QC.Rs = struct('x', [], 'y', []);
QC.Rin = struct('x', [], 'y', []);

if ~exist(rsFigureFile, 'file')
    warning('Figure file not found: %s', rsFigureFile);
    return
end

% Open invisibly so it does not flash onscreen
fig = openfig(rsFigureFile, 'invisible');

cleanupObj = onCleanup(@() close(fig));

axesList = findall(fig, 'Type', 'axes');

% Ignore legends/colorbars if any sneak in
axesList = axesList(~strcmp(get(axesList, 'Tag'), 'legend'));

for a = 1:numel(axesList)

    ax = axesList(a);

    axTitle = '';
    if ~isempty(ax.Title) && isvalid(ax.Title)
        axTitle = string(ax.Title.String);
    end

    yLabel = '';
    if ~isempty(ax.YLabel) && isvalid(ax.YLabel)
        yLabel = string(ax.YLabel.String);
    end

    plotObjs = findall(ax, '-property', 'YData');

    if isempty(plotObjs)
        continue
    end

    % Use the first plotted object with numeric YData
    xData = [];
    yData = [];

    for k = 1:numel(plotObjs)
        thisY = plotObjs(k).YData;

        if isnumeric(thisY) && ~isempty(thisY)
            yData = thisY(:);

            if isprop(plotObjs(k), 'XData')
                xData = plotObjs(k).XData(:);
            else
                xData = (1:numel(yData))';
            end

            break
        end
    end

    if isempty(yData)
        continue
    end

    labelText = lower(strjoin([axTitle, yLabel], " "));

    if contains(labelText, "rin") || contains(labelText, "input")
        QC.Rin.x = xData;
        QC.Rin.y = yData;

    elseif contains(labelText, "rs") || contains(labelText, "series")
        QC.Rs.x = xData;
        QC.Rs.y = yData;

    else
        % Fallback logic:
        % If only one axis exists, assume old Rs-only figure.
        % If multiple axes exist and Rs is empty, assign first unknown to Rs.
        if numel(axesList) == 1 && isempty(QC.Rs.y)
            QC.Rs.x = xData;
            QC.Rs.y = yData;
        elseif isempty(QC.Rs.y)
            QC.Rs.x = xData;
            QC.Rs.y = yData;
        elseif isempty(QC.Rin.y)
            QC.Rin.x = xData;
            QC.Rin.y = yData;
        end
    end
end

end