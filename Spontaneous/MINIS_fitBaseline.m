function fit = MINIS_fitBaseline(trial,S)
% Estimate holding current and inward synaptic current from an all-points histogram.
%
% The Gaussian is fit beginning at the histogram peak and extending
% through the positive/right tail. The fitted Gaussian is then evaluated
% symmetrically over the complete histogram.
%
% The histogram current axis is baseline-subtracted using the fitted
% Gaussian mean (mu). Excess observed counts above the Gaussian prediction
% on the negative/inward side are amplitude-weighted to calculate
% synaptic charge and mean synaptic current.
%
% Final synaptic charge/current are reported as positive magnitudes.
% Signed inward values are also retained.

trial = trial(:);
trial = trial(isfinite(trial));

if isempty(trial)
    error('MINIS_fitBaseline received no finite samples.');
end

binWidth = S.fitBinWidth_pA;

%% HISTOGRAM

lo = floor(min(trial)/binWidth)*binWidth;
hi = ceil(max(trial)/binWidth)*binWidth;
edges = lo:binWidth:(hi+binWidth);

if numel(edges) < 2
    edges = [lo lo+binWidth];
end

[pointFreq,edges] = histcounts(trial,edges);
centers = edges(1:end-1) + diff(edges)/2;

%% FIND HISTOGRAM PEAK

[~,peakIdx] = max(pointFreq);
peakCurrent = centers(peakIdx);

%% FIT RIGHT SIDE OF HISTOGRAM

fitMask = centers >= peakCurrent & centers <= max(trial);

xFit = centers(fitMask);
yFit = pointFreq(fitMask);

if isempty(xFit) || isempty(yFit)
    error('Gaussian fit region is empty. Check histogram settings.');
end

A0 = max(max(yFit),eps);

rightData = trial(trial >= peakCurrent);
sigma0 = std(rightData);

if ~isfinite(sigma0) || sigma0 < binWidth
    sigma0 = max(std(trial),binWidth);
end

sigma0 = min(max(sigma0,binWidth),50);

q0 = [log(A0),log(sigma0)];

AfromQ = @(q) exp(q(1));
sigmafromQ = @(q) exp(q(2));

mu = peakCurrent;

gaussianFromQ = @(q,x) AfromQ(q).*exp( ...
    -0.5.*((x-mu)./sigmafromQ(q)).^2);

gaussianSSE = @(q) sum((yFit-gaussianFromQ(q,xFit)).^2) + ...
    1e9*(sigmafromQ(q) > 100 || sigmafromQ(q) < 0.05);

opts = optimset('Display','off','MaxFunEvals',5000,'MaxIter',2000);
q = fminsearch(gaussianSSE,q0,opts);

A = AfromQ(q);
sigma = sigmafromQ(q);

%% EVALUATE GAUSSIAN

yFitPred = A.*exp(-0.5.*((xFit-mu)./sigma).^2);
yAllPred = A.*exp(-0.5.*((centers-mu)./sigma).^2);

SSE = sum((yFit-yFitPred).^2);
SST = sum((yFit-mean(yFit)).^2);

if SST > 0
    R2 = 1-SSE/SST;
else
    R2 = NaN;
end

%% BASELINE-SUBTRACT HISTOGRAM

% Shift histogram x-axis so fitted mu becomes 0 pA.
centeredCenters = centers-mu;

% Inward current is negative after baseline subtraction.
negativeSide = centeredCenters < 0;

%% SYNAPTIC EXCESS

% Difference between observed counts and Gaussian prediction.
% If Gaussian > histogram, contribution is forced to zero.
synapticExcessCounts = zeros(size(pointFreq));

synapticExcessCounts(negativeSide) = max( ...
    pointFreq(negativeSide)-yAllPred(negativeSide),0);

synapticExcessCount = sum(synapticExcessCounts);

% Weight each excess frequency value by its baseline-subtracted current.
% Units: pA*samples.
synapticExcess_pASamplesSigned = sum( ...
    synapticExcessCounts .* centeredCenters);

% Convert integrated current to charge.
% pA*s = pC.
dt = 1/S.Fs;
synapticChargeSigned_pC = synapticExcess_pASamplesSigned*dt;

% Mean synaptic current contribution over analyzed duration.
trialDuration_s = numel(trial)/S.Fs;
synapticCurrentSigned_pA = synapticChargeSigned_pC/trialDuration_s;

% Chiayu reports absolute pA values.
synapticCharge_pC = abs(synapticChargeSigned_pC);
synapticCurrent_pA = abs(synapticCurrentSigned_pA);

%% STORE OUTPUTS

fit.mu = mu;
fit.sigma = sigma;
fit.amplitude = A;
fit.R2 = R2;
fit.peakCurrent = peakCurrent;
fit.binWidth = binWidth;

fit.centers = centers;
fit.centeredCenters = centeredCenters;
fit.pointFreq = pointFreq;
fit.counts = pointFreq;

fit.fitMask = fitMask;
fit.xFit = xFit;
fit.yFit = yFit;
fit.yFitPred = yFitPred;
fit.gaussianCounts = yAllPred;

fit.synapticExcessCounts = synapticExcessCounts;
fit.synapticExcessCount = synapticExcessCount;

fit.synapticExcess_pASamplesSigned = synapticExcess_pASamplesSigned;
fit.synapticChargeSigned_pC = synapticChargeSigned_pC;
fit.synapticCurrentSigned_pA = synapticCurrentSigned_pA;

fit.synapticCharge_pC = synapticCharge_pC;
fit.synapticCurrent_pA = synapticCurrent_pA;

fit.trialDuration_s = trialDuration_s;
fit.nPoints = numel(trial);

end