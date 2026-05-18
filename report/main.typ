#import "template.typ": *

#set page(paper: "a4", margin: 2cm)
#set text(font: "New Computer Modern", lang: "ru", size: 13pt)
// #set text(font: "Times New Roman")
#set par(justify: true)

#set text(lang: "ru", hyphenate: false)

#show link: set text(fill: blue)
#show link: underline

#show raw.where(block: true): it => align(center, block(
  fill: rgb("#EEEEEE"),
  inset: 5pt,
  radius: 8pt,
  width: auto,
  text(it)
))
#show raw.where(block: true): set text(1em * 0.78)
#show raw.where(block: false): it => box(
  fill: rgb("#EEEEEE"),
  inset: (x: 3pt),
  outset: (y: 3pt),
  radius: 3pt,
  it
)

#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  it
  v(0.3em)
}

#show heading: it => {
  it
  v(0.3em)
}

#show: template.with(
  title: [Лабораторная работа №4],
  description: [Технологии программирования],
  author: [
    Выполнили: \
    Пшеничников Артём Дмитриевич \
    Корепанов Олег Сергеевич \
    P3207 \
    Принял: \
    Кулинич Ярослав Вадимович
  ],
  variant: "24999"
)

#outline()

#set page(numbering: "1")

= Текст задания

Для своей программы из лабораторной работы #3 по дисциплине «Веб-программирование» реализовать:

+ MBean, считающий общее число установленных пользователем точек, а также число точек, попадающих в область. В случае, если количество установленных пользователем точек стало кратно 15, разработанный MBean должен отправлять оповещение об этом событии.
+ MBean, определяющий средний интервал между кликами пользователя по координатной плоскости.

С помощью утилиты JConsole провести мониторинг программы:

- Снять показания MBean-классов, разработанных в ходе выполнения задания.
- Определить время (в мс), прошедшее с момента запуска виртуальной машины.

С помощью утилиты VisualVM провести мониторинг и профилирование программы:

- Снять график изменения показаний MBean-классов, разработанных в ходе выполнения задания, с течением времени.
- Определить имя класса, объекты которого занимают наибольший объём памяти JVM; определить пользовательский класс, в экземплярах которого находятся эти объекты.

С помощью утилиты VisualVM и профилировщика IDE локализовать и устранить проблемы с производительностью в программе. По результатам необходимо составить отчёт, содержащий: описание проблемы, описание путей устранения, подробное описание алгоритма локализации со скриншотами.

= Разработанные MBean-классы

== Архитектура

В рамках задания реализованы два MBean-класса в пакете `lab.mbean`:

- `PointsCounter` — отслеживает общее число установленных пользователем точек и число попаданий в область, рассылает уведомления при достижении значения, кратного 15.
- `ClickInterval` — рассчитывает средний временной интервал между кликами пользователя по координатной плоскости.

Регистрация бинов в `MBeanServer` JVM выполняется при инициализации сервлет-контекста через `ServletContextListener`. Это гарантирует, что бины становятся доступны сразу после развёртывания WAR-приложения в WildFly. Вызовы методов бинов производятся из управляемого бина `lab.AreaBean` при обработке кликов пользователя.

== `PointsCounterMBean` (интерфейс)

Стандартный MBean-интерфейс:

```java
package lab.mbean;

public interface PointsCounterMBean {
    long getTotalPoints();
    long getHitPoints();
}
```

== `PointsCounter` (реализация)

Реализация наследуется от `NotificationBroadcasterSupport` для поддержки JMX-уведомлений. Метод `addPoint` синхронизирован, поскольку вызывается из нескольких сессий одновременно. При достижении значения `totalPoints`, кратного 15, формируется и отправляется уведомление типа `lab.mbean.points.multipleOf15`.

```java
package lab.mbean;

import javax.management.AttributeChangeNotification;
import javax.management.MBeanNotificationInfo;
import javax.management.Notification;
import javax.management.NotificationBroadcasterSupport;

public class PointsCounter extends NotificationBroadcasterSupport implements PointsCounterMBean {
    private long totalPoints = 0;
    private long hitPoints = 0;
    private long sequenceNumber = 1;

    @Override
    public long getTotalPoints() {
        return totalPoints;
    }

    @Override
    public long getHitPoints() {
        return hitPoints;
    }

    public synchronized void addPoint(boolean hit) {
        totalPoints++;
        if (hit) {
            hitPoints++;
        }

        if (totalPoints % 15 == 0) {
            Notification notification = new Notification(
                "lab.mbean.points.multipleOf15",
                this,
                sequenceNumber++,
                System.currentTimeMillis(),
                "Total points reached a multiple of 15: " + totalPoints
            );
            sendNotification(notification);
        }
    }

    @Override
    public MBeanNotificationInfo[] getNotificationInfo() {
        String[] types = new String[]{ "lab.mbean.points.multipleOf15" };
        String name = Notification.class.getName();
        String description = "Notification sent when total points is a multiple of 15";
        MBeanNotificationInfo info = new MBeanNotificationInfo(types, name, description);
        return new MBeanNotificationInfo[]{ info };
    }
}
```

== `ClickIntervalMBean` (интерфейс)

```java
package lab.mbean;

public interface ClickIntervalMBean {
    double getAverageInterval();
}
```

== `ClickInterval` (реализация)

Средний интервал вычисляется как отношение суммы интервалов между последовательными кликами к количеству зафиксированных интервалов. Использование переменной `lastClickTime = -1` как маркера «первый клик ещё не зафиксирован» позволяет корректно обрабатывать самый первый вызов `recordClick`.

#pagebreak()

```java
package lab.mbean;

public class ClickInterval implements ClickIntervalMBean {
    private long lastClickTime = -1;
    private long totalInterval = 0;
    private long clickCount = 0;

    @Override
    public synchronized double getAverageInterval() {
        if (clickCount == 0) return 0;
        return (double) totalInterval / clickCount;
    }

    public synchronized void recordClick() {
        long currentTime = System.currentTimeMillis();
        if (lastClickTime != -1) {
            totalInterval += (currentTime - lastClickTime);
            clickCount++;
        }
        lastClickTime = currentTime;
    }
}
```

== `MBeanRegistry` (регистрация в `MBeanServer`)

Класс содержит статические экземпляры MBean'ов и регистрирует их в платформенном `MBeanServer` под именами `lab.mbean:type=PointsCounter` и `lab.mbean:type=ClickInterval`. Проверка `isRegistered` обеспечивает идемпотентность регистрации.

#pagebreak()

```java
package lab.mbean;

import javax.management.MBeanServer;
import javax.management.ObjectName;
import java.lang.management.ManagementFactory;

public class MBeanRegistry {
    private static final PointsCounter pointsCounter = new PointsCounter();
    private static final ClickInterval clickInterval = new ClickInterval();

    public static void registerMBeans() {
        try {
            MBeanServer mbs = ManagementFactory.getPlatformMBeanServer();

            ObjectName pointsName = new ObjectName("lab.mbean:type=PointsCounter");
            if (!mbs.isRegistered(pointsName)) {
                mbs.registerMBean(pointsCounter, pointsName);
            }

            ObjectName clickName = new ObjectName("lab.mbean:type=ClickInterval");
            if (!mbs.isRegistered(clickName)) {
                mbs.registerMBean(clickInterval, clickName);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static PointsCounter getPointsCounter() {
        return pointsCounter;
    }

    public static ClickInterval getClickInterval() {
        return clickInterval;
    }
}
```

== `MBeanContextListener` (enter point)

Аннотация `@WebListener` подключает класс к жизненному циклу веб-приложения; метод `contextInitialized` вызывается единожды при развёртывании WAR.

```java
package lab.mbean;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;

@WebListener
public class MBeanContextListener implements ServletContextListener {
    @Override
    public void contextInitialized(ServletContextEvent sce) {
        MBeanRegistry.registerMBeans();
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
    }
}
```

== Интеграция в `AreaBean`

Управляемый бин `AreaBean` вызывает методы MBean'ов из двух точек обработки клика. Метод `checkCanvasClick` обрабатывает события клика по координатной плоскости (canvas) и сначала фиксирует время клика через `ClickInterval`, после чего делегирует обработку на `checkPoint`. Метод `processResult` после успешной вставки результата в БД увеличивает счётчик через `PointsCounter.addPoint`.

```java
public void checkCanvasClick() {
    MBeanRegistry.getClickInterval().recordClick();
    checkPoint();
}

private void processResult(double r) {
    boolean hit = checkHit(r);
    Result result = resultManager.insertResult(x, y, r, hit);
    if (resultsCache != null) {
        resultsCache.add(0, result);
    }
    MBeanRegistry.getPointsCounter().addPoint(hit);
}
```

= Мониторинг с помощью JConsole

== Подключение к серверу приложений

JConsole запускается командой `jconsole`. Поскольку WildFly развёрнут внутри Docker-контейнера, подключение производится через WildFly Remoting на порт `9990`. URL подключения имеет вид `service:jmx:remote+http://localhost:9990`. Для аутентификации указаны учётные данные админа (`admin` / `admin_password`).

Для работы JConsole по протоколу `remote+http` в classpath должна присутствовать библиотека `jboss-client.jar` из дистрибутива WildFly; запуск выполнялся командой:

```bash
jconsole -J-Djava.class.path=$JAVA_HOME/lib/jconsole.jar:$JAVA_HOME/lib/tools.jar:/path/to/jboss-client.jar
```

#figure(
  image("screenshots/image_2026-05-17_21-03-20.png", width: 60%),
  caption: [Output JConsole при подключении]
)

== Снятие показаний `PointsCounter`

В дереве MBeans раскрыт домен `lab.mbean`, выбран узел `PointsCounter → Attributes`. В таблице два атрибута: `TotalPoints` (общее число точек) и `HitPoints` (число попаданий в область).

#figure(
  image("screenshots/image_2026-05-17_21-03-46.png", width: 80%),
  caption: [Начальное состояние счётчика: `HitPoints = 0`, `TotalPoints = 0`.]
)

#figure(
  image("screenshots/image_2026-05-17_21-04-34.png", width: 80%, height: 40%),
  caption: [Состояние после нескольких кликов в приложении: `HitPoints = 1`, `TotalPoints = 3`. Обновление показаний MBean происходит синхронно с действиями пользователя.]
)

== Снятие показаний `ClickInterval`

Узел `ClickInterval → Attributes` содержит вычисляемый атрибут `AverageInterval` — средний интервал между последовательными кликами в миллисекундах.

#figure(
  image("screenshots/image_2026-05-17_21-15-11.png", width: 80%),
  caption: [Атрибут `AverageInterval = 462.0` мс: средний интервал между кликами пользователя.]
)

== Получение уведомлений

Подписка на уведомления выполняется во вкладке `Notifications` MBean'а `PointsCounter`. Уведомление формируется автоматически при каждом достижении `TotalPoints`, кратного 15.

#figure(
  image("screenshots/image_2026-05-17_21-06-00.png", width: 80%),
  caption: [Буфер уведомлений сразу после подписки — пустой.]
)

#figure(
  image("screenshots/image_2026-05-17_21-06-37.png", width: 80%, height: 40%),
  caption: [После добавления 15 точек: пришло одно уведомление типа `lab.mbean.points.multipleOf15` с сообщением `Total points reached...` и источником `lab.mbean:type=PointsCounter`.]
)

== Время с момента запуска JVM

Время работы виртуальной машины определяется из встроенного MBean'а платформы `java.lang.Runtime`, атрибут `Uptime` (в миллисекундах), либо со страницы `VM Summary`.

#figure(
  image("screenshots/image_2026-05-17_21-16-38.png", width: 90%),
  caption: [Страница `VM Summary`: указана отметка `Uptime` с момента запуска JVM и `Total compile time`. На момент скриншота uptime ≈17 минут с момента старта.]
)

== Выводы по результатам мониторинга

JConsole, входящая в состав стандартного JDK, позволяет в режиме реального времени:

- наблюдать значения атрибутов произвольных пользовательских MBean-классов через древовидный браузер;
- подписываться на пользовательские JMX-уведомления и видеть их историю в буфере;
- считывать показания платформенных MBean'ов (`java.lang.Runtime`, `Memory`, `Threading` и т.д.), в том числе для определения характеристик работы JVM.

Подключение к WildFly производится через специализированный протокол JBoss Remoting (`remote+http`) на порт `9990`.

= Мониторинг и профилирование с помощью VisualVM

== Подключение к серверу приложений

VisualVM подключается к JVM сервера приложений через JMX-агент. Поскольку WildFly работает в Docker-контейнере, для подключения добавлены опции запуска JVM в переменной `JAVA_OPTS_APPEND`:

```text
-Dcom.sun.management.jmxremote
-Dcom.sun.management.jmxremote.port=9010
-Dcom.sun.management.jmxremote.rmi.port=9010
-Dcom.sun.management.jmxremote.local.only=false
-Dcom.sun.management.jmxremote.authenticate=false
-Dcom.sun.management.jmxremote.ssl=false
-Djava.rmi.server.hostname=127.0.0.1
```

Также задана `JBOSS_MODULES_SYSTEM_PKGS=org.jboss.byteman,com.sun.management`, чтобы внутренний `JBoss Modules` ClassLoader делегировал поиск классов JMX-агента системному загрузчику. Подключение в VisualVM: `File → Add JMX Connection → localhost:9010`.

== Графики показаний MBean'ов

Для построения графиков на атрибуте MBean VisualVM запоминает последовательность значений и отображает их в виде непрерывной кривой.

#figure(
  image("screenshots/image_2026-05-17_23-25-58.png", width: 100%),
  caption: [Графики `HitPoints` (верхний, рост 0 → 14) и `TotalPoints` (нижний, рост 0 → 36) бина `PointsCounter` в окне VisualVM MBean Browser. ]
)

#figure(
  image("screenshots/image_2026-05-17_23-27-07.png", width: 100%),
  caption: [Начальный вид графика `AverageInterval` бина `ClickInterval`: после первой серии быстрых кликов накопилась статистика, виден высокий пик и постепенный спад значения.]
)

#figure(
  image("screenshots/image_2026-05-17_23-28-34.png", width: 100%),
  caption: [Установившееся значение `AverageInterval ≈ 13653` мс при равномерной нагрузке.]
)

== Анализ потребления памяти JVM

=== График использования heap

Вкладка `Monitor` показывает динамику использования heap-памяти JVM. Под нагрузкой наблюдается типичная «пилообразная» картина: память активно аллоцируется (рост) и периодически освобождается сборщиком мусора (резкие спады).

#figure(
  image("screenshots/image_2026-05-17_23-32-48.png", width: 100%),
  caption: [Вкладка `Monitor`: график использования heap-памяти. Used Heap (синяя линия) колеблется в диапазоне 75–160 МБ, после каждого GC возвращается к стабильной базовой линии ≈75 МБ — утечек на данном промежутке не выявлено.]
)

=== Heap dump: класс с наибольшим объёмом памяти

Снятие heap dump'а выполнено через `jcmd` внутри Docker-контейнера для последующего открытия в VisualVM:

```bash
docker compose exec server bash -c 'jcmd $(pgrep -f jboss-modules | head -1) GC.heap_dump /tmp/heap.hprof'
docker compose cp server:/tmp/heap.hprof ./heap.hprof
```

Это потребовалось ввиду того, что VisualVM при подключении по JMX к контейнерной JVM записывает heap dump во внутреннюю ФС контейнера, вследствие чего из интерфейса невозможно открыть полученный файл напрямую.

#figure(
  image("screenshots/image_2026-05-17_23-40-18.png", width: 100%),
  caption: [Открытый heap dump в виде `Objects → Aggregation: Classes`. В верхней части таблицы доминируют примитивные массивы и `java.lang.String`]
)

Класс с наибольшим суммарным объёмом памяти JVM — `byte[]`. Анализ цепочки ссылок этого класса показал, что подавляющую часть его экземпляров удерживают системные `java.util.zip.ZipFile$Source` (это central directory загруженных JAR-модулей WildFly).

=== Heap dump: пользовательский класс-владелец

Для нахождения пользовательского класса применён фильтр `lab.`:

#figure(
  image("screenshots/image_2026-05-18_00-11-00.png", width: 100%),
  caption: [Heap dump с фильтром `lab.`: в дампе зафиксировано 244 экземпляра `lab.Result`. В нижней панели `References` развёрнута цепочка владения: \ `lab.Result#1 → Object[]#35525 (244 items) → elementData в ArrayList#8999 (177 elements) → resultsCache в lab.AreaBean#1`, далее `AreaBean` находится в `HashMap$Node` сессии Undertow (`InMemorySessionManager$SessionImpl`).]
)

Таким образом, пользовательский класс, в экземплярах которого находятся объекты `lab.Result` — это `lab.AreaBean` (поле `resultsCache: ArrayList<Result>`). Бин -- session-scoped, поэтому накопление результатов происходит в пределах одной HTTP-сессии.

== Выводы по результатам профилирования

VisualVM (free, в отличие от JConsole — встроенной в JDK) предоставляет гораздо более широкий набор инструментов:

- *MBeans Browser* с возможностью построения графиков по атрибутам в реальном времени;
- *Monitor* с интегрированными графиками CPU, heap, classes loading и threads;
- *Sampler* для лёгкого статистического CPU- и memory-профилирования;
- работа с heap dump'ами: просмотр классов, экземпляров, References и GC roots.

Использование VisualVM позволило не только наблюдать показания MBean'ов в форме графиков, но и провести подробный анализ потребления памяти. Объекты доменной модели приложения (`lab.Result`) удерживаются в `ArrayList`-кеше внутри session-scoped управляемого бина `lab.AreaBean`, что указало на потенциальную область для оптимизации (см. раздел 4).

= Локализация и устранение проблемы производительности

== Описание выявленной проблемы

При нагрузочном тестировании приложения (серия из 100 последовательных ajax-запросов на проверку точки, отправленных через PrimeFaces `remoteCommand`) обнаружено, что суммарное время обработки серии существенно превышает теоретически ожидаемое, и *растёт от прогона к прогону в пределах одной сессии*:

#align(center, table(
  columns: (auto, auto),
  align: (left, right),
  inset: 6pt,
  [*Прогон в одной сессии*], [*Время 100 кликов*],
  [Первый], [≈20 557 мс],
  [Второй], [≈26 000 мс],
  [Третий], [≈30 000 мс],
))

Рост времени с увеличением размера сессии указывает на наличие операции с алгоритмической сложностью, не являющейся константой относительно числа уже обработанных кликов.

== Алгоритм локализации проблемы

=== Шаг 1. Базовый мониторинг (VisualVM Monitor)

Подключение к JVM через JMX, наблюдение за вкладкой `Monitor` при подаче нагрузки. CPU и heap демонстрируют активную работу, GC справляется, baseline стабилен — утечки памяти как таковой нет, но активный поток аллокаций при каждой обработке клика подтверждает гипотезу о неоптимальной работе с объектами.

=== Шаг 2. Анализ heap dump

Снятие дампа в момент типовой нагрузки, фильтрация классов по префиксу `lab.`. Обнаружено: `lab.Result` имеет 244 экземпляра, удерживаемых полем `resultsCache: ArrayList<Result>` бина `lab.AreaBean`. Цепочка References:

```
lab.Result#1
  ← [51] in Object[]#35525 (244 items)
    ← elementData in ArrayList#8999 (177 elements)
      ← resultsCache in lab.AreaBean#1
```

Это согласуется с реализацией: на каждый клик в `processResult` выполняется операция вставки в начало списка:

#pagebreak()

```java
private void processResult(double r) {
    boolean hit = checkHit(r);
    Result result = resultManager.insertResult(x, y, r, hit);
    if (resultsCache != null) {
        resultsCache.add(0, result);
    }
    MBeanRegistry.getPointsCounter().addPoint(hit);
}
```

Гипотеза: операция `ArrayList.add(0, element)` имеет сложность $O(N)$ из-за внутреннего `System.arraycopy`. Однако замеры в Sampler этого не подтвердили — на 100 кликах вклад `ArrayList.add` оказался незначимым по сравнению с другими операциями.

=== Шаг 3. CPU-сэмплирование (VisualVM Sampler)

Запуск `Sampler → CPU` под нагрузкой и переключение в `Reverse Calls` для метода `lab.AreaBean.processResult`:

#figure(
  image("screenshots/image_2026-05-18_00-58-09.png", width: 100%),
  caption: [Sampler Reverse Calls для `lab.AreaBean.processResult`. Видно, что 5160 мс из 5160 мс времени выполнения метода (на 2000 кликов) уходят в `lab.ResultManager.insertResult → org.postgresql.jdbc.PgPreparedStatement.executeQuery → QueryExecutorImpl.processResults → PGStream.read*`. \ CPU Time при этом всего 190 мс — то есть \~96 % времени метод проводит в ожидании сетевого ответа от PostgreSQL.]
)

Этот результат указывает на то, что основной вклад в задержку даёт не локальная работа с памятью, а обращение к БД в каждом вызове.

=== Шаг 4. Анализ HTTP-таймингов в DevTools

Чтобы понять, действительно ли сервер является «бутылочным горлышком», были проанализированы тайминги одиночного AJAX-запроса:

#figure(
  image("screenshots/Снимок экрана_20260518_010602.png", width: 80%),
  caption: [Тайминги одного AJAX-запроса до оптимизации: `Ожидание` (TTFB) = 15 мс — сервер обрабатывает запрос быстро. Однако `В очереди = 32.62 с` для одного из поздних запросов в серии — это означает, что запрос ждал ≈32 с в клиентской очереди браузера/JSF перед отправкой.]
)

Анализ выявил два важных факта:
+ Время обработки запроса сервером (TTFB) — всего 15 мс. Сам по себе JDBC-вызов не критичен.
+ Время «получения» (download) ответа — 48 мс и растёт от запроса к запросу.

Поскольку `<p:remoteCommand action="#{area.checkCanvasClick}" update="results">` обновляет HTML-фрагмент с таблицей результатов через `<ui:repeat value="#{area.results}">`, при каждом запросе JSF полностью перерендеривает таблицу. С ростом `resultsCache` растёт и размер ответа, и время рендеринга. Итоговая сложность серии из $N$ кликов — $O(N^2)$ как по передаваемым данным, так и по нагрузке на JSF.

== Описание пути устранения

Применены *две оптимизации*, нацеленные на разные участки кода.

=== Оптимизация 1: кэширование `PreparedStatement` и сокращение `RETURNING`

Исходная реализация `insertResult` создавала новый `PreparedStatement` через `try-with-resources` на каждый вызов и возвращала весь набор полей через `RETURNING *`:

#pagebreak()

```java
public Result insertResult(int x, double y, double r, boolean hit) {
    String sql = "INSERT INTO results(x, y, r, hit) VALUES (?, ?, ?, ?) RETURNING *";
    try (PreparedStatement statement = getConnection().prepareStatement(sql)) {
        statement.setInt(1, x);
        statement.setDouble(2, y);
        statement.setDouble(3, r);
        statement.setBoolean(4, hit);

        try (ResultSet resultSet = statement.executeQuery()) {
            if (!resultSet.next()) {
                throw new RuntimeException("INSERT INTO must return value");
            }
            return parseRow(resultSet);
        }
    } catch (SQLException e) {
        throw new RuntimeException("Error inserting result: " + e.getMessage(), e);
    }
}
```

Новая реализация выносит `PreparedStatement` в поле класса (что позволяет PostgreSQL JDBC-драйверу после 5 вызовов переключиться на server-side prepared statement) и сокращает возвращаемые данные до одного поля `id`. Остальные поля результата (известные на момент вставки) собираются локально без сетевого участия:

```java
private PreparedStatement insertStatement;

private PreparedStatement getInsertStatement() throws SQLException {
    if (insertStatement == null || insertStatement.isClosed()) {
        insertStatement = getConnection().prepareStatement(
            "INSERT INTO results(x, y, r, hit) VALUES (?, ?, ?, ?) RETURNING id"
        );
    }
    return insertStatement;
}

public Result insertResult(int x, double y, double r, boolean hit) {
    try {
        PreparedStatement statement = getInsertStatement();
        statement.setInt(1, x);
        statement.setDouble(2, y);
        statement.setDouble(3, r);
        statement.setBoolean(4, hit);

        try (ResultSet resultSet = statement.executeQuery()) {
            if (!resultSet.next()) {
                throw new RuntimeException("INSERT INTO must return value");
            }
            int id = resultSet.getInt("id");
            return new Result(id, x, y, r, hit);
        }
    } catch (SQLException e) {
        throw new RuntimeException("Error inserting result: " + e.getMessage(), e);
    }
}
```

=== Оптимизация 2: ограничение размера отображаемой таблицы

Анализ HTTP-таймингов показал, что доминирующий вклад в общее время серии запросов даёт не сервер сам по себе, а растущий размер AJAX-ответа из-за полного обновления таблицы. Решение — возвращать клиенту только последние $K$ результатов (для отображения в виде истории достаточно последних 10):

```java
private static final int DISPLAY_LIMIT = 10;

public List<Result> getResults() {
    if (resultsCache == null) {
        resultsCache = resultManager.getResults();
    }
    return resultsCache.subList(0, Math.min(DISPLAY_LIMIT, resultsCache.size()));
}
```

Так как `resultsCache.add(0, result)` помещает каждый новый результат в начало списка, `subList(0, 10)` возвращает 10 самых свежих результатов. Полная история по-прежнему сохраняется в БД и в `resultsCache`, но не передаётся в клиента на каждый клик.

== Сравнение «до» и «после»

После пересборки контейнера был выполнен повторный замер на свежей HTTP-сессии при идентичной нагрузке (100 ajax-запросов с интервалом 20 мс через PrimeFaces `checkPointCommand()` из браузерной консоли):

#align(center, table(
  columns: (auto, auto, auto, auto),
  align: (left, right, right, right),
  inset: 6pt,
  [*Метрика*], [*До*], [*После*], [*Изменение*],
  [Время серии из 100 кликов], [20 557 мс], [*2 146 мс*], [×9.6],
  [TTFB одного запроса], [15 мс], [11 мс], [≈×1.4],
  [Размер `Получение` ответа], [48 мс], [*0 мс*], [≈×50],
  [`В очереди` (поздний запрос)], [32.62 с], [9.12 с], [×3.6],
  [Рост времени между прогонами], [есть ($O(N^2)$)], [нет], [—],
))

#figure(
  image("screenshots/timings after fix.png", width: 80%),
  caption: [Тайминги одного AJAX-запроса после оптимизации: `Ожидание` (TTFB) = 11 мс, `Получение` = 0 мс (ответ помещается в один TCP-пакет), очередь снизилась почти в 4 раза.]
)

#figure(
  image("screenshots/Снимок экрана_20260518_014442.png", width: 100%),
  caption: [Sampler после оптимизации (Hot Spots / Reverse Calls для `lab.AreaBean.processResult`). Чтобы метод попал в выборку профилировщика, потребовалось прогнать несколько тысяч запросов — после фикса один вызов исполняется настолько быстро, что на меньшем числе вызовов в выборку попадал редко. Доля JDBC-операций в общем времени метода заметно снизилась благодаря кэшу `PreparedStatement` и сокращённому `RETURNING id`.]
)

#figure(
  image("screenshots/main page.png", width: 100%),
  caption: [Основная страница приложения после оптимизации: в таблице отображаются последние 10 результатов проверки точки, остальные сохраняются в БД и доступны через стандартный SELECT.]
)

== Выводы по разделу

Локализация проблемы потребовала комбинированного применения нескольких инструментов:

+ VisualVM Monitor — для общей картины поведения JVM (исключил гипотезу об утечке памяти).
+ VisualVM Heap Dump (Objects / References) — для определения структуры удерживаемых объектов и пользовательского класса-владельца.
+ VisualVM Sampler (Reverse Calls) — для понимания, где именно метод `processResult` проводит время (96% — в ожидании БД, а не на CPU).
+ Browser DevTools (Network → Timings) — для разделения времени обработки запроса (TTFB, на сервере) и передачи ответа (Download), а также для обнаружения клиентской очереди.

Ключевой вывод: профилировщик с одной точки зрения может ввести в заблуждение. Sampler корректно указал на вклад JDBC как преобладающий в CPU-времени метода, но реальное узкое место с точки зрения пользователя находилось вне Java-кода — в передаче растущего HTML-фрагмента и клиентской JSF-очереди.

Применённые оптимизации (кэш `PreparedStatement` + сокращение `RETURNING`; лимит размера таблицы при отдаче) дали суммарное ускорение в 9.6 раз и устранили рост времени между прогонами в пределах одной сессии.

= Выводы по работе

В рамках лабораторной работы освоены стандартные средства мониторинга и профилирования JVM-приложений из состава JDK и экосистемы Java:

- Разработаны и интегрированы пользовательские MBean-классы, реализующие модель `NotificationBroadcasterSupport` для оповещений и собственную бизнес-логику (счётчик точек, средний интервал между кликами). Регистрация бинов выполняется через `ServletContextListener` в момент инициализации веб-приложения.
- Освоено подключение к серверу приложений (WildFly в Docker-контейнере) обоими стандартными способами: через WildFly Remoting (`service:jmx:remote+http://...`) для JConsole и через стандартный JMX-RMI (`localhost:9010`) для VisualVM.
- Изучены возможности JConsole как инструмента для оперативного мониторинга: чтение атрибутов MBean'ов, подписка на уведомления, получение характеристик JVM (`Uptime`).
- Изучены возможности VisualVM как более полнофункционального инструмента: построение временных графиков по атрибутам MBean'ов, мониторинг heap/CPU/threads, снятие и анализ heap dump'ов (Classes, Instances, References, GC roots), CPU-сэмплирование с переключением между видами Hot Spots и Reverse Calls.
- Проведена самостоятельная локализация и устранение проблемы производительности в собственной программе с применением профилировщика, анализатора heap dump'а и инструментов браузера. Достигнуто ускорение стандартной пользовательской операции в ≈10 раз.

Основной вывод: мониторинг и оптимизация программы выполянютя не с помощью одного инструмента, а путем комбинирования нескольких (Monitor, Sampler, Heap Dump, Network), что даёт полную картину узких мест программы и позволяет эффективно их устранить.