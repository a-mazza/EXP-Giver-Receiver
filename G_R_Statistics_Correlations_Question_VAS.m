% Correlazione VAS con questionari

clc
clear 
close all

%% Choose measure
ChosenMeasure = 'STQ'; % <---------- Choose here questionario
%                                   DAS
%                                   SIAS
%                                   STQ
%                                   STAI_TRATTO
%                                   STAI_STATO

delSogg = 13;% <---------- Choose here soggetti da eliminare

%% Import questionnaire

opts = spreadsheetImportOptions("NumVariables", 21);
opts.Sheet = "EXP";
opts.DataRange = "A1:U15";
opts.VariableNames = ["Var1", "SOGGETTO", "Var3", "Var4", "SEX", "Var6", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13", "DAS", "Var15", "SIAS", "STQ", "STAI_TRATTO", "STAI_STATO", "STAI_STATO_P", "STAI_STATO_S"];
    if ChosenMeasure == "STAI_STATO"
        opts.SelectedVariableNames = ["SOGGETTO", "SEX", "STAI_STATO" "STAI_STATO_P" "STAI_STATO_S"];
    else
        opts.SelectedVariableNames = ["SOGGETTO", "SEX", ChosenMeasure];
    end
opts.VariableTypes = ["char", "double", "char", "char", "categorical", "char", "char", "char", "char", "char", "char", "char", "char", "double", "double", "double", "double", "double", "double", "double", "double"];
opts = setvaropts(opts, ["Var1", "Var3", "Var4", "Var6", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var1", "Var3", "Var4", "SEX", "Var6", "Var7", "Var8", "Var9", "Var10", "Var11", "Var12", "Var13"], "EmptyFieldRule", "auto");

questionnaire = readtable("C:\Users\test_Admin\Desktop\EXP Giver Receiver\dati\FOGLIO_LAB_DEF.xlsx", opts, "UseExcel", false);

clear opts

questionnaire(1,:) = [];

%% Import other measures

load Stats60s_Gender.mat



Quest_VAS = [questionnaire VAS];
Quest_VAS.Gender = [];


%% Normalize

norm = table2array(Quest_VAS(:,4:7));


norm = (norm-min(norm,[],2)) ./ (max(norm,[],2) - min(norm,[],2));


Quest_VAS(:,4:7) = array2table(norm);


% create variables 4 correlations

Quest_VAS.Stranger = (Quest_VAS.StrangerCross + Quest_VAS.StrangerEye)./2;
Quest_VAS.Partner = (Quest_VAS.PartnerCross + Quest_VAS.PartnerEye)./2;



%% Delete subjects

Quest_VAS(Quest_VAS.SOGGETTO == delSogg,:) = [];

%% plot

figure

tiledlayout(1,2)

nexttile

scatter(Quest_VAS.(3), Quest_VAS.Partner,'filled','b')

mdlCross = fitlm(Quest_VAS.(3), Quest_VAS.Partner);

hold on

plot(mdlCross)
title([ChosenMeasure ' Partner. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)])
xlabel(ChosenMeasure)
ylabel('VAS')
legend off

hold off


nexttile

scatter(Quest_VAS.(3), Quest_VAS.Stranger,'filled','r')

mdlCross = fitlm(Quest_VAS.(3), Quest_VAS.Stranger);

hold on

plot(mdlCross)
title([ChosenMeasure ' Stranger. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)])
xlabel(ChosenMeasure)
ylabel('VAS')
legend off

sgtitle('Correlations')

hold off










