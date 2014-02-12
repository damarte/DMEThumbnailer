//
//  DMEThumnailer.m
//

#import "DMEThumnailer.h"

@implementation DMEThumnailer

+(instancetype)sharedInstance {
    static DMEThumnailer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DMEThumnailer alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark Generic generate thumbnails
-(void)generateImageThumbnails:(NSString *)aUrl;
{
    for (NSString* prefix in self.sizes) {
        CGSize size = [[self.sizes objectForKey:prefix] CGSizeValue];
        [self generateImageThumbnail:aUrl widthSize:size widthPrefix:prefix];
    }
}

-(void)generateVideoThumbnails:(NSString *)aUrl;
{
    for (NSString* prefix in self.sizes) {
        CGSize size = [[self.sizes objectForKey:prefix] CGSizeValue];
        [self generateVideoThumbnail:aUrl widthSize:size atSecond:1 widthPrefix:prefix response:nil];
    }
}

-(void)generatePDFThumbnails:(NSString *)aUrl
{
    for (NSString* prefix in self.sizes) {
        CGSize size = [[self.sizes objectForKey:prefix] CGSizeValue];
        [self generatePDFThumbnail:aUrl widthSize:size forPage:1 widthPrefix:prefix];
    }
}

-(void)removeThumbnails:(NSString *)url
{
    for (NSString* prefix in self.sizes) {
        [self removeThumb:url withPrefix:prefix];
    }
}

#pragma mark Specified generate thumbnails

-(UIImage *)generateImageThumbnail:(NSString *)aUrl widthSize:(CGSize)aSize
{
    return [self generateImageThumbnail:aUrl widthSize:aSize widthPrefix:@""];
}

-(UIImage *)generateImageThumbnail:(NSString *)aUrl widthSize:(CGSize)aSize widthPrefix:(NSString *)aPrefix
{
    UIImage *thumbnail = nil;
    if([self thumbExistWithName:[aUrl lastPathComponent] andPrefix:aPrefix]){
        //Cargamos el thumb
        thumbnail= [self readThumb:[aUrl lastPathComponent] withPrefix:aPrefix];
    }
    else{
        aSize = [self adjustSizeRetina:aSize];
        
        UIImage *originalImage = [UIImage imageWithContentsOfFile:aUrl];
        thumbnail = [self imageByScalingAndCropping:originalImage forSize:aSize];
        
        //Guardamos el thumb
        [self saveThumb:thumbnail withName:[aUrl lastPathComponent] withPrefix:aPrefix];
    }
    
    return thumbnail;
}

//Genera un thumbnail a partir de un video mp4
-(void)generateVideoThumbnail:(NSString *)aUrl widthSize:(CGSize)aSize response:(AVAssetImageGeneratorCompletionHandler)aResponse
{
    [self generateVideoThumbnail:aUrl widthSize:aSize atSecond:1 widthPrefix:@"" response:aResponse];
}

-(void)generateVideoThumbnail:(NSString *)aUrl widthSize:(CGSize)aSize atSecond:(NSInteger)aSecond widthPrefix:(NSString *)aPrefix response:(AVAssetImageGeneratorCompletionHandler) aResponse
{
    if([self thumbExistWithName:[aUrl lastPathComponent] andPrefix:aPrefix]){
        UIImage *thumbnail = [self readThumb:[aUrl lastPathComponent] withPrefix:aPrefix];
        if(aResponse){
            aResponse(CMTimeMake(0, 0), [thumbnail CGImage], CMTimeMake(0, 0), AVAssetImageGeneratorSucceeded, nil);
        }
    }
    else{
        aSize = [self adjustSizeRetina:aSize];
        
        //Generamos el thumbnail asincronamente
        AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:aUrl] options:nil];
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
            UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            //Guardamos el thumb
            [self saveThumb:finalImage withName:[aUrl lastPathComponent] withPrefix:aPrefix];
            
            if(aResponse){
                aResponse(requestedTime, image, actualTime, result, error);
            }
        }];
    }
}

//Genera un thumbnail de una pagina de un PDF
-(UIImage *)generatePDFThumbnail:(NSString *)aUrl widthSize:(CGSize)aSize
{
    return [self generatePDFThumbnail:aUrl widthSize:aSize forPage:1 widthPrefix:@""];
}

-(UIImage *)generatePDFThumbnail:(NSString *)aUrl widthSize:(CGSize)aSize forPage:(NSInteger)aPage widthPrefix:(NSString *)aPrefix
{
    NSFileManager *gestorArchivos = [NSFileManager defaultManager];
    UIImage *thumbnail = nil;
    
    if([self thumbExistWithName:[aUrl lastPathComponent] andPrefix:aPrefix]){
        //Cargamos el thumb
        thumbnail= [self readThumb:[aUrl lastPathComponent] withPrefix:aPrefix];
    }
    else{
        //Comprobamos si existe el pdf
        if ([gestorArchivos fileExistsAtPath: aUrl]) {
            aSize = [self adjustSizeRetina:aSize];
            
            //Ruta al pdf
            CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:aUrl]);
            
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
            [self saveThumb:thumbnail withName:[aUrl lastPathComponent] withPrefix:aPrefix];
        }
    }
    return thumbnail;
}

#pragma mark - File Management

-(UIImage *)readThumb:(NSString *)aName
{
    return [self readThumb:aName withPrefix:@""];
}

-(UIImage *)readThumb:(NSString *)aName withPrefix:(NSString *)aPrefix
{
    return [UIImage imageWithContentsOfFile:[self pathFromName:aName andPrefix:aPrefix]];
}

-(BOOL)saveThumb:(UIImage *)aImage withName:(NSString *)aName
{
    return [self saveThumb:aImage withName:aName withPrefix:@""];
}

-(BOOL)saveThumb:(UIImage *)aImage withName:(NSString *)aName withPrefix:(NSString *)aPrefix
{
    NSFileManager *filemgr = [NSFileManager defaultManager];
    
    NSString *urlDirectorio = [NSString stringWithFormat:@"%@/%@", pathCache(), @"Thumbs"];
    
    if([filemgr changeCurrentDirectoryPath: urlDirectorio] == NO)
    {
        [filemgr createDirectoryAtPath: urlDirectorio withIntermediateDirectories: YES attributes: nil error: NULL];
    }
    
    if ([filemgr changeCurrentDirectoryPath: urlDirectorio] == YES)
    {
        [UIImagePNGRepresentation(aImage) writeToFile:[self pathFromName:aName andPrefix:aPrefix] atomically:YES];
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

-(BOOL)removeThumb:(NSString *)aName withPrefix:(NSString *)aPrefix
{
    if([self thumbExistWithName:aName andPrefix:aPrefix]){
        NSFileManager *filemgr = [NSFileManager defaultManager];
        NSError *error;
        [filemgr removeItemAtPath:[self pathFromName:aName andPrefix:aPrefix] error:&error];
        if (error.code != NSFileNoSuchFileError) {
            return NO;
        }
        return YES;
    }
    else{
        return NO;
    }
}

-(BOOL)thumbExistWithName:(NSString *)aName
{
    return [self thumbExistWithName:aName andPrefix:@""];
}

-(BOOL)thumbExistWithName:(NSString *)aName andPrefix:(NSString *)aPrefix
{
    NSFileManager *filemgr = [NSFileManager defaultManager];
    return [filemgr fileExistsAtPath:[self pathFromName:aName andPrefix:aPrefix]];
}

-(NSString *)pathFromName:(NSString *)aName andPrefix:(NSString *)aPrefix
{
    if([aPrefix isEqualToString:@""]){
        return [NSString stringWithFormat:@"%@/%@/%@", pathCache(), @"Thumbs", aName];
    }
    else{
        return [NSString stringWithFormat:@"%@/%@/%@-%@", pathCache(), @"Thumbs", aPrefix, aName];
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
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else if (widthFactor < heightFactor) {
            thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
    }
    
    UIGraphicsBeginImageContext(aSize); // this will crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not scale image");
    }
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}


@end
