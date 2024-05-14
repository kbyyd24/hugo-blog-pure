# 函数式编程给代码设计带来了什么变化？


我第一次接触函数式编程还是在大学的时候，学长实习回来给我介绍了这个新的概念。后来通过阅读《Java8 函数式编程》，我入门了函数式的一些常见方法和思维方式，并在之后的实践中一直尝试使用函数式的方式来解决问题。

渐渐地，我发现有的人使用函数式仅仅是在使用 `map`、`filter` 等函数时使用一下，而没有尝试在更多地地方使用函数式编程、利用它带来地优势。本文就简单分析一下我认为函数式可以为我们的代码带来的改变。

## 数据的不可变性

尽管《重构》中把全局数据和可变数据当作两种坏味道罗列了出来，但我们似乎没有特别强调数据不可变的重要性。再加上古老的 Java 对不可变数据的支持不是那么便捷，我们总是利用可变数据来实现我们的软件。实际上，它们之所以是坏味道，就在于全局变量与可变数据是可以被改变的，其他引用它们的地方可能会因为它们的改变引发 bug。

而函数式天生的数据不可变的特性，加上现代语言的支持，让我们可以在代码中更容易地采用不可变数据，避免前面说的那两种坏味道。

### 重新思考领域模型的实现

在面向对象的语言中，数据是可变的。我们修改一个对象中的属性，是通过直接修改它的值来实现的。修改后的对象还是原来的那个对象，它在内存中的位置并没有发生变化。

而在函数式中，数据是不变的。这似乎意味着我们不能使用函数式的思维来实现领域模型。

但看完《函数响应式领域建模》这本书，我们得到了一种新思路：**每次方法的操作结束都返回一个新的对象，这个对象包含了修改后的新数据；这个时候系统中存在同一个业务对象的两个不同内存对象实例，我们应该把旧对象实例当作进行操作前的快照，把新的对象实例当作业务对象的当前状态。**

接受这种思路的关键在于解耦业务对象和内存中的对象实例，它们本来就是不同上下文中的概念。接受了这种思路，我们就能够非常容易地实现面向对象的不可变对象。

以 Kotlin 为例，我们可以使用不可变的 `data class` 来定义模型，然后以利用 `copy()` 函数来轻松的实现修改。比如我们要修改账号的昵称，可以提供这样的方法：

```kotlin
data class Account(
  val nickName: String,
  //...
) {
  fun updateNickName(newName: String): Account = this.copy(nickName = newName)
}
```

在调用完 `updateNickName` 之后，我们应该使用它的返回值来进行后续的操作，而原来的对象则不再被需要了。

### 选择不可变的容器

在 Java 中，List、Map 等接口并没有不可变的限定，默认的实现也没有这样的限制。这就导致我们创建出来的 List 等对象很容易被修改。而在 Kotlin 中则对这些接口进行了重新设计，它们默认不再是可变的。如果想要一个可变的列表，那么需要把类型声明成 `MutableList`。这可以帮助我们避免意外地修改这些集合。而在 Java 中，我们则要有意识地选择不可变的容器来达到相同地目的，比如使用 Guava 提供的一些函数来创建 List、Map 等。

使用不可变的容器，带来的一个改变是对容器的修改操作。如果容器是可变的，那么修改操作可能就是 `list.add(xxx)` 这样的操作。容器变成不可变之后，这样的操作就失效了。在 Kotlin 中我们可以利用 `plus()` 函数来为容器添加值，而原来的容器不会改变，这个函数会返回一个新的容器对象，它包含了原有容器中的元素和 `plus` 函数中的参数。

如果我们要对一个 `List` 对象中的所有元素进行修改，在传统做法中，我们可能会写下面这样的代码：

```kotlin
fun mapItem(source: List<SourceItem>): List<ResultItem> {
  val result = mutalbeListOf<ResultItem>()
  for (item in source) {
    val resultItem = item.toResultItem()
    result.add(resultItem)
  }
  return result
}
```

而如果我们使用不可变的容器，上面的方法就不能奏效了。在函数式中，我们可以直接利用 `map` 函数来处理这个问题：

```kotlin
source.map { it.toResultItem() }
```

可以看到，这种方式避免了手动创建新的容器，而是通过 `map` 函数，让 JDK 帮我们做到这一点，从而节省掉了大量的无关代码。

再比如，我们要根据用户的输入来生成 SQL 的查询条件，下面是一个使用可变容器的 JOOQ 例子：

```kotlin
fun buildConditions(search: String?, deliveryType: DeliveryType?, brand: String?): List<Condition> {
  val conditions = mutalbeListOf(noCondition())
  if (search != null) {
    conditions.add(PRODUCT.NAME.containsIgnoreCase(search))
  }
  if (deliveryType != null) {
    conditions.add(PRODUCT.DELEVERY_TYPE.eq(deliveryType.name))
  }
  if (brand != null) {
    condition.add(PRODUCT.BRAND.eq(brand))
  }
  return conditions
}
```

> 不需要纠结 JOOQ 是什么，上面的 `PRODUCT` 代表数据表，`NAME`、`DELIVERY_TYPE`、`BRAND` 代表表中的列，剩下的内容看名字即可。

如果我们要使用不可变的容器来改造上面这个例子，那么可以变成下面这样：

```kotlin
fun buildConditions(search: String?, deliveryType: DeliveryType?, brand: String?): List<Condition> {
  var conditions = listOf(noCondition())
  if (search != null) {
    conditions = conditions.plus(PRODUCT.NAME.containsIgnoreCase(search))
  }
  if (deliveryType != null) {
    conditions = conditions.plus(PRODUCT.DELEVERY_TYPE.eq(deliveryType.name))
  }
  if (brand != null) {
    conditions = conditions.plus(PRODUCT.BRAND.eq(brand))
  }
  return conditions
}
```

而这种改造又引入了 `var` 这个关键字，这就是下面要讨论的内容。

### 避免 var 关键字

`var` 代表可以被重新赋值的变量，`val` 代表不可被重新赋值的“变量”。重新赋值意味着需要关注每一个使用这个变量的地方是否对它进行了赋值。这对代码阅读来讲不能说是不好吧，至少也是个灾难了 :new_moon_with_face: 。出现 `var` 意味着这个变量的值有多个来源，这代表着它的可能有多种含义，而我们暂时没有识别出来。

如果代码中出现了 `var`，那就值得好好阅读一下代码，看看是不是可以避免它，哪怕把赋值的逻辑移动到同一个方法中也行。

接着前面的例子，如果我们还想避免使用 `var` 关键字，可以考虑这样改造：

```kotlin
fun buildConditions(search: String?, deliveryType: DeliveryType?, brand: String?): List<Condition> {
  return listOf(noCondition())
    .addCondition(PRODUCT.NAME.containsIgnoreCase(search)) { search != null }
    .addCondition(PRODUCT.DELIVERY_TYPE.eq(deliveryType?.name)) { deliveryType != null }
    .addCondition(PRODUCT.BRAND.eq(brand)) { brand != null }
}

fun List<Condition>.addCoundition(condition: Condition, predicate: () -> Bool): List<Condition> {
  return this.takkeIf { predicate() }
    ?.let { it.plus(condition) }
    ?: this
}
```

这段代码在每次调用 `addCondition` 方法后都会得到一个新的 list 对象，而我们并没有定义很多 `conditions` 变量来接收这些对象，而是使用链式调用来避免无效且重复的变量名。

再比如一个场景，我们在登录的时候，如果账号不存在，那就自动创建出来，那么使用 `var` 的代码可能会像下面这样：

```kotlin
fun login(name: String, password: String) {
  var account = AccountRepository.findBy(name, password)
  if (account != null) {
    account = accountFactory.create(name, password)
  }
  //...
}
```

我们可以把它改成

```kotlin
fun login(name: String, password: String) {
  val account = findOrCreate(name, password)
  //...
}

fun findOrcreate(name: String, password: String): Account = accountRepository.findBy(name, password) ?: accountFactory.create(name, password)
```

`val` 和不可变容器的例子局限在一两个函数的上下文中，并不能充分说明它们带来的真正好处，读者可以带入自己面临的场景来思考这两个问题。虽然例子中的上下文有限，看起来使用 `var` 或 `val`、使用可变容器或者不可变容器的区别并不大，但是在全局中保持代码风格的统一也是一件好事，不是吗？


## 重新思考设计模式

对于相似代码逻辑，我们应该如何处理？复制一份来修改？利用设计模式？利用面向对象的多态？

函数式为我们带来了新思路：可以把函数当作函数的参数和返回值。所以当两个地方有相似的逻辑时，我们可以把这一段代码定义成一个函数，其中不同的代码作为这个新函数的参数，而这个参数则是一个函数。当调用我们定义的这个函数时，调用方需要传递一个函数作为参数，于是不同的调用方就可以通过传递不同的参数来实现不同的需求。

上面这个被定义出来的函数，像不像设计模式中的模板方法？没错，正是模板方法模式，而且这种方式比模板方法需要的代码量更少——不需要定义抽象方法、不需要进行继承、不需要思考子类的名称。

举个例子，一个引用中有 todo 和纪念日两种功能，我们要实现列出今天到期的待办事项和今天的纪念日两个功能，那么代码可能是这样：

```kotlin
fun findDueToday(tasks: List<Task>): List<Task> {
  val today = LocalDate.now()
  return tasks.filter { it.dueDate == today }
}

fun findMemorialToday(memorialDays: List<MemorialDay>): List<MemorialDay> {
  val today = LocalDate.now()
  return tasks.filter { it.nextTime() == today }
}
```

可以看到，在这个简单的例子中，两个方法只有两个区别：`filter` 函数的参数不同，以及处理的数据类型不同。所以我们可以对 `filter` 函数的参数进行抽象，让它不再依赖要处理的数据类型即可：

```kotlin
fun findDueToday(tasks: List<Task>): List<Task> {
  return findToday(tasks, { it.dueDate })
}

fun findMemorialToday(memorialDays: List<MemorialDay>): List<MemorialDay> {
  return findToday(memorialDays, { it.nextTime() })
}

fun <T> findToday(list: List<T>, dateGetter: (T) -> LocalDate): List<T> {
  val today = LocalDate.now()
  return list.filter { dateGetter(it) == today }
}
```

在这个例子中，通过对相似代码中不同部分抽象成函数，从而得到了一部分相同的代码，也就是 `findToday` 方法的内容。如果采用模板方法模式，我们还需要让 `Task` 和 `MemorialDay` 这两个类型拥有相同的父类或接口，而从业务的表达上却很难给这样的抽象命名。

事实上，我们常说的设计模式是针对面向对象编程设计出来的一系列模型设计模式。而在我们引入和函数式的概念后，我们面对相同的问题可以有传统设计模式之外的新方案，而不再需要原原本本地套用为面向对象编程设计的设计模式。

## 巧用柯里化

柯里化是我很喜欢使用的一种方式，用来解决函数的参数过长、函数中的部分逻辑需要延后执行等场景。但并不需要完全地按照柯里化的描述转换成每个函数只有一个参数，而是根据参数的作用分组后进行柯里化。

比如我们要实现把文件上传到 S3 的功能，那么代码可能是这样：

```kotlin
fun upload(bucket: String, key: String, fileContent: ByteArray) {
  val request = PutObjectRequest.builder()
    .bucket(bucket)
    .key(key)
    .build()
  s3Client.putObject(request, RequestBody.fromBytes(fileContent))
}

upload("upload-bucket", "fliename", fileContent)
```

可以看到，最后一行的调用代码需要一次性传递全部的参数。当参数过多时，这样的方式就会导致代码难以阅读。但是通过分析代码，我们可以把上面的步骤拆分成准备 `request` 对象和发出请求两个部分，从而得到下面的代码：

```kotlin
fun buildUploadRequest(bucket: String, key: String): (ByteArray) -> Unit {
  val request = PutObjectRequest.builder()
    .bucket(bucket)
    .key(key)
    .build()
  return { fileContent ->
    s3Client.putObject(request, RequestBody.fromBytes(fileContent))
  }
}

val upload = buildUploadRequest("upload-bucket", "filename")
upload(fileContent)
```

可以看到，原始的方法多了一个返回值，是一个接收 `ByteArray` 类型为参数、没有返回值的函数。所以在调用之后我们可以得到一个变量 `upload`，它就是这样一个函数。所以我们可以传递一个 `ByteArray` 类型的对象作为参数来调用它，从而执行上传操作。

实际上，我们并不是使用了柯里化，而是借用柯里化的思维设计出了一个高阶函数，把原本一步完成的步骤进行拆分，尽量让每一步都清晰明了，减少阅读的困难。

但是理解高阶函数需要一定的知识，并不是每一个人都能很容易地理解上面地代码。我在实际工作中地尝试也往往被吐槽看不懂。所以选择这种方式前，先想想项目中的小伙伴能不能看懂这种代码再做决定会好一点。

## 总结

以上是我对函数式对面向对象编程带来影响的简单思考。
总的来说，我们就是要以提高代码质量为目的，思考面向对象编程的各种范式背后的原因，分析函数式编程可以为此带来的改变。所谓他山之石可以攻玉，函数式编程就好像这个他山之石，可以帮助我们提高代码的可读性、安全性、可维护性等方面，帮助我们写出更好的代码。


