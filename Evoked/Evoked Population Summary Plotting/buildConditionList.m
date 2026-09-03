function [condList, mainPharm] = buildConditionList(baselineCond, secondCond, thirdCond)

condList = {baselineCond};

if ~strcmp(secondCond, 'None')
    if strcmp(baselineCond, 'Control')
        condList{end+1} = secondCond;
    else
        condList{end+1} = sprintf('%s_%s', baselineCond, secondCond);
    end
end

if ~strcmp(thirdCond, 'None')
    if strcmp(baselineCond, 'Control')
        condList{end+1} = sprintf('%s_%s', secondCond, thirdCond);
    else
        condList{end+1} = sprintf('%s_%s_%s', baselineCond, secondCond, thirdCond);
    end
end

%%
% getMainPharm - Determine which primary dataset to load
%
% Example:
%   {'Control','AgaTK','AgaTK_AMN082'}      -> "AgaTK"
%   {'AgaTK','AgaTK_AMN082'}                -> "AgaTK"
%   {'Control','ConoGVIA','ConoGVIA_AMN082'} -> "ConoGVIA"

condList = string(condList);

if any(startsWith(condList, "AgaTK"))
    mainPharm = "AgaTK";

elseif any(startsWith(condList, "ConoGVIA"))
    mainPharm = "ConoGVIA";

elseif any(startsWith(condList, "Muscarine"))
    mainPharm = "Muscarine";

else
    error('Could not determine main pharmacology from condList.');
end

end
