function RSP_Analysis = RSP_Measures(data,SR)
%% Basic

% Delete nans

itsnan = find(isnan(data));
data(itsnan,:) = [];

% Standardize
%data = (data - mean(data)) / std(data);


% Filter
tx =(0:size(data,1)-1)'*1/SR;
%data = bandpass(data, [0.05 1]);
Fs = 1/mean(diff(tx)); % Average sample rate

tx =(0:size(data,1)-1)'*1/SR; % define time based on sampling rate SR

[peaks,peakLocs,w,pProm] = findpeaks(data,tx,...
    'MinPeakDistance',1.2,'MinPeakProminence',0.15,...
    'Annotate','extents','WidthReference','halfheight');

% Plot raw data and peaks
figure
hold on
plot(tx,data,'k','linewidth',1.5)
plot(peakLocs,peaks,'ro','MarkerFaceColor','r')
legend('Standardized Data','Peaks');
xlabel('Seconds')
hold off


% % Plot frequencies
% figure
% pspectrum(data);


%% Measures

% Respiration Frequency
RSP_Analysis.RPM = length(peakLocs)*SR*60/length(data); 

% Respiration Depth
RSP_Analysis.Depth = mean(pProm);

% Respiration Cycles width
RSP_Analysis.Width = mean(w);

RSP_Analysis.PeakNum = length(peakLocs);


end