% Example Script MS_Regress_Fit.m - MS-VAR estimation

clear;

addpath('m_Files'); % add 'm_Files' folder to the search path
addpath('data_Files');

% load data
% imported=importdata('./data_Files/trial1.txt');  % load some Data.
% data = imported.data;
load manual_select_dummy_FRED
%data = 100*diff(data(:,2:3));
start = 0;
shift = 0;
forward_resid_rCIPI = share_rCIPI_potential(start+2+shift:end,:);
forward_IS = ln_rISratio(start+1+shift:end,:);
match_sales = ln_rSales(start+1:end-shift,:);
match_gdp= ln_rGDP(start+1:end-shift,:);

data = 100*[ diff(match_sales) diff(match_gdp) forward_resid_rCIPI ];

% data label
datelabel = (1949.25:0.25:2016.50)'; % because first differenced
yearnum = floor(datelabel);
monthnum = 12*(datelabel - yearnum)+2;
date_serial = datenum(yearnum,monthnum,ones(size(yearnum)));

dep=data;                  % Defining dependent variables in system
nLag=1;                             % Number of lags in system
k=2;                                % Number of States
doIntercept=1;                      % add intercept to equations?
advOpt.distrib='Normal';            % The Distribution assumption (only 'Normal' for MS VAR models)
advOpt.std_method=2;                % Defining the method for calculation of standard errors. See pdf file for more details
advOpt.diagCovMat=0;                % since it reduced form, diagonal is stupid
advOpt.useMex=1;                % uses mex version of hamilton filter
% advOpt.optimizer='fminsearch';     % use fmincon instead

[Spec_Out]=MS_VAR_Fit(dep,nLag,k,doIntercept,advOpt);
save trials1_new.mat

%% plot
safe_dates = date_serial(start+1:end-shift,:);
figure
plot(safe_dates,Spec_Out.smoothProb(:,2));
h = gca;
datetick('x','yyyy','keepticks')
xlabel('Time');
ylabel('Smoothed States Probabilities');
legend('Regime 1');
axis tight
recessband = recessionplot;

%% IRF
regime = 1;
irfperiods = 6;
impulsevar = 1;

% initialzation
impulsevec = zeros(3,irfperiods);
Yimpulse = zeros(3,irfperiods);

B = [Spec_Out.Coeff.S_Param{1,1}(:,regime)'; ...
	        Spec_Out.Coeff.S_Param{1,2}(:,regime)'; ...
			Spec_Out.Coeff.S_Param{1,3}(:,regime)'; ...
			];
B0 = B(:,1);
B1 = B(:,2:2+2);
B2 = B(:,5:7);
Ymean = (eye(3) - B1 - B2)\B0;
L = chol(Spec_Out.Coeff.covMat{regime})';
impulsevec(impulsevar,1) = 1;
Yimpulse(:,1) = B0 + B1*Ymean + B2*Ymean + L*impulsevec(:,1);
Yimpulse(:,2) = B0 + B1*Yimpulse(:,1) + B2*Ymean + L*impulsevec(:,2);
for i_period = 3:irfperiods
	Yimpulse(:,i_period) = B0 + B1*Yimpulse(:,i_period-1) + B2*Yimpulse(:,i_period-2) + L*impulsevec(:,i_period);
end
Yirf_regime1 = Yimpulse - repmat(Ymean,1,irfperiods);

regime = 2;
% initialzation
impulsevec = zeros(3,irfperiods);
Yimpulse = zeros(3,irfperiods);

B = [Spec_Out.Coeff.S_Param{1,1}(:,regime)'; ...
	        Spec_Out.Coeff.S_Param{1,2}(:,regime)'; ...
			Spec_Out.Coeff.S_Param{1,3}(:,regime)'; ...
			];
B0 = B(:,1);
B1 = B(:,2:2+2);
B2 = B(:,5:7);
Ymean = (eye(3) - B1 - B2)\B0;
L = chol(Spec_Out.Coeff.covMat{regime})';
impulsevec(impulsevar,1) = 1;
Yimpulse(:,1) = B0 + B1*Ymean + B2*Ymean + L*impulsevec(:,1);
Yimpulse(:,2) = B0 + B1*Yimpulse(:,1) + B2*Ymean + L*impulsevec(:,2);
for i_period = 3:irfperiods
	Yimpulse(:,i_period) = B0 + B1*Yimpulse(:,i_period-1) + B2*Yimpulse(:,i_period-2) + L*impulsevec(:,i_period);
end
Yirf_regime2 = Yimpulse - repmat(Ymean,1,irfperiods);

figure 
subplot(2,1,1)
plot(Yirf_regime1')
legend('resid_CIPI','sales','ISratio')
subplot(2,1,2)
plot(Yirf_regime2')
legend('resid_CIPI','sales','ISratio')

%% aftermath

rmpath('m_Files');
rmpath('data_Files'); 