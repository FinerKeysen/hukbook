# final关键字

[TOC]



通常`final`关键字是指：“这是无法改变的”

但根据上下文环境，`final`的含义存在细微的区别，有可能被误用。

以下介绍三种可能使用到`final`的情况：数据、方法和类。

## 7.8.1、final数据

编程语言中都有某些方法来向编译器告知一块数据是恒定不变的。数据的恒定不变在一些场合中很重要，比如：

- 一个永不改变的编译时常量
- 一个在运行时被初始化的值，而你不希望它被改变

对于编译期常量，在Java中，这类常量必须时基本数据类型，并且以关键字`final`表示。在对这个常量进行定义的时候，必须对其进行赋值。

一个既是`static`又是`final`的域只占据一段不能改变的存储空间，通常用大写表示，并以下划线分隔单词。

对基本类型使用`final`时，其数值恒定不变；当对对象引用使用final时，其引用恒定不变（即无法再把它改为指向另一个对象），然而对象其自身却是可以被修改的。

Notes：

误区1，不能因为某数据是`final`，就认为在编译时可以知道它的值。

如例子：

```java
private final int i = rand.nextInt(20);
static final int INT_VALUE = rand.nextInt(20);
```

变量`i`和`INT_VALUE`是在运行时使用随机生成的数值来初始化的。

### （1）空白final

空白`final`是指被声明为`final`但又未给定初值的域。

无论何种情况，编译器都确保空白`final`在使用前必须被初始化。但空白`final`的使用比较灵活，比如：一个类中的`final`域可以做到根据对象而有所不同，却又保持其恒定不变的特性。

示例：

```java
//: reusing/BlankFinal.java
// "Blank" final fields.

class Poppet {
  private int i;
  Poppet(int ii) { i = ii; }
}

public class BlankFinal {
  private final int i = 0; // Initialized final
  private final int j; // Blank final
  private final Poppet p; // Blank final reference
  // Blank finals MUST be initialized in the constructor:
  public BlankFinal() {
    j = 1; // Initialize blank final
    p = new Poppet(1); // Initialize blank final reference
  }
  public BlankFinal(int x) {
    j = x; // Initialize blank final
    p = new Poppet(x); // Initialize blank final reference
  }
  public static void main(String[] args) {
    new BlankFinal();
    new BlankFinal(47);
  }
} ///:~
```

Notes：

必须在域的定义处或者每个构造器中用表达式对`final`进行赋值

### （2）final参数

`Java`允许在参数列表中以声明的方式将参数指明为`final`，那么将无法在方法中更改参数引用所指向的对象。（也即可以使用，但不可改变其指向）

## 7.8.2、final方法

使用`final`方法的原因有二。

一是，把方法锁定，以防任何继承类修改它的含义。比如确保在继承中使方法行为保持不变，并且不会被覆盖。

二是，效率。早期时，配合编译器将该方法的所有调用转为内嵌调用，从而消除方法调用的开销。当一个方法很大时，程序代码就会膨胀，可能看不到内嵌调用带来的性能提高。此外在新的`Java`版本中，虚拟机在无须`final`修饰时就能探测到这些情况，并能优化去掉这些效率反而降低的额外的内嵌调用，因此也就不需要再用`final`方法进行优化了。

综上，目前只有在想要明确禁止覆盖时，才将方法设置为`final`。

### （1）`final`和`private`关键字

类中所有的`private`方法都隐式地指定为是`final`的。因为无法取用`private`方法，所以也就无法覆盖它。可以对`private`方法添加`final`修饰词，但是不会增加额外的意义。



覆盖，只有在某方法是基类的接口的一部分时才会出现，即，必须能将一个对象向上转型为它的基本类型并调用相同的方法。如果方法是`private`，它就不是基类的接口的一部分。它仅是一些隐藏于类中的程序代码，只不过具有相同的名称而已。

> 练习：
>
> 创建一个带`final`方法的类。由此继承产生一个类并尝试覆盖该方法。

```java
/**
 * @FilePath reusing/Exercise21.java
 * @Author
 * @Date 2019/9/7 15:31
 * @Version 1.0.0
 * @Description
 */

package reusing;

import static hkeysen.utils.Print.*;

class WithFinal {
    final void f() { print("WithFinal.f()"); }
    void g() { print("WithFinal.g()"); }
    final void h() { print("WitFinal.h()"); }
}

class OverrideFinal extends WithFinal {
    // attempt to override:
    // public final void f() { print("OverrideFinal.f()"); } // no can do
    @Override public void g() { print("OverrideFinal.g()"); } // OK, not final
    // final void h(); { print("OVerrideFinal.h()"); } // cannot override final
}

public class Exercise21 {
    public static void main(String[] args) {
        OverrideFinal of = new OverrideFinal();
        of.f();
        of.g();
        of.h();
        // Upcast:
        WithFinal wf = of;
        wf.f();
        wf.g();
        wf.h();
    }
}/* Exercise21 output
WithFinal.f()
OverrideFinal.g()
WitFinal.h()
WithFinal.f()
OverrideFinal.g()
WitFinal.h()
 *///:~
```

## 7.8.3 final类

当用`final`修饰一个类时，说明你不打算继承该类，也不允许别人这样做。即，该类的设计不需要做任何改变。

`final`类中所有的方法都隐式指定为`final`的，因为无法覆盖它们。但仍然可以在`final`类中为其成员或方法添加`final`修饰，尽管这样没有任何意义。



