//
//  spinConnection.h
//  AudioGraffiti_iPhone
//
//  Created by Mike Wozniewski on 08/02/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "lo/lo.h"

typedef enum { UNKNOWN_DIALOG, SERVER_CHOOSER_DIALOG, USER_CHOOSER_DIALOG } SPINDialogType;


@interface spinConnection : NSObject <UIActionSheetDelegate>
{	
	BOOL connected;
	lo_server_thread infoServer;
	lo_server_thread spinServer;
	lo_server_thread syncServer;
	
	lo_address serverUDP;
	lo_address serverTCP;
	
	
	NSMutableDictionary *servers;
	NSMutableArray *users;
	BOOL serverListUpdated;
	BOOL userListUpdated;
	
	
	NSString *spinID;
	NSString *currentUser;
	
	long int lastSyncValue;
	NSDate *lastSyncTime;
	

	NSTimer *waitForServersTimer;
	UIActionSheet *serverActionSheet;
	NSTimer *waitForUsersTimer;
	UIActionSheet *usersActionSheet;
	
}

@property (readwrite) BOOL connected;
@property (readwrite, assign) lo_server_thread spinServer;
@property (readwrite, assign) lo_server_thread syncServer;
@property (readwrite, assign) lo_address serverUDP;
@property (readwrite, assign) lo_address serverTCP;
@property (nonatomic, retain) NSMutableDictionary *servers;
@property (nonatomic, retain) NSMutableArray *users;
@property (readwrite, copy) NSString *spinID;
@property (readwrite, copy) NSString *currentUser;
@property (readwrite) long int lastSyncValue;
@property (readwrite, copy) NSDate *lastSyncTime;
@property (readwrite) BOOL serverListUpdated;
@property (readwrite) BOOL userListUpdated;


-(NSString*) userPath;


- (void) setInfoServer :(NSString*)addr :(NSString*)port;
- (int) setServer:(NSString*)id;
- (int) setUser:(NSString*)userID;
- (void) disconnect;
- (void) connect;

// callbacks for connecting:
- (void) waitForServers:(NSTimer *)timer;
- (void) waitForUsers:(NSTimer *)timer;

- (long int) getCurrentTime;

- (void) debugPrint;

//- (void) sendMessage :(NSString*)path :(NSString*)types, ... NS_REQUIRES_NIL_TERMINATION;
- (void) sendMessage :(NSString*)path :(NSString*)types, ...;


@end

int user_callback(const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data);
int sync_callback(const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data);
int scene_callback(const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data);
int info_callback(const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data);

