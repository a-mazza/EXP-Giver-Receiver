% clc
% clear
% close all

%%

prompt = {'Enter Start time:','Enter End time:'};
dlgtitle = 'Choose window to analyze';
dims = [1 55];
definput = {'0','36'};
answer = inputdlg(prompt,dlgtitle,dims,definput);

Xstart = str2double(answer{1});
Xend = str2double(answer{2});

% ask for subject, sequence and trial
prompt = {'Subject (DUE CIFRE SEMPRE):','Sequence','Trial (due cifre solo se >= 10'};
dlgtitle = 'Choose trial to preprocess';
dims = [1 55];
definput = {'0','A','0'};
answer = inputdlg(prompt,dlgtitle,dims,definput);

s = str2double(answer{1});
ss = answer{1};
seq = answer{2};
t = answer{3};


% transform in samples
startSecs = Xstart*500;
endSecs = Xend*500;

% upload sequences (just to have it in the workspace)
seq1 = readtable('Sequences.xlsx','sheet',1);
seq2 = readtable('Sequences.xlsx','sheet',2);
seq3 = readtable('Sequences.xlsx','sheet',3);
seq4 = readtable('Sequences.xlsx','sheet',4);


%% Choose subj 

    currSubj = ['subj_' ss '_' seq];

%% Import data
opts = delimitedTextImportOptions("NumVariables", 20, "Encoding", "UTF-8");
% opts.DataLines = [30, Inf];
opts.Delimiter = ",";
% opts.VariableNames = ["Var1", "Var2", "Var3", "Event", "Var5", "Var6", "Var7", "Slide", "Var9", "Var10", "ECG", "Var12", "Var13", "EDA", "Var15", "Var16", "EMG", "Var18", "Var19", "RSP"];
% opts.SelectedVariableNames = ["Event", "Slide", "ECG", "EDA", "EMG", "RSP"];
opts.VariableTypes = ["string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string", "string"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
% opts = setvaropts(opts, ["Var1", "Var2", "Var3", "Event", "Var5", "Var6", "Var7", "Var9", "Var10", "Var12", "Var13", "Var15", "Var16", "Var18", "Var19"], "WhitespaceRule", "preserve");
% opts = setvaropts(opts, ["Var1", "Var2", "Var3", "Event", "Var5", "Var6", "Var7", "Slide", "Var9", "Var10", "Var12", "Var13", "Var15", "Var16", "Var18", "Var19"], "EmptyFieldRule", "auto");

file2read = strcat('C:\Users\test_Admin\Desktop\EXP Giver Receiver\dati\ALL SUBJECTS\', currSubj);
data = readtable(file2read, opts);

toRead = data{data.Var1 == "Row",:};
isEVENT = find(contains(toRead, "SlideEvent"));
isSLIDE = find(contains(toRead, "SourceStimuliName"));
isECG = find(contains(toRead, "ECG"));


firstRow = find(data.Var1 == "Row");
goodVars = [isEVENT isSLIDE isECG];

data = data(firstRow+1:end, goodVars);
data.Properties.VariableNames = ["Event", "Slide", "ECG"];
data.Slide = categorical(data.Slide);
data.ECG = str2double(data.ECG);

clear opts

data.Subj(:) = s;

%% Arrange stimuli/conditions to be analyzed
data.Slide = string(data.Slide);
data = data(find(contains(data.Slide,'FIXCROSS')),:);
data.TrialN = regexp(data.Slide(contains(data.Slide,'FIXCROSS')),'\d*','Match');
data(ismissing(data.Event) & isnan(data.ECG),:) = [];

% cut seconds for each trial
isEvent = find(data.Event=='StartSlide');
dat = [];
for ev = 1:size(isEvent)
    zz = data(isEvent(ev)+startSecs:isEvent(ev)+endSecs,:); % define interval
    dat = [dat; zz];
end

data = dat;
clear dat zz




    if ~isempty(find(data.Event=='StartSlide'))
            events = find(data.Event == 'StartSlide');
    else
            data.TrialN = cellfun(@str2double, data.TrialN);
            events = find(ischange(data.TrialN));
            events = [1; events];
    end

isTrial = find(string(data.TrialN) == t);
isTrial(1,:) = [];


dataa = data;   
    
 







%% \\\\\\\\\\\\\\\\\\ Copied analyzer \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
data = dataa.ECG(isTrial); 
SR = 500;


itsnan = find(isnan(data));
data(itsnan,:) = [];

% standardize
data = (data-mean(data)) / std(data);

data(1000:500*12.5) = data(1000:500*12.5)*3;

tx =(0:size(data,1)-1)'*1/SR;
Fs = 1/mean(diff(tx)); % Average sample rate

% Filter
%data = bandstop(data,[49 51],Fs);
%data = highpass(data,5,Fs);
%data = lowpass(data,5,Fs);



% Create the wavelet resembling your ECG signal and Find peaks


% Decompose the ECG waveform down to level 5 using the default 'sym4' wavelet.
wt = modwt(data,5);  

wtrec = zeros(size(wt));
wtrec(4:5,:) = wt(4:5,:);
y = imodwt(wtrec,'sym4');


% Find peaks of the wavelet --> Solve for inversed polarities

% Use the squared absolute values of the signal approximation built from the 
% wavelet coefficients and employ a peak finding algorithm ( findepeaks() ) 
% to identify the R peaks.

y = abs(y).^2; % squared absolute value

tx =(0:size(data,1)-1)'*1/SR; % define time based on sampling rate SR

[peaks,peakLocs] = findpeaks(y,tx,'MinPeakHeight',2*mean(y),...
    'MinPeakDistance',0.3);



peaks(9) = [];
peakLocs(9) = [];


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
%ECG_Analysis.RR = RR;
%ECG_Analysis.RRsterr = sterr(RR);

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




%% Substitute preprocessed values in Measures

% create vector with new values to be substituted
fn = fieldnames(ECG_Analysis);
fn = string(fn);
nfn = length(fn);

ecgprep = [];

for s = 1:nfn
    z = sprintf('%s', fn(s));
    zz = ECG_Analysis.(z);
    ecgprep = [ecgprep zz];
end
    
% load Measures   
load('Physio_0_to_36_ECG.mat')   
    

%% Save measures
    
save('Physio_0_to_36_ECG.mat','MeasuresECG')    
    
    

