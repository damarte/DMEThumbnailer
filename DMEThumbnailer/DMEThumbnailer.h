//
//  DMEThumbnailer.h
//

#import <AVFoundation/AVFoundation.h>

typedef void (^GenerateThumbCompletionBlock)(UIImage *thumb);
typedef void (^GenerateThumbsCompletionBlock)(NSDictionary *thumbs);

@interface DMEThumbnailer : NSObject

//Sizes of the thumbnails
@property (strong, nonatomic) NSDictionary *sizes;

+(instancetype)sharedInstance;

-(void)generateImageThumbnails:(NSString *)aPath completionBlock:(GenerateThumbsCompletionBlock)block;
-(void)generateVideoThumbnails:(NSString *)aPath completionBlock:(GenerateThumbsCompletionBlock)block;
-(void)generatePDFThumbnails:(NSString *)aPath completionBlock:(GenerateThumbsCompletionBlock)block;
-(void)removeThumbnails:(NSString *)aPath;

//Generate thumbnail from image
-(void)generateImageThumbnail:(NSString *)aPath widthSize:(CGSize)aSize completionBlock:(GenerateThumbCompletionBlock)block;

//Generate thumbnail from MP4 video
-(void)generateVideoThumbnail:(NSString *)aPath widthSize:(CGSize)aSize completionBlock:(GenerateThumbCompletionBlock)block;

//Generate thumbnail from PDF
-(void)generatePDFThumbnail:(NSString *)aPath widthSize:(CGSize)aSize completionBlock:(GenerateThumbCompletionBlock)block;

//Thumbnail manipulation
-(UIImage *)readThumb:(NSString *)aPath;
-(UIImage *)readThumb:(NSString *)aPath withPrefix:(NSString *)aPrefix;
-(BOOL)saveThumb:(UIImage *)aImage inPath:(NSString *)aPath;
-(BOOL)removeThumb:(NSString *)aPath;
-(BOOL)thumbExistForPath:(NSString *)aPath;
-(BOOL)thumbExistForPath:(NSString *)aPath andPrefix:(NSString *)aPrefix;

@end
