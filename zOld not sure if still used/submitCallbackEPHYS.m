function submitCallbackEPHYS(f, Data, avginghandles, pharms)

for p = 1:length(pharms)
    pharm = pharms{p};

firstTrialIdx = str2double(get(avginghandles.(pharm).start, 'String'));
lastTrialIdx = str2double(get(avginghandles.(pharm).end, 'String'));

    Data.(pharm).firstTrialAvgIdx = firstTrialIdx;
    Data.(pharm).lastTrialAvgIdx = lastTrialIdx;
end

assignin('base','Data', Data)
 uiresume(f);  % Resume execution after uiwait
    end
