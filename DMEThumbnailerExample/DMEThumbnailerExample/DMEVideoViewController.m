//
//  DMEVideoViewController.m
//  DMEThumbnailerExample
//
//  Created by David Getapp on 13/02/14.
//  Copyright (c) 2014 David. All rights reserved.
//

#import "DMEVideoViewController.h"
#import "DMEThumbnailer.h"

@interface DMEVideoViewController ()

@end

@implementation DMEVideoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
	
    if([[DMEThumbnailer sharedInstance] thumbExistForPath:path andPrefix:@"small"] && [[DMEThumbnailer sharedInstance] thumbExistForPath:path andPrefix:@"large"]){
        self.imgSmall.image = [[DMEThumbnailer sharedInstance] readThumb:path withPrefix:@"small"];
        self.imgLarge.image = [[DMEThumbnailer sharedInstance] readThumb:path withPrefix:@"large"];
        self.btnGenerate.hidden = YES;
    }
    else{
        self.btnRemove.hidden = YES;
    }
}

- (IBAction)generate:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
    
    [[DMEThumbnailer sharedInstance] generateVideoThumbnails:path completionBlock:^(NSDictionary *thumbs) {
        for (NSString *prefix in thumbs) {
            if([prefix isEqualToString:@"small"]){
                self.imgSmall.image = [thumbs objectForKey:prefix];
            }
            else if ([prefix isEqualToString:@"large"]){
                self.imgLarge.image = [thumbs objectForKey:prefix];
            }
        }
        
        self.btnGenerate.hidden = YES;
        self.btnRemove.hidden = NO;
    }];
    
}

- (IBAction)remove:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
    
    self.imgLarge.image = nil;
    self.imgSmall.image = nil;
    
    [[DMEThumbnailer sharedInstance] removeThumbnails:path];
    
    self.btnGenerate.hidden = NO;
    self.btnRemove.hidden = YES;
}

@end
