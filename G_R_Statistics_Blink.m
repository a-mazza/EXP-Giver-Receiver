clc
clear
close all

%% DEFINE WHICH SUBJECTS ARE FEMALES (for later computation)
females = [1 3 6 7 10 12 13]; % <--------------------- update here!!

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

%% exclude subjects?

exclude = {'08'}; % subjNum to exclude



%% Import and clean
data = readtable('C:\Users\test_Admin\Desktop\EXP Giver Receiver\dati\BLINKING.xlsx');
data(:,[5 7 9:11]) = [];
data.SOGG = regexp(data.SOGG(contains(data.SOGG,'_')),'\d*','Match');
data.SOGG = cellfun(@categorical, data.SOGG);

data(isnan(data.N_BLINK),:)= [];
data(data.INVALID==1, :) = [];
data(data.COD==3 | data.COD==4, :) = [];

data.OTHER = string(data.OTHER);
data.COD = string(data.COD);

data.OTHER(data.OTHER=='0') = 'S';
data.OTHER(data.OTHER=='1') = 'P';

data.COD(data.COD=='1') = 'OCCHI';
data.COD(data.COD=='2') = 'CROCE';



%% Normalize each trial's blink number by condition over total blink number per subject

G = findgroups(data.SOGG);

soggBlinkTot = table(unique(data.SOGG), splitapply(@sum,data(:,5),G), 'VariableNames',...
    {'Sogg' 'N_BLINKtot'});

for i = 1:size(data,1)
data.N_BLINKtot(i) = soggBlinkTot.N_BLINKtot(soggBlinkTot.Sogg == data.SOGG(i));
end

data.N_BLINKnorm = data.N_BLINK./data.N_BLINKtot;



%% Means by subject

% exclude subjects (OCCHIO CHE POI SALVA PLOTS E STATS E LE SOVRASCRIVE)!!!!!!!!!!!!!!!!!!!


data(data.SOGG==exclude,:) = [];
isDeleted = cellfun(@str2double,regexp(exclude,'\d*','Match'));

Genders(isDeleted) = [];

groups = table(data.SOGG, data.OTHER, data.COD);

[G, GID] = findgroups(groups);

GID.Properties.VariableNames = {'SOGG' 'OTHER' 'COD'};

soggCondMeans = splitapply(@mean,data(:,8),G); % <----------- choose column!!!

subjMeans = GID; 
subjMeans.Blink = soggCondMeans;
clear GID


%% Means by conditions 4 plots (without gender)
% 
% groups = table(subjMeans.OTHER, subjMeans.COD);
% [G, GID] = findgroups(groups);
%     
% CondMeans = splitapply(@mean,subjMeans(:,4),G); % <---------- choose column!!!!!!
%     
% allMeans = table(CondMeans, 'rownames', {'Partner_Croce' 'Partner_Occhi' 'Stranger_Croce' 'Stranger_Occhi'} );
% 
% 
% % errors
% 
% errs = [];
%    
% meanErr = splitapply(@sterr,subjMeans(:,4),G);
% 
% meanErr = table(meanErr, 'rownames', {'Partner_Croce' 'Partner_Occhi' 'Stranger_Croce' 'Stranger_Occhi'} );


%% Add gender
subjMeans.SOGG = double(subjMeans.SOGG);

for i = 1:size(subjMeans,1)
    if ismember(subjMeans.SOGG(i), females)
        subjMeans.Gender(i) = 'F';
    else
        subjMeans.Gender(i) = 'M';
    end
end










%% means by condition&Gender for plot

groups = table(subjMeans.Gender, subjMeans.OTHER, subjMeans.COD);
[G, GID] = findgroups(groups);
    
CondMeansGender = splitapply(@mean,subjMeans(:,4),G);
    
allMeansGender = table(CondMeansGender, 'rownames', {'F_Partner_Croce' 'F_Partner_Occhi' 'F_Stranger_Croce' 'F_Stranger_Occhi' ...
    'M_Partner_Croce' 'M_Partner_Occhi' 'M_Stranger_Croce' 'M_Stranger_Occhi'} );


% errors


   
errs = splitapply(@sterr,subjMeans(:,4),G);

errs = table(errs, 'rownames', {'F_Partner_Croce' 'F_Partner_Occhi' 'F_Stranger_Croce' 'F_Stranger_Occhi' ...
    'M_Partner_Croce' 'M_Partner_Occhi' 'M_Stranger_Croce' 'M_Stranger_Occhi'} );



%% Plot with gender
 
y = table2array(allMeansGender(:,1));
y = reshape(y,4,2)';
yerr = table2array(errs(:,1));
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

title('Blink Proportion')

%ylim([0 0.1])

xlabel('Gender')
xticklabels({'Females' 'Males'})
legend({'Stranger Cross' 'Stranger Eye' 'Partner Cross' 'Partner Eye'})


%% stats

% Create table for analysis (1 table for each measure)

a = table(subjMeans.SOGG, subjMeans.Blink, 'variablenames', {'Subj' 'Blink'});

Blink = [];

subjsN = unique(subjMeans.SOGG);

for i = 1:length(subjsN)
    z = a.Blink(a.Subj == subjsN(i));
    z = z';
    Blink(i,:) = z;
end

Blink = array2table(Blink);
Blink.Properties.VariableNames = {'PartnerCross' 'PartnerEye' 'StrangerCross' 'StrangerEye'};
Blink.Gender = Genders;
Blink = movevars(Blink,'Gender','before','PartnerCross');

% Create a within model to be applied in fitrm in all measures

Other = categorical({'Partner' 'Partner' 'Stranger' 'Stranger'}');
Sguardo = categorical({'Cross' 'Eye' 'Cross' 'Eye'}');

withintab = table(Other, Sguardo,'variablenames',{'Other','Sguardo'});

rm = fitrm(Blink,'PartnerCross-StrangerEye ~Gender','withindesign',withintab);

ANOVA_Blink = ranova(rm,'withinmodel','Other*Sguardo');

writetable(ANOVA_Blink, ['C:\Users\test_Admin\Desktop\EXP Giver Receiver\Stats\ANOVA_Blink_Gender.xlsx'],'WriteRowNames',true);


%% Plot quasi significant stuff

% Sguardo
y = [mean(mean([Blink.PartnerCross Blink.StrangerCross])) mean(mean([Blink.PartnerEye Blink.StrangerEye]))];
yerr = [mean(sterr([Blink.PartnerCross Blink.StrangerCross])) mean(sterr([Blink.PartnerEye Blink.StrangerEye]))];    

figure    
b = bar(y);

hold on

errorbar(y,yerr,'k','linestyle','none');

hold off

title('Blink Proportion')

xlabel('Sguardo')
xticklabels({'Cross' 'Eye'})


%% Sguardo by Gender
Male = Blink(Blink.Gender=='M',:);
yMale = [mean(mean([Male.PartnerCross Male.StrangerCross])) mean(mean([Male.PartnerEye Male.StrangerEye]))];
yMaleErr = [mean(sterr([Male.PartnerCross Male.StrangerCross])) mean(sterr([Male.PartnerEye Male.StrangerEye]))];

Female = Blink(Blink.Gender=='F',:);
yFemale = [mean(mean([Female.PartnerCross Female.StrangerCross])) mean(mean([Female.PartnerEye Female.StrangerEye]))];
yFemaleErr = [mean(sterr([Female.PartnerCross Female.StrangerCross])) mean(sterr([Female.PartnerEye Female.StrangerEye]))];

y = [yFemale;yMale];

yerr = [yFemaleErr;yMaleErr];   

figure    
b = bar(y, 'grouped');
b(1,1).FaceColor = [0.1, 0.6, 1];
b(1,2).FaceColor = [0.9, 0.7, 0.1];


hold on

[ngroups,nbars] = size(yerr);

x = nan(nbars, ngroups);
    for j = 1:nbars
        x(j,:) = b(j).XEndPoints;
    end
% Plot the errorbars
errorbar(x',y,yerr,'k','linestyle','none');

hold off

title('Blink Proportion')

%ylim([0 0.1])

xlabel('Gender')
xticklabels({'Females' 'Males'})
legend({'Cross' 'Eye'})



