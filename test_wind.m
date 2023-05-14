% 导入风电场出力数据，假设数据存储在变量 power 中
%%前提需要执行handle_data.m%%%
%绘图，绘制全年日出力标准差
power = [data.table];
% 计算风电场出力的统计信息
power_mean = mean(power); % 计算均值
power_std = std(power); % 计算标准差
power_var = var(power); % 计算方差
power_kurt = kurtosis(power); % 计算峰度
power_skew = skewness(power); % 计算偏度



plot(power_std);

xlim([1, 366]);   
power_std_std=std(power_std);
power_std_mean=mean(power_std);
title(sprintf("全年日出力标准差"), 'FontName', '宋体', 'FontSize', 20);
xlabel('天数');
ylabel('MW');