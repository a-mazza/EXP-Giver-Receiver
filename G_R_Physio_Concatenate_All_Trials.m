%% Analizza per concatenare tutti i trials.  t=0 è inizio trial (quindi t = 5 è inizio tocco)
% al primo trial sono lasciati come baseline 5 secondi di slide intro 
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

alldata = [];

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

% !!! L'evento è definito come  l'inizio del count down

% Lasciare 5 secondi (2500 samples)  di pre-stimolo baseline anche per il primo trial,
% prendendolo quindi da intro_ok


isIntro = find(contains(data.Slide, 'INTRO_OK'));
data(isIntro(1:end-2500),:) = [];
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


% isGood = data.Event == 'StartSlide' | data.Event == '';
% data(~isGood,:) = [];


% definisci partner vs sconosciuto
    if contains(blocks(s),'P')
        data.Other(:) = string('Partner');
    elseif contains(blocks(s),'S')
        data.Other(:) = string('Stranger');
    else
    end

data.Sguardo = categorical(data.Sguardo);
data.Other = categorical(data.Other);


data(data.Event == 0 & isnan(data.ECG),:) = [];

% create events for ledalab
% ledalab wants conditions defined by the code of the event:

%               1 = StrangerCross
%               2 = StrangerEye
%               3 = PartnerCross
%               4 = PartnerEye
ev = zeros(size(data.Event));
is1 = data.Event == 1 & data.Other == 'Stranger' & data.Sguardo == 'Cross';
is2 = data.Event == 1 & data.Other == 'Stranger' & data.Sguardo == 'Eye';
is3 = data.Event == 1 & data.Other == 'Partner' & data.Sguardo == 'Cross';
is4 = data.Event == 1 & data.Other == 'Partner' & data.Sguardo == 'Eye';

ev(is1) = 1;
ev(is2) = 2;
ev(is3) = 3;
ev(is4) = 4;

data.Event = ev;


data = [data.EDA data.Event];




alldata = [alldata; data];


end

% substitute nan values with the mean of the preceding and subsequent 10  values
alldata(find(isnan(alldata)),1) = nanmean( [alldata((find(isnan(alldata)))-10,1):alldata((find((isnan(alldata))))+10,1)] );


addpath 'C:\Users\test_Admin\Desktop\EXP partner\Analyses\ledalab-349'

dlmwrite('C:\Users\test_Admin\Desktop\EXP Giver Receiver\Data4Ledalab\EDA_data60s.txt',alldata)


%% Analizza solo eda per ledalab. 36 secondi di touch. t=0 è inizio trial (quindi t = 5 è inizio tocco)
% al primo trial sono lasciati come baseline 5 secondi di slide intro 
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

alldata = [];

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

% !!! L'evento è definito come  l'inizio del count down

% Lasciare 5 secondi (2500 samples)  di pre-stimolo baseline anche per il primo trial,
% prendendolo quindi da intro_ok


isIntro = find(contains(data.Slide, 'INTRO_OK'));
data(isIntro(1:end-2500),:) = [];
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


% isGood = data.Event == 'StartSlide' | data.Event == '';
% data(~isGood,:) = [];


% definisci partner vs sconosciuto
    if contains(blocks(s),'P')
        data.Other(:) = string('Partner');
    elseif contains(blocks(s),'S')
        data.Other(:) = string('Stranger');
    else
    end

data.Sguardo = categorical(data.Sguardo);
data.Other = categorical(data.Other);


data(data.Event == 0 & isnan(data.ECG),:) = [];

% create events for ledalab
% ledalab wants conditions defined by the code of the event:

%               1 = StrangerCross
%               2 = StrangerEye
%               3 = PartnerCross
%               4 = PartnerEye
ev = zeros(size(data.Event));
is1 = data.Event == 1 & data.Other == 'Stranger' & data.Sguardo == 'Cross';
is2 = data.Event == 1 & data.Other == 'Stranger' & data.Sguardo == 'Eye';
is3 = data.Event == 1 & data.Other == 'Partner' & data.Sguardo == 'Cross';
is4 = data.Event == 1 & data.Other == 'Partner' & data.Sguardo == 'Eye';

ev(is1) = 1;
ev(is2) = 2;
ev(is3) = 3;
ev(is4) = 4;

data.Event = ev;


data = [data.EDA data.Event];




alldata = [alldata; data];


end

% substitute nan values with the mean of the preceding and subsequent 10  values
alldata(find(isnan(alldata)),1) = nanmean( [alldata((find(isnan(alldata)))-10,1):alldata((find((isnan(alldata))))+10,1)] );


addpath 'C:\Users\test_Admin\Desktop\EXP partner\Analyses\ledalab-349'

dlmwrite('C:\Users\test_Admin\Desktop\EXP Giver Receiver\Data4Ledalab\EDA_data60s.txt',alldata)


%% Analizza solo eda per ledalab. 36 secondi di touch. t=0 è inizio trial (quindi t = 5 è inizio tocco)
% al primo trial sono lasciati come baseline 5 secondi di slide intro 
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

alldata = [];

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

% !!! L'evento è definito come  l'inizio del count down

% Lasciare 5 secondi (2500 samples)  di pre-stimolo baseline anche per il primo trial,
% prendendolo quindi da intro_ok


isIntro = find(contains(data.Slide, 'INTRO_OK'));
data(isIntro(1:end-2500),:) = [];
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


% isGood = data.Event == 'StartSlide' | data.Event == '';
% data(~isGood,:) = [];


% definisci partner vs sconosciuto
    if contains(blocks(s),'P')
        data.Other(:) = string('Partner');
    elseif contains(blocks(s),'S')
        data.Other(:) = string('Stranger');
    else
    end

data.Sguardo = categorical(data.Sguardo);
data.Other = categorical(data.Other);


data(data.Event == 0 & isnan(data.ECG),:) = [];

% create events for ledalab
% ledalab wants conditions defined by the code of the event:

%               1 = StrangerCross
%               2 = StrangerEye
%               3 = PartnerCross
%               4 = PartnerEye
ev = zeros(size(data.Event));
is1 = data.Event == 1 & data.Other == 'Stranger' & data.Sguardo == 'Cross';
is2 = data.Event == 1 & data.Other == 'Stranger' & data.Sguardo == 'Eye';
is3 = data.Event == 1 & data.Other == 'Partner' & data.Sguardo == 'Cross';
is4 = data.Event == 1 & data.Other == 'Partner' & data.Sguardo == 'Eye';

ev(is1) = 1;
ev(is2) = 2;
ev(is3) = 3;
ev(is4) = 4;

data.Event = ev;


%data = [data.ECG data.Event];




alldata = [alldata; data];


end

% substitute nan values with the mean of the preceding and subsequent 10  values
alldata(find(isnan(alldata)),1) = nanmean( [alldata((find(isnan(alldata)))-10,1):alldata((find((isnan(alldata))))+10,1)] );



