在实际项目中，经常会想要将某些事物尽可能对这个世界隐藏起来，但仍然允许导出类的成员访问他们。

关键字`protected`，指明“就类用户而言，这是`private`的，但对于任何继承与此类的导出类或其他任何位于同一个包内的类来说，他却是可以访问的”。

`protected`也具有包访问权限。

一般将域保持为`private`，然后通过`protected`方法控制类的继承者的访问权限。

练习：在包中编写一个类，类具备一个protected方法。在包外部，试着调用该protected方法并解释其结果。然后，从你的类中继承产生一个类，并从该导出类的方法内部调用该protected方法。

```java
/**
 * @FilePath reusing/BasicDevice.java
 * @Author
 * @Date 2019/9/1 19:38
 * @Version 1.0.0
 * @Description
 */

package reusing;

public class BasicDevice {
    private String s = "BasicDevice";
    public BasicDevice() {
        System.out.println("This is " + s);
    }
    protected void changeS(String c) {
        s = c;
    }
    public void showS() {
        System.out.println(s);
    }
}/* BasicDevice output

  *///:~
```

在包外创建

```java
/**
 * @FilePath reusing.Device.java
 * @Author
 * @Date 2019/9/1 19:39
 * @Version 1.0.0
 * @Description
 */

// 调用protected方法
class reusing.DeviceTest {
    public static void main(String[] args) {
        BasicDevice bd = new BasicDevice();
        bd.showS();
        // bd.changeS("test changeS function..."); // error, can not access protected method from outside package
    }
}

public class reusing.Device extends BasicDevice {
    void changeBasicDevice(String c) {
        super.changeS(c); // correct, can access protected method
    }
    public static void main(String[] args) {
        reusing.Device d = new reusing.Device();
        d.showS();
        d.changeBasicDevice("changed changed");
        d.showS();
        reusing.DeviceTest.main(args);
    }
}/* reusing.Device output
This is BasicDevice
BasicDevice
changed changed
This is BasicDevice
BasicDevice
  *///:~
```

