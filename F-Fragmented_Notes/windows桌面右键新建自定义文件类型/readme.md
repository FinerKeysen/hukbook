如何在桌面右键新建标签中添加自定义的文件类型？

在redegit注册表编辑器中HKEY_CLASS_ROOT下对应的文件夹下添加ShellNew子项，并在该子项下添加字符值，修改名称为NullFile，其他为默认值。

如右键下添加MarkDown文件类型

![img](readme.assets/wps1.jpg)

 

具体做法是：

第一步

![img](readme.assets/wps2.jpg)

 

第二步

![img](readme.assets/wps3.jpg)

 

 