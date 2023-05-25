function [] = output_plot(raw,edges,Fs,x1,prc,colMeans,beta,label,stimstr)
L=length(raw.data); 
t_signal = ((0:L-1)/Fs)';%time vector 
%% categorize the data 
edges2 = edges(2:end)-1;
edges(end) = [];
roitable = [t_signal(edges),t_signal(edges2)];
str(1:length(edges),1) = "Non-sync aVNs"; 
str(2,1) = "Systole-sync aVNS"; 
str(4,1) = "Diastole-sync aVNS";
c = categorical(str,unique(str,"stable"));
msk = signalMask(table(roitable,c),SampleRate=Fs,RightShortening=1);
%% Plot the data 
figure()
plotsigroi(msk,raw.data(:,4));
colorbar("off")
nc = 3;
colormap(gca,lines(nc));
colorbar(TickLabels=categories(c),Ticks=1/2/nc:1/nc:1, ...
TickLength=0,Location="northoutside")
xlabel('time [sec]')
%% PLOT Histogram of stimulation and normalized ECG 
nshift = round(300/360 * length(prc(1,:))); 
colMeans = circshift(colMeans,nshift); 
prc(1,:) = circshift(prc(1,:),nshift);
prc(2,:) = circshift(prc(2,:),nshift);
for k = 1:length(beta)
beta{k,1} = beta{k,1} + 300/360; 
    if beta{k,1} >= 1 
    beta{k,1} = beta{k,1} - 1; 
    end 
end  
x1 = rescale(x1,60,420); 
beta = rescale(cell2mat(beta),60,420); 
label = cell2mat(label); 
colorstr = ["k","b","r"]; 
% all in one 
figure()
sgtitle(['Normalized ECG and Stimulation location.' ...
    'Delay between Stimulation and ECG measurement is not considered yet.'] ...
    ,'color','red')
subplot(2,2,1)
yyaxis left
plot(x1,colMeans,'k','LineWidth',2,'DisplayName','Mean')
hold on
plot(x1,prc(1,:),'b--','DisplayName','25')
plot(x1,prc(2,:),'b:','DisplayName','75')
yyaxis right
for j = 1:3
h = histogram(beta(label==j),'BinWidth',11.7, ... 
  'DisplayName',stimstr(j),'FaceColor',colorstr(j)); 
title(['Total stimulations:',num2str(length(beta))])
xlabel('$deg [^\circ]$','interpreter','latex')
alpha(h,.2)
end 
grid minor
legend('Location','north')
% single plots 
for j = 1:3
subplot(2,2,j+1)
yyaxis left
plot(x1,colMeans,'k','LineWidth',2,'DisplayName','Mean')
hold on
plot(x1,prc(1,:),'b--','DisplayName','25')
plot(x1,prc(2,:),'b:','DisplayName','75')
yyaxis right
histogram(beta(label==j),'BinWidth',11.7, ... 
  'DisplayName',stimstr(j),'FaceColor',colorstr(j)) 
title(['Total stimulations:',num2str(length(beta(label==j)))])
grid minor
legend('Location','north')
end

