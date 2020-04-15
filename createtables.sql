CREATE DATABASE stats;
USE stats;
CREATE TABLE SRMPlaceholders (
	Name varchar(128), 
	PowerState varchar(128), 
	UsedSpaceGB int(11),      
	CreationDate datetime     
);
CREATE TABLE VMFullList (
	Name varchar(128),
	PowerState varchar(128),
	ProvisionedSpaceGB int(11),    
	UsedSpaceGB int(11),   
	CreationDate datetime    
);
CREATE TABLE VRConfigured (
	Name varchar(128),
	PowerState varchar(128),
	RPOMinutes int(11),     
	Quiesced varchar(128),
	WANCompressed varchar(128),
	WANEncrypted varchar(128),
	ProvisionedSpaceGB int(11),     
	UsedSpaceGB int(11),     
	CreationDate datetime    
);
CREATE TABLE VRNotConfiguredPoweredOff (
	Name varchar(128), 
	PowerState varchar(128), 
	ProvisionedSpaceGB int(11),      
	UsedSpaceGB int(11),     
	CreationDate datetime     
);
CREATE TABLE VRNotConfiguredPoweredOn (
	Name varchar(128), 
	PowerState varchar(128), 
	ProvisionedSpaceGB int(11),      
	UsedSpaceGB int(11),     
	CreationDate datetime     
);
CREATE TABLE VRReplHistory (
	Name varchar(128), 
	Last5SuccessfulReplications varchar(128), 
	SizeofReplicationTransferMB int(11),      
	DaysSinceReplication int(11)      
);
CREATE TABLE VRErrorPaused (
	Name varchar(128),
	PowerState varchar(128),
	ReplicationStatus varchar(128),
	ProvisionedSpaceGB int(11),
	UsedSpaceGB int(11),		
	CreationDate datetime
);

