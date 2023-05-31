%TODO: Revisit the Code, Simplify things, overthink every concept, improve
%runtime
%TODO: Improve inspiration/expiration detection
%Further Ideas: Include Blood Pressure into concideration. (Baroreceptor) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                     choose patient and protocoll                        %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
for k =3
close all; clc; 
id1 = ['ID1';'ID2';'ID3';'ID4';'ID5'];
cd(id1(k,:))
y = load("protocol_3_2.mat"); 
% initial values 
resp=y.data(:,1); 
ECG=y.data(:,2); 
bloodp=y.data(:,3); 
Rstim = y.data(:,4);
RR =y.data(:,5); 
% Convert x-axis to time in sec
Fs=1000; %Sample rate in Hz
L=length(y.data(:,2)); 
t_signal = ((0:L-1)/Fs)';%time vector 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                        DETECT R PEAKS & STIM                            %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd("/Users/jt/Library/Mobile Documents/com~apple~CloudDocs/Documents/TUW/M. Sc. 3 Semester/Project Signals&Instrumentation /analyze_ecg")
[rpeaks,~,~] = analyze_ecg_offline_r(ECG, Fs);  
% find rising flank of stimulus
cd("/Users/jt/Library/Mobile Documents/com~apple~CloudDocs/Documents/TUW/M. Sc. 3 Semester/Project Signals&Instrumentation ")
stim = RF_stim(Rstim,ECG,rpeaks,t_signal,Fs,1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                   Categorize stimulation protocoll                      %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%automatic detection of stimulation protocol change
[~,loc] = findpeaks(abs(gradient(stim.beg)-1000),'MinPeakDistance',300,'MinPeakHeight',900); 
edges = [1,stim.beg(loc),length(Rstim)]; 
  
% Mark the data 
stimstr = ["Non-sync aVNS", "Systole-sync aVNS", "Diastole-sync aVNS"]; 
sflag(edges(1):max(edges),1) = 1; 
sflag(edges(2):edges(3),1) = 2;
sflag(edges(4):edges(5),1) = 3; 
stim_flag = sflag(stim.beg);

[stim_RR,stim_alpha,stim_flag,stim_tR] =initRR(stim.beg, rpeaks,t_signal,stim_flag); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                       Normalize ECG and histogram                       %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
nflag = zeros(length(sflag),1); 
nflag(stim.beg) = 1; 
x1 = linspace(0,1,length(rpeaks)); 
%
for j = 1:length(rpeaks)-1
% split ECG signal and flag from R to R peak 
segment= rpeaks(j):rpeaks(j+1); 
splitECG{j,:} = [y.data(segment,2),nflag(segment),sflag(segment)];
%find stimulation point in splitted ECG signal 
splitECG_stimloc{j,1} = find(splitECG{j,1}(:,2) == 1,1,'last'); 
label{j,1} = splitECG{j,1}(splitECG_stimloc{j,1},3); 
% calulate timepoint of stimulation in degrees
beta{j,1} = splitECG_stimloc{j,1}  / length(splitECG{j,:}(:,1)); 
% Interpolate = Normalization of ECG signals
splitECG_res(j,:) = interp1(linspace(0,1,length(splitECG{j,1}(:,1))), ...
    splitECG{j,:}(:,1), x1);
end 

colMeans = mean(splitECG_res,1);
prc = prctile(splitECG_res,[25 75],1); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                Classification Inspiration / Expiration                  %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% Moving Average Filter
windowSize = 1.5*Fs; 
b = (1/windowSize)*ones(1,windowSize);
a = 1; 
maf = filtfilt(b,a,resp);
dmaf = gradient(maf); 
% window function inspiration/ expiration 
for i=1:length(maf)
    if dmaf(i)<= 0 
        wresp(i)=-1;
    elseif dmaf(i)> 0
        wresp(i)=1; 
    else 
        wresp(i) = wresp(i-1); 
    end 
end 
[~,seg.begIn] = findpeaks(wresp); 
[~,seg.begEx] = findpeaks(-wresp); 

% Ensure same number of Insp/ Exp. 
if length(seg.begEx) > length(seg.begIn)
    seg.begEx(end) = []; 
elseif length(seg.begIn) > length(seg.begEx)
    seg.begIn(end) = []; 
end 
% Assign label 
resp_flag(1:length(seg.begEx),1) = "Expiration"; 
resp_flag(length(seg.begEx)+1:2*length(seg.begEx),1)= "Inspiration"; 
[start_InEx,I] = sort([seg.begEx, seg.begIn]); 
resp_flag = resp_flag(I); 
    
%PLOT 
figure()
plot(t_signal,resp,'DisplayName','Raw')
hold on
plot(t_signal,maf,'DisplayName','Moving Average')
plot(t_signal(seg.begIn),maf(seg.begIn),'g*','DisplayName','Inspiration')
plot(t_signal(seg.begEx),maf(seg.begEx),'r*','DisplayName','Expiration')
legend show

[resp_RR,resp_alpha,resp_flag,resp_tR] = initRR(start_InEx, rpeaks,t_signal,resp_flag); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                   Filter signal with mean resp frequency                %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
meanF = meanfreq(resp,Fs);
q= 3;%Hz
[filt_respRR,~] = RR_filt(resp_tR(:,2),resp_RR,meanF,q,0); 
[filt_stimRR,~] = RR_filt(stim_tR(:,2),stim_RR,meanF,q,1); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                           Adaptive Filter                               %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for kk = 1:5 
af_respRRi = interp1(resp_tR(:,2),resp_RR{kk,1},t_signal,'linear');
af_stimRRi = interp1(stim_tR(:,2),stim_RR{kk,1},t_signal,'linear');
resp_res= adapt_filt2(seg.begIn,t_signal,af_respRRi,meanF,0); 
stim_res= adapt_filt2(seg.begIn,t_signal,af_stimRRi,meanF,1); 
af_respRR{kk,1} = interp1(t_signal,resp_res,resp_tR(:,2),'linear','extrap');
af_stimRR{kk,1} = interp1(t_signal,stim_res,stim_tR(:,2),'linear','extrap');
end 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                                OUTPUT                                   %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%(1.) OUTPUT - Data Overview - 
output_plot(y,edges,Fs,x1,prc,colMeans,beta,label,stimstr); 
%OUTPUT - Respiration -
RdR_fit(resp_alpha, resp_RR, resp_flag,1,0,1) 
%OUTPUT - Filter Respiration
RdR_fit(resp_alpha, filt_respRR, resp_flag,1,0,1) 
%OUTPUT - Adaptive Filter Respiration
RdR_fit(resp_alpha, af_respRR,resp_flag,1,0,1)
%OUTPUT - Stimulation -
RdR_fit(stim_alpha, stim_RR, stimstr(stim_flag),1,60,1)
%RdR_fit(stim_alpha, stim_RR, stim_flag,2,60,0)
%OUTPUT - Filter Stimulation -
RdR_fit(stim_alpha, filt_stimRR, stimstr(stim_flag),1,60,1) 
%OUTPUT - Adaptive Filter Stimulation 
RdR_fit(stim_alpha, af_stimRR, stimstr(stim_flag),1,60,1)
% SAVE for further investigations 
save(['Patient',num2str(k),'.mat'],"stim_alpha","stim_RR","stim_flag","af_stimRR")
clear variables
end 