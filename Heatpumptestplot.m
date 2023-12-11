%% Heat Pump test
% Baseline, Superheat, Off
fig = figure;
fig.Units = 'centimeters';
fig.Position = [1 1 16 8]; % [left bottom width height]
t = tiledlayout(5,1, 'TileSpacing', 'none');
color = ['g'; 'r'; 'b'];
for i = 1:3
    nexttile;
    stairs(out.TemP{2*i-1}.Values.Time, real(out.TemP{2*i-1}.Values.Data), 'Color', color(i), 'LineWidth', 2);
    ylim([-200 4200]);
    yticks([]);
    xticks([]);
    ylabel(char('a' + i - 1), 'FontSize', 8, 'FontWeight', 'bold');
    axs(i) = gca;
end
nexttile([2 1]);
hold on;
for i = 3:-1:1
    plot(out.TemP{2*i}.Values.Time, real(out.TemP{2*i}.Values.Data), 'Color', color(i), 'LineWidth', 2);
end
hold off;
box on;
ylim([20 23]);
yticks(20.5:0.5:22.5);
axs(4) = gca;
set(axs(4), 'YGrid', 'on', 'XGrid', 'off');
ylabel('T [°C]', 'FontSize', 8, 'FontWeight', 'bold');
set(axs(4), 'FontSize', 8);

patch(axs(2), [5 6 6 5 5], [-200 -200 4200 4200 -200], 'red', 'FaceAlpha', 0.25, 'EdgeColor', 'none');
patch(axs(3), [6 7 7 6 6], [-200 -200 4200 4200 -200], 'blue', 'FaceAlpha', 0.25, 'EdgeColor', 'none');

xlabel(t, 'Idő [h]', 'FontSize', 8, 'FontWeight', 'bold');

%% Superheat vs On
fig2 = figure;
fig2.Units = 'centimeters';
fig2.Position = [1 1 16 6]; % [left bottom width height]
t2 = tiledlayout(4,1, 'TileSpacing', 'none');

% Superheat
nexttile;
stairs(out.TemP{3}.Values.Time, real(out.TemP{3}.Values.Data), 'Color', 'red', 'LineWidth', 2);
ylim([-200 4200]);
yticks([]);
xticks([]);
ylabel(["Super-"; "heat"], 'FontSize', 8, 'FontWeight', 'bold');
axs2(1) = gca;
patch([5 6 6 5 5], [-200 -200 4200 4200 -200], 'red', 'FaceAlpha', 0.25, 'EdgeColor', 'none');

% On
nexttile;
stairs(out.TemP{7}.Values.Time, real(out.TemP{7}.Values.Data), 'Color', 'magenta', 'LineWidth', 2);
ylim([-200 4200]);
yticks([]);
xticks([]);
ylabel('On', 'FontSize', 8, 'FontWeight', 'bold');
axs2(2) = gca;
patch([5 6 6 5 5], [-200 -200 4200 4200 -200], 'magenta', 'FaceAlpha', 0.25, 'EdgeColor', 'none');

nexttile([2 1]);
hold on;
plot(out.TemP{4}.Values.Time, real(out.TemP{4}.Values.Data), 'Color', 'red', 'LineWidth', 2);
plot(out.TemP{8}.Values.Time, real(out.TemP{8}.Values.Data), 'Color', 'magenta', 'LineWidth', 2);
hold off;
box on;
ylim([20 23]);
yticks(20.5:0.5:22.5);
axs2(3) = gca;
set(axs2(3), 'YGrid', 'on', 'XGrid', 'off');
ylabel('T [°C]', 'FontSize', 8, 'FontWeight', 'bold');
set(axs2(3), 'FontSize', 8);

xlabel(t2, 'Idő [h]', 'FontSize', 8, 'FontWeight', 'bold');