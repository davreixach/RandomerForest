%% Plot posterior heat maps

clear
close all
clc

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);

%PageWidth = 8.5;
%PageHeigth = 11;

%FigPosition = [0 0 8.5 11];
LineWidth = 2;
FontSize = .2;
axWidth = 2;
axHeight = 2;
axLeft = [FontSize*4 FontSize*8+axWidth FontSize*4 FontSize*8+axWidth];
axBottom = [FontSize*8+axHeight FontSize*8+axHeight FontSize*4 FontSize*4];
cbWidth = .25;
cbHeight = axHeight;
cbLeft = axLeft(4) + axWidth + FontSize;
cbBottom = [axBottom(2) axBottom(4)];
figWidth = cbLeft + cbWidth + FontSize*4;
figHeight = axBottom(1) + axHeight + FontSize*4;

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);

runSims = false;

if runSims
    run_sparse_parity_posteriors
else
    load Sparse_parity_true_posteriors.mat
    load Sparse_parity_posteriors_npoints_50.mat
end

clNames = {'RF' 'RerF' 'RotRF' 'Posterior'};

figure('visible','off')
p1 = posterior_map(Xpost,Ypost,mean(rf.posteriors,3));
xlabel('X_1')
ylabel('X_2')
t(1) = title(['(A) ' clNames{1}]);
ax_old(1) = gca;
c(1) = findobj(gcf,'Type','ColorBar');

figure('visible','off')
p2 = posterior_map(Xpost,Ypost,mean(rerf.posteriors,3));
xlabel('X_1')
ylabel('X_2')
t(2) = title(['(B) ' clNames{2}]);
ax_old(2) = gca;
c(2) = findobj(gcf,'Type','ColorBar');

figure('visible','off')
p3 = posterior_map(Xpost,Ypost,mean(rf_rot.posteriors,3));
xlabel('X_1')
ylabel('X_2')
t(3) = title(['(C) ' clNames{3}]);
ax_old(3) = gca;
c(3) = findobj(gcf,'Type','ColorBar');

cmin = min([p1.CData(:);p2.CData(:);p3.CData(:)]);
cmax = max([p1.CData(:);p2.CData(:);p3.CData(:)]);

for i = 1:3
    figure(i)
    caxis([cmin cmax])
end

figure('visible','off')
p4 = posterior_map(Xpost,Ypost,mean(truth.posteriors,3));
xlabel('X_1')
ylabel('X_2')
t(4) = title(['(D) ' clNames{4}]);
ax_old(4) = gca;
c(4) = findobj(gcf,'Type','ColorBar');

cmin = min(p4.CData(:));
cmax = max(p4.CData(:));

caxis([cmin cmax])

fig = figure;
fig.Units = 'inches';
fig.PaperUnits = 'inches';
fig.Position = [0 0 figWidth figHeight];
fig.PaperPosition = [0 0 figWidth figHeight];
for j = 1:4
    figure(fig)
    ax = subplot(2,2,j);
    newHandle = copyobj(allchild(ax_old(j)),ax);
    ax.Title.String = ax_old(j).Title.String;
    ax.XLabel.String = ax_old(j).XLabel.String;
    ax.YLabel.String = ax_old(j).YLabel.String;
    ax.XLim = ax_old(j).XLim;
    ax.YLim = ax_old(j).YLim;
    ax.LineWidth = LineWidth;
    ax.FontUnits = 'inches';
    ax.FontSize = FontSize;
    ax.Units = 'inches';
    ax.Position = [axLeft(j) axBottom(j) axWidth axHeight];
    ax.XTick = [];
    ax.YTick = ax.XTick;
    ax.TickDir = 'out';
    ax.TickLength = [.02 .03];

    if j == 2
        cb = colorbar;
        cb.Units = 'inches';
        cb.Position = [cbLeft cbBottom(1) cbWidth cbHeight];
        cb.Box = 'off';
        colormap(ax,'parula')
        cb.Ticks = .45:.025:.525;
    elseif j == 4
        cb = colorbar;
        cb.Units = 'inches';
        cb.Position = [cbLeft cbBottom(2) cbWidth cbHeight];
        cb.Box = 'off';
        colormap(ax,'jet')
    else
        colormap(ax,'parula')
    end
    caxis(c(j).Limits)
end

save_fig(gcf,[rerfPath 'RandomerForest/Figures/Sparse_parity_posteriors'])