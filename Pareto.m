%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%注意%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%前置条件：handle_data.m kmeans.m flow_data.m NSGA.m%%%
%%%由于kmeans.m 和 NSGA.m 两个运行结果具有随机性，这里建议将kmeans.m生成的all_ty_days_01h保存下来，
%%%然后在使用的时候直接导入即可，可以确保其值不变；
%%%NSGA.m 计算60个典型日需要在i7-7700HQ @ 2.80Ghz 笔记本上运行 1~2小时，并且运行后的结果也有很大的随机性，
%%%也建议将其生成的最后结果ga_out_LESS 保存到本地备用，使用的时候从本地导入数据，这样就不需要运行NSGA.m以节省时间
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('=======>Running Pareto.m<===========');
%电网负荷特性
MAX_LOAD_POWER=11800;
summer_load_rate=[0.936,0.920,0.912,0.890,0.900,0.936,0.953,0.957,0.959,0.948,0.952,0.967,0.958,0.951,0.969,0.965,0.982,0.970,0.956,0.949,1.000,0.991,0.964,0.950];
winter_load_rate=[0.901,0.899,0.881,0.880,0.883,0.918,0.920,0.945,0.955,0.982,0.957,0.981,0.969,0.962,0.939,0.908,0.928,0.971,1.000,0.993,0.989,0.984,0.919,0.895];
TYPE_SUMMER =[0,0,0,0,0,1,1,1,1,1,1,0];
summer_load =summer_load_rate*MAX_LOAD_POWER;
winter_load =winter_load_rate*MAX_LOAD_POWER;
%Pareto图的绘制
%请使用绝对路径，默认保存在与脚本同级别目录下
%请使用绝对路径，默认保存位置不确定
%<==========================================>
PARETO_DIR='./pareto_photo';
if not(isfolder(PARETO_DIR))
    mkdir(PARETO_DIR);
end
if not(isfolder(PARETO_DIR))
    assert(0,'=====>Pareto.m:!!!ERROE:Cannot create folder, please check permissions!!!')
end
folder = PARETO_DIR; % 文件夹名称%%%%%%<==>
%<==========================================>
prefix1 = 'mouth_of_Pareto'; % 文件名前缀
prefix_power='power_of_Pareto'; % 文件名前缀
prefix_level='level_of_Pareto'; % 文件名前缀
prefix2='target_Pareto'; % 文件名前缀
disp('=======>Pareto.m:Saving Pareto photo to ./pareto_photo ...');
for i=1:12
    figure(i);
    % 绘制散点图
    hold on;%保持打开让多个图绘制到同一图上
    for j=1:5
        scatter(ga_out_LESS(i).fval{j}(:,1),ga_out_LESS(i).fval{j}(:,2),'.');
    end
    %设置x轴标题
    xlabel(sprintf(' %d 月水电特征日小时平均出力(MW)', i),'FontName', '宋体', 'FontSize', 12);
    %y轴标题
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

STEP=1;
for i=1:12
    %获取入库流量数据
    ga_flow_in =total_mouth_avg(i);
    %确定起调水位，电网负荷
    if TYPE_SUMMER(i) == 1
        initial_level =2713;
        net_load=summer_load;   
    else
        initial_level=2712;
        net_load=winter_load;
    end
    for ty_day=1:5
        %获取风力发电数据
        ga_wind_power=zeros(1,24);
        ga_wind_power(1,:)=all_ty_days_01h(i,ty_day,:);
        %获取得分最高的流量数据，默认最后一组数据流量最高
        ga_flow_out=ga_out_LESS(i).flow{ty_day}(end,:);
        [pareto(i).fenergy(ty_day,:),pareto(i).flevel(ty_day,:),pareto(i).remain_power(ty_day,:),reduce_rate(ty_day,i),ww_left(ty_day,i),w_left(ty_day,i)]=water_energy( ga_flow_out,ga_flow_in,initial_level,STEP,ga_wind_power,net_load);
        if 1%(i==2 || i == 4 || i==8 || i==11)
            %画图
            draw_power(ga_wind_power,pareto(i).fenergy(ty_day,:),pareto(i).remain_power(ty_day,:),net_load,i,ty_day,folder,prefix_power);
            draw_level(ones(1,24)*total_mouth_avg(i),ga_flow_out,pareto(i).flevel(ty_day,:),i,ty_day,folder,prefix_level);
        end
    end
end
disp('=====>Pareto.m:Saved Pareto photo Done.');
disp('=======>Pareto.m:Done.<===========');

%计算只有风和有风和有水的峰谷差
peak_valley_diff=w_left-ww_left;
water_power=zeros(12,5);
water_use_day=zeros(12,1);
water_use_rate=zeros(12,1);
%取出数据
for i = 1:12
    for j=1:5
        %water_power(i,j)=ga_out_LESS(i).fval{ty_day}(end,1);
        tmp(j)=mean(mean(ga_out_LESS(i).flow{j}(end,:)),1);
    end
    water_use_day(i)=mean(tmp);
end
%平均来水利用率
water_use_rate = water_use_day./total_mouth_avg;
%剩余负荷峰谷差的平均值
%tmp_A=mean(peak_valley_diff)
%剩余负荷波动削减率
mean_reduce_rate=mean(reduce_rate);




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
%计算电站24小时出力，水位变化，剩余负荷,剩余负荷变化
function [hydro_energy,water_level,remain_power,reduce_rate,ww_left,w_left]=water_energy(Q_out,Q_in,inital_level,step,wind_power,net_load)
    water_level = zeros(24/step,1);
    remain_power=zeros(24/step,1);
    remain_only_wind=zeros(24/step,1);
    hydro_energy=zeros(24/step,1);
    last_level=inital_level;
    len = 24/step;
    %step为小时数
    rate=0.90;
    %计算水位和小时平均出力
    for i = 1:len
        change_volume = (Q_in - Q_out(i))*step*3600;
        change_levlel = change_volume /(2.39*1000*1000*100/5);
        if Q_out(i) < 177  %如果下泄流量小于最小发电流量，那么将不进行发电
            hydro_energy(i)=0;
        else
            hydro_energy(i)=rate*9.8*Q_out(i)*(last_level+change_levlel/2-end_level(Q_out(i)))*step;
            hydro_energy(i)=hydro_energy(i)/1000;%kw==>MW
        end
        last_level = last_level+change_levlel;
        water_level(i)=last_level+change_levlel/2;%时段平均水位
        remain_power(i) =net_load(i)-hydro_energy(i)-wind_power(i);
        remain_only_wind(i) = net_load(i)-wind_power(i);
    end  
    %削减的波动率
    reduce_rate=(std( remain_only_wind)-std( remain_power))/std( remain_only_wind);
    %有风有水的时候剩余负荷峰谷差
    ww_left = max(remain_power)-min(remain_power);
    %只有风的时候剩余负荷峰谷差
    w_left  = max(remain_only_wind)-min(remain_only_wind);

end

%绘制堆叠
function succcess=draw_power(wind_power,water_power,remain_power,net_load,mouth,ty_day,folder,prefix)
    figure((mouth-1)*5+ty_day);
    hold on;
    if mouth ==1 || mouth ==2
        max_water_power=max(water_power)*1.95;
    else
        max_water_power=max(water_power)*1.85;
    end
    %颜色数组
    %colors =[ 0, 1, 0;0, 0, 1];
    %初始化获取数据
    area_power=zeros(24,2);
    area_power(:,1)=wind_power(1,:);
    area_power(:,2)=water_power(1,:);
    yyaxis right;%y的右轴%右轴是水电和风力发电
    area(area_power);
    % 设置每个数据序列的标注名称
    %colormap(colors);
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
    Min_LEVEL=min(water_level)-(max(water_level)-min(water_level))*0.1;
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



