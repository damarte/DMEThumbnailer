//
//  DMEThumnailer.m
//

#import "DMEThumbnailer.h"

@implementation DMEThumbnailer

+(instancetype)sharedInstance {
    static DMEThumbnailer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DMEThumbnailer alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark Generic generate thumbnails
-(void)generateImageThumbnails:(NSString *)aPath completionBlock:(GenerateThumbsCompletionBlock)block
{
    __block NSMutableDictionary *thumbs = [NSMutableDictionary dictionaryWithCapacity:self.sizes.count];
    for (NSString* prefix in self.sizes) {
        CGSize size = [[self.sizes objectForKey:prefix] CGSizeValue];
        [self generateImageThumbnail:aPath widthSize:size widthPrefix:prefix completionBlock:^(UIImage *thumb) {
            [thumbs setObject:thumb forKey:prefix];
        }];
    }
    
    if(block){
        block(thumbs);
    }
}

-(void)generateVideoThumbnails:(NSString *)aPath completionBlock:(GenerateThumbsCompletionBlock)block
{
    // Create a dispatch group
    dispatch_group_t group = dispatch_group_create();
    
    __block NSMutableDictionary *thumbs = [NSMutableDictionary dictionaryWithCapacity:self.sizes.count];
    for (NSString* prefix in self.sizes) {
        // Enter the group for each request we create
        dispatch_group_enter(group);
        
        CGSize size = [[self.sizes objectForKey:prefix] CGSizeValue];
        [self generateVideoThumbnail:aPath widthSize:size atSecond:1 widthPrefix:prefix completionBlock:^(UIImage *thumb) {
            [thumbs setObject:thumb forKey:prefix];
            
            // Leave the group as soon as the request succeeded
            dispatch_group_leave(group);
        }];
    }
    
    // Here we wait for all the requests to finish
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if(block){
            block(thumbs);
        }
    });
}

-(void)generatePDFThumbnails:(NSString *)aPath completionBlock:(GenerateThumbsCompletionBlock)block
{
    __block NSMutableDictionary *thumbs = [NSMutableDictionary dictionaryWithCapacity:self.sizes.count];
    for (NSString* prefix in self.sizes) {
        CGSize size = [[self.sizes objectForKey:prefix] CGSizeValue];
        [self generatePDFThumbnail:aPath widthSize:size forPage:1 widthPrefix:prefix completionBlock:^(UIImage *thumb) {
            [thumbs setObject:thumb forKey:prefix];
        }];
    }
    
    if(block){
        block(thumbs);
    }
}

-(void)removeThumbnails:(NSString *)aPath
{
    for (NSString* prefix in self.sizes) {
        [self removeThumb:aPath withPrefix:prefix];
    }
}

#pragma mark Specified generate thumbnails

-(void)generateImageThumbnail:(NSString *)aPath widthSize:(CGSize)aSize completionBlock:(GenerateThumbCompletionBlock)block
{
    [self generateImageThumbnail:aPath widthSize:aSize widthPrefix:@"" completionBlock:block];
}

-(void)generateImageThumbnail:(NSString *)aPath widthSize:(CGSize)aSize widthPrefix:(NSString *)aPrefix completionBlock:(GenerateThumbCompletionBlock)block
{
    UIImage *thumbnail = nil;
    if([self thumbExistForPath:aPath andPrefix:aPrefix]){
        thumbnail= [self readThumb:[aPath lastPathComponent] withPrefix:aPrefix];
    }
    else{
        aSize = [self adjustSizeRetina:aSize];
        
        UIImage *originalImage = [UIImage imageWithContentsOfFile:aPath];
        thumbnail = [self imageByScalingAndCropping:originalImage forSize:aSize];
        
        [self saveThumb:thumbnail inPath:aPath withPrefix:aPrefix];
    }
    
    if(block){
        block(thumbnail);
    }
}

-(void)generateVideoThumbnail:(NSString *)aPath widthSize:(CGSize)aSize completionBlock:(GenerateThumbCompletionBlock)block
{
    [self generateVideoThumbnail:aPath widthSize:aSize atSecond:1 widthPrefix:@"" completionBlock:block];
}

-(void)generateVideoThumbnail:(NSString *)aPath widthSize:(CGSize)aSize atSecond:(NSInteger)aSecond widthPrefix:(NSString *)aPrefix completionBlock:(GenerateThumbCompletionBlock)block
{
    if([self thumbExistForPath:aPath andPrefix:aPrefix]){
        UIImage *thumbnail = [self readThumb:aPath withPrefix:aPrefix];
        if(block){
            block(thumbnail);
        }
    }
    else{
        aSize = [self adjustSizeRetina:aSize];
        
        AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:aPath] options:nil];
        AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        generator.appliesPreferredTrackTransform=TRUE;
        CMTime thumbTime = CMTimeMakeWithSeconds(aSecond,1);
        
        CGFloat max;
        if(aSize.width > aSize.height){
            max = aSize.width;
        }
        else{
            max = aSize.height;
        }
        CGSize maxSize = CGSizeMake(max, max);
        generator.maximumSize = maxSize;
        [generator generateCGImagesAsynchronouslyForTimes:[NSArray arrayWithObject:[NSValue valueWithCMTime:thumbTime]] completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {

            //Overlay play
            UIImage *backgroundImage = [self imageByScalingAndCropping:[UIImage imageWithCGImage:image] forSize:aSize];
            UIImage *watermarkImage = [UIImage imageNamed:@"VideoWatermark"];
            CGSize watermarkSize = watermarkImage.size;
            watermarkSize = [self adjustSizeRetina:watermarkSize];
            UIGraphicsBeginImageContext(backgroundImage.size);
            [backgroundImage drawInRect:CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height)];
            [watermarkImage drawInRect:CGRectMake((backgroundImage.size.width - watermarkSize.width) / 2, (backgroundImage.size.height - watermarkSize.height) / 2, watermarkSize.width, watermarkSize.height)];
            UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            [self saveThumb:thumbnail inPath:aPath withPrefix:aPrefix];
            
            if(block){
                block(thumbnail);
            }
        }];
    }
}

//Genera un thumbnail de una pagina de un PDF
-(void)generatePDFThumbnail:(NSString *)aPath widthSize:(CGSize)aSize completionBlock:(GenerateThumbCompletionBlock)block
{
    [self generatePDFThumbnail:aPath widthSize:aSize forPage:1 widthPrefix:@"" completionBlock:block];
}

-(void)generatePDFThumbnail:(NSString *)aPath widthSize:(CGSize)aSize forPage:(NSInteger)aPage widthPrefix:(NSString *)aPrefix completionBlock:(GenerateThumbCompletionBlock)block
{
    NSFileManager *gestorArchivos = [NSFileManager defaultManager];
    UIImage *thumbnail = nil;
    
    if([self thumbExistForPath:aPath andPrefix:aPrefix]){
        //Cargamos el thumb
        thumbnail= [self readThumb:aPath withPrefix:aPrefix];
    }
    else{
        //Comprobamos si existe el pdf
        if ([gestorArchivos fileExistsAtPath: aPath]) {
            aSize = [self adjustSizeRetina:aSize];
            
            //Ruta al pdf
            CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:aPath]);
            
            CGPDFPageRef page = CGPDFDocumentGetPage(pdf, aPage);
            CGRect aRect = CGPDFPageGetBoxRect(page, kCGPDFCropBox);
            UIGraphicsBeginImageContext(aRect.size);
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            CGContextSaveGState(context);
            CGContextTranslateCTM(context, 0.0, aRect.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextTranslateCTM(context, -(aRect.origin.x), -(aRect.origin.y));
            
            CGContextSetGrayFillColor(context, 1.0, 1.0);
            CGContextFillRect(context, aRect);
            
            CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, aRect, 0, false);
            CGContextConcatCTM(context, pdfTransform);
            CGContextDrawPDFPage(context, page);
            
            thumbnail = UIGraphicsGetImageFromCurrentImageContext();
            CGContextRestoreGState(context);
            UIGraphicsEndImageContext();
            CGPDFDocumentRelease(pdf);
            
            thumbnail = [self imageByScalingAndCropping:thumbnail forSize:aSize];

            //Guardamos el thumb
            [self saveThumb:thumbnail inPath:aPath withPrefix:aPrefix];
        }
    }
    
    if(block){
        block(thumbnail);
    }
}

#pragma mark - File Management

-(UIImage *)readThumb:(NSString *)aPath
{
    return [self readThumb:aPath withPrefix:@""];
}

-(UIImage *)readThumb:(NSString *)aPath withPrefix:(NSString *)aPrefix
{
    return [UIImage imageWithContentsOfFile:[self thumbPathFromFilePath:aPath andPrefix:aPrefix]];
}

-(BOOL)saveThumb:(UIImage *)aImage inPath:(NSString *)aPath
{
    return [self saveThumb:aImage inPath:aPath withPrefix:@""];
}

-(BOOL)saveThumb:(UIImage *)aImage inPath:(NSString *)aPath withPrefix:(NSString *)aPrefix
{
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    NSString *urlDirectorio = [NSString stringWithFormat:@"%@/%@", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0], @"Thumbs"];
    
    if([filemgr changeCurrentDirectoryPath: urlDirectorio] == NO)
    {
        [filemgr createDirectoryAtPath: urlDirectorio withIntermediateDirectories: YES attributes: nil error: NULL];
    }
    
    if ([filemgr changeCurrentDirectoryPath: urlDirectorio] == YES)
    {
        [UIImagePNGRepresentation(aImage) writeToFile:[self thumbPathFromFilePath:aPath andPrefix:aPrefix] atomically:YES];
        return YES;
    }
    else{
        return NO;
    }
}

-(BOOL)removeThumb:(NSString *)aName
{
    return [self removeThumb:aName withPrefix:@""];
}

-(BOOL)removeThumb:(NSString *)aPath withPrefix:(NSString *)aPrefix
{
    if([self thumbExistForPath:aPath andPrefix:aPrefix]){
        NSFileManager *filemgr = [NSFileManager defaultManager];
        NSError *error;
        [filemgr removeItemAtPath:[self thumbPathFromFilePath:aPath andPrefix:aPrefix] error:&error];
        if (error.code != NSFileNoSuchFileError) {
            return NO;
        }
        return YES;
    }
    else{
        return NO;
    }
}

-(BOOL)thumbExistForPath:(NSString *)aPath
{
    return [self thumbExistForPath:aPath andPrefix:@""];
}

-(BOOL)thumbExistForPath:(NSString *)aPath andPrefix:(NSString *)aPrefix
{
    NSFileManager *filemgr = [NSFileManager defaultManager];
    return [filemgr fileExistsAtPath:[self thumbPathFromFilePath:aPath andPrefix:aPrefix]];
}

-(NSString *)thumbPathFromFilePath:(NSString *)aPath andPrefix:(NSString *)aPrefix
{
    if([aPrefix isEqualToString:@""]){
        return [NSString stringWithFormat:@"%@/%@/%@", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0], @"Thumbs", [aPath lastPathComponent]];
    }
    else{
        return [NSString stringWithFormat:@"%@/%@/%@-%@", [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0], @"Thumbs", aPrefix, [aPath lastPathComponent]];
    }
}

#pragma mark Util

-(CGSize)adjustSizeRetina:(CGSize)aSize{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]){
        return CGSizeMake(aSize.width * [[UIScreen mainScreen] scale], aSize.height * [[UIScreen mainScreen] scale]);
    }
    else{
        return aSize;
    }
}

-(UIImage *)imageByScalingAndCropping:(UIImage *)aImage forSize:(CGSize)aSize
{
    UIImage *sourceImage = aImage;
    UIImage *newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = aSize.width;
    CGFloat targetHeight = aSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, aSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
            scaleFactor = widthFactor; //Scale to fit height
        else
            scaleFactor = heightFactor; //Scale to fit width
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        //Center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else if (widthFactor < heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    UIGraphicsBeginImageContext(aSize); //This will crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not scale image");
    }
    
    //Pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}


@end
