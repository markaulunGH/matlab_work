%%%这个脚本作用是统计各个月在0 10 20  40  60  80  100区间上的发电占比
%前提需要执行handle_data.m%%%
%用于后续的百分占比直方图
% 分成6个区间，并计算每个区间内的数据数量
edges = [0 0.0001 10 20  40  60  80  99];
sum_edges=size(edges,2)-1;
percentages=zeros(sum_edges,12);
cumPercent = zeros(sum_edges,12);
sum_power = zeros(sum_edges,12);
energy_power = zeros(sum_edges,12);
energy_percentages= zeros(sum_edges,12);
valid_hours     = zeros(1,12);
for i=1:size(data,2)
    [N, edges] = histcounts((data(i).table), edges);
    %记录每月出力小时数  
    sum_power(:,i)=N/60;
    % 计算每个区间内的数据总数
    total_count = sum(N);
    valid_hours(i) = sum(N(2:end))/60;
    %先排序，不知道能不能提高运行速度，
    v_sorted = sort(data(i).table(:));
    %计算各区间出力和%零出力区间不需要计算
    for j=2:sum_edges
        tmp=sum(v_sorted(v_sorted>=edges(j) &v_sorted < edges(j+1)))/60;
        energy_power(j,i)=tmp;
    end
    
    % 计算频数的累计和
    cumCounts = cumsum(N);
    % 计算每个区间内的数据占总数据量的百分比
    percentages(:,i) = N / total_count * 100;
    %计算每个区间的发电总量占总发电量的百分比
    energy_percentages(:,i)=energy_power(:,i)/mouth(i).sum*100;
    % 计算频数的累计百分比
    cumPercent(:,i) = cumCounts / total_count * 100;
end




% % 输出结果
% disp(total_count);
% disp("区间边界：");
% disp(edges);
% disp("区间数据占比（%）：");
% disp(percentages);