%%画各月出力小时数
%前置执行条件，需要执行test_precent.m
figure;
colors = hsv(size(sum_power,1));%生成区间种不同的颜色
power_range={'0','0~10MW','10~20MW','20~40MW','40~60MW','60~80MW','80~99MW'};
hold on;
yyaxis left;
for i = 1:size(sum_power,1)
    %yyaxis left;
    ylabel('小时');
    %ylim([0, 100]);
    
    plot(sum_power(i, :),'Color',colors(i,:),'DisplayName', power_range{i},'LineWidth',1.5);
    xlabel('月份');
    
    % 设置坐标轴范围，方便查看
    
    xlim([1, 12]);
    %title(i,'月出力图');
    title(sprintf(' 风电场累计出力时长'),'FontName', '宋体', 'FontSize', 20);    
     
    % 生成文件名
    %plotname = [prefix, num2str(i), '.png'];
                                                                                                                                                                                                              
    % 拼接保存路径
    %savepath = fullfile(folder, plotname);

    width=700;
    height=600;

    set(gcf, 'Units', 'pixels','Position', [100 100 width height]);%设置长宽比
    set(gca, 'LooseInset', get(gca, 'TightInset'));
    
    % 保存图
    %saveas(gcf, savepath);
end
%累计风力出力小时
plot(valid_hours,'DisplayName', "总出力时长",'LineWidth',1.5);
%右
yyaxis right;
plot([mouth.sum],'k','LineWidth',1.5,'DisplayName', '累计出力'); %月累计出力画上面%
legend();
ylabel('MW');
hold off;