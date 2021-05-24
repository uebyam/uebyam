#import <Cocoa/Cocoa.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <Foundation/Foundation.h>
#include <time.h>



#define utf8_enc 4
#define _read CBCharacteristicPropertyRead
#define _notify CBCharacteristicPropertyNotify
#define _write CBCharacteristicPropertyWrite
#define _writewr CBCharacteristicPropertyWriteWithoutResponse

#define _pread CBAttributePermissionsReadable
#define _pwrite CBAttributePermissionsWriteable
#define _epread CBAttributePermissionsReadEncryptionRequired
#define _epwrite CBAttributePermissionsWriteEncryptionRequired
#define _awrite CBCharacteristicWriteWithResponse
#define _awritewr CBCharacteristicWriteWithoutResponse

char canGo = 0;

@interface AppDelegate : NSObject<NSApplicationDelegate, CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate>

@property CBCentralManager* cmgr;
@property CBPeripheralManager* pmgr;

@property CBCentral* ccen;
@property CBPeripheral* cper;

@property CBUUID* sUUID;
@property CBUUID* crUUID;
@property CBUUID* cwUUID;
@property CBUUID* ccUUID;
@property CBUUID* csUUID;

@property CBMutableService* mservice;
@property CBMutableCharacteristic* mrcharac;
@property CBMutableCharacteristic* mwcharac;
@property CBMutableCharacteristic* mccharac;
@property CBMutableCharacteristic* mscharac;

@property CBService* service;
@property CBCharacteristic* rcharac;
@property CBCharacteristic* wcharac;
@property CBCharacteristic* ccharac;
@property CBCharacteristic* scharac;

@property NSString* cname;
@property NSString* pname;
@property NSString* lf;

@property (weak) IBOutlet NSView *MenuView;
@property (weak) IBOutlet NSView *PeripheralOptionsView;
@property (weak) IBOutlet NSView *PeripheralWaitView;
@property (weak) IBOutlet NSView *CentralOptionsView;
@property (weak) IBOutlet NSView *CentralWaitView;
@property (weak) IBOutlet NSView *ChatView;

@property (weak) IBOutlet NSTextField *pnameField;
@property (weak) IBOutlet NSButton *SystemNameUsed;

@property (weak) IBOutlet NSTextField *chattingWithWho;

@property (unsafe_unretained) IBOutlet NSTextView *YourMessages;

@property (weak) IBOutlet NSTextField *centralName;
@property (weak) IBOutlet NSTextField *connectTo;

- (IBAction)ModeChosen:(NSButton *)sender;
- (IBAction)PeripheralGo:(NSButton *)sender;
- (IBAction)sendMessage:(id)sender;
- (IBAction)sendMessageEnter:(NSTextField *)sender;
@property (weak) IBOutlet NSTextField *message;
@property (weak) IBOutlet NSLevelIndicator *RSSIIndicator;

@property char canSend;
@property char whoSpeak;
@property char firstMessageSent;

@property (strong) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

@synthesize cmgr;
@synthesize pmgr;

@synthesize ccen;
@synthesize cper;

@synthesize sUUID;
@synthesize crUUID;
@synthesize cwUUID;
@synthesize ccUUID;
@synthesize csUUID;

@synthesize mservice;
@synthesize mrcharac;
@synthesize mwcharac;
@synthesize mccharac;
@synthesize mscharac;

@synthesize service;
@synthesize rcharac;
@synthesize wcharac;
@synthesize ccharac;
@synthesize scharac;

@synthesize cname;
@synthesize pname;
@synthesize lf;

@synthesize canSend;
@synthesize whoSpeak;
@synthesize firstMessageSent;

CBPeripheral* passedPeripheral;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    sUUID = [CBUUID UUIDWithString:@"BEEF"];
    crUUID = [CBUUID UUIDWithString:@"BEF0"];
    cwUUID = [CBUUID UUIDWithString:@"BEF1"];
    ccUUID = [CBUUID UUIDWithString:@"BEF2"];
    csUUID = [CBUUID UUIDWithString:@"BEF3"];
    
    lf = @"\n";
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
}





#pragma mark Central sided use





- (void)cmgris {
    [cmgr scanForPeripheralsWithServices:@[sUUID] options:nil];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    if ([peripheral.name isEqual:pname]) {
        puts("Found device");
        NSLog(@"%@", peripheral);
        [cmgr stopScan];
        cper = peripheral;
        passedPeripheral = cper;
        [cmgr connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    puts("Connected to device");
    peripheral.delegate = self;
    cper = peripheral;
    passedPeripheral = cper;
    [peripheral discoverServices:@[sUUID]];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    puts("Disconnected");
    printf("%s\n", [error.localizedDescription cStringUsingEncoding:utf8_enc]);
    cper = nil;
    ccharac = nil;
    wcharac = nil;
    rcharac = nil;
    _ChatView.hidden = 1;
    _CentralOptionsView.hidden = 0;
    _YourMessages.string = @" ";
    firstMessageSent = 0;
    whoSpeak = 0;
    canGo = 0;
    
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    puts("Failed connect");
    printf("%s\n", [error.localizedDescription cStringUsingEncoding:utf8_enc]);
    cper = nil;
    canGo = 0;
    [cmgr scanForPeripheralsWithServices:@[sUUID] options:nil];
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices {
    puts("Services invalidated, rescanning");
    _ChatView.hidden = 1;
//    _CentralOptionsView.hidden = 0;
    canGo = 0;
    [cmgr cancelPeripheralConnection:peripheral];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    puts("Disc: Services");
    cper = peripheral;
    passedPeripheral = cper;
    for (CBService* ser in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:ser];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    puts("Disc: Charac");
    cper = peripheral;
    passedPeripheral = cper;
    NSLog(@"%@", service.characteristics);
    for (CBCharacteristic* tcharac in service.characteristics) {
        if ([tcharac.UUID.UUIDString isEqual:crUUID.UUIDString]) {
            puts("Found read charac");
            [peripheral setNotifyValue:1 forCharacteristic:tcharac];
        } else if ([tcharac.UUID.UUIDString isEqual:ccUUID.UUIDString]) {
            puts("Found connect charac");
            [peripheral setNotifyValue:1 forCharacteristic:tcharac];
        } else if ([tcharac.UUID.UUIDString isEqual:cwUUID.UUIDString]) {
            puts("Found write charac");
            canSend = 1;
            wcharac = tcharac;
            _CentralWaitView.hidden = 1;
            _ChatView.hidden = 0;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        printf("Error from charac %s: %s\n",
               [characteristic.UUID.UUIDString cStringUsingEncoding:utf8_enc],
               [error.localizedDescription cStringUsingEncoding:utf8_enc]);
    } else {
        if ([characteristic.UUID.UUIDString isEqual:crUUID.UUIDString]) {
            puts("Read charac sub success");
            rcharac = characteristic;
        } else if ([characteristic.UUID.UUIDString isEqual:ccUUID.UUIDString]) {
            puts("Connect charac sub success");
            _connectTo.stringValue = peripheral.name;
            [peripheral writeValue:[cname dataUsingEncoding:utf8_enc]
                 forCharacteristic:characteristic
                              type:_awrite];
            ccharac = characteristic;
            [peripheral readRSSI];
        }
    }
}

- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    if (cmgr.state == CBManagerStatePoweredOn) {
        puts("Success: cmgr");
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        printf("%s\n", [error.localizedDescription cStringUsingEncoding:utf8_enc]);
    } else {

        if ([characteristic.UUID.UUIDString isEqual:cwUUID.UUIDString]) {
            puts("Write successful");
            if (whoSpeak == 0 && firstMessageSent == 1) {
                _YourMessages.string = [_YourMessages.string stringByAppendingString:lf];
            }
            if ([_message.stringValue isEqual:@"\\disconnect"]) {
                [cmgr cancelPeripheralConnection:cper];
                return;
            }
            _YourMessages.string = [_YourMessages.string stringByAppendingString:@"> "];
            _YourMessages.string = [_YourMessages.string stringByAppendingString:_message.stringValue];
            _YourMessages.string = [_YourMessages.string stringByAppendingString:lf];
            
            [self autoScroll:_YourMessages threshold:26];
            whoSpeak = 1;
            firstMessageSent = 1;
            _message.stringValue = @"";
        } else if ([characteristic.UUID.UUIDString isEqual:ccUUID.UUIDString]) {
            puts("Written connect charac");
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        printf("%s\n", [error.localizedDescription cStringUsingEncoding:utf8_enc]);
    } else {
        if ([characteristic.UUID.UUIDString isEqual:crUUID.UUIDString]) {
            puts("Received value");
            NSString* newString = [[NSString alloc]
                                   initWithData:characteristic.value
                                   encoding:utf8_enc];
            if ([newString isEqual:@"\\disconnect"]) { [cmgr cancelPeripheralConnection:peripheral];
                return;
            }
            if (whoSpeak == 1 && firstMessageSent == 1) {
                _YourMessages.string = [_YourMessages.string stringByAppendingString:lf];
            }
            
            _YourMessages.string = [_YourMessages.string stringByAppendingString:@"- "];
            _YourMessages.string = [_YourMessages.string stringByAppendingString:newString];
            _YourMessages.string = [_YourMessages.string stringByAppendingString:lf];
            [self autoScroll:_YourMessages threshold:26];
            whoSpeak = 0;
            firstMessageSent = 1;
        }
    }
}

- (IBAction)readrssibp:(NSButton *)sender {
    [cper readRSSI];
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    if (error) {
        printf("%s\n", [error.localizedDescription cStringUsingEncoding:utf8_enc]);
    } else {
        _RSSIIndicator.intValue = RSSI.intValue + 120;
    }
}





#pragma mark Peripheral sided use





- (void)pmgris {
    if (![pname isEqual:@""] && !(pname.length > 9) && !(pname.length < 1)) {
        [pmgr startAdvertising:@{
            CBAdvertisementDataServiceUUIDsKey: @[sUUID],
            CBAdvertisementDataLocalNameKey: pname
        }];
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    if (error) {
        printf("%s\n", [error.localizedDescription cStringUsingEncoding:utf8_enc]);
        kill(getpid(), SIGKILL);
    } else {
        puts("Advertising success");
    }
}

- (void)peripheralManagerDidUpdateState:(nonnull CBPeripheralManager *)peripheral {
    if (pmgr.state == CBManagerStatePoweredOn) {
        mservice = [[CBMutableService alloc] initWithType:sUUID primary:1];
        mrcharac = [[CBMutableCharacteristic alloc]
                    initWithType:crUUID
                    properties:_notify | _read
                    value:nil
                    permissions:_pread];
        mwcharac = [[CBMutableCharacteristic alloc]
                    initWithType:cwUUID
                    properties:_read | _write
                    value:nil
                    permissions:_pread | _pwrite];
        mccharac = [[CBMutableCharacteristic alloc]
                    initWithType:ccUUID
                    properties:_notify | _read | _write
                    value:nil
                    permissions:_pread | _pwrite];
        mscharac = [[CBMutableCharacteristic alloc]
                    initWithType:csUUID
                    properties:_read | _write
                    value:nil
                    permissions:_pread | _pwrite];
        mservice.characteristics = @[mrcharac, mwcharac, mccharac, mscharac];
        [pmgr addService:mservice];
        
        puts("Success: pmgr");
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    if ([characteristic.UUID.UUIDString isEqual:ccUUID.UUIDString]) {
        puts("Connected");
        ccen = central;
    }
    if ([characteristic.UUID.UUIDString isEqual:crUUID.UUIDString]) {
        puts("Sending of messages allowed");
        canSend = 1;
        _PeripheralOptionsView.hidden = 1;
        _ChatView.hidden = 0;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    if ([characteristic.UUID.UUIDString isEqual:ccUUID.UUIDString]) {
        puts("Disconnected");
        _ChatView.hidden = 1;
        _PeripheralWaitView.hidden = 0;
        canSend = 0;
        ccen = nil;
    }
    if ([characteristic.UUID.UUIDString isEqual:crUUID.UUIDString]) {
        puts("Sending of messages disallowed");
        canSend = 0;
        ccen = nil;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray<CBATTRequest *> *)requests {
    for (CBATTRequest* request in requests) {
        if ([request.characteristic.UUID.UUIDString isEqual:cwUUID.UUIDString]) {
            puts("Received write");
            [pmgr updateValue:request.value
            forCharacteristic:mwcharac
         onSubscribedCentrals:nil];
            
            NSString* newString = [[NSString alloc] initWithData:request.value encoding:utf8_enc];
            if (whoSpeak == 0 && firstMessageSent == 1) {
                _YourMessages.string = [_YourMessages.string stringByAppendingString:lf];
            }
            
            _YourMessages.string = [_YourMessages.string stringByAppendingString:@"@ "];
            _YourMessages.string = [_YourMessages.string stringByAppendingString:newString];
            _YourMessages.string = [_YourMessages.string stringByAppendingString:lf];
            [self autoScroll:_YourMessages threshold:26];
            whoSpeak = 1;
            firstMessageSent = 1;
        } else if ([request.characteristic.UUID.UUIDString isEqual:ccUUID.UUIDString]) {
            puts("Name updated");
            [pmgr updateValue:request.value
            forCharacteristic:mccharac
         onSubscribedCentrals:nil];
            _connectTo.stringValue = [[NSString alloc]
                                      initWithData:request.value
                                      encoding:utf8_enc];
        }
    }
    [pmgr respondToRequest:requests[0] withResult:0];
}

- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral {
    
}





#pragma mark init/actions





- (IBAction)sendMessageEnter:(NSTextField *)sender {
    [self sendMessage:sender];
}

- (IBAction)sendMessage:(id)sender {
    if (canSend == 1) {
        if ([_message.stringValue isEqual:@""]) {
            printf(":/ No message to send! Ignoring send request...\n");
        } else {
            puts("Sending");
            if (pmgr) {
                puts("Sending as peripheral");
                BOOL returnv = [pmgr updateValue:[_message.stringValue dataUsingEncoding:utf8_enc]
                               forCharacteristic:mrcharac
                            onSubscribedCentrals:nil];
                if (returnv == YES) {
                    puts("Send: Success");
                    if (whoSpeak == 1 && firstMessageSent == 1) {
                        _YourMessages.string = [_YourMessages.string stringByAppendingString:lf];
                    }
                    _YourMessages.string = [_YourMessages.string stringByAppendingString:@"> "];
                    _YourMessages.string = [_YourMessages.string stringByAppendingString:_message.stringValue];
                    _YourMessages.string = [_YourMessages.string stringByAppendingString:lf];
                    [self autoScroll:_YourMessages threshold:26];
                    whoSpeak = 0;
                    firstMessageSent = 1;
                    _message.stringValue = @"";
                }
                else puts("Send: Failed");
                
            } else {
                puts("Sending as central");
                [cper writeValue:[_message.stringValue dataUsingEncoding:utf8_enc]
               forCharacteristic:wcharac
                            type:_awrite];
            }
        }
    }
}



- (IBAction)PeripheralGo:(NSButton *)sender {
    if ([sender.title isEqual:@"Go "]) {
        if (_centralName.stringValue.length < 9 && _centralName.stringValue.length > 0 && _connectTo.stringValue.length < 9 && _connectTo.stringValue.length > 0) {
            cname = _centralName.stringValue;
            pname = _connectTo.stringValue;
            _CentralOptionsView.hidden = 1;
            _CentralWaitView.hidden = 0;
            printf("Scanning for %s\n", [pname cStringUsingEncoding:utf8_enc]);
            [self cmgris];
        }
    } else {
        if (_SystemNameUsed.state == 1) {
            pname = @"?????????";
            _PeripheralOptionsView.hidden = 1;
            _PeripheralWaitView.hidden = 0;
            printf("Advertising (hopefully) as %s\n",
                   [[NSHost currentHost].localizedName cStringUsingEncoding:utf8_enc]);
            [self pmgris];
        }
        if (_pnameField.stringValue.length < 9 && _pnameField.stringValue.length > 0) {
            pname = _pnameField.stringValue;
            _PeripheralOptionsView.hidden = 1;
            _PeripheralWaitView.hidden = 0;
            printf("Advertising as %s\n", [pname cStringUsingEncoding:utf8_enc]);
            [self pmgris];
        }
    }
}

- (IBAction)ModeChosen:(NSButton *)sender {
    if ([sender.title isEqual:@"Central"]) {
        _MenuView.hidden = 1;
        _CentralOptionsView.hidden = 0;
        cmgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    } else {
        _MenuView.hidden = 1;
        _PeripheralOptionsView.hidden = 0;
        pmgr = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    }
}

#pragma mark Others

- (void)autoScroll:(NSTextView *)tv threshold:(int)threshold{
    CGRect docR = tv.bounds;
    CGRect docVR = tv.visibleRect;
    
    if (docR.size.height <= docVR.origin.y+docVR.size.height+threshold) {
        [tv scrollToEndOfDocument:nil];
    }
}

@end
