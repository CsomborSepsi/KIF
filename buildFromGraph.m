function buildFromGraph(G, wiretypes, name)
    warnStruct = warning('off', 'Simulink:Commands:SetParamLinkChangeWarn'); % generating parameterized links on purpose

    % TODO: error handling :(

    system = new_system(name);
    open_system(system);

    dfs = dfsearch(G, 1, {'discovernode', 'finishnode', 'edgetonew'});
    dfs(1,:) = []; % omit first node
    assert(dfs.Event(1) == 'edgetonew', 'Firs event after startnode must be edgetonew.');
    assert(~hascycles(G), 'Graph must be tree.');
    [~, binsizes] = conncomp(G);
    assert(numel(binsizes) == 1, 'Graph must be connected.');
    
    % Count houses
    numhouses = 0;
    maxhouses = 0;
    for i = 1:G.numnodes
        atnode = length(G.Nodes.Households{i, 1});
        numhouses = numhouses + atnode;
        if atnode > maxhouses
            maxhouses = atnode;
        end
    end

    % Preallocate memory
    wires = double.empty(0, G.numedges);
    houses = double.empty(0, numhouses);
    housecntr = 0;

    % Add first wire
    iedge = dfs.EdgeIndex(1);
    type = G.Edges.Type(iedge);
    wires(iedge) = add_block('kif2/Wire', [name '/Wire' num2str(iedge)]);
    set_param(wires(iedge), ...
        'Length', num2str(G.Edges.Length(iedge)), ...
        'Resistances', wiretypes.r(type), ...
        'Inductances', wiretypes.l(type), ...
        'Capacitances', wiretypes.c(type), ...
        'Vtag', ['V_L' num2str(iedge)], 'Vtagv', 'global', ...
        'Itag', ['I_L' num2str(iedge)], 'Itagv', 'global');
    whandles(iedge) = get_param(wires(iedge), 'PortHandles');

    pos = get_param(wires(iedge), 'Position'); % [left top right bottom]
    w_wire = pos(3) - pos(1); % width
    h_wire = pos(4) - pos(2); % height
    dpv = [2*w_wire 0 2*w_wire 0]; % delta position vertical
    dph = [0 1.5*h_wire 0 1.5*h_wire]; % delta position horizontal
    odbp = 1; % optical distance between poles (Simulink model appearance)

    % Add wires and connect them to houses
    for i = 2:1:height(dfs)
        switch dfs.Event(i)
            case 'edgetonew'
                % Add wire
                iedge = dfs.EdgeIndex(i);
                type = G.Edges.Type(iedge);                
                wires(iedge) = add_block('kif2/Wire', [name '/Wire' num2str(iedge)]);                
                set_param(wires(iedge), ...
                'Length', num2str(G.Edges.Length(iedge)), ...
                'Resistances', wiretypes.r(type), ...
                'Inductances', wiretypes.l(type), ...
                'Capacitances', wiretypes.c(type), ...
                'Vtag', ['V_L' num2str(iedge)], 'Vtagv', 'global', ...
                'Itag', ['I_L' num2str(iedge)], 'Itagv', 'global');
                pos = pos + dpv*odbp;
                set_param(wires(iedge), 'Position', pos);
                whandles(iedge) = get_param(wires(iedge), 'PortHandles');

                % Connect to network (i. e. previous wire/edge)
                fromnode = dfs.Edge(i, 1);
                fromedge = dfs.EdgeIndex(dfs.Edge(:,2) == fromnode);
                if ~isempty(fromedge)
                    % It's not the start node (i. e. transformer)
                    for j = 1:3
                        add_line(system, whandles(fromedge).RConn(j), whandles(iedge).LConn(j));
                    end
                end

            case 'discovernode'
                node = G.Nodes.Households{dfs.Node(i), 1};
                % Add and connect houses
                for j = 1:length(node)
                    housecntr = housecntr + 1;
                    ns = num2str(housecntr);
                    hhname = [name '/HH' ns];
                    if length(node(j).Phase) == 3 % Three Phase
                        houses(housecntr) = add_block('kif2/Household', hhname);
                    else % Single Phase
                        houses(housecntr) = add_block('kif2/Household (Single Phase)', hhname);
                    end                    
                    hhandles(housecntr) = get_param(houses(housecntr), 'PortHandles');
                    set_param(houses(housecntr), 'Position', pos + dph * j + dpv);

                    % Connect phases
                    if length(node(j).Phase) == 3 % Three Phase
                        for k = 1:3                            
                            add_line(system, whandles(iedge).RConn(k), hhandles(housecntr).LConn(k));
                        end
                    else % Single Phase
                        add_line(system, whandles(iedge).RConn(node(j).Phase - 'a' + 1), hhandles(housecntr).LConn(1));
                    end

                    % Consumption
                    set_param(houses(housecntr), 'Ctag', node(j).Consum);
                    
                    % Photovoltaic
                    set_param([hhname '/PV'], ...
                        'P_STCm', num2str(node(j).PV.P));
                                        
                    % Battery
                    set_param([hhname '/ES'], ...
                        'Cap', num2str(node(j).ES.C), ...
                        'Pin', num2str(node(j).ES.P), ...
                        'Pout', num2str(-node(j).ES.P), ...
                        'SoCin', num2str(node(j).ES.SoCin));
                    
                    % Heat Pump
                    set_param([hhname '/HP'], ...
                        'P_HP', num2str(node(j).HP.P), ...
                        'C', num2str(node(j).HP.C), ...
                        'H', num2str(node(j).HP.H), ...
                        'T_init', num2str(node(j).HP.T_init), ...
                        'Tset', num2str(node(j).HP.Tset));

                    % Weather
                    set_param(houses(housecntr), ...
                        'Itag', 'Irrad', ...
                        'Ttag', 'T_Amb', ...
                        'Wtag', 'Wind');

                    % Measurements
                    set_param(houses(housecntr), ...
                        'PVtag', ['PQ_PV' ns], 'PVtagv', 'global', ...
                        'EStag', ['PQ_ES' ns], 'EStagv', 'global', ...
                        'HPtag', ['PQ_HP' ns], 'HPtagv', 'global', ...
                        'HHtag', ['PQ_HH' ns], 'HHtagv', 'global');

                end

            case 'finishnode'
                pos = pos - dpv*odbp; % go back
                if (i + 1 <= height(dfs)) && (dfs.Event(i+1) ~= "finishnode")
                    pos = pos + dph * (maxhouses + 1); % start new line (+2 might look better?)
                end
        end
    end

    warning(warnStruct); % Restore previous warning state
end