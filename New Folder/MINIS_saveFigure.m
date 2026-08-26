function MINIS_saveFigure(fig, figureFolder, fileName)
% Save each figure as both MATLAB .fig and 300-dpi .png.

if nargin < 2 || isempty(figureFolder)
    return
end

if ~exist(figureFolder, 'dir')
    mkdir(figureFolder);
end

safeName = regexprep(fileName, '[^a-zA-Z0-9 _-]', '_');

savefig(fig, fullfile(figureFolder, [safeName '.fig']));

try
    exportgraphics(fig, fullfile(figureFolder, [safeName '.png']), ...
        'Resolution', 300);
catch
    saveas(fig, fullfile(figureFolder, [safeName '.png']));
end
end
