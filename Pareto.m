%Pareto图的绘制
folder = 'G:\大一下\毕业设计多能互补\data\Pareto'; % 文件夹名称
prefix1 = 'mouth_of_Pareto'; % 文件名前缀
% for i=1:12
%     figure(i);
%     % 绘制散点图
%     scatter(ga_out(i).fval{1}(:,1),ga_out(i).fval{1}(:,2),'.');
%     xlabel(sprintf(' %d 月水电特征日小时平均出力(MW)', i),'FontName', '宋体', 'FontSize', 12);
%     ylabel("剩余负荷标准差(MW)")
% 
%     % 生成文件名
%     plotname = [prefix1, num2str(i), '.png'];
%     % 拼接保存路径
%     savepath = fullfile(folder, plotname);
%     set(gca, 'LooseInset', get(gca, 'TightInset'));
%     % 保存图
%     saveas(gcf, savepath)
%     % 关闭当前窗口
%     close;
% 
% end
level=end_level(1000);

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
    remain_power=zeros(24,1);
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
        water_level(i,energy_index)=last_level+change_levlel/2;%时段平均水位
        remain_power(i) =net_load(i)-hydro_energy(i)-wind_power(i);
    end  
end
