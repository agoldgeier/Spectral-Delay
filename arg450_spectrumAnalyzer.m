%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DST Lab - Spring 2015
% Aviv Goldgeier - arg450
% Spectrum Analyzer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ output ] = arg450_spectrumAnalyzer( fileName, winLength, overlapLength, window, fftLength )
%arg450_spectrumAnalyzer - outputs a spectrogram for a given waveform. User
% specifies the details of the FFT used
%

% Input validation! First check the number of arguments.
if nargin<4
    error('not enough input arguments');
elseif nargin==4
    fftLength = winLength;
elseif nargin>5
    error('the number of input arguments is too damn high!');
end

% Then check the types and validity of arguments
windowOptions = {'rect','hamming','hann','blackman','tukey'};

if ~ischar(fileName)
    error('file name must be a string');
elseif ~isnumeric(winLength)
    error('window length must be a number');
elseif ~isnumeric(overlapLength)
    error('overlap length must be a number');
elseif overlapLength>=winLength
    error('overlap length must be less than window length');
elseif ~ismember(window, windowOptions)
    error('window shape is invalid');
elseif ~isnumeric(fftLength)
    error('FFT length must be a number');
elseif fftLength<winLength
    error('FFT length cannot be less than window length');
end

[audio, fs] = audioread(fileName);

%for testing: truncate audio
%audio = audio(1:44100);

%make audio mono
s = size(audio);
if s(2)>1
   audio = audio(:,1);
end

%normalize window length and fftlength
winLength = makeBase2(winLength);
fftLength = makeBase2(fftLength);

%set window shape
% note: this is kinda shady programming - fully aware that I'm changing
% the type of window
if strcmp(window,'rect')
    window = 1;
elseif strcmp(window,'hann')
    window = hann(winLength);
elseif strcmp(window,'hamming')
    window = hamming(winLength);
elseif strcmp(window,'blackman')
    window = blackman(winLength);
elseif strcmp(window,'tukey')
    window = tukeywin(winLength);
end    

%slide window through audio
curStart = 1;
hop = winLength-overlapLength;
%make a matrix of the correct size
columns = ceil(length(audio)/hop);
rows = fftLength/2 + 1;
output = zeros(rows,columns);
idx = 1;
while (curStart+winLength)<length(audio)
    %extract a window's length of audio
    curWin = audio(curStart:curStart+winLength-1);
    %apply window function
    curWin = curWin.*window;
    %take fft of window and scale to dB
    f = 20*log10(abs(fft(curWin,fftLength)));
    %remove duplicate symmetry
    f = f(1:rows);
    %normalize magnitudes
    f = f./sum(window);
    %store in output matrix
    output(:,idx) = f;
    %increment counters
    curStart = curStart + hop;
    idx = idx + 1;
end

output = flipud(output);

% for testing:
% imagesc(output);

end

function [ result ] = makeBase2( num )
    result = 1;
    while result<num
        result = result * 2;
    end
end

