
function [ output ] = spectralDelay( fileName, numBands, baseEcho, echoSkew, decay)
% SPECTRALDELAY  apply spectral delay to an audio signal. Splits audio into
%   a number of frequency bands and applies a different delay to each.
%
%   Used like this:
%      output = spectralDelay( fileName, numBands, baseEcho, echoSkew, decay)
%
% fileName - location of original file
% numBands - the number of different spectrum bands (1 to 100)
% baseEcho - the average echo among all bands (50 to 1000 ms)
% echoSkew - the way in which the echo varies among bands (-1.0 to 1.0)
% decay - the rate at which each delay effect decays (0.0 to 1.0)
%
% Input is slightly lenient - if inputs are possible but unrecommended,
% they will snap to recommended range.
%
% (c) 2015 Aviv Goldgeier - written as a final project for Fundamentals of
% Digital Signal Theory at NYU

% Input validation for quantity and type
if nargin ~= 5
    error('Must provide 5 args of form (string, int, int, float, float)');
end

if ~ischar(fileName)
    error('File name must be a string');
elseif ~isnumeric(numBands)
    error('Number of bands must be a number');
elseif mod(numBands,1) ~= 0
    error('Number of bands must be an integer');
elseif numBands < 1
    error('Number of bands must be between 1 and 100 inclusive');
elseif ~isnumeric(baseEcho)
    error('Base echo length must be a number');
elseif baseEcho < 0
    error('Base echo must be between 50 and 1000 milliseconds');
elseif ~isnumeric(echoSkew)
    error('Base echo length must be a number');
elseif ~isnumeric(decay)
    error('Base echo length must be a number');
elseif decay >= 1
    error('Decay must be less than one if you want to live');
elseif decay <= 0
    error('Decay must be between 0.0 and 1.0 exclusive');
end

% Limit range of inputs
numBands = min(numBands, 100);


% Read audio and convert to mono if necessary
[audio, fs] = audioread(fileName);

numChannels = size(audio,2);
if numChannels > 1
    audioMono = zeros(size(audio,1),1);
    for i = 1:numChannels
        audioMono = audioMono + audio(:,i)/numChannels;
    end
    audio = audioMono;
end

maxVal = max(max(audio), min(audio)*-1);


% MIGHT IT BE FASTER TO COMBINE STEPS TWO AND THREE (iterate through all
% bands only once). But not by much, if we have a reasonable number of
% bands.

% Step 1: create bands. Input: 1xM audio matrix. Output: NxM audio matrix
audioMatrix = splitBands(numBands, audio, fs);

% Step 2: generate delays. Input: N, baseEcho, echoSkew. Output: NxP dela
% matrix
delayMatrix = generateDelays(numBands, baseEcho, echoSkew, decay, fs);

% Step 3: Convolve audio matrices with delay matrices
audioMatrix = matrixConvolve(audioMatrix, delayMatrix);

% Step 4: Sum NxM audio matrix back into a 1xM audio matrix and export
output = sumBands(audioMatrix, maxVal);

%sound(output,fs);

end

function [ audioMatrix ] = splitBands(numBands, audio, fs)

% validate inputs

% I want the bands to be split equally on a log scale - generating an array
% of successive corner freuqnecies.
%   Let's do some math to figure out how to do this.
%       if x is our nyquist and n is our numbands
%       log(x) is split into n segments
%       the log of each corner frequency is then log(x)/n Hz apart
%       which should give something like this:
%       f_i = e^(i * log(x)/n)
%   Lastly, we must divide by fs/2 to get the frequencies as a ratio
fcArray = zeros(1, numBands-1);
for i = 1:numBands-1
    fcArray(i) = exp(i * log(fs/2)/numBands) / (fs/2);
end

% Change order of filter here; no reason to make this available to user
order = 2;
% Given corner frequencies, generate array of filters
filterArray = zeros(2, 2*order+1, numBands);
% Make a low pass for band 1, high pass for band n, band pass for
% everything in between.
% WARNING: ugly matrix indexing ahead!
[filterArray(1,1:3,1), filterArray(2,1:3,1)] = butter(order,fcArray(1),'low');
[filterArray(1,1:3,numBands), filterArray(2,1:3,numBands)] = butter(order,fcArray(numBands-1),'high');
for i = 2:numBands-1
    [filterArray(1,:,i), filterArray(2,:,i)] = butter(order,[fcArray(i-1), fcArray(i)]);
end

% Create output matrix and apply filters
audioMatrix = zeros(length(audio), numBands);
for i = 1:numBands
    audioMatrix(:,i) = filter(filterArray(1,:,i), filterArray(2,:,i), audio);
end

end

function [ delayMatrix ] = generateDelays(numBands, baseEcho, echoSkew, decay, fs)

% validate inputs

% First, let's create an array of delay lengths
%   Let's do some more math:
%       We want the median band to have a baseEcho amount of delay
%       When echoSkew is 1.0, the highest band should have 2*baseEcho
%           amount of delay and the lowest band should have 0.
%       When echoSkew is -1.0, it should be the other way around
%       The following definitions fit this model with linear interpolation.
minDelay = baseEcho * (1 - echoSkew);
maxDelay = baseEcho * (1 + echoSkew);
delays = linspace(minDelay, maxDelay, numBands+1);
%       We use numBands + 1 because we will throw out the first element of
%       this array - we never want to assign a delay of 0.

% In order to create an appropriately sized output matrix, we need to make
% each output band the length of the longest output band. This is found by:
%       max(delays) * numEchoes
%   where the number of echoes is found by:
%       -60dB = decay^(numEchoes), or:
%       numEchoes = log_decay(-60dB), or if you speak computer:
%       numEchoes = log2(0.001)/log2(decay).
%   We can then fudge the numbers for slightly quicker computation by
%   substituting 1/1024 for 0.001:
numEchoes = min(100, ceil(-10/log2(decay)));
if (echoSkew > 0)
    % numEchoes+1 because the original instance doesn't count
    delayMatrix = zeros(ceil(numEchoes+1 * maxDelay * fs/1000) + 1, numBands);
else
    delayMatrix = zeros(ceil(numEchoes+1 * minDelay * fs/1000) + 1, numBands);
end
% The plus one is because Matlab is dumb

% Now we fill the matrix
for i = 1:numBands
    curAmp = 1;
    for j = 0:numEchoes
        delayMatrix(floor((j*delays(i+1)*fs/1000) + 1), i) = curAmp;
        curAmp = curAmp * decay;
    end
end

end

function [ output ] = matrixConvolve(audioMatrix, delayMatrix)

% set conv lengths and recover numBands
audioLen = size(audioMatrix,1);
delayLen = size(delayMatrix,1);
numBands = size(delayMatrix,2);

outLen = audioLen + delayLen - 1;
output = zeros(outLen,numBands);

% for every band...
for i = 1:numBands
    audioBand = audioMatrix(:,i);
    delayBand = delayMatrix(:,i);
    % ...convolve
    IRFFT = fft(delayBand(:),outLen);
    inputFFT = fft(audioBand(:),outLen);
    
    output(:,i) = ifft((inputFFT) .* (IRFFT));
end

end

function [ output ] = sumBands(audioMatrix, maxVal)

% Recover numBands and set output matrix
numBands = size(audioMatrix, 2);
output = zeros(size(audioMatrix, 1), 1);

% add every band to output
for i = 1:numBands
    output = output + audioMatrix(:, i);
end

% normalize amplitude to original maximum
newMax = max(max(output), min(output)*-1);
ratio = newMax/maxVal;
output = output./ratio;

end
