---
title: "写给 Java 程序员的函数式入门指南"
date: 2022-05-31T23:04:11+08:00
draft: true
---

这是一篇写给 Java 程序员的函数式入门指南，旨在帮助 Java 程序员了解 Java 语言提供的函数式语法糖，建立起函数式编程的思维。

## Java 提供了哪些函数式的语法糖

Java 8 开始提供了函数式编程的支持，这些支持不是来自虚拟机层面的支持，而仅仅是语法层面的语法糖。
我们首先要明确这一点，这样更能够理解 Java 里用函数式编程写出来的代码究竟是如何执行的。

### 最容易接触到函数式的地方

Java 8 中最容易接触到函数式的地方就是 `Stream` API 了。
我们就从这里开始吧。

#### Stream

想要获得一个 `Stream` 对象非常简单，我们可以从任意的 `Collection` 对象上通过调用 `stream()` 方法获得。
接下来我们就可以调用这个 `Stream` 对象上的各种 `map`、`filter` 等方法了。

假设我们有这么一些类：

```java
@Value //lombok annotation
public class Client {
  String id;
  Collection<CreditCard> creditCards;
}

@Value
public class CreditCard {
  String cardNumber;
  String vcc;
  LocalDate expiredDate;
}
```

然后我们有一个 `List<Client>`。

接下来我们想获取所有用户的明年到期的信用卡信息。

如果我们采用传统的方式，可能写出下面的代码：

```java
Map<String, List<CreditCard>> result = new HashMap<>();
for (Client client: clients) {
  for (CreditCard creditCard: client.getCreditCards()) {
    if (creditCard.getExpiredDate().isBefore(endOfNextYear) && creditCard.getExpiredDate().isAfter(beginOfNextYear)) {
      List<CreditCard> expiredCards = result.get(client.getId());
      if (expiredCards == null) {
        expiredCards = new ArrayList<>();
      }
      expiredCards.add(creditCard);
      result.put(client.getId(), expiredCards);
    }
  }
}
```

不知道你有没有耐心看完上面的代码。不过没关系，我也没有期望谁会去看它，因为我也不想看。

但是我们可以分析一下上面的代码有什么问题。

首先是 `result` 这个变量，它和后面的 `for` 循环纠缠到了一起，这意味着重构的复杂度会比较高。同时它还在不断被修改，这就可能是导致 bug 风险。
其次是这种命令式的编程风格，让我们的代码把业务需求和实现逻辑混合到了一起，很难一眼看出这一段代码在做什么事情。

当然还有很多问题，我就不一一列举了。让我们直接进入正题，看看 `Stream` 如何帮我们更加简洁得实现这个需求。

```java
Predicate<Pair<Client, CreditCard>> isInNextYear = pair -> pair.getRight().getExpiredDate().isBefore(endOfNextYear) && pair.getRight().getExpiredDate().isAfter(beginOfNextYear);
Map<String, List<CreditCard>> result = clients.stream()
  .flatMap(
    client -> client.getCreditCards().stream()
      .map(creditCard -> Pair.of(client, creditCard))
  )
  .filter(isInNextYear)
  .map(pair -> Pair.of(pair.getLeft().getId(), pair.getRight()))
  .collect(toMap(Pair::getLeft, Pair::getRight));
```

这个例子似乎看起来更复杂了，里面的什么 `flatMap`、`filter`、`map`、`collect` 都是啥玩意儿？

别急，我这就要解释这些函数。至于函数的参数，暂时不重要。

##### 函数式常见的函数

上面例子中的 `flatMap`、`filter`、`map` 都是在函数式语法中常见的函数，了解了它们在 Java 中的含义，也就很容易理解其他语言用函数式写出来的代码了。

###### flatMap

`flatMap` 是一种拍平的做法，把嵌套的容器结构拍平成单层的容器结构。

举个例子就是，有这样一个嵌套的列表，`[[1,2],[3,4]]` 在经过 `flatMap` 的操作之后，就变成了 `[1,2,3,4]`。

而 Java 中的这个函数它接收的参数是一个返回值为 `Stream` 对象的函数。也就是说，上面的 `flatMap` 中的内容是一个函数。

```java
// 这是一个函数
client -> client.getCreditCards().stream()
      .map(creditCard -> Pair.of(client, creditCard))
```

同样，Java 中的 `flatMap` 返回的类型也是一个 `Stream`，这也是我们能接着调用 `filter` 的原因。

至于传递给 `flatMap` 的那段代码为什么是个函数，我们会在后面的 [lambda 表达式](#lambda-表达式) 中看到。

###### filter

`filter` 的语义是过滤，或者说筛选。过滤的条件是传递给它的函数的运算结果。结果为 `true` 则选择当前对象，结果为 `false` 则舍弃当前对象。

这里我们把这个函数抽成了变量，直接把这个变量传递了进去。我们可以发现这个变量还有一个类型 `Predicate`，是一个接口。

等等，它的参数不是函数吗？怎么变成一个接口了？让我们先带着这个问题继续上面的代码。

###### map

`map` 的语义是变换，把一种类型的值转变成另一种类型的值。它也接收一个函数，这个函数就包含了转换的逻辑。

比如说，我们要把一个 `Integer` 转变成一个 `String`，就可以把 `Integer` 的 `toString()` 方法传递给它，这样就可以把一个 `Stream` 里面的 `Integer` 都转换成 `String` 了。

###### reduce/fold

这两个函数的含义相同，只不过不同的语言提供的是不同的方法，但作用是一样的，就是把一个集合收集起来。在 Java 中收集的集合就是 `Stream`。

举个例子，我们有一个 `Stream<Integer>` 对象，想把它们的和算出来，就可以利用 `reduce` 方法：

```java
stream
  .reduce(0, (acc, next) -> acc + next);
```

其中的第一个参数是初始值，第二个参数是一个函数，用来做收集的逻辑。

在上面的例子中，我们使用的 `collect` 方法是 Java 提供的一个语法糖，用来简化一些常用的收集操作的。
如果我们把它换成 `reduce` 就会变成这样：

```java
stream
  .reduce(
    new HashMap<>(),
    (result, nextPair) -> {
      result.put(nextPair.getLeft(), nextPair.getRight());
      return result;
    }
  );
```

###### 回到例子

现在我们回到前面的例子。
虽然仍然看不懂里面的所有代码，但是在搞清楚 `flatMap` 等函数的作用之后，能够明白这段代码大致的步骤了。

1. 把 `Client` 与 `CreditCard` 的一对多关系拍平，变成多个重复的 `Client` 对象和不同的 `CreditCard` 对象的一对一关系
2. 在这些一对一关系中，筛选出 `expiredDate` 在明年的组合
3. 把一对一关系中的 `Client` 对象换成它的 `id`
4. 把这些一对一关系重新整理成一对多关系

在了解了这些步骤之后，我们就可以去理解每一步是如何做的了。

这就和原来的代码产生了区别：
旧代码中的

##### lambda 表达式

#### Optional

### FunctionalInterface

### 不可变对象

### 尝试用函数式来解决这些问题

## 还缺少什么

### 柯里化

### 异常处理

### Either 类型

### 模式匹配

### 不可变的容器

## Vavr


