#Использовать asserts
#Использовать logos
#Использовать reflector
#Использовать sql
#Использовать strings

Перем Соединение;

Перем Лог;

Процедура ПриСозданииОбъекта()
	Соединение = Новый Соединение();
	Лог = Логирование.ПолучитьЛог("oscript.lib.entity.connector.sqlite");
КонецПроцедуры

Процедура Открыть(СтрокаСоединения, ПараметрыКоннектора) Экспорт
	Соединение.ТипСУБД = Соединение.ТипыСУБД.sqlite;
	Соединение.СтрокаСоединения = СтрокаСоединения;
	// Соединение.ИмяБазы = ОбъединитьПути(ТекущийКаталог(), "test.db");
	Соединение.Открыть();
КонецПроцедуры

Процедура Закрыть() Экспорт
	Соединение.Закрыть();
КонецПроцедуры

Функция Открыт() Экспорт
	Возврат Соединение.Открыто;
КонецФункции

Процедура НачатьТранзакцию() Экспорт
	Запрос = Новый Запрос();
	Запрос.УстановитьСоединение(Соединение);
	Запрос.Текст = "BEGIN TRANSACTION;";
	Запрос.ВыполнитьКоманду();
КонецПроцедуры

Процедура ЗафиксироватьТранзакцию() Экспорт
	Запрос = Новый Запрос();
	Запрос.УстановитьСоединение(Соединение);
	Запрос.Текст = "COMMIT;";
	Запрос.ВыполнитьКоманду();
КонецПроцедуры

Процедура ИнициализироватьТаблицу(ОбъектМодели) Экспорт
	
	КартаТипов = СоответствиеТиповМоделиИТиповКолонок();

	ИмяТаблицы = ОбъектМодели.ИмяТаблицы();
		
	ТекстЗапроса = "CREATE TABLE IF NOT EXISTS %1 (
	|%2
	|);";
	КолонкиТаблицы = ОбъектМодели.Колонки();
	Идентификатор = ОбъектМодели.Идентификатор();
	СтрокаОпределенийКолонок = "";
	Для Каждого Колонка Из КолонкиТаблицы Цикл
		
		СтрокаКолонка = "";
		СтрокаПервичныйКлюч = "";

		// Формирование строки-колонки
		СтрокаКолонка = Символы.Таб + Колонка.ИмяКолонки;
		Если Колонка.ТипКолонки = ТипыКолонок.Ссылка Тогда
			ОбъектМоделиСсылка = ОбъектМодели.МодельДанных().Получить(Колонка.ТипСсылки);
			ТипКолонки = КартаТипов.Получить(ОбъектМоделиСсылка.Идентификатор().ТипКолонки);

			СтрокаПервичныйКлюч = Символы.Таб + СтрШаблон(
				"FOREIGN KEY (%1) REFERENCES %2(%3),%4",
				Колонка.ИмяКолонки,
				ОбъектМоделиСсылка.ИмяТаблицы(),
				ОбъектМоделиСсылка.Идентификатор().ИмяКолонки,
				Символы.ПС
			);
		Иначе
			ТипКолонки = КартаТипов.Получить(Колонка.ТипКолонки);
		КонецЕсли;
		СтрокаКолонка = СтрокаКолонка + " " + ТипКолонки;
		Если Колонка.ИмяПоля = Идентификатор.ИмяПоля Тогда
			СтрокаКолонка = СтрокаКолонка + " PRIMARY KEY";
		КонецЕсли;
		Если Колонка.ГенерируемоеЗначение Тогда
			СтрокаКолонка = СтрокаКолонка + " AUTOINCREMENT";
		КонецЕсли;
		СтрокаКолонка = СтрокаКолонка + "," + Символы.ПС;
		
		СтрокаОпределенийКолонок = СтрокаОпределенийКолонок + СтрокаКолонка;
		
		Если ЗначениеЗаполнено(СтрокаПервичныйКлюч) Тогда
			СтрокаОпределенийКолонок = СтрокаОпределенийКолонок + СтрокаПервичныйКлюч;
		КонецЕсли;
	КонецЦикла;
	СтроковыеФункции.УдалитьПоследнийСимволВСтроке(СтрокаОпределенийКолонок, 2);

	ТекстЗапроса = СтрШаблон(ТекстЗапроса, ИмяТаблицы, СтрокаОпределенийКолонок);
	Лог.Отладка("Инициализация таблицы %1:%2%3", ИмяТаблицы, Символы.ПС, ТекстЗапроса);

	Запрос = Новый Запрос();
	Запрос.УстановитьСоединение(Соединение);
	Запрос.Текст = ТекстЗапроса;

	Запрос.ВыполнитьКоманду();
КонецПроцедуры

Процедура Сохранить(ОбъектМодели, Сущность) Экспорт
	// TODO: Таблица с единственным автополем - INSERT INTO first (id) VALUES (null);
	ИмяТаблицы = ОбъектМодели.ИмяТаблицы();
	КолонкиТаблицы = ОбъектМодели.Колонки();
	
	Запрос = Новый Запрос();
	Запрос.УстановитьСоединение(Соединение);
	
	ТекстЗапроса = "INSERT OR REPLACE INTO %1 (
	|%2
	|) VALUES (
	|%3
	|);";
	
	ИменаКолонок = "";
	ЗначенияКолонок = "";
	// TODO: преобразования типов? Дата в число и тому подобное
	Для Каждого ДанныеОКолонке Из КолонкиТаблицы Цикл
		ЗначениеПараметра = ОбъектМодели.ПолучитьПриведенноеЗначениеПоля(Сущность, ДанныеОКолонке.ИмяПоля);
		
		Если ДанныеОКолонке.ГенерируемоеЗначение И НЕ ЗначениеЗаполнено(ЗначениеПараметра) Тогда
			// TODO: Поддержка чего-то кроме автоинкремента
			Продолжить;
		КонецЕсли;
		ИменаКолонок = ИменаКолонок + Символы.Таб + ДанныеОКолонке.ИмяКолонки + "," + Символы.ПС;
		ЗначенияКолонок = ЗначенияКолонок + Символы.Таб + "@" + ДанныеОКолонке.ИмяКолонки + "," + Символы.ПС;
		
		ЗначениеПараметра = ОбъектМодели.ПолучитьПриведенноеЗначениеПоля(Сущность, ДанныеОКолонке.ИмяПоля);
		Запрос.УстановитьПараметр(ДанныеОКолонке.ИмяКолонки, ЗначениеПараметра);
	КонецЦикла;
	
	СтроковыеФункции.УдалитьПоследнийСимволВСтроке(ИменаКолонок, 2);
	СтроковыеФункции.УдалитьПоследнийСимволВСтроке(ЗначенияКолонок, 2);
	
	ТекстЗапроса = СтрШаблон(ТекстЗапроса, ИмяТаблицы, ИменаКолонок, ЗначенияКолонок);
	Запрос.Текст = ТекстЗапроса;

	Запрос.ВыполнитьКоманду();
	
	Если ОбъектМодели.Идентификатор().ГенерируемоеЗначение Тогда
		ИДПоследнейДобавленнойЗаписи = Запрос.ИДПоследнейДобавленнойЗаписи();
		ОбъектМодели.УстановитьЗначениеКолонкиВПоле(
			Сущность,
			ОбъектМодели.Идентификатор().ИмяКолонки,
			ИДПоследнейДобавленнойЗаписи
		);
	КонецЕсли;

	// TODO: Для полей с автоинкрементом - получить значения из базы.
	// по факту - просто переинициализировать класс значениями полей из СУБД.
	ЗаполнитьСущность(Сущность, ОбъектМодели);

КонецПроцедуры

// TODO: Стоит вынести в сам менеджер?
Функция ВыполнитьЗапрос(ТекстЗапроса) Экспорт

	Запрос = Новый Запрос();
	Запрос.УстановитьСоединение(Соединение);
	Запрос.Текст = ТекстЗапроса;
	Результат = Запрос.Выполнить().Выгрузить();
	
	Возврат Результат;

КонецФункции

Функция СоответствиеТиповМоделиИТиповКолонок()
	
	Карта = Новый Соответствие;
	Карта.Вставить(ТипыКолонок.Целое, "INTEGER");
	Карта.Вставить(ТипыКолонок.Строка, "TEXT");
	Карта.Вставить(ТипыКолонок.Дата, "DATE");
	Карта.Вставить(ТипыКолонок.Время, "TIME");
	Карта.Вставить(ТипыКолонок.ДатаВремя, "DATETIME");
	
	Возврат Карта;
	
КонецФункции

Процедура ЗаполнитьСущность(Сущность, ОбъектМодели)
	
	// TODO: Идеи на API:
	// МенеджерСущности::Получить вызывает Коннектор::ПолучитьЗначенияКолонокСущности(ОбъектМодели, Идентификатор)
	// Менеджер сущности создает/заполняет уже созданную сущность значениями колонок с автоприведением типов.
	// Коннектор обязан вернуть значения колонок примитивных типов в типах 1С, соответствующих карте типов ОбъектаМодели <-> ТипыКолонок
	// При обработке колонки с типом колонки "Ссылка", МенеджерСущности получает значения колонок сущности по подчиненному объекту модели
	// Таким образом в менеджере сохраняется общая логика для всех коннекторов,
	// а ответственность коннектора - вернуть ТЗ/Соответствие со значениями колонок

	ТекстЗапроса = СтрШаблон("SELECT * FROM %1", ОбъектМодели.ИмяТаблицы());;
	
	Запрос = Новый Запрос();
	Запрос.УстановитьСоединение(Соединение);
	Запрос.Текст = ТекстЗапроса;
	Результат = Запрос.Выполнить().Выгрузить();
	Ожидаем.Что(
		Результат, 
		СтрШаблон("Сущность с типом %1 и ИД %2 не найдена", ТипЗнч(Сущность), ОбъектМодели.ПолучитьЗначениеИдентификатора(Сущность))
	).ИмеетДлину(1);
	
	ДанныеИзБазы = Результат[0];
	ДанныеИзБазы.Идентификатор = 333;
	Для Каждого Колонка Из ОбъектМодели.Колонки() Цикл
		Если Колонка.Идентификатор Тогда
			Продолжить;
		КонецЕсли;
		Если Колонка.ТипКолонки = ТипыКолонок.Ссылка Тогда
			// TODO: Инициализация ссылочных типов
			// TODO: Кэш сущностей по типам и их идентификаторам для исключения создания новых сущностей с отличающимися указателями
			Продолжить;
		КонецЕсли;

		ОбъектМодели.УстановитьЗначениеКолонкиВПоле(
			Сущность,
			Колонка.ИмяКолонки,
			ДанныеИзБазы[Колонка.ИмяКолонки]
		);
	КонецЦикла;

КонецПроцедуры
