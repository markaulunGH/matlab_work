%%%这是主要脚本，提供一些基本的环境检测以及其他脚本的检测%%%%

disp('=======>Runing main.m ...<=======');
disp('=====>Main:Chicking Sourece data ...');
check_file('.\source_data\wind_power_data.xls');
check_file('.\source_data\flow_data.xls');
disp('=====>Main:Chicking Script ...');
check_file('handle_data.m');
check_file('kmeans.m');
check_file('flow_data.m');
check_file('NSGA.m');
check_file('Pareto.m');
disp('=====>Main:Chick Script PASS');
%run('handle_data.m');
run('kmeans.m');
run('flow_data.m');
run('NSGA.m');
run('Pareto.m');

disp('=======>Main.m:Done.Exit.<=======');

% if exist('./kmens.m','file')==2
%     disp('=====>Exist kmeans.m');
% else
%     disp('!!!!!!ERROR :Not found kmeans.m,Please check!!!!!!!')
% end

function check_file(file_name)
    if exist(file_name,'file')==2
        fprintf("=====>Exist %s\n",file_name);
    else
        assert(0,'=====>ERROR:%s.EXIT.',file_name);
    end

end