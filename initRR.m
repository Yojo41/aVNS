function [RR,alpha,groupflag,tRpeaks] = initRR(event_loc, rpeaks,t_signal,groupflag)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% -Description-
%Calculation of RR, and alpha. Alpha is an angle and descirbes the point,
%where the stimulation in den RR circle happens. 
%
% -Input- 
%event_loc: location of an event (stimulation, expiration, inspiration) 
%rpeaks: all locations of R-peaks 
%t_signal: time vector of the signal. Translate the locations in the time
%domain
%groupflag: assign each event to an specific subgroup (e.g. stimulation
%protocol, Inspiration vs. Expiration) 
%
% -Output- 
%RR: struct containing RR intervalls
%alpha: stimulation point in the circle of RR intervall.
%tRpeaks: time of the R peak before the stimulation, the R peak after the
%stimulation and the 4 following R peaks. 
%groupflag:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if max(event_loc) > max(rpeaks)
    event_loc(end) = []; 
    groupflag(end) = []; 
end 
for i = 1:length(event_loc)
   idx_r(i) = find(rpeaks - event_loc(i) >= 0,1); 
end 
%if there are no more Rpeaks, because the measurement ends the 
%b stimuli after the last R peak are ignored. 
if max(idx_r)+4 > length(rpeaks)
    b = sum(idx_r+4 >= length(rpeaks)); 
    idx_r(end-b:end) = []; 
    event_loc(end-b:end) = [];
    groupflag(end-b:end) = []; 
end 
if min(idx_r) == 1 
    idx_r(1) = []; 
    event_loc(1) = []; 
    groupflag(1) = []; 
end
% 
R_after = rpeaks(idx_r); 
R_before = rpeaks(idx_r-1);  
% get stimulation in degrees
alpha = ((t_signal(event_loc) - t_signal(R_before)) ./ ...
   (t_signal(R_after) - t_signal(R_before)) ) * 360 ; 
%if there are multiple stimuli in one interval ignore the earlier one, 
%and keep the last one.
[idx_r,ia,~] = unique(idx_r,'last'); 
alpha = alpha(ia); 
groupflag =groupflag(ia); 
%assign time of nearest r peak, the r peak before and the 4 r peaks after
%the stimulation 
%k=1 --> Ri-1 ...... k=6 --> Ri+4
for j = 1:6
tRpeaks(:,j) = t_signal(rpeaks(idx_r+j-2)); 
end
for j = 1:5
RR{j,:}= tRpeaks(:,j+1) - tRpeaks(:,j);
end