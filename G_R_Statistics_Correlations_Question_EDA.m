% Correlazione VAS con questionari
clc
close all
clear

%% Choose period time to analyze

time_period = 'Stats_0_to_36_Gender.mat';

% Start Loop over everything

questMeasures = {'DAS' 'SIAS' 'STQ' 'STAI_TRATTO' 'STAI_STATO'};
Physios = {'EDA_Mean' 'AreaUnderTheCurve' 'PeakNumber' 'MeanPeakAmplitude' 'MeanPeakProminence' 'MeanPeakWidth'};


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
    %                                   EDA_Mean
    %                                   AreaUnderTheCurve
    %                                   PeakNumber
    %                                   MeanPeakAmplitude
    %                                   MeanPeakProminence
    %                                   MeanPeakWidth

    delSogg = 999;% <---------- Choose here soggetti da eliminare
    %                               no delete: inpuit = 999

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

    load(time_period)

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


    %% Normalize

    % norm = table2array(Quest_Physio(:,4:7));
    % 
    % 
    % norm = (norm-min(norm,[],2)) ./ (max(norm,[],2) - min(norm,[],2));
    % 
    % 
    % Quest_Physio(:,4:7) = array2table(norm);


    % create variables 4 correlations

    Quest_Physio.Stranger = (Quest_Physio.StrangerCross + Quest_Physio.StrangerEye)./2;
    Quest_Physio.Partner = (Quest_Physio.PartnerCross + Quest_Physio.PartnerEye)./2;

    Quest_Physio.Eye = (Quest_Physio.StrangerEye + Quest_Physio.PartnerEye)./2;
    Quest_Physio.Cross = (Quest_Physio.PartnerCross + Quest_Physio.StrangerCross)./2;


    %% Delete subjects

    Quest_Physio(Quest_Physio.SOGGETTO == delSogg,:) = [];

%     %% Separate genders
% 
%     Quest_F = Quest_Physio(Quest_Physio.SEX == 'F',:);
%     Quest_M = Quest_Physio(Quest_Physio.SEX == 'M',:);

    %% _________________________ Plots & Stats_________________________________


    %% ________ NOT stai stato

    if ChosenMeasure  ~= "STAI_STATO"


    %% Plot Main effects
    figure

    tiledlayout(2,2)

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
    hold off




    nexttile

    scatter(Quest_Physio.(3), Quest_Physio.Eye,'filled','b')
    mdlCross = fitlm(Quest_Physio.(3), Quest_Physio.Eye);

    hold on
    plot(mdlCross)
    title([ChosenMeasure ' Eye. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)])
    xlabel(ChosenMeasure)
    ylabel(ChosenPhysio)
    legend off
    hold off


    nexttile

    scatter(Quest_Physio.(3), Quest_Physio.Cross,'filled','r')
    mdlCross = fitlm(Quest_Physio.(3), Quest_Physio.Cross);

    hold on
    plot(mdlCross)
    title([ChosenMeasure ' Cross. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)])
    xlabel(ChosenMeasure)
    ylabel(ChosenPhysio)
    legend off
    hold off


    sgtitle('MAIN EFFECTS Correlations')



    %% Plot interactions

    figure

    tiledlayout(1,2)


    % Stranger
    nexttile

    scatter(Quest_Physio.(3), Quest_Physio.StrangerCross,'filled','r')
    hold on
    scatter(Quest_Physio.(3), Quest_Physio.StrangerEye,'filled','b')

    mdlCross = fitlm(Quest_Physio.(3), Quest_Physio.StrangerCross);
    h = plot(mdlCross);
    dataHandle = findobj(h,'DisplayName','Data');
    fitHandle = findobj(h,'DisplayName','Fit'); 
    cbHandles = findobj(h,'DisplayName','Confidence bounds');
    cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
    dataHandle.Color = 'r'; 
    fitHandle.Color = [1 0 0];
    set(cbHandles, 'Color', 'r', 'LineWidth', 1)

    mdlEye = fitlm(Quest_Physio.(3), Quest_Physio.StrangerEye);
    h = plot(mdlEye);
    dataHandle = findobj(h,'DisplayName','Data');
    fitHandle = findobj(h,'DisplayName','Fit'); 
    cbHandles = findobj(h,'DisplayName','Confidence bounds');
    cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
    dataHandle.Color = 'b'; 
    fitHandle.Color = [0 0 1]; 
    set(cbHandles, 'Color', 'b', 'LineWidth', 1)


    title('Stranger')
    xlabel(ChosenMeasure)
    ylabel(ChosenPhysio)
    legend({['Cross. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)],...
        ['Eye. p = ' num2str(mdlEye.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlEye.Rsquared.Ordinary)]})
    hold off




    % Partner
    nexttile

    scatter(Quest_Physio.(3), Quest_Physio.PartnerCross,'filled','r')
    hold on
    scatter(Quest_Physio.(3), Quest_Physio.PartnerEye,'filled','b')

    mdlCross = fitlm(Quest_Physio.(3), Quest_Physio.PartnerCross);
    h = plot(mdlCross);
    dataHandle = findobj(h,'DisplayName','Data');
    fitHandle = findobj(h,'DisplayName','Fit'); 
    cbHandles = findobj(h,'DisplayName','Confidence bounds');
    cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
    dataHandle.Color = 'r'; 
    fitHandle.Color = [1 0 0];
    set(cbHandles, 'Color', 'r', 'LineWidth', 1)

    mdlEye = fitlm(Quest_Physio.(3), Quest_Physio.PartnerEye);
    h = plot(mdlEye);
    dataHandle = findobj(h,'DisplayName','Data');
    fitHandle = findobj(h,'DisplayName','Fit'); 
    cbHandles = findobj(h,'DisplayName','Confidence bounds');
    cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
    dataHandle.Color = 'b'; 
    fitHandle.Color = [0 0 1]; 
    set(cbHandles, 'Color', 'b', 'LineWidth', 1)


    title('Partner')
    xlabel(ChosenMeasure)
    ylabel(ChosenPhysio)
    legend({['Cross. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)],...
        ['Eye. p = ' num2str(mdlEye.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlEye.Rsquared.Ordinary)]})
    hold off


    sgtitle(ChosenMeasure)




    %% ________ stai stato

    else

    %% Plot STAI raw (no correlations)
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

    %% Plot STAI delta (no correlations)
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


    %% Plot STAI Correlations Raw - PARTNER vs STRANGER

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



    %% Plot STAI Correlations Delta - PARTNER vs STRANGER

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







    %% Plot STAI Correlations Delta - Interaction


    figure

    tiledlayout(1,2)


    % Stranger
    nexttile

    scatter(Quest_Physio.STAI_STATO_S, Quest_Physio.StrangerCross,'filled','r')
    hold on
    scatter(Quest_Physio.STAI_STATO_S, Quest_Physio.StrangerEye,'filled','b')

    mdlCross = fitlm(Quest_Physio.STAI_STATO_S, Quest_Physio.StrangerCross);
    h = plot(mdlCross);
    dataHandle = findobj(h,'DisplayName','Data');
    fitHandle = findobj(h,'DisplayName','Fit'); 
    cbHandles = findobj(h,'DisplayName','Confidence bounds');
    cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
    dataHandle.Color = 'r'; 
    fitHandle.Color = [1 0 0];
    set(cbHandles, 'Color', 'r', 'LineWidth', 1)

    mdlEye = fitlm(Quest_Physio.STAI_STATO_S, Quest_Physio.StrangerEye);
    h = plot(mdlEye);
    dataHandle = findobj(h,'DisplayName','Data');
    fitHandle = findobj(h,'DisplayName','Fit'); 
    cbHandles = findobj(h,'DisplayName','Confidence bounds');
    cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
    dataHandle.Color = 'b'; 
    fitHandle.Color = [0 0 1]; 
    set(cbHandles, 'Color', 'b', 'LineWidth', 1)


    title('Stranger')
    xlabel(ChosenMeasure)
    ylabel(ChosenPhysio)
    legend({['Cross. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)],...
        ['Eye. p = ' num2str(mdlEye.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlEye.Rsquared.Ordinary)]})
    hold off




    % Partner
    nexttile

    scatter(Quest_Physio.STAI_STATO_P, Quest_Physio.PartnerCross,'filled','r')
    hold on
    scatter(Quest_Physio.STAI_STATO_P, Quest_Physio.PartnerEye,'filled','b')

    mdlCross = fitlm(Quest_Physio.STAI_STATO_P, Quest_Physio.PartnerCross);
    h = plot(mdlCross);
    dataHandle = findobj(h,'DisplayName','Data');
    fitHandle = findobj(h,'DisplayName','Fit'); 
    cbHandles = findobj(h,'DisplayName','Confidence bounds');
    cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
    dataHandle.Color = 'r'; 
    fitHandle.Color = [1 0 0];
    set(cbHandles, 'Color', 'r', 'LineWidth', 1)

    mdlEye = fitlm(Quest_Physio.STAI_STATO_P, Quest_Physio.PartnerEye);
    h = plot(mdlEye);
    dataHandle = findobj(h,'DisplayName','Data');
    fitHandle = findobj(h,'DisplayName','Fit'); 
    cbHandles = findobj(h,'DisplayName','Confidence bounds');
    cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
    dataHandle.Color = 'b'; 
    fitHandle.Color = [0 0 1]; 
    set(cbHandles, 'Color', 'b', 'LineWidth', 1)


    title('Partner')
    xlabel(ChosenMeasure)
    ylabel(ChosenPhysio)
    legend({['Cross. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)],...
        ['Eye. p = ' num2str(mdlEye.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlEye.Rsquared.Ordinary)]})
    hold off


    sgtitle([ChosenMeasure ' Raw'])





    %% Plot STAI Correlations Delta - Interaction


    figure

    tiledlayout(1,2)


    % Stranger
    nexttile

    scatter(Quest_Physio.Delta_S, Quest_Physio.StrangerCross,'filled','r')
    hold on
    scatter(Quest_Physio.Delta_S, Quest_Physio.StrangerEye,'filled','b')

    mdlCross = fitlm(Quest_Physio.Delta_S, Quest_Physio.StrangerCross);
    h = plot(mdlCross);
    dataHandle = findobj(h,'DisplayName','Data');
    fitHandle = findobj(h,'DisplayName','Fit'); 
    cbHandles = findobj(h,'DisplayName','Confidence bounds');
    cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
    dataHandle.Color = 'r'; 
    fitHandle.Color = [1 0 0];
    set(cbHandles, 'Color', 'r', 'LineWidth', 1)

    mdlEye = fitlm(Quest_Physio.Delta_S, Quest_Physio.StrangerEye);
    h = plot(mdlEye);
    dataHandle = findobj(h,'DisplayName','Data');
    fitHandle = findobj(h,'DisplayName','Fit'); 
    cbHandles = findobj(h,'DisplayName','Confidence bounds');
    cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
    dataHandle.Color = 'b'; 
    fitHandle.Color = [0 0 1]; 
    set(cbHandles, 'Color', 'b', 'LineWidth', 1)


    title('Stranger')
    xlabel(ChosenMeasure)
    ylabel(ChosenPhysio)
    legend({['Cross. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)],...
        ['Eye. p = ' num2str(mdlEye.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlEye.Rsquared.Ordinary)]})
    hold off




    % Partner
    nexttile

    scatter(Quest_Physio.Delta_P, Quest_Physio.PartnerCross,'filled','r')
    hold on
    scatter(Quest_Physio.Delta_P, Quest_Physio.PartnerEye,'filled','b')

    mdlCross = fitlm(Quest_Physio.Delta_P, Quest_Physio.PartnerCross);
    h = plot(mdlCross);
    dataHandle = findobj(h,'DisplayName','Data');
    fitHandle = findobj(h,'DisplayName','Fit'); 
    cbHandles = findobj(h,'DisplayName','Confidence bounds');
    cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
    dataHandle.Color = 'r'; 
    fitHandle.Color = [1 0 0];
    set(cbHandles, 'Color', 'r', 'LineWidth', 1)

    mdlEye = fitlm(Quest_Physio.Delta_P, Quest_Physio.PartnerEye);
    h = plot(mdlEye);
    dataHandle = findobj(h,'DisplayName','Data');
    fitHandle = findobj(h,'DisplayName','Fit'); 
    cbHandles = findobj(h,'DisplayName','Confidence bounds');
    cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
    dataHandle.Color = 'b'; 
    fitHandle.Color = [0 0 1]; 
    set(cbHandles, 'Color', 'b', 'LineWidth', 1)


    title('Partner')
    xlabel(ChosenMeasure)
    ylabel(ChosenPhysio)
    legend({['Cross. p = ' num2str(mdlCross.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlCross.Rsquared.Ordinary)],...
        ['Eye. p = ' num2str(mdlEye.Coefficients.pValue(2)) '; Rsq = ' num2str(mdlEye.Rsquared.Ordinary)]})
    hold off


    sgtitle([ChosenMeasure ' Delta'])



    end








    end
end

