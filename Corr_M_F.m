% coprrelazioni peaknumber/stai per maschio/femmina in ogni interazione


x_SC_M = PeakNumber.StrangerCross(PeakNumber.Gender == 'M');
x_SE_M = PeakNumber.StrangerEye(PeakNumber.Gender == 'M');
x_PC_M = PeakNumber.PartnerCross(PeakNumber.Gender == 'M');
x_PE_M = PeakNumber.PartnerEye(PeakNumber.Gender == 'M');



x_SC_F = PeakNumber.StrangerCross(PeakNumber.Gender == 'F');
x_SE_F = PeakNumber.StrangerEye(PeakNumber.Gender == 'F');
x_PC_F = PeakNumber.PartnerCross(PeakNumber.Gender == 'F');
x_PE_F = PeakNumber.PartnerEye(PeakNumber.Gender == 'F');


isM = PeakNumber.Gender == 'M';
isF = PeakNumber.Gender == 'F';

staiM = stai(isM,:);
staiF = stai(isF,:);



%
x = x_PE_F;
y = staiM.deltaP;
%



mdl = fitlm(x,y);

plot(mdl);

title(['R = ' num2str(mdl.Rsquared.Adjusted) '. p = ' num2str(mdl.Coefficients.pValue(2))])
    



