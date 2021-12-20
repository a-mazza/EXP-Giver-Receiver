% Only valid for EDA
% stats including GENDER as factor

% !!! Remember: 
%      - in Measures, TrialN is the trial to analyze
%      - in Baseline, TrialN is the trial from which the baseline has been taken
%       (i.e. the ITI, last 5 seconds of that trial). 
%        Thus the values of trial i are the baseline for trial i+1. 
%        Trial 1 in Measures has no baseline; Trial 1 in Baseline is the
%        baseline for Trial 2 in Measures, and so on

% Thus, IGNORE OTHER AND SGUARDO in Baseline. The real condition is given
% by Other and Sguardo in Measures

clc
clear
close all

%% Choose how many secs to keep 
% verify the interval exists in folder - If not, use 'G_R_Physio_N_sec.m' to create it

startSecs = 0;%  <---------------------------------------------- Change here sec start
endSecs = 36;%  <---------------------------------------------- Change here sec end




% import
load Physio_Baseline.mat
Baseline = Measures;
clear Measures

load(['Physio_' num2str(startSecs) '_to_' num2str(endSecs) '.mat']);



% Add gender
Genders = categorical(...
          {'F'...
           'M'...
           'F'...
           'M'...
           'M'...
           'F'...
           'F'...
           'M'...
           'M'...
           'F'...
           'M'...
           'F'...
           'F'...
           'M'}');

% in Measures
Measures.Gender = zeros(size(Measures,1),1);
Measures = movevars(Measures,'Gender','before','EDA_Mean');
Measures.Gender = categorical(Measures.Gender);

Measures.Gender(Measures.Subj == 1) = Genders(1);
Measures.Gender(Measures.Subj == 2) = Genders(2);
Measures.Gender(Measures.Subj == 3) = Genders(3);
Measures.Gender(Measures.Subj == 4) = Genders(4);
Measures.Gender(Measures.Subj == 5) = Genders(5);
Measures.Gender(Measures.Subj == 6) = Genders(6);
Measures.Gender(Measures.Subj == 7) = Genders(7);
Measures.Gender(Measures.Subj == 8) = Genders(8);
Measures.Gender(Measures.Subj == 9) = Genders(9);
Measures.Gender(Measures.Subj == 10) = Genders(10);
Measures.Gender(Measures.Subj == 11) = Genders(11);
Measures.Gender(Measures.Subj == 12) = Genders(12);
Measures.Gender(Measures.Subj == 13) = Genders(13);
Measures.Gender(Measures.Subj == 14) = Genders(14);


% in Baseline
Baseline.Gender = zeros(size(Baseline,1),1);
Baseline = movevars(Baseline,'Gender','before','EDA_Mean');
Baseline.Gender = categorical(Baseline.Gender);

Baseline.Gender(Baseline.Subj == 1) = Genders(1);
Baseline.Gender(Baseline.Subj == 2) = Genders(2);
Baseline.Gender(Baseline.Subj == 3) = Genders(3);
Baseline.Gender(Baseline.Subj == 4) = Genders(4);
Baseline.Gender(Baseline.Subj == 5) = Genders(5);
Baseline.Gender(Baseline.Subj == 6) = Genders(6);
Baseline.Gender(Baseline.Subj == 7) = Genders(7);
Baseline.Gender(Baseline.Subj == 8) = Genders(8);
Baseline.Gender(Baseline.Subj == 9) = Genders(9);
Baseline.Gender(Baseline.Subj == 10) = Genders(10);
Baseline.Gender(Baseline.Subj == 11) = Genders(11);
Baseline.Gender(Baseline.Subj == 12) = Genders(12);
Baseline.Gender(Baseline.Subj == 13) = Genders(13);
Baseline.Gender(Baseline.Subj == 14) = Genders(14);


%% first trial in Measures - because it has no baseline

% Match TrialN. IGNORE OTHER AND SGUARDO IN BASELINE!
% The actual condition is given by other and sguardo in Measures
Baseline.TrialN = Baseline.TrialN+1;

if iscell(Measures.TrialN)
Measures.TrialN = cellfun(@str2double, Measures.TrialN);
end
Measures(Measures.TrialN == 1,:) = [];

%% Subtract Baseline from Measures
z = table2array(Measures(:,6:end-1)) - table2array(Baseline(:,6:end));
Measures(:,6:end-1) = array2table(z);

clear z

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



%% ________________ Stats

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

writetable(ANOVA_EDA_Mean, ['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Stats\ANOVA_EDA_Mean_' num2str(startSecs) '_to_' num2str(endSecs) '_Gender_Baseline.xlsx'],'WriteRowNames',true);



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

writetable(ANOVA_PeakNumber, ['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Stats\ANOVA_PeakNumber_' num2str(startSecs) '_to_' num2str(endSecs) '_Gender_Baseline.xlsx'],'WriteRowNames',true);



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

writetable(ANOVA_MeanPeakAmplitude, ['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Stats\ANOVA_MeanPeakAmplitude_' num2str(startSecs) '_to_' num2str(endSecs) '_Gender_Baseline.xlsx'],'WriteRowNames',true);



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

writetable(ANOVA_MeanPeakProminence, ['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Stats\ANOVA_MeanPeakProminence_' num2str(startSecs) '_to_' num2str(endSecs) '_Gender_Baseline.xlsx'],'WriteRowNames',true);



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

writetable(ANOVA_MeanPeakWidth, ['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Stats\ANOVA_MeanPeakWidth_' num2str(startSecs) '_to_' num2str(endSecs) '_Gender_Baseline.xlsx'],'WriteRowNames',true);


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

writetable(ANOVA_AreaUnderTheCurve, ['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Stats\ANOVA_AreaUnderTheCurve_' num2str(startSecs) '_to_' num2str(endSecs) '_Gender_Baseline.xlsx'],'WriteRowNames',true);


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



%% ______Plots


for i = 1:size(allMeans,2)
    
    y = table2array(allMeans(:,i));
    y = reshape(y,4,2)';
    yerr = table2array(errs(:,i));
    yerr = reshape(yerr,4,2)';    
    
    figure    
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
    
end



%% _________explore VAS correlations (find and replace measures here)

%% VAS and AreaUnderTheCurve

figure
tiledlayout(2,2)

% PartnerCross
nexttile

mdlCross = fitlm(VAS.PartnerCross, AreaUnderTheCurve.PartnerCross);

scatter(VAS.PartnerCross, AreaUnderTheCurve.PartnerCross, 'b','filled')
hold on

plot(mdlCross)
title(['PartnerCross AreaUnderTheCurve - VAS correlation. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)])
xlabel('VAS')
ylabel('AreaUnderTheCurve')
legend off

hold off



% PartnerEye
nexttile

mdlCross = fitlm(VAS.PartnerEye, AreaUnderTheCurve.PartnerEye);

scatter(VAS.PartnerEye, AreaUnderTheCurve.PartnerEye, 'b','filled')
hold on

plot(mdlCross)
title(['PartnerEye AreaUnderTheCurve - VAS correlation. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)])
xlabel('VAS')
ylabel('AreaUnderTheCurve')
legend off

hold off




% StrangerCross
nexttile

mdlCross = fitlm(VAS.StrangerCross, AreaUnderTheCurve.StrangerCross);

scatter(VAS.StrangerCross, AreaUnderTheCurve.StrangerCross, 'b','filled')
hold on

plot(mdlCross)
title(['StrangerCross AreaUnderTheCurve - VAS correlation. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)])
xlabel('VAS')
ylabel('AreaUnderTheCurve')
legend off

hold off




% StrangerEye
nexttile

mdlCross = fitlm(VAS.StrangerEye, AreaUnderTheCurve.StrangerEye);

scatter(VAS.StrangerEye, AreaUnderTheCurve.StrangerEye, 'b','filled')
hold on

plot(mdlCross)
title(['StrangerEye AreaUnderTheCurve - VAS correlation. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)])
xlabel('VAS')
ylabel('AreaUnderTheCurve')
legend off

hold off





%% VAS Cross vs VAS eye
% c'è correlazione tra le VAS di partner e sconosciuto solo se si considera quando
% i soggetti guardano la croce (cioè, un sogg è più propenso a dare punteggi alti, sia allo sconosciuto che al partner).
% Ma la correlazione sparisce quando guardano negli occhi: Il guardare negli occhi 
% ha un effetto sulla predisposizione a dare punteggi alti

mdlCross = fitlm(VAS.PartnerCross, VAS.StrangerCross);
mdlEye = fitlm(VAS.PartnerEye, VAS.StrangerEye);

figure

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

saveas(gcf,'C:\Users\test_Admin\Desktop\EXP Giver Receiver\Plots per Monia\VAS_Corr','epsc')
saveas(gcf,'C:\Users\test_Admin\Desktop\EXP Giver Receiver\Plots per Monia\VAS_Corr.jpg')





save StatsNs_Gender_BaselineCorrect



%% ________ plot each subject separately (explorative)


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

title('EDA_Mean')
xlabel('Subjects')
xticklabels((1:nSubjs))
legend({'Stranger Cross' 'Stranger Eye' 'Partner Cross' 'Parnter Eye'})






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
