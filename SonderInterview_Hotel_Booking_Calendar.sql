/*
@author = Viswanathan
@Date = 5/31/2021
@Env= mysql
@Description = Interview question - map the Hotel Availability over the calendar
*/

/* Bookings Table */

CREATE TABLE `booking` (
  `id` int NOT NULL,
  `star_dt` date DEFAULT NULL,
  `end_dt` date DEFAULT NULL,
  `room_id` int DEFAULT NULL,
  `status` varchar(45) DEFAULT NULL.
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


/*Rooms Table */

CREATE TABLE `rooms` (
  `id` int NOT NULL,
  `availability_start_dt` varchar(45) DEFAULT NULL,
  `availability_end_dt` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


CREATE TABLE `calendar` (
  `calendar_date` date NOT NULL,
  PRIMARY KEY (`calendar_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


/* Store procedure to populate the Calendar table */

CREATE DEFINER=`root`@`localhost` PROCEDURE `FillCalendar`(start_date DATE, end_date DATE)
BEGIN
	DECLARE crt_date DATE;
	SET crt_date = start_date;
	WHILE crt_date <= end_date DO
		INSERT IGNORE INTO calendar VALUES(crt_date);
		SET crt_date = ADDDATE(crt_date, INTERVAL 1 DAY);
	END WHILE;
END

/* Procedure call */

CALL FillCalendar('2021-01-01', '2021-12-31')


/* Populate Bookings Table */
LOCK TABLES `booking` WRITE;

INSERT INTO `booking` VALUES (1,'2021-01-11','2021-01-13',1,'completed'),(2,'2021-02-01','2021-02-13',2,'completed'),(3,'2021-03-11','2021-03-15',1,'completed'),(4,'2021-04-01','2021-04-12',1,'completed'),(5,'2021-05-11','2021-05-14',3,'completed'),(6,'2021-05-11','2021-05-14',2,'pending');

UNLOCK TABLES;



/* Populate Rooms Table */

LOCK TABLES `rooms` WRITE;

INSERT INTO `rooms` VALUES (1,'2020-12-01','2021-06-01'),(2,'2021-01-01','2021-12-31'),(3,'2020-01-01','2021-12-31'),(4,'2022-01-01','2022-12-31');

UNLOCK TABLES;



/* 
FINAL QUERY TO EXTRACT THE DATA 

BUILD A TABLE VIEW for ROOMS WITH BOOKING DATA*/
WITH OCCUPIED AS
	(
		SELECT
			CAL.CALENDAR_DATE
			, RM.ID AS ROOM_ID
			, BK.STAR_DT
			, BK.END_DT
			, RM.AVAILABILITY_START_DT
			, RM.AVAILABILITY_END_DT
			, CASE
				WHEN CAL.CALENDAR_DATE BETWEEN BK.STAR_DT AND BK.END_DT
					AND CAL.CALENDAR_DATE BETWEEN RM.AVAILABILITY_START_DT AND RM.AVAILABILITY_END_DT
					AND BK.STATUS ='completed'
					THEN 'BOOKED'
					ELSE 'AVAILABLE'
			END AS STATS
		FROM
			CALENDAR CAL
			JOIN
				INTERVIEWS.ROOMS RM
				ON
					CAL.CALENDAR_DATE BETWEEN RM.AVAILABILITY_START_DT AND RM.AVAILABILITY_END_DT
			JOIN
				INTERVIEWS.BOOKING BK
				ON
					CAL.CALENDAR_DATE BETWEEN BK.STAR_DT AND BK.END_DT
					AND RM.ID = BK.ROOM_ID
	)
	/* BUILD A TABLE VIEW WITH ALL CALENDAR DAYS AND ROOM_id */
	,DATEROOM AS
	(
		SELECT
			CALENDAR_DATE
			, ID
		FROM
			CALENDAR
			 JOIN
				ROOMS
				ON
					1=1
	)
/* GENERATE THE FINAL RESULT ON THE CALENDAR WITH ROOM STATUS 
 DIFFERENT ROOM_STATUS - BOOKED, AVAILABLE , NOT AVAILABLE(MEANING THE ROOM IS NO LONGER LISTED ON THE WEBSITE FOR BOOKING)
*/
SELECT DISTINCT
	ROOM.CALENDAR_DATE
	, ROOM.ID AS ROOM_ID
	,CASE
		WHEN OCCUPIED.STATS = 'BOOKED'
			THEN 'ROOM RESERVED'
		WHEN (
				ROOM.CALENDAR_DATE NOT BETWEEN RS.AVAILABILITY_START_DT AND RS.AVAILABILITY_END_DT
			)
			AND ISNULL(OCCUPIED.STATS)
			THEN 'OUTSIDE BOOKING WINDOW'
		WHEN ROOM.CALENDAR_DATE BETWEEN RS.AVAILABILITY_START_DT AND RS.AVAILABILITY_END_DT
			AND (
				ISNULL(OCCUPIED.STATS)
				OR OCCUPIED.STATS = 'AVAILABLE'
			)
			THEN 'AVAILABLE FOR BOOKING'
	END AS ROOM_AVAILABILITY_STATUS
FROM
	DATEROOM ROOM LEFT JOIN OCCUPIED
		ON
			ROOM.ID = OCCUPIED.ROOM_ID AND ROOM.CALENDAR_DATE=OCCUPIED.CALENDAR_DATE
	LEFT JOIN ROOMS RS ON ROOM.ID = RS.ID
ORDER BY 1 ,2  ASC;


