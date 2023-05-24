%%功能，加载风力出力数据和流量数据%%

%加载数据脚本，执行其他命令之前需要执行本脚本
%设置存放数据文件的地方，这里使用的是与handle_data.m同级目录下的数据文件
%这里建议使用绝对路径，或者将数据与脚本文件设置到同一文件夹下面
disp('=======>Runing handle_data.m<===========');
filename = '.\source_data\wind_power_data.xls';
% 定义要保存的文件夹和文件名前缀
%请使用绝对路径，默认保存位置不确定
if not(isfolder('./photo'))
    mkdir('./photo');
end
if not(isfolder('./photo'))
    assert(0,'!!!ERROE:Can not found floder, Please Check right!!!')
end

folder = './photo'; % 文件夹名称
prefix1 = 'mouth_of_everyday'; % 文件名前缀
prefix = 'mouth';% 文件名前缀
% 工作表名称,方便集中处理
sheetNames = {'1yue', '2yue', '3yue', '4yue', '5yue', '6yue', '7yue', '8yue', '9yue', '10yue', '11yue', '12yue'};
% 跳过每个工作表的第一行%第一行是无用信息
skipRows = 1; 
disp('=======>Load wind power data ...<===========');
%从xls读取数据到matlab中
for i = 1:length(sheetNames)
    sheetName = sheetNames{i};
    data(i).table = readtable(filename, 'Sheet', sheetName,'HeaderLines', skipRows); % 读取数据表格,并且从第二行开始读
    data(i).table = table2array(data(i).table); % table2array，方便计算 
end
disp('=======>Load wind power data succeed<===========');
total_year=0;%年出力
%计算一些特征值
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
disp('=======>Begin draw photo in folder: ./photo <===========');
%scatter(day(1).max);
% % % % 循环生成和保存每个天平均值然后月的图
for i = 1:12
    % 生成第i个图
    figure(i)
    %使多个图绘制到同一个图上面
    hold on;
    %画左边y轴的图像
    yyaxis left;
    plot(day(i).max,'--r','LineWidth',1,'DisplayName', '最大出力'); %月最大画年上面%
    plot(day(i).avg,'-m','LineWidth',2,'DisplayName', '平均出力'); %月平均画年上面%
    %平均，发电量，%最大功率，最小功率
    plot(day(i).min,'--g','LineWidth',1,'DisplayName', '最小出力'); %月最小画年上面%
    %左y轴标记
    ylabel('出力(MW)');
    %左y轴的范围
    ylim([0, 110]);
    %画右轴%其实这里不一定需要右轴
    yyaxis right;
    plot(day(i).std,':b','LineWidth',1,'DisplayName', '标准差'); %月平均画年上面%
    xlabel('日期(天数）');
    ylabel("标准差(MW)")
    ylim([0, 110]);
    %图例的位置和图例的行数
    legend('Location', 'northeast','NumColumns', 2);
    % 设置坐标轴范围，方便查看
    xlim([1, 31]);
    %图的标题，可以循环设置每一个月的情况
    title(sprintf(' %d 月出力图', i),'FontName', '宋体', 'FontSize', 20);    
    % 生成文件名
    plotname = [prefix, num2str(i), '.png'];                                                                                                                                                                                                      
    % 拼接保存路径
    savepath = fullfile(folder, plotname);
    %设置图片长宽
    width=700;
    height=600;
    %设置长宽比和图框的出现的位置
    set(gcf, 'Units', 'pixels','Position', [100 100 width height]);%设置长宽比
    %设置图片空白边最小
    set(gca, 'LooseInset', get(gca, 'TightInset'));
    % 保存图
    saveas(gcf, savepath);
    hold off;
    % 关闭当前窗口
    close;
end
% % 循环生成和保存每个图
% %画一个月所有天数的出力图
for i = 1:12
    % 生成第i个图
    figure(i)
    hold on;
    colors = hsv(31);%生成31种不同的颜色
    for j=1:size(data(i).table,2)
        plot(data(i).table(:, j),'Color',colors(j,:),'LineWidth',0.5);
    end
    %画平均值
    plot(day(i).minute_avg ,'k','LineWidth',1.5);
    xlabel('时段(分钟）');
    ylabel('出力(MW)');
    % 设置坐标轴范围，方便查看
    ylim([0, 100]);
    xlim([1, 1440]);
    % 设置 x 轴和 y 轴的标记值
    title(sprintf(' %d 月每天出力图', i),'FontName', '宋体', 'FontSize', 20);
    % 设置x轴刻度
    set(gca, 'XTick', [ 300 600 900 1200 1440]); %
    % 生成文件名
    plotname = [prefix1, num2str(i), '.png'];
    % 拼接保存路径
    savepath = fullfile(folder, plotname);
    width=700;
    height=600;
    %TightInset 表示获取 axes 的 tight inset（紧凑的内边距），LooseInset 表示设置 axes 的 loose inset（宽松的内边距）。
    % 通过将 LooseInset 设置为 TightInset，可以确保图像的边距最小化。
    set(gcf, 'Units', 'pixels','Position', [100 100 width height]);%设置长宽比
    set(gca, 'LooseInset', get(gca, 'TightInset'));
    % 保存图
    saveas(gcf, savepath)
    hold off;
    % 关闭当前窗口
    close;
end

%风电场月平均，发电量，%最大功率，最小功率画图
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
title(sprintf("各月出力图"), 'FontName', '宋体', 'FontSize', 20);
saveas(gcf, './photo/mouth_mean.png')
hold off;
close;
disp('=======>Draw photo Done <===========');
disp('=======>hand_data.m Done <===========');
disp('Checking kmeans.m...')
if exist('./source_data/all_ty_days_01h.mat','file')==2
    disp('Exist kmeans.m');
    disp('Beging execute kmeans.m');
    run('kmens.m');
else
    disp('!!!!!!ERROR :Not found kmeans.m,Please check!!!!!!!')
end
