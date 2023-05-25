function [filt_RR,ti] = RR_filt(tR,RR,meanF,q,pltflg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% -Description-
%Interpolation, application of filter, Extrapolation
%
% -Input- 
%tR: time of R peaks
%RR: struct containing RR intervalls 
%meanF: filter frequency 
%q: interpolation frequency in Hz (3-5Hz) 
%windowsize: length of the filter window 
%
% -Output- 
%filt_RR: struct containing filtered RR intervalls
%ti: timevector of interpolated signal 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define equidistant vector between min and max
n = round((max(tR)-min(tR))*q); 
ti = linspace(min(tR),max(tR),n);

Fpass1 = meanF-0.1; 
Fstop1 = meanF; 
Fstop2 = meanF+0.1; 
Fpass2 = meanF+0.2; 

d = designfilt('bandstopfir', ...
  'PassbandFrequency1',Fpass1,...
  'StopbandFrequency1',Fstop1, ...
  'StopbandFrequency2',Fstop2,...
  'PassbandFrequency2',Fpass2, ...
  'PassbandRipple1',0.5,...
  'StopbandAttenuation',10, ...
  'PassbandRipple2',0.5, ...
  'DesignMethod','kaiser',...
  'SampleRate', q);
          
%fvtool(d)
% 
for k = 1:5
%% Linear interpolation 
RRi{k,:} = interp1(tR,RR{k,:},ti,'linear'); 
%% Design and application of lowpass filter 
filt_RRi{k,:} = filtfilt(d,RRi{k,:}); 
%% Linear extrapolation 
filt_RR{k,:} = interp1(ti,filt_RRi{k,:},tR,'linear','extrap'); 
% 
end 
if pltflg == 1 
    [h{1},w{1}] = freqz(d); 
    figure
    subplot(2,1,1)
    plot(RRi{1,1})
    hold on 
    plot(filt_RRi{1,1})
    subplot(2,1,2)
    yyaxis left
    plot(w{1},20*log10(abs(h{1})),'DisplayName','Magnitude')
    hold on 
    ylabel('$Magnitude [dB]$','Interpreter','latex')
    yyaxis right
    plot(w{1},unwrap(angle(h{1})),'DisplayName','Phase')
    ylabel('$Phase [^\circ]$','Interpreter','latex')
    grid minor 
    xlim([0,q/2])
    xlabel('$Frequency [Hz]$','Interpreter','latex')
    
    legend show
end 
