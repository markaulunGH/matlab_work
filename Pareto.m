%电网负荷特性
MAX_LOAD_POWER=11800;
summer_load_rate=[0.936,0.920,0.912,0.890,0.900,0.936,0.953,0.957,0.959,0.948,0.952,0.967,0.958,0.951,0.969,0.965,0.982,0.970,0.956,0.949,1.000,0.991,0.964,0.950];
winter_load_rate=[0.901,0.899,0.881,0.880,0.883,0.918,0.920,0.945,0.955,0.982,0.957,0.981,0.969,0.962,0.939,0.908,0.928,0.971,1.000,0.993,0.989,0.984,0.919,0.895];
TYPE_SUMMER =[0,0,0,0,1,1,1,1,1,1,0,0];
summer_load =summer_load_rate*MAX_LOAD_POWER;
winter_load =winter_load_rate*MAX_LOAD_POWER;
%Pareto图的绘制
folder = 'G:\大一下\毕业设计多能互补\data\Pareto'; % 文件夹名称
prefix1 = 'mouth_of_Pareto'; % 文件名前缀
prefix_power='power_of_Pareto';
prefix_level='level_of_Pareto';
prefix2='target_Pareto';
for i=1:12
    figure(i);
    % 绘制散点图
    hold on;
    for j=1:1
        scatter(ga_out(i).fval{j}(:,1),ga_out(i).fval{j}(:,2),'.');
    end
    
    xlabel(sprintf(' %d 月水电特征日小时平均出力(MW)', i),'FontName', '宋体', 'FontSize', 12);
    ylabel("剩余负荷标准差(MW)")
    % 生成文件名
    plotname = [prefix2, num2str(i), '.png'];
    % 拼接保存路径
    savepath = fullfile(folder, plotname);
    set(gca, 'LooseInset', get(gca, 'TightInset'));
    % 保存图
    saveas(gcf, savepath)
    hold off;
    % 关闭当前窗口
    close;

end
% pareto.fenergy=zeros(12,5,24);
% pareto.flevel=zeros(12,5,24);
STEP=1;
% for i=1:12
%     
%     %获取出库流量数据
%     %ga_flow_out=zeros(1,24);
% 
%     ga_flow_in =total_mouth_avg(i);
%     if TYPE_SUMMER(i) == 1
%         initial_level =2713;
%         net_load=summer_load;
%     else
%         initial_level=2712;
%         net_load=winter_load;
%     end
%     for ty_day=1:5
%         ga_wind_power=all_ty_days_01h(i,ty_day,:);
%         ga_flow_out=ga_out(i).flow{ty_day}(end,:);
%         [pareto(i).fenergy(ty_day,:),pareto(i).flevel(ty_day,:),pareto(i).remain_power(ty_day,:)]=water_energy( ga_flow_out,ga_flow_in,inital_level,STEP,ga_wind_power,net_load);
%         if 1%(i==2 || i == 4 || i==8 || i==11)
%             %draw_power(ga_wind_power,pareto(i).fenergy(ty_day,:),pareto(i).remain_power(ty_day,:),net_load,i,ty_day,folder,prefix_power);
%             draw_level(ones(1,24)*total_mouth_avg(i),ga_flow_out,pareto(i).flevel(ty_day,:),i,ty_day,folder,prefix_level);
%         end
%     end
%     
% end



%根据流量计算尾水位
function level=end_level(Q)
    assert(Q>=40 && Q <= 2000,"Q out of band !");
    if (Q>=40 && Q < 120)
        level=2592+(Q-40)/(120-40);
    elseif (Q >= 120 && Q < 230)
        level=2593+(Q-120)/(230-120);
    elseif(Q>=230 && Q< 400)
        level=2594+(Q-230)/(400 -230);
    elseif(Q>=600 && Q < 900) 
        level=2596+1.1*(Q-600)/(900-600);
    else
        level=2597.1+3.4*(Q-900)/(2000-900);
    end
end
%计算电站24小时出力，水位变化，剩余负荷
function [hydro_energy,water_level,remain_power]=water_energy(Q_out,Q_in,inital_level,step,wind_power,net_load)
    water_level = zeros(24/step,1);
    remain_power=zeros(24/step,1);
    hydro_energy=zeros(24/step,1);
    last_level=inital_level;
    len = 24/step;
    %step为小时数
    rate=0.90;
    %计算水位和小时平均出力
    for i = 1:len
        change_volume = (Q_in - Q_out(i))*step*3600;
        change_levlel = change_volume /(2.39*1000*1000*100);
        if Q_out(i) < 177  %如果下泄流量小于最小发电流量，那么将不进行发电
            hydro_energy(i)=0;
        else
            hydro_energy(i)=rate*9.8*Q_out(i)*(last_level+change_levlel/2-end_level(Q_out(i)))*step;
            hydro_energy(i)=hydro_energy(i)/1000;%kw==>MW
        end
        last_level = last_level+change_levlel;
        water_level(i)=last_level+change_levlel/2;%时段平均水位
        remain_power(i) =net_load(i)-hydro_energy(i)-wind_power(i);
    end  
end

%绘制堆叠
function succcess=draw_power(wind_power,water_power,remain_power,net_load,mouth,ty_day,folder,prefix)
    figure((mouth-1)*5+ty_day);
    hold on;
    if mouth ==1
        max_water_power=max(water_power)*1.9;
    else
        max_water_power=max(water_power)*1.7;
    end
    colors =[ 0, 1, 0;0, 0, 1];
    area_power=zeros(24,2);
    area_power(:,1)=wind_power(1,:);
    area_power(:,2)=water_power(1,:);
    yyaxis right;
    h=area(area_power);
    % 设置每个数据序列的标注名称
    colormap(colors);
    %labels = {'风电', '水电'};
    %legend({'风电','水电'});
    newcolors = [0 0.5 1; 0.5 0 1];
    colororder(newcolors);
    ylim([0, max_water_power]);
    ylabel("风电、水电时段平均出力(MW)");
    yyaxis left;
    plot(net_load,'m','LineWidth',1.5);
    plot(remain_power(1,:),'LineWidth',1.5);
    ylim([5000, 12800]);
    ylabel("电网负荷(MW)");
    xlabel('时段');
    %legend([net_plot,remain_plot] ,'负荷','剩余负荷');
    legend('负荷','剩余负荷','风电','水电', 'Orientation', 'horizontal','Location', 'northwest');
    title(sprintf(' %d月第%d个典型出力场景', mouth,ty_day),'FontName', '宋体', 'FontSize', 12);
    set(gca, 'LooseInset', get(gca, 'TightInset'));
    xlim([0,24]);
    plotname = [num2str(mouth),prefix,num2str(ty_day)  '.png'];
    savepath = fullfile(folder, plotname);
    saveas(gcf, savepath);
    hold off;
    close;
end

function success=draw_level(Q_in,Q_out,water_level,mouth,ty_day,folder,prefix)
    figure((mouth-1)*5+ty_day);
    hold on;
    MAX_Q=max([max(Q_out),Q_in])*1.15;
    MAX_LEVEL=max(water_level)+(max(water_level)-min(water_level))*0.15;
    Min_LEVEL=min(water_level)-(max(water_level)-min(water_level))*0.1;;
    Min_Q=min(Q_out)*0.9;
    yyaxis left;
    plot(Q_in,'c','LineWidth',1.5,'DisplayName','入库流量');
    plot(Q_out,'m','LineWidth',1.5,'DisplayName','出库流量');
    ylabel("流量(立方米每秒)");
    ylim([Min_Q,MAX_Q]);
    yyaxis right;
    plot(water_level,'b','LineWidth',1.5,'DisplayName','水库水位');
    ylabel("时段平均水位(米)");
    ylim([Min_LEVEL,MAX_LEVEL]);

    xlabel('时段');
    legend('Orientation', 'horizontal','Location', 'northwest');
    xlim([0,24]);
    title(sprintf(' %d月第%d个典型水电出力过程', mouth,ty_day),'FontName', '宋体', 'FontSize', 12);
    set(gca, 'LooseInset', get(gca, 'TightInset'));
    plotname = [num2str(mouth),prefix,num2str(ty_day)  '.png'];
    savepath = fullfile(folder, plotname);
    saveas(gcf, savepath);
    hold off;
    close;
end
