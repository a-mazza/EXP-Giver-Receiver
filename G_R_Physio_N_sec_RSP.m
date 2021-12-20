%% Analizza (import dati singolo blocco, mette in variabile "Measures", elimina, e così via,
% ugualmente lento, ma meglio per preprocessare perchè non ci sono tutti i dati che rallentano)

% - diverso dagli altri: usa BREATHMETRICS e non le mie funzioni.
% - prende i trial validi in RSP_Valid_Data (scelti a mano trial by trial)
% - VALIDO SOLO PER I 36 SECONDI
%
% - MISURE ESTRATTE:
%       Resp Rate 
%       Coeff. di variazione della resp rate
%       Resp volume
%       Coeff. di variazione del resp volume
%
% Also, deletes zero values and nans at the end
% 
%  SALVA IN: 'C:\Users\DalMonte\Desktop\EXP Giver Receiver\dati\RSP_Clean.xlsx'

clear
clc
close all

% upload sequences from LABDEF (for later assignment of Sguardo)
opts = spreadsheetImportOptions("NumVariables", 7);
opts.Sheet = "EXP";
opts.DataRange = "A:G";
opts.VariableNames = ["Var1", "SOGGETTO", "Var3", "Var4", "SEX", "BLOCCO_1sequenza_other", "BLOCCO_2sequenza_other"];
opts.SelectedVariableNames = ["SOGGETTO", "SEX", "BLOCCO_1sequenza_other", "BLOCCO_2sequenza_other"];
opts.VariableTypes = ["char", "double", "char", "char", "categorical", "categorical", "categorical"];
opts = setvaropts(opts, ["Var1", "Var3", "Var4"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var1", "Var3", "Var4", "SEX", "BLOCCO_1sequenza_other", "BLOCCO_2sequenza_other"], "EmptyFieldRule", "auto");
fogliolabdef = readtable("C:\Users\DalMonte\Desktop\EXP Giver Receiver\dati\FOGLIO_LAB_DEF.xlsx", opts, "UseExcel", false);
clear opts

fogliolabdef(1,:) = [];
fogliolabdef.Properties.VariableNames = {'Subj', 'Gender', 'Block1', 'Block2'};


% upload sequences (for later assignment of Sguardo)
seq1 = readtable('Sequences.xlsx','sheet',1);
seq2 = readtable('Sequences.xlsx','sheet',2);
seq3 = readtable('Sequences.xlsx','sheet',3);
seq4 = readtable('Sequences.xlsx','sheet',4);
 

%% Upload
rootPath = 'C:\Users\DalMonte\Desktop\EXP Giver Receiver\Matlab Scripts\RSP_Valid_Data';
szPath = dir(rootPath);
szPath = size(szPath,1) - 2;

AllSubjects = table;

for sp = 1:szPath % Cartella RSP_Valid_Data -> scegli soggetto
    data = table;
    dat = table;
    sogg = ['Subj_' num2str(sp)];
    subjID = sprintf('%s',sogg);
    soggFolder = dir(fullfile(rootPath,sogg));
    soggFolder(1:2,:) = [];
    files = natsortfiles(soggFolder);
    szFolder = size(files,1);
    fileNames = {files.name};
    
    for sf = 1:szFolder % Cartella del soggetto -> processa trial
            currFile = fullfile(rootPath,sogg,fileNames(sf));
            respiratoryData = load(currFile{1});
            respiratoryData.resp([1 end]) = [];

            % Analyze (commands taken and adapted from breathmetrics)
            respiratoryRecording = respiratoryData.resp;
            srate = respiratoryData.srate;
            dataType = 'humanAirflow';
            addpath 'C:\Users\DalMonte\Desktop\EXP Giver Receiver\Matlab Scripts\breathmetrics-master\breathmetrics_functions'
            
            currSubj = breathmetrics(respiratoryRecording, srate, dataType);
            
            verbose = 0; 
            baselineCorrectionMethod = 'sliding'; 
            zScore = 1;
            simplify = 1;

            currSubj.estimateAllFeatures(zScore, [], simplify, verbose);

            currSubj.findExtrema(simplify, verbose);
            currSubj.findOnsetsAndPauses(verbose);
            currSubj.findInhaleAndExhaleOffsets(currSubj);
            currSubj = findBreathAndPauseDurations(currSubj);
            currSubj.findInhaleAndExhaleVolumes(verbose);
            currSubj.getSecondaryFeatures(verbose);

            statKeys = currSubj.secondaryFeatures.keys();
            breathingRateKey = statKeys{11};                    % 'Breathing Rate'
            breathRateVvariationCoefficientKey = statKeys{13};  % 'Coefficient of Variation of Breathing Rate'
            tidalVolumeCoefficientKey = statKeys{10}; % 'Average Tidal Volume'
            volumeVariationCoefficientKey = statKeys{12};       % 'Coefficient of Variation of Breath Volumes'
            
            breathingRate = currSubj.secondaryFeatures(breathingRateKey);
            varBreathRate = currSubj.secondaryFeatures(breathRateVvariationCoefficientKey);
            tidalVolume = currSubj.secondaryFeatures(tidalVolumeCoefficientKey);
            varBreathVol = currSubj.secondaryFeatures(volumeVariationCoefficientKey);

        

        % Put in the subject's table
        data.BreathRate = breathingRate;
        data.BreathRateVar = varBreathRate;
        data.BreathVol = tidalVolume;
        data.BreathVolVar = varBreathVol;
        

        % Add Sogg ID
        soggID = regexp(sogg,'\d*','Match');
        data.Subj = soggID{1};
        data.Subj = str2double(data.Subj);

        % Add trial number
        trialN = regexp(fileNames{sf},'\d*','Match');
        data.TrialN = trialN{1};
        data.TrialN = str2double(data.TrialN);

        % Add Other
        if contains(fileNames{sf},'Partner')
            data.Other = categorical("Partner");
        elseif contains(fileNames{sf},'Stranger')
            data.Other = categorical("Stranger");
        end

        % Add Gender
        data.Gender = fogliolabdef.Gender(fogliolabdef.Subj==data.Subj);

        
        
        
        % Add Sguardo
        currOther = data.Other;
        currLabDefOther = string([fogliolabdef.Block1(fogliolabdef.Subj==data.Subj) fogliolabdef.Block2(fogliolabdef.Subj==data.Subj)]);
        
        switch currOther

            case 'Partner'
                o = find(contains(currLabDefOther,'P'));
                currSeq = currLabDefOther(o);
                currSeq = extractBefore(currSeq,'_');
                    if currSeq == 'A'
                        currSguardo = seq1.c(str2double(trialN{1}));
                            switch currSguardo
                                case 1
                                    currSguardo = 'Eye';
                                case 2
                                    currSguardo = 'Cross';
                            end
                    
                    elseif currSeq == 'B'
                        currSguardo = seq2.c(str2double(trialN{1}));
                            switch currSguardo
                                case 1
                                    currSguardo = 'Eye';
                                case 2
                                    currSguardo = 'Cross';
                            end

                    elseif currSeq == 'c'
                        currSguardo = seq3.c(str2double(trialN{1}));
                            switch currSguardo
                                case 1
                                    currSguardo = 'Eye';
                                case 2
                                    currSguardo = 'Cross';
                            end

                    elseif currSeq == 'D'
                        currSguardo = seq4.c(str2double(trialN{1}));
                            switch currSguardo
                                case 1
                                    currSguardo = 'Eye';
                                case 2
                                    currSguardo = 'Cross';
                            end
                    end
                             


            case 'Stranger'
                o = find(contains(currLabDefOther,'S'));
                currSeq = currLabDefOther(o);
                currSeq = extractBefore(currSeq,'_');
                    if currSeq == 'A'
                        currSguardo = seq1.c(str2double(trialN{1}));
                            switch currSguardo
                                case 1
                                    currSguardo = 'Eye';
                                case 2
                                    currSguardo = 'Cross';
                            end
                    
                    elseif currSeq == 'B'
                        currSguardo = seq2.c(str2double(trialN{1}));
                            switch currSguardo
                                case 1
                                    currSguardo = 'Eye';
                                case 2
                                    currSguardo = 'Cross';
                            end

                    elseif currSeq == 'c'
                        currSguardo = seq3.c(str2double(trialN{1}));
                            switch currSguardo
                                case 1
                                    currSguardo = 'Eye';
                                case 2
                                    currSguardo = 'Cross';
                            end

                    elseif currSeq == 'D'
                        currSguardo = seq4.c(str2double(trialN{1}));
                            switch currSguardo
                                case 1
                                    currSguardo = 'Eye';
                                case 2
                                    currSguardo = 'Cross';
                            end
                    end
        end

        data.Sguardo = currSguardo;
        data.Sguardo = categorical(cellstr(data.Sguardo));
        dat = [dat;data];

        
    end
    dat = movevars(dat,5:9,'Before',1);
    dat = movevars(dat,'Gender','before','TrialN');
    AllSubjects = [AllSubjects; dat];
end

% Delete nans and zeros
AllSubjects(isnan(AllSubjects.BreathRate),:) = [];
AllSubjects(isnan(AllSubjects.BreathRateVar),:) = [];
AllSubjects(isnan(AllSubjects.BreathVol),:) = [];
AllSubjects(isnan(AllSubjects.BreathVolVar),:) = [];

forzeros = AllSubjects{:,6:9};
forzeros = ~forzeros;
forzeros = forzeros(:,1) | forzeros(:,2) | forzeros(:,3) | forzeros(:,4);
haszeros = find(forzeros);
AllSubjects(haszeros,:) = [];

% save
writetable(AllSubjects,'C:\Users\DalMonte\Desktop\EXP Giver Receiver\dati\RSP_Clean.xlsx');








