-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Хост: db-pl-sql
-- Время создания: Янв 02 2025 г., 00:04
-- Версия сервера: 9.1.0
-- Версия PHP: 8.2.25

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База данных: `db`
--

DELIMITER $$
--
-- Процедуры
--
CREATE DEFINER=`root`@`%` PROCEDURE `AddColumnMaxSum` ()   BEGIN
   ALTER TABLE `PRODUCTS`
DROP COLUMN `MAX_SUM`;

ALTER TABLE `PRODUCTS`
ADD COLUMN `MAX_SUM` 
    DECIMAL(10, 2) NOT NULL DEFAULT 0
 COMMENT 'Максимальная сумма операции';
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `FixIncorrectBalance` ()   BEGIN
    -- Временная таблица для хранения ID счетов с неверным балансом
    DROP TEMPORARY TABLE IF EXISTS incorrect_balances;
    CREATE TEMPORARY TABLE incorrect_balances (
        account_id INT,
        correct_saldo DECIMAL(18, 2)
    );
    -- Заполнение временной таблицы данными о неверных балансах
    INSERT INTO incorrect_balances (account_id, correct_saldo)
    SELECT
        a.`ID`,
        SUM(
            CASE
                WHEN r.`DT` = 1 THEN -r.`SUM`
                ELSE r.`SUM`
        END
    ) AS correct_saldo
    FROM
        `ACCOUNTS` a
    LEFT JOIN
        `RECORDS` r ON a.`ID` = r.`ACC_REF`
    GROUP BY
        a.`ID`;
    -- Обновление баланса для счетов с неверными значениями
    UPDATE `ACCOUNTS` a
    INNER JOIN incorrect_balances ib ON a.`ID` = ib.account_id
    SET
        a.`SALDO` = ib.correct_saldo
    WHERE
        a.`SALDO` <> COALESCE(ib.correct_saldo, 0);
    -- Очистка временной таблицы
    DROP TEMPORARY TABLE IF EXISTS incorrect_balances;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `OperationsLastMonthPivot` ()   BEGIN
    SET @sql = NULL;
    SELECT
        GROUP_CONCAT(DISTINCT
                     CONCAT(
                         'SUM(CASE WHEN r.`OPER_DATE` = ''',
                         r.`OPER_DATE`,
                         ''' THEN r.`SUM` ELSE 0 END) AS `',
                         r.`OPER_DATE`,
                         '`')
                    ) INTO @sql
    FROM
        `RECORDS` r
    WHERE
        r.`OPER_DATE` >= DATE_SUB(NOW(), INTERVAL 1 MONTH);
    SET @sql = CONCAT('SELECT ', @sql, ' FROM `RECORDS` r;');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `ACCOUNTS`
--

CREATE TABLE `ACCOUNTS` (
  `ID` int NOT NULL COMMENT 'Primary Key',
  `NAME` varchar(100) DEFAULT NULL,
  `SALDO` int DEFAULT NULL,
  `CLIENT_REF` int DEFAULT NULL,
  `OPER_DATE` date DEFAULT NULL,
  `CLOSE_DATE` date DEFAULT NULL,
  `PRODUCT_REF` int DEFAULT NULL,
  `ACC_NUM` varchar(25) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `ACCOUNTS`
--

INSERT INTO `ACCOUNTS` (`ID`, `NAME`, `SALDO`, `CLIENT_REF`, `OPER_DATE`, `CLOSE_DATE`, `PRODUCT_REF`, `ACC_NUM`) VALUES
(1, 'Кредитный счет для Сидоровым И.П.', -5000, 1, '2015-06-01', NULL, 1, '45502810401020000022'),
(2, 'Депозитный счет для Ивановым П.С.', 8000, 2, '2017-08-01', NULL, 2, '42301810400000000001'),
(3, 'Карточный счет для Петровым С.И.', 100000, 3, '2017-08-01', NULL, 3, '40817810700000000001'),
(4, 'Кредитный счет для Иванов И.И.', 0, 4, '2015-06-01', NULL, 1, '45502810401020010012'),
(5, 'Депозитный счет для Иванов И.И.', 0, 4, '2017-08-01', NULL, 2, '42301810400000000002'),
(6, 'Депозитный счет для Иванов И.И.', 0, 4, '2024-12-01', NULL, 2, '42301810400000000111'),
(7, 'Депозитный счет для Ивановым П.С.', 0, 2, '2024-12-01', NULL, 2, '42301810400000000001'),
(8, 'Кредитный счет для Иванов И.И.', 0, 4, '2024-12-22', NULL, 1, '45502810401020010013');

-- --------------------------------------------------------

--
-- Структура таблицы `CLIENTS`
--

CREATE TABLE `CLIENTS` (
  `ID` int NOT NULL COMMENT 'Primary Key',
  `NAME` varchar(1000) DEFAULT NULL,
  `PLACE_OF_BIRTH` varchar(1000) DEFAULT NULL,
  `DATE_OF_BIRTH` date DEFAULT NULL,
  `ADDRESS` varchar(1000) DEFAULT NULL,
  `PASSPORT` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `CLIENTS`
--

INSERT INTO `CLIENTS` (`ID`, `NAME`, `PLACE_OF_BIRTH`, `DATE_OF_BIRTH`, `ADDRESS`, `PASSPORT`) VALUES
(1, 'Сидоров Иван Петрович', 'Россия, Московская облать, г. Пушкин', '2001-01-01', 'Россия, Московская облать, г. Пушкин, ул. Грибоедова, д. 5', '2222 555555, выдан ОВД г. Пушкин, 10.01.2015'),
(2, 'Иванов Петр Сидорович', 'Россия, Московская облать, г. Клин', '2001-01-01', 'Россия, Московская облать, г. Клин, ул. Мясникова, д. 3', '4444 666666, выдан ОВД г. Клин, 10.01.2015'),
(3, 'Петров Сиодр Иванович', 'Россия, Московская облать, г. Балашиха', '2001-01-01', 'Россия, Московская облать, г. Балашиха, ул. Пушкина, д. 7', '4444 666666, выдан ОВД г. Клин, 10.01.2015'),
(4, 'Петров Сиодр Иванович', 'Россия, Московская облать, г. Балашиха', '2001-01-01', 'Россия, Московская облать, г. Балашиха, ул. Пушкина, д. 7', '4444 666666, выдан ОВД г. Клин, 10.01.2015');

-- --------------------------------------------------------

--
-- Структура таблицы `PRODUCTS`
--

CREATE TABLE `PRODUCTS` (
  `ID` int NOT NULL COMMENT 'Primary Key',
  `PRODUCT_TYPE_ID` int DEFAULT NULL,
  `NAME` varchar(100) DEFAULT NULL,
  `CLIENT_REF` int DEFAULT NULL,
  `OPEN_DATE` date DEFAULT NULL,
  `CLOSE_DATE` date DEFAULT NULL,
  `MAX_SUM` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT 'Максимальная сумма операции'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `PRODUCTS`
--

INSERT INTO `PRODUCTS` (`ID`, `PRODUCT_TYPE_ID`, `NAME`, `CLIENT_REF`, `OPEN_DATE`, `CLOSE_DATE`, `MAX_SUM`) VALUES
(1, 1, 'Кредитный договор с Сидоровым И.П.', 1, '2015-06-01', NULL, 5000.00),
(2, 2, 'Депозитный договор с Ивановым П.С.', 2, '2017-08-01', NULL, 20000000.00),
(3, 3, 'Карточный договор с Петровым С.И.', 3, '2017-08-01', NULL, 20000000.00),
(4, 1, 'Кредитный договор с Иванов И.И.', 4, '2015-06-01', '2025-01-01', 2000.00),
(5, 2, 'Депозитный договор с Иванов И.И.', 4, '2015-06-01', NULL, 20000000.00);

-- --------------------------------------------------------

--
-- Структура таблицы `PRODUCT_TYPES`
--

CREATE TABLE `PRODUCT_TYPES` (
  `ID` int NOT NULL COMMENT 'Primary Key',
  `NAME` varchar(100) DEFAULT NULL,
  `BEGIN_DATE` date DEFAULT NULL,
  `END_DATE` date DEFAULT NULL,
  `TARIF_REF` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `PRODUCT_TYPES`
--

INSERT INTO `PRODUCT_TYPES` (`ID`, `NAME`, `BEGIN_DATE`, `END_DATE`, `TARIF_REF`) VALUES
(1, 'КРЕДИТ', '2018-01-01', NULL, 1),
(2, 'ДЕПОЗИТ', '2018-01-01', NULL, 2),
(3, 'КАРТА', '2018-01-01', NULL, 3);

-- --------------------------------------------------------

--
-- Структура таблицы `RECORDS`
--

CREATE TABLE `RECORDS` (
  `ID` int NOT NULL COMMENT 'Primary Key',
  `DT` int DEFAULT NULL,
  `SUM` int DEFAULT NULL,
  `ACC_REF` int DEFAULT NULL,
  `OPER_DATE` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `RECORDS`
--

INSERT INTO `RECORDS` (`ID`, `DT`, `SUM`, `ACC_REF`, `OPER_DATE`) VALUES
(1, 1, 5000, 1, '2015-06-01'),
(2, 0, 1000, 1, '2015-07-01'),
(3, 0, 2000, 1, '2015-08-01'),
(4, 0, 3000, 1, '2015-09-01'),
(5, 1, 5000, 1, '2015-10-01'),
(6, 0, 3000, 1, '2015-10-01'),
(7, 0, 10000, 2, '2017-08-01'),
(8, 1, 1000, 2, '2017-08-05'),
(9, 1, 2000, 2, '2017-09-21'),
(10, 1, 5000, 2, '2017-10-24'),
(11, 0, 6000, 2, '2017-11-26'),
(12, 0, 120000, 3, '2017-09-08'),
(13, 1, 1000, 3, '2017-10-05'),
(14, 1, 2000, 3, '2017-10-21'),
(15, 1, 5000, 3, '2017-10-24'),
(16, 1, 5000, 3, '2024-12-01'),
(17, 1, 5000, 3, '2024-12-11'),
(18, 1, 2000, 3, '2024-12-21'),
(19, 1, 2000, 4, '2024-12-21'),
(20, 0, 2000, 4, '2024-12-21'),
(21, 0, 2000, 1, '2024-12-21'),
(22, 0, 2000, 1, '2024-12-22'),
(23, 0, 2000, 1, '2024-12-22'),
(24, 0, 10000, 1, '2024-12-22'),
(25, 1, 20000, 1, '2024-12-22'),
(26, 1, 2000, 4, '2024-12-22'),
(27, 1, 2000, 8, '2024-12-22'),
(28, 0, 2000, 8, '2024-12-22'),
(29, 1, 2000, 8, '2024-12-23'),
(30, 0, 2000, 8, '2024-12-23'),
(31, 1, 2000, 8, '2024-12-24'),
(32, 0, 2000, 8, '2024-12-25'),
(33, 0, 2000, 4, '2024-12-25');

-- --------------------------------------------------------

--
-- Структура таблицы `TARIFS`
--

CREATE TABLE `TARIFS` (
  `ID` int NOT NULL COMMENT 'Primary Key',
  `NAME` varchar(100) DEFAULT NULL,
  `COST` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `TARIFS`
--

INSERT INTO `TARIFS` (`ID`, `NAME`, `COST`) VALUES
(1, 'Тариф за выдачу кредита', 10),
(2, 'Тариф за открытие счета', 10),
(3, 'Тариф за обслуживание карты', 10);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `ViewClients_ticket7`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `ViewClients_ticket7` (
`ID` int
,`NAME` varchar(1000)
,`PLACE_OF_BIRTH` varchar(1000)
,`DATE_OF_BIRTH` date
,`ADDRESS` varchar(1000)
,`PASSPORT` varchar(100)
,`ACC_NUM` varchar(25)
,`SALDO` int
);

-- --------------------------------------------------------

--
-- Структура для представления `ViewClients_ticket7`
--
DROP TABLE IF EXISTS `ViewClients_ticket7`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `ViewClients_ticket7`  AS WITH     `tab` as (select `r`.`ACC_REF` AS `ACC_REF`,`r`.`DT` AS `DT`,(case when (`r`.`DT` = 0) then -(`r`.`SUM`) else `r`.`SUM` end) AS `correct_saldo` from (`RECORDS` `r` join `ACCOUNTS` `a` on((`r`.`ACC_REF` = `a`.`ID`))) where (`r`.`ACC_REF` = `a`.`ID`) order by `r`.`OPER_DATE` limit 1) select `c`.`ID` AS `ID`,`c`.`NAME` AS `NAME`,`c`.`PLACE_OF_BIRTH` AS `PLACE_OF_BIRTH`,`c`.`DATE_OF_BIRTH` AS `DATE_OF_BIRTH`,`c`.`ADDRESS` AS `ADDRESS`,`c`.`PASSPORT` AS `PASSPORT`,`a`.`ACC_NUM` AS `ACC_NUM`,`a`.`SALDO` AS `SALDO` from (((`CLIENTS` `c` join `ACCOUNTS` `a` on((`c`.`ID` = `a`.`CLIENT_REF`))) join `PRODUCTS` `p` on((`c`.`ID` = `p`.`CLIENT_REF`))) join `tab` `t` on((`a`.`ID` = `t`.`ACC_REF`))) where ((`p`.`PRODUCT_TYPE_ID` = 1) and (`p`.`CLOSE_DATE` is null) and (`a`.`SALDO` >= `t`.`correct_saldo`) and (`t`.`DT` = 1))  ;

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `ACCOUNTS`
--
ALTER TABLE `ACCOUNTS`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `ACC_CL_FK` (`CLIENT_REF`),
  ADD KEY `ACC_PROD_FK` (`PRODUCT_REF`);

--
-- Индексы таблицы `CLIENTS`
--
ALTER TABLE `CLIENTS`
  ADD PRIMARY KEY (`ID`);

--
-- Индексы таблицы `PRODUCTS`
--
ALTER TABLE `PRODUCTS`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `PROD_PRODTYPE_FK` (`PRODUCT_TYPE_ID`),
  ADD KEY `PROD_CL_FK` (`CLIENT_REF`);

--
-- Индексы таблицы `PRODUCT_TYPES`
--
ALTER TABLE `PRODUCT_TYPES`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `PROD_TYPE_TAR_FK` (`TARIF_REF`);

--
-- Индексы таблицы `RECORDS`
--
ALTER TABLE `RECORDS`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `REC_ACC_FK` (`ACC_REF`);

--
-- Индексы таблицы `TARIFS`
--
ALTER TABLE `TARIFS`
  ADD PRIMARY KEY (`ID`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `ACCOUNTS`
--
ALTER TABLE `ACCOUNTS`
  MODIFY `ID` int NOT NULL AUTO_INCREMENT COMMENT 'Primary Key', AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT для таблицы `CLIENTS`
--
ALTER TABLE `CLIENTS`
  MODIFY `ID` int NOT NULL AUTO_INCREMENT COMMENT 'Primary Key', AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT для таблицы `PRODUCTS`
--
ALTER TABLE `PRODUCTS`
  MODIFY `ID` int NOT NULL AUTO_INCREMENT COMMENT 'Primary Key', AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT для таблицы `PRODUCT_TYPES`
--
ALTER TABLE `PRODUCT_TYPES`
  MODIFY `ID` int NOT NULL AUTO_INCREMENT COMMENT 'Primary Key', AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `RECORDS`
--
ALTER TABLE `RECORDS`
  MODIFY `ID` int NOT NULL AUTO_INCREMENT COMMENT 'Primary Key', AUTO_INCREMENT=34;

--
-- AUTO_INCREMENT для таблицы `TARIFS`
--
ALTER TABLE `TARIFS`
  MODIFY `ID` int NOT NULL AUTO_INCREMENT COMMENT 'Primary Key', AUTO_INCREMENT=4;

--
-- Ограничения внешнего ключа сохраненных таблиц
--

--
-- Ограничения внешнего ключа таблицы `ACCOUNTS`
--
ALTER TABLE `ACCOUNTS`
  ADD CONSTRAINT `ACC_CL_FK` FOREIGN KEY (`CLIENT_REF`) REFERENCES `CLIENTS` (`ID`),
  ADD CONSTRAINT `ACC_PROD_FK` FOREIGN KEY (`PRODUCT_REF`) REFERENCES `PRODUCTS` (`ID`);

--
-- Ограничения внешнего ключа таблицы `PRODUCTS`
--
ALTER TABLE `PRODUCTS`
  ADD CONSTRAINT `PROD_CL_FK` FOREIGN KEY (`CLIENT_REF`) REFERENCES `CLIENTS` (`ID`),
  ADD CONSTRAINT `PROD_PRODTYPE_FK` FOREIGN KEY (`PRODUCT_TYPE_ID`) REFERENCES `PRODUCT_TYPES` (`ID`);

--
-- Ограничения внешнего ключа таблицы `PRODUCT_TYPES`
--
ALTER TABLE `PRODUCT_TYPES`
  ADD CONSTRAINT `PROD_TYPE_TAR_FK` FOREIGN KEY (`TARIF_REF`) REFERENCES `TARIFS` (`ID`);

--
-- Ограничения внешнего ключа таблицы `RECORDS`
--
ALTER TABLE `RECORDS`
  ADD CONSTRAINT `REC_ACC_FK` FOREIGN KEY (`ACC_REF`) REFERENCES `ACCOUNTS` (`ID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
