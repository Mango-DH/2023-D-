# 2023-D
为了今年（2025）的电赛国赛，两位队友和我一起走上漫漫征程。感谢队友，没有你们我也想不到自己能做到... 整个装置的构成：AD8099前端放大，FPAG数字解调、参数结算，正点原子ATK-HS-ADDA模块采集信号、输出解调信号，STM32F407负责参数显示。

## 关于项目的工程构成
### 2023D_FPGA 存放FPGA工程
#### Design 
存放所有的模块代码、例化的ip核、fir低通滤波器的.coe文件、FPGA的.xdc文件
#### Modelsim
存放Measure测量模块的仿真调试工程，Measure文件夹是解调波参数计算的各个模块。Wave_Cal文件夹中的wave_cal.v 模块是 dc_remover.v 和 wave_identifier.v 两个模块的合并。
#### TestBench
该文件夹中的三个模块在Vivado仿真时使用，用于产生AM调制信号。删除并不会对最终结果产生影响。
 
### STM32FINAL STM32的代码
STM32只负责通过uart协议接受FPGA解调的信息并在屏幕上显示。

### 增益放大器 
AD9833的仿真文件、Gerber文件


