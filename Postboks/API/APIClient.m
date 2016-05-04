//
//  Created by Ole Gammelgaard Poulsen on 15/08/14.
//  Copyright (c) 2014 SHAPE A/S. All rights reserved.
//

#import "APIClient.h"
#import "EboksAccount.h"
#import "NSString+EboksAdditions.h"
#import <AFOnoResponseSerializer/AFOnoResponseSerializer.h>
#import <ReactiveCocoa/ReactiveCocoa/RACSignal.h>
#import "ONOXMLDocument.h"
#import "EboksSession.h"
#import "RegExCategories.h"
#import "NSArray+F.h"
#import "MessageInfo.h"
#import "EboksFolderInfo.h"
#import "SharedAccount.h"
#import <AFNetworking/AFNetworking.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <CocoaSecurity/CocoaSecurity.h>
#import <Functional.m/F.h>

@interface APIClient ()

@property (nonatomic, copy) NSURL *baseURL;

@end

@implementation APIClient {

}

- (instancetype)initWithBaseURL:(NSURL *)baseURL {
  self = [super init];
  if (!self) return nil;
  
  _baseURL = [baseURL copy];
  
  return self;
}

+ (APIClient *)sharedInstanceForAccount:(EboksAccount *)account {
  static NSMutableDictionary *sharedClients = nil;
  
  static dispatch_once_t pred;
  dispatch_once(&pred, ^{
    sharedClients = [NSMutableDictionary new];
  });
  
  APIClient *client = sharedClients[account.nationality];
  if (!client) {
    NSURL *baseURL = [self baseURLForNationality:account.nationality];
    client = [[APIClient alloc] initWithBaseURL:baseURL];

    sharedClients[account.nationality] = client;
  }

  return client;
}

+ (NSURL *)baseURLForNationality:(NSString *)nationality {
  if ([nationality isEqualToString:EboksNationalitySweden]) {
    return [NSURL URLWithString:@"https://rest.e-boks.dk/mobile/1/xml.svc/sv-se"];
  }

  return [NSURL URLWithString:@"https://rest.e-boks.dk/mobile/1/xml.svc/en-gb"];
}

+ (NSData *)authBodyForAccount:(EboksAccount *)account {
  NSString *bodyString = [NSString stringWithFormat:
    @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
    "<Logon xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"urn:eboks:mobile:1.0.0\">"
    "<App version=\"1.4.1\" os=\"iOS\" osVersion=\"9.0.0\" Device=\"iPhone\" />"
    "<User identity=\"%@\" identityType=\"P\" nationality=\"%@\" pincode=\"%@\"/>"
    "</Logon>", account.userId, account.nationality, account.password];
  
  return [bodyString dataUsingEncoding:NSUTF8StringEncoding];
}

- (RACSignal *)getSessionForAccount:(EboksAccount *)account {
	EboksSession *session = [EboksSession new];
	session.deviceId = [NSString nextUUID];
	session.account = account;

	NSString *dateString = [APIClient currentDateString];
	NSString *input = [NSString stringWithFormat:@"%@:%@:P:%@:%@:%@:%@", account.activationCode, session.deviceId, account.userId, account.nationality, account.password, dateString];
	NSString *challenge = [APIClient doubleHash:input];
  NSURL *url = [self.baseURL URLByAppendingPathComponent:@"session"];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	NSString *authHeader = [NSString stringWithFormat:@"logon deviceid=\"%@\",datetime=\"%@\",challenge=\"%@\"", session.deviceId, dateString, challenge];

	[request setValue:authHeader forHTTPHeaderField:@"X-EBOKS-AUTHENTICATE"];
	[request setHTTPBody:[[self class] authBodyForAccount:account]];
	[request setHTTPMethod:@"PUT"];
	[request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
	[request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
	[request setValue:@"eboks/35 CFNetwork/672.1.15 Darwin/14.0.0" forHTTPHeaderField:@"User-Agent"];

	AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	
#ifdef DEBUG
	AFSecurityPolicy *sec = [[AFSecurityPolicy alloc] init];
	[sec setAllowInvalidCertificates:YES];
	requestOperation.securityPolicy = sec;
#endif
	
	requestOperation.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
	RACSignal *requestSignal = [self signalForRequestOperation:requestOperation];

	RACSignal *sessionSignal = [requestSignal map:^id(ONOXMLDocument *responseDocument) {
		ONOXMLElement *userElement = responseDocument.rootElement.children.firstObject;
		session.name = [userElement valueForAttribute:@"name" inNamespace:nil];
		account.ownerName = session.name; // a little dirty
		session.internalUserId = [userElement valueForAttribute:@"userId" inNamespace:nil];
		NSDictionary *headers = [requestOperation.response allHeaderFields];
		NSString *authenticateResponse = headers[@"X-EBOKS-AUTHENTICATE"];
		session.sessionId = [[authenticateResponse firstMatchWithDetails:RX(@"sessionid=\\\"(([a-f0-9]|-)+)\\\"")].groups[1] value];
		session.nonce = [[authenticateResponse firstMatchWithDetails:RX(@"nonce=\\\"(([a-f0-9])+)\\\"")].groups[1] value];
		return session;
	}];

	return sessionSignal;
}

- (RACSignal *)getFoldersWithSessionId:(EboksSession *)session shareId:(NSString *)shareId {
	if (!shareId) shareId = @"0"; // means the logged in user
	NSString *urlString = [NSString stringWithFormat:@"%@/%@/%@/mail/folders", self.baseURL.absoluteString, session.internalUserId, shareId];

	RACSignal *requestSignal = [self requestSignalForSession:session urlString:urlString xmlResponse:YES];
	RACSignal *foldersSignal = [requestSignal map:^id(ONOXMLDocument *responseDocument) {
		NSArray *folderElements = [responseDocument.rootElement children];
		NSArray *folders = [folderElements map:^id(ONOXMLElement *element) {
			return [EboksFolderInfo folderFromXMLElement:element];
		}];
		return folders;
	}];
	return foldersSignal;
}

- (RACSignal *)getSharesWithSessionId:(EboksSession *)session {
	NSString *urlString = [NSString stringWithFormat:@"%@/%@/0/shares?listType=active", self.baseURL.absoluteString, session.internalUserId];
	RACSignal *requestSignal = [self requestSignalForSession:session urlString:urlString xmlResponse:YES];
	RACSignal *sharesSignal = [requestSignal map:^id(ONOXMLDocument *responseDocument) {
		NSArray *shareElements = [responseDocument.rootElement children];
		NSArray *shares = [shareElements map:^id(ONOXMLElement *element) {
			return [SharedAccount shareFromXMLElement:element];
		}];
		SharedAccount *ownShare = [SharedAccount new];
		ownShare.userId = @"0";
		ownShare.name = session.name;
		return [shares arrayByAddingObject:ownShare];
	}];
	return sharesSignal;
}

- (RACSignal *)getFolderId:(NSString *)folderId share:(SharedAccount *)share session:(EboksSession *)session skip:(NSInteger)skip take:(NSInteger)take {
	NSParameterAssert(share);
	NSString *urlFormat = @"%@/%@/%@/mail/folder/%@?skip=%ld&take=%ld&latest=false";
	NSString *urlString = [NSString stringWithFormat:urlFormat, self.baseURL.absoluteString, session.internalUserId, share.userId, folderId, skip, take];
	RACSignal *requestSignal = [self requestSignalForSession:session urlString:urlString xmlResponse:YES];
	RACSignal *folderSignal = [requestSignal flattenMap:^RACStream *(ONOXMLDocument *responseDocument) {
		NSArray *messageElements = [responseDocument.rootElement.children.firstObject children];
		NSMutableArray *mutableMessages = [NSMutableArray array];
		NSArray *getMessageSignals = [messageElements map:^id(ONOXMLElement *element) {
			MessageInfo *messageInfo = [MessageInfo messageFromXMLElement:element name:share.name];
			// if there are attachments we need to make another request to get their ids
			if (messageInfo.numAttachments == 0){
				[mutableMessages addObject:messageInfo];
				return [[RACSignal return:nil] ignoreValues];
			}
			return [[[self getMessageId:messageInfo.messageId folderId:folderId share:share session:session] doNext:^(MessageInfo *fullMessage) {
				[mutableMessages addObject:fullMessage];
			}] ignoreValues];
		}];
		return [[[[[RACSignal concat:getMessageSignals] materialize] map:^id(RACEvent *event) {
			NSAssert(event.eventType == RACEventTypeCompleted, @"Event should be completed");
			return [RACEvent eventWithValue:[mutableMessages copy]];
		}] dematerialize] take:1];
	}];
	return folderSignal;
}

- (RACSignal *)getMessageId:(NSString *)messageId folderId:(NSString *)folderId share:(SharedAccount *)share session:(EboksSession *)session {
	NSParameterAssert(share);
	NSString *urlFormat = @"%@/%@/%@/mail/folder/%@/message/%@";
	NSString *urlString = [NSString stringWithFormat:urlFormat, self.baseURL.absoluteString, session.internalUserId, share.userId, folderId, messageId];
	RACSignal *requestSignal = [self requestSignalForSession:session urlString:urlString xmlResponse:YES];
	RACSignal *messageSignal = [requestSignal map:^id(ONOXMLDocument *responseDocument) {
		ONOXMLElement *messageElement = responseDocument.rootElement;
		MessageInfo *message = [MessageInfo messageFromXMLElement:messageElement name:share.name];
		return message;
	}];
	return messageSignal;
}

- (RACSignal *)getFileDataForMessageId:(NSString *)messageId shareId:(NSString *)shareId session:(EboksSession *)session {
	if (!shareId) shareId = @"0"; // means the logged in user
	NSString *urlFormat = @"%@/%@/%@/mail/folder/0/message/%@/content";
	NSString *urlString = [NSString stringWithFormat:urlFormat, self.baseURL.absoluteString, session.internalUserId, shareId, messageId];
	RACSignal *requestSignal = [[self requestSignalForSession:session urlString:urlString xmlResponse:NO] catch:^RACSignal *(NSError *error) {
		NSHTTPURLResponse *response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
		RACSignal *returnSignal = [RACSignal error:error];
		if (response.statusCode == 500) {
			NSLog(@"Document failed to download. This sometimes happens. Recover by writing empty file. %@, %@", urlString, error);
			returnSignal = [RACSignal return:[NSData data]];
		}
		return returnSignal;
	}];

	RACSignal *contentSignal = [requestSignal map:^id(id responseData) {
		return responseData;
	}];
	return contentSignal;

}

- (RACSignal *)requestSignalForSession:(EboksSession *)session urlString:(NSString *)urlString xmlResponse:(BOOL)xml {
	// we need defer here to avoid setting the nonce before last second
	return [RACSignal defer:^RACSignal * {
		NSURL *url = [NSURL URLWithString:urlString];
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
		[APIClient setHeadersOnRequest:request session:session];

		AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
		if (xml) {
			requestOperation.responseSerializer = [AFOnoResponseSerializer XMLResponseSerializer];
		}
		RACSignal *requestSignal = [[self signalForRequestOperation:requestOperation] doNext:^(id _) {
			NSDictionary *headers = [requestOperation.response allHeaderFields];
			NSString *authenticateResponse = headers[@"X-EBOKS-AUTHENTICATE"];
			session.nonce = [[authenticateResponse firstMatchWithDetails:RX(@"nonce=\\\"(([a-f0-9])+)\\\"")].groups[1] value];
		}];
		return requestSignal;
	}];
}

- (RACSignal *)signalForRequestOperation:(AFHTTPRequestOperation *)requestOperation {
	return [[RACSignal createSignal:^RACDisposable *(id <RACSubscriber> subscriber) {
		[requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
			[subscriber sendNext:responseObject];
			[subscriber sendCompleted];
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			[subscriber sendError:error];
			NSLog(@"Error: %@", error);
		}];
		[[NSOperationQueue mainQueue] addOperation:requestOperation];
		return [RACDisposable disposableWithBlock:^{
			[requestOperation cancel];
		}];
	}] logError];
}

+ (void)setHeadersOnRequest:(NSMutableURLRequest *)request session:(EboksSession *)session {
	NSString *signature = [NSString stringWithFormat:@"%@:%@:%@:%@", session.account.activationCode, session.deviceId, session.nonce, session.sessionId];
	NSString *responseChallenge = [APIClient doubleHash:signature];
	NSString *auth = [NSString stringWithFormat:@"deviceid=\"%@\",nonce=\"%@\",sessionid=\"%@\",response=\"%@\"", session.deviceId, session.nonce, session.sessionId, responseChallenge];
	[request setValue:auth forHTTPHeaderField:@"X-EBOKS-AUTHENTICATE"];
	[request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
	[request setValue:@"eboks/35 CFNetwork/672.1.15 Darwin/14.0.0" forHTTPHeaderField:@"User-Agent"];
}

+ (NSString *)currentDateString {
	return [[NSDate date] description];
}

+ (NSString *)sha256:(NSString *)input {
	return [CocoaSecurity sha256:input].hexLower;
}

+ (NSString *)doubleHash:(NSString *)input {
	return [self sha256:[self sha256:input]];
}


@end