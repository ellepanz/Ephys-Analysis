function waves = loadMultiIgorWaves(filename)
% automatically load .itx with multiple waves exported from Igor into a
% single .itx file
%
% Input:
%   filename - path to the .itx file
%
% Output:
%   waves - struct with 1 field per wave named as in Igor

% Open file
fid = fopen(filename,'r');
if fid == -1
    error('Cannot open file: %s', filename);
end

% Read all lines
C = textscan(fid,'%s','Delimiter','\n');
fclose(fid);
lines = C{1};

% Find the WAVES header (first line starting with 'WAVES')
waveLineIdx = find(startsWith(strtrim(lines),'WAVES'),1,'first');
waveLine = strtrim(lines{waveLineIdx});

% Extract wave names
parts = strsplit(waveLine);
waveNames = parts(2:end);  % skip 'WAVES/D' or 'WAVES'

numWaves = length(waveNames);

% Find numeric block
beginIdx = find(contains(lines,'BEGIN'),1,'first');
endIdx   = find(contains(lines,'END'),1,'first');
rawLines = lines(beginIdx+1:endIdx-1);

% Replace Igor arrow → with spaces
rawLines = strrep(rawLines,'→',' ');

% Convert each line into numbers and store in matrix
numRows = length(rawLines);
dataMat = zeros(numRows,numWaves);

for r = 1:numRows
    nums = str2num(rawLines{r}); %#ok<ST2NM>
    if length(nums) ~= numWaves
        error('Line %d does not have %d numbers', r, numWaves);
    end
    dataMat(r,:) = nums;
end

% Assign each column to struct fields
waves = struct();
for k = 1:numWaves
    waves.(waveNames{k}) = dataMat(:,k); % column vector
        waves.(waveNames{k}) = waves.(waveNames{k})*10e12
end


end
