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
Consum = [1000 1500 2000 2500 3000 3500 4000]; % [kWh/a]

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
HPtable.T_init = repelem(21, height(HPtable))'; % randomisation?
HPtable.Tset = repelem(21, height(HPtable))';
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
s = 1:1:33;
t = 2:1:34;
s = [s 11 35:1:39];
t = [t 35:1:40];
s = [s 18 41:1:45];
t = [t 41:1:46];
s = [s 21 47:1:51];
t = [t 47:1:52];
% insulated-bundled
s = [s 1 53:1:66];
t = [t 53:1:67];
s = [s 60 68:1:73];
t = [t 68:1:74];
% cable
s = [s 1 75:1:88];
t = [t 75:89];

% edges
w(1:26) = "95lat";
w(27:51) = "50lat";
d(1:51) = 0.03; % [km] distance
w(52:66) = "95ins";
w(67:73) = "50ins";
d(52:73) = 0.03; % [km]
w(74:88) = "150cab";
d(74:88) = 0.03; % [km]

EdgeTable = table([s' t'], w', d', 'VariableNames', {'EndNodes', 'Type', 'Length'});

% network connection point
for i = 1:89
    switch mod(i, 3)
        case 0
            cells{i} = HH(1:3);
        case 1
            cells{i} = HH(4:6);
        otherwise
            cells{i} = HH(7);
    end
end
cells{88} = []; % no connection at this pole

NodeTable = table(cells', 'VariableNames', {'Households'});

G = graph(EdgeTable,NodeTable);

%% Plot graph
wirecolor = table(["#0072BD"; "#0072BD"; "#A2142F"; "#A2142F"; "k"], 'VariableNames', {'Color'}, 'RowNames', conductors); % could be stored in wiretypes
drawFromGraph(G, wirecolor);

%% Build Simulink model
buildFromGraph(G, wiretypes, 'example');
