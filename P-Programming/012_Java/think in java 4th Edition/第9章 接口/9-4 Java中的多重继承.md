组合多个类的接口的行为被称作**多重继承**。

在导出类中，不强制要求有一个是抽象的或“具体的”（没有任何抽象方法的）基类。

如果从一个非接口的类继承，那么只能从一个类去继承。

```java
class A{}
class B{}
class C extends A,B {} // 报错，cannot extents multiple classes
```

其余的元素必须为是接口，在implements之后并用`,`分隔。可以继承任意多个接口，并能向上转型为接口。

```java
package interfaces.demo.ch9_4;//: interfaces/Adventure.java
// Multiple interfaces.

interface CanFight {
  void fight();
}

interface CanSwim {
  void swim();
}

interface CanFly {
  void fly();
}

class ActionCharacter {
  public void fight() {}
}	

class Hero extends ActionCharacter
    implements CanFight, CanSwim, CanFly {
  public void swim() {}
  public void fly() {}
}

public class Adventure {
  public static void t(CanFight x) { x.fight(); }
  public static void u(CanSwim x) { x.swim(); }
  public static void v(CanFly x) { x.fly(); }
  public static void w(ActionCharacter x) { x.fight(); }
  public static void main(String[] args) {
    Hero h = new Hero();
    t(h); // Treat it as a CanFight
    u(h); // Treat it as a CanSwim
    v(h); // Treat it as a CanFly
    w(h); // Treat it as an ActionCharacter
  }
} ///:~
```

