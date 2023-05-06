%加载数据脚本，执行其他命令之前需要执行本脚本
filename = 'G:\大一下\毕业设计多能互补\data\金伦+毕业论文材料\wind_power_data.xls';
sheetNames = {'1yue', '2yue', '3yue', '4yue', '5yue', '6yue', '7yue', '8yue', '9yue', '10yue', '11yue', '12yue'}; % 工作表名称
skipRows = 1; % 跳过每个工作表的第一行
for i = 1:length(sheetNames)
    sheetName = sheetNames{i};
    data(i).table = readtable(filename, 'Sheet', sheetName,'HeaderLines', skipRows); % 读取数据表格,并且从第二行开始读
    data(i).table = table2array(data(i).table); % table2array，方便计算 
end
total_year=0;%年出力
for i = 1:length(sheetNames)
    day(i).avg=nanmean(data(i).table);%计算一天中的平均值
    day(i).max  =max(data(i).table);%计算一天中的最大值
    day(i).min  =min(data(i).table);%计算一天中的最小值
    day(i).sum  =sum(data(i).table/60);%计算每天的总出力mw*h
    day(i).std  =std(data(i).table);%求标准差
    day(i).minute_avg=mean(data(i).table,2);  %求30天，的每天平均值
    mouth(i).max=max(day(i).avg); %计算一个月中的天平均的最大值
    mouth(i).min=min(day(i).avg); %计算一个月中的天平均的最小值
    mouth(i).sum=sum(day(i).sum);%计算一个月的总出力mw*h
    mouth(i).avg=mean(day(i).avg); %计算一个月中的天平均的平均值
    total_year=mouth(i).sum+total_year;%计算年出力
end

%处理风力数据，这里采用0.1小时精度，具体就是每相邻6分钟取平均值
%设置处理步长1小时的STEP为60
STEP=60;
for i=1:size(data,2)
    for j=1:size(data(i).table,2)
        for h=1:(size(data(i).table,1)/STEP)
            data_0_1h(i).table(h,j)=mean(data(i).table((h-1)*STEP+1:h*STEP,j));
        end
    end
    
end

%scatter(day(1).max);
% 定义要保存的文件夹和文件名前缀
folder = 'G:\大一下\毕业设计多能互补\data\plot_out'; % 文件夹名称
prefix1 = 'mouth_of_everyday'; % 文件名前缀
prefix = 'mouth';
% % % 循环生成和保存每个天平均值然后月的图
% for i = 1:12
%     % 生成第i个图
%     figure(i)
%     % 假设第i个图的变量名称为data_i
%     %plot(day(i).avg ,'m');
%     hold on;
%     %yyaxis left;
%     yyaxis left;
%     plot(day(i).max,'--r','LineWidth',1,'DisplayName', '最大出力'); %月最大画年上面%
%     plot(day(i).avg,'-m','LineWidth',2,'DisplayName', '平均出力'); %月平均画年上面%
%     %平均，发电量，%最大功率，最小功率
%     plot(day(i).min,'--g','LineWidth',1,'DisplayName', '最小出力'); %月最小画年上面%
%     %yyaxis right;
%     %ylabel('MW*h');
%     %plot(day(i).sum,'k','LineWidth',1.0,'DisplayName', '累计出力'); %月累计出力画上面%
%     ylabel('出力(MW)');
%     ylim([0, 110]);
%     yyaxis right;
%     plot(day(i).std,':b','LineWidth',1,'DisplayName', '标准差'); %月平均画年上面%
%     xlabel('日期(天数）');
%     ylabel("标准差(MW)")
%     ylim([0, 110]);
%     legend('Location', 'northeast','NumColumns', 2);
%     
%     % 设置坐标轴范围，方便查看
%     
%     xlim([1, 31]);
%     %title(i,'月出力图');
%     title(sprintf(' %d 月出力图', i),'FontName', '宋体', 'FontSize', 20);    
%      
%     % 生成文件名
%     plotname = [prefix, num2str(i), '.png'];
%                                                                                                                                                                                                               
%     % 拼接保存路径
%     savepath = fullfile(folder, plotname);
% 
%     width=700;
%     height=600;
% 
%     set(gcf, 'Units', 'pixels','Position', [100 100 width height]);%设置长宽比
%     set(gca, 'LooseInset', get(gca, 'TightInset'));
%     
%     % 保存图
%     saveas(gcf, savepath);
%     hold off;
%     % 关闭当前窗口
%     close;
% end
% % 循环生成和保存每个图
% %画一个月所有天数的出力图
% for i = 1:12
%     % 生成第i个图
%     figure(i)
%     % 假设第i个图的变量名称为data_
% 
%     hold on;
%     colors = hsv(31);%生成31种不同的颜色
%     for j=1:size(data(i).table,2)
%         %colData = data(i).table(:, j);
%         plot(data(i).table(:, j),'Color',colors(j,:),'LineWidth',0.5);
%         
%     end
%     %画平均值
%     plot(day(i).minute_avg ,'k','LineWidth',1.5);
%     
%     xlabel('时段(分钟）');
%     ylabel('出力(MW)');
%     % 设置坐标轴范围，方便查看
%     ylim([0, 100]);
%     xlim([1, 1440]);
%     % 设置 x 轴和 y 轴的标记值
% 
%     title(sprintf(' %d 月每天出力图', i),'FontName', '宋体', 'FontSize', 20);
%     %自动裁掉空白部分
%     %tightfig(gcf);
% 
%     % 修改 X 轴刻度
%     % 设置x轴刻度
%     set(gca, 'XTick', [ 300 600 900 1200 1440]); %
%     
% 
%     
%     % 生成文件名
%     plotname = [prefix1, num2str(i), '.png'];
%     % 拼接保存路径
%     savepath = fullfile(folder, plotname);
% 
%     width=700;
%     height=600;
%     %TightInset 表示获取 axes 的 tight inset（紧凑的内边距），LooseInset 表示设置 axes 的 loose inset（宽松的内边距）。
%     % 通过将 LooseInset 设置为 TightInset，可以确保图像的边距最小化。
%     set(gcf, 'Units', 'pixels','Position', [100 100 width height]);%设置长宽比
%     set(gca, 'LooseInset', get(gca, 'TightInset'));
% 
% 
%     % 保存图
%     saveas(gcf, savepath)
%     %print(savepath, '-dpng', '-r0');
%     % 关闭当前窗口
%     hold off;
%     close;
% end

%total
year_power=mean([mouth.avg]);
hold on;
yyaxis left;
ylabel('MW');
ylim([0, 80]);
plot([mouth.avg],'color',[0 0.4470 0.7410],'LineWidth',1.5,'DisplayName', '平均出力'); %月平均画年上面%
%月平均，发电量，%最大功率，最小功率
plot([mouth.max],'r','LineWidth',1.5,'DisplayName', '最大出力'); %月最大画年上面%
plot([mouth.min],'g','LineWidth',1.5,'DisplayName', '最小出力'); %月最小画年上面%
yyaxis right;
ylabel('MW*h');
plot([mouth.sum],'k','LineWidth',1.5,'DisplayName', '累计出力'); %月累计出力画上面%
legend('Location', 'best');
xlabel('月份');
% 设置坐标轴范围，方便查看

xlim([1, 12]);
%title(i,'月出力图');
title(sprintf("各月出力图"), 'FontName', '宋体', 'FontSize', 20);
hold off;
