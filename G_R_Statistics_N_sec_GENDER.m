% % Only valid for EDA
% % choose the interval to analyze
% % stats including GENDER as factor
% 
% 
% clc
% clear
% close all


%% Dialog boxes
% Ask for time window to analyze
% verify the interval exists in folder - If not, use 'G_R_Physio_N_sec.m' to create it

% prompt = {'Enter Start time:','Enter End time:'};
% dlgtitle = 'Choose window to run stats';
% dims = [1 55];
% definput = {'0','36'};
% answerWind = inputdlg(prompt,dlgtitle,dims,definput);
% 
% startSecs = str2double(answerWind{1});
% endSecs = str2double(answerWind{2});

% % ask for EDA normalization
% prompt = {'Normalize EDA?'};
% dlgtitle = 'Choose to normalize EDA data (within subjects)';
% answerNormEDA = questdlg(prompt,dlgtitle,'Yes','No','Yes');
% 
% % ask for VAS normalization
% prompt = {'Normalize VAS?'};
% dlgtitle = 'Choose to normalize VAS data (within subjects)';
% answerNormVAS = questdlg(prompt,dlgtitle,'Yes','No','Yes');

% % ask for plotting sing subj
% prompt = {'Plot single subjects VAS and EDA?'};
% dlgtitle = 'Choose to plot sing subj';
% answerPlotSing = questdlg(prompt,dlgtitle,'Yes','No','No');

% % ask for plotting averages
% prompt = {'Plot Average measures?'};
% dlgtitle = 'Choose to plot means for measures';
% answerPlotMean = questdlg(prompt,dlgtitle,'Yes','No','Yes');

% % ask for plot quarters
% prompt = {'Choose measure'};
% dlgtitle = 'Measure to plot in quarters';
% answerPlotQuart = inputdlg(prompt,dlgtitle, [1 50]);
% answerPlotQuart = string(answerPlotQuart);


% % ask for bad subjs
% prompt = {'Enter bad subjects - Space-separated values'};
% dlgtitle = 'Bad subjects';
% answerBadSubj = inputdlg(prompt,dlgtitle, [1 50]);
% answerBadSubjs = str2num(answerBadSubj{1});

% answerBadSubjs = 1:15;

%% import
%file = 'Physio_0_to_36_threshold_001.mat';
load(file);

% Add gender
opts = spreadsheetImportOptions("NumVariables", 1);
opts.Sheet = "EXP";
opts.DataRange = "E1";
opts.VariableNames = "SEX";
%opts.VariableTypes = "categorical"; 
opts = setvaropts(opts, "SEX", "EmptyFieldRule", "auto");

Genders = readtable("C:\Users\test_Admin\Desktop\EXP Giver Receiver\dati\FOGLIO_LAB_DEF.xlsx", opts, "UseExcel", false);
clear opts
Genders(1,:) = [];

Genders = Genders.SEX;


Measures.Gender = zeros(size(Measures,1),1);
Measures = movevars(Measures,'Gender','before','VAS');
Measures.Gender = categorical(Measures.Gender);

gn = length(Genders);
for g = 1:gn
    Measures.Gender(Measures.Subj == g) = Genders(g);
end


% Delete bad subjects

isBadSubj = ismember(Measures.Subj, answerBadSubjs);
Measures(isBadSubj,:) = [];

%isn = find(isnan(Measures.VAS));
%Measures(isn,:) = [];
%% \\\\\\\ CALCULATIONS \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

%% Normalize EDA and VAS (in case)

if answerNormEDA == 1
sn = unique(Measures.Subj);
    for mm = 7:13
        for ss = 1:length(sn)
            mes = Measures(Measures.Subj == sn(ss), mm);
            mes = table2array(mes);
            switch answerNormType
                case 'minMax'
            mes = (mes - min(mes)) / (max(mes) - min(mes));
                case 'z-score'
            mes = (mes - mean(mes))/std(mes);
            end
            mes(isnan(mes)) = 0;
            Measures(Measures.Subj == sn(ss), mm) = array2table(mes);
        end
    end
    
else
end




if answerNormECG == 1
sn = unique(Measures.Subj);
    for mm = 16:25
        for ss = 1:length(sn)
            mes = Measures(Measures.Subj == sn(ss), mm);
            mes = table2array(mes);
            switch answerNormType
                case 'minMax'
            mes = (mes - min(mes)) / (max(mes) - min(mes));
                case 'z-score'
            mes = (mes - mean(mes))/std(mes);
            end
            mes(isnan(mes)) = 0;
            Measures(Measures.Subj == sn(ss), mm) = array2table(mes);
        end
    end
    
else
end



if answerNormVAS == 1
sn = unique(Measures.Subj);

    for ss = 1:length(sn)
        mes = Measures.VAS(Measures.Subj == sn(ss));
            switch answerNormType
                case 'minMax'
            mes = (mes - min(mes)) / (max(mes) - min(mes));
                case 'z-score'
            mes = (mes - mean(mes))/std(mes);
            end
        Measures.VAS(Measures.Subj == sn(ss)) = mes;
    end

    
else
end
    
%% Means by subject

% exclude subjects (OCCHIO CHE POI SALVA PLOTS E STATS E LE SOVRASCRIVE)!!!!!!!!!!!!!!!!!!!

% Measures(Measures.Subj==2,:) = [];
% Measures(Measures.Subj==4,:) = [];
% Measures(Measures.Subj==6,:) = [];
% Measures(Measures.Subj==7,:) = [];
% Measures(Measures.Subj==9,:) = [];


groups = table(Measures.Subj, Measures.Other, Measures.Sguardo, Measures.Gender);

[G, GID] = findgroups(groups);

GID.Properties.VariableNames = {'Sogg' 'Other' 'Sguardo' 'Gender'};


for i = 6:size(Measures.Properties.VariableNames,2)
    
    soggCondMeans = splitapply(@nanmean,Measures(:,i),G);
    
    z = table(soggCondMeans, 'variablenames', {num2str(rand(1,1))} );
    
    GID = [GID z];
    
end


GID.Properties.VariableNames = Measures.Properties.VariableNames([1 3:end]);

subjMeans = GID; clear GID


%% Means by conditions 4 plots

G = findgroups(subjMeans.Gender, subjMeans.Other, subjMeans.Sguardo);

allMeans = [];

for i = 5:size(subjMeans.Properties.VariableNames,2)
    
    CondMeans = splitapply(@nanmean,subjMeans(:,i),G);
    
    z = table(CondMeans, 'variablenames', {num2str(rand(1,1))} );
    
    allMeans = [allMeans z];
    
end

allMeans.Properties.VariableNames = subjMeans.Properties.VariableNames(5:end);


allMeans.Properties.RowNames = {'F_Stranger_Cross' 'F_Stranger_Eye' 'F_Partner_Cross' 'F_Partner_Eye' ...
    'M_Stranger_Cross' 'M_Stranger_Eye' 'M_Partner_Cross' 'M_Partner_Eye'};


% errors

errs = [];

for i = 5:size(subjMeans.Properties.VariableNames,2)
    
    meanErr = splitapply(@sterr,subjMeans(:,i),G);
    
    z = table(meanErr, 'variablenames', {num2str(rand(1,1))} );
    
    errs = [errs z];
    
end

errs.Properties.VariableNames = allMeans.Properties.VariableNames;
errs.Properties.RowNames = allMeans.Properties.RowNames;


Genders = array2table(Genders);
Genders.Subj = [1:size(Genders,1)]';
isBadSubj = ismember(Genders.Subj, answerBadSubjs);
Genders(isBadSubj,:) = [];
Genders = Genders.Genders;



%% Suddivisione in quarti e plot
if answerPlotQuart ~= ''

    subjsN = unique(subjMeans.Subj);

    q1SC = []; q2SC = []; q3SC = []; q4SC = [];
    q1SE = []; q2SE = []; q3SE = []; q4SE = [];
    q1PC = []; q2PC = []; q3PC = []; q4PC = [];
    q1PE = []; q2PE = []; q3PE = []; q4PE = [];


    % create a table for each quarter for each condition
    for s = 1:length(subjsN)

        ss = Measures(Measures.Subj == subjsN(s),:);

        qSC = ss(ss.Subj == subjsN(s) & ss.Other == 'Stranger' & ss.Sguardo == 'Cross',:);
        qSE = ss(ss.Subj == subjsN(s) & ss.Other == 'Stranger' & ss.Sguardo == 'Eye',:);
        qPC = ss(ss.Subj == subjsN(s) & ss.Other == 'Partner' & ss.Sguardo == 'Cross',:);
        qPE = ss(ss.Subj == subjsN(s) & ss.Other == 'Partner' & ss.Sguardo == 'Eye',:);

        q1SCa = qSC(1:2,:);  q2SCa = qSC(3:4,:);  q3SCa = qSC(5:6,:);  q4SCa = qSC(7:8,:);
        q1SC = [q1SC;q1SCa]; q2SC = [q2SC;q2SCa]; q3SC = [q3SC;q3SCa]; q4SC = [q4SC;q4SCa];
        clear q1SCa q2SCa q3SCa q4SCa

        q1SEa = qSE(1:2,:);  q2SEa = qSE(3:4,:);  q3SEa = qSE(5:6,:);  q4SEa = qSE(7:8,:);
        q1SE = [q1SE;q1SEa]; q2SE = [q2SE;q2SEa]; q3SE = [q3SE;q3SEa]; q4SE = [q4SE;q4SEa];
        clear q1SEa q2SEa q3SEa q4SEa

        q1PCa = qPC(1:2,:);  q2PCa = qPC(3:4,:);  q3PCa = qPC(5:6,:);  q4PCa = qPC(7:8,:);
        q1PC = [q1PC;q1PCa]; q2PC = [q2PC;q2PCa]; q3PC = [q3PC;q3PCa]; q4PC = [q4PC;q4PCa];
        clear q1PCa q2PCa q3PCa q4PCa

        q1PEa = qPE(1:2,:);  q2PEa = qPE(3:4,:);  q3PEa = qPE(5:6,:);  q4PEa = qPE(7:8,:);
        q1PE = [q1PE;q1PEa]; q2PE = [q2PE;q2PEa]; q3PE = [q3PE;q3PEa]; q4PE = [q4PE;q4PEa];
        clear q1PEa q2PEa q3PEa q4PEa
    end

    clear qPC qPE qSC qSE


    ySC = [nanmean(q1SC.(answerPlotQuart)) nanmean(q2SC.(answerPlotQuart)) nanmean(q3SC.(answerPlotQuart)) nanmean(q4SC.(answerPlotQuart))];
    ySE = [nanmean(q1SE.(answerPlotQuart)) nanmean(q2SE.(answerPlotQuart)) nanmean(q3SE.(answerPlotQuart)) nanmean(q4SE.(answerPlotQuart))];
    yPC = [nanmean(q1PC.(answerPlotQuart)) nanmean(q2PC.(answerPlotQuart)) nanmean(q3PC.(answerPlotQuart)) nanmean(q4PC.(answerPlotQuart))];
    yPE = [nanmean(q1PE.(answerPlotQuart)) nanmean(q2PE.(answerPlotQuart)) nanmean(q3PE.(answerPlotQuart)) nanmean(q4PE.(answerPlotQuart))];

    ySCerr = [nanstd(q1SC.(answerPlotQuart))/sqrt(length(q1SC.(answerPlotQuart))) nanstd(q2SC.(answerPlotQuart))/sqrt(length(q2SC.(answerPlotQuart))) nanstd(q3SC.(answerPlotQuart))/sqrt(length(q3SC.(answerPlotQuart))) nanstd(q4SC.(answerPlotQuart))/sqrt(length(q4SC.(answerPlotQuart)))];
    ySEerr = [nanstd(q1SE.(answerPlotQuart))/sqrt(length(q1SE.(answerPlotQuart))) nanstd(q2SE.(answerPlotQuart))/sqrt(length(q2SE.(answerPlotQuart))) nanstd(q3SE.(answerPlotQuart))/sqrt(length(q3SE.(answerPlotQuart))) nanstd(q4SE.(answerPlotQuart))/sqrt(length(q4SE.(answerPlotQuart)))];
    yPCerr = [nanstd(q1PC.(answerPlotQuart))/sqrt(length(q1PC.(answerPlotQuart))) nanstd(q2PC.(answerPlotQuart))/sqrt(length(q2PC.(answerPlotQuart))) nanstd(q3PC.(answerPlotQuart))/sqrt(length(q3PC.(answerPlotQuart))) nanstd(q4PC.(answerPlotQuart))/sqrt(length(q4PC.(answerPlotQuart)))];
    yPEerr = [nanstd(q1PE.(answerPlotQuart))/sqrt(length(q1PE.(answerPlotQuart))) nanstd(q2PE.(answerPlotQuart))/sqrt(length(q2PE.(answerPlotQuart))) nanstd(q3PE.(answerPlotQuart))/sqrt(length(q3PE.(answerPlotQuart))) nanstd(q4PE.(answerPlotQuart))/sqrt(length(q4PE.(answerPlotQuart)))];



    fh = figure();
    errorbar(ySC,ySCerr,'r')
    hold on
    errorbar(ySE,ySEerr,':r')
    errorbar(yPC,yPCerr,'b')
    errorbar(yPE,yPEerr,':b')
    xticks([1:4])
    xlim([0.5 4.5])
    legend({'Strager Cross', 'Stranger Eye' 'Partner Cross' 'Partner Eye'})
    xlabel('Quarters')
    title(answerPlotQuart)


    if answerSaveQuart == 1
    fh.WindowState = 'maximized';
    saveas(gcf,['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Plots\Quarters\' answerPlotQuart '.png'])
    close 
    end
else
end


%% \\\\\\\\\\\\\\\\ STATS \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
%% EDA_Mean
% Create table for analysis (1 table for each measure)
a = table(subjMeans.Subj, subjMeans.EDA_Mean, 'variablenames', {'Subj' 'EDA_Mean'});

EDA_Mean = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.EDA_Mean(a.Subj == subjsN(i));
    z = z';
    EDA_Mean(i,:) = z;
end

EDA_Mean = array2table(EDA_Mean);
EDA_Mean.Properties.VariableNames = {'StrangerCross' 'StrangerEye' 'PartnerCross' 'PartnerEye'};
EDA_Mean.Gender = Genders;
EDA_Mean = movevars(EDA_Mean,'Gender','before','StrangerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Stranger' 'Partner' 'Partner'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(EDA_Mean,'StrangerCross-PartnerEye ~Gender','withindesign',withintab);

ANOVA_EDA_Mean = ranova(rm,'withinmodel','Other*Sguardo');

if answerSaveStats == 1
writetable(ANOVA_EDA_Mean, ['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Stats\ANOVA_EDA_Mean_' num2str(startSecs) '_to_' num2str(endSecs) '_Gender.xlsx'],'WriteRowNames',true);
end


%% PeakNumber

% Create table for analysis (1 table for each measure)

a = table(subjMeans.Subj, subjMeans.PeakNumber, 'variablenames', {'Subj' 'PeakNumber'});

PeakNumber = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.PeakNumber(a.Subj == subjsN(i));
    z = z';
    PeakNumber(i,:) = z;
end

PeakNumber = array2table(PeakNumber);
PeakNumber.Properties.VariableNames = {'StrangerCross' 'StrangerEye' 'PartnerCross' 'PartnerEye'};
PeakNumber.Gender = Genders;
PeakNumber = movevars(PeakNumber,'Gender','before','StrangerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Stranger' 'Partner' 'Partner'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(PeakNumber,'StrangerCross-PartnerEye ~Gender','withindesign',withintab);

ANOVA_PeakNumber = ranova(rm,'withinmodel','Other*Sguardo');

if answerSaveStats == 1
writetable(ANOVA_PeakNumber, ['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Stats\ANOVA_PeakNumber_' num2str(startSecs) '_to_' num2str(endSecs) '_Gender.xlsx'],'WriteRowNames',true);
end


%% MeanPeakAmplitude

% Create table for analysis (1 table for each measure)

a = table(subjMeans.Subj, subjMeans.MeanPeakAmplitude, 'variablenames', {'Subj' 'MeanPeakAmplitude'});

MeanPeakAmplitude = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.MeanPeakAmplitude(a.Subj == subjsN(i));
    z = z';
    MeanPeakAmplitude(i,:) = z;
end

MeanPeakAmplitude = array2table(MeanPeakAmplitude);
MeanPeakAmplitude.Properties.VariableNames = {'StrangerCross' 'StrangerEye' 'PartnerCross' 'PartnerEye'};
MeanPeakAmplitude.Gender = Genders;
MeanPeakAmplitude = movevars(MeanPeakAmplitude,'Gender','before','StrangerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Stranger' 'Partner' 'Partner'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(MeanPeakAmplitude,'StrangerCross-PartnerEye ~Gender','withindesign',withintab);

ANOVA_MeanPeakAmplitude = ranova(rm,'withinmodel','Other*Sguardo');

if answerSaveStats == 1
writetable(ANOVA_MeanPeakAmplitude, ['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Stats\ANOVA_MeanPeakAmplitude_' num2str(startSecs) '_to_' num2str(endSecs) '_Gender.xlsx'],'WriteRowNames',true);
end

%% MeanPeakProminence

% Create table for analysis (1 table for each measure)

a = table(subjMeans.Subj, subjMeans.MeanPeakProminence, 'variablenames', {'Subj' 'MeanPeakProminence'});

MeanPeakProminence = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.MeanPeakProminence(a.Subj == subjsN(i));
    z = z';
    MeanPeakProminence(i,:) = z;
end

MeanPeakProminence = array2table(MeanPeakProminence);
MeanPeakProminence.Properties.VariableNames = {'StrangerCross' 'StrangerEye' 'PartnerCross' 'PartnerEye'};
MeanPeakProminence.Gender = Genders;
MeanPeakProminence = movevars(MeanPeakProminence,'Gender','before','StrangerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Stranger' 'Partner' 'Partner'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(MeanPeakProminence,'StrangerCross-PartnerEye ~Gender','withindesign',withintab);

ANOVA_MeanPeakProminence = ranova(rm,'withinmodel','Other*Sguardo');

if answerSaveStats == 1
writetable(ANOVA_MeanPeakProminence, ['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Stats\ANOVA_MeanPeakProminence_' num2str(startSecs) '_to_' num2str(endSecs) '_Gender.xlsx'],'WriteRowNames',true);
end


%% MeanPeakWidth

% Create table for analysis (1 table for each measure)

a = table(subjMeans.Subj, subjMeans.MeanPeakWidth, 'variablenames', {'Subj' 'MeanPeakWidth'});

MeanPeakWidth = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.MeanPeakWidth(a.Subj == subjsN(i));
    z = z';
    MeanPeakWidth(i,:) = z;
end

MeanPeakWidth = array2table(MeanPeakWidth);
MeanPeakWidth.Properties.VariableNames = {'StrangerCross' 'StrangerEye' 'PartnerCross' 'PartnerEye'};
MeanPeakWidth.Gender = Genders;
MeanPeakWidth = movevars(MeanPeakWidth,'Gender','before','StrangerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Stranger' 'Partner' 'Partner'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(MeanPeakWidth,'StrangerCross-PartnerEye ~Gender','withindesign',withintab);

ANOVA_MeanPeakWidth = ranova(rm,'withinmodel','Other*Sguardo');

if answerSaveStats == 1
writetable(ANOVA_MeanPeakWidth, ['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Stats\ANOVA_MeanPeakWidth_' num2str(startSecs) '_to_' num2str(endSecs) '_Gender.xlsx'],'WriteRowNames',true);
end


%% AreaUnderTheCurve

% Create table for analysis (1 table for each measure)

a = table(subjMeans.Subj, subjMeans.AreaUnderTheCurve, 'variablenames', {'Subj' 'AreaUnderTheCurve'});

AreaUnderTheCurve = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.AreaUnderTheCurve(a.Subj == subjsN(i));
    z = z';
    AreaUnderTheCurve(i,:) = z;
end

AreaUnderTheCurve = array2table(AreaUnderTheCurve);
AreaUnderTheCurve.Properties.VariableNames = {'StrangerCross' 'StrangerEye' 'PartnerCross' 'PartnerEye'};
AreaUnderTheCurve.Gender = Genders;
AreaUnderTheCurve = movevars(AreaUnderTheCurve,'Gender','before','StrangerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Stranger' 'Partner' 'Partner'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(AreaUnderTheCurve,'StrangerCross-PartnerEye ~Gender','withindesign',withintab);

ANOVA_AreaUnderTheCurve = ranova(rm,'withinmodel','Other*Sguardo');

%writetable(ANOVA_AreaUnderTheCurve, ['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Stats\ANOVA_AreaUnderTheCurve_' num2str(startSecs) '_to_' num2str(endSecs) '_Gender.xlsx'],'WriteRowNames',true);





%% pLF

% Create table for analysis (1 table for each measure)

a = table(subjMeans.Subj, subjMeans.pLF, 'variablenames', {'Subj' 'pLF'});

pLF = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.pLF(a.Subj == subjsN(i));
    z = z';
    pLF(i,:) = z;
end

pLF = array2table(pLF);
pLF.Properties.VariableNames = {'StrangerCross' 'StrangerEye' 'PartnerCross' 'PartnerEye'};
pLF.Gender = Genders;
pLF = movevars(pLF,'Gender','before','StrangerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Stranger' 'Partner' 'Partner'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(pLF,'StrangerCross-PartnerEye ~Gender','withindesign',withintab);

ANOVA_pLF = ranova(rm,'withinmodel','Other*Sguardo');




%% pHF

% Create table for analysis (1 table for each measure)

a = table(subjMeans.Subj, subjMeans.pHF, 'variablenames', {'Subj' 'pHF'});

pHF = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.pHF(a.Subj == subjsN(i));
    z = z';
    pHF(i,:) = z;
end

pHF = array2table(pHF);
pHF.Properties.VariableNames = {'StrangerCross' 'StrangerEye' 'PartnerCross' 'PartnerEye'};
pHF.Gender = Genders;
pHF = movevars(pHF,'Gender','before','StrangerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Stranger' 'Partner' 'Partner'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(pHF,'StrangerCross-PartnerEye ~Gender','withindesign',withintab);

ANOVA_pHF = ranova(rm,'withinmodel','Other*Sguardo');


%% rpLF

% Create table for analysis (1 table for each measure)

a = table(subjMeans.Subj, subjMeans.rpLF, 'variablenames', {'Subj' 'rpLF'});

rpLF = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.rpLF(a.Subj == subjsN(i));
    z = z';
    rpLF(i,:) = z;
end

rpLF = array2table(rpLF);
rpLF.Properties.VariableNames = {'StrangerCross' 'StrangerEye' 'PartnerCross' 'PartnerEye'};
rpLF.Gender = Genders;
rpLF = movevars(rpLF,'Gender','before','StrangerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Stranger' 'Partner' 'Partner'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(rpLF,'StrangerCross-PartnerEye ~Gender','withindesign',withintab);

ANOVA_rpLF = ranova(rm,'withinmodel','Other*Sguardo');



%% rpHF

% Create table for analysis (1 table for each measure)

a = table(subjMeans.Subj, subjMeans.rpHF, 'variablenames', {'Subj' 'rpHF'});

rpHF = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.rpHF(a.Subj == subjsN(i));
    z = z';
    rpHF(i,:) = z;
end

rpHF = array2table(rpHF);
rpHF.Properties.VariableNames = {'StrangerCross' 'StrangerEye' 'PartnerCross' 'PartnerEye'};
rpHF.Gender = Genders;
rpHF = movevars(rpHF,'Gender','before','StrangerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Stranger' 'Partner' 'Partner'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(rpHF,'StrangerCross-PartnerEye ~Gender','withindesign',withintab);

ANOVA_rpHF = ranova(rm,'withinmodel','Other*Sguardo');





%% LF_HF_ratio

% Create table for analysis (1 table for each measure)

a = table(subjMeans.Subj, subjMeans.LF_HF_ratio, 'variablenames', {'Subj' 'LF_HF_ratio'});

LF_HF_ratio = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.LF_HF_ratio(a.Subj == subjsN(i));
    z = z';
    LF_HF_ratio(i,:) = z;
end

LF_HF_ratio = array2table(LF_HF_ratio);
LF_HF_ratio.Properties.VariableNames = {'StrangerCross' 'StrangerEye' 'PartnerCross' 'PartnerEye'};
LF_HF_ratio.Gender = Genders;
LF_HF_ratio = movevars(LF_HF_ratio,'Gender','before','StrangerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Stranger' 'Partner' 'Partner'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(LF_HF_ratio,'StrangerCross-PartnerEye ~Gender','withindesign',withintab);

ANOVA_LF_HF_ratio = ranova(rm,'withinmodel','Other*Sguardo');


%% BPM

% Create table for analysis (1 table for each measure)

a = table(subjMeans.Subj, subjMeans.BPM, 'variablenames', {'Subj' 'BPM'});

BPM = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.BPM(a.Subj == subjsN(i));
    z = z';
    BPM(i,:) = z;
end

BPM = array2table(BPM);
BPM.Properties.VariableNames = {'StrangerCross' 'StrangerEye' 'PartnerCross' 'PartnerEye'};
BPM.Gender = Genders;
BPM = movevars(BPM,'Gender','before','StrangerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Stranger' 'Partner' 'Partner'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(BPM,'StrangerCross-PartnerEye ~Gender','withindesign',withintab);

ANOVA_BPM = ranova(rm,'withinmodel','Other*Sguardo');




%% SDNN

% Create table for analysis (1 table for each measure)

a = table(subjMeans.Subj, subjMeans.SDNN, 'variablenames', {'Subj' 'SDNN'});

SDNN = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.SDNN(a.Subj == subjsN(i));
    z = z';
    SDNN(i,:) = z;
end

SDNN = array2table(SDNN);
SDNN.Properties.VariableNames = {'StrangerCross' 'StrangerEye' 'PartnerCross' 'PartnerEye'};
SDNN.Gender = Genders;
SDNN = movevars(SDNN,'Gender','before','StrangerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Stranger' 'Partner' 'Partner'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(SDNN,'StrangerCross-PartnerEye ~Gender','withindesign',withintab);

ANOVA_SDNN = ranova(rm,'withinmodel','Other*Sguardo');



%% RMSSD

% Create table for analysis (1 table for each measure)

a = table(subjMeans.Subj, subjMeans.RMSSD, 'variablenames', {'Subj' 'RMSSD'});

RMSSD = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.RMSSD(a.Subj == subjsN(i));
    z = z';
    RMSSD(i,:) = z;
end

RMSSD = array2table(RMSSD);
RMSSD.Properties.VariableNames = {'StrangerCross' 'StrangerEye' 'PartnerCross' 'PartnerEye'};
RMSSD.Gender = Genders;
RMSSD = movevars(RMSSD,'Gender','before','StrangerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Stranger' 'Partner' 'Partner'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(RMSSD,'StrangerCross-PartnerEye ~Gender','withindesign',withintab);

ANOVA_RMSSD = ranova(rm,'withinmodel','Other*Sguardo');


%% pNN50

% Create table for analysis (1 table for each measure)

a = table(subjMeans.Subj, subjMeans.pNN50, 'variablenames', {'Subj' 'pNN50'});

pNN50 = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.pNN50(a.Subj == subjsN(i));
    z = z';
    pNN50(i,:) = z;
end

pNN50 = array2table(pNN50);
pNN50.Properties.VariableNames = {'StrangerCross' 'StrangerEye' 'PartnerCross' 'PartnerEye'};
pNN50.Gender = Genders;
pNN50 = movevars(pNN50,'Gender','before','StrangerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Stranger' 'Partner' 'Partner'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(pNN50,'StrangerCross-PartnerEye ~Gender','withindesign',withintab);

ANOVA_pNN50 = ranova(rm,'withinmodel','Other*Sguardo');



%% VAS

% Create table for analysis (1 table for each measure)

a = table(subjMeans.Subj, subjMeans.VAS, 'variablenames', {'Subj' 'VAS'});

VAS = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.VAS(a.Subj == subjsN(i));
    z = z';
    VAS(i,:) = z;
end

VAS = array2table(VAS);
VAS.Properties.VariableNames = {'StrangerCross' 'StrangerEye' 'PartnerCross' 'PartnerEye'};
VAS.Gender = Genders;
VAS = movevars(VAS,'Gender','before','StrangerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Stranger' 'Partner' 'Partner'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(VAS,'StrangerCross-PartnerEye ~Gender','withindesign',withintab);

ANOVA_VAS = ranova(rm,'withinmodel','Other*Sguardo');



%% \\\\\\\ PLOTS \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

if answerPlotMean == 1

for i = 1:size(allMeans,2)
    
    y = table2array(allMeans(:,i));
    y = reshape(y,4,2)';
    yerr = table2array(errs(:,i));
    yerr = reshape(yerr,4,2)';    
    
    fh = figure()    
    b = bar(y, 'grouped');
    b(1,1).FaceColor = [0.1, 0.6, 1];
    b(1,2).FaceColor = [0.1, 0.7, 0.9];
    b(1,3).FaceColor = [0.8500, 0.3250, 0.0980];
    b(1,4).FaceColor = [1, 0.8, 0.2];
    
    hold on
    
    [ngroups,nbars] = size(yerr);

    x = nan(nbars, ngroups);
    for j = 1:nbars
        x(j,:) = b(j).XEndPoints;
    end
    % Plot the errorbars
    errorbar(x',y,yerr,'k','linestyle','none');
    
    hold off
    
    title(allMeans.Properties.VariableNames(i))
    
    xlabel('Gender')
    xticklabels({'Females' 'Males'})
    legend({'Stranger Cross' 'Stranger Eye' 'Partner Cross' 'Partner Eye'})
    
    if answerSaveMeans == 1
    fh.WindowState = 'maximized';
    saveas(gcf,['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Plots\Main\' allMeans.Properties.VariableNames{i} '.png'])
    close  
    end
    
end

end

%% _________explore VAS correlations (find and replace measures here)


%% VAS Cross vs VAS eye
% c'è correlazione tra le VAS di partner e sconosciuto solo se si considera quando
% i soggetti guardano la croce (cioè, un sogg è più propenso a dare punteggi alti, sia allo sconosciuto che al partner).
% Ma la correlazione sparisce quando guardano negli occhi: Il guardare negli occhi 
% ha un effetto sulla predisposizione a dare punteggi alti

if answerPlotVASVAS == 1

mdlCross = fitlm(VAS.PartnerCross, VAS.StrangerCross);
mdlEye = fitlm(VAS.PartnerEye, VAS.StrangerEye);

fh = figure();

scatter(VAS.PartnerCross, VAS.StrangerCross,'b','filled')
hold on
scatter(VAS.PartnerEye, VAS.StrangerEye,'r','filled')

xlabel('VAS Partner')
ylabel('VAS Stranger')
title('VAS ratings')
legend({['Cross p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)], ...
        ['Eye p = ' num2str(mdlEye.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlEye.Rsquared.Ordinary)]})

coefficients = polyfit(VAS.PartnerCross, VAS.StrangerCross, 1);
xFit = linspace(min(VAS.PartnerCross), max(VAS.PartnerCross), 1000);
yFit = polyval(coefficients , xFit);
plot(xFit, yFit, 'b-', 'LineWidth', 1); 

coefficients = polyfit(VAS.PartnerEye, VAS.StrangerEye, 1);
xFit = linspace(min(VAS.PartnerEye), max(VAS.PartnerEye), 1000);
yFit = polyval(coefficients , xFit);
plot(xFit, yFit, 'r-', 'LineWidth', 1); 
  
hold off


if answerSaveVASVAS == 1
fh.WindowState = 'maximized';
saveas(gcf,['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Plots\Correlations\' allMeans.Properties.VariableNames{i} '.png'])
end

end

%% ________ plot each subject separately (explorative)

if answerPlotSing == 1

%% EDA_Mean

nSubjs = size(unique(Measures.Subj),1);

% Means
y1 = [];

for s = 1:nSubjs
    yy = mean(Measures.EDA_Mean(Measures.Subj == s & ...
        Measures.Other == 'Stranger' & Measures.Sguardo == 'Cross'));
    y1= [y1; yy];
end

y2 = [];

for s = 1:nSubjs
    yy = mean(Measures.EDA_Mean(Measures.Subj == s & ...
        Measures.Other == 'Stranger' & Measures.Sguardo == 'Eye'));
    y2= [y2; yy];
end

y3 = [];

for s = 1:nSubjs
    yy = mean(Measures.EDA_Mean(Measures.Subj == s & ...
        Measures.Other == 'Partner' & Measures.Sguardo == 'Cross'));
    y3= [y3; yy];
end


y4 = [];

for s = 1:nSubjs
    yy = mean(Measures.EDA_Mean(Measures.Subj == s & ...
        Measures.Other == 'Partner' & Measures.Sguardo == 'Eye'));
    y4= [y4; yy];
end


y = [y1 y2 y3 y4];






% errors
y1err = [];

for s = 1:nSubjs
    yyerr = sterr(Measures.EDA_Mean(Measures.Subj == s & ...
        Measures.Other == 'Stranger' & Measures.Sguardo == 'Cross'));
    y1err= [y1err; yyerr];
end

y2err = [];

for s = 1:nSubjs
    yyerr = sterr(Measures.EDA_Mean(Measures.Subj == s & ...
        Measures.Other == 'Stranger' & Measures.Sguardo == 'Eye'));
    y2err= [y2err; yyerr];
end

y3err = [];

for s = 1:nSubjs
    yyerr = sterr(Measures.EDA_Mean(Measures.Subj == s & ...
        Measures.Other == 'Partner' & Measures.Sguardo == 'Cross'));
    y3err= [y3err; yyerr];
end


y4err = [];

for s = 1:nSubjs
    yyerr = sterr(Measures.EDA_Mean(Measures.Subj == s & ...
        Measures.Other == 'Partner' & Measures.Sguardo == 'Eye'));
    y4err= [y4err; yyerr];
end


yerr = [y1err y2err y3err y4err];

% Plot
fh = figure();
b = bar(y,'grouped');

hold on

[ngroups,nbars] = size(yerr);

x = nan(nbars, ngroups);
for j = 1:nbars
    x(j,:) = b(j).XEndPoints;
end
% Plot the errorbars
errorbar(x',y,yerr,'k','linestyle','none');

hold off

title('EDA_Mean')
xlabel('Subjects')
xticklabels((1:nSubjs))
legend({'Stranger Cross' 'Stranger Eye' 'Partner Cross' 'Parnter Eye'})


if answerSaveSing == 1
fh.WindowState = 'maximized';
saveas(gcf,['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Plots\Single subjects\' allMeans.Properties.VariableNames{i} '.png'])
end



%% MeanPeakAmplitude

% Means
y1 = [];

for s = 1:nSubjs
    yy = mean(Measures.MeanPeakAmplitude(Measures.Subj == s & ...
        Measures.Other == 'Stranger' & Measures.Sguardo == 'Cross'));
    y1= [y1; yy];
end

y2 = [];

for s = 1:nSubjs
    yy = mean(Measures.MeanPeakAmplitude(Measures.Subj == s & ...
        Measures.Other == 'Stranger' & Measures.Sguardo == 'Eye'));
    y2= [y2; yy];
end

y3 = [];

for s = 1:nSubjs
    yy = mean(Measures.MeanPeakAmplitude(Measures.Subj == s & ...
        Measures.Other == 'Partner' & Measures.Sguardo == 'Cross'));
    y3= [y3; yy];
end


y4 = [];

for s = 1:nSubjs
    yy = mean(Measures.MeanPeakAmplitude(Measures.Subj == s & ...
        Measures.Other == 'Partner' & Measures.Sguardo == 'Eye'));
    y4= [y4; yy];
end


y = [y1 y2 y3 y4];






% errors
y1err = [];

for s = 1:nSubjs
    yyerr = sterr(Measures.MeanPeakAmplitude(Measures.Subj == s & ...
        Measures.Other == 'Stranger' & Measures.Sguardo == 'Cross'));
    y1err= [y1err; yyerr];
end

y2err = [];

for s = 1:nSubjs
    yyerr = sterr(Measures.MeanPeakAmplitude(Measures.Subj == s & ...
        Measures.Other == 'Stranger' & Measures.Sguardo == 'Eye'));
    y2err= [y2err; yyerr];
end

y3err = [];

for s = 1:nSubjs
    yyerr = sterr(Measures.MeanPeakAmplitude(Measures.Subj == s & ...
        Measures.Other == 'Partner' & Measures.Sguardo == 'Cross'));
    y3err= [y3err; yyerr];
end


y4err = [];

for s = 1:nSubjs
    yyerr = sterr(Measures.MeanPeakAmplitude(Measures.Subj == s & ...
        Measures.Other == 'Partner' & Measures.Sguardo == 'Eye'));
    y4err= [y4err; yyerr];
end


yerr = [y1err y2err y3err y4err];

% Plot
figure
b = bar(y,'grouped');

hold on

[ngroups,nbars] = size(yerr);

x = nan(nbars, ngroups);
for j = 1:nbars
    x(j,:) = b(j).XEndPoints;
end
% Plot the errorbars
errorbar(x',y,yerr,'k','linestyle','none');

hold off

title('MeanPeakAmplitude')
xlabel('Subjects')
xticklabels((1:nSubjs))
legend({'Stranger Cross' 'Stranger Eye' 'Partner Cross' 'Parnter Eye'})


end


%% ///////////// QUESTIONARI/////////////////////////////////////////////
%% ___ STAI

% import
opts = spreadsheetImportOptions("NumVariables", 4);
opts.Sheet = "EXP";
opts.DataRange = "R:U";
opts.VariableNames = ["tratto", "stato_baseline", "stato_P", "stato_S"];
opts.VariableTypes = ["double", "double", "double", "double"];
stai = readtable("C:\Users\test_Admin\Desktop\EXP Giver Receiver\dati\FOGLIO_LAB_DEF.xlsx", opts, "UseExcel", false);
clear opts

% delete first row (not read as variables)
stai(1,:) = [];

stai.deltaP = stai.stato_P - stai.stato_baseline;
stai.deltaS = stai.stato_S - stai.stato_baseline;
stai.Subj = [1:size(stai,1)]';
stai = movevars(stai,'Subj','Before',1);
isBadSubj = ismember(stai.Subj,answerBadSubjs);
stai(isBadSubj,:) = [];
stai(:,1) = [];


%% SIAS

opts = spreadsheetImportOptions("NumVariables", 4);
opts.Sheet = "EXP";
opts.DataRange = "P2";
opts.VariableNames = "SIAS";
opts.VariableTypes = "double";
SIAS = readtable("C:\Users\test_Admin\Desktop\EXP Giver Receiver\dati\FOGLIO_LAB_DEF.xlsx", opts, "UseExcel", false);
clear opts

% del bad subjs
SIAS.Subj = [1:size(SIAS,1)]';
SIAS = movevars(SIAS,'Subj','Before',1);
isBadSubj = ismember(SIAS.Subj,answerBadSubjs);
SIAS(isBadSubj,:) = [];
SIAS(:,1) = [];


%% STQ

opts = spreadsheetImportOptions("NumVariables", 4);
opts.Sheet = "EXP";
opts.DataRange = "Q2";
opts.VariableNames = "STQ";
opts.VariableTypes = "double";
STQ = readtable("C:\Users\test_Admin\Desktop\EXP Giver Receiver\dati\FOGLIO_LAB_DEF.xlsx", opts, "UseExcel", false);
clear opts

% del bad subjs
STQ.Subj = [1:size(STQ,1)]';
STQ = movevars(STQ,'Subj','Before',1);
isBadSubj = ismember(STQ.Subj,answerBadSubjs);
STQ(isBadSubj,:) = [];
STQ(:,1) = [];



%% DAS

% import
opts = spreadsheetImportOptions("NumVariables", 5);
opts.Sheet = "EXP";
opts.DataRange = "J:N";
opts.VariableNames = ["Consensus", "Aff_expr", "Satisfaction", "Cohesion" "Total"];
opts.VariableTypes = ["double", "double", "double", "double" "double"];
DAS = readtable("C:\Users\test_Admin\Desktop\EXP Giver Receiver\dati\FOGLIO_LAB_DEF.xlsx", opts, "UseExcel", false);
clear opts

% delete first row (not read as variables)
DAS(1,:) = [];

% del bad subjs
DAS.Subj = [1:size(DAS,1)]';
DAS = movevars(DAS,'Subj','Before',1);
isBadSubj = ismember(DAS.Subj,answerBadSubjs);
DAS(isBadSubj,:) = [];
DAS(:,1) = [];




%% ///////////// Plots coppia per coppia ///////////////////////////

if answerPlotCouples == 1


% EDA_Mean

nSubjs = size(unique(Measures.Subj),1);

% Means
y1 = [];

for s = 1:nSubjs
    yy = nanmean(Measures.EDA_Mean(Measures.Subj == s & ...
        Measures.Other == 'Stranger' & Measures.Sguardo == 'Cross'));
    y1= [y1; yy];
end

y2 = [];

for s = 1:nSubjs
    yy = nanmean(Measures.EDA_Mean(Measures.Subj == s & ...
        Measures.Other == 'Stranger' & Measures.Sguardo == 'Eye'));
    y2= [y2; yy];
end

y3 = [];

for s = 1:nSubjs
    yy = nanmean(Measures.EDA_Mean(Measures.Subj == s & ...
        Measures.Other == 'Partner' & Measures.Sguardo == 'Cross'));
    y3= [y3; yy];
end


y4 = [];

for s = 1:nSubjs
    yy = nanmean(Measures.EDA_Mean(Measures.Subj == s & ...
        Measures.Other == 'Partner' & Measures.Sguardo == 'Eye'));
    y4= [y4; yy];
end


yEDA = [y1 y2 y3 y4];
    




% errors
y1err = [];

for s = 1:nSubjs
    yyerr = sterr(Measures.EDA_Mean(Measures.Subj == s & ...
        Measures.Other == 'Stranger' & Measures.Sguardo == 'Cross'));
    y1err= [y1err; yyerr];
end

y2err = [];

for s = 1:nSubjs
    yyerr = sterr(Measures.EDA_Mean(Measures.Subj == s & ...
        Measures.Other == 'Stranger' & Measures.Sguardo == 'Eye'));
    y2err= [y2err; yyerr];
end

y3err = [];

for s = 1:nSubjs
    yyerr = sterr(Measures.EDA_Mean(Measures.Subj == s & ...
        Measures.Other == 'Partner' & Measures.Sguardo == 'Cross'));
    y3err= [y3err; yyerr];
end


y4err = [];

for s = 1:nSubjs
    yyerr = sterr(Measures.EDA_Mean(Measures.Subj == s & ...
        Measures.Other == 'Partner' & Measures.Sguardo == 'Eye'));
    y4err= [y4err; yyerr];
end


yerrEDA = [y1err y2err y3err y4err];



% VAS

nSubjs = size(unique(Measures.Subj),1);

% Means
y1 = [];

for s = 1:nSubjs
    yy = nanmean(Measures.VAS(Measures.Subj == s & ...
        Measures.Other == 'Stranger' & Measures.Sguardo == 'Cross'));
    y1= [y1; yy];
end

y2 = [];

for s = 1:nSubjs
    yy = nanmean(Measures.VAS(Measures.Subj == s & ...
        Measures.Other == 'Stranger' & Measures.Sguardo == 'Eye'));
    y2= [y2; yy];
end

y3 = [];

for s = 1:nSubjs
    yy = nanmean(Measures.VAS(Measures.Subj == s & ...
        Measures.Other == 'Partner' & Measures.Sguardo == 'Cross'));
    y3= [y3; yy];
end


y4 = [];

for s = 1:nSubjs
    yy = nanmean(Measures.VAS(Measures.Subj == s & ...
        Measures.Other == 'Partner' & Measures.Sguardo == 'Eye'));
    y4= [y4; yy];
end


yVAS = [y1 y2 y3 y4];
    




% errors
y1err = [];

for s = 1:nSubjs
    yyerr = sterr(Measures.VAS(Measures.Subj == s & ...
        Measures.Other == 'Stranger' & Measures.Sguardo == 'Cross'));
    y1err= [y1err; yyerr];
end

y2err = [];

for s = 1:nSubjs
    yyerr = sterr(Measures.VAS(Measures.Subj == s & ...
        Measures.Other == 'Stranger' & Measures.Sguardo == 'Eye'));
    y2err= [y2err; yyerr];
end

y3err = [];

for s = 1:nSubjs
    yyerr = sterr(Measures.VAS(Measures.Subj == s & ...
        Measures.Other == 'Partner' & Measures.Sguardo == 'Cross'));
    y3err= [y3err; yyerr];
end


y4err = [];

for s = 1:nSubjs
    yyerr = sterr(Measures.VAS(Measures.Subj == s & ...
        Measures.Other == 'Partner' & Measures.Sguardo == 'Eye'));
    y4err= [y4err; yyerr];
end


yerrVAS = [y1err y2err y3err y4err];



% Plot

for i = 1:2:nSubjs-1
    fh = figure();

    
  % VAS 1
    subplot(2,2,1)
    yyy = yVAS(i,:);
    yyy = reshape(yyy,2,2)';
    yyyerr = yerrVAS(i,:);
    yyyerr = reshape(yyyerr,2,2)';
    b = bar(yyy,'grouped');
    
    hold on
        ngroups =2;
        nbars = 2;
        x = nan(nbars, ngroups);
        for j = 1:nbars
            x(j,:) = b(j).XEndPoints;
        end
        errorbar(x',yyy,yyyerr,'k','linestyle','none');
    hold off
    title("VAS " + string(unique(Measures.Gender(Measures.Subj == i))))
    xticklabels({'Stranger' 'Parnter'})
    legend({'Cross' 'Eye'})
 
    
    
  % VAS 2
    subplot(2,2,2)
    yyy = yVAS(i+1,:);
    yyy = reshape(yyy,2,2)';
    yyyerr = yerrVAS(i+1,:);
    yyyerr = reshape(yyyerr,2,2)';
    b = bar(yyy,'grouped');
    
    hold on
        ngroups =2;
        nbars = 2;
        x = nan(nbars, ngroups);
        for j = 1:nbars
            x(j,:) = b(j).XEndPoints;
        end
        errorbar(x',yyy,yyyerr,'k','linestyle','none');
    hold off
    title("VAS " + string(unique(Measures.Gender(Measures.Subj == i+1))))
    xticklabels({'Stranger' 'Parnter'})
    legend({'Cross' 'Eye'})    
    
    
    
    
  % EDA_Mean 1
    subplot(2,2,3)
    yyy = yEDA(i,:);
    yyy = reshape(yyy,2,2)';
    yyyerr = yerrEDA(i,:);
    yyyerr = reshape(yyyerr,2,2)';
    b = bar(yyy,'grouped');
    
    hold on
        ngroups =2;
        nbars = 2;
        x = nan(nbars, ngroups);
        for j = 1:nbars
            x(j,:) = b(j).XEndPoints;
        end
        errorbar(x',yyy,yyyerr,'k','linestyle','none');
    hold off
    title("EDA " + string(unique(Measures.Gender(Measures.Subj == i))))
    xticklabels({'Stranger' 'Parnter'})
    legend({'Cross' 'Eye'})
 
    
    
  % EDA_Mean 2
    subplot(2,2,4)
    yyy = yEDA(i+1,:);
    yyy = reshape(yyy,2,2)';
    yyyerr = yerrEDA(i+1,:);
    yyyerr = reshape(yyyerr,2,2)';
    b = bar(yyy,'grouped');
    
    hold on
        ngroups =2;
        nbars = 2;
        x = nan(nbars, ngroups);
        for j = 1:nbars
            x(j,:) = b(j).XEndPoints;
        end
        errorbar(x',yyy,yyyerr,'k','linestyle','none');
    hold off
    title("EDA " + string(unique(Measures.Gender(Measures.Subj == i+1))))
    xticklabels({'Stranger' 'Parnter'})
    legend({'Cross' 'Eye'})  
    
    
    
    
    
sgtitle(['Coppia ' num2str((i+1)/2)])
    
if answerSaveCouples == 1
fh.WindowState = 'maximized';
saveas(gcf,['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Plots\Coppie_EDA_VAS\Coppia ' num2str((i+1)/2) '.png'])
close
end

end

else
end




%% \\\\\\\\\\\\\\\\\\\\\\\ RESPIRATION \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


if answerRSP == 1 

RSP = readtable('C:\Users\DalMonte\Desktop\EXP Giver Receiver\dati\RSP_Clean.xlsx');

RSP.Gender = categorical(RSP.Gender);
RSP.Other = categorical(RSP.Other);
RSP.Sguardo = categorical(RSP.Sguardo);


%% Subjects means


groups_RSP = table(RSP.Subj, RSP.Other, RSP.Sguardo, RSP.Gender);

[G_RSP, GID_RSP] = findgroups(groups);

GID_RSP.Properties.VariableNames = {'Sogg' 'Other' 'Sguardo' 'Gender'};


for i = 6:size(RSP.Properties.VariableNames,2)
    
    soggCondMeans_RSP = splitapply(@nanmean,RSP(:,i),G);
    
    z = table(soggCondMeans_RSP, 'variablenames', {num2str(rand(1,1))} );
    
    GID_RSP = [GID_RSP z];
    
end


GID_RSP.Properties.VariableNames(5:8) = RSP.Properties.VariableNames(6:9);

subjMeans_RSP = GID_RSP; clear GID_RSP

p = subjMeans_RSP.BreathVolVar(subjMeans_RSP.Other == 'Partner');
s = subjMeans_RSP.BreathVolVar(subjMeans_RSP.Other == 'Stranger');

[test,t] = ttest2(p,s)

mean(p)

mean(s)

end















    
