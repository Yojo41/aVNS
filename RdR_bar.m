function output = RdR_bar(i_Rpeaks,t_Rpeaks, t_onset, pltflag, colorflag)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: 
% Calculates the difference between RR intervall 

% Input: 
%i_Rpeaks: index of interested R peaks
%t_Rpeaks: time of all R peaks
%t_onset: time of event (stimulation,inspiration,expiration) 

% Output: 
%output: difference between RRi to RRi+4 
%alpha: angle between event (stimulation,inspiration,expiration) and R peak
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if max(i_Rpeaks)+4 > length(t_Rpeaks)
    k = sum(i_Rpeaks+4 > length(t_Rpeaks)); 
    i_Rpeaks(end-k:end) = []; 
    t_onset(end-k:end) = [];
    colorflag(end-k:end) = [];
end 
if min(i_Rpeaks) == 1 
    i_Rpeaks(1) = []; 
    t_onset(1) = []; 
    colorflag(1) = []; 
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
RR_0 = t_Rpeaks(i_Rpeaks) - t_Rpeaks(i_Rpeaks-1);
RR_1 = t_Rpeaks(i_Rpeaks+1) - t_Rpeaks(i_Rpeaks); 
RR_2 = t_Rpeaks(i_Rpeaks+2) - t_Rpeaks(i_Rpeaks+1);
RR_3 = t_Rpeaks(i_Rpeaks+3) - t_Rpeaks(i_Rpeaks+2);
RR_4 = t_Rpeaks(i_Rpeaks+4) - t_Rpeaks(i_Rpeaks+3);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
alpha = ((t_onset - t_Rpeaks(i_Rpeaks -1 )) ./ RR_0) * 360; 
% 
[alpha,s_idx] = sort(alpha); 
alpha(1:sum(alpha < 60),1) = alpha(1:sum(alpha < 60),1) + 360; 
% 
RR_0 = RR_0(s_idx); 
RR_1 = RR_1(s_idx); 
RR_2 = RR_2(s_idx); 
RR_3 = RR_3(s_idx); 
RR_4 = RR_4(s_idx); 
colorflag = colorflag(s_idx); 
x_lim = [60,420]; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
output = {alpha; RR_0 ; RR_1; RR_2; RR_3; RR_4}; 

if pltflag == 1 
    figure 
    hp1 = uipanel('position',[0 .5 .5 .5]);
    hp2 = uipanel('position',[0 0 .5 .5]);
    hp3 = uipanel('position',[.5 .5 .5 .5]);
    hp4 = uipanel('position',[0.5 0 .5 .5]);
    %%%
    h = scatterhist(alpha,((RR_1 ./ RR_0) -1 )*100,'Color','kbr',...
        'LineStyle',{'-','-.',':'},'Marker','+od','Parent',hp1,'Group',colorflag);
    h(1).XLim = (x_lim); 
    h(1).YLim = ([-30,30]); 
    title('$\Delta RR = RR_{i+1}/RR_{i}$','Interpreter','latex')
    xlabel('$deg [^\circ]$','interpreter','latex'); 
    ylabel('$\Delta RR \quad [\%]$','interpreter','latex');
    %
    hold on;
    boxplot(h(2),alpha,colorflag,'orientation','horizontal',...
         'label',{'','',''},'color','kbr');
    boxplot(h(3),((RR_1 ./ RR_0) -1 )*100,colorflag,'orientation','horizontal',...
         'label', {'','',''},'color','kbr');
    set(h(2:3),'XTickLabel','');
    view(h(3),[270,90]);  % Rotate the Y plot
    hold off; 
    %%%
    h = scatterhist(alpha,((RR_2 ./ RR_0) -1 )*100,'Color','kbr',...
        'LineStyle',{'-','-.',':'},'Marker','+od','Parent',hp2,'Group',colorflag);
    title('$\Delta RR = RR_{i+2}/RR_{i}$','Interpreter','latex')
    xlim(x_lim)
    ylim([-30,30])
    xlabel('$deg [^\circ]$','interpreter','latex'); 
    ylabel('$\Delta RR \quad [\%]$','interpreter','latex');
    %
    hold on;
    boxplot(h(2),alpha,colorflag,'orientation','horizontal',...
         'label',{'','',''},'color','kbr');
    boxplot(h(3),((RR_2 ./ RR_0) -1 )*100,colorflag,'orientation','horizontal',...
         'label', {'','',''},'color','kbr');
    set(h(2:3),'XTickLabel','');
    view(h(3),[270,90]);  % Rotate the Y plot
    hold off; 
    %%%
        h = scatterhist(alpha,((RR_3 ./ RR_0) -1 )*100,'Color','kbr',...
        'LineStyle',{'-','-.',':'},'Marker','+od','Parent',hp3,'Group',colorflag);
    title('$\Delta RR = RR_{i+3}/RR_{i}$','Interpreter','latex')
     xlim(x_lim)
    ylim([-30,30])
    xlabel('$deg [^\circ]$','interpreter','latex'); 
    ylabel('$\Delta RR \quad [\%]$','interpreter','latex');
    %
    hold on;
    boxplot(h(2),alpha,colorflag,'orientation','horizontal',...
         'label',{'','',''},'color','kbr');
    boxplot(h(3),((RR_3 ./ RR_0) -1 )*100,colorflag,'orientation','horizontal',...
         'label', {'','',''},'color','kbr');
    set(h(2:3),'XTickLabel','');
    view(h(3),[270,90]);  % Rotate the Y plot
    hold off; 
    %%%
    h = scatterhist(alpha,((RR_4 ./ RR_0) -1 )*100,'Color','kbr',...
        'LineStyle',{'-','-.',':'},'Marker','+od','Parent',hp4,'Group',colorflag);
    title('$\Delta RR = RR_{i+4}/RR_{i}$','Interpreter','latex')
     xlim(x_lim)
    ylim([-30,30])
    xlabel('$deg [^\circ]$','interpreter','latex'); 
    ylabel('$\Delta RR \quad [\%]$','interpreter','latex');
    %
    hold on;
    boxplot(h(2),alpha,colorflag,'orientation','horizontal',...
         'label',{'','',''},'color','kbr');
    boxplot(h(3),((RR_4 ./ RR_0) -1 )*100,colorflag,'orientation','horizontal',...
         'label', {'','',''},'color','kbr');
    set(h(2:3),'XTickLabel','');
    view(h(3),[270,90]);  % Rotate the Y plot
    hold off; 
    %%%
end 
end 
