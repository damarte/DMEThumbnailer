//
//  DMEVideoViewController.h
//  DMEThumbnailerExample
//
//  Created by David Getapp on 13/02/14.
//  Copyright (c) 2014 David. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DMEVideoViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *imgLarge;
@property (weak, nonatomic) IBOutlet UIImageView *imgSmall;
@property (weak, nonatomic) IBOutlet UIButton *btnGenerate;
@property (weak, nonatomic) IBOutlet UIButton *btnRemove;

- (IBAction)generate:(id)sender;
- (IBAction)remove:(id)sender;

@end
