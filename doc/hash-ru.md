Dictionaries, Hashing and Performance

Ускорение поиска для хэшмап в таком случае равен ~ 1/N, где N это размер таблицы.

Пока таблица заполнена не полностью менее чем < 0.7
таблица работает хорошо, а потом наступает деградации производительности.

В таких случаях увеличивают размер таблицы и все данные перемещаются в новую таблицу.
На это требуется дополнительное время.
Это также означает, что пока вы это не сделает ваша система не сможет обслуживать клиентов.

По моему, где то до 16 элементов, лучше использовать обычный 
несортированный список и линейный поиск.
Далее имеет смысл использовать 
либр TList с сортировкой при каждом добавлении нового ключа, ~ N * log2(N) для quicksort, либо дерево, в котором поиск и вставка с поддерживанием упорядоченности является недорогой log2(N).

Либо хэшмап.
Поиск по хэшмап включает генерацию hash + от 1 до m сравнений на равенство.

Идеальная функция хеширования:
1. должна быть быстрой
2. не создаёт коллизий (не формирует одинаковый ключ для разных ключей)

В своё время я сравнивал самые разные хэш функции и понял, что даже самые простые функции обеспечивают неплохой результат на реальных данных.

Я проверял на базе данных адресов с порядка миллиона записей и для клиентской базы порядка 500 тысяч записей.
алгоритмы включали md5, sha-2, sha-3, src32, multiplicative hash.

Для строк полезна функция, которая при расчёте хэша учитывает длину строки в символах.
Для чисел с плавающей запятой лучше использовать алгоритм который отдельно хеширует экспоненту и мантиссу числа.
Если это объект или запись, иногда имеет смысл написать свою функцию, в которой будут хешироваться избранные ключевые поля объекта.

Мне нравятся реализации хэш таблиц с цепочками.
Обычно я знаю примерное количество объектов в системе и могу сразу установить требуемый размер таблицы входов N.
Нет смысла увеличивать размер таблицы намного больше N.

Так как полученный при поиске определятся индекс входа
индекс_входа := хэш mod N;

Нельзя выбирать размер таблицы  кратный байту, это увеличивает скученность данных в таблице.

Для многих алгоритмов хеширования, если выбрать размер отличный от простого числа, увеличится вероятность коллизий и это ухудшит статистику.