function fit = MINIS_fitBaseline(currentData, S)
% Estimate baseline holding current using a Glykys/Mody-style histogram fit.
%
% Steps:
%   1) make an all-points histogram
%   2) smooth histogram counts with Savitzky-Golay smoothing
%   3) find histogram mode
%   4) fit a Gaussian from 3 pA left of the mode through the positive side
%   5) use Gaussian center (mu) as baseline holding current
%
% The fitted Gaussian is symmetric. Excess histogram mass on the negative
% side is stored as a phasic/synaptic excess metric, but it is NOT an
% individual event detector.

xdata = currentData(:);
xdata = xdata(isfinite(xdata));

if numel(xdata) < 100
    error('MINIS_fitBaseline requires more data points.');
end

bw = S.fitBinWidth_pA;
lo = floor(min(xdata) / bw) * bw;
hi = ceil(max(xdata) / bw) * bw;

if hi <= lo
    hi = lo + 10*bw;
end

edges = lo:bw:(hi + bw);
[counts, edges] = histcounts(xdata, edges);
centers = edges(1:end-1) + diff(edges)/2;
counts = double(counts(:)');
centers = centers(:)';

% Savitzky-Golay smoothing of the histogram, with a toolbox-independent fallback.
frame = min(S.sgFrame, numel(counts));
if mod(frame,2) == 0
    frame = frame - 1;
end
frame = max(frame, S.sgOrder + 3);
if mod(frame,2) == 0
    frame = frame + 1;
end
frame = min(frame, numel(counts) - mod(numel(counts)+1,2));

if frame >= S.sgOrder + 2 && exist('sgolayfilt', 'file') == 2
    smoothCounts = sgolayfilt(counts, S.sgOrder, frame);
else
    smoothCounts = movmean(counts, max(3, min(11, numel(counts))));
end
smoothCounts = max(smoothCounts, 0);

[~, peakIdx] = max(smoothCounts);
peakCurrent = centers(peakIdx);
fitStartCurrent = peakCurrent - S.fitLeftOffset_pA;
fitMask = centers >= fitStartCurrent & centers <= max(xdata);

xFit = centers(fitMask);
yFit = smoothCounts(fitMask);

if numel(xFit) < 5 || max(yFit) <= 0
    error('Not enough histogram points for Gaussian baseline fit.');
end

A0 = max(yFit);
rightData = xdata(xdata >= peakCurrent);
sigma0 = std(rightData);
if ~isfinite(sigma0) || sigma0 < bw
    sigma0 = max(std(xdata), bw);
end
sigma0 = min(max(sigma0, bw), 50);

% Parameterization keeps amplitude/sigma positive and mu near the mode.
q0 = [log(A0), 0, log(sigma0)];
opts = optimset('Display','off', 'MaxFunEvals',5000, 'MaxIter',2000);
q = fminsearch(@(q) gaussianSSE(q, xFit, yFit, peakCurrent, S), q0, opts);

[A, mu, sigma] = unpackGaussian(q, peakCurrent, S);
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
synapticExcessCounts = zeros(size(smoothCounts));
synapticExcessCounts(negativeSide) = max( ...
    smoothCounts(negativeSide) - yAllPred(negativeSide), 0);

if sum(smoothCounts) > 0
    synapticExcessFraction = sum(synapticExcessCounts) / sum(smoothCounts);
else
    synapticExcessFraction = NaN;
end

fit.mu = mu;
fit.sigma = sigma;
fit.amplitude = A;
fit.R2 = R2;
fit.peakCurrent = peakCurrent;
fit.fitStartCurrent = fitStartCurrent;
fit.binWidth = bw;
fit.centers = centers;
fit.counts = counts;
fit.smoothCounts = smoothCounts;
fit.gaussianCounts = yAllPred;
fit.synapticExcessCounts = synapticExcessCounts;
fit.synapticExcessFraction = synapticExcessFraction;
fit.nPoints = numel(xdata);
end

function err = gaussianSSE(q, x, y, peakCurrent, S)
[A, mu, sigma] = unpackGaussian(q, peakCurrent, S);
yp = A .* exp(-0.5 .* ((x - mu)./sigma).^2);
err = sum((y - yp).^2);

% Prevent pathological very broad fits.
if sigma > 100 || sigma < 0.05
    err = err + 1e9;
end
end

function [A, mu, sigma] = unpackGaussian(q, peakCurrent, S)
A = exp(q(1));
mu = peakCurrent + S.maxMuShiftFromPeak_pA * tanh(q(2));
sigma = exp(q(3));
end
