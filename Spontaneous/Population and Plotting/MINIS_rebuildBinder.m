function binderFile = MINIS_rebuildBinder(Expt)
% Rebuild the complete binder for one recording type.
%
% Expt.recordingType is required. Expt.studyID is ignored for binder scope.
% Cells are ordered by Marker. Validation pages are included according to
% BinderIndex.IncludeValidation.

tic

if ~isfield(Expt,'recordingType') || isempty(Expt.recordingType)
    error('Expt.recordingType must be defined.');
end

paths = MINIS_getPopulationPaths(Expt);
binderIndexFile = paths.binderIndexFile;
binderFile = paths.binderFile;

if ~isfile(binderIndexFile)
    error('Binder index not found: %s',binderIndexFile);
end

tmp = load(binderIndexFile,'BinderIndex');

if ~isfield(tmp,'BinderIndex') || ~istable(tmp.BinderIndex)
    error('BinderIndex file does not contain a BinderIndex table.');
end

BinderIndex = tmp.BinderIndex;

if ismember('RecordingType',BinderIndex.Properties.VariableNames)
    recordingType = string(Expt.recordingType);
    rowType = strtrim(string(BinderIndex.RecordingType));
    keep = strlength(rowType) > 0 & strcmpi(rowType,recordingType);

    if any(~keep)
        warning('%d BinderIndex row(s) do not match recordingType %s and will be skipped.', ...
            sum(~keep),recordingType);
    end

    BinderIndex = BinderIndex(keep,:);
end

BinderIndex = sortrows(BinderIndex,'Marker');

if isempty(BinderIndex)
    error('No BinderIndex rows remain for recordingType %s.',string(Expt.recordingType));
end

[binderFolder,binderName,binderExt] = fileparts(binderFile);
tempBinder = fullfile(binderFolder,[binderName '_building' binderExt]);

if isfile(tempBinder)
    delete(tempBinder);
end

firstPage = true;

%% BUILD TEMP BINDER

for c = 1:height(BinderIndex)

    marker = BinderIndex.Marker(c);
    summaryFigFile = BinderIndex.SummaryFig(c);
    figureFolder = BinderIndex.FigureFolder(c);

    fprintf('Adding %s...\n',marker);

    %% SUMMARY PAGE

    if ~isfile(summaryFigFile)
        warning('%s summary figure is missing. Skipping cell.',marker);
        continue
    end

    fig = openfig(summaryFigFile,'invisible');

    if firstPage
        exportgraphics(fig,tempBinder,'ContentType','vector','BackgroundColor','white');
        firstPage = false;
    else
        exportgraphics(fig,tempBinder,'ContentType','vector','BackgroundColor','white','Append',true);
    end

    delete(fig);

    %% VALIDATION PAGES

    if BinderIndex.IncludeValidation(c)

        validationFiles = getValidationFiles(figureFolder);

        for k = 1:numel(validationFiles)

            validationFile = fullfile(validationFiles(k).folder,validationFiles(k).name);
            fig = createValidationPage(validationFile,marker);

            exportgraphics(fig,tempBinder,'ContentType','vector','BackgroundColor','white','Append',true);

            delete(fig);
        end
    end
end

if firstPage
    error('No valid cell summary figures were found. Binder was not created.');
end

%% REPLACE OLD BINDER ONLY AFTER NEW ONE WAS BUILT SUCCESSFULLY

try
    if isfile(binderFile)
        delete(binderFile);
    end
    movefile(tempBinder,binderFile);
catch ME
    warning('New binder was built at %s but the existing binder could not be replaced.',tempBinder);
    rethrow(ME);
end

fprintf('\nBinder rebuilt successfully:\n%s\n',binderFile);
toc

end

%% CREATE VALIDATION PAGE

function fig = createValidationPage(imageFile,marker)

fig = figure('Color','w','Units','inches','Position',[1 1 8.5 11], ...
    'Visible','off','MenuBar','none','ToolBar','none','NumberTitle','off');

annotation(fig,'rectangle',[0.001 0.001 0.998 0.998], ...
    'Color','w','FaceColor','none','LineWidth',0.01);

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

annotation(fig,'textbox',[contentLeft 0.945 contentWidth 0.03], ...
    'String',marker,'FontSize',12,'FontWeight','bold','EdgeColor','none');

img = imread(imageFile);

if ndims(img) == 2
    img = repmat(img,[1 1 3]);
end

img = cropWhiteBorder(img);

ax = axes(fig,'Units','normalized', ...
    'Position',[contentLeft contentBottom contentWidth contentHeight-0.04]);

image(ax,img);
axis(ax,'image');
axis(ax,'off');

end

%% FIND VALIDATION FILES

function files = getValidationFiles(figureFolder)

files = dir(fullfile(figureFolder,'*Stable Baseline Validation Page *.png'));

if isempty(files)
    return
end

names = string({files.name})';
conditionName = strings(numel(files),1);
pageNum = zeros(numel(files),1);

for k = 1:numel(files)

    tok = regexp(names(k),'^(.*) Page (\d+)\.png$','tokens','once');

    if isempty(tok)
        conditionName(k) = names(k);
        pageNum(k) = 0;
    else
        conditionName(k) = string(tok{1});
        pageNum(k) = str2double(tok{2});
    end
end

orderTable = table(conditionName,pageNum,(1:numel(files))', ...
    'VariableNames',{'Condition','Page','Idx'});

orderTable = sortrows(orderTable,{'Condition','Page'});
files = files(orderTable.Idx);

end

%% CROP IMAGE

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
