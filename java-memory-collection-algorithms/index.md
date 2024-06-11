# Java内存回收算法介绍



`JVM` 提供了自动化的内存管理，使得开发者不需要编写内存回收的代码。但是，`JVM` 是如何工作的呢？是如何知道哪些内存应该被清理呢？又如何减小垃圾回收时产生的问题的影响呢？周志明的《深入理解 Java 虚拟机》可以给我们答案，本文主要针对垃圾收集**算法**做介绍。

== 如何判断对象是否存活

`JVM` 要收集垃圾，那么久需要先判断哪些内容是垃圾，需要被收集。

=== 引用计数算法

该算法是指，给对象添加一个引用计数器，每当有一个地方引用它时，计数器加一；当引用失效时，计数器减一。

这个算法看上去很简单，但是有一个很大的问题，就是没有办法解决循环引用的问题。比如，`A` 引用了 `B`，`B` 引用了 `C`，`C` 又引用了 `A`。这样每个对象都被引用了一次，但是有可能 `ABC` 三个对象我们都不再需要，也就是它们都是垃圾。但这个算法却会认为它们都被引用了，所以它们都不是垃圾，也就永远都不会被回收了。

所以这个算法不应该被采用。

=== 可达性分析算法

这个算法的思路是，定义一系列称作 `GC Roots` 的对象作为起始点，从这些节点开始向下搜索，搜索走过的路径成为引用链（`Reference Chain`），当一个对象到 `GC Roots` 没有任何引用链相连时，说明这个对象是不可达对象。

这个算法就解决了循环引用的问题，并且也是 `JVM` 中主流的实现。

`JVM` 中可以作为 `GC Roots` 的对象有：

- 虚拟机栈中**引用的对象**
- 方法区中静态属性**引用的对象**
- 方法区中常量**引用的对象**
- 本地方法栈中 `Native` 方法**引用的对象**

== 如何清理垃圾

前面判断了一个对象是不是垃圾，接下来，就要看看我们应该如何清理这些垃圾了。

=== 标记-清除算法（Mark-Sweep）

这个算法顾名思义，就是先标记出需要回收的对象，然后清除它们。这个算法没有被采用，主要是两个原因：

. 效率低：无论是 `标记` 还是 `清除`，这两个过程的效率都很低下。
. 容易产生空间碎片：在 `清除` 过后，容易产生大量不连续的内存碎片，导致在分配大对象时找不到足够的连续空间来分配。

由此，人们基于这个算法进行改进，衍生出了后来的算法。

=== 复制算法（Copying）

将内存按容量分为大小相等的两块，每次只使用其中一块。垃圾回收时，将还存活的对象复制到另一块上面去，然后将刚才使用的这一块空间全部清除。

优点：

. 效率更高：每次都是对整个半块内存进行回收
. 避免了空间碎片问题

缺点：

. 能够使用的内存只有一半，利用率仅有 50%。

复制算法经过改良后，被广泛的使用到 `**新生代**` 的内存回收中。

==== 改进

IBM 的研究表面，`JVM` 新生代中 98% 的对象都是“朝生夕死”的，所以没有必要按照 1:1 来划分内存空间。而在 `HotSpot` 的实现中，恰好是这样设计的。

`HotSpot` 将 `新生代` 分为一块较大的 `Eden` 空间和两块较小且大小相等的 `Survivor` 空间，默认比例是 8:1:1。

. 每次使用 `Eden` 和其中一块 `Survivor`
. 回收时，将 `Eden` 和 `Survivor` 中还存活的对象复制到另一块 `Survivor` 中去
. 清理掉 `Eden` 和刚才使用的那块 `Survivor`
. 如果 `Survivor` 没有足够的空间存放对象，那么这些对象需要通过内存担保机制存入老年代

=== 标记-整理算法（Mark-Compact）

顾名思义，与 `标记-清除` 算法的区别是，该算法会让所有存活的对象都向一端移动，然后直接清理掉边界之外的内存。这样可以成功的避免内存碎片。

`标记-整理` 算法没有解决效率低的问题，所以显而易见，没有理由在 `新生代` 中用它替换 `复制` 算法。但由于 `复制` 算法按 1:1 划分时会浪费空间，划分 `Eden` & `Survivor` 又需要内存担保，所以在对象存活率较高的老年代中不适合使用。而 `标记-整理`/`标记-清理` 算法则更适合于这样的场景。

=== 分代收集算法

这并不是新的算法，而是根据对象存活周期的不同，将内存分为几块，分别采用不同的收集算法。

我们一般把 `Java 堆` 分为新生代和老年代。

新生代::
研究表明，每次收集新生代内存时，都有大量对象死去，只有少量对象存活，所以采用改进的 `复制` 算法，付出少量对象的复制成本就可以完成收集。
老年代::
老年代对象存活率高，没有额外空间进行内存担保，所以没有办法使用 `复制` 算法，就必须采用 `Mark-Compact` 或 `Mark-Sweep` 算法。

== 总结

`JVM` 通过 `可达性分析算法` 标记需要被收集的对象，然后通过 `Copying`、 `Mark-Sweep` 和 `Mark-Compact` 算法的配合回收内存。 `Copying` 算法被改良后划分出一个 `Eden` 和两个 `Survivor` 区域，比例为 8:1:1，用于 `新生代`；`Mark-Sweep` 和 `Mark-Compact` 用于 `老年代`。