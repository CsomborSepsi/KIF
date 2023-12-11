%% Wires
conductors = {'95lat', '50lat', '95ins', '50ins', '150cab'};
r = ["296.8421e-003 446.8421e-003", "564.0000e-003 714.0000e-003", "296.8421e-003 446.8421e-003", "263.6030e-006 6.8471e-003", "188.0000e-003 338.0000e-003"];
l = ["953.5880e-006 5.4671e-003", "1.0178e-003 5.5313e-003", "263.6030e-006 6.8471e-003", "270.2520e-006 7.0263e-003", "630.6533e-006 5.9760e-003"];
c = ["12.4583e-009 3.9055e-009", "11.6151e-009 3.8190e-009", "52.0885e-009 2.6280e-009", "50.5161e-009 2.5213e-009", "872.4959e-009 872.4959e-009"];
r = append('[', r, ']');
l = append('[', l, ']');
c = append('[', c, ']');

wiretypes = table(r', l', c', 'VariableNames', {'r', 'l', 'c'}, 'RowNames', conductors);

%% Household types
% Consumption
Consum = [1000 1500 2000 2500 3000 3500 4000] * 12; % [kWh/a]

% Photovoltaic
PV_P = round(Consum / 1300 * 1000, -2); % [W] 1 kW peak / 1300 kWh/a
PV = table2struct(table(PV_P', 'VariableNames', {'P'}));

% Battery
ESc2p = @(x) 439.21 * x + 1277.8; % Power vs Capacity from linear regression on manufacturer data
ES_C = round(Consum / 365 * 2 / 0.6 * 1000, -2); % [Wh] 2 days bridging time, 60 % DoD
ES_P = round(ESc2p(ES_C / 1000), -2); % [W]
ES_SoCin = linspace(0.2, 0.8, 7);
ES = table2struct(table(ES_C', ES_P', ES_SoCin', 'VariableNames', {'C', 'P', 'SoCin'}));

% Heat Pump
HP_Ts = 0.05; % 1s ~ 1h -> 0.05s -> 3min
HP_Teqv = 3; % minutes
HPtable = readtable("heatpump.xlsx");
HPtable.T_init = repelem(21, height(HPtable))';
HPtable.Tset = repelem(0, height(HPtable))';
HP = table2struct(HPtable);

% Household types
for i=1:numel(Consum)
    HH(i) = struct('Phase', char('a' + mod(i-1,3)), 'Consum', ['CONS' num2str(i)], 'PV', PV(i), 'ES', ES(i), 'HP', HP(i));
end
% modifying some values for demonstration purposes
HH(end).Phase = 'abc';
HH(end-1).PV.P = min(HH(6).PV.P, 2500);

%% Construct Graph
% nodes
% lateral overhead line
s = 1:1:7;
t = 2:1:8;

% edges
w(1:7) = "95lat";
d(1:7) = 0.120; % [km] distance

EdgeTable = table([s' t'], w', d', 'VariableNames', {'EndNodes', 'Type', 'Length'});

% network connection points
for i = 2:8
    cells{i} = HH(i-1);
end
cells{1} = []; % no connection at this pole

NodeTable = table(cells', 'VariableNames', {'Households'});

G = graph(EdgeTable,NodeTable);

%% Plot graph
wirecolor = table(["#0072BD"; "#0072BD"; "#A2142F"; "#A2142F"; "k"], 'VariableNames', {'Color'}, 'RowNames', conductors); % could be stored in wiretypes
drawFromGraph(G, wirecolor);

%% Build Simulink model
buildFromGraph(G, wiretypes, 'demonstration');
