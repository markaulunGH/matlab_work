
% 执行的前提是，需要执行加载数据的脚本

% 对样本进行聚类，选择 k=3
%[idx, centroids] = kmeans(normalized_samples, 3);

% 得到聚类结果，每个聚类中心即为一个典型出力代表日
%12个月总的典型日
all_ty_days =  zeros(12, 5, 1440);%minutes
all_ty_days_01h =  zeros(12, 5, size(data_0_1h(1).table,1));%

folder = 'G:\大一下\毕业设计多能互补\data\plot_out'; % 文件夹名称
prefix_ty = 'typical_days_of_mouth'; % 文件名前缀
%生成0.1小时的kmeans聚类数据；
for i =1:12
    % 将其按天进行分割，得到 天数 个样本，每个样本包含 24*60=1440 个数据点
    samples_01h = reshape(data_0_1h(i).table, size(data_0_1h(i).table,1), size(data_0_1h(i).table,2))';

    % 对样本进行聚类，选择 k=5
    [idx_0_1h, centroids_0_1h] = kmeans(samples_01h, 5);

    % 得到聚类结果，每个聚类中心即为一个典型出力代表日

    typical_days_01h = centroids_0_1h;
    all_ty_days_01h(i,:,:) =centroids_0_1h;
    % 生成第i个图  

end
% 定义要保存的文件夹和文件名前缀
% % 循环生成和保存每个天平均值然后月的图
% for i = 1:12
%     % 将其按天进行分割，得到 天数 个样本，每个样本包含 24*60=1440 个数据点
%     samples = reshape(data(i).table, size(data(i).table,1), size(data(i).table,2))';
% 
%     % 对样本进行聚类，选择 k=5
%     [idx, centroids] = kmeans(samples, 5);
% 
%     % 得到聚类结果，每个聚类中心即为一个典型出力代表日
% 
%     typical_days = centroids;
%     all_ty_days(i,:,:) =centroids;
%     % 生成第i个图
%     
%     figure(i)
%     % 假设第i个图的变量名称为data_
% 
%     hold on;
%     colors = hsv(size(typical_days,1));%生成5种不同的颜色
%     for j=1:size(typical_days,1)
%         %colData = data(i).table(:, j);
%         plot(typical_days(j,:),'Color',colors(j,:),'LineWidth',0.5);
%         
%     end
%     
%     xlabel('时段(分钟）');
%     ylabel('出力(MW)');
%     % 设置坐标轴范围，方便查看
%     ylim([0, 100]);
%     xlim([0, 1440]);
%     % 设置 x 轴和 y 轴的标记值
% 
%     title(sprintf(' %d 月典型日出力过程图', i),'FontName', '宋体', 'FontSize', 20);
%     % 修改 X 轴刻度
%     % 设置x轴刻度
%     set(gca, 'XTick', [0 360 720 1080 1440]); %
%     
%     
%     % 生成文件名
%     plotname = [prefix_ty, num2str(i), '.png'];
%     % 拼接保存路径
%     savepath = fullfile(folder, plotname);
% 
%     width=700;
%     height=600;
% 
%     set(gcf, 'Position', [100 100 width height]);%设置长宽比
%     
%     % 保存图
%     saveas(gcf, savepath)
%     % 关闭当前窗口
%     hold off;
%     close;
% end
