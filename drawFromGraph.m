function [fig, h] = drawFromGraph(G, wirecolor)
    fig = figure;
    fig.Units = 'centimeters';
    fig.Position = [1 1 16 8]; % [left bottom width height]
    axes('Units', 'normalized', 'Position', [0.005 0.005 0.99 0.99]);
    width = str2double(extractBefore(G.Edges.Type, strlength(G.Edges.Type) - 2)) / 50 * 3;
    G.Edges.Weight = repelem(1, G.numedges)';
    h = plot(G,'Layout', 'force', 'WeightEffect', 'direct', 'Iterations', 65, 'LineWidth', width, 'NodeColor', 'black', 'EdgeColor', 'k', 'NodeLabel', {}, 'MarkerSize', 3);
    highlight(h, 1, 'NodeColor', 'red', 'Marker', 'square', 'MarkerSize', 8); % startnode (i. e. transformer)
    for i = 1:height(wirecolor)
        highlight(h, 'Edges', find(G.Edges.Type == wirecolor.Properties.RowNames(i)), 'EdgeColor', wirecolor.Color(i));
    end
    h.NodeFontSize = 12;
end