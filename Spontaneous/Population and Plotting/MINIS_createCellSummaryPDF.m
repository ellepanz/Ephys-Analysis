function [pdfFile,BinderIndex] = MINIS_createCellSummaryPDF(Expt,figureFolder,includeValidationPages,conditions,dataFile)
% Create/update the printable PDF packet for one MINIS cell.
%
% includeValidationPages = true/false
%
% BinderIndex is recording-type-wide. Population membership is study-specific
% and is stored in BinderIndex.IncludeInPopulation.

if nargin < 3
    includeValidationPages = false;
end

if nargin < 4
    conditions = {};
end

if nargin < 5
    dataFile = '';
end

%% FILES

paths = MINIS_getPopulationPaths(Expt);
populationFile = paths.populationFile;
binderIndexFile = paths.binderIndexFile;

cellFolder = fileparts(figureFolder);

stabilityFile = fullfile(figureFolder,'Baseline Sigma Rs Rin Stable Selection.png');
baselineValidationFile = fullfile(figureFolder,'Stable Baseline Fit Summary.png');
summaryFile = fullfile(figureFolder,'Holding Synaptic Excess Variability.png');

pdfFile = fullfile(cellFolder,sprintf('%s_summary.pdf',Expt.marker));
summaryFigFile = fullfile(cellFolder,sprintf('%s_summary.fig',Expt.marker));

if strlength(string(dataFile)) == 0
    dataFile = resolveDataFile(cellFolder,Expt.marker,binderIndexFile);
else
    dataFile = char(string(dataFile));
end

if ~isfile(stabilityFile)
    error('Stability figure not found: %s',stabilityFile);
end

hasBaselineValidation = isfile(baselineValidationFile);
hasSummary = isfile(summaryFile);

%% LOAD/UPGRADE BINDER INDEX

BinderIndex = table;
hadPopulationDecision = false;

if isfile(binderIndexFile)
    tmp = load(binderIndexFile,'BinderIndex');

    if isfield(tmp,'BinderIndex') && istable(tmp.BinderIndex)
        hadPopulationDecision = ismember('IncludeInPopulation',tmp.BinderIndex.Properties.VariableNames);
        BinderIndex = upgradeBinderIndex(tmp.BinderIndex);
    end
end

%% IS THIS CELL IN THE POPULATION?

includeInPopulation = false;
exclusionReason = "";
existingIdx = [];

if ~isempty(BinderIndex)
    existingIdx = find(string(BinderIndex.Marker) == string(Expt.marker));
end

if ~isempty(existingIdx) && hadPopulationDecision
    includeInPopulation = BinderIndex.IncludeInPopulation(existingIdx(1));
    exclusionReason = string(BinderIndex.ExclusionReason(existingIdx(1)));
elseif ~isempty(populationFile) && isfile(populationFile)
    tmp = load(populationFile,'Population');

    if isfield(tmp,'Population') && istable(tmp.Population) && ismember('CellID',tmp.Population.Properties.VariableNames)
        includeInPopulation = any(string(tmp.Population.CellID) == string(Expt.marker));
    end
end

%% METADATA

metaLines = [
    "Experiment:          " + string(Expt.marker)
    "Date:                " + string(Expt.date)
    "Starting Condition:  " + string(Expt.startingCond)
    "Drug Condition:      " + string(Expt.drugCond)
    "Drug Duration:       " + string(Expt.drugTime)
    "Internal:            " + string(Expt.internal)
    "Holding Potential:   " + string(Expt.Vh)
    "Temperature:         " + string(Expt.temp)
    "Ca2+/Mg2+:           " + string(Expt.CaMg)
    "Genotype:            " + string(Expt.genotype)
    "Mouse Age:           " + string(Expt.age)
    "Cell Type:           " + string(Expt.cellType)
    "Brain Region:        " + string(Expt.region)
    "Trial Interval:      " + string(Expt.trialInterval) + " s"
    "Folder:              " + string(cellFolder)
];

metadataText = strjoin(metaLines,newline);

%% CREATE LETTER-SIZE SUMMARY PAGE

fig = figure('Color','w','Units','inches','Position',[1 1 8.5 11],'Visible','off','MenuBar','none','ToolBar','none','NumberTitle','off');

annotation(fig,'rectangle',[0.001 0.001 0.998 0.998],'Color','w','FaceColor','none','LineWidth',0.01);

pageWidth = 8.5;
pageHeight = 11;

leftMargin = 0.85/pageWidth;
rightMargin = 0.40/pageWidth;
topMargin = 0.40/pageHeight;
bottomMargin = 0.40/pageHeight;

contentLeft = leftMargin;
contentBottom = bottomMargin;
contentWidth = 1-leftMargin-rightMargin;
contentHeight = 1-topMargin-bottomMargin;

%% TITLE

annotation(fig,'textbox',[contentLeft contentBottom+0.955*contentHeight contentWidth 0.03], ...
    'String',sprintf('%s Summary',Expt.marker),'FontSize',14,'FontWeight','bold', ...
    'EdgeColor','none','HorizontalAlignment','center');

%% POPULATION CHECKBOX

boxX = contentLeft;
boxY = contentBottom+0.915*contentHeight;
boxW = 0.027;
boxH = 0.021;

annotation(fig,'rectangle',[boxX boxY boxW boxH],'LineWidth',1.2);

if includeInPopulation
    annotation(fig,'line',[boxX+0.005 boxX+0.011],[boxY+0.010 boxY+0.005],'LineWidth',1.5);
    annotation(fig,'line',[boxX+0.011 boxX+0.023],[boxY+0.005 boxY+0.017],'LineWidth',1.5);
end

annotation(fig,'textbox',[boxX+0.035 boxY-0.005 0.50 0.03], ...
    'String','Include in population analysis?','FontSize',10.5, ...
    'EdgeColor','none','VerticalAlignment','middle');

if ~includeInPopulation && strlength(exclusionReason) > 0
    annotation(fig,'textbox',[boxX+0.035 boxY-0.035 contentWidth-0.04 0.03], ...
        'String',"Reason: " + exclusionReason,'FontSize',8.5,'Interpreter','none', ...
        'EdgeColor','none','VerticalAlignment','middle');
end

%% METADATA

metadataPosition = [contentLeft contentBottom+0.70*contentHeight contentWidth 0.19*contentHeight];

annotation(fig,'textbox',metadataPosition,'String',metadataText,'FontName','Consolas', ...
    'FontSize',8.5,'Interpreter','none','EdgeColor','none','VerticalAlignment','top');

%% ANALYSIS FIGURES

figureGap = 0.02;
halfWidth = (contentWidth-figureGap)/2;

stabilityPosition = [contentLeft contentBottom+0.38*contentHeight contentWidth 0.29*contentHeight];
baselineValidationPosition = [contentLeft contentBottom+0.04*contentHeight halfWidth 0.29*contentHeight];
summaryPosition = [contentLeft+halfWidth+figureGap contentBottom+0.04*contentHeight halfWidth 0.29*contentHeight];

addImageToPage(fig,stabilityFile,stabilityPosition);

if hasBaselineValidation
    addImageToPage(fig,baselineValidationFile,baselineValidationPosition);
else
    addPlaceholderToPage(fig,baselineValidationPosition,'Stable baseline validation not performed');
end

if hasSummary
    addImageToPage(fig,summaryFile,summaryPosition);
else
    addPlaceholderToPage(fig,summaryPosition,'Holding/synaptic excess analysis not performed');
end

%% SAVE SUMMARY FIGURE SOURCE

if isfile(summaryFigFile)
    delete(summaryFigFile);
end

savefig(fig,summaryFigFile);

%% CREATE INDIVIDUAL CELL PDF

if isfile(pdfFile)
    delete(pdfFile);
end

exportgraphics(fig,pdfFile,'ContentType','vector','BackgroundColor','white');

%% ADD VALIDATION PAGES TO INDIVIDUAL CELL PDF

if includeValidationPages
    validationFiles = getValidationFiles(figureFolder,conditions);

    for k = 1:numel(validationFiles)
        validationFile = fullfile(validationFiles(k).folder,validationFiles(k).name);
        validationFig = createValidationPage(validationFile,Expt.marker);
        exportgraphics(validationFig,pdfFile,'ContentType','vector','BackgroundColor','white','Append',true);
        delete(validationFig);
    end
end

delete(fig);

%% UPDATE BINDER INDEX

newRow = table(string(Expt.marker),string(Expt.recordingType),string(Expt.studyID), ...
    string(dataFile),string(figureFolder),string(summaryFigFile),string(pdfFile), ...
    logical(includeValidationPages),logical(includeInPopulation),string(exclusionReason),datetime('now'), ...
    'VariableNames',{'Marker','RecordingType','StudyID','DataFile','FigureFolder', ...
    'SummaryFig','SummaryPDF','IncludeValidation','IncludeInPopulation','ExclusionReason','LastUpdated'});

if isempty(BinderIndex)
    BinderIndex = newRow([],:);
else
    BinderIndex = upgradeBinderIndex(BinderIndex);
end

existingIdx = find(string(BinderIndex.Marker) == string(Expt.marker));

if isempty(existingIdx)
    BinderIndex = [BinderIndex; newRow];
else
    BinderIndex(existingIdx(1),:) = newRow;

    if numel(existingIdx) > 1
        BinderIndex(existingIdx(2:end),:) = [];
    end
end

BinderIndex = sortrows(BinderIndex,'Marker');
save(binderIndexFile,'BinderIndex');

fprintf('Created %s\n',pdfFile);
fprintf('Validation pages: %s\n',string(includeValidationPages));
fprintf('Population inclusion: %s\n',string(includeInPopulation));

end

%% UPGRADE/ORDER BINDER INDEX

function BinderIndex = upgradeBinderIndex(BinderIndex)

n = height(BinderIndex);

if ~ismember('Marker',BinderIndex.Properties.VariableNames)
    error('BinderIndex is missing Marker.');
end
if ~ismember('RecordingType',BinderIndex.Properties.VariableNames)
    BinderIndex.RecordingType = strings(n,1);
end
if ~ismember('StudyID',BinderIndex.Properties.VariableNames)
    BinderIndex.StudyID = strings(n,1);
end
if ~ismember('DataFile',BinderIndex.Properties.VariableNames)
    BinderIndex.DataFile = strings(n,1);
end
if ~ismember('FigureFolder',BinderIndex.Properties.VariableNames)
    BinderIndex.FigureFolder = strings(n,1);
end
if ~ismember('SummaryFig',BinderIndex.Properties.VariableNames)
    BinderIndex.SummaryFig = strings(n,1);
end
if ~ismember('SummaryPDF',BinderIndex.Properties.VariableNames)
    BinderIndex.SummaryPDF = strings(n,1);
end
if ~ismember('IncludeValidation',BinderIndex.Properties.VariableNames)
    BinderIndex.IncludeValidation = false(n,1);
end
if ~ismember('IncludeInPopulation',BinderIndex.Properties.VariableNames)
    BinderIndex.IncludeInPopulation = false(n,1);
end
if ~ismember('ExclusionReason',BinderIndex.Properties.VariableNames)
    BinderIndex.ExclusionReason = strings(n,1);
end
if ~ismember('LastUpdated',BinderIndex.Properties.VariableNames)
    BinderIndex.LastUpdated = NaT(n,1);
end

vars = {'Marker','RecordingType','StudyID','DataFile','FigureFolder','SummaryFig', ...
    'SummaryPDF','IncludeValidation','IncludeInPopulation','ExclusionReason','LastUpdated'};
BinderIndex = BinderIndex(:,vars);

end

%% RESOLVE CURRENT DATA FILE

function dataFile = resolveDataFile(cellFolder,marker,binderIndexFile)

candidateFiles = [dir(fullfile(cellFolder,[marker '.mat'])); dir(fullfile(cellFolder,[marker '_data.mat']))];

if isempty(candidateFiles)
    error('No saved data file found for %s in %s.',marker,cellFolder);
end

matches = string(fullfile({candidateFiles.folder},{candidateFiles.name}))';

if numel(matches) == 1
    dataFile = char(matches);
    return
end

if isfile(binderIndexFile)
    tmp = load(binderIndexFile,'BinderIndex');

    if isfield(tmp,'BinderIndex') && istable(tmp.BinderIndex) && ...
            ismember('Marker',tmp.BinderIndex.Properties.VariableNames) && ...
            ismember('DataFile',tmp.BinderIndex.Properties.VariableNames)
        idx = find(string(tmp.BinderIndex.Marker) == string(marker),1);

        if ~isempty(idx)
            requestedFile = string(tmp.BinderIndex.DataFile(idx));
            [~,requestedName,requestedExt] = fileparts(requestedFile);
            requestedBase = requestedName + requestedExt;

            [~,names,exts] = cellfun(@fileparts,cellstr(matches),'UniformOutput',false);
            candidateBase = string(strcat(names,exts));
            sameName = strcmpi(candidateBase,requestedBase);

            if sum(sameName) == 1
                dataFile = char(matches(sameName));
                return
            end
        end
    end
end

error('Multiple saved data files found for %s. Pass the active dataFile as the fifth input.\n%s', ...
    marker,strjoin(matches,newline));

end
%% ADD IMAGE TO PAGE

function addImageToPage(fig,imageFile,position)

img = imread(imageFile);

if ndims(img) == 2
    img = repmat(img,[1 1 3]);
end

img = cropWhiteBorder(img);

ax = axes(fig,'Units','normalized','Position',position);
image(ax,img);
axis(ax,'image');
axis(ax,'off');

end


%% ADD PLACEHOLDER TO PAGE

function addPlaceholderToPage(fig,position,message)

annotation(fig,'textbox',position,'String',message,'FontSize',10, ...
    'HorizontalAlignment','center','VerticalAlignment','middle', ...
    'EdgeColor',[0.7 0.7 0.7],'LineStyle','--','Interpreter','none');

end


%% CREATE VALIDATION PAGE

function fig = createValidationPage(imageFile,marker)

fig = figure('Color','w','Units','inches','Position',[1 1 8.5 11],'Visible','off','MenuBar','none','ToolBar','none','NumberTitle','off');

annotation(fig,'rectangle',[0.001 0.001 0.998 0.998],'Color','w','FaceColor','none','LineWidth',0.01);

pageWidth = 8.5;
pageHeight = 11;

leftMargin = 0.85/pageWidth;
rightMargin = 0.40/pageWidth;
topMargin = 0.40/pageHeight;
bottomMargin = 0.40/pageHeight;

contentLeft = leftMargin;
contentBottom = bottomMargin;
contentWidth = 1-leftMargin-rightMargin;
contentHeight = 1-topMargin-bottomMargin;

annotation(fig,'textbox',[contentLeft 0.945 contentWidth 0.03],'String',marker, ...
    'FontSize',12,'FontWeight','bold','EdgeColor','none');

img = imread(imageFile);

if ndims(img) == 2
    img = repmat(img,[1 1 3]);
end

img = cropWhiteBorder(img);

ax = axes(fig,'Units','normalized','Position',[contentLeft contentBottom contentWidth contentHeight-0.04]);
image(ax,img);
axis(ax,'image');
axis(ax,'off');

end


%% FIND AND SORT VALIDATION PAGES

function files = getValidationFiles(figureFolder,conditions)

files = dir(fullfile(figureFolder,'*Stable Baseline Validation Page *.png'));

if isempty(files)
    return
end

names = string({files.name})';
conditionName = strings(numel(files),1);
pageNum = zeros(numel(files),1);

for k = 1:numel(files)
    tok = regexp(names(k),'^(.*?) Stable Baseline Validation Page (\d+)\.png$','tokens','once');

    if isempty(tok)
        conditionName(k) = names(k);
        pageNum(k) = 0;
    else
        conditionName(k) = string(tok{1});
        pageNum(k) = str2double(tok{2});
    end
end

if ~isempty(conditions)
    conditions = string(conditions(:));
    conditionOrder = inf(numel(files),1);

    for k = 1:numel(files)
        idx = find(strcmpi(conditionName(k),conditions),1);
        if ~isempty(idx)
            conditionOrder(k) = idx;
        end
    end

    orderTable = table(conditionOrder,pageNum,(1:numel(files))', ...
        'VariableNames',{'ConditionOrder','Page','Idx'});
    orderTable = sortrows(orderTable,{'ConditionOrder','Page'});
else
    orderTable = table(conditionName,pageNum,(1:numel(files))', ...
        'VariableNames',{'Condition','Page','Idx'});
    orderTable = sortrows(orderTable,{'Condition','Page'});
end

files = files(orderTable.Idx);

end


%% CROP PNG WHITE BORDER

function img = cropWhiteBorder(img)

if isa(img,'uint16')
    img8 = uint8(double(img)/65535*255);
elseif isa(img,'double')
    img8 = uint8(img*255);
else
    img8 = img;
end

contentMask = any(img8 < 248,3);

rows = find(any(contentMask,2));
cols = find(any(contentMask,1));

if isempty(rows) || isempty(cols)
    return
end

padding = 40;

r1 = max(rows(1)-padding,1);
r2 = min(rows(end)+padding,size(img,1));
c1 = max(cols(1)-padding,1);
c2 = min(cols(end)+padding,size(img,2));

img = img(r1:r2,c1:c2,:);

end