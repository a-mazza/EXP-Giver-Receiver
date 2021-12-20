%% preso dai physio 60seconds
% Here we compute Baseline, where Baseline = ITI (5 sec)
% non esiste iti per il primo trial di ogni blocco, quindi va escluso - non
% si possono prendere sempre 5 secondi dall'intro perché la durata varia da
% soggetto a soggetto (press spacebar) e alcuni hanno intro di meno di 5 sec

% !!! L'evento è definito come  l'inizio del count down
% !!! Il numero di trial TrialN si riferisce al trial di cui sono stati
% presi gli ultimi 5 secondi (ITI), che quindi fanno da base per il trial
% successivo

clear
clc
close all


% upload sequences (just to have it in the workspace)
seq1 = readtable('Sequences.xlsx','sheet',1);
seq2 = readtable('Sequences.xlsx','sheet',2);
seq3 = readtable('Sequences.xlsx','sheet',3);
seq4 = readtable('Sequences.xlsx','sheet',4);

% import blocks (for sconosciuto vs partner)
opts = spreadsheetImportOptions("NumVariables", 7);
opts.Sheet = "EXP";
opts.DataRange = "A2:G15";
opts.VariableNames = ["Var1", "Subj", "Var3", "Var4", "Var5", "Block1", "Block2"];
opts.SelectedVariableNames = ["Subj", "Block1", "Block2"];
opts.VariableTypes = ["char", "string", "char", "char", "char", "string", "string"];
opts = setvaropts(opts, ["Var1", "Subj", "Var3", "Var4", "Var5", "Block1", "Block2"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var1", "Subj", "Var3", "Var4", "Var5", "Block1", "Block2"], "EmptyFieldRule", "auto");
blocks = readtable("C:\Users\test_Admin\Desktop\EXP Giver Receiver\dati\FOGLIO_LAB_DEF.xlsx", opts, "UseExcel", false);
clear opts

zz = strcat(blocks.Subj, {'_'}, blocks.Block1);
zzz = strcat(blocks.Subj, {'_'}, blocks.Block2);
blocks = [zz; zzz];
blocks = sortrows(blocks);
clear zz zzz




fileNames = dir('C:\Users\test_Admin\Desktop\EXP Giver Receiver\dati\ALL SUBJECTS');
okFiles = find(contains({fileNames.name}.','subj'));
fileNames = {fileNames(okFiles).name}.';
fileNames = string(fileNames);

%% Loop 

for s = 1:length(fileNames)
    
    currSubj = fileNames(s);


%% Import data
opts = delimitedTextImportOptions("NumVariables", 20, "Encoding", "UTF-8");
opts.DataLines = [30, Inf];
opts.Delimiter = ",";
opts.VariableNames = ["Var1", "Var2", "Var3", "Event", "Var5", "Var6", "Var7", "Slide", "Var9", "Var10", "ECG", "Var12", "Var13", "EDA", "Var15", "Var16", "EMG", "Var18", "Var19", "RSP"];
opts.SelectedVariableNames = ["Event", "Slide", "ECG", "EDA", "EMG", "RSP"];
opts.VariableTypes = ["string", "string", "string", "string", "string", "string", "string", "categorical", "string", "string", "double", "string", "string", "double", "string", "string", "double", "string", "string", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts = setvaropts(opts, ["Var1", "Var2", "Var3", "Event", "Var5", "Var6", "Var7", "Var9", "Var10", "Var12", "Var13", "Var15", "Var16", "Var18", "Var19"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var1", "Var2", "Var3", "Event", "Var5", "Var6", "Var7", "Slide", "Var9", "Var10", "Var12", "Var13", "Var15", "Var16", "Var18", "Var19"], "EmptyFieldRule", "auto");

file2read = strcat('C:\Users\test_Admin\Desktop\EXP Giver Receiver\dati\ALL SUBJECTS\', currSubj);
data = readtable(file2read, opts);

clear opts

data.Subj(:) = round(s/2);

%% Separate periods of 60 secs

% create vector of zeros and 1 (i.e. trial change) in data.Event
data.Slide = string(data.Slide);
isCountDown = contains(data.Slide,'-');
isCountDown = double(isCountDown);
isPerdiodChange = ischange(isCountDown);

isEvent = find(isPerdiodChange);

isEvent(2:2:end) = [];

data.Event = zeros(size(data,1),1);
data.Event(isEvent) = 1;


% correct for some import errors occurring sometimes (rows shifted)
    if ~isnan(data.ECG(2)) & isnan(data.EDA(2))
        data.EDA = circshift(data.EDA,1);
    end

    if ~isnan(data.ECG(2)) & isnan(data.RSP(2))
        data.RSP = circshift(data.RSP,1);
    end


% clear intro and end
isIntro = find(contains(data.Slide, 'INTRO_OK'));
data(isIntro,:) = [];
data(contains(data.Slide, 'END_OK'),:) = [];


%% Arrange stimuli/conditions to be analyzed

data.TrialN = regexp(data.Slide,'\d*','Match');
isEvent = find(data.Event);
isEvent(end+1) = size(data,1);

for i = 2:size(isEvent)
    
    data.TrialN(isEvent(i-1):isEvent(i)-1) = data.TrialN(isEvent(i)-1);
end

stims = data.Slide;
stims = string(stims);

isCond1 = contains(stims,'OTHER_EYE');
isCond2 = contains(stims,'OTHER_CROSS');
isCond3 = contains(stims,'SELF_EYE');
isCond4 = contains(stims,'SELF_CROSS');
stims(isCond1) = 'Eye';
stims(isCond2) = 'Cross';
stims(isCond3) = 'Self_Eye';
stims(isCond4) = 'Self_Cross';
data.Slide = stims;


data = renamevars(data, 'Slide', 'Sguardo');
data(contains(data.Sguardo,'Self'),:) = [];


% definisci partner vs sconosciuto
    if contains(blocks(s),'P')
        data.Other(:) = string('Partner');
    elseif contains(blocks(s),'S')
        data.Other(:) = string('Stranger');
    else
    end

data.Sguardo = categorical(data.Sguardo);
data.Other = categorical(data.Other);

data = movevars(data,'Subj','before','Event');
data = movevars(data,'Other','before','Sguardo');
data = movevars(data,'TrialN','before','Other');

% correct for some import errors occurring sometimes (rows shifted)
    if ~isnan(data.ECG(4)) & isnan(data.EDA(4))
        data.EDA = circshift(data.EDA,1);
    end

    if ~isnan(data.ECG(4)) & isnan(data.RSP(4))
        data.RSP = circshift(data.RSP,1);
    end

data(data.Event == 0 & isnan(data.ECG),:) = [];



% cut seconds for each trial
isEvent = find(data.Event==1);
isEvent(1) = [];
dat = [];
for ev = 1:size(isEvent)
    zz = data(isEvent(ev)-2500:isEvent(ev)-1,:); % define interval
    dat = [dat; zz];
end

data = dat;
clear dat zz


alldata(s).data = data;
end


% Riunisci in una struttura tutti i grezzi
    for i = 1:2:size(alldata,2)-1    
            Alldata(round(i/2)).Subjects = [alldata(i).data;alldata(i+1).data];       
    end

clear alldata

%% Estrai misure
Measures = [];
%Measures.Properties.VariableNames = {'Subj' 'TrialN' 'Other' 'Sguardo' 'EDA_Mean', 'PeakNumber', 'MeanPeakAmplitude', 'MeanPeakProminence', ...
%     'MeanPeakWidth', 'FirstPeakLatency', 'AreaUnderTheCurve' 'BPM' 'SDNN', 'RMSSD', ...
%     'IBI', 'pNN50' 'RPM', 'Depth', 'Width'};

for ss = 1:size(Alldata,2)
    
dat = Alldata(ss).Subjects;
dat.TrialN = cellfun(@str2double,dat.TrialN);
isChange = ischange(dat.TrialN);
events = find(isChange);
events = [1; events];
events(end+1) = size(dat,1);


    for i = 1:length(events)-1
        trial = dat(events(i):events(i+1),[6 7 9]); % -2500 -> from next event - 5 sec (start ITI) to next event (start next trial)
                                                           % inoltre esclude primo trial (perchè parte da i+1)

        results.ECG(i) = ECG_Time_2(trial.ECG,500);
        results.EDA(i) = EDA_Analysis(trial.EDA,500);
        results.RSP(i) = RSP_Measures(trial.RSP,500);
        close all
    end

% Create a unique table
% define measures
measures = table([results.EDA.EDA_Mean].', [results.EDA.PeakNumber].', [results.EDA.MeanPeakAmplitude].', ...
    [results.EDA.MeanPeakProminence].', [results.EDA.MeanPeakWidth].', [results.EDA.FirstPeakLatency].', ...
    [results.EDA.AreaUnderTheCurve].', [results.ECG.BPM].', [results.ECG.SDNN].', [results.ECG.RMSSD].', [results.ECG.IBI].', ...
    [results.ECG.pNN50].', [results.RSP.RPM].', [results.RSP.Depth].', [results.RSP.Width].', 'variablenames',...
    {'EDA_Mean', 'PeakNumber', 'MeanPeakAmplitude', 'MeanPeakProminence', ...
    'MeanPeakWidth', 'FirstPeakLatency', 'AreaUnderTheCurve' 'BPM' 'SDNN', 'RMSSD', ...
    'IBI', 'pNN50' 'RPM', 'Depth', 'Width'});

% define subj number
measures.Subj(:) = dat.Subj(1);

% define trial number
    for i = 1:length(events)-1
        measures.TrialN(i) = dat.TrialN(events(i));
    end

% define conditions
    for i = 1:length(events)-1
        measures.Other(i) = dat.Other(events(i));
    end

    for i = 1:length(events)-1
        measures.Sguardo(i) = dat.Sguardo(events(i));
    end

measures = movevars(measures,16:19, 'before', 1);

Measures = [Measures;measures];


clear events results measures
end


%% Add behavioral VAS measures

opts = spreadsheetImportOptions("NumVariables", 6);
opts.Sheet = "VAS";
opts.DataRange = "A2:F505";
opts.VariableNames = ["Subj", "Var2", "Other", "Sguardo", "Var5", "VAS"];
opts.SelectedVariableNames = ["Subj", "Other", "Sguardo", "VAS"];
opts.VariableTypes = ["categorical", "char", "categorical", "categorical", "char", "double"];
opts = setvaropts(opts, ["Var2", "Var5"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Subj", "Var2", "Other", "Sguardo", "Var5"], "EmptyFieldRule", "auto");

Behavioral = readtable("C:\Users\test_Admin\Desktop\EXP Giver Receiver\dati\VAS4Analysis.xlsx", opts, "UseExcel", false);

clear opts

Behavioral(Behavioral.Sguardo=='3' | Behavioral.Sguardo=='4', :) = [];

clearvars -except Measures

save Physio_Baseline


