USE stats;
TRUNCATE TABLE SRMPlaceholders;
TRUNCATE TABLE VMFullList;
TRUNCATE TABLE VRConfigured;
TRUNCATE TABLE VRNotConfiguredPoweredOff;
TRUNCATE TABLE VRNotConfiguredPoweredOn;
TRUNCATE TABLE VRReplHistory;
TRUNCATE TABLE VRErrorPaused;
LOAD DATA LOCAL INFILE '/root/SRM-Placeholders.csv'
INTO TABLE SRMPlaceholders
FIELDS
  TERMINATED BY ','
  ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
IGNORE 1 LINES
(Name, PowerState, UsedSpaceGB, @CreationDate)
set
CreationDate = str_to_date(@CreationDate, '%m/%d/%Y' '%r')
;
LOAD DATA LOCAL INFILE '/root/VM.Full-List.csv'
INTO TABLE VMFullList
FIELDS
  TERMINATED BY ','
  ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
IGNORE 1 LINES
(Name, PowerState, ProvisionedSpaceGB, UsedSpaceGB, @CreationDate)
set
CreationDate = str_to_date(@CreationDate, '%m/%d/%Y' '%r')
;
LOAD DATA LOCAL INFILE '/root/VR-Configured.csv'
INTO TABLE VRConfigured
FIELDS
  TERMINATED BY ','
  ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
IGNORE 1 LINES
(Name, PowerState, RPOMinutes, Quiesced, WANCompressed, WANEncrypted, ProvisionedSpaceGB, UsedSpaceGB, @CreationDate)
set
CreationDate = str_to_date(@CreationDate, '%m/%d/%Y' '%r')
;
LOAD DATA LOCAL INFILE '/root/VR-Not-Configured-PoweredOff.csv'
INTO TABLE VRNotConfiguredPoweredOff
FIELDS
  TERMINATED BY ','
  ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
IGNORE 1 LINES
(Name, PowerState, ProvisionedSpaceGB, UsedSpaceGB, @CreationDate)
set
CreationDate = str_to_date(@CreationDate, '%m/%d/%Y' '%r')
;
LOAD DATA LOCAL INFILE '/root/VR-Not-Configured-PoweredOn.csv'
INTO TABLE VRNotConfiguredPoweredOn
FIELDS
  TERMINATED BY ','
  ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
IGNORE 1 LINES
(Name, PowerState, ProvisionedSpaceGB, UsedSpaceGB, @CreationDate)
set
CreationDate = str_to_date(@CreationDate, '%m/%d/%Y' '%r')
;
LOAD DATA LOCAL INFILE '/root/VR-Repl-History.csv'
INTO TABLE VRReplHistory
FIELDS
  TERMINATED BY ','
  ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
IGNORE 1 LINES
(Name, Last5SuccessfulReplications, SizeofReplicationTransferMB, DaysSinceReplication)
;
LOAD DATA LOCAL INFILE '/root/VR-Error-Paused.csv'
INTO TABLE VRErrorPaused
FIELDS
  TERMINATED BY ','
  ENCLOSED BY '"'
  LINES TERMINATED BY '\n'
IGNORE 1 LINES
(Name, PowerState, ReplicationStatus, ProvisionedSpaceGB, UsedSpaceGB, @CreationDate)
set
CreationDate = str_to_date(@CreationDate, '%m/%d/%Y' '%r')
;
