%% Takes the raw export of imotions and creates new files which:
% - start from the first countdown and finish at the last ITI
% - contains all trials (catch included)
% - has columns [Subj, Slide, TrialN, Other, Sguardo, Event, EDA, ECG, RSP, Catch]


clc; clear; close all


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

parfor s = 1:length(fileNames)
    
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

file2read = strcat('C:\Users\DalMonte\Desktop\EXP Giver Receiver\dati\ALL SUBJECTS\', currSubj);
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

%clear opts

data.Subj(:) = round(s/2);

%% Arrange stimuli/conditions to be analyzed
data.Slide = string(data.Slide);

data( contains(data.Slide,'INTRO') | contains(data.Slide,'END'), : ) = [];

data.Slide(contains(data.Slide,'-5')) = strrep(data.Slide(contains(data.Slide,'-5')), '-5', 'COUNTDOWN');
data.Slide(contains(data.Slide,'-4')) = strrep(data.Slide(contains(data.Slide,'-4')), '-4', 'COUNTDOWN');
data.Slide(contains(data.Slide,'-3')) = strrep(data.Slide(contains(data.Slide,'-3')), '-3', 'COUNTDOWN');
data.Slide(contains(data.Slide,'-2')) = strrep(data.Slide(contains(data.Slide,'-2')), '-2', 'COUNTDOWN');
data.Slide(contains(data.Slide,'-1')) = strrep(data.Slide(contains(data.Slide,'-1')), '-1', 'COUNTDOWN');




stims = data.Slide;
stims = string(stims);

% isCond1 = contains(stims,'FIXCROSS_OTHER_EYE');
% isCond2 = contains(stims,'FIXCROSS_OTHER_CROSS');
% isCond3 = contains(stims,'FIXCROSS_SELF_EYE');
% isCond4 = contains(stims,'FIXCROSS_SELF_CROSS');
% isStim = isCond1 | isCond2 | isCond3 | isCond4;
% data = data(isStim,:);

data.TrialN = regexp(data.Slide,'\d*','Match');

stims = data.Slide;
%stims = string(stims);
data.Catch = zeros(size(data,1),1);
isSelf = contains(data.Slide,'SELF');
data.Catch(isSelf) = 1;

isCond1 = contains(stims,'EYE');
isCond2 = contains(stims,'CROSS');

stims(isCond1) = 'Eye';
stims(isCond2) = 'Cross';

data.Sguardo = stims;

data.Slide = extractBefore(data.Slide,'_');

%data(contains(data.Sguardo,'Self'),:) = [];

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
data.Slide = categorical(data.Slide);

data = movevars(data,'Subj','before','Event');
data = movevars(data,'Slide','before','Event');
data = movevars(data,'TrialN','before','Event');
data = movevars(data,'Other','before','Event');
data = movevars(data,'Sguardo','before','Event');


% correct for some import errors occurring sometimes (rows shifted)
    if ~isnan(data.ECG(2)) & isnan(data.EDA(2))
        data.EDA = circshift(data.EDA,1);
    end

    if ~isnan(data.ECG(2)) & isnan(data.RSP(2))
        data.RSP = circshift(data.RSP,1);
    end

data(ismissing(data.Event) & isnan(data.ECG),:) = [];

file2write = strrep(file2read,'ALL SUBJECTS', 'ALL_SUBJECTS_CLEAN');

writetable(data,file2write)



end