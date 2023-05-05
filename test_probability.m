%前置执行条件，需要执行test_precent.m
% 将数据堆叠在一起
stackedData = [percentages'];    

% 绘制百分比直方堆叠图
bar(stackedData, 'stacked');

% 计算堆叠面积
stackedArea = cumsum(stackedData, 1);

% 绘制堆叠面积图
%area(stackedArea, 'LineStyle', 'none');
yyaxis left;
% 设置x轴标签
xlabel('月份');

% 设置y轴标签
ylabel('百分比');

% 设置图例
hLegend =legend('0','0~10MW','10~20MW','20~40MW','40~60MW','60~80MW','80~99MW');
% 添加图例并设置属性,'NumColumns', 2设置两行
%可以使用'Orientation'属性来指定图例的方向，其取值可以是'horizontal'（横向）或'vertical'（纵向）。
set(hLegend, 'Location', 'northwest', 'FontSize', 12, 'Orientation', 'horizontal','NumColumns', 2);

% 添加标题
title('各月风电场出力时长百分比', 'FontName', '宋体', 'FontSize', 20);
yyaxis right;
plot([mouth.sum],'k','LineWidth',1.5,'DisplayName', '累计出力'); %月累计出力画上面%
ylabel('MW');


hold off;

