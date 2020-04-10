create table atp_players
(
    id        INT PRIMARY KEY,
    firstName varchar(100),
    lastName  varchar(100),
    hand      varchar(10),
    birth     date,
    country   varchar(10)
);