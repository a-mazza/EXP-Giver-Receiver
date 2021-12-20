% Also valid for HRV and RSP

clc
clear
close all


prompt = {'Write Measure:'};
dlgtitle = 'Choose measure to analyze';
dims = [1 55];
definput = {'xxxxxxxx'};
answer = inputdlg(prompt,dlgtitle,dims,definput);
answer = answer{1};


% import
load Physio_WholeBlock.mat

% Import genders here

opts = spreadsheetImportOptions("NumVariables", 1);

opts.Sheet = "EXP";
opts.DataRange = "E1";
opts.VariableNames = "SEX";
opts.VariableTypes = "categorical";
opts = setvaropts(opts, "SEX", "EmptyFieldRule", "auto");
Genders = readtable("C:\Users\DalMonte\Desktop\EXP Giver Receiver\dati\FOGLIO_LAB_DEF.xlsx", opts, "UseExcel", false);
clear opts
Genders(1,:) = [];

Genders = repelem(Genders.SEX,2);


% define Gender
Measures.Gender = Genders;

Measures = movevars(Measures,'Gender','before','BPM');

Measures.Other = categorical(Measures.Other);
Measures.Gender = categorical(Measures.Gender);
  

%% Means by conditions 4 plots

subjMeans = Measures;

subjMeans(subjMeans.Subj == 27 | subjMeans.Subj == 28 | subjMeans.Subj == 35,:) = [];

G = findgroups(subjMeans.Gender, subjMeans.Other);

allMeans = [];

for i = 4:size(subjMeans.Properties.VariableNames,2)
    
    CondMeans = splitapply(@nanmean,subjMeans(:,i),G);
    
    z = table(CondMeans, 'variablenames', {num2str(rand(1,1))} );
    
    allMeans = [allMeans z];
    
end

allMeans.Properties.VariableNames = subjMeans.Properties.VariableNames(4:end);


allMeans.Properties.RowNames = {'Female_Partner' 'Female_Stranger' 'Male_Partner' 'Male_Stranger'};

% errors

errs = [];

for i = 4:size(subjMeans.Properties.VariableNames,2)
    
    meanErr = splitapply(@sterr,subjMeans(:,i),G);
    
    z = table(meanErr, 'variablenames', {num2str(rand(1,1))} );
    
    errs = [errs z];
    
end

errs.Properties.VariableNames = allMeans.Properties.VariableNames;
errs.Properties.RowNames = allMeans.Properties.RowNames;


%% ________________ Stats

% Create table for analysis (1 table for each measure)

a = table(subjMeans.Subj, subjMeans.(answer), subjMeans.Other, 'variablenames', {'Subj' 'Measure' 'Other'});

Table = [];

subjsN = unique(subjMeans.Subj);

for i = 1:length(subjsN)
    z = a.Measure(a.Subj == subjsN(i) & a.Other == 'S');
    z = [z; a.Measure(a.Subj == subjsN(i) & a.Other == 'P')]; 
    Table(i,:) = z;
end

Table = array2table(Table);
Table.Gender = subjMeans.Gender(1:2:end);
Table.Properties.VariableNames = {'Stranger' 'Partner' 'Gender'};
Table = movevars(Table,'Gender', 'before',1);

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Stranger' 'Partner'}');

withintab = table(Other,'variablenames',{'Other'});

Table.Gender = double(Table.Gender);

rm = fitrm(Table,'Stranger-Partner ~ Gender','withindesign',withintab);

ANOVA_Measure = ranova(rm,'withinmodel','Other');

%writetable(ANOVA_Measure, 'C:\Users\test_Admin\Desktop\EXP Giver Receiver\Stats\ANOVA_Measure_WholeBlock.xlsx','WriteRowNames',true);


%% Plots
i = find(string(allMeans.Properties.VariableNames) == answer);
    
    y = table2array(allMeans(:,i));
    y = reshape(y,2,2)';
    y = circshift(y,1);
    yerr = table2array(errs(:,i));
    yerr = reshape(yerr,2,2)';  
    yerr = circshift(yerr,1);
    
    figure    
    %b = bar(y, 'grouped');
    
    %hold on
    
%     [ngroups,nbars] = size(yerr);
% 
%     x = nan(nbars, ngroups);
%     for j = 1:nbars
%         x(j,:) = b(j).XEndPoints;
%     end
    % Plot the errorbars
    errorbar(y(:,1),yerr(:,1),'k');
    hold on
    errorbar(y(:,2),yerr(:,2),'r');
    
    hold off
    xlim([0.5 2.5])

    xticks([1 2]);
    
    title(allMeans.Properties.VariableNames(i))
    
    xlabel('Gender')
    xticklabels({'Male' 'Female'})
    legend({'Partner' 'Stranger'})
    


%save Stats_WholeBlock
