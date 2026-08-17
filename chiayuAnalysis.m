
filename = '\\bunson\bunson\Higley_Lab\Chiayu\Analyses\IN to GIN\pv1 all.itx';

waves = loadMultiIgorWaves(filename);

h = GUI_chiayuAnalysis;
stimLoc = h.stimLoc;

taus = [];

for i = 1:numel(fieldnames(waves))

    % Pull ephys trace
    traceName = sprintf('pv%d', i);
    trace = waves.(traceName);

    % Find peakVal and peakIdx
    baseline = mean(trace((stimLoc-20 : stimLoc),:)); % sets baseline before stim as 20 points
    peakRange = trace(stimLoc:stimLoc+100);

    [peakVal, peakIdx] = max(trace(stimLoc:stimLoc+100));
    peakIdx = stimLoc + peakIdx - 1;

    % Calculate tau boundaries (10%, 90%)
   % ----got rid of amplitude calculation because some basleines are negative and it's already baseline subtraced ---
    percent10Val = baseline + (peakVal*0.1);
    percent90Val = baseline + (peakVal*0.9);


    % Find idx values of boundaries
    [~, percent10idx] = min(abs(trace(stimLoc:peakIdx) - percent10Val));
    percent10idx = percent10idx + stimLoc;
    [~, percent90idx] = min(abs(trace(stimLoc:peakIdx) - percent90Val));
    percent90idx = percent90idx + stimLoc;

    tau = percent90idx - percent10idx;

    Data.(traceName).trace = trace;
    Data.(traceName).baseline = baseline;
    Data.(traceName).peakRange = peakRange;
    -
    Data.(traceName).peakVal = peakVal;
    Data.(traceName).peakIdx = peakIdx;
    %Data.(traceName).amplitude = amplitude;
    Data.(traceName).percent10Val = percent10Val;
    Data.(traceName).percent90Val = percent90Val;
    Data.(traceName).percent10idx = percent10idx;
    Data.(traceName).percent90idx = percent90idx;
    Data.(traceName).tau = tau;

end

%% Plot

figure('position',[1 49 1920 955]);
t = tiledlayout('flow');

for i = 1:numel(fieldnames(waves))

    nexttile
    hold on

    % === Pull data ===
    traceName = sprintf('pv%d', i);
    trace = waves.(traceName);

    percent10Val = Data.(traceName).percent10Val;
    percent90Val =  Data.(traceName).percent90Val ;
    percent10idx = Data.(traceName).percent10idx ;
    percent90idx = Data.(traceName).percent90idx;

    % === Plot trace ===
    plot(trace, 'k')

    % === Plot 10% and 90% points ===
    plot(percent10idx, percent10Val, 'o', 'MarkerSize', 8, 'LineWidth', 1.5)
    plot(percent90idx, percent90Val, 'o', 'MarkerSize', 8, 'LineWidth', 1.5)

    % === Draw horizontal line at 10% between indices ===
    plot([percent10idx percent90idx], ...
        [percent10Val percent10Val], ...
        'LineWidth', 1.5)
    
    % === Aesthetics ===
    sgtitle('Indviidual trials')
    title(['Trial ' num2str(i)])
    xlabel('Time (ms)')
    ylabel('pA')
    grid on
    
end


