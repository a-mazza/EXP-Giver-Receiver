%% Analizza (import dati singolo blocco, mette in variabile "Measures", elimina, e così via,
% ugualmente lento, ma meglio per preprocessare perchè non ci sono tutti i dati che rallentano)

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
blocks = readtable("C:\Users\DalMonte\Desktop\EXP Giver Receiver\dati\FOGLIO_LAB_DEF.xlsx", opts);
clear opts

blocks.Subj(1:9) = ["01" "02" "03" "04" "05" "06" "07" "08" "09"];


zz = strcat(blocks.Subj, {'_'}, blocks.Block1);
zzz = strcat(blocks.Subj, {'_'}, blocks.Block2);
blocks = [zz; zzz];
blocks = sortrows(blocks);
clear zz zzz




fileNames = dir('C:\Users\DalMonte\Desktop\EXP Giver Receiver\dati\ALL SUBJECTS');
okFiles = find(contains({fileNames.name}.','subj'));
fileNames = {fileNames(okFiles).name}.';
fileNames = string(fileNames);

%% Loop 
MeasuresEDA = [];
for s = 1:length(fileNames)
    
    currSubj = fileNames(s);


% Import data
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

file2read = strcat('C:\Users\DalMonte\Desktop\EXP Giver Receiver\dati\ALL SUBJECTS\', currSubj);
data = readtable(file2read, opts);

toRead = data{data.Var1 == "Row",:};
isEVENT = find(contains(toRead, "SlideEvent"));
isSLIDE = find(contains(toRead, "SourceStimuliName"));
isEDA = find(contains(toRead, "EDA"));


firstRow = find(data.Var1 == "Row");
goodVars = [isEVENT isSLIDE isEDA];

data = data(firstRow+1:end, goodVars);
data.Properties.VariableNames = ["Event", "Slide", "EDA"];
data.Slide = categorical(data.Slide);
data.EDA = str2double(data.EDA);

clear opts

data.Subj(:) = round(s/2);

% Arrange stimuli/conditions to be analyzed
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

data(ismissing(data.Event) & isnan(data.EDA),:) = [];

% cut seconds for each trial
isEvent = find(data.Event=='StartSlide');
dat = [];
for ev = 1:size(isEvent)
    zz = data(isEvent(ev)+startSecs:isEvent(ev)+endSecs,:); % define interval
    dat = [dat; zz];
end



% Estrai misure


    if ~isempty(find(dat.Event=='StartSlide'))
            events = find(dat.Event == 'StartSlide');
    else
            dat.TrialN = cellfun(@str2double, dat.TrialN);
            events = find(ischange(dat.TrialN));
            events = [1; events];
    end
events(end+1) = size(dat,1);
varNs = dat.Properties.VariableNames;
varNs = string(varNs);
varz = find(varNs == 'EDA');

    for i = 1:length(events)-1
        trial = dat(events(i):events(i+1),varz); % define measures
        results.EDA(i) = EDA_Analysis(trial.EDA,500);
        close all
    end

% Create a unique table
% define measures
measuresEDA = table([results.EDA.EDA_Mean].', [results.EDA.PeakNumber].', [results.EDA.MeanPeakAmplitude].', [results.EDA.MeanPeakProminence].', ...
    [results.EDA.MeanPeakWidth].', [results.EDA.FirstPeakLatency].', [results.EDA.AreaUnderTheCurve].', ...
    'variablenames', {'EDA_Mean' 'PeakNumber', 'MeanPeakAmplitude', 'MeanPeakProminence', 'MeanPeakWidth', ...
    'FirstPeakLatency', 'AreaUnderTheCurve'});

% define subj number
measuresEDA.Subj(:) = dat.Subj(1);

% define trial number
    for i = 1:length(events)-1
        measuresEDA.TrialN(i) = dat.TrialN(events(i));
    end

% define conditions
    for i = 1:length(events)-1
        measuresEDA.Other(i) = dat.Other(events(i));
    end

    for i = 1:length(events)-1
        measuresEDA.Sguardo(i) = dat.Sguardo(events(i));
    end

measuresEDA = movevars(measuresEDA,11:14, 'before', 1);

MeasuresEDA = [MeasuresEDA;measuresEDA];


clear events results measuresEDA
end

%%

clearvars -except MeasuresEDA
save(['Physio_' num2str(Xstart) '_to_' num2str(Xend) '_EDA.mat']);


