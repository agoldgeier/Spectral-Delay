%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DST Lab - Sprint 2015
% Aviv Goldgeier - arg450
% Square wave Generator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ squareWave ] = arg450_squareGen( dur, freq, otCnt, srate, file )
%squareGen - outputs a vector containing a square wave function with 
%      specified duration, fundamental frequency, and # of overtones
%
%

if nargin<4
    error('not enough input arguments');
elseif nargin==4
    printFile = false;
else
    printFile = true;
end

% The output is a vector containing a list of samples. The total # of
% samples is equal to sample rate multiplied by the duration in seconds.
%
% The vector will have two columns because audiowrite require two channels
% of audio.
squareWave = zeros([dur * srate, 2]);

% Convert frequency to wavelength to make future calculations easier.
w = 2 * pi * freq;

% The naive way of doing this is to iterate through all of the samples
% once for each overtone. This doesn't work very well for sampling rates
% in the range of actual audio.
for s = 1:length(squareWave)
    % Only odd harmonics contribute to the square wave, so we convert
    % the current overtone to the next odd number.
    for i = 1:otCnt
        k = 2 * i - 1;
        % This is where the magic happens.
        %
        % Here we add the value of the harmonic at this sample to the
        % current value of the sample.
        %
        % The current time is equal to the current sample / the sampling
        % rate.
        squareWave(s,1) = squareWave(s,1) + sin(k * w * s/srate) / k;
    end  
    squareWave(s,2) = squareWave(s,1);
end

if printFile
    audiowrite(file, squareWave, srate);
end

end

