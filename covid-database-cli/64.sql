CREATE DATABASE  IF NOT EXISTS `Covid` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `Covid`;
-- MySQL dump 10.13  Distrib 8.0.27, for Linux (x86_64)
--
-- Host: 127.0.0.1    Database: Covid
-- ------------------------------------------------------
-- Server version	8.0.27

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Dependents`
--

DROP TABLE IF EXISTS `Dependents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Dependents` (
  `Name` varchar(100) NOT NULL,
  `VID` int NOT NULL,
  PRIMARY KEY (`Name`,`VID`),
  KEY `fk_Dependents_1_idx` (`VID`),
  CONSTRAINT `fk_Dependents_1` FOREIGN KEY (`VID`) REFERENCES `Volunteer` (`Volunteer_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Dependents`
--

LOCK TABLES `Dependents` WRITE;
/*!40000 ALTER TABLE `Dependents` DISABLE KEYS */;
INSERT INTO `Dependents` VALUES ('Mohan',1),('Ram',1),('Shohan',2),('Geetha',3);
/*!40000 ALTER TABLE `Dependents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Gets_vaccinated_by`
--

DROP TABLE IF EXISTS `Gets_vaccinated_by`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Gets_vaccinated_by` (
  `Paadhar_no` int NOT NULL,
  `Num_vacc` int NOT NULL,
  `VID` int DEFAULT NULL,
  `Vacc_name` varchar(50) DEFAULT NULL,
  `Vacc_centre_ID` int DEFAULT NULL,
  PRIMARY KEY (`Paadhar_no`,`Num_vacc`),
  KEY `fk_Gets_vaccinated_by_2_idx` (`VID`),
  KEY `fk_Gets_vaccinated_by_3_idx` (`Vacc_name`),
  KEY `fk_Gets_vaccinated_by_4_idx` (`Vacc_centre_ID`),
  CONSTRAINT `fk_Gets_vaccinated_by_1` FOREIGN KEY (`Paadhar_no`) REFERENCES `Person` (`Aadhar_no`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_Gets_vaccinated_by_2` FOREIGN KEY (`VID`) REFERENCES `Volunteer` (`Volunteer_ID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_Gets_vaccinated_by_3` FOREIGN KEY (`Vacc_name`) REFERENCES `Vaccine` (`Vaccine_name`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_Gets_vaccinated_by_4` FOREIGN KEY (`Vacc_centre_ID`) REFERENCES `Vaccination_centre` (`Vaccination_centre_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Gets_vaccinated_by`
--

LOCK TABLES `Gets_vaccinated_by` WRITE;
/*!40000 ALTER TABLE `Gets_vaccinated_by` DISABLE KEYS */;
INSERT INTO `Gets_vaccinated_by` VALUES (1,1,2,'Covi-1',2),(1,2,3,'Covi-1',1),(2,1,1,'Covi-2',2),(3,0,NULL,NULL,NULL),(4,1,1,'Covi-2',3);
/*!40000 ALTER TABLE `Gets_vaccinated_by` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Person`
--

DROP TABLE IF EXISTS `Person`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Person` (
  `Aadhar_no` int NOT NULL,
  `Sname` varchar(50) DEFAULT NULL,
  `Name` varchar(100) NOT NULL,
  `Date_of_birth` date NOT NULL,
  `Gender` varchar(2) NOT NULL,
  `HNo` int NOT NULL,
  `City` varchar(50) NOT NULL,
  `State` varchar(50) NOT NULL,
  `Area` varchar(50) NOT NULL,
  `Pin_code` int NOT NULL,
  PRIMARY KEY (`Aadhar_no`),
  KEY `fk__1_idx` (`Sname`),
  CONSTRAINT `fk__1` FOREIGN KEY (`Sname`) REFERENCES `State` (`State_name`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Person`
--

LOCK TABLES `Person` WRITE;
/*!40000 ALTER TABLE `Person` DISABLE KEYS */;
INSERT INTO `Person` VALUES (1,'AP','Vinay','2010-10-10','M',22,'Vijayawada','AP','AK nagar',510000),(2,'RJ','Saurav','2002-06-12','M',56,'Jaipur','RJ','Gandhinagar',502060),(3,'AP','Rahul','2002-05-18','M',78,'Guntur','AP','RJ colony',536812),(4,'TN','Devi','2004-07-22','F',27,'Chennai','TN','T Nagar',520084);
/*!40000 ALTER TABLE `Person` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Person_contact`
--

DROP TABLE IF EXISTS `Person_contact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Person_contact` (
  `Phone_no` varchar(15) NOT NULL,
  `Paadhar_no` int NOT NULL,
  PRIMARY KEY (`Phone_no`,`Paadhar_no`),
  KEY `fk_Person_contact_1_idx` (`Paadhar_no`),
  CONSTRAINT `fk_Person_contact_1` FOREIGN KEY (`Paadhar_no`) REFERENCES `Person` (`Aadhar_no`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Person_contact`
--

LOCK TABLES `Person_contact` WRITE;
/*!40000 ALTER TABLE `Person_contact` DISABLE KEYS */;
INSERT INTO `Person_contact` VALUES ('8585858585',1),('8989898989',1),('7676767676',2),('8458458451',3),('7657658452',4);
/*!40000 ALTER TABLE `Person_contact` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `State`
--

DROP TABLE IF EXISTS `State`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `State` (
  `State_name` varchar(50) NOT NULL,
  `Population` int NOT NULL,
  PRIMARY KEY (`State_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `State`
--

LOCK TABLES `State` WRITE;
/*!40000 ALTER TABLE `State` DISABLE KEYS */;
INSERT INTO `State` VALUES ('AP',40),('KA',20),('KS',25),('RJ',32),('TN',35),('TS',30);
/*!40000 ALTER TABLE `State` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Vaccination_centre`
--

DROP TABLE IF EXISTS `Vaccination_centre`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Vaccination_centre` (
  `Vaccination_centre_ID` int NOT NULL,
  `Vaccination_centre_name` varchar(100) NOT NULL,
  `Vaccination_centre_state` varchar(50) NOT NULL,
  `Vaccination_centre_city` varchar(50) NOT NULL,
  `Vaccination_centre_area` varchar(50) NOT NULL,
  `Vaccination_centre_HNo` int NOT NULL,
  `Vaccination_centre_pin_code` int NOT NULL,
  PRIMARY KEY (`Vaccination_centre_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Vaccination_centre`
--

LOCK TABLES `Vaccination_centre` WRITE;
/*!40000 ALTER TABLE `Vaccination_centre` DISABLE KEYS */;
INSERT INTO `Vaccination_centre` VALUES (1,'Subhodaya vacc centre','AP','Vijayawada','Gandhinagar',68,502063),(2,'Medtok vacc centre','RJ','Jaipur','Jagatpura',52,562341),(3,'Vasi vacc centre','TN','Chennai','T Nagar',26,501236);
/*!40000 ALTER TABLE `Vaccination_centre` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Vaccination_centre_contact`
--

DROP TABLE IF EXISTS `Vaccination_centre_contact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Vaccination_centre_contact` (
  `Contact_no` varchar(15) NOT NULL,
  `Vaccination_centre_ID` int NOT NULL,
  PRIMARY KEY (`Contact_no`,`Vaccination_centre_ID`),
  KEY `fk_Vaccination_centre_contact_1_idx` (`Vaccination_centre_ID`),
  CONSTRAINT `fk_Vaccination_centre_contact_1` FOREIGN KEY (`Vaccination_centre_ID`) REFERENCES `Vaccination_centre` (`Vaccination_centre_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Vaccination_centre_contact`
--

LOCK TABLES `Vaccination_centre_contact` WRITE;
/*!40000 ALTER TABLE `Vaccination_centre_contact` DISABLE KEYS */;
INSERT INTO `Vaccination_centre_contact` VALUES ('9999999999',1),('9797979797',2),('9898989898',2),('9494949494',3);
/*!40000 ALTER TABLE `Vaccination_centre_contact` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Vaccination_status`
--

DROP TABLE IF EXISTS `Vaccination_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Vaccination_status` (
  `Paadhar_no` int NOT NULL,
  `Status` varchar(15) NOT NULL,
  `Date_of_first_vaccination` date DEFAULT NULL,
  `Date_of_second_vaccination` date DEFAULT NULL,
  PRIMARY KEY (`Paadhar_no`),
  CONSTRAINT `fk_Vaccination_status_1` FOREIGN KEY (`Paadhar_no`) REFERENCES `Person` (`Aadhar_no`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Vaccination_status`
--

LOCK TABLES `Vaccination_status` WRITE;
/*!40000 ALTER TABLE `Vaccination_status` DISABLE KEYS */;
INSERT INTO `Vaccination_status` VALUES (1,'Full','2021-09-26','2021-10-26'),(2,'Partial','2021-10-20',NULL),(3,'None',NULL,NULL),(4,'Partial','2021-08-29',NULL);
/*!40000 ALTER TABLE `Vaccination_status` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Vaccine`
--

DROP TABLE IF EXISTS `Vaccine`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Vaccine` (
  `Vaccine_name` varchar(50) NOT NULL,
  `Manufacturing_company` varchar(50) NOT NULL,
  `Efficacy` int DEFAULT NULL,
  PRIMARY KEY (`Vaccine_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Vaccine`
--

LOCK TABLES `Vaccine` WRITE;
/*!40000 ALTER TABLE `Vaccine` DISABLE KEYS */;
INSERT INTO `Vaccine` VALUES ('Covi-1','Marin',86),('Covi-2','Goldblum',89);
/*!40000 ALTER TABLE `Vaccine` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Volunteer`
--

DROP TABLE IF EXISTS `Volunteer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Volunteer` (
  `Volunteer_ID` int NOT NULL,
  `Sname` varchar(50) DEFAULT NULL,
  `Volunteer_name` varchar(100) NOT NULL,
  `Volunteer_date_of_birth` date NOT NULL,
  `Volunteer_gender` varchar(2) NOT NULL,
  `Volunteer_HNo` int NOT NULL,
  `Volunteer_city` varchar(50) NOT NULL,
  `Volunteer_state` varchar(50) NOT NULL,
  `Volunteer_area` varchar(50) NOT NULL,
  `Volunteer_pin_code` int NOT NULL,
  `Volunteer_aadhar_no` int NOT NULL,
  `Spread_flag` int NOT NULL,
  `Vaccinate_flag` int NOT NULL,
  PRIMARY KEY (`Volunteer_ID`),
  UNIQUE KEY `Volunteer_aadhar_no_UNIQUE` (`Volunteer_aadhar_no`),
  KEY `fk_Volunteer_1_idx` (`Sname`),
  CONSTRAINT `fk_Volunteer_1` FOREIGN KEY (`Sname`) REFERENCES `State` (`State_name`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Volunteer`
--

LOCK TABLES `Volunteer` WRITE;
/*!40000 ALTER TABLE `Volunteer` DISABLE KEYS */;
INSERT INTO `Volunteer` VALUES (1,'AP','Akhila','2000-05-16','F',26,'Rajamundry','AP','Seethampeta',526812,5,0,1),(2,'TN','Akhil','2000-04-18','M',58,'Chennai','TN','Gandhinagar',546481,6,0,1),(3,'RJ','Nikhil','1999-05-16','M',27,'Jaipur','RJ','Malviya Nagar',521846,7,0,1),(4,'RJ','Sahruda','1998-06-12','F',98,'Ajmer','RJ','Kotra',549612,8,1,0);
/*!40000 ALTER TABLE `Volunteer` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2021-10-26 15:26:27