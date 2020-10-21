# Репозитарий строк

## Почему это хорошо

Управляемые типы данных, имеют большие накладные расходы.
Это касается и string type.
Я прихожу уже к мысли, что кое где было бы полезно использовать некий репозитарий для строк.
Тогда мы вместо строки могли бы использовать PChar.

Хранить строки в можно словаре, вероятно это неплохая идея.
Поиск строки в хэшмап может быть реализована эффективно.
Обычно используемые строки, по большей части это immutable значения.

Обычно строки используются для описания метаданных, таких как имена полей, классов, значения перечислимых типов.
При разработки пользовательского интерфейса мы имеем дела с большим количеством надписей.

Например, когда мы передаём данные в json большая часть этих данных — это наименования полей. 
Если мы используем Google protocol buffer, для кодирования полей используются целочисленное кодирование без лидирующих нулей.

Использование алгоритмов сжатия подразумевают приличные накладные расходы.

Рассмотрим, к примеру, передачу табличных данных для отображения отчета.
Строковые данные — это имена колонок, стили отображения, ширина, способ выравнивания, ну и сами значения,
которые должны быть для каждой ячейки таблицы.
Можно выявить повторяющий при каждой передаче набор строковых данных для конкретного типа отчёта. 
То есть мы можем сказать вот вам набор данных для отчёта № 9.
Какие-то поля будут иметь весьма ограниченный набор значений на основе перечислимого типа.

## Постоянный репозитарий строк.
Неизменяемая часть данных, которая может быть в каждой передаче, должна быть задекларирована как составная часть конкретного формата данных и передаваться на клиентскую сторону один раз. 

## Переменный репозитарий строк.
Изменяемую часть передаем как значения полей или в отдельной части сообщения.
Также можно совместить эту часть данных с применяемой кодировкой данных и национального языка.