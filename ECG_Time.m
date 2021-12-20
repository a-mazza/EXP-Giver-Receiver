function ECG_Time_Analysis = ECG_Time(data,SR)
%% Preprocess
% Delete nans
% data = data.ECG;
itsnan = find(isnan(data));
data(itsnan,:) = [];

% Delete first and last 2 secs, Detrend & Delete offset
data = data(2*SR:end-2*SR);
data = detrend(data,'linear');
data = data-mean(data);

% Filter
tx =(0:size(data,1)-1)'*1/SR;
Fs = 1/mean(diff(tx)); % Average sample rate
fdata = lowpass(data,30,Fs,'Steepness',0.8,'StopbandAttenuation',60);
fdata = highpass(fdata,0.3,Fs,'Steepness',0.8,'StopbandAttenuation',60);


%% Find peaks
[pks, pLoc] = findpeaks(fdata, tx,'MinPeakProminence', 1,...
 'MinPeakDistance', 0.2,'MinPeakHeight',0.1);

%figure

plot(tx,data);
hold on
plot(tx, fdata)
hold on
plot(pLoc,pks,'ro')
hold off
title('ECG data')
legend({'Unfiltered' 'Filtered'})

%% Measures

% Beats per minute
ECG_Time_Analysis.BPM = length(pLoc)*SR*60/length(fdata); 

% Interval between peaks (R to R) [non normalized]
RR = diff(pLoc); 
    % Rejecty noise from RR
    RRmean = mean(RR);
    rejectMax = RRmean + 2.5*std(RR);
    rejectMin = RRmean - 2.5*std(RR);
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

% Calculate pNN50 (percentage of NN intervals > 50 msec)
ECG_Time_Analysis.pNN50 = RRmean;

%figure
%x = linspace(0,pLoc(end-1),size(RR,1));
%plot(x,RR)
%xlim([0 pLoc(end-1)])
%title('RR interval')
%xlabel('Time (Sec)')
%ylabel('Seconds')
%yline(RRmean,'--r')
end