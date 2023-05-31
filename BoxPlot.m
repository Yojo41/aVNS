% BOX PLOT 
clear variables
clc
% % load data 
P1 = load('Patient1.mat'); 
P2 = load('Patient2.mat'); 
P3 = load('Patient3.mat'); 
P4 = load('Patient4.mat'); 
P5 = load('Patient5.mat'); 
a = [P1.af_stimRR{2,1};P2.af_stimRR{2,1};P3.af_stimRR{2,1};P4.af_stimRR{2,1};P5.af_stimRR{2,1}]; 
b = [P1.af_stimRR{1,1};P2.af_stimRR{1,1};P3.af_stimRR{1,1};P4.af_stimRR{1,1};P5.af_stimRR{1,1}]; 
data = (((a ./ b) -1) * 100);
c = [P1.stim_flag;P2.stim_flag;P3.stim_flag;P4.stim_flag;P5.stim_flag]; 
stimstr = ["Non-sync aVNS", "Systole-sync aVNS", "Diastole-sync aVNS"];
Var = stimstr(c)';
dataSet= [ones(1,length(P1.stim_flag)),2*ones(1,length(P2.stim_flag)),...
    3*ones(1,length(P3.stim_flag)),4*ones(1,length(P4.stim_flag)),...
    5*ones(1,length(P5.stim_flag))]';
    
    testData = table(data,dataSet,Var);
    h = boxplot(testData.data,{testData.dataSet,testData.Var},...
        'ColorGroup',testData.Var,'Colors','kbr',...
        'Labels',{'','Patient 1','','','Patient 2','','','Patient 3','','','Patient 4','','','Patient 5',''});
    ylim([-10,10]);
    hold on
    % set(gca,'XTickLabel',{' '})
    % Don't display outliers
    ol = findobj(h,'Tag','Outliers');
    set(ol,'Visible','off');
    % Find all boxes
    box_vars = findall(h,'Tag','Box');
    % Fill boxes
    for j=1:length(box_vars)
        patch(get(box_vars(j),'XData'),get(box_vars(j),'YData'),box_vars(j).Color,'FaceAlpha',.1,'EdgeColor','none');
    end
    % Add legend
    Lg = legend(box_vars(1:3), {'Non-sync aVNS','Systole-sync aVNS','Diastole-sync aVNS'},'Location','northoutside','Orientation','horizontal');
    %% Add Mean to boxplots  
    summaryTbl = groupsummary(testData,{'dataSet','Var'},"mean")
    plot(summaryTbl.mean_data, '+k')
    Lg.String{4} = 'mean';
    xline(3.5,'Linewidth',2,'HandleVisibility','off')
    xline(6.5,'Linewidth',2,'HandleVisibility','off')
    xline(9.5,'Linewidth',2,'HandleVisibility','off')
    xline(12.5,'Linewidth',2,'HandleVisibility','off')
