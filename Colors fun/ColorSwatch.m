%% COLOR SWATCH



Colors

% Flatten all colors in the struct
[colorNames, colorVals] = flattenColors(colors);

numColors = length(colorNames);

% Grid layout
nCols = 3;
nRows = ceil(numColors / nCols);

% Create figure
figure('Color','w', ...
    'Position',[100 100 1100 700]);

axis off;
hold on;

% Swatch dimensions
swatchWidth  = 0.45;
swatchHeight = 0.35;
xSpacing = 1.8;
ySpacing = 0.55;

% Plot swatches
for i = 1:numColors

    % Fill down each column
    row = nRows - mod(i-1,nRows);
    col = floor((i-1)/nRows);

    x = 0.1 + col*xSpacing;
    y = (row-1)*ySpacing + 0.1;

    rectangle('Position',[x y swatchWidth swatchHeight], ...
        'FaceColor',colorVals{i}, ...
        'EdgeColor','k');

    text(x + swatchWidth + 0.08, ...
         y + swatchHeight/2, ...
         colorNames{i}, ...
         'FontSize',10, ...
         'Interpreter','none', ...
         'VerticalAlignment','middle');
end

xlim([0 nCols*xSpacing]);
ylim([0 nRows*ySpacing + 0.5]);

title('All Stored Colors','FontSize',14);

hold off;


%% Local function
function [names, vals] = flattenColors(S, prefix)

    if nargin < 2
        prefix = '';
    end

    names = {};
    vals = {};

    fields = fieldnames(S);

    for i = 1:length(fields)

        field = fields{i};
        value = S.(field);

        if isempty(prefix)
            fullName = field;
        else
            fullName = [prefix '.' field];
        end

        if isstruct(value)

            % Recursively go into nested structs
            [subNames, subVals] = flattenColors(value, fullName);

            names = [names; subNames];
            vals  = [vals; subVals];

        else

            names{end+1,1} = fullName;
            vals{end+1,1} = value;

        end
    end
end