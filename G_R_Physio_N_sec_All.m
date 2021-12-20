%% Analizza (dati meglio organizzati rispetto all'altro G_R_Physio.m)

clear
clc
close all
 

%% Choose how many secs to keep in the input dialog box

prompt = {'Enter Start time:','Enter End time:'};
dlgtitle = 'Choose window to analyze';
dims = [1 55];
definput = {'0','36'};
answer = inputdlg(prompt,dlgtitle,dims,definput);


% create to save right filenames
Xstart = str2double(answer{1});
Xend = str2double(answer{2});

% transform in samples
startSecs = Xstart*500;
endSecs = Xend*500;

% upload sequences (just to have it in the workspace)
seq1 = readtable('Sequences.xlsx','sheet',1);
seq2 = readtable('Sequences.xlsx','sheet',2);
seq3 = readtable('Sequences.xlsx','sheet',3);
seq4 = readtable('Sequences.xlsx','sheet',4);

% import blocks (for sconosciuto vs partner)
opts = spreadsheetImportOptions("NumVariables", 7);
opts.Sheet = "EXP";
opts.DataRange = "A2";
opts.VariableNames = ["Var1", "Subj", "Var3", "Var4", "Var5", "Block1", "Block2"];
opts.SelectedVariableNames = ["Subj", "Block1", "Block2"];
opts.VariableTypes = ["char", "string", "char", "char", "char", "string", "string"];
opts = setvaropts(opts, ["Var1", "Subj", "Var3", "Var4", "Var5", "Block1", "Block2"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var1", "Subj", "Var3", "Var4", "Var5", "Block1", "Block2"], "EmptyFieldRule", "auto");
blocks = readtable("C:\Users\test_Admin\Desktop\EXP Giver Receiver\dati\FOGLIO_LAB_DEF.xlsx", opts);
clear opts

blocks.Subj(1:9) = ["01" "02" "03" "04" "05" "06" "07" "08" "09"];


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
isEDA = find(contains(toRead, "EDA"));
isECG = find(contains(toRead, "ECG"));
isRSP = find(contains(toRead, "RSP"));

firstRow = find(data.Var1 == "Row");
goodVars = [isEVENT isSLIDE isEDA isECG isRSP];

data = data(firstRow+1:end, goodVars);
data.Properties.VariableNames = ["Event", "Slide", "EDA", "ECG", "RSP"];
data.Slide = categorical(data.Slide);
data.EDA = str2double(data.EDA);
data.ECG = str2double(data.ECG);
data.RSP = str2double(data.RSP);

clear opts

data.Subj(:) = round(s/2);

%% Arrange stimuli/conditions to be analyzed
data.Slide = string(data.Slide);

stims = data.Slide;
stims = string(stims);

isCond1 = contains(stims,'FIXCROSS_OTHER_EYE');
isCond2 = contains(stims,'FIXCROSS_OTHER_CROSS');
isCond3 = contains(stims,'FIXCROSS_SELF_EYE');
isCond4 = contains(stims,'FIXCROSS_SELF_CROSS');
isStim = isCond1 | isCond2 | isCond3 | isCond4;
data = data(isStim,:);

data.TrialN = regexp(data.Slide(contains(data.Slide,'FIXCROSS')),'\d*','Match');

stims = data.Slide;
stims = string(stims);

isCond1 = contains(stims,'FIXCROSS_OTHER_EYE');
isCond2 = contains(stims,'FIXCROSS_OTHER_CROSS');
isCond3 = contains(stims,'FIXCROSS_SELF_EYE');
isCond4 = contains(stims,'FIXCROSS_SELF_CROSS');
stims(isCond1) = 'Eye';
stims(isCond2) = 'Cross';
stims(isCond3) = 'Self_Eye';
stims(isCond4) = 'Self_Cross';
data.Slide = stims;


data = renamevars(data, 'Slide', 'Sguardo');
data(contains(data.Sguardo,'Self'),:) = [];

isGood = data.Event == 'StartSlide' | ismissing(data.Event);
data(~isGood,:) = [];


% definisci partner vs sconosciuto
    if contains(blocks(s),'P')
        data.Other(:) = "Partner";
    elseif contains(blocks(s),'S')
        data.Other(:) = "Stranger";
    else
    end

data.Sguardo = categorical(data.Sguardo);
data.Other = categorical(data.Other);

data = movevars(data,'Subj','before','Event');
data = movevars(data,'Other','before','Sguardo');
data = movevars(data,'TrialN','before','Other');

% correct for some import errors occurring sometimes (rows shifted)
    if ~isnan(data.ECG(2)) & isnan(data.EDA(2))
        data.EDA = circshift(data.EDA,1);
    end

    if ~isnan(data.ECG(2)) & isnan(data.RSP(2))
        data.RSP = circshift(data.RSP,1);
    end

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
    
dat = Alldata(ss).d;

    if ~isempty(find(dat.Event=='StartSlide'))
            events = find(dat.Event == 'StartSlide');
    else
            dat.TrialN = cellfun(@str2double, dat.TrialN);
            events = find(ischange(dat.TrialN));
            events = [1; events];
    end
events(end+1) = size(dat,1);


    for i = 1:length(events)-1
        trial = dat(events(i):events(i+1),[6 7 8]); % define measures

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

opts = spreadsheetImportOptions("NumVariables", 8);
opts.Sheet = "VAS";
opts.DataRange = "A:H";
opts.VariableNames = ["Subj", "TrialN", "Other", "Sguardo", "SEQ", "VAS", "Note", "Invalid"];
opts.VariableTypes = ["string", "double", "double", "categorical", "categorical", "double", "string", "double"];
opts = setvaropts(opts, "Note", "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Subj", "SEQ", "Note"], "EmptyFieldRule", "auto");

Behavioral = readtable("C:\Users\test_Admin\Desktop\EXP Giver Receiver\dati\FOGLIO_LAB_DEF.xlsx", opts, "UseExcel", false);

clear opts

% clean
Behavioral(1,:) = []; % del first row repeated var names
Behavioral.Subj = regexprep(Behavioral.Subj, '^(\D+)(\d+)(.*)', '$2'); % delete alphanumeric
Behavioral.Subj = str2double(Behavioral.Subj);
Behavioral = sortrows(Behavioral,{'Subj' 'SEQ' 'TrialN'}); % Sort
Behavioral.SEQ = []; % del seq

Behavioral(Behavioral.Sguardo=='3' | Behavioral.Sguardo=='4', :) = [];

Measures.VAS = Behavioral.VAS;

clearvars -except Measures Xstart Xend

save(['Physio_' num2str(Xstart) '_to_' num2str(Xend) '_threshold_001.mat']);


