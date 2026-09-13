function color = assignColors(conditions)

Colors
color = cell(1, numel(conditions));

for i = 1:numel(conditions)

    cond = conditions{i};
    
    % Handle drug names that are hyphonated
     if contains(cond,'SNX_482')
        color{i} = colors.greens.medium;
        continue
    end
    
    % Split condition at underscores
    parts = split(cond, '_');

    % Use the last drug in the condition
    drug = parts{end};

    switch drug

        case 'Control'
            color{i} = colors.gray;

        case 'AgaTK'
            color{i} = colors.Aga;

        case 'ConoGVIA'
            color{i} = colors.Cono;

        case 'CdCl2'
            color{i} = colors.CdCl2;

        case 'Muscarine'
            color{i} = colors.Muscarine;

        case 'AMN082'
            color{i} = colors.AMN082;

        case 'WIN'
            color{i} = colors.WIN;

        case 'NBQX' 
            color{i} = colors.gray;

        case 'NMDA'
            color{i} = colors.coral;

        case 'Washout' 
            color{i} = colors.turq;

        case 'Gabazine'
            color{i} = colors.Aga;

        otherwise
            color{i} = colors.black;
            warning('No color defined for "%s". Defaulting to black.', cond);
    end
end

end

% 
% Colors  % run your Colors script to populate the colors struct
% color = cell(1, numel(conditions));
% 
% % Map condition names to colors
% colorMap = struct( ...
%     'Control',              'gray', ...
%     'AgaTK',                'Aga', ...
%     'ConoGVIA',             'Cono', ...
%     'WIN',                  'Muscarine', ...
%     'Muscarine',            'Muscarine', ...
%     'AMN082',               'AMN082', ...
%     'CdCl2',                'CdCl2', ...
%     'ConoGVIA_AgaTK',       'Aga', ...
%     'AgaTK_Muscarine',      'Muscarine', ...
%     'Muscarine_ConoGVIA',   'Cono', ...
%     'ConoGVIA_Muscarine',   'Muscarine', ...
%     'ConoGVIA_AMN082',      'AMN082', ...
%     'AgaTK_AMN082',         'AMN082' ...
% 
% );
% 
% for i = 1:numel(conditions)
%     cond = conditions{i};
%     % Sanitize: replace characters invalid for struct fieldnames
%     condField = matlab.lang.makeValidName(cond);
% 
%     if isfield(colorMap, condField)
%         colorKey = colorMap.(condField);
%         color{i} = colors.(colorKey);
%     elseif contains(cond, 'CdCl2')
%         color{i} = colors.CdCl2;
%     elseif contains(cond, 'AMN082')
%         color{i} = colors.AMN082;
%     elseif contains(cond, 'Muscarine')
%         color{i} = colors.Muscarine;
%     else
%         color{i} = colors.black;
%         warning('assignColors: No color defined for condition "%s", defaulting to black.', cond);
%     end
% end
% 
% end