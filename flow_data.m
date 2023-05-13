%%%%%%%%%%%%%%%%%%%%%%%%%%注意%注意%注意%%%%%%%%%%%%%%%%%%%%%
%% 执行的前提是，需要执行加载数据的脚本 handle_data.m%%
%%需要handle_data.m 处理的风电场月平均出力%%
%本脚本暂未设置自动保存，需要手动保存绘出的折线图
%流量数据文件夹，这里处理流量数据的时候只按照特定文件进行设计
%如果需要处理其他流量的数据文件，可能需要对下面的处理过程进行修改
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


flow_filename='G:\大一下\毕业设计多能互补\data\金伦+毕业论文材料\flow_data.xls';
sheetnames='total';

% 读取数据
tmp_data=readtable(flow_filename);
flow    = tmp_data{:,2};

% 转换日期格式
dates = datetime(tmp_data{:, 1}, 'InputFormat', 'yyyy/MM/dd');
flow_table = timetable(dates, flow); %创建timetable对象
% 计算每个月的平均值,最小值，最大值
%monthly_mean_flow = retime(table(dates, tmp_data{:, 2}), 'monthly', 'mean');
monthly_mean_flow = retime(flow_table,'monthly', 'mean');
% 将每个月的平均值存储在一个数组中
monthly_means = monthly_mean_flow{:, 1};
%按年进行划分
years_num = length(monthly_means)/12;
years_flow = zeros(12,years_num);
yyaxis right;

line_wind=plot([mouth.avg],'r','LineWidth',1.5,'DisplayName', '风电场平均出力'); %月平均画年上面%
ylabel("风电场出力(MW)");

yyaxis left;
for i=1:years_num
       years_flow(:,i)=monthly_means((i-1)*12+1:i*12);
end
%计算一些特征值
total_mouth_avg=mean(years_flow,2);
flow_max        =max((years_flow'));
flow_min        =min((years_flow'));
flow_std        =std((years_flow'));
    %画平均值
line_flow=plot(total_mouth_avg ,'k','LineWidth',1.5,'DisplayName', '平均来水流量');
    
    xlabel('月份');
    ylabel('流量(立方米每秒）');
    % 设置坐标轴范围，方便查看
    %ylim([0, 100]);
    xlim([1, 12]);
    % 设置 x 轴和 y 轴的标记值

    title(sprintf('多年来水流量图'),'FontName', '宋体', 'FontSize', 20);

    % 生成第i个图
    figure(1)
    % 假设第i个图的变量名称为data_

    hold on;
    colors = hsv(years_num);%生成不同的颜色
    for j=30:years_num
        plot(years_flow(:, j),'Color',colors(j,:),'LineWidth',0.5,'DisplayName','');
    end

    width=800;
    height=600;
    %TightInset 表示获取 axes 的 tight inset（紧凑的内边距），LooseInset 表示设置 axes 的 loose inset（宽松的内边距）。
    % 通过将 LooseInset 设置为 TightInset，可以确保图像的边距最小化。
    set(gcf, 'Units', 'pixels','Position', [100 100 width height]);%设置长宽比
    set(gca, 'LooseInset', get(gca, 'TightInset'));
    hold off;
%只设置部分需要设置图例的曲线
legend([line_flow,line_wind] ,'平均来水流量','风电场平均出力');
% 检查结果
disp(length(monthly_means));  % 输出：456
