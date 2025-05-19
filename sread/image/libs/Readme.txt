routines文件夹中：
IMAGE_Set_Value是主程序。
Usage: info = IMAGE_Set_Value(filename, record)
filename: *.cdf。
要求：	（1）CDAWeb上IMAGE卫星数据。IMAGE -> IMAGE_K0_WIC -> Create Version 3.0 compatible CDFs。
	（2）图像部分必须选“Mapped Images”。
	（3）非图像数据全部勾上。
record: 就是文件中包含的某个记录，如共有100张图，record可取0到99。

info数组内容见IMAGE_Set_Value.pro第135行。

注意：
（1）没有airglow subtraction.
（2）解压缩后的目录为根目录root_dir，需要改的，在IMAGE_Set_Value.pro第20行。
（3）如果有的函数没定义，有可能是我没有加到我的文件夹中，我会补发过去，你可自行加到routines文件夹中。