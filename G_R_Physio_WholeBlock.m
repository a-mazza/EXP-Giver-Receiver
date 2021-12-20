%% Analizza a blocco intero (solo per HRV e RSP)

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

file2read = strcat('C:\Users\test_Admin\Desktop\EXP Giver Receiver\dati\ALL SUBJECTS\', currSubj);
data = readtable(file2read, opts);

toRead = data{data.Var1 == "Row",:};
isEVENT = find(contains(toRead, "SlideEvent"));
isSLIDE = find(contains(toRead, "SourceStimuliName"));
isECG = find(contains(toRead, "ECG"));
isRSP = find(contains(toRead, "RSP"));



firstRow = find(data.Var1 == "Row");
goodVars = [isEVENT isSLIDE isECG isRSP];

data = data(firstRow+1:end, goodVars);
data.Properties.VariableNames = ["Event", "Slide", "ECG" "RSP"];
data.Slide = categorical(data.Slide);
data.ECG = str2double(data.ECG);
data.RSP = str2double(data.RSP);

clear opts

data.Subj(:) = round(s/2);

%% Separate periods of 60 secs



data(contains(string(data.Slide), 'INTRO_OK'),:) = [];
data(contains(string(data.Slide), 'END_OK'),:) = [];


%% Arrange stimuli/conditions to be analyzed

% definisci partner vs sconosciuto
    if contains(blocks(s),'P')
        data.Other(:) = string('Partner');
    elseif contains(blocks(s),'S')
        data.Other(:) = string('Stranger');
    else
    end

data.Other = categorical(data.Other);

data = movevars(data,'Subj','before','Event');
data = movevars(data,'Other','before','Event');


    if ~isnan(data.ECG(2)) & isnan(data.RSP(2))
        data.RSP = circshift(data.RSP,1);
    end

data(isnan(data.RSP) & isnan(data.ECG),:) = [];

alldata(s).data = data;
end


% Riunisci in una struttura tutti i grezzi
    for i = 1:2:size(alldata,2)-1    
            Alldata(round(i/2)).Subjects = [alldata(i).data;alldata(i+1).data];       
    end

clear alldata

%% Estrai misure
Measures = [];


for ss = 1:size(Alldata,2)
    
dat = Alldata(ss).Subjects;
block = dat.Other == 'Partner';
block = double(block);
block = [1, find(ischange(block)), size(dat,1)]; % set blocks [start to change block (block 1), change block to end (block 2)

    for i = 1:length(block)-1
        trial = dat(block(i):block(i+1),5); % check column numbers

        results.ECG(i) = ECG_Analyze(trial.ECG,500);
        %results.RSP(i) = RSP_Measures(trial.RSP,500);   % if you want rsp too, add column 8    
        close all
    end


% Create a unique table
% define measures
measures = table([results.ECG.BPM].', [results.ECG.SDNN].', [results.ECG.RMSSD].', [results.ECG.IBI].', ...
    [results.ECG.pNN50].', [results.ECG.pLF].', [results.ECG.pHF].', [results.ECG.rpLF].', [results.ECG.rpHF].',...
    [results.ECG.LF_HF_ratio].',[results.RSP.RPM].', [results.RSP.Depth].', [results.RSP.Width].', 'variablenames',...
    {'BPM' 'SDNN', 'RMSSD','IBI', 'pNN50', 'pLF', 'pHF', 'rpLF', 'rpHF', 'LF_HF_ratio', 'RPM', 'Depth', 'Width'});

% define subj number
measures.Subj(:) = dat.Subj(1);

measures = movevars(measures,'Subj', 'before', 1);

Measures = [Measures;measures];




clear events results measures
end

% Add other

Measures.Other = blocks;

for i = 1:size(Measures,1)
    if contains(Measures.Other(i), '_S')
        Measures.Other(i) = 'S';
    else
        Measures.Other(i) = 'P';
    end
end

Measures = movevars(Measures,'Other','before','EDA_Mean');


clearvars -except Measures

save Physio_WholeBlock
