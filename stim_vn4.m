%TODO: Improve protocol detection
%TODO: Adaptive Filtering
%% choose patient and protocoll 
for k = 1
close all; clc; 
id1 = ['ID1';'ID2';'ID3';'ID4';'ID5'];
cd(id1(k,:))
clear variables
y = load("protocol_3_2.mat"); 
%% initial values 
resp=y.data(:,1); 
bloodp=y.data(:,3); 
stim = y.data(:,4);
RR =y.data(:,5); 
%% Convert x-axis to time in sec
Fs=1000; %Sample rate in Hz
L=length(y.data(:,2)); 
t_signal = ((0:L-1)/Fs)';%time vector 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                        DETECT R PEAKS & STIM                            %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd("/Users/jt/Library/Mobile Documents/com~apple~CloudDocs/Documents/TUW/M. Sc. 3 Semester/Project Signals&Instrumentation /analyze_ecg")
%detect r peaks 
[rpeaks,~,~] = analyze_ecg_offline_r(y.data(:,2), Fs);  
t_Rpeaks= t_signal(rpeaks);
%% find rising flank of stimulus
cd("/Users/jt/Library/Mobile Documents/com~apple~CloudDocs/Documents/TUW/M. Sc. 3 Semester/Project Signals&Instrumentation ")
[start_stim,stim_loc,end_loc] = RF_stim(stim,Fs,0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                       Categorize the input protocoll                    %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
diff1 = find((diff(end_loc) <= 20) == 1); 
diff2 = find((gradient(end_loc) >= 2000) == 1); 
sort1  = sort([1, end_loc(diff1), end_loc(diff2),length(t_signal)]);
for i=1:length(sort1)-1
    c(i,1) = (sort1(i+1) - sort1(i)) >= 150000; 
end
d = find(c == 1); 
edges = [1,sort1(d+1)];  

% Mark the data 
cflag(edges(1):max(edges),1) = "Non-sync aVNS"; 
cflag(edges(2):edges(3),1) = "Systole-sync aVNS";
cflag(edges(4):edges(5),1) = "Diastole-sync aVNS"; 
stim_flag = cflag(stim_loc);

dflag(edges(1):max(edges),1) = 1; 
dflag(edges(2):edges(3),1) = 2;
dflag(edges(4):edges(5),1) = 3; 
stimstr = ["Non-sync aVNS", "Systole-sync aVNS", "Diastole-sync aVNS"]; 

[stim_RR,stim_alpha,stim_flag,stim_tR] =initRR(stim_loc, rpeaks,t_signal,stim_flag); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                       Normalize ECG and histogram                       %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
nflag = zeros(length(dflag),1); 
nflag(stim_loc) = 1; 
x1 = linspace(0,1,length(rpeaks)); 
%
for j = 1:length(rpeaks)-1
% split ECG signal and flag from R to R peak 
segment= rpeaks(j):rpeaks(j+1); 
splitECG{j,:} = [y.data(segment,2),nflag(segment),dflag(segment)];
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
% Savitzky-Golay filter
SG_resp = sgolayfilt(resp,1,Fs+1);
%
[seg,~,~] = cyclesAdvance(Fs, SG_resp,[]); %,'plot');  
% Ensure same number of Insp/ Exp. 
if length(seg.begEx) > length(seg.begIn)
    seg.begEx(end) = []; 
elseif length(seg.begIn) > length(seg.begEx)
    seg.begIn(end) = []; 
end 
%
resp_flag(1:length(seg.begEx),1) = "Expiration"; 
resp_flag(length(seg.begEx)+1:2*length(seg.begEx),1)= "Inspiration"; 
[start_InEx,I] = sort([seg.begEx, seg.begIn]); 
resp_flag = resp_flag(I); 

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
testRR = interp1(stim_tR(:,2),stim_RR{1,1},t_signal,'linear');
res= adapt_filt2(seg.begIn,t_signal,testRR,meanF,1); 
%test function 
% x = exp(-2*t').*chirp(t',2,1,28,'quadratic');
% figure

% RdR_fit(stim_alpha, af_RR, stim_flag,1,60,1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                                OUTPUT                                   %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%(1.) OUTPUT - Data Overview - 
output_plot(y,edges,Fs,x1,prc,colMeans,beta,label,stimstr); 
%(2.) OUTPUT - Respiration -
RdR_fit(resp_alpha, resp_RR, resp_flag,1,0,1) 
%(2.) OUTPUT - Filter Respiration
RdR_fit(resp_alpha, filt_respRR, resp_flag,1,0,1) 
%(4.) OUTPUT - Stimulation -
RdR_fit(stim_alpha, stim_RR, stim_flag,1,60,1)
%RdR_fit(stim_alpha, stim_RR, stim_flag,2,60,0)
%(5.) OUTPUT - Filter Stimulation -
RdR_fit(stim_alpha, filt_stimRR, stim_flag,1,60,1) 
end 