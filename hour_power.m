% 假设原始数据为一个 1440x30 的矩阵 data
% 每列有 1440 个数据，需要每 60 个求平均，一共求 24 个平均值

% 将每列的数据重塑为 24x60 的矩阵
%求出每天24小时的平均值
for i = 1:size(data,2)
    data_reshape = reshape(data(i).table, 60, 24, size(data(i).table,2));
    % 计算每列的平均值
    day(i).hour_power = squeeze(mean(data_reshape, 1));
end
%avg_data_3d = mean(data_reshape, 3);

%avg_data = reshape(avg_data_3d, 24, 31);

% mean_data 是一个 24x30 的矩阵，即每列有 24 个平均值，一共 30 列
