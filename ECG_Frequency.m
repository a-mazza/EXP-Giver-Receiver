function ECG_Freq_Analysis = ECG_Frequency(data,SR)
%% Preprocess
% Delete nans
%data = data.ECG;
itsnan = find(isnan(data));
data(itsnan,:) = [];

% Delete offset
data = data-mean(data);

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

[pks,pLoc] = findpeaks(y,tx,'MinPeakHeight',0.1,...
    'MinPeakDistance',0.300);


figure
plot(tx,data,'k','linewidth',2)
hold on
plot(tx,y,'r','linewidth',1.5)
plot(tx,abs(data).^2,'b--')
plot(pLoc,pks,'ro')
legend('Raw Data','Wavelet Reconstruction','Raw Data Squared', ...
    'Location','SouthEast');
xlabel('Seconds')

%% Extract features

% Beats per minute
BPM = length(pLoc)*SR*60/length(data); 

RR = diff(pLoc); 
RRsize = length(RR);

% Interpolate RR series with N of points = 10 * BPM
xRR = 1:RRsize;
xq = linspace(1,RRsize,round(100000*BPM));


RRinterp = interp1(xRR,RR,xq);


 %Calculate PSD
 figure
      [PSD,F] = pwelch(RRinterp,[],[],[],Fs); %uses a hamming window
      %VLF = [0.0033 0.04];
      LF = [0.04 0.15];
      HF = [0.15 0.4];
      % find the indexes corresponding to the VLF, LF, and HF bands
      %iVLF= (F>=VLF(1)) & (F<=VLF(2));
      iLF = (F>=LF(1)) & (F<=LF(2));
      iHF = (F>=HF(1)) & (F<=HF(2));
      % calculate areas, within the freq bands (ms^2)
      %aVLF=trapz(F(iVLF),PSD(iVLF));
      %set(handles.vlf, 'string', num2str(aVLF));
      aLF=trapz(F(iLF),PSD(iLF));
      %set(handles.lf, 'string', num2str(LF));
      aHF=trapz(F(iHF),PSD(iHF));
      %set(handles.hf, 'string', num2str(aHF));
      aTotal=aLF+aHF;
      %set(handles.tp, 'string', num2str(aTotal));
%     calculate areas relative to the total area (%)
%     pVLF=(aVLF/aTotal)*100;
%     pLF=(aLF/aTotal)*100;
%     pHF=(aHF/aTotal)*100;
      %calculate LF/HF ratio
      ECG_Freq_Analysis.LFHF =aLF/aHF;
%axes(handles.axes5);
%set(handles.text45, 'visible', 'on')
%set(handles.axes5, 'visible', 'on')
%plot area under PSD curve
% area(F(:),PSD(:),'FaceColor',[.6 .6 .6]);        
grid on;
end