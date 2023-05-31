function result = RF_stim(stim,ECG,rpeaks,t_signal,Fs,pltflag)

avg_stim = mean(stim);
std_stim = std(stim);
norm_stim = stim - avg_stim;
ratio = round(norm_stim./std_stim);
win_stim = zeros(1,length(stim));
win_stim(ratio>0.1 | ratio<-0.1) = 1;
% when stim changes between pos and neg a timestep is not detected as
% stimulus. So overcome this problem it is manually asigned to stim (=1). 
for i=1:length(win_stim)-10
    if win_stim(i+1) == 0 && win_stim(i+2) ==1 && win_stim(i) == 1 || ...
       win_stim(i+1) == 0 && win_stim(i+5) ==1 && win_stim(i) == 1 || ...
       win_stim(i+1) == 0 && win_stim(i+10) ==1 && win_stim(i) == 1 
       win_stim(i+1)=1;  
    end
end 
%now findpeaks will work properly  
[~,start_loc] = findpeaks(win_stim); 
[~,end_loc] = findpeaks(-win_stim);
start_stim = (start_loc-1)'/Fs;

result.beg = start_loc; 
result.end = end_loc; 
%% PLOT 
% random range 
a = t_signal(randperm(length(t_signal),1));
b = a + 5; 

if pltflag == 1
    ax(1) = subplot(3,1,1); 
    plot(t_signal,ECG)
    hold on
    plot(t_signal(rpeaks),ECG(rpeaks),'r*')
    legend(['ECG signal','r peaks'])
    ax(2) = subplot(3,1,2); 
    plot(t_signal,stim)
    legend('stim signal')
    ax(3) = subplot(3,1,3); 
    plot(t_signal,win_stim,'k','LineWidth',1)
    hold on
    plot(start_stim,ones(length(start_stim),1),'g*')
    plot(t_signal(rpeaks),ones(length(rpeaks),1),'r*')
    legend('window func','start stim','r peak ECG')
    linkaxes(ax,'x')
    xlim(ax,[a b])
end 