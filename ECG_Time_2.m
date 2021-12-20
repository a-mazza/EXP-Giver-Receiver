function ECG_Time_Analysis = ECG_Time_2(data,SR)
%% Basic

% Delete nans
%data = data.ECG;
itsnan = find(isnan(data));
data(itsnan,:) = [];

% standardize
data = (data-mean(data)) / std(data);

% Filter
tx =(0:size(data,1)-1)'*1/SR;
Fs = 1/mean(diff(tx)); % Average sample rate

%data = bandstop(data, [49 51], Fs);
%data = highpass(data,10,Fs,'Steepness',0.8,'StopbandAttenuation',60);
%data = lowpass(data,25,Fs);

%% IMPORT SIGNAL & Define sampling rate SR


% You can use wavelets to build an automatic QRS detector for use in applications 
%   like R-R interval estimation.
% There are two keys for using wavelets as general feature detectors:
%     1 - The wavelet transform separates signal components into different 
%          frequency bands enabling a sparser representation of the signal.
%     2 - You can often find a wavelet which resembles the feature you are trying to detect.
% The 'sym4' wavelet resembles the QRS complex, which makes it a good choice for QRS detection. 


%% Create the wavelet resembling your ECG signal

% Use the maximal overlap discrete wavelet transform (MODWT) to enhance 
% the R peaks in the ECG waveform. The MODWT is an undecimated wavelet transform, 
% which handles arbitrary sample sizes.

% Decompose the ECG waveform down to level 5 using the default 'sym4' wavelet.
wt = modwt(data,5);  

% Reconstruct a frequency-localized version of the ECG waveform using only 
% the wavelet coefficients at scales 4 and 5. 
% The scales correspond to the following approximate frequency bands.
%         Scale 4 -- [11.25, 22.5) Hz
%         Scale 5 -- [5.625, 11.25) Hz.

wtrec = zeros(size(wt));
wtrec(4:5,:) = wt(4:5,:);
y = imodwt(wtrec,'sym4');


%% Find peaks of the wavelet --> Solve for inversed polarities

% Use the squared absolute values of the signal approximation built from the 
% wavelet coefficients and employ a peak finding algorithm ( findepeaks() ) 
% to identify the R peaks.

y = abs(y).^2; % squared absolute value

tx =(0:size(data,1)-1)'*1/SR; % define time based on sampling rate SR

[peaks,peakLocs] = findpeaks(y,tx,'MinPeakHeight',8*mean(y),...
    'MinPeakDistance',0.35);


figure
plot(tx,data,'k','linewidth',2)
hold on
plot(tx,y,'r','linewidth',1.5)
plot(tx,abs(data).^2,'b--')
plot(peakLocs,peaks,'go','MarkerFaceColor','r')
legend('Raw Data','Wavelet Reconstruction','Raw Data Squared', ...
    'Location','SouthEast');
xlabel('Seconds')




%% Measures

% Beats per minute
ECG_Time_Analysis.BPM = length(peakLocs)*SR*60/length(y); 

% Interval between peaks (R to R) [non normalized]
RR = diff(peakLocs); 
    % Rejecty noise from RR
    RRmean = mean(RR);
    rejectMax = RRmean + 3*std(RR);
    rejectMin = RRmean - 3*std(RR);
    ArrReject = find((RR > rejectMax) | (RR < rejectMin));
    RR(ArrReject) = [];
ECG_Time_Analysis.RR = RR;
ECG_Time_Analysis.RRsterr = sterr(RR);

% Calculate SDNN
ECG_Time_Analysis.SDNN = std(RR)*10; % Per mille è ok secondo fz ECG, ma check unità di misura

% Calculate RMSSD
differences = (RR-RRmean).^2;
ECG_Time_Analysis.RMSSD = sqrt(mean(differences.^2))*10;

% Calculate IBI (Inter-Beat Interval)
ECG_Time_Analysis.IBI = RRmean;

% Calculate pNN50 - Percentage of successive RR intervals that differ by more than 50 ms
NN = diff(RR);
ispnn = NN > 0.05 | NN < -0.05;
ECG_Time_Analysis.pNN50 = 100*( sum(ispnn) / length(NN) );


% figure
% x = linspace(0,pLoc(end-1),size(RR,1));
% plot(x,RR)
% xlim([0 pLoc(end-1)])
% title('RR interval')
% xlabel('Time (Sec)')
% ylabel('Seconds')
% yline(RRmean,'--r')
end