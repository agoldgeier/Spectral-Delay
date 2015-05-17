function [] = spectralDelayTest()
% SPECTRALDELAYTEST offers a demonstration of of the spectral delay
% function created as my final project for Fundamentals of Digital Signal
% Theory, taken at NYU, Spring 2015.
%
% Here we write a few different files, showing the different kinds of
% effects possible with my spectral delay, and we will also plot their
% spectra to further show what is going on.
%
% I'm including a couple sound effects in the folder. If you do not see
% them:
%   HornHit.wav is from freesound.org user Meutecee 
%       https://www.freesound.org/people/Meutecee/sounds/69840/
%
% (c) 2015 Aviv Goldgeier

% First, let's run the function a few times with different parameters. This
% will take a minute to compute...
polyrhythm = spectralDelay('PoolIR.wav', 3, 300, 0.4, 0.7);
noiseSweep = spectralDelay('PoolIR.wav', 75, 300, 1, 0.5);
krazyVerb  = spectralDelay('HornHit.wav', 15, 150, 1, 0.7);
bubbles    = spectralDelay('PoolIR.wav', 50, 300, 1, 0.9);

% ...and export into some files
audiowrite('polyrhythm.wav',polyrhythm,44100);
audiowrite('noiseSweep.wav',noiseSweep,44100);
audiowrite('krazyVerb.wav',krazyVerb,44100);
audiowrite('bubbles.wav',bubbles,44100);

% You can now play these files at your own discretion.

% Here are some plots.

subplot(221);
imagesc(arg450_spectrumAnalyzer('polyrhythm.wav', 1024, 256, 'hamming'));
title('polyrhythm');

subplot(222);
imagesc(arg450_spectrumAnalyzer('noiseSweep.wav', 1024, 256, 'hamming'));
title('noise sweep');

subplot(223);
imagesc(arg450_spectrumAnalyzer('krazyVerb.wav', 1024, 256, 'hamming'));
title('krazy verb');

subplot(224);
imagesc(arg450_spectrumAnalyzer('bubbles.wav', 1024, 256, 'hamming'));
title('bubbles');

end