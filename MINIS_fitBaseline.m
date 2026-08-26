function fit = MINIS_fitBaseline(trial, S)
% Estimate baseline holding current using a Glykys/Mody-style histogram fit.
%
% Steps:
%   1) make an all-points histogram
%   
%   3) find histogram mode
%   4) fit a Gaussian from 3 pA left of the mode through the positive side
%   5) use Gaussian center (mu) as baseline holding current
%
% The fitted Gaussian is symmetric. Excess histogram mass on the negative
% side is stored as a phasic/synaptic excess metric.


%% Create histogram
binWidth = S.fitBinWidth_pA; % bin width 
lo = floor(min(trial) / binWidth) * binWidth; % find lowest 
hi = ceil(max(trial ) / binWidth) * binWidth;

edges = lo:binWidth:(hi + binWidth);
[pointFreq, edges] = histcounts(trial, edges); % Sorts and counts all points
centers = edges(1:end-1) + diff(edges)/2; % finds center of bins for xaxis pts

[~, peakIdx] = max(pointFreq); % Find the bin containing the greatest number of points
peakCurrent = centers(peakIdx); % Current corresponding to the histogram peak
fitStartCurrent = peakCurrent - S.fitLeftOffset_pA; % num pA to fit the Gaussian so it has something at the top to fit to 
fitMask = centers >= fitStartCurrent & centers <= max(trial); % makes a mask of just the bins to the right of fitStartCurrent

xFit = centers(fitMask);
yFit = pointFreq(fitMask);

A0 = max(yFit);
rightData = trial(trial >= peakCurrent);
sigma0 = std(rightData);
if ~isfinite(sigma0) || sigma0 < binWidth
    sigma0 = max(std(trial), binWidth);
end
sigma0 = min(max(sigma0, binWidth), 50);

%% Fit Gaussian

% q contains transformed versions of the Gaussian parameters:
% q(1) -> amplitude
% q(2) -> Gaussian center (mu)
% q(3) -> sigma

q0 = [log(A0), 0, log(sigma0)];

% Define how q translates into Gaussian parameters
AfromQ = @(q) exp(q(1));
mufromQ = @(q) peakCurrent + ...
    S.maxMuShiftFromPeak_pA * tanh(q(2));
sigmafromQ = @(q) exp(q(3));

% Gaussian predicted by a given set of q values
gaussianFromQ = @(q,x) ...
    AfromQ(q) .* exp(-0.5 .* ...
    ((x - mufromQ(q)) ./ sigmafromQ(q)).^2);

% difference between histogram points and Gaussian prediction
gaussianSSE = @(q) ...
    sum((yFit - gaussianFromQ(q,xFit)).^2) + ...
    1e9 * (sigmafromQ(q) > 100 || sigmafromQ(q) < 0.05);

% Find q values that minimize the squared error
opts = optimset('Display','off', ...
    'MaxFunEvals',5000, ...
    'MaxIter',2000);

q = fminsearch(gaussianSSE, q0, opts);

% Convert optimized q values back into Gaussian parameters
A = AfromQ(q);
mu = mufromQ(q);
sigma = sigmafromQ(q);

yFitPred = A .* exp(-0.5 .* ((xFit - mu)./sigma).^2);
yAllPred = A .* exp(-0.5 .* ((centers - mu)./sigma).^2);

SSE = sum((yFit - yFitPred).^2);
SST = sum((yFit - mean(yFit)).^2);
if SST > 0
    R2 = 1 - SSE/SST;
else
    R2 = NaN;
end

% The Gaussian is the symmetric noise model. Negative-side histogram mass
% above that model is the distributional excess produced by inward events.
negativeSide = centers < mu;
synapticExcessCounts = zeros(size(pointFreq));
synapticExcessCounts(negativeSide) = max( ...
    pointFreq(negativeSide) - yAllPred(negativeSide), 0);

if sum(pointFreq) > 0
    synapticExcessFraction = sum(synapticExcessCounts) / sum(pointFreq);
else
    synapticExcessFraction = NaN;
    end

fit.mu = mu;
fit.sigma = sigma;
fit.amplitude = A;
fit.R2 = R2;
fit.peakCurrent = peakCurrent;
fit.fitStartCurrent = fitStartCurrent;
fit.binWidth = binWidth;

fit.centers = centers;
fit.counts = pointFreq;
fit.pointFreq = pointFreq;

fit.fitMask = fitMask;
fit.xFit = xFit;
fit.yFit = yFit;
fit.yFitPred = yFitPred;

fit.gaussianCounts = yAllPred;

fit.synapticExcessCounts = synapticExcessCounts;
fit.synapticExcessFraction = synapticExcessFraction;

fit.nPoints = numel(trial);






