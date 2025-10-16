-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 16, 2025 at 10:34 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `workmanager_st`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `clonare_proiect_template` (IN `p_id_template` INT, IN `p_denumire_nou_proiect` VARCHAR(150), OUT `p_id_nou_proiect` INT)   BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_id_categorie_template INT;
    DECLARE v_denumire_categorie VARCHAR(150);
    DECLARE v_timp_alocat DECIMAL(10,2);
    DECLARE v_prioritate INT;
    DECLARE v_buget_alocat DECIMAL(15,2);
    DECLARE cur_categorii CURSOR FOR
        SELECT id_categorie_sarcina, denumire_categorie, timp_alocat_total_ore, prioritate, buget_alocat
        FROM categorie_sarcina
        WHERE id_proiect = p_id_template;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Creăm noul proiect, copiem doar tip_proiect, timp_alocat_total_ore și buget_alocat
    INSERT INTO proiecte (denumire, tip_proiect, timp_alocat_total_ore, buget_alocat, buget_efectiv, este_template)
    SELECT p_denumire_nou_proiect, tip_proiect, timp_alocat_total_ore, buget_alocat, 0, 0
    FROM proiecte
    WHERE id_proiect = p_id_template;

    SET p_id_nou_proiect = LAST_INSERT_ID();

    -- Iterăm prin categoriile template-ului
    OPEN cur_categorii;
    read_loop: LOOP
        FETCH cur_categorii INTO v_id_categorie_template, v_denumire_categorie, v_timp_alocat, v_prioritate, v_buget_alocat;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Creăm categoria nouă pentru proiectul nou
        INSERT INTO categorie_sarcina (id_proiect, denumire_categorie, timp_alocat_total_ore, prioritate, buget_alocat)
        VALUES (p_id_nou_proiect, v_denumire_categorie, v_timp_alocat, v_prioritate, v_buget_alocat);

        SET @v_noua_categorie_id = LAST_INSERT_ID();

        -- Clonăm sarcinile din categoria template în categoria nou creată, copiem doar nume_sarcina, timp_alocat_ore, buget_alocat, prioritate
        INSERT INTO sarcina (id_categorie_sarcina, nume_sarcina, timp_alocat_ore, buget_alocat, prioritate)
        SELECT @v_noua_categorie_id, nume_sarcina, timp_alocat_ore, buget_alocat, prioritate
        FROM sarcina
        WHERE id_categorie_sarcina = v_id_categorie_template;

    END LOOP;
    CLOSE cur_categorii;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_actualizeaza_statistici` (IN `p_id_categorie_sarcina` INT)   BEGIN
    DECLARE v_id_proiect INT;

    -- Actualizare bugete pentru categoria de sarcini
    UPDATE categorie_sarcina cs
    SET 
        cs.timp_alocat_total_ore = IFNULL((
            SELECT SUM(s.timp_alocat_ore)
            FROM sarcina s
            WHERE s.id_categorie_sarcina = cs.id_categorie_sarcina
        ), 0),
        cs.timp_utilizat_total_ore = IFNULL((
            SELECT SUM(s.timp_utilizat)
            FROM sarcina s
            WHERE s.id_categorie_sarcina = cs.id_categorie_sarcina
        ), 0),
        cs.buget_alocat = IFNULL((
            SELECT SUM(s.buget_alocat)
            FROM sarcina s
            WHERE s.id_categorie_sarcina = cs.id_categorie_sarcina
        ), 0),
        cs.buget_efectiv = IFNULL((
            SELECT SUM(s.buget_efectiv)
            FROM sarcina s
            WHERE s.id_categorie_sarcina = cs.id_categorie_sarcina
        ), 0)
    WHERE cs.id_categorie_sarcina = p_id_categorie_sarcina;

    -- Preluăm proiectul asociat categoriei
    SELECT id_proiect INTO v_id_proiect
    FROM categorie_sarcina
    WHERE id_categorie_sarcina = p_id_categorie_sarcina;

    -- Actualizare bugete pentru proiectul respectiv
    UPDATE proiecte p
    SET 
        p.timp_alocat_total_ore = IFNULL((
            SELECT SUM(cs.timp_alocat_total_ore)
            FROM categorie_sarcina cs
            WHERE cs.id_proiect = p.id_proiect
        ), 0),
        p.buget_alocat = IFNULL((
            SELECT SUM(cs.buget_alocat)
            FROM categorie_sarcina cs
            WHERE cs.id_proiect = p.id_proiect
        ), 0),
        p.timp_utilizat_total_ore = IFNULL((
            SELECT SUM(cs.timp_utilizat_total_ore)
            FROM categorie_sarcina cs
            WHERE cs.id_proiect = p.id_proiect
        ), 0),
        p.buget_efectiv = IFNULL((
            SELECT SUM(cs.buget_efectiv)
            FROM categorie_sarcina cs
            WHERE cs.id_proiect = p.id_proiect
        ), 0)
    WHERE p.id_proiect = v_id_proiect;
END$$

--
-- Functions
--
CREATE DEFINER=`root`@`localhost` FUNCTION `calculeaza_data_finalizare_estimata` (`p_data_start` DATE, `p_timp_alocat_ore` INT) RETURNS DATE DETERMINISTIC BEGIN
    DECLARE v_zile_necesare INT;
    DECLARE v_data_curenta DATE;
    DECLARE v_zile_adaugate INT DEFAULT 0;

    -- Calculăm numărul de zile lucrătoare necesare
    SET v_zile_necesare = CEIL(p_timp_alocat_ore / 8);
    SET v_data_curenta = p_data_start;

    -- Parcurgem zilele până când avem suficiente zile lucrătoare
    WHILE v_zile_adaugate < v_zile_necesare DO
        SET v_data_curenta = DATE_ADD(v_data_curenta, INTERVAL 1 DAY);

        -- verificăm dacă ziua curentă este sâmbătă sau duminică
        IF DAYOFWEEK(v_data_curenta) NOT IN (1, 7)
           AND v_data_curenta NOT IN (SELECT data_sarbatoare FROM sarbatori_legale)
        THEN
            SET v_zile_adaugate = v_zile_adaugate + 1;
        END IF;
    END WHILE;

    RETURN v_data_curenta;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fn_calculeaza_zile_lucratoare` (`data_inceput` DATE, `data_sfarsit` DATE) RETURNS INT(11)  BEGIN
    DECLARE total_zile INT;
    DECLARE saptamani_complete INT;
    DECLARE zile_extra INT;
    DECLARE nr_weekenduri INT;
    DECLARE contor INT;
    DECLARE zi_curenta INT;
    DECLARE nr_sarbatori INT;

    -- Dacă datele nu sunt valide
    IF data_inceput IS NULL OR data_sfarsit IS NULL OR data_sfarsit < data_inceput THEN
        RETURN 0;
    END IF;

    -- Calculăm numărul total de zile calendaristice
    SET total_zile = DATEDIFF(data_sfarsit, data_inceput) + 1;

    -- Numărul de săptămâni complete (fiecare are 2 zile de weekend)
    SET saptamani_complete = total_zile DIV 7;
    SET nr_weekenduri = saptamani_complete * 2;

    -- Calculăm câte zile rămân după săptămânile complete (0–6 zile)
    SET zile_extra = total_zile - saptamani_complete * 7;
    SET contor = 0;

    -- Verificăm câte din zilele rămase sunt weekenduri
    WHILE contor < zile_extra DO
        SET zi_curenta = WEEKDAY(DATE_ADD(data_inceput, INTERVAL contor DAY));  -- 0=Luni ... 6=Duminică
        IF zi_curenta IN (5,6) THEN
            SET nr_weekenduri = nr_weekenduri + 1;
        END IF;
        SET contor = contor + 1;
    END WHILE;

    -- Numărăm sărbătorile legale din tabel care se află în interval și care NU cad în weekend
    SELECT COUNT(*) INTO nr_sarbatori
    FROM sarbatori_legale
    WHERE data_sarbatoare BETWEEN data_inceput AND data_sfarsit
      AND WEEKDAY(data_sarbatoare) NOT IN (5,6);

    -- Rezultatul final = total zile - weekenduri - sărbători legale
    RETURN total_zile - nr_weekenduri - IFNULL(nr_sarbatori, 0);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `categorie`
--

CREATE TABLE `categorie` (
  `id_categorie` int(11) NOT NULL,
  `tip_utilizator` enum('internal','subcontractor','beneficiar') NOT NULL,
  `nume_categorie` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categorie_permisiune`
--

CREATE TABLE `categorie_permisiune` (
  `id_categorie` int(11) NOT NULL,
  `id_permisiune` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categorie_sarcina`
--

CREATE TABLE `categorie_sarcina` (
  `id_categorie_sarcina` int(11) NOT NULL,
  `id_proiect` int(11) NOT NULL,
  `denumire_categorie` varchar(150) NOT NULL,
  `timp_alocat_total_ore` decimal(10,2) DEFAULT 0.00,
  `timp_utilizat_total_ore` decimal(10,2) DEFAULT 0.00,
  `data_inceput` date DEFAULT NULL,
  `data_finalizare_estimata` date DEFAULT NULL,
  `data_finalizare_efectiva` date DEFAULT NULL,
  `status_timp` enum('eficient','in timp','intarziat') DEFAULT 'in timp',
  `prioritate` int(11) DEFAULT 0,
  `buget_alocat` decimal(15,2) DEFAULT 0.00,
  `buget_efectiv` decimal(15,2) DEFAULT 0.00,
  `este_template` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `concediu`
--

CREATE TABLE `concediu` (
  `id_cerere` int(11) NOT NULL,
  `nr_matricol` int(11) DEFAULT NULL,
  `tip_concediu` enum('medical','invoire','maternal','special','odihna','altele') NOT NULL,
  `data_inceput` date NOT NULL,
  `data_sfarsit` date NOT NULL,
  `nr_zile_calculate` int(11) DEFAULT 0,
  `status` enum('initiat','in procesare','aprobat','respins') DEFAULT 'initiat',
  `cale_documente` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `concediu`
--
DELIMITER $$
CREATE TRIGGER `trg_cale_concediu` BEFORE INSERT ON `concediu` FOR EACH ROW BEGIN
    DECLARE dep VARCHAR(100);
    DECLARE nume_prenume VARCHAR(150);

    SELECT CONCAT(nume, '_', prenume), departament
    INTO nume_prenume, dep
    FROM utilizator
    WHERE nr_matricol = NEW.nr_matricol;

    SET NEW.cale_documente = CONCAT('DOCUMENTE_ANGAJATI/', dep, '/', nume_prenume, '/CERERI_CONCEDIU/');
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_nr_zile_concediu_before_insert` BEFORE INSERT ON `concediu` FOR EACH ROW BEGIN
    SET NEW.nr_zile_calculate = fn_calculeaza_zile_lucratoare(NEW.data_inceput, NEW.data_sfarsit);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_nr_zile_concediu_before_update` BEFORE UPDATE ON `concediu` FOR EACH ROW BEGIN
    SET NEW.nr_zile_calculate = fn_calculeaza_zile_lucratoare(NEW.data_inceput, NEW.data_sfarsit);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_scade_zile_concediu_delete` AFTER DELETE ON `concediu` FOR EACH ROW BEGIN
    -- Verificăm dacă concediul șters era de tip 'odihna' și aprobat
    IF OLD.status = 'aprobat' AND OLD.tip_concediu = 'odihna' THEN
        UPDATE utilizator
        SET zile_concediu_utilizate = GREATEST(zile_concediu_utilizate - OLD.nr_zile_calculate, 0)
        WHERE nr_matricol = OLD.nr_matricol;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_update_concediu_utilizate` AFTER UPDATE ON `concediu` FOR EACH ROW BEGIN
    IF NEW.status = 'aprobat' AND OLD.status != 'aprobat' AND NEW.tip_concediu = 'odihna' THEN
        UPDATE utilizator
        SET zile_concediu_utilizate = zile_concediu_utilizate + NEW.nr_zile_calculate
        WHERE nr_matricol = NEW.nr_matricol;
    END IF;
    
    IF OLD.status = 'aprobat' AND NEW.status != 'aprobat' AND NEW.tip_concediu = 'odihna' THEN
        UPDATE utilizator
        SET zile_concediu_utilizate = GREATEST(zile_concediu_utilizate - OLD.nr_zile_calculate, 0)
        WHERE nr_matricol = NEW.nr_matricol;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `permisiune`
--

CREATE TABLE `permisiune` (
  `id_permisiune` int(11) NOT NULL,
  `denumire` varchar(100) NOT NULL,
  `descriere` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `proiecte`
--

CREATE TABLE `proiecte` (
  `id_proiect` int(11) NOT NULL,
  `denumire` varchar(150) NOT NULL,
  `tip_proiect` varchar(50) DEFAULT NULL,
  `stadiu` enum('definire','ofertare','licitatie','respins','executie','asistenta tehnica','arhivare') DEFAULT 'definire',
  `manager_responsabil` int(11) DEFAULT NULL,
  `timp_alocat_total_ore` decimal(10,2) DEFAULT 0.00,
  `timp_utilizat_total_ore` decimal(10,2) DEFAULT 0.00,
  `data_inceput` date DEFAULT NULL,
  `data_finalizare_estimata` date DEFAULT NULL,
  `data_finalizare_efectiva` date DEFAULT NULL,
  `buget_alocat` decimal(15,2) DEFAULT 0.00,
  `buget_efectiv` decimal(15,2) DEFAULT 0.00,
  `beneficiar` varchar(100) DEFAULT NULL,
  `cale_documente` varchar(255) DEFAULT NULL,
  `este_template` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `proiecte`
--
DELIMITER $$
CREATE TRIGGER `trg_cale_proiect` BEFORE INSERT ON `proiecte` FOR EACH ROW BEGIN
    SET NEW.cale_documente = CONCAT(
        'PROIECTE/',
        NEW.tip_proiect, '/',
        NEW.denumire, '/'
    );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `sarbatori_legale`
--

CREATE TABLE `sarbatori_legale` (
  `data_sarbatoare` date NOT NULL,
  `descriere` varchar(100) DEFAULT NULL,
  `este_constanta` tinyint(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `sarbatori_legale`
--

INSERT INTO `sarbatori_legale` (`data_sarbatoare`, `descriere`, `este_constanta`) VALUES
('2025-01-01', 'Anul Nou', 1),
('2025-01-02', 'Anul Nou', 1),
('2025-01-06', 'Boboteaza', 1),
('2025-01-07', 'Sfantul Ioan Botezatorul', 1),
('2025-01-24', 'Ziua Unirii Principatelor Romane', 1),
('2025-04-18', 'Vinerea Mare - Paste Ortodox', 0),
('2025-04-21', 'A doua zi de Paste Ortodox', 0),
('2025-05-01', 'Ziua Muncii', 1),
('2025-06-01', 'Ziua Copilului', 1),
('2025-06-09', 'A doua zi de Rusalii', 0),
('2025-08-15', 'Adormirea Maicii Domnului', 1),
('2025-11-30', 'Sfantul Andrei', 1),
('2025-12-01', 'Ziua Nationala a Romaniei', 1),
('2025-12-25', 'Craciunul', 1),
('2025-12-26', 'A doua zi de Craciun', 1);

-- --------------------------------------------------------

--
-- Table structure for table `sarcina`
--

CREATE TABLE `sarcina` (
  `id_sarcina` int(11) NOT NULL,
  `id_categorie_sarcina` int(11) NOT NULL,
  `nume_sarcina` varchar(150) NOT NULL,
  `utilizator_responsabil` int(11) DEFAULT NULL,
  `timp_alocat_ore` decimal(10,2) NOT NULL,
  `data_inceput` date DEFAULT NULL,
  `data_finalizare_estimata` date DEFAULT NULL,
  `data_finalizare_efectiva` date DEFAULT NULL,
  `timp_utilizat` decimal(10,2) DEFAULT 0.00,
  `buget_alocat` decimal(15,2) DEFAULT NULL,
  `buget_efectiv` decimal(15,2) DEFAULT 0.00,
  `status` enum('in planificare','in lucru','blocat','clarificare','verificare','finalizat') DEFAULT 'in planificare',
  `prioritate` int(11) DEFAULT 0,
  `status_timp` enum('eficient','in timp','intarziat') DEFAULT 'in timp',
  `comentarii` text DEFAULT NULL,
  `cale_documente` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `sarcina`
--
DELIMITER $$
CREATE TRIGGER `trg_calc_indice_performanta` AFTER UPDATE ON `sarcina` FOR EACH ROW BEGIN
    DECLARE ore_ramase DECIMAL(10,2);
    DECLARE zile_ramase DECIMAL(10,2);
    DECLARE crestere DECIMAL(5,2);

    -- Doar dacă sarcina a fost finalizată și a fost făcută eficient
    IF NEW.status = 'finalizat' AND NEW.status_timp = 'eficient' THEN
        SET ore_ramase = GREATEST(NEW.timp_alocat_ore - NEW.timp_utilizat, 0);
        SET zile_ramase = ore_ramase / 8;
        SET crestere = zile_ramase * 0.20; -- 20% per zi

        UPDATE utilizator
        SET indice_performanta = indice_performanta + crestere
        WHERE nr_matricol = NEW.utilizator_responsabil;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_calcul_buget_sarcina` BEFORE INSERT ON `sarcina` FOR EACH ROW BEGIN
    DECLARE salariu_ora_utilizator DECIMAL(10,2);
    SELECT salariu_ora INTO salariu_ora_utilizator
    FROM utilizator
    WHERE nr_matricol = NEW.utilizator_responsabil;

    SET NEW.buget_alocat = salariu_ora_utilizator * NEW.timp_alocat_ore;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_calculeaza_buget_efectiv_insert` BEFORE INSERT ON `sarcina` FOR EACH ROW BEGIN
    IF NEW.utilizator_responsabil IS NOT NULL THEN
        SET NEW.buget_efectiv = (
            SELECT IFNULL(salariu_ora, 0) * NEW.timp_utilizat
            FROM utilizator
            WHERE nr_matricol = NEW.utilizator_responsabil
        );
    ELSE
        SET NEW.buget_efectiv = 0;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_calculeaza_buget_efectiv_update` BEFORE UPDATE ON `sarcina` FOR EACH ROW BEGIN
    IF NEW.utilizator_responsabil IS NOT NULL THEN
        SET NEW.buget_efectiv = (
            SELECT IFNULL(salariu_ora, 0) * NEW.timp_utilizat
            FROM utilizator
            WHERE nr_matricol = NEW.utilizator_responsabil
        );
    ELSE
        SET NEW.buget_efectiv = 0;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_calculeaza_data_finalizare_sarcina` BEFORE INSERT ON `sarcina` FOR EACH ROW BEGIN
    -- Dacă nu este specificată manual, calculăm data estimată de finalizare
    IF NEW.data_inceput IS NOT NULL AND NEW.timp_alocat_ore IS NOT NULL THEN
        SET NEW.data_finalizare_estimata = calculeaza_data_finalizare_estimata(NEW.data_inceput, NEW.timp_alocat_ore);
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_cale_sarcina` BEFORE INSERT ON `sarcina` FOR EACH ROW BEGIN
    DECLARE v_id_proiect INT;
    DECLARE v_tip_proiect VARCHAR(50);
    DECLARE v_nume_proiect VARCHAR(150);
    DECLARE v_nume_categorie VARCHAR(150);
    DECLARE v_este_template BOOLEAN;

    -- Verificăm dacă sarcina este legată la o categorie
    IF NEW.id_categorie_sarcina IS NOT NULL THEN

        --  Preluăm informațiile despre categorie și proiect
        SELECT 
            c.id_proiect,
            p.tip_proiect,
            p.denumire,
            p.este_template,
            c.denumire_categorie
        INTO 
            v_id_proiect,
            v_tip_proiect,
            v_nume_proiect,
            v_este_template,
            v_nume_categorie
        FROM categorie_sarcina c
        JOIN proiecte p ON p.id_proiect = c.id_proiect
        WHERE c.id_categorie_sarcina = NEW.id_categorie_sarcina
        LIMIT 1;

        --  Verificăm dacă proiectul nu este template
        IF v_este_template = FALSE THEN
            --  Construim calea documentelor
                  SET NEW.cale_documente = CONCAT(
                        'PROIECTE/',
                v_tip_proiect, '/',
                v_nume_proiect, '/',
                v_nume_categorie, '/',
                NEW.nume_sarcina, '/'
                  );
        	ELSE
              -- Pentru template-uri, nu generăm cale
            SET NEW.cale_documente = NULL;
        END IF;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_status_timp_eficient` BEFORE UPDATE ON `sarcina` FOR EACH ROW BEGIN
    IF NEW.status = 'finalizat' AND NEW.timp_utilizat < NEW.timp_alocat_ore THEN
        SET NEW.status_timp = 'eficient';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_status_timp_intarziat` BEFORE UPDATE ON `sarcina` FOR EACH ROW BEGIN
    IF NEW.timp_utilizat > NEW.timp_alocat_ore THEN
        SET NEW.status_timp = 'intarziat';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_update_buget_sarcina` BEFORE UPDATE ON `sarcina` FOR EACH ROW BEGIN
    DECLARE salariu_ora_utilizator DECIMAL(10,2);
    IF NEW.utilizator_responsabil != OLD.utilizator_responsabil OR NEW.timp_alocat_ore != OLD.timp_alocat_ore THEN
        SELECT salariu_ora INTO salariu_ora_utilizator
        FROM utilizator
        WHERE nr_matricol = NEW.utilizator_responsabil;
        SET NEW.buget_alocat = salariu_ora_utilizator * NEW.timp_alocat_ore;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_update_data_finalizare_sarcina` BEFORE UPDATE ON `sarcina` FOR EACH ROW BEGIN
    -- Dacă s-a modificat timpul alocat sau data de start, recalculează estimarea
    IF (NEW.timp_alocat_ore <> OLD.timp_alocat_ore OR NEW.data_inceput <> OLD.data_inceput)
       AND NEW.data_inceput IS NOT NULL THEN
        SET NEW.data_finalizare_estimata = calculeaza_data_finalizare_estimata(NEW.data_inceput, NEW.timp_alocat_ore);
    END IF;

    -- Dacă statusul devine 'finalizata', setează data efectivă
    IF NEW.status = 'finalizata' AND OLD.status <> 'finalizata' THEN
        SET NEW.data_finalizare_efectiva = CURDATE();
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_update_finalizare_sarcina_delete` AFTER DELETE ON `sarcina` FOR EACH ROW BEGIN
    DECLARE v_id_categorie INT;
    DECLARE v_id_proiect INT;

    -- Preluăm categoria sarcinii șterse
    SET v_id_categorie = OLD.id_categorie_sarcina;

    -- Preluăm proiectul asociat categoriei
    SELECT id_proiect INTO v_id_proiect
    FROM categorie_sarcina
    WHERE id_categorie_sarcina = v_id_categorie;

    -- Recalculăm datele finale pentru categoria de sarcini
    UPDATE categorie_sarcina
    SET 
        data_finalizare_estimata = (
            SELECT MAX(data_finalizare_estimata)
            FROM sarcina
            WHERE id_categorie_sarcina = v_id_categorie
        ),
        data_finalizare_efectiva = (
            SELECT MAX(data_finalizare_efectiva)
            FROM sarcina
            WHERE id_categorie_sarcina = v_id_categorie
        )
    WHERE id_categorie_sarcina = v_id_categorie;

    -- Recalculăm datele finale pentru proiect
    UPDATE proiecte
    SET 
        data_finalizare_estimata = (
            SELECT MAX(data_finalizare_estimata)
            FROM categorie_sarcina
            WHERE id_proiect = v_id_proiect
        ),
        data_finalizare_efectiva = (
            SELECT MAX(data_finalizare_efectiva)
            FROM categorie_sarcina
            WHERE id_proiect = v_id_proiect
        )
    WHERE id_proiect = v_id_proiect;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_update_finalizare_sarcina_insert` AFTER INSERT ON `sarcina` FOR EACH ROW BEGIN
    DECLARE v_id_categorie INT;
    DECLARE v_id_proiect INT;
    
    -- Identificăm categoria și proiectul
    SET v_id_categorie = NEW.id_categorie_sarcina;
    
    SELECT id_proiect INTO v_id_proiect
    FROM categorie_sarcina
    WHERE id_categorie_sarcina = v_id_categorie;
    
    -- Actualizăm data_finalizare_estimata pentru categoria de sarcini
    UPDATE categorie_sarcina
    SET data_finalizare_estimata = (
        SELECT MAX(data_finalizare_estimata)
        FROM sarcina
        WHERE id_categorie_sarcina = v_id_categorie
    ),
        data_finalizare_efectiva = (
        SELECT MAX(data_finalizare_efectiva)
        FROM sarcina
        WHERE id_categorie_sarcina = v_id_categorie
    )
    WHERE id_categorie_sarcina = v_id_categorie;
    
    -- Actualizăm data_finalizare_estimata pentru proiect
    UPDATE proiecte
    SET data_finalizare_estimata = (
        SELECT MAX(data_finalizare_estimata)
        FROM categorie_sarcina
        WHERE id_proiect = v_id_proiect
    ),
        data_finalizare_efectiva = (
        SELECT MAX(data_finalizare_efectiva)
        FROM categorie_sarcina
        WHERE id_proiect = v_id_proiect
    )
    WHERE id_proiect = v_id_proiect;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_update_finalizare_sarcina_update` AFTER UPDATE ON `sarcina` FOR EACH ROW BEGIN
    DECLARE v_id_categorie INT;
    DECLARE v_id_proiect INT;
    
    SET v_id_categorie = NEW.id_categorie_sarcina;
    
    SELECT id_proiect INTO v_id_proiect
    FROM categorie_sarcina
    WHERE id_categorie_sarcina = v_id_categorie;
    
    -- Actualizăm categoria de sarcini
    UPDATE categorie_sarcina
    SET data_finalizare_estimata = (
        SELECT MAX(data_finalizare_estimata)
        FROM sarcina
        WHERE id_categorie_sarcina = v_id_categorie
    ),
        data_finalizare_efectiva = (
        SELECT MAX(data_finalizare_efectiva)
        FROM sarcina
        WHERE id_categorie_sarcina = v_id_categorie
    )
    WHERE id_categorie_sarcina = v_id_categorie;
    
    -- Actualizăm proiectul
    UPDATE proiecte
    SET data_finalizare_estimata = (
        SELECT MAX(data_finalizare_estimata)
        FROM categorie_sarcina
        WHERE id_proiect = v_id_proiect
    ),
        data_finalizare_efectiva = (
        SELECT MAX(data_finalizare_efectiva)
        FROM categorie_sarcina
        WHERE id_proiect = v_id_proiect
    )
    WHERE id_proiect = v_id_proiect;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_update_statistici_sarcina_delete` AFTER DELETE ON `sarcina` FOR EACH ROW BEGIN
    CALL sp_actualizeaza_statistici(OLD.id_categorie_sarcina);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_update_statistici_sarcina_insert` AFTER INSERT ON `sarcina` FOR EACH ROW BEGIN
    CALL sp_actualizeaza_statistici(NEW.id_categorie_sarcina);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_update_statistici_sarcina_update` AFTER UPDATE ON `sarcina` FOR EACH ROW BEGIN
    -- Dacă s-a schimbat categoria de sarcini, actualizăm ambele
    IF OLD.id_categorie_sarcina <> NEW.id_categorie_sarcina THEN
        CALL sp_actualizeaza_statistici(OLD.id_categorie_sarcina);
        CALL sp_actualizeaza_statistici(NEW.id_categorie_sarcina);
    ELSE
        CALL sp_actualizeaza_statistici(NEW.id_categorie_sarcina);
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `utilizator`
--

CREATE TABLE `utilizator` (
  `nr_matricol` int(11) NOT NULL,
  `email` varchar(100) NOT NULL,
  `parola` varchar(100) NOT NULL,
  `prenume` varchar(100) NOT NULL,
  `nume` varchar(50) NOT NULL,
  `departament` varchar(100) NOT NULL,
  `superior` int(11) DEFAULT NULL,
  `functie` varchar(100) DEFAULT NULL,
  `salariu_lunar` decimal(10,2) NOT NULL,
  `salariu_ora` decimal(10,2) GENERATED ALWAYS AS (`salariu_lunar` / (20 * 8)) STORED,
  `id_categorie` int(11) DEFAULT NULL,
  `zile_concediu_alocate` int(11) DEFAULT 20,
  `zile_concediu_utilizate` int(11) DEFAULT 0,
  `indice_performanta` decimal(5,2) DEFAULT 0.00,
  `cale_documente` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Triggers `utilizator`
--
DELIMITER $$
CREATE TRIGGER `trg_cale_utilizator` BEFORE INSERT ON `utilizator` FOR EACH ROW BEGIN
    SET NEW.cale_documente = CONCAT(
        'DOCUMENTE_ANGAJATI/',
        NEW.departament, '/',
        NEW.nume, '_', NEW.prenume, '/'
    );
END
$$
DELIMITER ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `categorie`
--
ALTER TABLE `categorie`
  ADD PRIMARY KEY (`id_categorie`);

--
-- Indexes for table `categorie_permisiune`
--
ALTER TABLE `categorie_permisiune`
  ADD PRIMARY KEY (`id_categorie`,`id_permisiune`),
  ADD KEY `id_permisiune` (`id_permisiune`);

--
-- Indexes for table `categorie_sarcina`
--
ALTER TABLE `categorie_sarcina`
  ADD PRIMARY KEY (`id_categorie_sarcina`),
  ADD KEY `fk_categorie_proiect` (`id_proiect`);

--
-- Indexes for table `concediu`
--
ALTER TABLE `concediu`
  ADD PRIMARY KEY (`id_cerere`),
  ADD KEY `nr_matricol` (`nr_matricol`);

--
-- Indexes for table `permisiune`
--
ALTER TABLE `permisiune`
  ADD PRIMARY KEY (`id_permisiune`);

--
-- Indexes for table `proiecte`
--
ALTER TABLE `proiecte`
  ADD PRIMARY KEY (`id_proiect`),
  ADD KEY `manager_responsabil` (`manager_responsabil`);

--
-- Indexes for table `sarbatori_legale`
--
ALTER TABLE `sarbatori_legale`
  ADD PRIMARY KEY (`data_sarbatoare`);

--
-- Indexes for table `sarcina`
--
ALTER TABLE `sarcina`
  ADD PRIMARY KEY (`id_sarcina`),
  ADD KEY `utilizator_responsabil` (`utilizator_responsabil`),
  ADD KEY `fk_sarcina_categorie` (`id_categorie_sarcina`);

--
-- Indexes for table `utilizator`
--
ALTER TABLE `utilizator`
  ADD PRIMARY KEY (`nr_matricol`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `superior` (`superior`),
  ADD KEY `id_categorie` (`id_categorie`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `categorie`
--
ALTER TABLE `categorie`
  MODIFY `id_categorie` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `categorie_sarcina`
--
ALTER TABLE `categorie_sarcina`
  MODIFY `id_categorie_sarcina` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `concediu`
--
ALTER TABLE `concediu`
  MODIFY `id_cerere` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `permisiune`
--
ALTER TABLE `permisiune`
  MODIFY `id_permisiune` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `proiecte`
--
ALTER TABLE `proiecte`
  MODIFY `id_proiect` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sarcina`
--
ALTER TABLE `sarcina`
  MODIFY `id_sarcina` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `categorie_permisiune`
--
ALTER TABLE `categorie_permisiune`
  ADD CONSTRAINT `categorie_permisiune_ibfk_1` FOREIGN KEY (`id_categorie`) REFERENCES `categorie` (`id_categorie`),
  ADD CONSTRAINT `categorie_permisiune_ibfk_2` FOREIGN KEY (`id_permisiune`) REFERENCES `permisiune` (`id_permisiune`);

--
-- Constraints for table `categorie_sarcina`
--
ALTER TABLE `categorie_sarcina`
  ADD CONSTRAINT `fk_categorie_proiect` FOREIGN KEY (`id_proiect`) REFERENCES `proiecte` (`id_proiect`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `concediu`
--
ALTER TABLE `concediu`
  ADD CONSTRAINT `concediu_ibfk_1` FOREIGN KEY (`nr_matricol`) REFERENCES `utilizator` (`nr_matricol`);

--
-- Constraints for table `proiecte`
--
ALTER TABLE `proiecte`
  ADD CONSTRAINT `proiecte_ibfk_1` FOREIGN KEY (`manager_responsabil`) REFERENCES `utilizator` (`nr_matricol`);

--
-- Constraints for table `sarcina`
--
ALTER TABLE `sarcina`
  ADD CONSTRAINT `fk_sarcina_categorie` FOREIGN KEY (`id_categorie_sarcina`) REFERENCES `categorie_sarcina` (`id_categorie_sarcina`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `sarcina_ibfk_1` FOREIGN KEY (`utilizator_responsabil`) REFERENCES `utilizator` (`nr_matricol`);

--
-- Constraints for table `utilizator`
--
ALTER TABLE `utilizator`
  ADD CONSTRAINT `utilizator_ibfk_1` FOREIGN KEY (`superior`) REFERENCES `utilizator` (`nr_matricol`),
  ADD CONSTRAINT `utilizator_ibfk_2` FOREIGN KEY (`id_categorie`) REFERENCES `categorie` (`id_categorie`);

DELIMITER $$
--
-- Events
--
CREATE DEFINER=`root`@`localhost` EVENT `ev_resetare_concedii_anuale` ON SCHEDULE EVERY 1 YEAR STARTS '2026-01-01 00:00:00' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    -- Resetăm zilele de concediu utilizate pentru toți utilizatorii
    UPDATE utilizator
    SET zile_concediu_utilizate = 0;
END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
