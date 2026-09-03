%% build by chatgpt 6/7/25 to try and get the averages out of igor files 


function waveData = readITXwaves(filename)
    fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open file: %s', filename);
    end

    waveData = struct();
    currentWave = '';
    readingData = false;
    dataBuffer = [];

    while ~feof(fid)
        line = strtrim(fgetl(fid));

        % Start of a new wave
        if startsWith(line, 'WAVES', 'IgnoreCase', true)
            tokens = regexp(line, 'WAVES.*?(\w+)', 'tokens');
            if ~isempty(tokens)
                currentWave = tokens{1}{1};
            end
            dataBuffer = [];
        
        % Begin reading data
        elseif strcmpi(line, 'BEGIN')
            readingData = true;
            dataBuffer = [];

        % End reading data
        elseif strcmpi(line, 'END')
            if ~isempty(currentWave)
                waveData.(currentWave) = dataBuffer(:);
            end
            readingData = false;

        % Reading numerical data
        elseif readingData
            nums = sscanf(line, '%f');
            dataBuffer = [dataBuffer; nums];
        end
    end

    fclose(fid);
end
