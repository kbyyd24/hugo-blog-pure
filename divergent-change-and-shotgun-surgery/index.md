# 发散式变化与霰弹式修改


发散式变化和霰弹式修改是 Martin Fowler 在《重构》中收录的两种代码坏味道。看到这两个名字时，我并不理解它们描述的是什么样的代码。也许我已经遇到过这样的代码，只是没有把它们叫做这两个名字而已。

今天我们就来看看这俩是什么样的坏味道。

== 发散式变化 Divergent Change

*发散式变化是指一个代码模块因为不同的原因在不同的方向上发生变化*。这里的不同原因可以是不同的业务需求、不同技术的实现等。比如下面这个例子：

[source,kotlin]
----
fun sendTicket(sendToUserId: String, ticket: Ticket) {
  val emailAddress = httpClient.get('http://account.service/accounts/${sendToUserId}/emailAddress').body
  val message = """
xxx
  xxx ${ticket.price}
  xxx ${ticket.productions}
xxx
"""
  emailService.send(from = 'ticket@xxx.com', to = emailAddress, cc = null, title = 'Ticket', message = message)
}
----

在这个只有几行代码的虚拟例子中，我们就能发现好几个关注点，比如处理根据 `sendToUserId` 拿到 `emailAddress` 的逻辑、组装邮件内容的逻辑和发送邮件的逻辑。这意味着每当一个关注点发生变化的时候，就需要修改这里的代码。比如获取用户的邮件地址的方式发生变化的时候、邮件内容需要修改的时候、发送邮件的方式变化的时候。

=== 为什么发散式变化是一个坏味道

上面的例子已经能够很好的回答这个问题。如果一段代码会因为不同的原因发生变化，那么意味着变化发生时，修改这部分的代码会变得困难。

困难之一是需要理解这里所有的代码才能做出正确的修改。

另一个困难的点是多个变化同时发生时，这里的代码很可能出现冲突。

=== 如何避免发散式变化

发散式变化的本质是耦合，把不同关注点的代码耦合到一个地方。所以要避免发散式变化，就需要识别出不同的关注点并解耦。

识别关注点需要搞清楚什么是业务、什么是技术、什么技术在处理什么问题。

用上面的例子来说，业务就是 "给用户的邮箱发送 ticket，ticket 应该长成xxx样" ；技术包括如何根据用户 ID 找到邮箱和如何发送邮件；使用 `httpClient` 解决了获取用户邮箱的问题、使用 `emailService` 解决了发送邮件的问题。所以应该把这三个关注点的代码实现分离到不同的地方。

解耦就是要把处理不同关注点的代码分开组织，放到不同的函数、类、文件中。

=== 如何修改发散式变化

不管多么小心，我们总是很难避免代码的坏味道，所以我们需要知道用什么样的方法可以修改这些坏味道。针对发散式变化，我们知道了核心是耦合，所以我们要做的就是解耦了。老马在书中给出了几种重构手法可以用来处理发散式变化：*拆分阶段*、*搬移函数*、*提炼函数*、*提炼类*

至于这几个重构手法如何操作，我想说懂得都懂🤪，不懂的，可以看看书。

== 霰弹式修改 Shotgun Surgery

了解了发散式变化，我们再来看看霰弹式修改。

*霰弹式修改是指每次发生某种变化，都需要到不同的地方做出修改*。

这是与发散式变化截然相反的坏味道。一个是在一个地方出现了处理不同事情的代码，一个是处理一件事的代码被分散到了不同的地方。

同样，我们在想一个例子：

[source,kotlin]
----
class AccountServiceAdaptor : AccountServicePort {
  fun getAccountById(accountId: String) : HttpResponse<Account> {
    return httpClient.get('http://account.service/accounts/${accountId}')
  }
}

class BusinessService {
  fun businessWork(accountId: String) {
    val accountResponse = accountServicePort.getAccountById(accountId)
    val account = accountResponse.takeIf { it.status == 200 }?.body ?: { throw SomeException() }
    // business works
  }
}
----

在这个例子中，根据用户 ID 获取用户信息的代码被分散在了两个地方：`AccountServieAdaptor` 和 `BusinessService` 。那么当获取用户信息的方式发生变化时，这两个地方的代码都会发生变化。比如从缓存中获取用户信息，那么就不再需要处理 HTTP Status Code。

除了上面这个例子，重复的代码也有可能导致霰弹式修改。

=== 为什么霰弹式修改是一个坏味道

这个问题的答案应该是不言而喻的。当一个变化发生，却需要修改多个地方的代码时，意味着处理这个问题的代码不够内聚。这样的代码意味着当改变发生的时候，需要修改多个地方的代码甚至是重复的代码才能完成修改，这很容易导致遗漏，从而导致 bug。

=== 如何避免霰弹式修改

霰弹式修改的本质是内聚，没有把息息相关的代码放到一起做到高内聚。所以要避免霰弹式修改，也要识别出关注点，然后把处理同一个关注点的代码内聚到一起。

用上面的例子来说，`businessWork` 和 `根据用户 ID 获取用户信息` 是两个不同的关注点，所以我们应该把处理这两个关注点的代码分隔开，各自放到一起。

[source,kotlin]
----
class AccountServiceAdaptor : AccountServicePort {
  fun getAccountById(accountId: String) : Account {
    return httpClient.get('http://account.service/accounts/${accountId}')
                     .takeIf { it.status == 200 }
                     ?.body
                     ?: { throw SomeException() }
  }
}

class BusinessService {
  fun businessWork(accountId: String) {
    val account = accountServicePort.getAccountById(accountId)
    // business works
  }
}
----

=== 如何修改霰弹式修改

同样的，老马在书中也给出了修改的手法，这里也只是列出来：**搬移函数**、**搬移字段**、**函数组合成类**、**函数组合成变换**、**拆分阶段**、**内联函数**、**内联类**

== 总结

我们可以认为发散式变化在强调低耦合，把不相关的代码分离到不同的地方；霰弹式修改在强调高内聚，把相关的代码放到同一个地方。

它们的名字看起来有点隐晦，难以顾名思义。但是它们其实就是我们一直推崇的**高内聚、低耦合**。

