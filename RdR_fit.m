function [] = RdR_fit(alpha, RR, groupflag, pltflag, theta, showfit)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description: 
% Calculates the difference between RR intervall 
%
% Input: 
%i_Rpeaks: index of interested R peaks
%t_Rpeaks: time of all R peaks
%t_onset: time of event (stimulation,inspiration,expiration) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                    Shift data by theta degrees                          %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if theta > 0 
    %
    [alpha,s_idx] = sort(alpha); 
    alpha(1:sum(alpha < theta),1) = alpha(1:sum(alpha < theta),1) + 360; 
    % 
    for k = 1:5 
    RR{k,:} = RR{k,:}(s_idx); 
    end 
    groupflag = groupflag(s_idx); 
    B = ["Non-sync aVNS", "Systole-sync aVNS", "Diastole-sync aVNS"];
    [~, index] = ismember(groupflag, B);
    [~, s] = sort(index);
    groupflag = groupflag(s)';
    alpha = alpha(s); 
    for k = 1:5 
    RR{k,:} = RR{k,:}(s); 
    end 
end 
x_lim = [theta,360+theta]; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                               FIT                                       %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for k = 1:4 
    if any(groupflag == "Expiration")
    ifit{k,:}= fit(alpha,((RR{k+1,:} ./ RR{1,:}) -1 )* 100,'poly1','Exclude',groupflag ~= "Inspiration"); 
    efit{k,:}= fit(alpha,((RR{k+1,:} ./ RR{1,:}) -1 )* 100,'poly1', 'Exclude', groupflag ~= "Expiration"); 
    elseif any(groupflag == "Non-sync aVNS")
    sfit{k,:}= fit(alpha,((RR{k+1,:} ./ RR{1,:}) -1 )* 100,'poly1','Exclude',or(groupflag ~= "Systole-sync aVNS",alpha < 200)); 
    dfit{k,:}= fit(alpha,((RR{k+1,:} ./ RR{1,:}) -1 )* 100,'poly1','Exclude',or(groupflag ~="Diastole-sync aVNS", alpha > 250)); 
    nfit{k,:}= fit(alpha,((RR{k+1,:} ./ RR{1,:}) -1 )* 100,'poly1','Exclude',groupflag ~= "Non-sync aVNS");
    end
end 
xfit1 = linspace(250,360+theta,100); 
xfit2 = linspace(theta,250,100); 
xfit3 = linspace(theta,360,150); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                               Plot                                      %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if pltflag == 1 
    colorstr = ["b","k","r"]; 
    figure 
    hp1 = uipanel('position',[0 .5 .5 .5]);
    hp2 = uipanel('position',[0 0 .5 .5]);
    hp3 = uipanel('position',[.5 .5 .5 .5]);
    hp4 = uipanel('position',[0.5 0 .5 .5]);
    hp = {hp1; hp2; hp3; hp4}; 
    g = findgroups(groupflag); 
for k = 1:4
    %%%
    
    s = scatterhist(alpha,((RR{k+1,:} ./ RR{1,:}) -1 )* 100,'NBins',[30 20], ...
        'Color','kbr', 'LineStyle',{'-','-.',':'},'Marker','+od','Style','bar', ...
        'Parent',hp{k},'Group',groupflag,'Direction','in');
    pdca = fitdist(((RR{k+1,:}(g) ./ RR{1,:}(g)) -1 )* 100,'Kernel','By',g,'Width',3); 
    for j=1:length(unique(g))
    cla(s(2))
    cla(s(3))
    hold(s(2),'on')
    hold(s(3),'on')
    arrayfun(@(j)histogram(s(2),alpha(g==j),'BinWidth',11.7,'FaceColor',...
        colorstr(j),'Normalization','probability'),unique(g))
    x2 = -30:1:30; 
    arrayfun(@(j) plot(s(3),x2,pdf(pdca{1,j},x2),'Color',colorstr(j)),unique(g))
    end 
    camroll(s(3),180)
    
%    arrayfun(@(j)fitdist(s(3),((RR{k+1,:}(g==j) ./ RR{1,:}(g==j)) -1 )* 100,...
%        'kernel'),unique(g)); 
%   end
    axis(s(2:3),'tight')
    axis(s(2:3),'on')
    set(s(2:3),'xtick',[],'Xcolor','w','box','off')    
    hold on 
    %
    if any(groupflag == "Expiration") && showfit == 1 
    h1 = plot(xfit3, ifit{k,:}.p1*xfit3+ifit{k,:}.p2, ...
        'DisplayName',sprintf("Inspiration: m=%4.2f",ifit{k,:}.p1)); 
    h2 = plot(xfit3, efit{k,:}.p1*xfit3+efit{k,:}.p2, ...
        'DisplayName',sprintf("Expiration: m=%4.2f",efit{k,:}.p1)); 
    set(h1, 'LineWidth',2)
    set(h2, 'LineWidth',2)
    elseif any(groupflag == "Non-sync aVNS") && showfit == 1 
    plot(xfit1,sfit{k,:}.p1*xfit1+sfit{k,:}.p2, ...
        'Color','r','LineStyle','--','LineWidth',2,'DisplayName',sprintf("Systole: m=%4.2f",sfit{k,:}.p1)); 
    plot(xfit2,dfit{k,:}.p1*xfit2+dfit{k,:}.p2, ...
        'Color','b','LineStyle','--','LineWidth',2,'DisplayName',sprintf("Diastole: m=%4.2f",dfit{k,:}.p1)); 
    h3 = plot(nfit{k,:});
    set(h3,'Color','m','LineStyle','--','LineWidth',2,'DisplayName',sprintf("Non-sync: m=%4.2f",nfit{k,:}.p1))
    end
    %
    title(['$\Delta RR = RR_{i+',num2str(k),'}/RR_{i}$'],'Interpreter','latex')
    xlim(x_lim)
    ylim([-30,30])
    xlabel('$deg [^\circ]$','interpreter','latex'); 
    ylabel('$\Delta RR \quad [\%]$','interpreter','latex');
end 
end 
if pltflag == 2
    figure 
    hp1 = uipanel('position',[0 .5 .5 .5]);
    hp2 = uipanel('position',[0 0 .5 .5]);
    hp3 = uipanel('position',[.5 .5 .5 .5]);
    hp4 = uipanel('position',[0.5 0 .5 .5]);
    hp = {hp1; hp2; hp3; hp4}; 
    %%%
for k = 1:4
    %%%
    h= scatterhist(alpha,((RR{k+1,:} ./ RR{1,:}) -1 )* 100,'Color','kbr',...
        'LineStyle',{'-','-.',':'},'Marker','+od','Parent',hp{k},'Group',groupflag);
    h(1).XLim = (x_lim); 
    h(1).YLim = ([-30,30]); 
    title('$\Delta RR = RR_{i+1}/RR_{i}$','Interpreter','latex')
    xlabel('$deg [^\circ]$','interpreter','latex'); 
    ylabel('$\Delta RR \quad [\%]$','interpreter','latex');
    %
    hold on;
    boxplot(h(2),alpha,groupflag,'orientation','horizontal',...
         'label',{'','',''},'color','kbr');
    boxplot(h(3),((RR{k+1,:} ./ RR{1,:}) -1 )* 100,groupflag,'orientation','horizontal',...
         'label', {'','',''},'color','kbr');
    set(h(2:3),'XTickLabel','');
    view(h(3),[270,90]);  % Rotate the Y plot
    hold off; 
end 
end 

 



