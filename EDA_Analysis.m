function EDA_Measures = EDA_Analysis(data,SR,epochs)

% Epochs = which 15 seconds to analyze (first, second, third or fourth)

%% Preprocess


% Set epochs to analyze
if nargin == 3
epBorders = [round(length(data)*1/4) round(length(data)*2/4) round(length(data)*3/4)];
    switch epochs
        case 1
            data = data(2*SR:epBorders(1)); % 2*SR allows cutting first 2 seconds of recording, preventing edge artifacts
        case 2
            data = data(epBorders(1):epBorders(2));
        case 3
            data = data(epBorders(2):epBorders(3));
        case 4
            data = data(epBorders(3):end-2*SR); % 2*SR allows cutting last 2 seconds of recording, preventing edge artifacts
        case 0
            data = data(2*SR:end-2*SR); % 0 if in scripts you predefine the epochs and you want the whole signal
    end
else
    %data = data(2*SR:end-2*SR); % 2*SR allows cutting first and last 2 seconds of recording, preventing edge artifacts
end


% Delete nans
itsnan = find(isnan(data));
data(itsnan,:) = [];

% shift positive
% figure
% plot(data)
% 
% data = detrend(data,1);
% 
% if min(data) < 0
%     data = (data + abs(min(data)));
% else
%     data = (data - abs(min(data)));
% end
% 
% 
% hold on
% 
% plot(data)
% legend({'raw', 'normDet'})
% hold off




%% Find peaks
tx =(0:size(data,1)-1)'*1/SR;

[pks, pLoc, w, pProm] = findpeaks(data, tx,'MinPeakProminence', 0.01,...
 'MinPeakDistance', 1);


% %Plot % UNCOMMENT TO PLOT PEAKS FOUND __________________________________
% figure
% plot(tx,data)
% hold on
% plot(pLoc,pks,'ro')
% x1 = tx(1);
% xend = tx(end);
% y1 = data(1);
% yend = data(end);
% pLoc2plot = [x1; pLoc; xend];
% pks2plot = [y1; pks; yend];
% plot(pLoc2plot,pks2plot,'r:')
% ylim([-0.2 0.5])
% hold off

% Get features
EDA_Measures.EDA_Mean = mean(data);
EDA_Measures.EDA_Mean(isnan(EDA_Measures.EDA_Mean)) = 0;

EDA_Measures.PeakNumber = length(pks);
EDA_Measures.PeakNumber(isnan(EDA_Measures.PeakNumber)) = 0;

EDA_Measures.MeanPeakAmplitude = mean(pks,'omitnan');
EDA_Measures.MeanPeakAmplitude(isnan(EDA_Measures.MeanPeakAmplitude)) = 0;

EDA_Measures.MeanPeakProminence = mean(pProm,'omitnan');
EDA_Measures.MeanPeakProminence(isnan(EDA_Measures.MeanPeakProminence)) = 0;

EDA_Measures.MeanPeakWidth = mean(w,'omitnan');
EDA_Measures.MeanPeakWidth(isnan(EDA_Measures.MeanPeakWidth)) = 0;



if ~isempty(pLoc)
    EDA_Measures.FirstPeakLatency = pLoc(1);
else
    EDA_Measures.FirstPeakLatency = 0;

end

EDA_Measures.AreaUnderTheCurve = trapz(tx,data);
%EDA_Measures.AreaUnderConvolution = trapz(pks2plot);

end