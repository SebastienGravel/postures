//
//  spinConnection.m
//  AudioGraffiti_iPhone
//
//  Created by Mike Wozniewski on 08/02/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "spinConnection.h"
#import "AudioGraffitiAppDelegate.h"
#import "TagViewController.h"

@implementation spinConnection

@synthesize connected, spinServer, syncServer, serverUDP, serverTCP, spinID, servers, users, serverListUpdated, userListUpdated, currentUser, lastSyncValue, lastSyncTime;

-(id)init
{
	self = [super init];
	if (self)
	{
		servers = [[NSMutableDictionary alloc] init];
		users = [[NSMutableArray alloc] init];
		
		serverListUpdated = NO;
		userListUpdated = NO;
		
		connected = FALSE;
		
		spinServer = 0;
		infoServer = 0;
		serverUDP = 0;
		serverTCP = 0;
		
		spinID = @"default";
	}
	return self;
}

- (void)dealloc {
	
    [super dealloc];
}

-(NSString*) userPath
{
	return [NSString stringWithFormat:@"/SPIN/%@/%@", spinID, currentUser];
}

-(void) setInfoServer :(NSString*)addr :(NSString*)port
{
	infoServer = lo_server_thread_new_multicast( [addr UTF8String], [port UTF8String], NULL );
	
	if (infoServer)
	{
		lo_server_thread_add_method(infoServer, "/SPIN/__server__", "ssiisii", info_callback, self);
		lo_server_thread_start(infoServer);
		NSLog(@"spinConnection listening to info messages on %s", (char*)lo_server_thread_get_url(infoServer));
	} else {
		NSLog(@"Error: spinConnection could not create info server");
	}
	
}


- (int) setServer:(NSString*)id
{
	// verify that it is in the dictionary:
	NSMutableArray *serv = [servers objectForKey:id];
	if (!serv)
	{
		NSLog(@"ERROR: selectServer could not find %@ in the server list", id);
		return 0;
	}
	
	// TODO !!!!! clear previous servers, addresses, callbacks
	
	
	self.spinID = [id copy];
	
	
	// serv has contents:  (rxaddr)   (udp) (tcp) (txaddr) (port) (sync)
	//                        0         1     2      3       4      5
	
	// create addresses where we can send UDP and TCP to the server:	
	serverUDP = lo_address_new([[serv objectAtIndex:0] UTF8String], [[serv objectAtIndex:0] UTF8String]);
	serverTCP = lo_address_new_with_proto(LO_TCP, [[serv objectAtIndex:0] UTF8String], [[serv objectAtIndex:2] UTF8String]);
	
	NSLog(@"sending to SPIN on (UDP): %s\n", lo_address_get_url(serverUDP));
	NSLog(@"sending to SPIN on (TCP): %s\n", lo_address_get_url(serverTCP));
	
	// 
	NSString *scenePath = [NSString stringWithFormat:@"/SPIN/%@", spinID];
	
	
	// now create a server thread to listen to multicast traffic from SPIN, and
	// add the scene_callback so we can listen to high-level scene messages:
	self.spinServer = lo_server_thread_new_multicast([[serv objectAtIndex:3] UTF8String], [[serv objectAtIndex:4] UTF8String], NULL);
	lo_server_thread_add_method(spinServer, [scenePath UTF8String], NULL, scene_callback, self);
	lo_server_thread_start(spinServer);
	
	NSLog(@"listening to SPIN on: %s\n", lo_server_thread_get_url(self.spinServer));
	
	// create another server thread to listen to timecode (sync) messages
	syncServer = lo_server_thread_new_multicast([[serv objectAtIndex:3] UTF8String], [[serv objectAtIndex:5] UTF8String], NULL);
	lo_server_thread_add_method(syncServer, [scenePath UTF8String], NULL, sync_callback, self);
	lo_server_thread_start(syncServer);
	
	NSLog(@"listening to sync on: %s\n", lo_server_thread_get_url(syncServer));

	
	// now ask the server to send the current nodelist:
	lo_send(serverTCP, [scenePath UTF8String], "ss", "getNodeList", "*");	
	
	// and now wait for userNode messages to come in:
	waitForUsersTimer = [NSTimer scheduledTimerWithTimeInterval: 0.5
														 target: self
													   selector: @selector(waitForUsers:)
													   userInfo: nil
														repeats: YES];
	
	
	return 1;
}


-(int) setUser:(NSString*)userID
{
	// if a currentUser was already registered, we have to remove his callback:
	if (currentUser) lo_server_thread_del_method(self.spinServer, [[self userPath] UTF8String], NULL);
	
	// set the userID
	currentUser = [userID copy];
	
	// add the user_callback:
	lo_server_thread_add_method(self.spinServer, [[self userPath] UTF8String], NULL, user_callback, self);
	NSLog(@"callback registered for %@", [self userPath]);
	
	
	// set label:
	AudioGraffitiAppDelegate *appDelegate = (AudioGraffitiAppDelegate *)[[UIApplication sharedApplication] delegate];
    TagViewController *tagView = [[appDelegate.tabBarController viewControllers] objectAtIndex:0];
    if (tagView != nil)
    {
        tagView.statusLabel.text = [NSString stringWithFormat:@"Connected to server: %@. User: %@", spinID, currentUser];
    }
	
	
	connected = YES;
	
	return 1;
}


-(void) disconnect
{
	connected = FALSE;
	
	currentUser = nil;
	
	//lo_server_thread_stop(infoServer);
	lo_server_thread_free(infoServer);
	
	//lo_server_thread_stop(spinServer);
	lo_server_thread_free(spinServer);
	
	lo_address_free(serverUDP);
	lo_address_free(serverTCP);
}



- (void) connect
{
	[self setInfoServer :@"239.0.0.1" :@"54320"];
	
	
	waitForServersTimer = [NSTimer scheduledTimerWithTimeInterval: 0.5
														   target: self
														 selector: @selector(waitForServers:)
														 userInfo: nil
														  repeats: YES];
}

- (void) waitForServers:(NSTimer *)timer
{
	//NSLog(@"spinConnection::waitForServers");

	if (serverListUpdated)
	{
		
		//NSLog(@"got serverlist: %@", servers);
		
		if (serverActionSheet) [serverActionSheet dismissWithClickedButtonIndex:-1 animated:NO];

		serverActionSheet = [[UIActionSheet alloc]
							 initWithTitle:@"Select SPIN server"
							 delegate:self
							 cancelButtonTitle:nil
							 destructiveButtonTitle:nil
							 otherButtonTitles:nil];
		serverActionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
		//serverActionSheet.cancelButtonIndex = i;
		serverActionSheet.tag = SERVER_CHOOSER_DIALOG;
		
		NSArray *serverIDs = [servers allKeys];
		for (int i=0; i < [serverIDs count]; i++)
		{
			[serverActionSheet addButtonWithTitle:[serverIDs objectAtIndex:i]];
		}
		
		AudioGraffitiAppDelegate *appDelegate = (AudioGraffitiAppDelegate *)[[UIApplication sharedApplication] delegate];
		[serverActionSheet showInView:appDelegate.window];
		[serverActionSheet release];
		
		serverListUpdated = NO;
	}
	
}

-(void) waitForUsers:(NSTimer *)timer
{
	if (userListUpdated)
	{
		NSLog(@"Updating users actionsheet: %@", users);
		
		if (usersActionSheet) [usersActionSheet dismissWithClickedButtonIndex:-1 animated:NO];
		
		usersActionSheet = [[UIActionSheet alloc]
							initWithTitle:@"Select user"
							delegate:self
							cancelButtonTitle:nil
							destructiveButtonTitle:nil
							otherButtonTitles:nil];
		
		usersActionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
		//usersActionSheet.cancelButtonIndex = i;
		usersActionSheet.tag = USER_CHOOSER_DIALOG;
		
		for (int i=0; i < [users count]; i++)
		{
			[usersActionSheet addButtonWithTitle:[users objectAtIndex:i]];
		}
		
		AudioGraffitiAppDelegate *appDelegate = (AudioGraffitiAppDelegate *)[[UIApplication sharedApplication] delegate];
		[usersActionSheet showInView:appDelegate.window];
		[usersActionSheet release];
		
		userListUpdated = NO;
	}
	
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (actionSheet.tag == SERVER_CHOOSER_DIALOG)
	{
		NSLog(@"chose server: %@", [actionSheet buttonTitleAtIndex:buttonIndex]);
		
		if ([self setServer:[actionSheet buttonTitleAtIndex:buttonIndex]])
		{
			[waitForServersTimer invalidate];
		}
		
		return;
	}
	
	else if (actionSheet.tag == USER_CHOOSER_DIALOG)
	{
		NSLog(@"chose user: %@", [actionSheet buttonTitleAtIndex:buttonIndex]);
		
		if ([self setUser:[actionSheet buttonTitleAtIndex:buttonIndex]])
		{
			[waitForUsersTimer invalidate];
		}
		
		return;
	}

}


- (long int) getCurrentTime
{
	// TODO
	return 0;
}


-(void) debugPrint
{
	//printf("debugPrint\n");
}

-(void) sendMessage :(NSString*)path :(NSString*)types, ...
{
	// THIS DOESN'T WORK YET ... var args is a problem
	
	va_list args;
	va_start(args, types);
	
	lo_message msg = lo_message_new();
	int err = lo_message_add_varargs(msg, [types UTF8String], args);
	
	if (!err && serverTCP)
	{
		lo_send_message(serverTCP, [path UTF8String], msg);
	} else {
		printf("ERROR in sendMessage formatting\n");
	}
	
	// Let's free the message after (not sure if this is necessary):
    lo_message_free(msg);
}


@end



int user_callback(const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data)
{
	/*
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	spinConnection *spin = (spinConnection*)user_data;

	printf("user callback: <%s> with %d args\n", path, argc);
	for (int i=0; i<argc; i++) {
		printf("arg %d '%c' ", i, types[i]);
		lo_arg_pp(types[i], argv[i]);
		printf("\n");
	}
	printf("\n");

	
	NSString *theMethod;
	if (lo_is_string_type((lo_type)types[0]))
	{
		theMethod = [NSString stringWithUTF8String: (char *)argv[0] ];
	}
	 
	[pool release];
	*/
	return 1;
}

int sync_callback(const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	spinConnection *spin = (spinConnection*)user_data;
	
	
	if (argc != 2) return 1;
	
	NSString *theMethod;
	if (lo_is_string_type((lo_type)types[0]))
	{
		theMethod = [NSString stringWithUTF8String: (char *)argv[0] ];
	}
	
	
	if ([theMethod compare:@"sync"] == NSOrderedSame)
	{
		long int sync = (long int) lo_hires_val((lo_type)types[1], argv[1]);
		NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
		
		NSTimeInterval dt = [now timeIntervalSinceDate:spin.lastSyncTime];
		
		NSLog(@"lastSync=%d, newSync=%d, syncdiff=%d, timediff=%.1f", spin.lastSyncValue, sync, (sync-spin.lastSyncValue), dt*1000);
		
		spin.lastSyncValue = sync;
		spin.lastSyncTime = now;
	}
	 
	
	[pool release];
	return 1;
}

int scene_callback(const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data)
{
	spinConnection *spin = (spinConnection*)user_data;
	
	/*
	printf("scene callback: <%s>\n", path);
	for (int i=0; i<argc; i++) {
		printf("arg %d '%c' ", i, types[i]);
		lo_arg_pp(types[i], argv[i]);
		printf("\n");
	}
	printf("\n");
	*/
	
	// make sure there is at least one argument (ie, a method to call):
	if (!argc) return 1;
	
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	
	// get the method (argv[0]):
	NSString *theMethod;
	if (lo_is_string_type((lo_type)types[0]))
	{
		theMethod = [NSString stringWithUTF8String: (char *)argv[0] ];
	}
	else {
		[pool release];
		return 1;
	}
	
	// note that args start at argv[1] now:
	
	if ([theMethod compare:@"nodeList"] == NSOrderedSame) 
	{
		NSString *nodeType = [NSString stringWithUTF8String: (char *)argv[1] ];
		if ([nodeType compare:@"UserNode"] == NSOrderedSame) 
		{
			
			// add all ids not equal to "NULL"
			for (int i=2; i<argc; i++)
			{
				NSString *nodeId = [NSString stringWithUTF8String: (char *)argv[i] ];
				if (![nodeId isEqualToString:@"NULL"])
				//if ([nodeId hasPrefix:@"u"]) // for agraffiti, all users start with 'u' (eg, u01)
				{
					if (![spin.users containsObject:nodeId])
					{
						[spin.users addObject:nodeId];
						spin.userListUpdated = YES;
					}
						
				}
			}
			
			//NSLog(@"current users: %@", spin.users);

			
			// sort
			 /*
			NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"self" ascending:YES];
			[spin.userList sortUsingDescriptors:[NSArray arrayWithObject:sorter]];
			*/
		}
	}
	
	else if ([theMethod compare:@"refresh"] == NSOrderedSame) 
	{
		printf("got 'refresh' message from SPIN");
	}
	else if ([theMethod compare:@"clear"] == NSOrderedSame) 
	{
		printf("got 'clear' message from SPIN");
	}
	
	[pool release];
	return 1;
}

int info_callback(const char *path, const char *types, lo_arg **argv, int argc, void *data, void *user_data)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	unsigned int i;
	
	spinConnection *spin = (spinConnection*)user_data;
	
	/*
	 printf("info callback: <%s> with %d args\n", path, argc);
	 for (int i=0; i<argc; i++) {
	 printf("arg %d '%c' ", i, types[i]);
	 lo_arg_pp(types[i], argv[i]);
	 printf("\n");
	 }
	 printf("\n");
	 */
	
	
	// our message should look something like this:
	//
	//   /SPIN/__server__ default 192.168.1.100 54324 54322 224.0.0.1 54323 54321
	//                    (sceneid)  (rxaddr)   (udp) (tcp) (txaddr) (port) (sync)
	//                        0         1         2     3      4       5      6
	
	
	if (argc==7)
	{
		// the sceneID is the first argument:
		NSString *sceneID = [NSString stringWithUTF8String: (char*) argv[0]];
		
		// If the server already exists in our list, we'll replace it with new
		// info (just in case it happened to change ports or something):
		NSMutableArray *servProperties = [spin.servers objectForKey:sceneID];
		if (!servProperties) {
			[servProperties release];
			spin.serverListUpdated = YES;
		}
		
		// since liblo takes strings for all it's arguments (even port numbers),
		// we store all server params as a simple NSString array:
		servProperties = [[NSMutableArray alloc] init];
		for (i=1; i<argc; i++) {
			if (lo_is_numerical_type((lo_type)types[i]))
			{
				[servProperties addObject:[NSString stringWithFormat:@"%d",(int)lo_hires_val('i', argv[i])]];
			}
			else {
				[servProperties addObject:[NSString stringWithUTF8String:(char*)argv[i]]];
			}
		}

		[spin.servers setObject:servProperties forKey:sceneID];
		
		//NSLog(@"infoport just got %@. dict is now: %@", sceneID, spin.servers);
	}

		
	[pool release];
	return 1;
}
