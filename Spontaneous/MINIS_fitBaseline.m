function fit = MINIS_fitBaseline(trial,S)
% Estimate holding current and inward synaptic excess from an all-points histogram.
%
% The Gaussian is fit only to bins beginning S.fitRightOffset_pA to the
% right of the histogram peak and extending through the positive tail.
% The fitted Gaussian is then extrapolated symmetrically over the complete
% histogram. Excess observed counts on the negative side of the Gaussian
% mean are treated as inward synaptic excess.

trial = trial(:);
trial = trial(isfinite(trial));

if isempty(trial)
    error('MINIS_fitBaseline received no finite samples.');
end

if ~isfield(S,'fitRightOffset_pA')
    error('S.fitRightOffset_pA is missing. Run the current MINIS_defaultSettings.');
end

binWidth = S.fitBinWidth_pA;

lo = floor(min(trial)/binWidth)*binWidth;
hi = ceil(max(trial)/binWidth)*binWidth;
edges = lo:binWidth:(hi+binWidth);

if numel(edges) < 2
    edges = [lo lo+binWidth];
end

[pointFreq,edges] = histcounts(trial,edges);
centers = edges(1:end-1) + diff(edges)/2;

[~,peakIdx] = max(pointFreq);
peakCurrent = centers(peakIdx);

fitStartCurrent = peakCurrent + S.fitRightOffset_pA;
fitMask = centers >= fitStartCurrent & centers <= max(trial);

xFit = centers(fitMask);
yFit = pointFreq(fitMask);

if isempty(xFit) || isempty(yFit)
    error('Gaussian fit region is empty. Check fit-bin and fit-offset settings.');
end

A0 = max(yFit);
A0 = max(A0,eps);

rightData = trial(trial >= peakCurrent);
sigma0 = std(rightData);

if ~isfinite(sigma0) || sigma0 < binWidth
    sigma0 = max(std(trial),binWidth);
end

sigma0 = min(max(sigma0,binWidth),50);

q0 = [log(A0),0,log(sigma0)];

AfromQ = @(q) exp(q(1));
mufromQ = @(q) peakCurrent + S.maxMuShiftFromPeak_pA*tanh(q(2));
sigmafromQ = @(q) exp(q(3));

gaussianFromQ = @(q,x) AfromQ(q).*exp(-0.5.*((x-mufromQ(q))./sigmafromQ(q)).^2);

gaussianSSE = @(q) sum((yFit-gaussianFromQ(q,xFit)).^2) + ...
    1e9*(sigmafromQ(q) > 100 || sigmafromQ(q) < 0.05);

opts = optimset('Display','off','MaxFunEvals',5000,'MaxIter',2000);
q = fminsearch(gaussianSSE,q0,opts);

A = AfromQ(q);
mu = mufromQ(q);
sigma = sigmafromQ(q);

yFitPred = A.*exp(-0.5.*((xFit-mu)./sigma).^2);
yAllPred = A.*exp(-0.5.*((centers-mu)./sigma).^2);

SSE = sum((yFit-yFitPred).^2);
SST = sum((yFit-mean(yFit)).^2);

if SST > 0
    R2 = 1-SSE/SST;
else
    R2 = NaN;
end

negativeSide = centers < mu;
synapticExcessCounts = zeros(size(pointFreq));
synapticExcessCounts(negativeSide) = max(pointFreq(negativeSide)-yAllPred(negativeSide),0);

synapticExcessCount = sum(synapticExcessCounts);

if sum(pointFreq) > 0
    synapticExcessFraction = synapticExcessCount/sum(pointFreq);
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
fit.synapticExcessCount = synapticExcessCount;
fit.synapticExcessFraction = synapticExcessFraction;

fit.nPoints = numel(trial);

end
