-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 11, 2025 at 08:29 PM
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
  `denumire_categorie` varchar(150) NOT NULL,
  `timp_alocat_total_ore` decimal(10,2) DEFAULT 0.00,
  `data_inceput` date DEFAULT NULL,
  `data_scadenta` date DEFAULT NULL,
  `status_timp` enum('eficient','in timp','intarziat') DEFAULT 'in timp',
  `prioritate` int(11) DEFAULT 0,
  `buget_total` decimal(15,2) DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categorie_sarcina_legaturi`
--

CREATE TABLE `categorie_sarcina_legaturi` (
  `id_categorie_sarcina` int(11) NOT NULL,
  `id_sarcina` int(11) NOT NULL
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
  `nr_zile_calculate` int(11) GENERATED ALWAYS AS (to_days(`data_sfarsit`) - to_days(`data_inceput`) + 1) STORED,
  `status` enum('initiat','in procesare','aprobat','respins') DEFAULT 'initiat',
  `cale_documente` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
  `data_inceput` date DEFAULT NULL,
  `data_finalizare_estimata` date DEFAULT NULL,
  `buget_total` decimal(15,2) DEFAULT 0.00,
  `beneficiar` varchar(100) DEFAULT NULL,
  `cale_documente` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `proiecte_categorie_sarcina`
--

CREATE TABLE `proiecte_categorie_sarcina` (
  `id_proiect` int(11) NOT NULL,
  `id_categorie_sarcina` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sarcina`
--

CREATE TABLE `sarcina` (
  `id_sarcina` int(11) NOT NULL,
  `nume_sarcina` varchar(150) NOT NULL,
  `utilizator_responsabil` int(11) DEFAULT NULL,
  `timp_alocat_ore` decimal(10,2) NOT NULL,
  `data_inceput` date DEFAULT NULL,
  `data_estimata_finalizare` date DEFAULT NULL,
  `timp_utilizat` decimal(10,2) DEFAULT 0.00,
  `buget_alocat` decimal(15,2) DEFAULT NULL,
  `status` enum('in planificare','in lucru','blocat','clarificare','verificare','finalizat') DEFAULT 'in planificare',
  `prioritate` int(11) DEFAULT 0,
  `status_timp` enum('eficient','in timp','intarziat') DEFAULT 'in timp',
  `comentarii` text DEFAULT NULL,
  `cale_documente` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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
  ADD PRIMARY KEY (`id_categorie_sarcina`);

--
-- Indexes for table `categorie_sarcina_legaturi`
--
ALTER TABLE `categorie_sarcina_legaturi`
  ADD PRIMARY KEY (`id_categorie_sarcina`,`id_sarcina`),
  ADD KEY `id_sarcina` (`id_sarcina`);

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
-- Indexes for table `proiecte_categorie_sarcina`
--
ALTER TABLE `proiecte_categorie_sarcina`
  ADD PRIMARY KEY (`id_proiect`,`id_categorie_sarcina`),
  ADD KEY `id_categorie_sarcina` (`id_categorie_sarcina`);

--
-- Indexes for table `sarcina`
--
ALTER TABLE `sarcina`
  ADD PRIMARY KEY (`id_sarcina`),
  ADD KEY `utilizator_responsabil` (`utilizator_responsabil`);

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
-- Constraints for table `categorie_sarcina_legaturi`
--
ALTER TABLE `categorie_sarcina_legaturi`
  ADD CONSTRAINT `categorie_sarcina_legaturi_ibfk_1` FOREIGN KEY (`id_categorie_sarcina`) REFERENCES `categorie_sarcina` (`id_categorie_sarcina`),
  ADD CONSTRAINT `categorie_sarcina_legaturi_ibfk_2` FOREIGN KEY (`id_sarcina`) REFERENCES `sarcina` (`id_sarcina`);

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
-- Constraints for table `proiecte_categorie_sarcina`
--
ALTER TABLE `proiecte_categorie_sarcina`
  ADD CONSTRAINT `proiecte_categorie_sarcina_ibfk_1` FOREIGN KEY (`id_proiect`) REFERENCES `proiecte` (`id_proiect`),
  ADD CONSTRAINT `proiecte_categorie_sarcina_ibfk_2` FOREIGN KEY (`id_categorie_sarcina`) REFERENCES `categorie_sarcina` (`id_categorie_sarcina`);

--
-- Constraints for table `sarcina`
--
ALTER TABLE `sarcina`
  ADD CONSTRAINT `sarcina_ibfk_1` FOREIGN KEY (`utilizator_responsabil`) REFERENCES `utilizator` (`nr_matricol`);

--
-- Constraints for table `utilizator`
--
ALTER TABLE `utilizator`
  ADD CONSTRAINT `utilizator_ibfk_1` FOREIGN KEY (`superior`) REFERENCES `utilizator` (`nr_matricol`),
  ADD CONSTRAINT `utilizator_ibfk_2` FOREIGN KEY (`id_categorie`) REFERENCES `categorie` (`id_categorie`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
