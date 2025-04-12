clc; clear; close all;

% 参数定义
depth = 1024;   % 数据深度
width = 8;      % 数据位宽

% 生成归一化余弦信号
n = 0:depth-1;
cos_wave = cos(2 * pi * n / depth);

% 映射到 8 位有符号整数 (-128 ~ 127)
cos_scaled = round(cos_wave * (2^(width-1) - 1));

% 生成 .coe 文件
fileID = fopen('cos_8_1024_signed.coe', 'w');

% 写入 COE 文件头
fprintf(fileID, 'memory_initialization_radix=10;\n');
fprintf(fileID, 'memory_initialization_vector=\n');

% 写入数据
for i = 1:depth
    if i ~= depth
        fprintf(fileID, '%d,\n', cos_scaled(i));
    else
        fprintf(fileID, '%d;\n', cos_scaled(i));  % 最后一个数据后加分号
    end
end

% 关闭文件
fclose(fileID);

disp('COE 文件生成完毕，文件名：cos_8_1024_signed.coe');
