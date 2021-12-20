clc
clear
close


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

file2read = strcat('C:\Users\DalMonte\Desktop\EXP Giver Receiver\dati\ALL SUBJECTS\', currSubj);
data = readtable(file2read, opts);

toRead = data{data.Var1 == "Row",:};
isEVENT = find(contains(toRead, "SlideEvent"));
isSLIDE = find(contains(toRead, "SourceStimuliName"));
isRSP = find(contains(toRead, "RSP"));


firstRow = find(data.Var1 == "Row");
goodVars = [isEVENT isSLIDE isRSP];

data = data(firstRow+1:end, goodVars);
data.Properties.VariableNames = ["Event", "Slide", "RSP"];
data.Slide = categorical(data.Slide);
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

data(ismissing(data.Event) & isnan(data.RSP),:) = [];

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
events(end+1) = size(data,1);


    for i = 1:length(events)-1
        trial = data(events(i):events(i+1), [1 3 4 6]); % define measures

        results = RSP_Measures(trial.RSP,500);
        f = gcf;
        f.WindowState = 'maximized'; 
        title(['Sogg ' num2str(trial.Subj(2)) ' Trial ' char(trial.TrialN{2}) trial.Other(2)])
        w = waitforbuttonpress;
        close all
        
        if w == 1
            other = sprintf('%s',(trial.Other(2)));
            tr = sprintf('%s',['trial ' (trial.TrialN{2})]);
            resp = trial.RSP;
            resp = resp';
            srate = 500;
            save(['C:\Users\DalMonte\Desktop\EXP Giver Receiver\Matlab Scripts\RSP_Valid_Data\Subj_' num2str(trial.Subj(2)) '\' other '_' tr],'resp', 'srate');
            clear tr resp
        else
             
        end
                
        
    end
        
end

