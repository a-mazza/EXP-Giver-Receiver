function ECG_Analysis = ECG_Analyze(data,SR)
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


% data = highpass(data,10,Fs,'Steepness',0.8,'StopbandAttenuation',60);
% data = lowpass(data,50,Fs,'Steepness',0.8,'StopbandAttenuation',60);

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
    'MinPeakDistance',0.30);


% figure
% plot(tx,data,'k','linewidth',2)
% hold on
% plot(tx,y,'r','linewidth',1.5)
% plot(tx,abs(data).^2,'b--')
% plot(peakLocs,peaks,'go','MarkerFaceColor','r')
% legend('Raw Data','Wavelet Reconstruction','Raw Data Squared', ...
%     'Location','SouthEast');
% xlabel('Seconds')






%% Measures

%% ____________________________ Time ______________________________________
% Beats per minute
ECG_Analysis.BPM = length(peakLocs)*SR*60/length(y); 

% Interval between peaks (R to R) [non normalized]
RR = diff(peakLocs); 
    % Rejecty noise from RR
    RRmean = mean(RR);
    rejectMax = RRmean + 3*std(RR);
    rejectMin = RRmean - 3*std(RR);
    ArrReject = find((RR > rejectMax) | (RR < rejectMin));
    RR(ArrReject) = [];
ECG_Analysis.RR = RR;
ECG_Analysis.RRsterr = sterr(RR);

% Calculate SDNN
ECG_Analysis.SDNN = std(RR)*10; % Per mille è ok secondo fz ECG, ma check unità di misura

% Calculate RMSSD
differences = (RR-RRmean).^2;
ECG_Analysis.RMSSD = sqrt(mean(differences.^2))*10;

% Calculate IBI (Inter-Beat Interval)
ECG_Analysis.IBI = RRmean;

% Calculate pNN50 - Percentage of successive RR intervals that differ by more than 50 ms
NN = diff(RR);
ispnn = NN > 0.05 | NN < -0.05;
ECG_Analysis.pNN50 = 100*( sum(ispnn) / length(NN) );




% _____________ Frequency (Wavelet transf)_________________________________

% Define RR sampling rate 
% (i.e. how many RR samples per second on average). Needed for cwt
RRsr = length(RR)/(length(data)/SR);

if length(RR) < 4 % wavelet transorfm requires a vector with legnth >= 4.
                  % if signal is corrupted, length(RR) might be <4.
                  % thus, create a fictious RR in order not to give errors
                  % when this function is looped trough other good data
    RR = [5 10 15 20]; 
end

% apply cwt to RR
[wt, f] = cwt(RR,'amor',RRsr);
wt = abs(wt); % keep only real values from complex matrix

% define high and low frequency
LF = [0.04 0.15]; 
HF = [0.15 0.4]; 

iLF = f >= LF(1) & f <= LF(2);
iHF = f > HF(1) & f <= HF(2);

% calculate absolute power
pLF = mean(mean(wt(iLF,:)));
pHF = mean(mean(wt(iHF,:)));

ECG_Analysis.pLF = pLF;
ECG_Analysis.pHF = pHF;

%calculate relative power
ECG_Analysis.rpLF = pLF/(pLF + pHF)*100;
ECG_Analysis.rpHF = pHF/(pLF + pHF)*100;

% calculate LF/HF ratio
ECG_Analysis.LF_HF_ratio = pLF/pHF;



%% plots
% plot time-frequency scalogram
dataLengthS = length(data)/SR;
txRR = linspace(0,dataLengthS,length(RR));

bound = find(f <= LF(2));
bound1 = bound(1);
bound2 = bound(1);
bound3 = find(f <= HF(2));
bound3 = bound3(1);

figure
pcolor(txRR,f,wt)
shading interp
xlabel('Time (s)')
ylabel('Frequency (Hz)')
hcb = colorbar;
colorTitleHandle = get(hcb,'YLabel');
titleString = 'PSD (s^2/Hz)';
set(colorTitleHandle ,'String',titleString);
yline(f(bound1))
yline(f(bound2))
yline(f(bound3))
title('Time-Frequency CWT scalogram')

% plot frequency distribution
wt_collapsed = mean(wt,2);
wt_collapsed = flipud(wt_collapsed);
fx = flipud(f);
bound = find(fx <= LF(2));
bound1 = bound(1);
bound2 = bound(end);
bound3 = find(fx <= HF(2));
bound3 = bound3(end);

plotLF = wt(iLF,:);
plotLF = mean(plotLF);

plotHF = wt(iHF,:);
plotHF = mean(plotHF);

figure
tiledlayout(2,1)

nexttile
area(fx(1:bound2),wt_collapsed(1:bound2));
hold on
area(fx(bound2:end),wt_collapsed(bound2:end));
xline(fx(bound1));
xline(fx(bound2));
xline(fx(bound3));
legend({'Low Frequencies' 'High Frequencies'})
xlabel('Frequency (Hz)')
ylabel('PSD (s^2/Hz)')
title('Frequency PSD')

nexttile
plot(txRR, plotLF,'color',[0 0.4470 0.7410],'linewidth',2)
xlabel('Time (s)')
ylabel('PSD (s^2/Hz)')
hold on
plot(txRR, plotHF,'color',[0.8500 0.3250 0.0980],'linewidth',2)
xlabel('Time (s)')
ylabel('PSD (s^2/Hz)')
title('Frequencies time course')

% plot RR timecourse
figure
plot(txRR, RR, 'k')
xlabel('Time (s)')
ylabel('RR interval (s)')
title('RR time course')

end