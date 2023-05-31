function result = adapt_filt2(insp,tsignal,RR,meanF,pltflg)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Description: 
%
%%INPUT: 
%insp: location of inspiration
%RR: Raw RR signal 
%OUTPUT:
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% INTERPOLATION WITH q Hz 
q=3; 
n = round(max(tsignal)*q);
ti = linspace(0,max(tsignal),n);
RRi = interp1(tsignal,RR,ti,'linear');
RRi(isnan(RRi)) = 1; 
for j= 0:length(insp)
    %% FIRST INTERVAL
    if j == 0 
        segment =1:insp(1);    
        %
        Fpass1 = meanF-0.1; 
        Fstop1 = meanF-0.05; 
        Fstop2 = meanF+0.05; 
        Fpass2 = meanF+0.1; 
    %% LAST INTERVAL
    elseif j == length(insp)
        segment =insp(end):length(tsignal); 
        %
        Fpass1 = meanF-0.1; 
        Fstop1 = meanF-0.05; 
        Fstop2 = meanF+0.05; 
        Fpass2 = meanF+0.1; 
    %% IN BETWEEN 
    else
        segment = insp(j):insp(j+1); 
        
        tresp= tsignal(segment(end)) - tsignal(segment(1));
        fresp= 1/tresp;
        if fresp > 0.1 && fresp < 1.4
        Fpass1 = fresp-0.1; 
        Fstop1 = fresp-0.05; 
        Fstop2 = fresp+0.05; 
        Fpass2 = fresp+0.1; 
        else
        Fpass1 = meanF-0.1; 
        Fstop1 = meanF-0.05; 
        Fstop2 = meanF+0.05; 
        Fpass2 = meanF+0.1; 
        end 
    end 
    %% FILTER DESIGN 
    d = designfilt('bandstopfir', ...
    'FilterOrder',30,...
    'PassbandFrequency1',Fpass1,...
    'StopbandFrequency1',Fstop1, ...
    'StopbandFrequency2',Fstop2,...
    'PassbandFrequency2',Fpass2, ...
    'SampleRate',q); 
    % Unity gain              
    b = d.Coefficients ./ sum(d.Coefficients); 
    %
    [filt_RRi] = filtfilt(b,1,RRi);
    %% EXTRAPOLATION
    filt_RR = interp1(ti,filt_RRi,tsignal,"linear","extrap"); 
    result(segment) = filt_RR(segment); 
end 

%% PLOT 
if pltflg == 1 
    figure()
    plot(tsignal,result,'DisplayName','Filtered signal')
    hold on
    plot(ti,RRi,'DisplayName','Original signal')
    xlabel('time [sec]')
    ylabel('RR')
    legend show
end 


