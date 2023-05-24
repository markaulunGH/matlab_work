%%这个脚本就是把获得每个流量段的24小时的流量数据处理一下，调出波动最小的一个

%电网负荷特性
MAX_LOAD_POWER=11800;
summer_load_rate=[0.936,0.920,0.912,0.890,0.900,0.936,0.953,0.957,0.959,0.948,0.952,0.967,0.958,0.951,0.969,0.965,0.982,0.970,0.956,0.949,1.000,0.991,0.964,0.950];
winter_load_rate=[0.901,0.899,0.881,0.880,0.883,0.918,0.920,0.945,0.955,0.982,0.957,0.981,0.969,0.962,0.939,0.908,0.928,0.971,1.000,0.993,0.989,0.984,0.919,0.895];
TYPE_SUMMER =[0,0,0,0,0,1,1,1,1,1,1,0];
summer_load =summer_load_rate*MAX_LOAD_POWER;
winter_load =winter_load_rate*MAX_LOAD_POWER;
S_INIT_LEVEL=2713;
W_INIT_LEVEL=2712;
SETP=1;

s_wind_power=zeros(1,24);
w_wind_power=zeros(1,24);
best_flow_summer=zeros(size(ga_out_SUMMER,2),5,24);
best_flow_winter=zeros(size(ga_out_WINTER,2),5,24);
%找出波动最小的情况的位置
for i=1:size(ga_out_SUMMER,2)
    for ty_days=1:5
        [x,y]=find(ga_out_SUMMER(i).fval{ty_days}(:,2)==min(ga_out_SUMMER(i).fval{ty_days}(:,:)));
        best_flow_summer(i,ty_days,:)=ga_out_SUMMER(i).flow{ty_days}(x(1),:);
        [x,y]=find(ga_out_WINTER(i).fval{ty_days}(:,2)==min(ga_out_WINTER(i).fval{ty_days}(:,:)));
        best_flow_winter(i,ty_days,:)=ga_out_WINTER(i).flow{ty_days}(x(1),:);
        %风力出力数据
        s_wind_power=all_ty_days_01h(7,ty_days,:);
        w_wind_power=all_ty_days_01h(1,ty_days,:);
        [summer(i).fenergy(ty_days,:),summer(i).flevel(ty_days,:),summer(i).remain_power(ty_days,:),s_reduce_rate(ty_days,i),s_ww_left(ty_days,i),s_w_left(ty_days,i)]=water_energy( best_flow_summer(i,ty_days,:),mean(best_flow_summer(i,ty_days,:)),S_INIT_LEVEL,STEP,s_wind_power,summer_load);
        [winter(i).fenergy(ty_days,:),winter(i).flevel(ty_days,:),winter(i).remain_power(ty_days,:),w_reduce_rate(ty_days,i),w_ww_left(ty_days,i),w_w_left(ty_days,i)]=water_energy( best_flow_winter(i,ty_days,:),mean(best_flow_winter(i,ty_days,:)),W_INIT_LEVEL,STEP,w_wind_power,winter_load);
    end
    
end


%计算只有风和有风和有水的峰谷差
s_peak_valley_diff=s_w_left-s_ww_left;
w_peak_valley_diff=w_w_left-w_ww_left;

%剩余负荷峰谷差的平均值
s_peak_mean=mean(s_peak_valley_diff);
w_peak_mean=mean(w_peak_valley_diff);

%剩余负荷波动削减率
s_mean_reduce_rate=mean(s_reduce_rate);
w_mean_reduce_rate=mean(w_reduce_rate);

%绘制不同流量的图
%生成流量范围
test_flow=180:10:1160;
hold on;
xlabel("流量/(立方米每秒)")
xlim([160,1180]);
yyaxis left;
%ylabel('MW');
%ylim([0, 80]);
%夏季平均波动削减率
plot(test_flow,s_mean_reduce_rate,'-c','LineWidth',3,'DisplayName', '夏季平均波动削减率'); 
%冬季平均波动削减率
plot(test_flow,w_mean_reduce_rate,'-g','LineWidth',3,'DisplayName', '冬季平均波动削减率');


yyaxis right;
%平均峰谷差
plot(test_flow,s_peak_mean,'.-b','LineWidth',1,'DisplayName', '夏季剩余负荷峰谷差平均改善值');
plot(test_flow,w_peak_mean,'.-m','LineWidth',1,'DisplayName', '冬季剩余负荷峰谷差平均改善值');

% %月平均，发电量，%最大功率，最小功率
% plot([mouth.max],'r','LineWidth',1.5,'DisplayName', '最大出力'); %月最大画年上面%
% plot([mouth.min],'g','LineWidth',1.5,'DisplayName', '最小出力'); %月最小画年上面%
% yyaxis right;
 ylabel('MW');
% plot([mouth.sum],'k','LineWidth',1.5,'DisplayName', '累计出力'); %月累计出力画上面%
legend('Location', 'best');

%title(sprintf("各月出力图"), 'FontName', '宋体', 'FontSize', 20);
hold off;

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