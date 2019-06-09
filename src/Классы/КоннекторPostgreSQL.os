#Использовать logos
#Использовать strings
#Использовать semaphore

Перем КоннекторSQL;
Перем КонструкторКоннектора Экспорт;
Перем Соединение Экспорт;
Перем КартаТипов;

Перем Лог Экспорт;

// Конструктор объекта КоннекторPostgreSQL.
//
Процедура ПриСозданииОбъекта()
	
	Лог = Логирование.ПолучитьЛог("oscript.lib.entity.connector.postgresql");
	КоннекторSQL = Новый АбстрактныйКоннекторSQL(ЭтотОбъект, Лог);

	КонструкторКоннектора = ПолучитьКонструкторКоннектора();
	Соединение = КонструкторКоннектора.НовыйСоединение();
	КартаТипов = СоответствиеТиповМоделиИТиповКолонок();

КонецПроцедуры

// Открыть соединение с БД.
//
// Параметры:
//   СтрокаСоединения - Строка - Строка соединения с БД.
//   ПараметрыКоннектора - Массив - Дополнительные параметры инициализации коннектора.
//
Процедура Открыть(СтрокаСоединения, ПараметрыКоннектора) Экспорт
	КонструкторКоннектора.Открыть(Соединение, СтрокаСоединения);
КонецПроцедуры

// Закрыть соединение с БД.
//
Процедура Закрыть() Экспорт
	КонструкторКоннектора.Закрыть(Соединение);
КонецПроцедуры

// Получить статус соединения с БД.
//
//  Возвращаемое значение:
//   Булево - Состояние соединения. Истина, если соединение установлено и готово к использованию.
//       В обратном случае - Ложь.
//
Функция Открыт() Экспорт
	Возврат Соединение.Открыто;
КонецФункции

// Начинает новую транзакцию в БД.
//
Процедура НачатьТранзакцию() Экспорт
	Запрос = КонструкторКоннектора.НовыйЗапрос(Соединение);
	Запрос.Текст = "START TRANSACTION;";
	Запрос.ВыполнитьКоманду();
КонецПроцедуры

// Фиксирует открытую транзакцию в БД.
//
Процедура ЗафиксироватьТранзакцию() Экспорт
	Запрос = КонструкторКоннектора.НовыйЗапрос(Соединение);
	Запрос.Текст = "COMMIT;";
	Запрос.ВыполнитьКоманду();
КонецПроцедуры

// Отменяет открытую транзакцию в БД.
//
Процедура ОтменитьТранзакцию() Экспорт
	Запрос = КонструкторКоннектора.НовыйЗапрос(Соединение);
	Запрос.Текст = "ROLLBACK;";
	Запрос.ВыполнитьКоманду();
КонецПроцедуры


// Создает таблицу в БД по данным модели.
//
// Параметры:
//   ОбъектМодели - ОбъектМодели - Объект, содержащий описание класса-сущности и настроек таблицы БД.
//
Процедура ИнициализироватьТаблицу(ОбъектМодели) Экспорт

	КоннекторSQL.ИнициализироватьТаблицу(ОбъектМодели);

КонецПроцедуры

// Сохраняет сущность в БД.
//
// Параметры:
//   ОбъектМодели - ОбъектМодели - Объект, содержащий описание класса-сущности и настроек таблицы БД.
//   Сущность - Произвольный - Объект (экземпляр класса, зарегистрированного в модели) для сохранения в БД.
//
Процедура Сохранить(ОбъектМодели, Сущность) Экспорт

	ИмяТаблицы = ОбъектМодели.ИмяТаблицы();
	КолонкиТаблицы = ОбъектМодели.Колонки();
	
	Запрос = КонструкторКоннектора.НовыйЗапрос(Соединение);
	
	КолонкаИдентификатор = ОбъектМодели.Идентификатор().ИмяКолонки;
	ЭтоВставкаОбъекта = Ложь;
	СоздаватьНовыйИдентификатор = Ложь;

	ИменаКолонок = "";
	ЗначенияКолонок = "";
	СтрокаОбновления = "";
	
	Если КолонкиТаблицы.Количество() = 1 И ОбъектМодели.Идентификатор().ГенерируемоеЗначение Тогда
		
		ИменаКолонок = Символы.Таб + ОбъектМодели.Идентификатор().ИмяКолонки;
		ЗначенияКолонок = Символы.Таб + "null";

		ЗначениеПараметра = ОбъектМодели.ПолучитьПриведенноеЗначениеПоля(Сущность, ОбъектМодели.Идентификатор().ИмяКолонки);
		Если Не ЗначениеЗаполнено(ЗначениеПараметра) Тогда
			СоздаватьНовыйИдентификатор = Истина;
		КонецЕсли;
	Иначе
		Для Каждого ДанныеОКолонке Из КолонкиТаблицы Цикл
			ЗначениеПараметра = ОбъектМодели.ПолучитьПриведенноеЗначениеПоля(Сущность, ДанныеОКолонке.ИмяПоля);

			Если ДанныеОКолонке.ГенерируемоеЗначение И НЕ ЗначениеЗаполнено(ЗначениеПараметра) Тогда

				ЭтоВставкаОбъекта = Истина;
				СоздаватьНовыйИдентификатор = Истина;
				Продолжить;

			КонецЕсли;

			Если ДанныеОКолонке.Идентификатор И ЗначениеЗаполнено(ЗначениеПараметра) Тогда
				ЭтоВставкаОбъекта = Истина; 
			КонецЕсли;

			ЭтоПустаяСсылка = 
				ДанныеОКолонке.ТипКолонки = ТипыКолонок.Ссылка 
				И (ЗначениеПараметра = 0 Или ЗначениеПараметра = Неопределено);

			ИменаКолонок = ИменаКолонок + Символы.Таб + ДанныеОКолонке.ИмяКолонки + "," + Символы.ПС;
			ЗначенияКолонок = ЗначенияКолонок 
				+ Символы.Таб 
				+ ?(ЭтоПустаяСсылка, "null", "@" + ДанныеОКолонке.ИмяКолонки) 
				+ "," + Символы.ПС;

			Если Не ДанныеОКолонке.Идентификатор Тогда

				ЗначениеОбновления = ?(ЭтоПустаяСсылка, "null", "@" + ДанныеОКолонке.ИмяКолонки);
				СтрокаОбновления = СтрокаОбновления + СтрШаблон(" %1 = %2,", ДанныеОКолонке.ИмяКолонки, ЗначениеОбновления); 
			КонецЕсли;

			Если Не ЭтоПустаяСсылка Тогда
				Запрос.УстановитьПараметр(ДанныеОКолонке.ИмяКолонки, ЗначениеПараметра);
			КонецЕсли;

		КонецЦикла;
		
		СтроковыеФункции.УдалитьПоследнийСимволВСтроке(ИменаКолонок, 2);
		СтроковыеФункции.УдалитьПоследнийСимволВСтроке(ЗначенияКолонок, 2);
	КонецЕсли;

	СтрокаОбновления = Лев(СтрокаОбновления, СтрДлина(СтрокаОбновления) - 1);

	Если КолонкиТаблицы.Количество() = 1 И СоздаватьНовыйИдентификатор Тогда

		ТекстЗапроса = СтрШаблон("INSERT INTO ""%1"" DEFAULT VALUES;", ИмяТаблицы);
		ЭтоВставкаОбъекта = Истина;

	Иначе
		ТекстЗапроса = 
			"INSERT INTO %1 (
			|%2
			|) VALUES (
			|%3
			|)%4;";

		ТекстОбновления = ?(
			ПустаяСтрока(СтрокаОбновления), 
			"", 
			СтрШаблон("ON CONFLICT (%1) DO UPDATE SET %2", КолонкаИдентификатор, СтрокаОбновления));

		ТекстЗапроса = СтрШаблон(
			ТекстЗапроса, 
			ИмяТаблицы, 
			ИменаКолонок, 
			ЗначенияКолонок,
			ТекстОбновления
		);

	КонецЕсли;

	Лог.Отладка("Сохранение сущности с типом %1:%2%3", ОбъектМодели.ТипСущности(), Символы.ПС, ТекстЗапроса);
	
	Семафор = Семафоры.Получить(Строка(ОбъектМодели.ТипСущности()));
	Семафор.Захватить();
	Запрос.Текст = ТекстЗапроса;
	Сообщить(ТекстЗапроса);
	Запрос.ВыполнитьКоманду();

	Если ОбъектМодели.Идентификатор().ГенерируемоеЗначение Тогда

		Если ЭтоВставкаОбъекта Тогда
			ПараметрыЗапросаИдентификатора = Новый Структура("ИмяТаблицы, ИмяКолонки", ИмяТаблицы, КолонкаИдентификатор);
			ИДПоследнейДобавленнойЗаписи =  
				КонструкторКоннектора.ИДПоследнейДобавленнойЗаписи(Соединение, ПараметрыЗапросаИдентификатора);
		Иначе
			ИДПоследнейДобавленнойЗаписи = ОбъектМодели.ПолучитьПриведенноеЗначениеПоля(Сущность, КолонкаИдентификатор);
		КонецЕсли;

		ОбъектМодели.УстановитьЗначениеКолонкиВПоле(
			Сущность,
			ОбъектМодели.Идентификатор().ИмяКолонки,
			ИДПоследнейДобавленнойЗаписи
		);
	КонецЕсли;
	Семафор.Освободить();

КонецПроцедуры

// Удаляет сущность из таблицы БД.
//
// Параметры:
//   ОбъектМодели - ОбъектМодели - Объект, содержащий описание класса-сущности и настроек таблицы БД.
//   Сущность - Произвольный - Объект (экземпляр класса, зарегистрированного в модели) для удаления из БД.
//
Процедура Удалить(ОбъектМодели, Сущность) Экспорт

	КоннекторSQL.Удалить(ОбъектМодели, Сущность);

КонецПроцедуры


// Осуществляет поиск строк в таблице по указанному отбору.
//
// Параметры:
//   ОбъектМодели - ОбъектМодели - Объект, содержащий описание класса-сущности и настроек таблицы БД.
//   Отбор - Массив - Отбор для поиска. Каждый элемент массива должен иметь тип "ЭлементОтбора".
//       Каждый элемент отбора преобразуется к условию поиска. В качестве "ПутьКДанным" указываются имена колонок.
//
//  Возвращаемое значение:
//   Массив - Массив, элементами которого являются "Соответствия". Ключом элемента соответствия является имя колонки,
//     значением элемента соответствия - значение колонки.
//
Функция НайтиСтрокиВТаблице(ОбъектМодели, Знач Отбор) Экспорт

	Возврат КоннекторSQL.НайтиСтрокиВТаблице(ОбъектМодели, Отбор);

КонецФункции

// Удаляет строки в таблице по указанному отбору.
//
// Параметры:
//   ОбъектМодели - ОбъектМодели - Объект, содержащий описание класса-сущности и настроек таблицы БД.
//   Отбор - Массив - Отбор для поиска. Каждый элемент массива должен иметь тип "ЭлементОтбора".
//       Каждый элемент отбора преобразуется к условию поиска. В качестве "ПутьКДанным" указываются имена колонок.
//
Процедура УдалитьСтрокиВТаблице(ОбъектМодели, Знач Отбор) Экспорт

	КоннекторSQL.УдалитьСтрокиВТаблице(ОбъектМодели, Отбор);

КонецПроцедуры

// @Unstable
// Выполнить произвольный запрос и получить результат.
//
// Данный метод не входит в основной интерфейс "Коннектор".
// Не рекомендуется использовать этот метод в прикладном коде, сигнатура метода может измениться.
//
// Параметры:
//   ТекстЗапроса - Строка - Текст выполняемого запроса
//
//  Возвращаемое значение:
//   ТаблицаЗначений - Результат выполнения запроса.
//
Функция ВыполнитьЗапрос(ТекстЗапроса) Экспорт

	Возврат КоннекторSQL.ВыполнитьЗапрос(ТекстЗапроса);

КонецФункции

Функция СоответствиеТиповМоделиИТиповКолонок()
	
	Карта = Новый Соответствие;
	Карта.Вставить(ТипыКолонок.Целое, "integer");
	Карта.Вставить(ТипыКолонок.Дробное, "decimal");
	Карта.Вставить(ТипыКолонок.Булево, "boolean");
	Карта.Вставить(ТипыКолонок.Строка, "text");
	Карта.Вставить(ТипыКолонок.Дата, "date");
	Карта.Вставить(ТипыКолонок.Время, "time");
	Карта.Вставить(ТипыКолонок.ДатаВремя, "timestamp");
	
	Возврат Карта;
	
КонецФункции

Функция ПолучитьТипКолонкиСУБД(ОбъектМодели, КолонкаМодели) Экспорт

	ТипКолонкиСУБД = Неопределено;
	
	Если КолонкаМодели.ТипКолонки = ТипыКолонок.Ссылка Тогда
		ОбъектМоделиСсылка = ОбъектМодели.МодельДанных().Получить(КолонкаМодели.ТипСсылки);
		ТипКолонкиСУБД = КартаТипов.Получить(ОбъектМоделиСсылка.Идентификатор().ТипКолонки);
	ИначеЕсли ТипыКолонок.ЭтоПримитивныйТип(КолонкаМодели.ТипКолонки) Тогда
		ТипКолонкиСУБД = КартаТипов.Получить(КолонкаМодели.ТипКолонки);
		Если КолонкаМодели.ГенерируемоеЗначение Тогда
			ТипКолонкиСУБД = "serial";
		КонецЕсли;
	Иначе
		ВызватьИсключение "Неизвестный тип колонки " + КолонкаМодели.ТипКолонки;
	КонецЕсли;
	
	Возврат ТипКолонкиСУБД;

КонецФункции

Функция ПолучитьОписаниеВнешнегоКлюча(ОбъектМодели, КолонкаМодели) Экспорт

	Возврат КоннекторSQL.ПолучитьОписаниеВнешнегоКлюча(ОбъектМодели, КолонкаМодели);

КонецФункции

#Область Подключение_коннектора_СУБД

Функция ПолучитьКонструкторКоннектора() 
	
	ПутьККлассам = ОбъединитьПути(
		ТекущийСценарий().Каталог,
		"..",
		"internal",
		"ДинамическиПодключаемыеКлассы"
	);

	Попытка
		А = Вычислить("ПользователиИнформационнойБазы");
		ПутьККоннектору = ОбъединитьПути(
			ПутьККлассам,
			"КонструкторКоннектораPostgreSQLWeb.os"
		);
	Исключение
		ПутьККоннектору = ОбъединитьПути(
			ПутьККлассам,
			"КонструкторКоннектораPostgreSQL.os"
		);
	КонецПопытки;

	Возврат ЗагрузитьСценарий(ПутьККоннектору);
	
КонецФункции

#КонецОбласти