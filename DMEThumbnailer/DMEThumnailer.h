//
//  DMEThumnailer.h
//

@interface DMEThumnailer : NSObject

//Sizes of the thumbnails
@property (strong, nonatomic) NSDictionary *sizes;

+(instancetype)sharedInstance;

-(void)generateImageThumbnails:(NSString *)aUrl;
-(void)generateVideoThumbnails:(NSString *)aUrl;
-(void)generatePDFThumbnails:(NSString *)aUrl;
-(void)removeThumbnails:(NSString *)aUrl;

//Generate thumbnail from image
-(UIImage *)generateImageThumbnail:(NSString *)aUrl widthSize:(CGSize)aSize;

//Generate thumbnail from mp4 video
-(void)generateVideoThumbnail:(NSString *)aUrl widthSize:(CGSize)aSize response:(AVAssetImageGeneratorCompletionHandler)aResponse;

//Generate thumbnail from PDF
-(UIImage *)generatePDFThumbnail:(NSString *)aUrl widthSize:(CGSize)aSize;

//Thumbnail manipulation
-(UIImage *)readThumb:(NSString *)aName;
-(UIImage *)readThumb:(NSString *)aName withPrefix:(NSString *)aPrefix;
-(BOOL)saveThumb:(UIImage *)aImage withName:(NSString *)aName;
-(BOOL)removeThumb:(NSString *)aName;
-(BOOL)thumbExistWithName:(NSString *)aName;

@end
