# 要扫描 Java 的 package 中有某个注解的类，应该怎么做？


在 Java 自带的反射库中，我们只能根据具体的一个完整类名去加载一个类。如果我们想要在一个 package 中扫描所有的符合条件的类，就需要自己写代码实现。

但是作为一个调包侠，让我自己写代码看处理起来非常常见的需求是一件很难忍受的事情。今天就来看看有什么包是我们可以直接调的。

== Reflections

link:https://github.com/ronmamo/reflections[Reflections] 是 github 上面的一个开源仓库，它主要提供的功能就是扫描。在它的 ReadMe 里，我们可以看到它能做什么

> - get all subtypes of some type
> - get all types/members annotated with some annotation
> - get all resources matching a regular expression
> - get all methods with specific signature including parameters, parameter annotations and return type

很明显，这个库不仅能帮我们扫描 class，还能扫描类的成员、方法。

=== 扫描被自定义注解的类

接下来假设我们有一个叫做 `@PrivateController` 的注解，用来标记那些提供内部 API 的 controller。现在我们想要拿到所有被打上了这个注解的类，我们应该如何使用 Reflections 做到呢？

[source,java]
----
public Collection<Class<*>> getAllPrivateAPIs() {
  Reflections reflections = new Reflections("root.package");
  return reflections.getTypesAnnotatedWith(PrivateController.class);
}
----

简单的两行代码，就完成了我们想要的功能。

除了根据被注解这个条件外，Reflections 还可以扫描某个类的子类，甚至根据一个表达式寻找符合要求的资源。不过这些操作都一样简单，阅读 ReadMe 就能够知道如何使用。

== 利用 Spring 来扫描

Reflections 看起来很不错，不过有什么替代方案吗？

我们知道 Spring 可以扫描所有的被 `@Component` 注解的类。那么 Spring 如何做到的呢？也许我们可以直接利用 Spring 达到我们的目的。

Spring 是可以通过 `@ComponentScan` 注解来指定扫描某个 package 下所有被 `@Component` 注解的类的。而这个过程则被实现在了 `ClassPathScanningCandidateComponentProvider` 这个类中。

=== 利用 TypeFilter 来做过滤

这个类的构造方法接收一个叫做 `useDefaultFilters` 的布尔值。那么问题来了，这里的 `defaultFilters` 是什么呢？

简单浏览一下源码，就能发现 `defaultFilters` 包括的是 `@Component`、`@ManagedBean`、`@Named` 这三个注解。

[NOTE]
====
- `ManagedBean` 是 Java EE 6 中的 `javax.annotation.ManagedBean`
- `Named` 是 JSR-330 中的 `javax.inject.Named`
====

现在我们知道了三个 `defaultFilter` 包括哪些东西了，那么又有问题了，这里的 filter 是什么呢？

刚才的三个注解，不是被直接使用，而是被用来创建了一个 `AnnotationTypeFilter` 实例，然后加入到了 `includeFilters` 集合中。与这个集合相对的，是 `excludeFilters` 集合。

这两个集合的职责，就是用来判断一个类是否符合要求的。如果一个类符合了 `excludeFilters` 中的条件，那么就不符合要求；接下来，如果符合了 `includeFilters` 中的条件，那么就符合要求。

接下来的例子中，我们将会使用到 `AnnotationTypeFilter` 这个类。它是 `TypeFilter` 的一个实现。而 `TypeFilter` 则有很多实现，包括 `AssignableTypeFilter`、`AspectJTypeFilter`、`JooqTypeExcludeFilter` 等。可以根据需要来选择或者自定义实现。

=== 如何使用 ClassPathScanningCandidateComponentProvider

我们还是使用上面的那个例子，正好对比一下两种方式的代码不同之处。

[source,java]
----
public Collection<Class<*>> getAllPrivateAPIs() {
  ClassPathScanningCandidateComponentProvider provider = new ClassPathScanningCandidateComponentPrivder(false);
  provider.addIncludeFilter(new AnnotationTypeFilter(PrivateController.class));
  Collection<BeanDefinition> beanDefinitions = provider.findCandidateComponents("root.package");
  return beanDefinitions.stream()
    .map(BeanDefinition::beanClassName)
    .map(Class::forName)
    .collect(toList());
}
----

== 对比

我们可以从几个角度来对比一下上面提到的两个方案。

=== 代码量

Reflections 明显是更简单的选择，短短两行代码就能得到想要的结果。

Spring 使用起来则要麻烦一些，需要先做一点配置才能使用。并且不能直接得到想要的 `Class` 对象，而是得到的 `BeanDefinition`，然后再自己转换。

=== 职责

从 ReadMe 就可以看出，Reflections 就是用来做这种事情的，非常符合这里面临的需求。

Spring 的 `ClassPathScanningCandidateComponentProvider` 则不是用来做这种事情的，它只是恰好提供了我们需要的功能而已。故名思意，这个类的职责是提供 Component candidates ，是给 Spring Context 使用的。Spring 并没有保证这个类会不会被修改。

=== 可维护性

其实从职责的角度来看，Spring 的这种方式的可维护性要稍微低一点点。但是在代码量较少且封装良好的情况下，这么一点点的差别并不会有什么影响。

== 总结

今天我们了解了如何扫描被注解的类的两种方式。但是我们没有研究这两种方式背后实现的逻辑。

作为一个合格的调包侠，如果不清楚背后的逻辑，那么很难自信的保证自己的代码是如何工作的。所以后面再单独写文章来看看这两种方式背后的逻辑吧。


