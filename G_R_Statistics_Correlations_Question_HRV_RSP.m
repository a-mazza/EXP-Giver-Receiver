% Correlazione Physio con questionari (HRV e RSP in Whole Block stats)
% Correlazione VAS con questionari
clc
close all
clear

%% Choose period time to analyze

% Start Loop over everything

questMeasures = {'DAS' 'SIAS' 'STQ' 'STAI_TRATTO' 'STAI_STATO'};
Physios = {'BPM' 'IBI' 'SDNN' 'RMSSD' 'pNN50' 'RPM' 'Depth' 'Width'};


for q = 1:length(questMeasures)
    for p = 1:length(Physios)
    
clearvars -except q p time_period questMeasures Physios 

    %% Choose measure
    ChosenMeasure = questMeasures(q); % <---------- Choose here questionario
    %                                   DAS
    %                                   SIAS
    %                                   STQ
    %                                   STAI_TRATTO
    %                                   STAI_STATO

    ChosenPhysio = Physios(p); % <------ choose the measures you want
    %                                   BPM
    %                                   IBI
    %                                   SDNN
    %                                   RMSSD
    %                                   pNN50
    %                                   RPM
    %                                   Depth
    %                                   Width

    delSogg = 999;% <---------- Choose here soggetti da eliminare
    %                               no delete: input = 999

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

    load Stats_WholeBlock.mat
    Quest_Physio = [questionnaire eval(ChosenPhysio{1})];
    Quest_Physio.Gender = [];
    isna = isnan(table2array(Quest_Physio(:,3:5)));
    isna = isna(:,1) | isna(:,2) | isna(:,3);
    Quest_Physio(find(isna),:) = [];

        if ChosenMeasure == "STAI_STATO"
            Quest_Physio.Delta_S = Quest_Physio.STAI_STATO_S - Quest_Physio.STAI_STATO;
            Quest_Physio.Delta_P = Quest_Physio.STAI_STATO_P - Quest_Physio.STAI_STATO;
        else
        end



    %% Delete subjects

    Quest_Physio(Quest_Physio.SOGGETTO == delSogg,:) = [];

%     %% Separate genders
% 
%     Quest_F = Quest_Physio(Quest_Physio.SEX == 'F',:);
%     Quest_M = Quest_Physio(Quest_Physio.SEX == 'M',:);



    %% plot PARTNER vs STRANGER

    if ChosenMeasure  ~= "STAI_STATO"

    figure

    tiledlayout(1,2)

    nexttile

    scatter(Quest_Physio.(3), Quest_Physio.Partner,'filled','b')

    mdlCross = fitlm(Quest_Physio.(3), Quest_Physio.Partner);

    hold on

    plot(mdlCross)
    title([ChosenMeasure ' Partner. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)])
    xlabel(ChosenMeasure)
    ylabel(ChosenPhysio)
    legend off

    hold off


    nexttile

    scatter(Quest_Physio.(3), Quest_Physio.Stranger,'filled','r')

    mdlCross = fitlm(Quest_Physio.(3), Quest_Physio.Stranger);

    hold on

    plot(mdlCross)
    title([ChosenMeasure ' Stranger. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)])
    xlabel(ChosenMeasure)
    ylabel(ChosenPhysio)
    legend off

    sgtitle('Correlations')

    hold off


    else

    % Plot STAI raw (no correlations)
    figure
    tiledlayout(1,2)
    nexttile
    y = [mean(Quest_Physio.STAI_STATO_P) mean(Quest_Physio.STAI_STATO_S)];
    yerr = [sterr(Quest_Physio.STAI_STATO_P) sterr(Quest_Physio.STAI_STATO_S)];
    bar(y)
    hold on
    errorbar(y,yerr,'k','linestyle','none')
    hold off
    title('STAI STATO Raw')
    xlabel('Other')
    xticklabels({'Partner' 'Stranger'})

    % Plot STAI delta (no correlations)
    nexttile
    y = [mean(Quest_Physio.Delta_P) mean(Quest_Physio.Delta_S)];
    yerr = [sterr(Quest_Physio.Delta_P) sterr(Quest_Physio.Delta_S)];
    bar(y)
    hold on
    errorbar(y,yerr,'k','linestyle','none')
    hold off
    title('STAI STATO Delta')
    xlabel('Other')
    xticklabels({'Partner' 'Stranger'})
    sgtitle('STAI STATO')


    % Plot STAI Correlations Raw

    figure

    tiledlayout(1,2)

    nexttile

    scatter(Quest_Physio.STAI_STATO_P, Quest_Physio.Partner,'filled','b')

    mdlCross = fitlm(Quest_Physio.STAI_STATO_P, Quest_Physio.Partner);

    hold on

    plot(mdlCross)
    title(['Partner. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)])
    xlabel('STAI STATO Raw')
    ylabel(ChosenPhysio)
    legend off

    hold off


    nexttile

    scatter(Quest_Physio.STAI_STATO_S, Quest_Physio.Stranger,'filled','b')

    mdlCross = fitlm(Quest_Physio.STAI_STATO_S, Quest_Physio.Stranger);

    hold on

    plot(mdlCross)
    title(['Stranger. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)])
    xlabel('STAI STATO Raw')
    ylabel(ChosenPhysio)
    legend off

    sgtitle('STAI STATO Raw')



    % Plot STAI Correlations Delta

    figure

    tiledlayout(1,2)

    nexttile

    scatter(Quest_Physio.Delta_P, Quest_Physio.Partner,'filled','b')

    mdlCross = fitlm(Quest_Physio.Delta_P, Quest_Physio.Partner);

    hold on

    plot(mdlCross)
    title(['Partner. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)])
    xlabel('STAI STATO Delta')
    ylabel(ChosenPhysio)
    legend off

    hold off


    nexttile

    scatter(Quest_Physio.Delta_S, Quest_Physio.Stranger,'filled','b')

    mdlCross = fitlm(Quest_Physio.Delta_S, Quest_Physio.Stranger);

    hold on

    plot(mdlCross)
    title(['Stranger. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)])
    xlabel('STAI STATO Delta')
    ylabel(ChosenPhysio)
    legend off

    sgtitle('STAI STATO Delta')


    end
    
    
    end
end
